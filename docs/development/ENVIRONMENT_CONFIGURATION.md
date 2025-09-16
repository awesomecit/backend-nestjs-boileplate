# Gestione delle Configurazioni con Environment Variables

## 🎯 Panoramica

Questo progetto utilizza un sistema centralizzato di configurazione basato su **variabili d'ambiente** per gestire tutte le configurazioni di host, porte e parametri dell'applicazione e dei servizi di monitoraggio.

## 📁 File di Configurazione

### `.env.example`

Template con tutte le variabili disponibili e i loro valori di default. Questo file è committato nel repository e serve come documentazione.

### `.env`

File di configurazione locale. Copiato da `.env.example` e personalizzato per il tuo ambiente. **NON deve essere committato.**

### `.env.local` (opzionale)

File di configurazione locale che sovrascrive `.env`. Utile per override temporanei.

## 🚀 Setup Iniziale

```bash
# 1. Copia il template
cp .env.example .env

# 2. Personalizza le configurazioni
vim .env

# 3. Avvia l'applicazione
npm run start:dev
```

## 📊 Configurazioni Disponibili

### Application Configuration

```bash
NODE_ENV=development
APP_PORT=3000
APP_HOST=localhost
APP_NAME=backend-nestjs-boilerplate
```

### Monitoring Services Ports

```bash
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
NODE_EXPORTER_PORT=9100
NGINX_EXPORTER_PORT=9113
PORTAINER_PORT=9000
NGINX_PORT=80
```

### Database Configuration

```bash
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=nestjs_db
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/nestjs_db
```

### Security & Authentication

```bash
JWT_SECRET=your-secret-key-here
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin123
```

## 🏗️ Architettura

### NestJS Configuration Module

Il progetto utilizza `@nestjs/config` per gestire le configurazioni:

```typescript
// src/config/app.config.ts
export default registerAs('app', () => ({
  port: parseInt(process.env.APP_PORT || '3000', 10),
  host: process.env.APP_HOST || 'localhost',
  // ...
}));
```

### Docker Compose Integration

I file docker-compose utilizzano le variabili d'ambiente:

```yaml
services:
  prometheus:
    ports:
      - '${PROMETHEUS_PORT:-9090}:9090'
  grafana:
    ports:
      - '${GRAFANA_PORT:-3000}:3000'
```

### Test Integration

I test caricano automaticamente le configurazioni:

```bash
# test/helpers/config.bash
export PROMETHEUS_URL="http://${PROMETHEUS_HOST}:${PROMETHEUS_PORT}"
export GRAFANA_URL="http://${GRAFANA_HOST}:${GRAFANA_PORT}"
```

## 🧪 Testing

I test utilizzano le stesse configurazioni:

```bash
# Test con configurazioni di default
npm run test

# Test con configurazioni personalizzate
GRAFANA_PORT=4000 npm run test:infrastructure
```

## 🔧 Utilizzo nel Codice

### NestJS Services

```typescript
import { ConfigService } from '@nestjs/config';

@Injectable()
export class MyService {
  constructor(private configService: ConfigService) {}

  getPort() {
    return this.configService.get<number>('app.port');
  }

  getMonitoringUrl() {
    return this.configService.get<string>('monitoring.prometheus.url');
  }
}
```

### Test Files (BATS)

```bash
load '../helpers/config'

@test "Service should be available" {
  run curl -f "${PROMETHEUS_URL}/api/v1/status"
  [ "$status" -eq 0 ]
}
```

### Scripts

```bash
#!/bin/bash
source .env
echo "Starting monitoring on port ${PROMETHEUS_PORT}"
```

## 🌍 Environment-Specific Configuration

### Development

```bash
NODE_ENV=development
LOG_LEVEL=debug
DATABASE_URL=postgresql://dev:dev@localhost:5432/dev_db
```

### Testing

```bash
NODE_ENV=test
LOG_LEVEL=error
DATABASE_URL=postgresql://test:test@localhost:5433/test_db
APP_PORT=3001  # Avoid conflicts
```

### Production

```bash
NODE_ENV=production
LOG_LEVEL=info
DATABASE_URL=postgresql://prod:****@prod-db:5432/prod_db
JWT_SECRET=strong-production-secret
```

## 🔒 Security Best Practices

1. **Mai committare `.env`**

   ```bash
   echo ".env" >> .gitignore
   ```

2. **Usare secrets management in produzione**

   ```bash
   # Instead of .env in production
   export DATABASE_PASSWORD=$(vault kv get -field=password secret/db)
   ```

3. **Validazione delle configurazioni**

   ```typescript
   // Validate required environment variables
   if (!process.env.JWT_SECRET) {
     throw new Error('JWT_SECRET is required');
   }
   ```

4. **Separare segreti dalle configurazioni**

   ```bash
   # .env (committed template)
   DATABASE_HOST=localhost

   # .env.local (secrets, not committed)
   DATABASE_PASSWORD=secret123
   ```

## 🚀 Deployment

### Docker

```dockerfile
# Dockerfile
COPY .env.example .env
# Override with environment-specific values
ENV NODE_ENV=production
ENV APP_PORT=3000
```

### Docker Compose

```yaml
services:
  app:
    env_file:
      - .env
    environment:
      - NODE_ENV=production
```

### Kubernetes

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_PORT: '3000'
  PROMETHEUS_PORT: '9090'
---
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
data:
  JWT_SECRET: base64-encoded-secret
```

## 🛠️ Troubleshooting

### Variable Not Found

```bash
# Check if variable is loaded
echo $PROMETHEUS_PORT

# Check .env file syntax
cat -A .env  # Shows invisible characters
```

### Port Conflicts

```bash
# Find what's using a port
lsof -i :9090

# Use different ports
export PROMETHEUS_PORT=9091
```

### Override for Testing

```bash
# Temporary override
GRAFANA_PORT=4000 npm run test

# Or create .env.test
cp .env.example .env.test
# Edit .env.test with test-specific values
```

## 📚 Migration Guide

### From Hardcoded Values

**Before:**

```typescript
await app.listen(3000);
```

**After:**

```typescript
const port = this.configService.get<number>('app.port');
await app.listen(port);
```

### From Direct process.env

**Before:**

```typescript
const port = process.env.PORT || 3000;
```

**After:**

```typescript
const port = this.configService.get<number>('app.port', 3000);
```

Questo sistema fornisce flessibilità, sicurezza e facilità di gestione delle configurazioni attraverso tutti gli ambienti del progetto.
