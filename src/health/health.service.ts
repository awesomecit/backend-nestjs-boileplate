// src/health/health.service.ts
import { Injectable } from '@nestjs/common';
import { exec } from 'child_process';
import { promisify } from 'util';

@Injectable()
export class HealthService {
  private execAsync = promisify(exec);

  async getClusterHealth() {
    try {
      // Ottieni informazioni sul nodo Docker Swarm
      const { stdout } = await this.execAsync('hostname');
      const hostname = stdout.trim();

      return {
        status: 'ok',
        node: {
          id: process.env.HOSTNAME || hostname,
          hostname: hostname,
        },
        cluster: {
          role: await this.getSwarmRole(),
        },
      };
    } catch (error) {
      return {
        status: 'error',
        error: error.message,
      };
    }
  }

  private async getSwarmRole(): Promise<string> {
    try {
      const { stdout } = await this.execAsync(
        'docker node ls --format "{{.Self}} {{.ManagerStatus}}"',
      );
      const lines = stdout.trim().split('\n');
      const selfLine = lines.find((line) => line.startsWith('true'));

      return selfLine?.includes('Leader') ? 'manager' : 'worker';
      // } catch (error) {
    } catch {
      return 'unknown';
    }
  }
}
