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

    // Then: Dovrei ricevere status OK
    expect(result).toEqual({
      status: 'ok',
      timestamp: expect.any(String),
      uptime: expect.any(Number),
      environment: 'test',
    });
  });

  // RED: Test per cluster awareness
  it('should include node information', async () => {
    // Given: App deployata in Docker Swarm
    // When: Chiamo health endpoint
    const result = await controller.getHealthWithNodeInfo();

    // Then: Dovrei vedere info del nodo
    expect(result).toEqual({
      status: 'ok',
      node: {
        id: expect.any(String),
        hostname: expect.any(String),
      },
      cluster: {
        role: expect.stringMatching(/manager|worker/),
      },
    });
  });
});
