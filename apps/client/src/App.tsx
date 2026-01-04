import { useState, useEffect } from 'react';
import type { HealthResponse } from '@repo/shared';
import './App.css';

function App() {
  const [health, setHealth] = useState<HealthResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchHealth();
  }, []);

  const fetchHealth = async () => {
    try {
      setLoading(true);
      setError(null);

      const apiUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3001';
      const response = await fetch(`${apiUrl}/api/v1/health`);

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data: HealthResponse = await response.json();
      setHealth(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch health');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="app">
      <header className="header">
        <h1>🚀 Launchpad</h1>
        <p>Enterprise DevOps Template • Vite + NestJS + K8s + AWS</p>
      </header>

      <main className="main">
        <div className="card">
          <h2>API Health Status</h2>

          {loading && <p className="loading">Loading...</p>}

          {error && (
            <div className="error">
              <p>❌ Error: {error}</p>
              <button onClick={fetchHealth}>Retry</button>
            </div>
          )}

          {health && (
            <div className="success">
              <p className="status">✅ {health.ok ? 'API is healthy' : 'API is down'}</p>
              <div className="details">
                <div className="detail-item">
                  <span className="label">Service:</span>
                  <span className="value">{health.service}</span>
                </div>
                <div className="detail-item">
                  <span className="label">Version:</span>
                  <span className="value">{health.version || 'N/A'}</span>
                </div>
                <div className="detail-item">
                  <span className="label">Uptime:</span>
                  <span className="value">{health.uptime}s</span>
                </div>
                <div className="detail-item">
                  <span className="label">Time:</span>
                  <span className="value">{new Date(health.time).toLocaleString()}</span>
                </div>
              </div>
              <button onClick={fetchHealth}>Refresh</button>
            </div>
          )}
        </div>
      </main>

      <footer className="footer">
        <p>Launchpad • Phase 0 Complete</p>
      </footer>
    </div>
  );
}

export default App;
