// test/health/health.controller.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { HealthController } from './health.controller';
import { HealthService } from './health.service';

describe('HealthController', () => {
  let controller: HealthController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [HealthController],
      providers: [HealthService], // Aggiungi qui eventuali servizi necessari
    }).compile();

    controller = module.get<HealthController>(HealthController);
  });

  // RED: Test che fallisce - l'endpoint non esiste ancora
  it('should return health status', async () => {
    // Given: Una richiesta di health check
    // When: Chiamo l'endpoint /health
    const result = await controller.getHealth();

    // Then: Dovrei ricevere status OK con tutte le proprietà
    expect(result).toEqual({
      status: 'ok',
      timestamp: expect.any(String),
      uptime: expect.any(Number),
      environment: 'test',
      pid: expect.any(Number),
      version: expect.any(String),
      memory: {
        rss: expect.any(Number),
        heapTotal: expect.any(Number),
        heapUsed: expect.any(Number),
      },
    });
  });

  // RED: Test per cluster awareness
  it('should include node information', async () => {
    // Given: App deployata in Docker Swarm
    // When: Chiamo health endpoint
    const result = await controller.getHealthWithNodeInfo();

    // Then: Dovrei vedere info del nodo con tutte le proprietà
    expect(result).toEqual({
      status: 'ok',
      timestamp: expect.any(String),
      uptime: expect.any(Number),
      environment: 'test',
      pid: expect.any(Number),
      version: expect.any(String),
      memory: {
        rss: expect.any(Number),
        heapTotal: expect.any(Number),
        heapUsed: expect.any(Number),
      },
      node: {
        id: expect.any(String),
        hostname: expect.any(String),
      },
      cluster: {
        role: expect.stringMatching(/manager|worker/),
        swarmActive: expect.any(Boolean),
      },
      dependencies: {
        database: {
          status: expect.stringMatching(/ok|error/),
          message: expect.any(String),
        },
        external: {
          status: expect.stringMatching(/ok|error/),
          message: expect.any(String),
        },
      },
    });
  });
});
