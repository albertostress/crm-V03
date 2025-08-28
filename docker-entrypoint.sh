#!/bin/bash
set -e

# Function to wait for database
wait_for_db() {
    echo "Waiting for database to be ready..."
    until php -r "
        \$host = getenv('ESPOCRM_DATABASE_HOST') ?: 'mariadb';
        \$port = getenv('ESPOCRM_DATABASE_PORT') ?: '3306';
        \$user = getenv('ESPOCRM_DATABASE_USER') ?: 'espocrm';
        \$pass = getenv('ESPOCRM_DATABASE_PASSWORD') ?: 'espocrm_password';
        \$db = getenv('ESPOCRM_DATABASE_NAME') ?: 'espocrm';
        
        try {
            \$pdo = new PDO(\"mysql:host=\$host;port=\$port;dbname=\$db\", \$user, \$pass);
            echo \"Database is ready!\n\";
            exit(0);
        } catch (PDOException \$e) {
            echo \"Database not ready, retrying...\n\";
            exit(1);
        }
    "; do
        sleep 2
    done
}

# Function to initialize EspoCRM
initialize_espocrm() {
    echo "Initializing EspoCRM..."
    
    # Skip auto install if requested (let web installer handle it)
    if [ "${ESPOCRM_SKIP_AUTO_INSTALL}" = "true" ]; then
        echo "Auto-install skipped. Use web installer at /install/"
        return 0
    fi
    
    # Check if already initialized
    if [ -f /var/www/html/data/config.php ]; then
        echo "EspoCRM is already initialized."
        return 0
    fi
    
    # Wait for database
    wait_for_db
    
    # Create config file if needed
    if [ ! -f /var/www/html/data/config.php ]; then
        echo "Creating initial configuration..."
        
        # Create config.php from environment variables
        php -r "
            \$config = [
                'database' => [
                    'driver' => getenv('ESPOCRM_DATABASE_PLATFORM') ?: 'pdo_mysql',
                    'host' => getenv('ESPOCRM_DATABASE_HOST') ?: 'mariadb',
                    'port' => getenv('ESPOCRM_DATABASE_PORT') ?: '3306',
                    'charset' => 'utf8mb4',
                    'dbname' => getenv('ESPOCRM_DATABASE_NAME') ?: 'espocrm',
                    'user' => getenv('ESPOCRM_DATABASE_USER') ?: 'espocrm',
                    'password' => getenv('ESPOCRM_DATABASE_PASSWORD') ?: 'espocrm_password',
                ],
                'useCache' => true,
                'recordsPerPage' => 20,
                'recordsPerPageSmall' => 5,
                'applicationName' => 'EspoCRM',
                'version' => '8.5.2',
                'timeZone' => getenv('ESPOCRM_DEFAULT_TIMEZONE') ?: 'UTC',
                'dateFormat' => 'DD.MM.YYYY',
                'timeFormat' => 'HH:mm',
                'weekStart' => 1,
                'thousandSeparator' => ',',
                'decimalMark' => '.',
                'exportDelimiter' => ',',
                'currencyList' => ['USD'],
                'defaultCurrency' => 'USD',
                'baseCurrency' => 'USD',
                'currencyRates' => [],
                'language' => getenv('ESPOCRM_DEFAULT_LANGUAGE') ?: 'en_US',
                'languageList' => ['en_US'],
                'siteUrl' => getenv('ESPOCRM_SITE_URL') ?: 'http://localhost',
                'isDeveloperMode' => false,
            ];
            
            file_put_contents('/var/www/html/data/config.php', '<?php return ' . var_export(\$config, true) . ';');
        "
        
        echo "Configuration created."
    fi
    
    # Run database rebuild
    echo "Rebuilding database..."
    cd /var/www/html && php rebuild.php
    
    # Clear cache
    echo "Clearing cache..."
    cd /var/www/html && php clear_cache.php
    
    # Create admin user if specified
    if [ ! -z "$ESPOCRM_ADMIN_USERNAME" ] && [ ! -z "$ESPOCRM_ADMIN_PASSWORD" ]; then
        echo "Creating admin user..."
        php -r "
            require_once 'bootstrap.php';
            \$app = new \Espo\Core\Application();
            \$app->setupSystemUser();
            
            \$entityManager = \$app->getContainer()->get('entityManager');
            
            \$user = \$entityManager->getRepository('User')->where(['userName' => getenv('ESPOCRM_ADMIN_USERNAME')])->findOne();
            
            if (!\$user) {
                \$user = \$entityManager->getEntity('User');
                \$user->set([
                    'userName' => getenv('ESPOCRM_ADMIN_USERNAME'),
                    'firstName' => 'Admin',
                    'lastName' => 'User',
                    'type' => 'admin',
                    'isActive' => true,
                ]);
                
                \$password = getenv('ESPOCRM_ADMIN_PASSWORD');
                \$passwordHash = \$app->getContainer()->get('passwordHash');
                \$user->set('password', \$passwordHash->hash(\$password));
                
                \$entityManager->saveEntity(\$user);
                echo \"Admin user created.\n\";
            } else {
                echo \"Admin user already exists.\n\";
            }
        " || true
    fi
}

# Set proper permissions
echo "Setting permissions..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
chmod -R 775 /var/www/html/data
chmod -R 775 /var/www/html/custom
chmod -R 775 /var/www/html/client/custom

# Initialize EspoCRM if needed
initialize_espocrm

# Setup cron for scheduled jobs
echo "Setting up cron..."
if [ ! -f /etc/cron.d/espocrm ]; then
    echo "* * * * * www-data cd /var/www/html && php cron.php > /dev/null 2>&1" > /etc/cron.d/espocrm
    chmod 0644 /etc/cron.d/espocrm
    crontab /etc/cron.d/espocrm
fi

# Start cron service
service cron start

# Update siteUrl in config.php if SITE_URL is set
if [ -n "$SITE_URL" ] && [ -f /var/www/html/data/config.php ]; then
    echo "Updating siteUrl to ${SITE_URL}..."
    
    # Check if siteUrl exists in config
    if grep -q "'siteUrl'" /var/www/html/data/config.php; then
        # Update existing siteUrl
        sed -i "s|'siteUrl' => '.*'|'siteUrl' => '${SITE_URL}'|" /var/www/html/data/config.php
    else
        # Add siteUrl if it doesn't exist
        sed -i "/return array (/a \ \ 'siteUrl' => '${SITE_URL}'," /var/www/html/data/config.php
    fi
    
    echo "✔ siteUrl updated to ${SITE_URL} in data/config.php"
    
    # Clear cache after updating config
    cd /var/www/html && php clear_cache.php > /dev/null 2>&1 || true
fi

# Ensure proper permissions after any config changes
chown -R www-data:www-data /var/www/html/data
chmod -R 775 /var/www/html/data

echo "Starting Apache..."

# Execute the CMD
exec "$@"