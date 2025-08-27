# Guia de Migração para Dokploy

## Migração de EspoCRM Existente para Dokploy

### Pré-Migração

#### 1. Auditoria do Sistema Atual

```bash
# Verificar versão do EspoCRM
php command.php version

# Verificar tamanho do banco de dados
mysql -u root -p -e "SELECT 
    table_schema AS 'Database',
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
FROM information_schema.tables
WHERE table_schema = 'espocrm'
GROUP BY table_schema;"

# Verificar tamanho dos uploads
du -sh data/upload/

# Listar customizações
ls -la custom/Espo/Custom/
```

#### 2. Backup Completo

```bash
#!/bin/bash
# backup-before-migration.sh

BACKUP_DIR="/backup/migration_$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

echo "1. Fazendo backup do banco de dados..."
mysqldump -u root -p \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    espocrm > $BACKUP_DIR/database.sql

echo "2. Fazendo backup dos arquivos..."
tar -czf $BACKUP_DIR/files.tar.gz \
    data/upload \
    data/config.php \
    custom \
    client/custom

echo "3. Exportando configurações..."
php -r "
    \$config = include 'data/config.php';
    file_put_contents('$BACKUP_DIR/config.json', json_encode(\$config, JSON_PRETTY_PRINT));
"

echo "Backup completo em: $BACKUP_DIR"
```

### Processo de Migração

#### 1. Preparar Ambiente Dokploy

```bash
# No servidor Dokploy
mkdir -p /var/dokploy/apps/espocrm-migration
cd /var/dokploy/apps/espocrm-migration

# Copiar arquivos de configuração Docker
scp user@old-server:/path/to/docker-compose.yml .
scp user@old-server:/path/to/Dockerfile .
scp user@old-server:/path/to/.env .
```

#### 2. Transferir Dados

```bash
# Transferir backup para novo servidor
rsync -avz --progress \
    user@old-server:/backup/migration_* \
    /var/dokploy/apps/espocrm-migration/backup/

# Ou usar SCP para arquivos menores
scp user@old-server:/backup/migration_*/database.sql .
scp user@old-server:/backup/migration_*/files.tar.gz .
```

#### 3. Script de Migração Automatizada

```bash
#!/bin/bash
# migrate-to-dokploy.sh

set -e

echo "=== Migração EspoCRM para Dokploy ==="

# Variáveis
OLD_SERVER="old.server.com"
OLD_USER="user"
OLD_PATH="/var/www/espocrm"
DOKPLOY_APP="espocrm"
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)

# 1. Parar aplicação antiga (opcional)
echo "1. Preparando servidor antigo..."
ssh $OLD_USER@$OLD_SERVER "cd $OLD_PATH && php clear_cache.php"

# 2. Fazer backup no servidor antigo
echo "2. Criando backup no servidor antigo..."
ssh $OLD_USER@$OLD_SERVER "
    mysqldump -u root -p espocrm > /tmp/espocrm_$BACKUP_DATE.sql
    tar -czf /tmp/espocrm_files_$BACKUP_DATE.tar.gz \
        $OLD_PATH/data/upload \
        $OLD_PATH/custom \
        $OLD_PATH/client/custom
"

# 3. Transferir dados
echo "3. Transferindo dados..."
scp $OLD_USER@$OLD_SERVER:/tmp/espocrm_$BACKUP_DATE.sql ./backup/
scp $OLD_USER@$OLD_SERVER:/tmp/espocrm_files_$BACKUP_DATE.tar.gz ./backup/

# 4. Criar aplicação no Dokploy
echo "4. Criando aplicação no Dokploy..."
dokploy create app \
    --name $DOKPLOY_APP \
    --type docker-compose \
    --path /var/dokploy/apps/espocrm-migration

# 5. Restaurar banco de dados
echo "5. Restaurando banco de dados..."
docker exec -i ${DOKPLOY_APP}-mariadb mysql -u root -p < ./backup/espocrm_$BACKUP_DATE.sql

# 6. Restaurar arquivos
echo "6. Restaurando arquivos..."
tar -xzf ./backup/espocrm_files_$BACKUP_DATE.tar.gz -C ./

# 7. Ajustar permissões
echo "7. Ajustando permissões..."
docker exec ${DOKPLOY_APP}-app chown -R www-data:www-data /var/www/html

# 8. Rebuild da aplicação
echo "8. Reconstruindo aplicação..."
docker exec ${DOKPLOY_APP}-app php rebuild.php
docker exec ${DOKPLOY_APP}-app php clear_cache.php

echo "=== Migração completa! ==="
echo "Acesse: https://crm.seudominio.com"
```

#### 4. Validação Pós-Migração

```bash
#!/bin/bash
# validate-migration.sh

echo "=== Validação da Migração ==="

# 1. Verificar containers rodando
echo "1. Status dos containers:"
docker ps | grep espocrm

# 2. Verificar conectividade do banco
echo "2. Teste de conexão com banco:"
docker exec espocrm-app php -r "
    try {
        \$pdo = new PDO('mysql:host=mariadb;dbname=espocrm', 'user', 'pass');
        echo 'Banco de dados: OK\n';
    } catch (Exception \$e) {
        echo 'Erro: ' . \$e->getMessage() . '\n';
    }
"

# 3. Verificar integridade dos dados
echo "3. Contagem de registros:"
docker exec espocrm-mariadb mysql -u root -p -e "
    SELECT 
        (SELECT COUNT(*) FROM user) as users,
        (SELECT COUNT(*) FROM account) as accounts,
        (SELECT COUNT(*) FROM contact) as contacts,
        (SELECT COUNT(*) FROM opportunity) as opportunities;
"

# 4. Verificar arquivos
echo "4. Verificar uploads:"
docker exec espocrm-app ls -la /var/www/html/data/upload/ | head -10

# 5. Testar funcionalidades críticas
echo "5. Teste de API:"
curl -s -o /dev/null -w "%{http_code}" https://crm.seudominio.com/api/v1/App/health

# 6. Verificar logs
echo "6. Últimos logs:"
docker logs --tail 20 espocrm-app
```

### Migração de Dados Específicos

#### 1. Migração Incremental

Para sistemas grandes, use migração incremental:

```bash
#!/bin/bash
# incremental-migration.sh

# Primeira sincronização (com sistema online)
mysqldump --single-transaction --master-data=2 \
    --databases espocrm > initial_dump.sql

# Parar escrita no banco antigo
mysql -e "FLUSH TABLES WITH READ LOCK;"

# Capturar mudanças finais
mysqldump --single-transaction \
    --where="modified > '2024-01-01 00:00:00'" \
    espocrm > incremental_dump.sql

# Aplicar no novo servidor
docker exec -i espocrm-mariadb mysql < initial_dump.sql
docker exec -i espocrm-mariadb mysql < incremental_dump.sql
```

#### 2. Migração de Customizações

```bash
# Copiar entidades customizadas
rsync -avz old-server:/path/to/custom/Espo/Custom/ ./custom/Espo/Custom/

# Copiar layouts customizados
rsync -avz old-server:/path/to/custom/Espo/Custom/Resources/layouts/ \
    ./custom/Espo/Custom/Resources/layouts/

# Copiar scripts customizados
rsync -avz old-server:/path/to/custom/Espo/Custom/Scripts/ \
    ./custom/Espo/Custom/Scripts/

# Rebuild após copiar customizações
docker exec espocrm-app php rebuild.php
```

#### 3. Migração de Integrações

```php
// migrate-integrations.php
<?php
// Script para migrar configurações de integração

$oldConfig = include '/backup/config.php';
$newConfig = [];

// Migrar configurações de email
$newConfig['smtpServer'] = $oldConfig['smtpServer'] ?? '';
$newConfig['smtpPort'] = $oldConfig['smtpPort'] ?? 587;
$newConfig['smtpAuth'] = $oldConfig['smtpAuth'] ?? true;
$newConfig['smtpUsername'] = $oldConfig['smtpUsername'] ?? '';
$newConfig['smtpPassword'] = $oldConfig['smtpPassword'] ?? '';

// Migrar configurações de API
$newConfig['apiUrl'] = str_replace('old.domain.com', 'new.domain.com', 
    $oldConfig['apiUrl'] ?? '');

// Aplicar configurações
file_put_contents('/var/www/html/data/config-integrations.php', 
    '<?php return ' . var_export($newConfig, true) . ';');
```

### Rollback Plan

#### 1. Preparar Rollback

```bash
#!/bin/bash
# prepare-rollback.sh

# Backup do estado atual antes de migrar
docker exec espocrm-mariadb mysqldump espocrm > pre_migration_backup.sql
tar -czf pre_migration_files.tar.gz data/ custom/

# Criar snapshot (se suportado)
docker commit espocrm-app espocrm-app:pre-migration
docker commit espocrm-mariadb espocrm-mariadb:pre-migration
```

#### 2. Executar Rollback

```bash
#!/bin/bash
# rollback.sh

echo "Iniciando rollback..."

# Parar containers atuais
docker-compose down

# Restaurar banco de dados
docker run --rm -v $(pwd):/backup mariadb:10.11 \
    mysql -h old-db-host -u root -p espocrm < /backup/pre_migration_backup.sql

# Restaurar arquivos
rm -rf data/ custom/
tar -xzf pre_migration_files.tar.gz

# Restaurar containers de snapshot
docker run -d --name espocrm-app espocrm-app:pre-migration
docker run -d --name espocrm-mariadb espocrm-mariadb:pre-migration

# Redirecionar DNS de volta (se necessário)
echo "Lembre-se de reverter as configurações de DNS!"
```

### Otimizações Pós-Migração

#### 1. Otimizar Banco de Dados

```sql
-- optimize-database.sql

-- Analisar todas as tabelas
ANALYZE TABLE account, contact, opportunity, lead, user;

-- Otimizar tabelas
OPTIMIZE TABLE account, contact, opportunity, lead, user;

-- Verificar e reparar se necessário
CHECK TABLE account, contact, opportunity, lead, user;

-- Recriar índices se necessário
ALTER TABLE entity_email_address ENGINE=InnoDB;
ALTER TABLE email_address ENGINE=InnoDB;
```

#### 2. Configurar Cache

```php
// config/cache.php
return [
    'cache' => [
        'driver' => 'Redis',
        'host' => 'redis',
        'port' => 6379,
        'database' => 0,
        'ttl' => 3600,
    ],
    'metadata' => [
        'cache' => true,
        'ttl' => 86400,
    ],
];
```

#### 3. Monitoramento

```yaml
# docker-compose.monitoring.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"
    networks:
      - espocrm-network

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - espocrm-network

  node-exporter:
    image: prom/node-exporter:latest
    ports:
      - "9100:9100"
    networks:
      - espocrm-network

volumes:
  prometheus_data:
  grafana_data:
```

### Checklist Final

#### Antes da Migração
- [ ] Backup completo realizado
- [ ] Dados de acesso documentados
- [ ] Janela de manutenção agendada
- [ ] Equipe notificada
- [ ] DNS preparado para mudança
- [ ] Rollback plan testado

#### Durante a Migração
- [ ] Aplicação antiga em modo manutenção
- [ ] Dados transferidos com sucesso
- [ ] Banco de dados restaurado
- [ ] Arquivos restaurados
- [ ] Permissões ajustadas
- [ ] Aplicação reconstruída

#### Após a Migração
- [ ] Todos os containers rodando
- [ ] Login funcionando
- [ ] Emails enviando/recebendo
- [ ] Integrações funcionando
- [ ] Performance adequada
- [ ] Backups configurados
- [ ] Monitoramento ativo
- [ ] DNS atualizado
- [ ] SSL funcionando

### Troubleshooting Migração

#### Problema: Dados corrompidos
```bash
# Verificar integridade
docker exec espocrm-mariadb mysqlcheck -u root -p --all-databases

# Reparar se necessário
docker exec espocrm-mariadb mysqlcheck -u root -p --repair --all-databases
```

#### Problema: Customizações não funcionam
```bash
# Verificar se arquivos foram copiados
docker exec espocrm-app ls -la /var/www/html/custom/

# Rebuild forçado
docker exec espocrm-app php rebuild.php --hard

# Limpar cache completamente
docker exec espocrm-app rm -rf data/cache/*
docker exec espocrm-app php clear_cache.php
```

#### Problema: Performance degradada
```bash
# Verificar recursos
docker stats

# Aumentar recursos no docker-compose.yml
services:
  espocrm:
    mem_limit: 2g
    cpus: '2.0'
```

---

**Última atualização**: Janeiro 2025
**Versão**: 1.0.0
**Tempo estimado de migração**: 2-4 horas (dependendo do tamanho)