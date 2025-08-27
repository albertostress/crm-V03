# Quick Start - Deploy EspoCRM com Dokploy

## Deployment Rápido (5 minutos)

### 1. Preparar Arquivos

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/espocrm.git
cd espocrm

# Configure variáveis de ambiente
cp .env.example .env
nano .env  # Edite com suas configurações
```

### 2. Instalar Dokploy no Servidor

```bash
# Em seu servidor de produção
curl -sSL https://dokploy.com/install.sh | sh
```

### 3. Deploy via Interface Dokploy

1. Acesse: `http://seu-servidor:3000`
2. Crie nova aplicação → Docker Compose
3. Configure:
   - **Nome**: espocrm
   - **Domínio**: crm.seudominio.com
   - **Repositório**: Link do seu GitHub
   - **Branch**: main

4. Adicione variáveis de ambiente:
```
DB_PASSWORD=senha_segura
ADMIN_PASSWORD=admin_senha
SITE_URL=https://crm.seudominio.com
```

5. Clique em "Deploy"

### 4. Acessar EspoCRM

- URL: `https://crm.seudominio.com`
- Login: admin / [senha configurada]

## Comandos Essenciais

```bash
# Ver status
dokploy status espocrm

# Ver logs
dokploy logs espocrm

# Reiniciar
dokploy restart espocrm

# Backup do banco
docker exec espocrm-db mysqldump -u root -p espocrm > backup.sql

# Limpar cache
docker exec espocrm-app php clear_cache.php
```

## Estrutura Mínima Necessária

```
espocrm/
├── docker-compose.yml    # Obrigatório
├── .env                  # Configurações
└── Dockerfile           # Opcional (se usar imagem custom)
```

## Checklist Pré-Deploy

- [ ] Servidor com Docker instalado
- [ ] Domínio apontando para o servidor
- [ ] Arquivo docker-compose.yml configurado
- [ ] Variáveis de ambiente definidas
- [ ] Backup dos dados (se migração)

## Troubleshooting Rápido

### Container não inicia
```bash
docker logs espocrm-app
```

### Erro de permissão
```bash
docker exec espocrm-app chown -R www-data:www-data /var/www/html
```

### Banco não conecta
```bash
docker exec espocrm-app ping mariadb
```

### Cache corrompido
```bash
docker exec espocrm-app php clear_cache.php
docker exec espocrm-app php rebuild.php
```

## Próximos Passos

1. Configure backups automáticos
2. Ative monitoramento
3. Configure SSL (automático com Dokploy)
4. Personalize o EspoCRM

Para documentação completa, veja [DOKPLOY_DEPLOYMENT.md](./DOKPLOY_DEPLOYMENT.md)