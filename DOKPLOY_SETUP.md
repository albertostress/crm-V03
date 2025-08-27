# Setup Simples para Dokploy

## 1. No Servidor Dokploy

### Instalar Dokploy (se ainda não tiver)
```bash
curl -sSL https://dokploy.com/install.sh | sh
```

## 2. No Painel Dokploy

1. **Criar Nova Aplicação**
   - Tipo: `Docker Compose`
   - Nome: `espocrm`
   - Git Repository: `https://github.com/albertostress/crm-V03.git`
   - Branch: `master`

2. **Configurar Variáveis de Ambiente**
   
No painel do Dokploy, adicione estas variáveis:

```env
# Banco de Dados
DB_ROOT_PASSWORD=senha_root_segura_123
DB_NAME=espocrm
DB_USER=espocrm
DB_PASSWORD=senha_db_segura_456

# Admin
ADMIN_USERNAME=admin
ADMIN_PASSWORD=senha_admin_segura_789

# Site
SITE_URL=https://seu-dominio.com
DEFAULT_LANGUAGE=pt_BR
DEFAULT_TIMEZONE=America/Sao_Paulo
```

3. **Configurar Domínio**
   - Domain: `seu-dominio.com`
   - SSL: `Let's Encrypt` (automático)
   - Port: `8080` (porta do container)

## 3. Deploy

No Dokploy, clique em **Deploy** e pronto!

O Dokploy vai:
- ✅ Fazer pull do código do GitHub
- ✅ Ler o `docker-compose.yml`
- ✅ Fazer build da imagem local (preservando customizações)
- ✅ Iniciar todos os containers
- ✅ Configurar SSL automaticamente

## 4. Verificar

Após o deploy, acesse:
- Site: `https://seu-dominio.com`
- Login: admin / [senha configurada]

## Arquivos Importantes no Projeto

O Dokploy precisa apenas destes arquivos:

```
espocrm/
├── docker-compose.yml    # ✅ Configuração dos containers
├── Dockerfile           # ✅ Build com customizações
├── .env.example        # ✅ Template de variáveis
└── [seu código]        # ✅ Todo o código do EspoCRM
```

## Comandos Úteis (executar no Dokploy)

Se precisar executar comandos após o deploy:

```bash
# Limpar cache
docker exec espocrm-app php clear_cache.php

# Rebuild
docker exec espocrm-app php rebuild.php

# Ver logs
docker logs espocrm-app
```

## Pronto! 🚀

Não precisa de scripts complexos. O Dokploy gerencia tudo!