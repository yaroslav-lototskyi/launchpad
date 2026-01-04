/**
 * Health check response type
 */
export type HealthResponse = {
  ok: true;
  service: 'api';
  time: string; // ISO date
  version?: string;
  uptime?: number;
};
