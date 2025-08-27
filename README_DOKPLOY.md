# EspoCRM - Pronto para Dokploy 🚀

## Arquivos Essenciais (já configurados)

✅ **docker-compose.yml** - Configurado para build local com suas customizações
✅ **Dockerfile** - Build customizado que preserva a pasta `/custom`
✅ **.env.example** - Template de variáveis de ambiente
✅ **.env.production** - Variáveis para produção (configure no Dokploy)

## Como fazer Deploy no Dokploy

### 1. No Painel Dokploy

1. **Nova Aplicação** → **Docker Compose**
2. **Git Repository**: `https://github.com/albertostress/crm-V03.git`
3. **Branch**: `master`

### 2. Variáveis de Ambiente (configurar no Dokploy)

```env
DB_ROOT_PASSWORD=sua_senha_root_segura
DB_NAME=espocrm
DB_USER=espocrm
DB_PASSWORD=sua_senha_db_segura
ADMIN_USERNAME=admin
ADMIN_PASSWORD=sua_senha_admin_segura
SITE_URL=https://seu-dominio.com
DEFAULT_LANGUAGE=pt_BR
DEFAULT_TIMEZONE=America/Sao_Paulo
```

### 3. Deploy

Clique em **Deploy** - O Dokploy faz tudo automaticamente:
- Build da imagem com suas customizações
- Start dos containers
- Configuração SSL com Let's Encrypt

### 4. Pós-Deploy (se necessário)

No terminal do Dokploy:
```bash
# Limpar cache
docker exec espocrm-app php clear_cache.php

# Rebuild
docker exec espocrm-app php rebuild.php
```

## Por que funciona?

- O `docker-compose.yml` usa `build: .` em vez de `image: espocrm/espocrm:latest`
- Isso força o Dokploy a construir a imagem localmente
- Suas customizações em `/custom` são preservadas no build
- Não depende da imagem oficial que pode sobrescrever suas modificações

## Suporte

- GitHub: https://github.com/albertostress/crm-V03
- Documentação EspoCRM: https://docs.espocrm.com
- Documentação Dokploy: https://docs.dokploy.com