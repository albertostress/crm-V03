<?php
return array (
  'database' => 
  array (
    'driver' => 'pdo_mysql',
    'host' => 'espocrm-db',
    'port' => '3306',
    'charset' => 'utf8mb4',
    'dbname' => 'espocrm',
    'user' => 'espocrm',
    'password' => 'espocrm_password',
  ),
  'useCache' => true,
  'recordsPerPage' => 20,
  'recordsPerPageSmall' => 5,
  'applicationName' => 'EspoCRM',
  'version' => '8.5.2',
  'timeZone' => 'UTC',
  'dateFormat' => 'DD.MM.YYYY',
  'timeFormat' => 'HH:mm',
  'weekStart' => 1,
  'thousandSeparator' => ',',
  'decimalMark' => '.',
  'exportDelimiter' => ',',
  'currencyList' => 
  array (
    0 => 'USD',
  ),
  'defaultCurrency' => 'USD',
  'baseCurrency' => 'USD',
  'currencyRates' => 
  array (
  ),
  'language' => 'en_US',
  'languageList' => 
  array (
    0 => 'en_US',
  ),
  'siteUrl' => 'https://crm.kwameoilandgas.ao',
  'isDeveloperMode' => false,
  'isInstalled' => true,
  'passwordSalt' => '7f8a9b6c5d4e3f2g1h',
  'cryptKey' => 'a1b2c3d4e5f6g7h8i9j0',
  'hashSecretKey' => 'z9y8x7w6v5u4t3s2r1q0',
  'defaultPermissions' => 
  array (
    'user' => 33,
    'group' => 33,
  ),
  'actualDatabaseType' => 'mariadb',
  'actualDatabaseVersion' => '10.11.0',
);