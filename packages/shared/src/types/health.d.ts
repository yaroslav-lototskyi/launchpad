export type HealthResponse = {
    ok: true;
    service: 'api';
    time: string;
    version?: string;
    uptime?: number;
};
