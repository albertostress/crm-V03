# Documentação EspoCRM - Deployment com Dokploy

## 📚 Índice de Documentação

Esta pasta contém toda a documentação necessária para fazer o deployment do EspoCRM usando Dokploy, incluindo guias de desenvolvimento, migração e manutenção.

## 📖 Documentos Disponíveis

### 1. [DOKPLOY_DEPLOYMENT.md](./DOKPLOY_DEPLOYMENT.md)
Guia completo e detalhado para deployment em produção com Dokploy.
- Configuração completa do ambiente
- Setup do Dokploy
- Configuração de domínios e SSL
- Monitoramento e manutenção
- Troubleshooting detalhado

### 2. [QUICK_START.md](./QUICK_START.md)
Guia rápido para deployment em 5 minutos.
- Setup mínimo necessário
- Comandos essenciais
- Troubleshooting básico
- Checklist de deployment

### 3. [DOCKER_DEVELOPMENT.md](./DOCKER_DEVELOPMENT.md)
Ambiente de desenvolvimento local com Docker.
- Setup do ambiente de desenvolvimento
- Docker Compose para dev
- Debugging com Xdebug
- Scripts de desenvolvimento
- Workflow de desenvolvimento

### 4. [MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md)
Guia para migrar EspoCRM existente para Dokploy.
- Backup e preparação
- Processo de migração passo a passo
- Migração incremental
- Rollback plan
- Validação pós-migração

## 🚀 Quick Start

### Para Deployment Rápido
```bash
# 1. Clone o repositório
git clone https://github.com/seu-usuario/espocrm.git

# 2. Configure variáveis
cp .env.example .env
nano .env

# 3. Deploy com Dokploy
dokploy deploy espocrm
```

Veja [QUICK_START.md](./QUICK_START.md) para mais detalhes.

### Para Desenvolvimento Local
```bash
# 1. Use o script de desenvolvimento
chmod +x dev.sh
./dev.sh start

# 2. Acesse
# http://localhost:8080 - EspoCRM
# http://localhost:8081 - PHPMyAdmin
# http://localhost:1080 - MailCatcher
```

Veja [DOCKER_DEVELOPMENT.md](./DOCKER_DEVELOPMENT.md) para setup completo.

## 📋 Requisitos

### Mínimos
- Docker 20.10+
- Docker Compose 2.0+
- 2GB RAM
- 10GB Disco
- Ubuntu 20.04+ ou similar

### Recomendados
- Docker 24.0+
- Docker Compose 2.20+
- 4GB RAM
- 20GB Disco SSD
- Ubuntu 22.04 LTS

## 🏗️ Arquitetura

```
┌─────────────────────────────────┐
│         Load Balancer           │
│          (Traefik)              │
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│       EspoCRM Container         │
│    (PHP 8.2 + Apache + App)     │
└────────────┬────────────────────┘
             │
     ┌───────┴───────┐
     │               │
┌────▼────┐    ┌────▼────┐
│MariaDB  │    │  Redis  │
│Database │    │  Cache  │
└─────────┘    └─────────┘
```

## 🔧 Configurações

### Variáveis de Ambiente Principais

```env
# Banco de Dados
DB_NAME=espocrm
DB_USER=espocrm
DB_PASSWORD=senha_segura

# Admin
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin_senha

# Site
SITE_URL=https://crm.exemplo.com
DEFAULT_LANGUAGE=pt_BR
DEFAULT_TIMEZONE=America/Sao_Paulo
```

### Portas Utilizadas

| Serviço | Porta | Descrição |
|---------|-------|-----------|
| EspoCRM | 8080 | Aplicação principal |
| MariaDB | 3306 | Banco de dados |
| WebSocket | 8081 | Real-time features |
| PHPMyAdmin | 8082 | Gerenciador DB (dev) |
| MailCatcher | 1080 | Email testing (dev) |

## 🛠️ Comandos Úteis

### Docker
```bash
# Ver logs
docker logs -f espocrm-app

# Acessar container
docker exec -it espocrm-app bash

# Limpar cache
docker exec espocrm-app php clear_cache.php

# Rebuild
docker exec espocrm-app php rebuild.php
```

### Dokploy
```bash
# Status da aplicação
dokploy status espocrm

# Deploy
dokploy deploy espocrm

# Restart
dokploy restart espocrm

# Logs
dokploy logs espocrm
```

### Backup
```bash
# Backup do banco
docker exec espocrm-db mysqldump -u root -p espocrm > backup.sql

# Backup dos arquivos
tar -czf files_backup.tar.gz data/ custom/

# Restore do banco
docker exec -i espocrm-db mysql -u root -p espocrm < backup.sql
```

## 🔐 Segurança

### Checklist de Segurança
- ✅ Use HTTPS sempre (SSL via Let's Encrypt)
- ✅ Senhas fortes para banco e admin
- ✅ Firewall configurado (apenas portas necessárias)
- ✅ Backups automáticos diários
- ✅ Monitoramento de recursos
- ✅ Updates regulares de segurança
- ✅ Logs centralizados
- ✅ Rate limiting configurado

### Hardening
```bash
# Configurar firewall
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP
ufw allow 443/tcp  # HTTPS
ufw enable

# Fail2ban para proteção
apt install fail2ban
systemctl enable fail2ban
```

## 📊 Monitoramento

### Métricas Importantes
- CPU: < 80% utilização
- Memória: < 85% utilização
- Disco: < 90% utilização
- Response time: < 500ms
- Uptime: > 99.9%

### Ferramentas Recomendadas
- Prometheus + Grafana
- Uptime Kuma
- Netdata
- New Relic (comercial)

## 🆘 Suporte e Troubleshooting

### Problemas Comuns

| Problema | Solução |
|----------|---------|
| Container não inicia | Verificar logs: `docker logs espocrm-app` |
| Erro de permissão | `docker exec espocrm-app chown -R www-data:www-data /var/www/html` |
| Cache corrompido | `docker exec espocrm-app php clear_cache.php` |
| Banco não conecta | Verificar variáveis de ambiente e rede Docker |

### Logs

```bash
# Logs da aplicação
tail -f data/logs/espo.log

# Logs do Apache
docker logs espocrm-app

# Logs do banco
docker logs espocrm-db

# Logs do sistema
journalctl -u docker -f
```

## 📚 Recursos Adicionais

### Documentação Oficial
- [EspoCRM Docs](https://docs.espocrm.com)
- [Dokploy Docs](https://docs.dokploy.com)
- [Docker Docs](https://docs.docker.com)

### Comunidade
- [EspoCRM Forum](https://forum.espocrm.com)
- [EspoCRM GitHub](https://github.com/espocrm/espocrm)
- [Dokploy GitHub](https://github.com/dokploy/dokploy)

### Tutoriais e Guias
- [EspoCRM Development](https://docs.espocrm.com/development/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [DevOps with Docker](https://devopswithdocker.com/)

## 🤝 Contribuindo

Para contribuir com esta documentação:

1. Fork o repositório
2. Crie uma branch: `git checkout -b docs/melhoria`
3. Faça suas alterações
4. Commit: `git commit -m "docs: descrição da melhoria"`
5. Push: `git push origin docs/melhoria`
6. Abra um Pull Request

## 📄 Licença

Esta documentação está sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.

## 📞 Contato

- **Email**: suporte@exemplo.com
- **Issues**: [GitHub Issues](https://github.com/seu-usuario/espocrm/issues)
- **Chat**: [Discord/Slack]

---

**Última Atualização**: Janeiro 2025  
**Versão da Documentação**: 1.0.0  
**Mantido por**: Equipe DevOps