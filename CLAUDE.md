# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

EspoCRM is an open-source CRM platform with a single-page application frontend and REST API backend written in PHP. The codebase follows SOLID principles, utilizes dependency injection, interfaces, static typing, and generics.

## Key Architecture

### Technology Stack
- **Backend**: PHP 8.2-8.4, follows SOLID principles with extensive DI
- **Frontend**: Single-page application using Backbone.js, RequireJS, Handlebars
- **Database**: MySQL 8.0+, MariaDB 10.3+, or PostgreSQL 15+
- **Build Tools**: Grunt for frontend build, Composer for PHP dependencies
- **Testing**: PHPUnit for unit/integration tests, PHPStan level 8 for static analysis

### Directory Structure
- `application/Espo/` - Core backend application code
  - `Controllers/` - REST API controllers
  - `Services/` - Business logic services
  - `Entities/` - Entity definitions
  - `Repositories/` - Data access layer
  - `Core/` - Core framework components
  - `ORM/` - Object-relational mapping
  - `Tools/` - Utility tools
  - `Hooks/` - Entity hooks
  - `Classes/` - Various helper classes
- `client/` - Frontend JavaScript application
  - `src/` - Main source files
  - `res/` - Resources (templates, layouts)
  - `modules/` - Frontend modules
  - `lib/` - Generated bundles
- `custom/` - Custom code and modules
  - `Espo/Custom/` - Custom PHP code
  - `Espo/Modules/` - Custom modules
- `frontend/` - Frontend build configuration
  - `less/` - LESS stylesheets for themes
- `data/` - Runtime data (cache, logs, uploads)
- `vendor/` - Composer dependencies
- `node_modules/` - NPM dependencies

### Metadata System
Metadata is central to EspoCRM, defining entities, fields, relationships, layouts, and more. Located in:
- `application/Espo/Resources/metadata/`
- `custom/Espo/Custom/Resources/metadata/`
- All metadata follows JSON Schema for IDE autocompletion

## Development Commands

### Build Commands
```bash
# Full production build
npm run build

# Development build (no minification)
npm run build-dev

# Build for running tests
npm run build-test

# Build only frontend (libs and CSS)
npm run build-frontend
```

### Testing Commands
```bash
# Run unit tests
npm run unit-tests
# Or directly: php vendor/bin/phpunit ./tests/unit

# Run integration tests
npm run integration-tests
# Or directly: php vendor/bin/phpunit ./tests/integration

# Run PHPStan static analysis (level 8)
npm run sa
# Or directly: php vendor/bin/phpstan
```

### Cache Management
```bash
# Clear cache (required after metadata/layout changes)
php clear_cache.php

# Rebuild application (clear cache + rebuild database)
php rebuild.php
```

### Console Commands
```bash
# Run console command
php command.php <command-name>

# Run cron jobs
php cron.php

# Run daemon (for job processing)
php daemon.php
```

## Key Concepts

### Dependency Injection
The application uses a DI container extensively. Services are defined in:
- `application/Espo/Core/Container/` - Core container configuration
- Bindings in `application/Espo/Binding.php`
- Module bindings in `Modules/*/Binding.php`

### Entity System
- Entities extend `Espo\Core\ORM\Entity`
- Repository classes handle data access
- Services contain business logic
- Controllers handle HTTP requests

### Metadata-Driven Development
- Entity definitions: `metadata/entityDefs/`
- Client definitions: `metadata/clientDefs/`
- Scopes (permissions): `metadata/scopes/`
- Layouts: `layouts/`

### Frontend Development
- Views extend from `client/src/view.js`
- Models extend from `client/src/model.js`
- Collections extend from `client/src/collection.js`
- RequireJS for module loading
- Handlebars for templates

### Custom Development
All custom code should be placed in the `custom/` directory:
- Custom entities: `custom/Espo/Custom/Entities/`
- Custom controllers: `custom/Espo/Custom/Controllers/`
- Custom services: `custom/Espo/Custom/Services/`
- Custom metadata: `custom/Espo/Custom/Resources/metadata/`

### API Endpoints
- REST API base: `/api/v1/`
- Portal API: `/portal/api/v1/`
- OAuth callback: `/oauth-callback`

## Development Workflow

1. **Making Backend Changes**:
   - Modify PHP code in `application/` or `custom/`
   - Run `php clear_cache.php` after metadata changes
   - Run `php rebuild.php` for database structure changes

2. **Making Frontend Changes**:
   - Modify JavaScript in `client/src/` or `client/modules/`
   - Run `npm run build-dev` for development
   - Clear browser cache after changes

3. **Adding Custom Entities**:
   - Use Entity Manager in Admin panel or
   - Create metadata manually in `custom/Espo/Custom/Resources/metadata/`
   - Run `php rebuild.php`

4. **Testing Changes**:
   - Write unit tests in `tests/unit/`
   - Write integration tests in `tests/integration/`
   - Run PHPStan to check static typing

## Important Notes

- Always run `php clear_cache.php` after modifying metadata, layouts, or language files
- Follow PSR-4 autoloading standards
- Maintain PHPStan level 8 compliance
- Use dependency injection instead of direct instantiation
- Entity names use PascalCase, database tables use snake_case
- Frontend modules use AMD format with RequireJS
- All custom modifications should be in `custom/` directory to survive upgrades

## Branch Strategy
- `fix` - upcoming maintenance release
- `master` - development branch for new features
- `stable` - last stable release

## Deployment with Dokploy

### Important Notes for Dokploy
- **Dokploy does NOT execute custom scripts** - it only reads `docker-compose.yml`
- The deployment is fully automated based on Docker Compose configuration
- No need for complex deployment scripts or automation tools
- Dokploy handles: Git pull, Docker build, Container management, SSL certificates

### Required Files for Dokploy
- `docker-compose.yml` - Main configuration (uses `build: .` for local build)
- `Dockerfile` - Build instructions (preserves `/custom` folder)
- `.env` - Environment variables (configured in Dokploy panel)

### How It Works
1. Dokploy pulls code from GitHub
2. Reads `docker-compose.yml`
3. Builds image locally using `Dockerfile` (preserves customizations)
4. Starts all containers
5. Configures SSL automatically

### Why Local Build is Important
- Using `image: espocrm/espocrm:latest` would override customizations
- Using `build: .` forces local build with all custom code
- Custom modules in `/custom` are preserved
- No dependency on official image updates

## Traefik Integration for Dokploy (Updated: 2025-01-27)

### Configuration Changes
- **Removed port exposure**: No `ports: - "80:80"` as Traefik handles routing
- **Network configuration**: Using `dokploy-network` (external) instead of internal network
- **Container access**: Via Traefik reverse proxy at https://crm.kwameoilandgas.ao/
- **No Traefik labels needed**: Dokploy handles Traefik configuration automatically

### Docker Compose Structure
```yaml
services:
  espocrm:
    build: .
    container_name: espocrm-v03-app
    # NO ports exposed
    networks:
      - dokploy-network
      
networks:
  dokploy-network:
    external: true
```

### Last Update
- **Date**: 2025-01-27
- **Change**: Configured for Traefik integration with Dokploy
- **Result**: Container runs only on internal network, accessible via HTTPS domain