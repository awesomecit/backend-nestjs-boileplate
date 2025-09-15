# Roadmap Completa per il Progetto Scalable Application Architecture

## Introduzione: Perché Questa Architettura?

Prima di immergerci nella roadmap, comprendiamo il **perché** dietro le scelte tecnologiche. Questo progetto rappresenta una moderna applicazione enterprise che deve gestire carichi variabili, garantire alta disponibilità e fornire visibilità operativa completa.

### I Principi Fondamentali che Guideranno il Nostro Percorso

**Scalabilità Orizzontale**: Invece di potenziare un singolo server (scaling verticale), aggiungiamo più istanze (scaling orizzontale). È come avere più camerieri in un ristorante affollato invece di un super-cameriere.

**Osservabilità**: Non basta che l'applicazione funzioni, dobbiamo sapere **come** funziona, **perché** fallisce e **quando** intervenire.

**Automazione**: Riduciamo l'errore umano automatizzando tutto ciò che è ripetibile.

## 🗺️ Roadmap Strutturata in 4 Fasi

### FASE 1: FONDAMENTA SOLIDE (Settimane 1-4)

>"Non si costruisce una cattedrale senza fondamenta robuste"

### FASE 2: SCALABILITÀ INTELLIGENTE (Settimane 5-8)

>"Ora insegniamo al sistema a crescere da solo"

### FASE 3: OSSERVABILITÀ COMPLETA (Settimane 9-12)

>"Se non puoi misurarlo, non puoi migliorarlo"

### FASE 4: OTTIMIZZAZIONE E PRODUZIONE (Settimane 13-14)

>"Il tocco finale che separa il buono dall'eccellente"

---

## 🏗️ FASE 1: FONDAMENTA SOLIDE

### Week 1: Setup Ambiente e TDD Foundation

**Obiettivo**: Creare l'ambiente di sviluppo e stabilire i pattern TDD che useremo per tutto il progetto.

#### Giorno 1-2: Analisi Architetturale e Setup

##### Comprendiamo il Pattern: Microservices con Container Orchestration

```text
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Load Balancer │────│  App Instance 1 │    │  App Instance N │
│     (NGINX)     │    │    (NestJS)     │    │    (NestJS)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   PostgreSQL    │
                    │   + Redis       │
                    └─────────────────┘
```

**Pro e Contro del Pattern Container Orchestration:**

**Vantaggi:**

- Isolamento delle applicazioni
- Facilità di scaling
- Portabilità tra ambienti
- Rollback rapidi

**Svantaggi:**

- Complessità iniziale maggiore
- Overhead di rete
- Curva di apprendimento

**Scelta: Docker Swarm vs Kubernetes**
Per questo progetto scegliamo **Docker Swarm** perché:

- Più semplice da configurare
- Adatto per team small-medium
- Meno overhead operativo
- Integrazione nativa con Docker

#### Test Infrastructure Foundation

```gherkin
Feature: Infrastructure Setup
  As a DevOps Engineer
  I want to ensure the basic infrastructure is correctly configured
  So that I can build upon solid foundations

Scenario: Docker Swarm Cluster Creation
  Given a set of clean servers
  When I initialize the Docker Swarm cluster
  Then I should have a working cluster with 3 nodes
  And each node should be healthy and accessible
  And the cluster should support service deployment

Scenario: Basic Service Deployment
  Given a working Docker Swarm cluster
  When I deploy a simple test service
  Then the service should be accessible
  And it should be distributed across available nodes
  And health checks should report success
```

#### Implementazione XP: Pair Programming Setup

##### Giorno 3-4: Creazione Struttura Progetto

Struttura del progetto seguendo i principi SOLID:

```text
scalable-app/
├── src/
│   ├── modules/          # Single Responsibility
│   ├── interfaces/       # Interface Segregation
│   ├── services/         # Dependency Inversion
│   └── common/
├── infrastructure/
│   ├── docker/
│   ├── monitoring/
│   └── ci-cd/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── infrastructure/
└── docs/
```

##### Principio SOLID in Azione: Dependency Inversion

```typescript
// ❌ Violazione - Dipendenza diretta
class UserService {
  private db = new PostgreSQLDatabase();
}

// ✅ Corretto - Inversione dipendenza
interface DatabaseInterface {
  findUser(id: string): Promise<User>;
}

class UserService {
  constructor(private database: DatabaseInterface) {}
}
```

#### Giorno 5: Docker Swarm Setup e Test

>Infrastructure as Code - docker-compose.yml

```yaml
version: '3.8'
services:
  app:
    image: nestjs-app:latest
    ports:
      - "3000:3000"
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Week 2: Applicazione Base con TDD

**Obiettivo**: Creare l'applicazione NestJS base seguendo rigorosamente TDD.

#### Pattern Scelto: Clean Architecture + CQRS

**Perché Clean Architecture?**

- Indipendenza dal framework
- Testabilità elevata
- Separazione delle responsabilità

```text
┌─────────────────────────────────────┐
│           Controllers               │
├─────────────────────────────────────┤
│           Use Cases                 │
├─────────────────────────────────────┤
│           Entities                  │
├─────────────────────────────────────┤
│        Infrastructure              │
└─────────────────────────────────────┘
```

#### TDD Cycle per User Management

```gherkin
Feature: User Management
  As an API consumer
  I want to manage users
  So that I can build user-centric applications

Scenario: Create New User
  Given a valid user payload
  When I send a POST request to /users
  Then I should receive a 201 status
  And the response should contain the user ID
  And the user should be persisted in the database

Scenario: Get User by ID
  Given a user exists in the system
  When I request GET /users/{id}
  Then I should receive the user data
  And the response time should be under 100ms

Scenario: Handle Invalid User Creation
  Given an invalid user payload
  When I send a POST request to /users
  Then I should receive a 400 status
  And the response should contain validation errors
```

#### Implementazione Red-Green-Refactor

**RED**: Test che fallisce

```typescript
describe('UserService', () => {
  it('should create user when valid data provided', async () => {
    // Given
    const userData = { name: 'John', email: 'john@example.com' };
    
    // When
    const result = await userService.create(userData);
    
    // Then
    expect(result).toHaveProperty('id');
    expect(result.name).toBe(userData.name);
  });
});
```

**GREEN**: Codice minimo che fa passare il test

```typescript
@Injectable()
export class UserService {
  constructor(private repository: UserRepository) {}
  
  async create(userData: CreateUserDto): Promise<User> {
    const user = new User(userData);
    return await this.repository.save(user);
  }
}
```

**REFACTOR**: Migliorare il codice

### Week 3: Database Layer e Testing

#### Pattern Scelto: Repository Pattern + Unit of Work

**Vantaggi Repository Pattern:**

- Astrazione del data layer
- Facilità di testing con mock
- Cambio di database trasparente

```typescript
interface UserRepository {
  findById(id: string): Promise<User>;
  save(user: User): Promise<User>;
  delete(id: string): Promise<void>;
}

class PostgreSQLUserRepository implements UserRepository {
  // Implementazione specifica PostgreSQL
}

class InMemoryUserRepository implements UserRepository {
  // Implementazione per test
}
```

#### Database Testing Strategy

```gherkin
Feature: Database Operations
  As a developer
  I want reliable database operations
  So that data integrity is maintained

Scenario: User Persistence
  Given a new user entity
  When I save it to the database
  Then it should be assigned an ID
  And I should be able to retrieve it by ID
  And the data should match exactly

Scenario: Connection Pool Management
  Given multiple concurrent requests
  When I perform database operations
  Then connection pool should handle requests efficiently
  And no connection leaks should occur
  And response times should remain consistent
```

### Week 4: Health Checks e Monitoring Foundation

#### Pattern Scelto: Health Check Pattern*

```typescript
@Controller('health')
export class HealthController {
  constructor(
    private dbHealth: DatabaseHealthIndicator,
    private memoryHealth: MemoryHealthIndicator
  ) {}

  @Get()
  @HealthCheck()
  check() {
    return this.health.check([
      () => this.dbHealth.pingCheck('database'),
      () => this.memoryHealth.checkHeap('memory_heap', 150 * 1024 * 1024),
    ]);
  }
}
```

#### Deliverable Fase 1

**Artefatti per NotebookLM/Udemy:**

1. **Video 1**: "Fondamenti dell'Architettura Scalabile" - Spiegazione pattern e scelte
2. **Video 2**: "TDD in Pratica" - Ciclo Red-Green-Refactor live
3. **Video 3**: "Docker Swarm Setup" - Configurazione pratica
4. **Video 4**: "Repository Pattern e Clean Architecture" - Implementazione

**Codice Repository**: Tag `v1.0-foundation`
**Documentazione**: Architecture Decision Records (ADR)

---

## ⚡ FASE 2: SCALABILITÀ INTELLIGENTE

### Week 5: Load Balancing e Service Discovery

>> Pattern Scelto: Reverse Proxy + Health-Based Load Balancing

#### Comprendiamo i Load Balancing Algorithms

```text
Round Robin: A → B → C → A → B → C
Least Connections: Route to server with fewer active connections
IP Hash: Hash client IP to ensure session affinity
Weighted: Distribute based on server capacity
```

**NGINX Configuration per Intelligent Load Balancing:**

```nginx
upstream app_servers {
    least_conn;
    server app1:3000 weight=3 max_fails=3 fail_timeout=30s;
    server app2:3000 weight=3 max_fails=3 fail_timeout=30s;
    server app3:3000 weight=2 max_fails=3 fail_timeout=30s;
}

server {
    listen 80;
    
    location /health {
        access_log off;
        proxy_pass http://app_servers/health;
        proxy_set_header Host $host;
    }
    
    location / {
        proxy_pass http://app_servers;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
    }
}
```

#### Test per Load Balancing

```gherkin
Feature: Load Balancing
  As a system administrator
  I want traffic distributed evenly
  So that no single server becomes overwhelmed

Scenario: Even Traffic Distribution
  Given 3 healthy application instances
  When I send 300 requests
  Then each instance should receive approximately 100 requests
  And response times should be consistent across instances

Scenario: Failover Handling
  Given 3 application instances
  When one instance becomes unhealthy
  Then traffic should be routed only to healthy instances
  And response success rate should remain above 99%
  And failed instance should be automatically removed from pool
```

### Week 6: Auto-scaling Implementation

>> Pattern Scelto: Reactive Auto-scaling + Predictive Scaling

#### Metrics-Based Scaling

```yaml
version: '3.8'
services:
  app:
    image: nestjs-app:latest
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

#### Scaling Logic Implementation

```typescript
interface ScalingMetrics {
  cpuUsage: number;
  memoryUsage: number;
  requestRate: number;
  responseTime: number;
}

class AutoScaler {
  async evaluateScaling(metrics: ScalingMetrics): Promise<ScalingDecision> {
    // Scale Up Conditions
    if (metrics.cpuUsage > 70 && metrics.responseTime > 200) {
      return { action: 'scale_up', targetReplicas: this.currentReplicas + 1 };
    }
    
    // Scale Down Conditions
    if (metrics.cpuUsage < 30 && metrics.requestRate < 100) {
      return { action: 'scale_down', targetReplicas: Math.max(3, this.currentReplicas - 1) };
    }
    
    return { action: 'no_change', targetReplicas: this.currentReplicas };
  }
}
```

### Week 7: Database Optimization e Connection Pooling

>> Pattern Scelto: Master-Slave Replication + Connection Pooling

#### Database Architecture

```text
┌─────────────────┐
│   Write Queries │
│       ↓         │
│   Master DB     │
│       ↓         │
│   Replication   │
│       ↓         │
│ ┌─────────────┐ │
│ │ Slave DB 1  │ │ ← Read Queries
│ └─────────────┘ │
│ ┌─────────────┐ │
│ │ Slave DB 2  │ │ ← Read Queries
│ └─────────────┘ │
└─────────────────┘
```

#### Connection Pool Configuration

```typescript
// PgBouncer Configuration
const poolConfig = {
  host: 'localhost',
  port: 6432, // PgBouncer port
  database: 'app_db',
  max: 100,        // Maximum connections
  min: 10,         // Minimum connections
  idle: 10000,     // Idle timeout
  acquire: 60000,  // Acquire timeout
  evict: 1000      // Eviction run interval
};

@Module({
  imports: [
    TypeOrmModule.forRoot({
      ...poolConfig,
      extra: {
        max: 100,
        min: 10,
        connectionTimeoutMillis: 60000,
        idleTimeoutMillis: 10000,
      }
    })
  ]
})
export class DatabaseModule {}
```

### Week 8: Caching Strategy e Performance

>> Pattern Scelto: Multi-Layer Caching

```text
Application Layer
       ↓
┌─────────────────┐
│   Redis Cache   │ ← L1 Cache (Hot data)
└─────────────────┘
       ↓
┌─────────────────┐
│   Database      │ ← L2 Storage (Cold data)
└─────────────────┘
```

#### Cache Implementation

```typescript
@Injectable()
export class CacheService {
  constructor(private redis: Redis) {}
  
  async get<T>(key: string): Promise<T | null> {
    const cached = await this.redis.get(key);
    return cached ? JSON.parse(cached) : null;
  }
  
  async set(key: string, value: any, ttl: number = 3600): Promise<void> {
    await this.redis.setex(key, ttl, JSON.stringify(value));
  }
  
  // Cache-aside pattern
  async getOrSet<T>(
    key: string, 
    fetcher: () => Promise<T>, 
    ttl: number = 3600
  ): Promise<T> {
    let result = await this.get<T>(key);
    
    if (!result) {
      result = await fetcher();
      await this.set(key, result, ttl);
    }
    
    return result;
  }
}
```

#### Deliverable Fase 2

**Artefatti per NotebookLM/Udemy:**

1. **Video 5**: "Load Balancing Strategies" - Algoritmi e configurazioni
2. **Video 6**: "Auto-scaling in Action" - Implementazione reactive scaling
3. **Video 7**: "Database Scaling Patterns" - Master-slave e connection pooling
4. **Video 8**: "Caching Strategies" - Multi-layer caching implementation

---

## 🔍 FASE 3: OSSERVABILITÀ COMPLETA

### Week 9: Application Performance Monitoring (APM)

**Obiettivo**: Implementare un sistema di monitoraggio completo che ci permetta di "vedere dentro" l'applicazione mentre funziona.

#### Pattern Scelto: Observability Triangle (Metrics + Logs + Traces)

```text
┌─────────────────────────────────────────┐
│              OBSERVABILITY              │
├─────────────────┬─────────────┬─────────┤
│    METRICS      │    LOGS     │ TRACES  │
│   (What?)       │   (Why?)    │ (Where?)│
└─────────────────┴─────────────┴─────────┘
```

**Perché questo pattern?**

- **Metrics**: Ci dicono COSA sta succedendo (CPU alto, errori in aumento)
- **Logs**: Ci dicono PERCHÉ sta succedendo (errori specifici, stack traces)
- **Traces**: Ci dicono DOVE sta succedendo (quale microservizio rallenta)

#### New Relic APM Integration

**Pro e Contro delle Soluzioni APM:**

**New Relic vs Datadog vs Application Insights:**

| Feature | New Relic | Datadog | App Insights |
|---------|-----------|---------|--------------|
| Facilità setup | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Costo | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |
| Features | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

**Scelta: New Relic** per questo progetto perché:

- Ottima integrazione Node.js
- Dashboard predefinite eccellenti
- Free tier generoso per apprendimento

#### Implementazione Step-by-Step

```typescript
// newrelic.js - Configurazione base
'use strict'

exports.config = {
  app_name: ['Scalable App'],
  license_key: process.env.NEW_RELIC_LICENSE_KEY,
  logging: {
    level: 'info'
  },
  allow_all_headers: true,
  attributes: {
    exclude: [
      'request.headers.cookie',
      'request.headers.authorization'
    ]
  }
}
```

#### Custom Metrics Implementation

```typescript
import * as newrelic from 'newrelic';

@Injectable()
export class MetricsService {
  // Business Metrics
  recordUserRegistration() {
    newrelic.recordMetric('Custom/Users/Registration', 1);
  }
  
  recordOrderValue(value: number) {
    newrelic.recordMetric('Custom/Orders/Value', value);
  }
  
  // Performance Metrics
  @newrelic.createTracer('database-query')
  async queryDatabase(query: string) {
    const startTime = Date.now();
    try {
      const result = await this.database.query(query);
      newrelic.recordMetric('Custom/Database/QueryTime', Date.now() - startTime);
      return result;
    } catch (error) {
      newrelic.noticeError(error);
      throw error;
    }
  }
}
```

#### Test per APM

```gherkin
Feature: Application Performance Monitoring
  As a DevOps Engineer
  I want comprehensive application monitoring
  So that I can detect and resolve issues proactively

Scenario: Custom Metrics Collection
  Given the application is instrumented with APM
  When a user performs key business actions
  Then custom metrics should be recorded
  And they should be visible in the APM dashboard
  And alerts should fire when thresholds are exceeded

Scenario: Error Tracking
  Given an application error occurs
  When the error is thrown
  Then it should be automatically captured
  And stack trace should be preserved
  And error context should include request details
  And notification should be sent to team

Scenario: Performance Baseline
  Given normal application load
  When I monitor response times over 24 hours
  Then 95th percentile should be under 200ms
  And error rate should be below 0.1%
  And Apdex score should be above 0.85
```

### Week 10: Infrastructure Monitoring con Prometheus e Grafana

>> Pattern Scelto: Pull-based Metrics Collection + Time Series Database

#### Architettura Monitoring Infrastructure

```text
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Node Exporter │────│   Prometheus    │────│     Grafana     │
│  (Server Metrics)│    │ (Time Series DB)│    │  (Visualization)│
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
┌─────────────────┐              │              ┌─────────────────┐
│  App Metrics    │──────────────┘              │   Alert Manager │
│   (/metrics)    │                             │  (Notifications)│
└─────────────────┘                             └─────────────────┘
```

**Perché Prometheus?**

- **Pull-based**: Il server chiede i dati (più affidabile del push)
- **Dimensional data**: Etichette flessibili per query complesse
- **Powerful query language**: PromQL per analisi avanzate
- **Integrazione nativa**: Ottima con Docker e Kubernetes

#### Prometheus Configuration

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "rules/*.yml"

scrape_configs:
  - job_name: 'nestjs-app'
    static_configs:
      - targets: ['app:3000']
    metrics_path: '/metrics'
    scrape_interval: 5s
    
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
      
  - job_name: 'postgres-exporter'
    static_configs:
      - targets: ['postgres-exporter:9187']

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093
```

#### Custom Metrics in NestJS

```typescript
import { register, Counter, Histogram, Gauge } from 'prom-client';

@Injectable()
export class PrometheusService {
  private readonly httpRequestCounter: Counter<string>;
  private readonly httpRequestDuration: Histogram<string>;
  private readonly activeConnections: Gauge<string>;
  
  constructor() {
    // HTTP Request Counter
    this.httpRequestCounter = new Counter({
      name: 'http_requests_total',
      help: 'Total number of HTTP requests',
      labelNames: ['method', 'route', 'status_code']
    });
    
    // Response Time Histogram
    this.httpRequestDuration = new Histogram({
      name: 'http_request_duration_seconds',
      help: 'Duration of HTTP requests in seconds',
      labelNames: ['method', 'route'],
      buckets: [0.1, 0.25, 0.5, 1, 2.5, 5, 10]
    });
    
    // Active Connections Gauge
    this.activeConnections = new Gauge({
      name: 'active_connections',
      help: 'Number of active connections'
    });
  }
  
  incrementRequestCounter(method: string, route: string, statusCode: number) {
    this.httpRequestCounter.inc({ method, route, status_code: statusCode.toString() });
  }
  
  observeRequestDuration(method: string, route: string, duration: number) {
    this.httpRequestDuration.observe({ method, route }, duration);
  }
}

@Controller('metrics')
export class MetricsController {
  @Get()
  getMetrics() {
    return register.metrics();
  }
}
```

#### Grafana Dashboard Creation

```json
{
  "dashboard": {
    "title": "Scalable App Overview",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "{{route}} - {{method}}"
          }
        ]
      },
      {
        "title": "Response Time P95",
        "type": "graph", 
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total{status_code=~\"5..\"}[5m]) / rate(http_requests_total[5m])",
            "legendFormat": "Error Rate %"
          }
        ]
      }
    ]
  }
}
```

### Week 11: Centralized Logging e Distributed Tracing

>> Pattern Scelto: ELK Stack + OpenTelemetry

#### Logging Architecture

```text
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   App Logs      │────│   Logstash      │────│  Elasticsearch  │
│  (Structured)   │    │  (Processing)   │    │   (Storage)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
┌─────────────────┐              │              ┌─────────────────┐
│  System Logs    │──────────────┘              │     Kibana      │
│   (Filebeat)    │                             │ (Visualization) │
└─────────────────┘                             └─────────────────┘
```

#### Structured Logging Implementation

```typescript
import { Logger } from '@nestjs/common';
import * as winston from 'winston';

export class StructuredLogger {
  private logger: winston.Logger;
  
  constructor(service: string) {
    this.logger = winston.createLogger({
      level: 'info',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
      ),
      defaultMeta: { 
        service,
        environment: process.env.NODE_ENV,
        version: process.env.APP_VERSION
      },
      transports: [
        new winston.transports.Console({
          format: winston.format.combine(
            winston.format.colorize(),
            winston.format.simple()
          )
        })
      ]
    });
  }
  
  logBusinessEvent(event: string, data: any, userId?: string) {
    this.logger.info('Business Event', {
      event,
      data,
      userId,
      timestamp: new Date().toISOString(),
      type: 'business_event'
    });
  }
  
  logPerformance(operation: string, duration: number, metadata?: any) {
    this.logger.info('Performance Metric', {
      operation,
      duration,
      metadata,
      type: 'performance'
    });
  }
  
  logError(error: Error, context?: any) {
    this.logger.error('Application Error', {
      message: error.message,
      stack: error.stack,
      context,
      type: 'error'
    });
  }
}
```

#### Distributed Tracing con OpenTelemetry

```typescript
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { JaegerExporter } from '@opentelemetry/exporter-jaeger';

const sdk = new NodeSDK({
  traceExporter: new JaegerExporter({
    endpoint: 'http://jaeger:14268/api/traces',
  }),
  instrumentations: [getNodeAutoInstrumentations()]
});

sdk.start();

// Custom Tracing
import { trace } from '@opentelemetry/api';

@Injectable()
export class UserService {
  private tracer = trace.getTracer('user-service');
  
  async createUser(userData: CreateUserDto): Promise<User> {
    return this.tracer.startActiveSpan('create-user', async (span) => {
      try {
        span.setAttributes({
          'user.email': userData.email,
          'user.type': userData.type
        });
        
        const user = await this.repository.save(userData);
        
        span.setAttributes({
          'user.id': user.id,
          'operation.result': 'success'
        });
        
        return user;
      } catch (error) {
        span.recordException(error);
        span.setStatus({ code: SpanStatusCode.ERROR });
        throw error;
      } finally {
        span.end();
      }
    });
  }
}
```

### Week 12: Alerting e Incident Response

>> Pattern Scelto: Layered Alerting + Escalation Policies

#### Alert Categories

```text
┌─────────────────────────────────────────┐
│               ALERT LEVELS              │
├─────────────────┬─────────────┬─────────┤
│     CRITICAL    │   WARNING   │   INFO  │
│   (< 2 mins)    │  (< 15 mins)│(< 1 hr) │
├─────────────────┼─────────────┼─────────┤
│ • Service Down  │ • High CPU  │ • Deploys│
│ • DB Failure    │ • Memory    │ • Scale │
│ • Error Spike   │ • Slow API  │ Events  │
└─────────────────┴─────────────┴─────────┘
```

#### AlertManager Configuration

```yaml
# alertmanager.yml
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alerts@company.com'

route:
  group_by: ['alertname', 'severity']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 12h
  receiver: 'web.hook'
  routes:
  - match:
      severity: critical
    receiver: 'critical-alerts'
    group_wait: 10s
    repeat_interval: 1m

receivers:
- name: 'web.hook'
  webhook_configs:
  - url: 'http://slack-webhook/alerts'

- name: 'critical-alerts'
  email_configs:
  - to: 'oncall@company.com'
    subject: 'CRITICAL: {{ .GroupLabels.alertname }}'
    body: |
      {{ range .Alerts }}
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      {{ end }}
  slack_configs:
  - api_url: 'https://hooks.slack.com/services/xxx'
    channel: '#alerts'
    text: 'CRITICAL: {{ .CommonAnnotations.summary }}'
```

#### Test per Monitoring Completo

```gherkin
Feature: Complete Observability
  As an Operations Engineer
  I want complete visibility into system behavior
  So that I can maintain system reliability

Scenario: End-to-End Tracing
  Given a user request enters the system
  When the request flows through multiple services
  Then I should see complete trace from entry to exit
  And each service span should include timing
  And errors should be captured with context
  And trace should be searchable by request ID

Scenario: Alert Propagation
  Given a critical system condition occurs
  When the threshold is exceeded
  Then an alert should be generated within 30 seconds
  And it should be sent to the correct escalation level
  And it should include actionable information
  And acknowledgment should stop further notifications

Scenario: Log Correlation
  Given an error occurs in the application
  When I search logs by trace ID
  Then I should find all related log entries
  And they should be properly structured
  And correlation across services should be maintained
  And sensitive data should be filtered out
```

#### Deliverable Fase 3

**Artefatti per NotebookLM/Udemy:**

1. **Video 9**: "APM con New Relic" - Setup e custom metrics
2. **Video 10**: "Prometheus e Grafana" - Infrastructure monitoring
3. **Video 11**: "Centralized Logging" - ELK stack e structured logging
4. **Video 12**: "Distributed Tracing" - OpenTelemetry implementation
5. **Video 13**: "Alerting Strategy" - AlertManager e incident response

---

## 🚀 FASE 4: OTTIMIZZAZIONE E PRODUZIONE

### Week 13: Performance Tuning e Optimization

**Obiettivo**: Ottimizzare le performance del sistema per carichi di produzione reali.

#### Pattern Scelto: Performance Budgets + Continuous Optimization

**Performance Budget Framework:**

```text
┌─────────────────────────────────────────┐
│           PERFORMANCE BUDGETS           │
├─────────────────┬─────────────┬─────────┤
│   API RESPONSE  │  THROUGHPUT │  ERROR  │
│     < 200ms     │  > 1000 RPS │  < 0.1% │
├─────────────────┼─────────────┼─────────┤
│   DATABASE      │    CACHE    │   CPU   │
│   < 100ms       │   > 85% HR  │  < 70%  │
└─────────────────┴─────────────┴─────────┘
```

#### Database Query Optimization

```typescript
@Injectable()
export class OptimizedUserService {
  
  // ❌ N+1 Query Problem
  async getUsersWithPostsBad(): Promise<User[]> {
    const users = await this.userRepository.find();
    for (const user of users) {
      user.posts = await this.postRepository.findByUserId(user.id);
    }
    return users;
  }
  
  // ✅ Optimized with JOIN
  async getUsersWithPostsGood(): Promise<User[]> {
    return this.userRepository
      .createQueryBuilder('user')
      .leftJoinAndSelect('user.posts', 'post')
      .where('user.active = :active', { active: true })
      .orderBy('user.createdAt', 'DESC')
      .limit(100)
      .getMany();
  }
  
  // ✅ Pagination for large datasets
  async getUsersPaginated(page: number, limit: number): Promise<PaginatedResult<User>> {
    const [users, total] = await this.userRepository.findAndCount({
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' }
    });
    
    return {
      data: users,
      total,
      page,
      totalPages: Math.ceil(total / limit)
    };
  }
}
```

#### Memory Optimization

```typescript
@Injectable()
export class MemoryOptimizedService {
  private readonly MAX_BATCH_SIZE = 1000;
  
  // Stream processing for large datasets
  async processLargeDataset(dataStream: ReadStream): Promise<void> {
    return new Promise((resolve, reject) => {
      let batch: any[] = [];
      
      dataStream
        .pipe(csv())
        .on('data', async (data) => {
          batch.push(data);
          
          if (batch.length >= this.MAX_BATCH_SIZE) {
            await this.processBatch(batch);
            batch = []; // Clear memory
          }
        })
        .on('end', async () => {
          if (batch.length > 0) {
            await this.processBatch(batch);
          }
          resolve();
        })
        .on('error', reject);
    });
  }
  
  private async processBatch(batch: any[]): Promise<void> {
    // Process in chunks to avoid memory pressure
    const chunks = this.chunkArray(batch, 100);
    
    for (const chunk of chunks) {
      await this.repository.save(chunk);
    }
  }
}
```

#### Caching Optimization

```typescript
@Injectable()
export class CacheOptimizationService {
  
  // Multi-level caching strategy
  async getPopularContent(category: string): Promise<Content[]> {
    const cacheKey = `popular_content:${category}`;
    
    // Level 1: In-memory cache (fastest)
    let content = this.memoryCache.get(cacheKey);
    if (content) {
      this.metrics.recordCacheHit('memory', cacheKey);
      return content;
    }
    
    // Level 2: Redis cache (fast)
    content = await this.redisCache.get(cacheKey);
    if (content) {
      this.memoryCache.set(cacheKey, content, 300); // 5 min TTL
      this.metrics.recordCacheHit('redis', cacheKey);
      return content;
    }
    
    // Level 3: Database (slow)
    content = await this.database.getPopularContent(category);
    
    // Populate caches with different TTLs
    await this.redisCache.set(cacheKey, content, 3600); // 1 hour
    this.memoryCache.set(cacheKey, content, 300); // 5 minutes
    
    this.metrics.recordCacheMiss(cacheKey);
    return content;
  }
  
  // Cache warming strategy
  @Cron('0 */6 * * *') // Every 6 hours
  async warmCache(): Promise<void> {
    const popularCategories = ['tech', 'business', 'health'];
    
    for (const category of popularCategories) {
      await this.getPopularContent(category);
    }
  }
}
```

### Week 14: Security Hardening e Production Readiness

>> Pattern Scelto: Defense in Depth + Zero Trust

#### Security Layers

```text
┌─────────────────────────────────────────┐
│              SECURITY LAYERS            │
├─────────────────┬─────────────┬─────────┤
│   NETWORK       │ APPLICATION │  DATA   │
│   • Firewall    │ • Auth/AuthZ│ • Encrypt│
│   • VPN         │ • Rate Limit│ • Backup │
│   • DDoS        │ • Input Val │ • Access │
└─────────────────┴─────────────┴─────────┘
```

#### Authentication & Authorization

```typescript
// JWT Strategy with Role-Based Access Control
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(private configService: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get('JWT_SECRET'),
    });
  }

  async validate(payload: any) {
    return {
      userId: payload.sub,
      email: payload.email,
      roles: payload.roles,
      permissions: payload.permissions
    };
  }
}

// RBAC Guard
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<Role[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    
    if (!requiredRoles) {
      return true;
    }
    
    const { user } = context.switchToHttp().getRequest();
    return requiredRoles.some((role) => user.roles?.includes(role));
  }
}

// Usage
@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AdminController {
  
  @Post('users')
  @Roles(Role.Admin, Role.SuperAdmin)
  async createUser(@Body() userData: CreateUserDto) {
    return this.userService.create(userData);
  }
}
```

#### Rate Limiting & DDoS Protection

```typescript
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';

@Module({
  imports: [
    ThrottlerModule.forRoot({
      ttl: 60, // Time window in seconds
      limit: 100, // Number of requests per window
    }),
  ],
})
export class AppModule {}

// Custom rate limiting per user type
@Injectable()
export class CustomThrottlerGuard extends ThrottlerGuard {
  protected getTracker(req: any): string {
    const user = req.user;
    
    // Different limits for different user types
    if (user?.isPremium) {
      return `premium_${user.id}`;
    }
    
    return req.ip;
  }
  
  protected async getLimit(context: ExecutionContext): Promise<number> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;
    
    // Premium users get higher limits
    if (user?.isPremium) {
      return 1000; // 1000 requests per minute
    }
    
    return 100; // 100 requests per minute for regular users
  }
}
```

#### Container Security

```dockerfile
# Multi-stage build for smaller, more secure images
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

FROM node:18-alpine AS runtime

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nestjs -u 1001

# Set working directory
WORKDIR /app

# Copy built application
COPY --from=builder /app/node_modules ./node_modules
COPY --chown=nestjs:nodejs . .

# Remove unnecessary packages and update
RUN apk update && apk upgrade && apk del curl wget

# Use non-root user
USER nestjs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

EXPOSE 3000

CMD ["node", "dist/main.js"]
```

#### Final Production Checklist

```gherkin
Feature: Production Readiness
  As a DevOps Engineer
  I want to ensure the application is production-ready
  So that it can handle real-world traffic safely

Scenario: Security Validation
  Given the application is deployed
  When I run security scans
  Then no critical vulnerabilities should be found
  And all secrets should be properly managed
  And HTTPS should be enforced
  And rate limiting should be active

Scenario: Performance Validation
  Given the application under normal load
  When I measure performance metrics
  Then response times should meet SLA requirements
  And throughput should handle expected traffic
  And resource utilization should be optimal
  And error rates should be within acceptable limits

Scenario: Disaster Recovery
  Given a complete system failure
  When I execute recovery procedures
  Then system should be restored within RTO
  And data loss should be within RPO
  And all monitoring should be functional
  And business operations should resume normally
```

#### Final Infrastructure Overview

```text
┌─────────────────────────────────────────────────────────┐
│                   PRODUCTION ARCHITECTURE               │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │     CDN     │  │   WAF/DDoS  │  │   Load LB   │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
│         │                 │                 │          │
│  ┌─────────────────────────────────────────────────┐   │
│  │              DOCKER SWARM CLUSTER              │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐           │   │
│  │  │  App 1  │ │  App 2  │ │  App N  │           │   │
│  │  └─────────┘ └─────────┘ └─────────┘           │   │
│  └─────────────────────────────────────────────────┘   │
│         │                 │                 │          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │ PostgreSQL  │  │    Redis    │  │  Monitoring │     │
│  │  Cluster    │  │   Cluster   │  │    Stack    │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
└─────────────────────────────────────────────────────────┘
```

#### Deliverable Fase 4

**Artefatti per NotebookLM/Udemy:**

1. **Video 14**: "Performance Optimization" - Database tuning e caching
2. **Video 15**: "Security Hardening" - Authentication, authorization, rate limiting
3. **Video 16**: "Production Deployment" - Final deployment e checklist
4. **Video 17**: "Monitoring in Production" - Real-world monitoring scenarios
5. **Video 18**: "Disaster Recovery" - Backup, restore, incident response

**Repository Finale**: Tag `v1.0-production`
**Documentazione Completa**: Architecture, Runbooks, Troubleshooting guides

---

## 🎯 Conclusione: Il Percorso Completo

Abbiamo creato una roadmap completa che trasforma un'idea in un sistema production-ready scalabile. Ogni fase è progettata per:

1. **Essere incrementale**: Ogni settimana produce valore tangibile
2. **Seguire TDD**: Test-first approach garantisce qualità
3. **Applicare XP**: Pair programming, continuous integration, refactoring
4. **Creare contenuti**: Ogni deliverable è perfetto per formazione

**Principi SOLID applicati costantemente:**

- **S**ingle Responsibility: Ogni classe ha un unico scopo
- **O**pen/Closed: Estensibile senza modifiche
- **L**iskov Substitution: Sostituibilità delle implementazioni
- **I**nterface Segregation: Interface piccole e specifiche
- **D**ependency Inversion: Dipendenze verso astrazioni

**Pattern utilizzati:**

- Repository Pattern per data access
- Observer Pattern per eventi
- Strategy Pattern per algoritmi intercambiabili
- Factory Pattern per creazione oggetti
- Circuit Breaker per resilienza

**Tool Open Source Scelti:**

- **Container Orchestration**: Docker Swarm
- **Application Framework**: NestJS
- **Database**: PostgreSQL + Redis
- **Load Balancing**: NGINX
- **Monitoring**: Prometheus + Grafana + New Relic
- **Logging**: ELK Stack
- **Tracing**: OpenTelemetry + Jaeger
- **CI/CD**: GitHub Actions
- **Security**: JWT, Rate Limiting, Container Security

**Metodologia XP Implementata:**

- Pair Programming per knowledge sharing
- Test-Driven Development per qualità
- Continuous Integration per feedback rapido
- Refactoring costante per clean code
- Small releases per delivery incrementale

Questa roadmap ti fornisce una base solida per creare un corso Udemy completo e materiale per NotebookLM che copre tutti gli aspetti moderni dello sviluppo di applicazioni scalabili enterprise.

Ogni settimana produce deliverable concreti che possono essere trasformati in contenuti formativi, dimostrazioni pratiche e materiale didattico per un pubblico che vuole imparare l'architettura scalabile moderna.
