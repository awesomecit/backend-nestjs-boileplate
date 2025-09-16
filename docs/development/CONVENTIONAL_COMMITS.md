# 📝 Conventional Commits Guide

## 🎯 Overview

I Conventional Commits sono una convenzione per strutturare i messaggi di commit in modo standardizzato, facilitando la generazione automatica di changelog, versioning semantico e comprensione del codice.

## 📋 Formato Base

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Esempio

```
feat(auth): add JWT token validation

Implement JWT middleware for protected routes with:
- Token expiration check
- Signature validation
- User role extraction

Closes #123
BREAKING CHANGE: requires Authorization header for all /api routes
```

## 🏷️ Types (Tipi)

### Core Types

| Type           | Descrizione                          | Esempio                                 | Versioning |
| -------------- | ------------------------------------ | --------------------------------------- | ---------- |
| **`feat`**     | Nuova funzionalità                   | `feat: add user registration`           | Minor      |
| **`fix`**      | Bug fix                              | `fix: resolve login validation issue`   | Patch      |
| **`docs`**     | Solo documentazione                  | `docs: update API documentation`        | -          |
| **`style`**    | Formatting, missing semicolons       | `style: fix indentation in auth module` | -          |
| **`refactor`** | Refactoring senza cambi funzionalità | `refactor: extract validation logic`    | -          |
| **`test`**     | Aggiunta/modifica test               | `test: add unit tests for user service` | -          |
| **`chore`**    | Task di manutenzione                 | `chore: update dependencies`            | -          |

### Extended Types

| Type         | Descrizione             | Esempio                                 |
| ------------ | ----------------------- | --------------------------------------- |
| **`perf`**   | Performance improvement | `perf: optimize database queries`       |
| **`ci`**     | CI/CD changes           | `ci: add GitHub Actions workflow`       |
| **`build`**  | Build system changes    | `build: update webpack config`          |
| **`revert`** | Revert previous commit  | `revert: "feat: add user registration"` |

## 🎯 Scopes (Ambiti)

### Common Scopes per NestJS Project

| Scope            | Uso                    | Esempio                                  |
| ---------------- | ---------------------- | ---------------------------------------- |
| **`auth`**       | Sistema autenticazione | `feat(auth): add OAuth2 integration`     |
| **`api`**        | API endpoints          | `fix(api): handle validation errors`     |
| **`db`**         | Database changes       | `feat(db): add user migration`           |
| **`config`**     | Configuration          | `chore(config): update environment vars` |
| **`deps`**       | Dependencies           | `chore(deps): upgrade nestjs to v10`     |
| **`monitoring`** | Monitoring stack       | `feat(monitoring): add nginx metrics`    |
| **`infra`**      | Infrastructure         | `feat(infra): add docker compose`        |
| **`security`**   | Security features      | `fix(security): patch JWT vulnerability` |

## ✅ Best Practices

### Formato Description

1. **Imperative mood**: "add" non "added" o "adds"
2. **No capital letter**: inizia minuscolo
3. **No period**: niente punto finale
4. **Max 50 chars**: mantieni conciso

```bash
✅ Good:
feat: add user authentication middleware
fix: resolve memory leak in websocket connection
docs: update installation instructions

❌ Bad:
feat: Added user authentication middleware.
fix: Fixed a memory leak issue
docs: Updated the installation instructions for developers
```

### Body Message

Usa il body per spiegare **cosa** e **perché**, non **come**:

```
feat(api): add rate limiting middleware

Implement rate limiting to prevent API abuse:
- 100 requests per minute per IP
- Different limits for authenticated users
- Redis-based storage for distributed systems

This addresses the performance issues reported in #456
```

### Breaking Changes

Per cambiamenti breaking:

```
feat(api): redesign authentication flow

BREAKING CHANGE: authentication now requires email instead of username
```

## 🚀 Esempi per Questo Progetto

### NestJS Application

```bash
feat(users): add user profile endpoint
fix(auth): handle expired JWT tokens gracefully
test(users): add integration tests for CRUD operations
refactor(services): extract common validation logic
perf(db): optimize user query with indexes
```

### Infrastructure & DevOps

```bash
feat(monitoring): integrate nginx with prometheus exporter
fix(docker): resolve container startup issues
ci(github): add automated testing workflow
chore(deps): update docker base images
feat(infra): add production docker-compose setup
```

### Documentation & Configuration

```bash
docs(api): add OpenAPI specification
docs(readme): update installation instructions
chore(config): update eslint rules
style(code): apply prettier formatting
```

### Monitoring & Testing

```bash
feat(monitoring): add grafana dashboard for nginx metrics
test(monitoring): add BATS tests for infrastructure validation
fix(monitoring): resolve prometheus scraping issues
feat(testing): implement smart test selection with husky
```

## 🛠️ Tools Integration

### Commitizen

```bash
npm install -g commitizen cz-conventional-changelog
echo '{ "path": "cz-conventional-changelog" }' > ~/.czrc

# Uso
git cz  # Invece di git commit
```

### Husky + Commitlint

```bash
npm install --save-dev @commitlint/config-conventional @commitlint/cli
echo "module.exports = {extends: ['@commitlint/config-conventional']}" > commitlint.config.js

# In .husky/commit-msg
npx --no-install commitlint --edit "$1"
```

### Release Automation

```bash
npm install --save-dev standard-version

# Package.json scripts
"release": "standard-version",
"release:minor": "standard-version --release-as minor",
"release:major": "standard-version --release-as major"
```

## 📊 Commit Categories per Team

### Frontend Developer

```bash
feat(ui): add responsive navigation component
fix(form): validate email field correctly
style(components): apply design system colors
perf(render): optimize component re-renders
```

### Backend Developer

```bash
feat(api): implement user CRUD endpoints
fix(validation): handle edge case in data parsing
refactor(services): split large service into modules
test(integration): add API endpoint tests
```

### DevOps Engineer

```bash
feat(ci): add automated deployment pipeline
fix(docker): resolve networking issues
chore(infra): update kubernetes manifests
feat(monitoring): add alerting rules
```

### QA Engineer

```bash
test(e2e): add user journey tests
fix(tests): resolve flaky test issues
test(load): add performance testing suite
docs(testing): update test execution guide
```

## 🎯 Template per Situazioni Comuni

### Bug Fix

```
fix(scope): brief description

More detailed explanation of what was broken and how
this fixes it. Include error symptoms if relevant.

Fixes #issue-number
```

### New Feature

```
feat(scope): brief description of new feature

Explain what the feature does and why it was needed.
Include any important implementation details.

Closes #feature-request-number
```

### Breaking Change

```
feat(scope): brief description

Detailed explanation of the change and its impact.

BREAKING CHANGE: specific details about what breaks
and how users should adapt their code.
```

### Performance Improvement

```
perf(scope): optimize specific operation

Explain what was optimized and the performance impact.
Include benchmarks if available.

- Before: 500ms average response time
- After: 50ms average response time
```

## 🚨 Common Mistakes

❌ **Vague descriptions**

```
fix: bug fix
feat: new stuff
chore: updates
```

❌ **Wrong type**

```
feat: fix typo in documentation  # Should be docs: or fix:
fix: add new user endpoint       # Should be feat:
```

❌ **Too long subject**

```
feat: implement a comprehensive user authentication system with JWT tokens and refresh token rotation
```

✅ **Correct versions**

```
docs: fix typo in user guide
feat: add user authentication system
```

## 📚 Resources

- [Conventional Commits Specification](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
- [Angular Commit Guidelines](https://github.com/angular/angular/blob/master/CONTRIBUTING.md)
- [Commitizen CLI](https://github.com/commitizen/cz-cli)

---

**Remember**: Un buon commit message è un messaggio che aiuta il tuo futuro io (e i tuoi colleghi) a capire cosa è cambiato e perché. Investi qualche secondo in più per scrivere commit chiari e utili! 🚀
