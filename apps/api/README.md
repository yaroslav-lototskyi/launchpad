# API

NestJS backend API for Launchpad.

## Scripts

- `pnpm dev` - Start development server with hot reload
- `pnpm build` - Build for production
- `pnpm start` - Start production server
- `pnpm test` - Run tests
- `pnpm lint` - Lint code

## Development

The API uses TypeScript and compiles to JavaScript in the `dist/` directory.

**Note on dist structure**: Due to monorepo setup with shared packages, TypeScript preserves the full directory structure when compiling. This results in output files being located at `dist/apps/api/src/main.js` instead of `dist/main.js`. This is normal behavior for TypeScript with path mappings in a monorepo.

## Environment Variables

Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

Required variables:
- `PORT` - Server port (default: 3001)
- `NODE_ENV` - Environment (development/production)
- `CORS_ORIGIN` - Allowed CORS origin
- `APP_VERSION` - Application version

## Endpoints

- `GET /api/v1/health` - Health check endpoint
