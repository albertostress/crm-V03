# Ambiente de Desenvolvimento Docker para EspoCRM

## Setup Local com Docker

### 1. Configuração Inicial

```bash
# Clone o projeto
git clone https://github.com/seu-usuario/espocrm.git
cd espocrm

# Copie as variáveis de ambiente
cp .env.example .env.local

# Edite para desenvolvimento
nano .env.local
```

### 2. Docker Compose para Desenvolvimento

Crie um `docker-compose.dev.yml`:

```yaml
version: '3.8'

services:
  mariadb:
    image: mariadb:10.11
    ports:
      - "3306:3306"  # Expor para acesso externo
    environment:
      MARIADB_ROOT_PASSWORD: devroot
      MARIADB_DATABASE: espocrm_dev
      MARIADB_USER: espocrm_dev
      MARIADB_PASSWORD: devpass
    volumes:
      - ./data/mysql:/var/lib/mysql

  espocrm:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "8080:80"
    environment:
      ESPOCRM_DATABASE_HOST: mariadb
      ESPOCRM_DATABASE_NAME: espocrm_dev
      ESPOCRM_DATABASE_USER: espocrm_dev
      ESPOCRM_DATABASE_PASSWORD: devpass
      ESPOCRM_SITE_URL: http://localhost:8080
      ESPOCRM_DEFAULT_LANGUAGE: pt_BR
      ESPOCRM_DEFAULT_TIMEZONE: America/Sao_Paulo
      # Modo desenvolvimento
      ESPOCRM_IS_DEV_MODE: "true"
    volumes:
      # Mount do código fonte para hot-reload
      - ./application:/var/www/html/application
      - ./client:/var/www/html/client
      - ./custom:/var/www/html/custom
      - ./data:/var/www/html/data
    depends_on:
      - mariadb

  # PHPMyAdmin para gerenciar banco
  phpmyadmin:
    image: phpmyadmin:latest
    ports:
      - "8081:80"
    environment:
      PMA_HOST: mariadb
      PMA_USER: root
      PMA_PASSWORD: devroot
    depends_on:
      - mariadb

  # Mailcatcher para testar emails
  mailcatcher:
    image: schickling/mailcatcher
    ports:
      - "1080:1080"  # Interface web
      - "1025:1025"  # SMTP
```

### 3. Dockerfile para Desenvolvimento

Crie `Dockerfile.dev`:

```dockerfile
FROM php:8.2-apache

# Instalar extensões necessárias
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    libldap2-dev \
    libxml2-dev \
    libonig-dev \
    git \
    vim \
    nano \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        gd \
        pdo \
        pdo_mysql \
        mysqli \
        ldap \
        zip \
        bcmath \
        mbstring

# Instalar Xdebug para debugging
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug

# Configurar Xdebug
RUN echo "xdebug.mode=develop,debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Configurações PHP para desenvolvimento
RUN { \
    echo 'display_errors=On'; \
    echo 'error_reporting=E_ALL'; \
    echo 'memory_limit=512M'; \
    echo 'max_execution_time=300'; \
    echo 'post_max_size=100M'; \
    echo 'upload_max_filesize=100M'; \
} > /usr/local/etc/php/conf.d/dev.ini

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Habilitar mod_rewrite
RUN a2enmod rewrite

# Configurar Apache
RUN { \
    echo '<VirtualHost *:80>'; \
    echo '    DocumentRoot /var/www/html/public'; \
    echo '    <Directory /var/www/html/public>'; \
    echo '        Options Indexes FollowSymLinks'; \
    echo '        AllowOverride All'; \
    echo '        Require all granted'; \
    echo '    </Directory>'; \
    echo '    SetEnv APPLICATION_ENV development'; \
    echo '</VirtualHost>'; \
} > /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html

# Instalar Node.js para desenvolvimento frontend
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Copiar arquivos
COPY . .

# Instalar dependências
RUN composer install --dev
RUN npm install

# Permissões
RUN chown -R www-data:www-data /var/www/html

CMD ["apache2-foreground"]
```

### 4. Scripts de Desenvolvimento

Crie `dev.sh`:

```bash
#!/bin/bash

# Script de desenvolvimento para EspoCRM

case "$1" in
    start)
        echo "Iniciando ambiente de desenvolvimento..."
        docker-compose -f docker-compose.dev.yml up -d
        echo "EspoCRM: http://localhost:8080"
        echo "PHPMyAdmin: http://localhost:8081"
        echo "MailCatcher: http://localhost:1080"
        ;;
    
    stop)
        echo "Parando ambiente..."
        docker-compose -f docker-compose.dev.yml down
        ;;
    
    rebuild)
        echo "Reconstruindo containers..."
        docker-compose -f docker-compose.dev.yml down
        docker-compose -f docker-compose.dev.yml build --no-cache
        docker-compose -f docker-compose.dev.yml up -d
        ;;
    
    logs)
        docker-compose -f docker-compose.dev.yml logs -f espocrm
        ;;
    
    shell)
        docker exec -it espocrm-espocrm-1 bash
        ;;
    
    clear-cache)
        docker exec espocrm-espocrm-1 php clear_cache.php
        ;;
    
    rebuild-app)
        docker exec espocrm-espocrm-1 php rebuild.php
        ;;
    
    composer)
        shift
        docker exec espocrm-espocrm-1 composer "$@"
        ;;
    
    npm)
        shift
        docker exec espocrm-espocrm-1 npm "$@"
        ;;
    
    test)
        docker exec espocrm-espocrm-1 vendor/bin/phpunit
        ;;
    
    *)
        echo "Uso: ./dev.sh {start|stop|rebuild|logs|shell|clear-cache|rebuild-app|composer|npm|test}"
        exit 1
        ;;
esac
```

Torne o script executável:
```bash
chmod +x dev.sh
```

### 5. Configuração VSCode

Crie `.vscode/launch.json` para debugging:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Listen for Xdebug",
            "type": "php",
            "request": "launch",
            "port": 9003,
            "pathMappings": {
                "/var/www/html": "${workspaceFolder}"
            },
            "xdebugSettings": {
                "max_data": 65535,
                "show_hidden": 1,
                "max_children": 100,
                "max_depth": 5
            }
        }
    ]
}
```

### 6. Desenvolvimento Frontend

Para desenvolvimento frontend com hot-reload:

```bash
# Instalar dependências
./dev.sh npm install

# Watch mode para desenvolvimento
./dev.sh npm run watch

# Build para produção
./dev.sh npm run build
```

### 7. Testes

#### PHPUnit

```bash
# Rodar todos os testes
./dev.sh test

# Rodar teste específico
./dev.sh composer test -- --filter TestClassName

# Com coverage
./dev.sh composer test -- --coverage-html coverage
```

#### PHPStan

```bash
# Análise estática
./dev.sh composer phpstan
```

### 8. Debug e Logs

#### Ver logs em tempo real
```bash
# Logs do Apache
./dev.sh logs

# Logs do EspoCRM
docker exec espocrm-espocrm-1 tail -f data/logs/espo.log
```

#### Debug com Xdebug
1. Configure breakpoints no VSCode
2. Inicie o debugging (F5)
3. Acesse a aplicação no navegador

### 9. Banco de Dados

#### Acessar MySQL CLI
```bash
docker exec -it espocrm-mariadb-1 mysql -u root -pdevroot espocrm_dev
```

#### Importar/Exportar banco
```bash
# Export
docker exec espocrm-mariadb-1 mysqldump -u root -pdevroot espocrm_dev > backup.sql

# Import
docker exec -i espocrm-mariadb-1 mysql -u root -pdevroot espocrm_dev < backup.sql
```

### 10. Comandos Úteis

```bash
# Limpar cache
./dev.sh clear-cache

# Rebuild da aplicação
./dev.sh rebuild-app

# Instalar dependência Composer
./dev.sh composer require vendor/package

# Instalar dependência NPM
./dev.sh npm install package-name

# Acessar shell do container
./dev.sh shell

# Ver uso de recursos
docker stats

# Limpar tudo (CUIDADO!)
docker-compose -f docker-compose.dev.yml down -v
```

## Workflow de Desenvolvimento

### 1. Desenvolvimento de Feature

```bash
# 1. Criar branch
git checkout -b feature/nova-funcionalidade

# 2. Iniciar ambiente
./dev.sh start

# 3. Desenvolver e testar
# ... fazer mudanças ...
./dev.sh clear-cache
./dev.sh rebuild-app

# 4. Rodar testes
./dev.sh test

# 5. Commit e push
git add .
git commit -m "feat: nova funcionalidade"
git push origin feature/nova-funcionalidade
```

### 2. Debug de Issues

```bash
# 1. Reproduzir o bug
./dev.sh start

# 2. Ativar logs detalhados
docker exec espocrm-espocrm-1 sed -i 's/"level": "WARNING"/"level": "DEBUG"/' data/config.php

# 3. Ver logs
./dev.sh logs

# 4. Debug com Xdebug no VSCode
# Configurar breakpoints e iniciar debugging
```

## Problemas Comuns

### Permissões
```bash
docker exec espocrm-espocrm-1 chown -R www-data:www-data /var/www/html
```

### Cache não limpa
```bash
docker exec espocrm-espocrm-1 rm -rf data/cache/*
./dev.sh rebuild-app
```

### Composer/NPM lento
```bash
# Use cache local
docker-compose -f docker-compose.dev.yml build --build-arg COMPOSER_CACHE_DIR=/tmp
```

### Port já em uso
```bash
# Mudar porta no docker-compose.dev.yml
# Ou parar serviço conflitante
sudo lsof -i :8080
sudo kill -9 <PID>
```

## Dicas de Performance

1. **Use volumes nomeados** para node_modules e vendor
2. **Configure Xdebug apenas quando necessário**
3. **Use .dockerignore** para excluir arquivos desnecessários
4. **Configure cache do Composer/NPM**
5. **Use multi-stage builds** quando possível

## Recursos Adicionais

- [Documentação Docker](https://docs.docker.com)
- [Documentação EspoCRM Development](https://docs.espocrm.com/development/)
- [PHP Xdebug](https://xdebug.org/docs)
- [Docker Compose](https://docs.docker.com/compose/)

---

**Última atualização**: Janeiro 2025
**Versão**: 1.0.0