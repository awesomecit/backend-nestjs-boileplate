// src/health/health.service.ts
import { Injectable } from '@nestjs/common';
import { exec } from 'child_process';
import { promisify } from 'util';

@Injectable()
export class HealthService {
  private execAsync = promisify(exec);

  async getBasicHealth() {
    const memoryUsage = process.memoryUsage();

    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      environment: process.env.NODE_ENV || 'development',
      version: process.version,
      memory: {
        rss: Math.round(memoryUsage.rss / 1024 / 1024), // MB
        heapUsed: Math.round(memoryUsage.heapUsed / 1024 / 1024), // MB
        heapTotal: Math.round(memoryUsage.heapTotal / 1024 / 1024), // MB
      },
      pid: process.pid,
    };
  }

  async getClusterHealth() {
    try {
      // Ottieni informazioni sul nodo Docker Swarm
      const { stdout } = await this.execAsync('hostname');
      const hostname = stdout.trim();

      const basicHealth = await this.getBasicHealth();

      return {
        ...basicHealth,
        node: {
          id: process.env.HOSTNAME || hostname,
          hostname: hostname,
        },
        cluster: {
          role: await this.getSwarmRole(),
          swarmActive: await this.isSwarmActive(),
        },
        dependencies: await this.checkDependencies(),
      };
    } catch (error) {
      return {
        status: 'error',
        error: error.message,
        timestamp: new Date().toISOString(),
      };
    }
  }

  async checkDependencies(): Promise<Record<string, any>> {
    const dependencies: Record<string, any> = {};

    // Check database connection (example - adapt based on your database)
    try {
      // If using TypeORM or Prisma, add actual database check here
      dependencies.database = { status: 'ok', message: 'Not configured yet' };
    } catch (error) {
      dependencies.database = { status: 'error', message: error.message };
    }

    // Check external services if any
    dependencies.external = {
      status: 'ok',
      message: 'No external dependencies configured',
    };

    return dependencies;
  }

  private async getSwarmRole(): Promise<string> {
    try {
      const { stdout } = await this.execAsync(
        'docker node ls --format "{{.Self}} {{.ManagerStatus}}"',
      );
      const lines = stdout.trim().split('\n');
      const selfLine = lines.find((line) => line.startsWith('true'));

      return selfLine?.includes('Leader') ? 'manager' : 'worker';
    } catch {
      return 'unknown';
    }
  }

  private async isSwarmActive(): Promise<boolean> {
    try {
      const { stdout } = await this.execAsync(
        'docker info --format "{{.Swarm.LocalNodeState}}"',
      );
      return stdout.trim() === 'active';
    } catch {
      return false;
    }
  }
}
