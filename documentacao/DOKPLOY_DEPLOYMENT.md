# Guia de Deployment do EspoCRM com Dokploy

## Índice
1. [Visão Geral](#visão-geral)
2. [Pré-requisitos](#pré-requisitos)
3. [Preparação do Projeto](#preparação-do-projeto)
4. [Configuração do Docker](#configuração-do-docker)
5. [Deployment no Dokploy](#deployment-no-dokploy)
6. [Configurações Pós-Deployment](#configurações-pós-deployment)
7. [Manutenção e Monitoramento](#manutenção-e-monitoramento)
8. [Troubleshooting](#troubleshooting)

## Visão Geral

Este documento descreve o processo completo para fazer o deployment do EspoCRM utilizando Dokploy, uma plataforma open-source alternativa ao Heroku, Vercel e Netlify.

### O que é Dokploy?

Dokploy é uma plataforma de deployment que:
- Utiliza Docker e Traefik para gerenciar aplicações
- Oferece deployment simplificado com suporte a múltiplas aplicações
- É totalmente open-source e self-hosted
- Suporta Docker Compose nativamente

### Arquitetura da Solução

```
┌─────────────────────────────────────────┐
│           Dokploy Platform               │
│  ┌─────────────────────────────────┐    │
│  │     Traefik (Load Balancer)     │    │
│  └────────┬────────────────────────┘    │
│           │                              │
│  ┌────────▼─────────┬──────────────┐    │
│  │   EspoCRM App    │  WebSocket    │    │
│  └────────┬─────────┴──────────────┘    │
│           │                              │
│  ┌────────▼─────────┬──────────────┐    │
│  │    MariaDB       │   Redis       │    │
│  └──────────────────┴──────────────┘    │
└─────────────────────────────────────────┘
```

## Pré-requisitos

### Servidor Dokploy
- Servidor Linux (Ubuntu 22.04+ recomendado)
- Mínimo 2GB RAM, 2 CPU cores
- 20GB+ de espaço em disco
- Docker e Docker Compose instalados
- Dokploy instalado e configurado

### Domínio e SSL
- Domínio apontando para o servidor Dokploy
- SSL será configurado automaticamente via Let's Encrypt

## Preparação do Projeto

### 1. Estrutura de Arquivos

Certifique-se de que o projeto tem a seguinte estrutura:

```
espocrm/
├── docker-compose.yml      # Configuração Docker
├── Dockerfile             # Imagem customizada
├── docker-entrypoint.sh   # Script de inicialização
├── .env.example          # Variáveis de ambiente exemplo
├── .dockerignore         # Arquivos ignorados no build
├── application/          # Código fonte EspoCRM
├── custom/              # Customizações
├── client/              # Frontend
├── data/               # Dados persistentes
└── documentacao/       # Esta documentação
```

### 2. Criar arquivo .dockerignore

```bash
# Criar .dockerignore para otimizar o build
cat > .dockerignore << 'EOF'
.git
.gitignore
*.md
.env
data/logs/*
data/cache/*
data/upload/.thumbs/*
node_modules
.DS_Store
*.log
*.tmp
.vscode
.idea
EOF
```

### 3. Configurar Variáveis de Ambiente

Copie o arquivo `.env.example` para `.env` e configure:

```bash
cp .env.example .env
```

Edite o arquivo `.env` com suas configurações:

```env
# Configurações do Banco de Dados
DB_ROOT_PASSWORD=sua_senha_root_segura
DB_NAME=espocrm_production
DB_USER=espocrm_user
DB_PASSWORD=senha_muito_segura

# Configurações do Admin
ADMIN_USERNAME=admin
ADMIN_PASSWORD=senha_admin_segura

# Configurações do Site
SITE_URL=https://crm.seudominio.com
ESPOCRM_PORT=80

# Configurações de Localização
DEFAULT_LANGUAGE=pt_BR
DEFAULT_TIMEZONE=America/Sao_Paulo
```

## Configuração do Docker

### 1. Docker Compose para Produção

O arquivo `docker-compose.yml` já está configurado com:
- MariaDB para banco de dados
- EspoCRM aplicação principal
- Daemon para jobs agendados
- WebSocket para funcionalidades real-time

### 2. Otimizações para Produção

Adicione um arquivo `docker-compose.prod.yml` para override de produção:

```yaml
version: '3.8'

services:
  mariadb:
    restart: always
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
  
  espocrm:
    restart: always
    environment:
      - NODE_ENV=production
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### 3. Build da Imagem Customizada

Se estiver usando o Dockerfile customizado:

```bash
# Build local para teste
docker build -t espocrm-custom:latest .

# Tag para registry (se usar registry privado)
docker tag espocrm-custom:latest seu-registry.com/espocrm:latest
```

## Deployment no Dokploy

### 1. Instalação do Dokploy

No servidor de produção, instale o Dokploy:

```bash
# Instalação rápida do Dokploy
curl -sSL https://dokploy.com/install.sh | sh

# Ou instalação manual
git clone https://github.com/dokploy/dokploy.git
cd dokploy
docker compose up -d
```

### 2. Acessar Interface do Dokploy

Acesse `http://seu-servidor:3000` e faça o setup inicial:
1. Crie uma conta de administrador
2. Configure o domínio principal
3. Ative SSL com Let's Encrypt

### 3. Criar Nova Aplicação

Na interface do Dokploy:

1. Clique em "New Application"
2. Selecione "Docker Compose"
3. Configure:
   - **Name**: espocrm
   - **Domain**: crm.seudominio.com
   - **Port**: 8080 (porta do container)

### 4. Deploy via Git

#### Opção A: Deploy direto do GitHub

1. Conecte seu repositório GitHub
2. Configure o branch (ex: `main` ou `production`)
3. Configure deploy automático on push

#### Opção B: Deploy manual

1. No servidor, clone o repositório:
```bash
cd /var/dokploy/apps/espocrm
git clone https://github.com/seu-usuario/espocrm.git .
```

2. Configure as variáveis de ambiente no Dokploy UI

3. Execute o deploy:
```bash
dokploy deploy espocrm
```

### 5. Configurar Variáveis de Ambiente no Dokploy

No painel do Dokploy, adicione as variáveis:

```
DB_ROOT_PASSWORD=senha_root_segura
DB_NAME=espocrm_production
DB_USER=espocrm_user
DB_PASSWORD=senha_segura
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin_senha_segura
SITE_URL=https://crm.seudominio.com
DEFAULT_LANGUAGE=pt_BR
DEFAULT_TIMEZONE=America/Sao_Paulo
```

### 6. Configurar Volumes Persistentes

No Dokploy, configure os volumes para persistir dados:

```yaml
volumes:
  - ./data/upload:/var/www/html/data/upload
  - ./data/logs:/var/www/html/data/logs
  - ./custom:/var/www/html/custom
  - mariadb_data:/var/lib/mysql
```

## Configurações Pós-Deployment

### 1. Verificar Status dos Containers

```bash
# Via Dokploy CLI
dokploy ps espocrm

# Ou diretamente via Docker
docker ps | grep espocrm
```

### 2. Acessar o EspoCRM

1. Acesse `https://crm.seudominio.com`
2. Faça login com as credenciais configuradas
3. Complete o setup inicial se necessário

### 3. Configurar Cron Jobs

O container já inclui cron configurado, mas verifique:

```bash
# Verificar se o cron está rodando
docker exec espocrm-daemon ps aux | grep cron

# Ver logs do cron
docker logs espocrm-daemon
```

### 4. Configurar Backup Automático

Crie um script de backup:

```bash
#!/bin/bash
# backup-espocrm.sh

BACKUP_DIR="/backup/espocrm"
DATE=$(date +%Y%m%d_%H%M%S)

# Backup do banco de dados
docker exec espocrm-db mysqldump \
  -u root -p${DB_ROOT_PASSWORD} \
  ${DB_NAME} > ${BACKUP_DIR}/db_${DATE}.sql

# Backup dos arquivos
tar -czf ${BACKUP_DIR}/files_${DATE}.tar.gz \
  /var/dokploy/apps/espocrm/data \
  /var/dokploy/apps/espocrm/custom

# Limpar backups antigos (manter últimos 30 dias)
find ${BACKUP_DIR} -type f -mtime +30 -delete
```

Adicione ao crontab:
```bash
0 2 * * * /path/to/backup-espocrm.sh
```

## Manutenção e Monitoramento

### 1. Monitoramento de Recursos

Use o painel do Dokploy para monitorar:
- Uso de CPU e memória
- Espaço em disco
- Status dos containers
- Logs da aplicação

### 2. Atualização do EspoCRM

Para atualizar o EspoCRM:

```bash
# 1. Fazer backup completo
./backup-espocrm.sh

# 2. Atualizar imagem Docker
docker pull espocrm/espocrm:latest

# 3. Recriar containers via Dokploy
dokploy update espocrm

# 4. Executar rebuild
docker exec espocrm-app php rebuild.php
```

### 3. Otimização de Performance

#### Cache Redis (Opcional)

Adicione Redis ao docker-compose.yml:

```yaml
redis:
  image: redis:7-alpine
  restart: unless-stopped
  volumes:
    - redis_data:/data
  networks:
    - espocrm-network
```

Configure no EspoCRM:
```php
// data/config.php
'cache' => [
    'driver' => 'Redis',
    'host' => 'redis',
    'port' => 6379,
],
```

#### Configurações PHP

Otimize PHP para produção no Dockerfile:

```dockerfile
RUN { \
    echo 'opcache.enable=1'; \
    echo 'opcache.memory_consumption=256'; \
    echo 'opcache.max_accelerated_files=20000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'realpath_cache_size=4096K'; \
    echo 'realpath_cache_ttl=600'; \
} > /usr/local/etc/php/conf.d/opcache-prod.ini
```

### 4. Logs e Debugging

#### Visualizar Logs

```bash
# Logs da aplicação
docker logs -f espocrm-app

# Logs do banco de dados
docker logs -f espocrm-db

# Logs do daemon
docker logs -f espocrm-daemon
```

#### Acessar Container

```bash
# Acessar shell do container
docker exec -it espocrm-app bash

# Executar comandos do EspoCRM
docker exec espocrm-app php command.php <command>
```

## Troubleshooting

### Problemas Comuns

#### 1. Container não inicia

```bash
# Verificar logs
docker logs espocrm-app

# Verificar configuração
docker compose config

# Verificar permissões
docker exec espocrm-app ls -la /var/www/html/data
```

#### 2. Erro de conexão com banco de dados

```bash
# Testar conexão
docker exec espocrm-app php -r "
  \$pdo = new PDO(
    'mysql:host=mariadb;dbname=espocrm',
    'espocrm_user',
    'password'
  );
  echo 'Conexão OK';
"
```

#### 3. Problemas de permissão

```bash
# Corrigir permissões
docker exec espocrm-app chown -R www-data:www-data /var/www/html
docker exec espocrm-app chmod -R 755 /var/www/html
docker exec espocrm-app chmod -R 775 /var/www/html/data
```

#### 4. Cache corrompido

```bash
# Limpar cache
docker exec espocrm-app php clear_cache.php

# Rebuild completo
docker exec espocrm-app php rebuild.php
```

### Comandos Úteis

```bash
# Status dos serviços
dokploy status espocrm

# Reiniciar aplicação
dokploy restart espocrm

# Ver uso de recursos
docker stats espocrm-app espocrm-db espocrm-daemon

# Backup rápido do banco
docker exec espocrm-db mysqldump -u root -p espocrm > backup.sql

# Restore do banco
docker exec -i espocrm-db mysql -u root -p espocrm < backup.sql
```

## Segurança

### 1. Configurações de Segurança

- Use sempre HTTPS (configurado automaticamente pelo Dokploy)
- Configure firewall para permitir apenas portas necessárias
- Use senhas fortes para banco de dados e admin
- Mantenha backups regulares
- Atualize regularmente

### 2. Hardening do Container

Adicione ao Dockerfile:

```dockerfile
# Remover pacotes desnecessários
RUN apt-get remove --purge -y \
    git \
    curl \
    wget \
    && apt-get autoremove -y \
    && apt-get clean

# Configurar usuário não-root
USER www-data
```

### 3. Configurar Firewall

```bash
# UFW (Ubuntu Firewall)
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw allow 3000/tcp # Dokploy UI (restringir IP se possível)
sudo ufw enable
```

## Recursos Adicionais

- [Documentação Dokploy](https://docs.dokploy.com)
- [Documentação EspoCRM](https://docs.espocrm.com)
- [Docker Hub - EspoCRM](https://hub.docker.com/r/espocrm/espocrm)
- [GitHub - EspoCRM](https://github.com/espocrm/espocrm)

## Suporte

Para suporte:
1. Consulte a documentação oficial
2. Verifique os logs da aplicação
3. Abra uma issue no GitHub do projeto
4. Contate o suporte da sua empresa

---

**Última atualização**: Janeiro 2025
**Versão**: 1.0.0
**Autor**: Equipe DevOps