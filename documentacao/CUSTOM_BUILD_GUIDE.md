# Guia de Build Customizado para EspoCRM

## Por que usar Build Local?

Quando você usa a imagem oficial `espocrm/espocrm:latest`, suas customizações em `/custom` e módulos personalizados podem ser sobrescritos. Para garantir que suas modificações sejam preservadas, usamos um build local.

## Como Funciona

### 1. Estrutura Modificada

```yaml
# docker-compose.yml
services:
  espocrm:
    # Em vez de:
    # image: espocrm/espocrm:latest
    
    # Usamos:
    build:
      context: .
      dockerfile: Dockerfile
    image: espocrm-custom:latest
```

### 2. Build da Imagem Customizada

O Dockerfile agora:
- Copia TODOS os arquivos do projeto
- Preserva a pasta `/custom` com suas customizações
- Preserva `/client/custom` com customizações frontend
- Preserva `/application/Espo/Modules` com seus módulos

## Comandos de Build

### Build para Desenvolvimento

```bash
# Build e iniciar em modo desenvolvimento
./build-and-deploy.sh development

# Ou manualmente
docker-compose build
docker-compose up -d
```

### Build para Produção

```bash
# Build para produção
./build-and-deploy.sh production

# Build forçado (limpa cache)
./build-and-deploy.sh production force

# Build e exportar imagem
./build-and-deploy.sh production normal export
```

### Build Manual

```bash
# Build da imagem
docker build -t espocrm-custom:latest .

# Verificar se a imagem foi criada
docker images | grep espocrm-custom

# Iniciar containers
docker-compose up -d
```

## Deploy no Dokploy

### Método 1: Build no Dokploy

1. Faça push do código para GitHub:
```bash
git add .
git commit -m "feat: customizações do EspoCRM"
git push origin master
```

2. No Dokploy:
   - Configure para fazer build da imagem
   - Use o Dockerfile do repositório
   - A imagem será construída com suas customizações

### Método 2: Registry Privado

1. Configure um registry privado:
```bash
export DOCKER_REGISTRY=seu-registry.com
```

2. Build e push:
```bash
# Build
docker build -t espocrm-custom:latest .

# Tag
docker tag espocrm-custom:latest $DOCKER_REGISTRY/espocrm-custom:latest

# Push
docker push $DOCKER_REGISTRY/espocrm-custom:latest
```

3. No Dokploy, configure o docker-compose.yml:
```yaml
services:
  espocrm:
    image: seu-registry.com/espocrm-custom:latest
```

### Método 3: Exportar/Importar Imagem

1. Exportar localmente:
```bash
./build-and-deploy.sh production normal export
# Ou
docker save espocrm-custom:latest | gzip > espocrm-custom.tar.gz
```

2. Transferir para servidor:
```bash
scp espocrm-custom.tar.gz user@servidor:/path/
```

3. Importar no servidor:
```bash
docker load < espocrm-custom.tar.gz
```

## Verificar Customizações

### Após o Build

```bash
# Verificar se customizações estão na imagem
docker run --rm espocrm-custom:latest ls -la /var/www/html/custom/

# Verificar módulos
docker run --rm espocrm-custom:latest ls -la /var/www/html/application/Espo/Modules/

# Verificar versão
docker run --rm espocrm-custom:latest cat /var/www/html/application/Espo/Resources/defaults/config.php | grep version
```

### Após Deploy

```bash
# Verificar no container rodando
docker exec espocrm-app ls -la /var/www/html/custom/

# Verificar se customizações estão ativas
docker exec espocrm-app php command.php app-info
```

## Desenvolvimento Local

### Usar docker-compose.override.yml

Para desenvolvimento, o `docker-compose.override.yml` monta os diretórios locais:

```yaml
services:
  espocrm:
    volumes:
      - ./application:/var/www/html/application
      - ./client:/var/www/html/client
      - ./custom:/var/www/html/custom
```

Isso permite editar código localmente e ver mudanças imediatamente.

### Desabilitar Override

Para testar como produção:
```bash
# Renomear temporariamente
mv docker-compose.override.yml docker-compose.override.yml.bak

# Testar
docker-compose up -d

# Restaurar
mv docker-compose.override.yml.bak docker-compose.override.yml
```

## Troubleshooting

### Customizações não aparecem

1. Verificar se o build foi feito:
```bash
docker images | grep espocrm-custom
```

2. Forçar rebuild:
```bash
docker-compose build --no-cache
docker-compose up -d --force-recreate
```

3. Verificar logs:
```bash
docker-compose logs espocrm
```

### Imagem muito grande

1. Limpar cache antes do build:
```bash
rm -rf data/cache/*
rm -rf data/logs/*
rm -rf node_modules
```

2. Usar multi-stage build (já configurado)

3. Verificar .dockerignore

### Build falha

1. Verificar memória disponível:
```bash
docker system df
docker system prune -a
```

2. Build com menos recursos:
```bash
docker build --memory="1g" --memory-swap="2g" -t espocrm-custom:latest .
```

## Melhores Práticas

### 1. Versionamento

Tag suas imagens com versões:
```bash
docker build -t espocrm-custom:v1.0.0 .
docker tag espocrm-custom:v1.0.0 espocrm-custom:latest
```

### 2. Backup antes de Atualizar

```bash
# Backup da imagem atual
docker tag espocrm-custom:latest espocrm-custom:backup-$(date +%Y%m%d)

# Se algo der errado, restaurar
docker tag espocrm-custom:backup-20250827 espocrm-custom:latest
```

### 3. Testes

Sempre teste o build localmente:
```bash
# Build
./build-and-deploy.sh development

# Testar
curl http://localhost:8080/api/v1/App/health

# Ver logs
docker-compose logs -f espocrm
```

### 4. CI/CD

Configure GitHub Actions para build automático:
```yaml
# .github/workflows/build.yml
- name: Build Docker image
  run: |
    docker build -t espocrm-custom:${{ github.sha }} .
    docker tag espocrm-custom:${{ github.sha }} espocrm-custom:latest
```

## Comandos Úteis

```bash
# Ver tamanho da imagem
docker images espocrm-custom --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# Inspecionar imagem
docker inspect espocrm-custom:latest

# Ver layers da imagem
docker history espocrm-custom:latest

# Executar comando na imagem (sem iniciar container)
docker run --rm espocrm-custom:latest php -v

# Comparar com imagem oficial
docker pull espocrm/espocrm:latest
docker run --rm espocrm/espocrm:latest ls /var/www/html/custom
docker run --rm espocrm-custom:latest ls /var/www/html/custom
```

## Resumo

✅ **Vantagens do Build Local:**
- Customizações sempre preservadas
- Controle total sobre o ambiente
- Possibilidade de adicionar ferramentas extras
- Configurações específicas do projeto

❌ **Desvantagens:**
- Build demora mais que pull
- Imagem pode ficar maior
- Precisa manter Dockerfile atualizado

## Suporte

Se tiver problemas com o build customizado:
1. Verifique os logs: `docker-compose logs`
2. Consulte a documentação Docker
3. Abra uma issue no GitHub do projeto

---

**Última atualização**: Janeiro 2025
**Versão**: 1.0.0