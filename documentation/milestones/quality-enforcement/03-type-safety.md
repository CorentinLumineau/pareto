# M3: Type Safety Maximum

> **Maximum strictness for all type systems**

```
╔════════════════════════════════════════════════════════════════╗
║  Milestone: Type Safety Maximum                                 ║
║  Status:    ✅ COMPLETE                                         ║
║  Effort:    1 day                                               ║
║  ROI:       🟢🟢 High                                           ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Configure maximum type strictness across all languages. Zero type errors policy.

## Tasks

### 1. TypeScript Strict Configuration

Update `packages/typescript-config/base.json`:

```json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "useUnknownInCatchVariables": true,
    "alwaysStrict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,

    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "resolveJsonModule": true,
    "isolatedModules": true
  }
}
```

### 2. ESLint TypeScript Rules

Create `.eslintrc.js` at root:

```javascript
module.exports = {
  root: true,
  env: {
    browser: true,
    es2022: true,
    node: true,
  },
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/strict-type-checked',
    'plugin:@typescript-eslint/stylistic-type-checked',
  ],
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
    project: ['./tsconfig.json', './apps/*/tsconfig.json', './packages/*/tsconfig.json'],
    tsconfigRootDir: __dirname,
  },
  plugins: ['@typescript-eslint'],
  rules: {
    // Ban any type
    '@typescript-eslint/no-explicit-any': 'error',
    '@typescript-eslint/no-unsafe-argument': 'error',
    '@typescript-eslint/no-unsafe-assignment': 'error',
    '@typescript-eslint/no-unsafe-call': 'error',
    '@typescript-eslint/no-unsafe-member-access': 'error',
    '@typescript-eslint/no-unsafe-return': 'error',

    // Require explicit types
    '@typescript-eslint/explicit-function-return-type': 'error',
    '@typescript-eslint/explicit-module-boundary-types': 'error',

    // Strict null checks
    '@typescript-eslint/no-non-null-assertion': 'error',
    '@typescript-eslint/prefer-nullish-coalescing': 'error',
    '@typescript-eslint/prefer-optional-chain': 'error',

    // Other strict rules
    '@typescript-eslint/no-floating-promises': 'error',
    '@typescript-eslint/await-thenable': 'error',
    '@typescript-eslint/no-misused-promises': 'error',
  },
  ignorePatterns: [
    'node_modules/',
    'dist/',
    '.next/',
    '.expo/',
    '*.config.js',
    '*.config.mjs',
  ],
}
```

### 3. Python mypy Strict (Already Configured)

Verify `apps/workers/pyproject.toml` has:

```toml
[tool.mypy]
python_version = "3.13"
strict = true
ignore_missing_imports = true
warn_return_any = true
warn_unused_ignores = true
disallow_untyped_defs = true
disallow_incomplete_defs = true
check_untyped_defs = true
disallow_untyped_decorators = true
no_implicit_optional = true
warn_redundant_casts = true
warn_unused_configs = true
```

### 4. Go Static Analysis

Create `.golangci.yml`:

```yaml
run:
  timeout: 5m
  tests: true

linters:
  enable:
    # Default linters
    - errcheck
    - gosimple
    - govet
    - ineffassign
    - staticcheck
    - unused

    # Type safety
    - typecheck
    - unconvert

    # Error handling
    - nilerr
    - errorlint

  disable:
    - deadcode  # deprecated
    - varcheck  # deprecated

linters-settings:
  govet:
    enable-all: true

  staticcheck:
    checks: ["all"]

issues:
  exclude-use-default: false
  max-issues-per-linter: 0
  max-same-issues: 0
```

### 5. Update Verify Scripts

Ensure type checking is strict in all verify scripts.

`scripts/verify/typescript.sh`:

```bash
#!/bin/bash

echo "[TypeScript]"

# Type check (strict)
echo -n "  Type check (tsc --strict)... "
if pnpm typecheck > /dev/null 2>&1; then
    echo "✅"
else
    echo "❌"
    pnpm typecheck 2>&1 | head -20
    exit 1
fi
```

## Success Criteria

- [x] TypeScript: All strict flags enabled
- [x] TypeScript: No `any` types allowed
- [x] TypeScript: Explicit return types required
- [x] Python: mypy --strict passing
- [x] Go: staticcheck all checks enabled
- [x] Zero type errors in `make verify`

## Deliverables

```
packages/typescript-config/base.json (updated)
.eslintrc.js (new)
.golangci.yml (new)
apps/workers/pyproject.toml (verified)
```

## Testing

```bash
# Verify type checking works
make verify

# Test that type errors are caught
# Create a file with type error and verify it fails

# TypeScript
echo "const x: string = 123;" > /tmp/test.ts
pnpm tsc /tmp/test.ts  # Should fail

# Python
echo "def foo(x): return x" > /tmp/test.py
mypy --strict /tmp/test.py  # Should fail (missing types)
```

---

**Previous**: [M2: Coverage Enforcement](./02-coverage-enforcement.md)
**Next**: [M4: SOLID/Complexity Checks](./04-solid-complexity.md)
