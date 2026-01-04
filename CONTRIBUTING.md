# Contributing to Launchpad

Thank you for contributing to Launchpad!

## Development Setup

1. **Fork and clone the repository**

```bash
git clone https://github.com/your-username/launchpad.git
cd launchpad
```

2. **Install dependencies**

```bash
pnpm install
```

3. **Copy environment files**

```bash
cp apps/api/.env.example apps/api/.env
cp apps/client/.env.example apps/client/.env
```

4. **Start development**

```bash
pnpm dev
```

## Code Standards

### TypeScript

- Use strict TypeScript settings
- Define types for all function parameters and return values
- Use shared types from `@repo/shared` for API contracts

### Code Style

- Run `pnpm format` before committing
- Follow ESLint rules
- Use meaningful variable names
- Add comments for complex logic

### Testing

- Write unit tests for new features
- Maintain >= 80% code coverage
- Use Jest for backend, Vitest for frontend

### Commits

- Use conventional commit messages:
  - `feat:` - New features
  - `fix:` - Bug fixes
  - `docs:` - Documentation changes
  - `refactor:` - Code refactoring
  - `test:` - Test additions/changes
  - `chore:` - Build/tooling changes

Example:
```
feat(api): add user authentication endpoint
fix(client): resolve CORS issue in production
docs: update deployment instructions
```

## Pull Request Process

1. Create a feature branch from `main`
2. Make your changes
3. Run checks locally:
   ```bash
   pnpm lint
   pnpm type-check
   pnpm test
   pnpm build
   ```
4. Push to your fork
5. Create a pull request with:
   - Clear description of changes
   - Link to related issues
   - Screenshots (for UI changes)

## Questions?

Open an issue for discussion before starting major changes.
