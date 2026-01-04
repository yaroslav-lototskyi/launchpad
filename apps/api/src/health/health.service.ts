import { Injectable } from '@nestjs/common';
import type { HealthResponse } from '@repo/shared';

@Injectable()
export class HealthService {
  private readonly startTime = Date.now();

  getHealth(): HealthResponse {
    return {
      ok: true,
      service: 'api',
      time: new Date().toISOString(),
      version: process.env.APP_VERSION || '0.1.0',
      uptime: Math.floor((Date.now() - this.startTime) / 1000),
    };
  }
}
