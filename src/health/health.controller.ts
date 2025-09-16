// src/health/health.controller.ts
import { Controller, Get } from '@nestjs/common';
import { HealthService } from './health.service';

@Controller('health')
export class HealthController {
  constructor(private readonly healthService: HealthService) {}

  @Get()
  async getHealth() {
    return this.healthService.getBasicHealth();
  }

  @Get('cluster')
  async getHealthWithNodeInfo() {
    return this.healthService.getClusterHealth();
  }

  @Get('detailed')
  async getDetailedHealth() {
    try {
      const basicHealth = await this.healthService.getBasicHealth();
      const clusterHealth = await this.healthService.getClusterHealth();

      return {
        basic: basicHealth,
        cluster: clusterHealth,
      };
    } catch (error) {
      return {
        status: 'error',
        error: error.message,
        timestamp: new Date().toISOString(),
      };
    }
  }
}
