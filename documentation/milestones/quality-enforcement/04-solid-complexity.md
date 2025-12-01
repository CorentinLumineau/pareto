# M4: SOLID/Complexity Checks

> **Enforce code quality metrics for maintainability**

```
╔════════════════════════════════════════════════════════════════╗
║  Milestone: SOLID/Complexity Checks                             ║
║  Status:    ✅ COMPLETE                                         ║
║  Effort:    2 days                                              ║
║  ROI:       🟡🟢 Medium-High                                    ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Enforce SOLID principles through automated checks:
- Cyclomatic complexity <10 per function
- Function length <50 lines
- Code duplication <3%
- Dependency rules (no circular deps)

## Tasks

### 1. Go Complexity Configuration

Update `.golangci.yml`:

```yaml
run:
  timeout: 5m
  tests: true

linters:
  enable:
    # Previous linters...
    - errcheck
    - gosimple
    - govet
    - ineffassign
    - staticcheck
    - unused
    - typecheck

    # SOLID/Complexity
    - gocyclo       # Cyclomatic complexity
    - funlen        # Function length
    - dupl          # Code duplication
    - gocognit      # Cognitive complexity
    - cyclop        # More complexity checks
    - maintidx      # Maintainability index
    - goconst       # Repeated strings
    - depguard      # Dependency rules

linters-settings:
  gocyclo:
    min-complexity: 10

  funlen:
    lines: 50
    statements: 40

  dupl:
    threshold: 100  # tokens

  gocognit:
    min-complexity: 10

  cyclop:
    max-complexity: 10
    package-average: 5.0
    skip-tests: true

  depguard:
    rules:
      main:
        deny:
          - pkg: "reflect"
            desc: "avoid reflection unless necessary"
          - pkg: "unsafe"
            desc: "unsafe operations not allowed"

issues:
  exclude-use-default: false
  max-issues-per-linter: 0
  max-same-issues: 0
```

### 2. Python Complexity Configuration

Update `apps/workers/pyproject.toml`:

```toml
[tool.ruff]
line-length = 100
target-version = "py313"

[tool.ruff.lint]
select = [
    "E",      # pycodestyle errors
    "F",      # pyflakes
    "I",      # isort
    "N",      # pep8-naming
    "W",      # pycodestyle warnings
    "UP",     # pyupgrade
    "C90",    # mccabe complexity
    "B",      # flake8-bugbear
    "A",      # flake8-builtins
    "COM",    # flake8-commas
    "C4",     # flake8-comprehensions
    "DTZ",    # flake8-datetimez
    "T10",    # flake8-debugger
    "EXE",    # flake8-executable
    "ISC",    # flake8-implicit-str-concat
    "ICN",    # flake8-import-conventions
    "G",      # flake8-logging-format
    "INP",    # flake8-no-pep420
    "PIE",    # flake8-pie
    "T20",    # flake8-print
    "PYI",    # flake8-pyi
    "PT",     # flake8-pytest-style
    "Q",      # flake8-quotes
    "RSE",    # flake8-raise
    "RET",    # flake8-return
    "SLF",    # flake8-self
    "SIM",    # flake8-simplify
    "TID",    # flake8-tidy-imports
    "TCH",    # flake8-type-checking
    "ARG",    # flake8-unused-arguments
    "PTH",    # flake8-use-pathlib
    "ERA",    # eradicate
    "PD",     # pandas-vet
    "PGH",    # pygrep-hooks
    "PL",     # pylint
    "TRY",    # tryceratops
    "FLY",    # flynt
    "NPY",    # numpy
    "PERF",   # perflint
    "RUF",    # ruff-specific
]

[tool.ruff.lint.mccabe]
max-complexity = 10

[tool.ruff.lint.pylint]
max-args = 5
max-branches = 10
max-returns = 3
max-statements = 50

[tool.ruff.lint.per-file-ignores]
"tests/**/*.py" = ["S101", "PLR2004"]
```

### 3. TypeScript Complexity Configuration

Update `.eslintrc.js` to add SonarJS:

```javascript
module.exports = {
  // ... previous config ...
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/strict-type-checked',
    'plugin:@typescript-eslint/stylistic-type-checked',
    'plugin:sonarjs/recommended',  // Add SonarJS
  ],
  plugins: ['@typescript-eslint', 'sonarjs', 'import'],
  rules: {
    // ... previous rules ...

    // Complexity
    'sonarjs/cognitive-complexity': ['error', 10],
    'complexity': ['error', 10],
    'max-lines-per-function': ['error', { max: 50, skipBlankLines: true, skipComments: true }],
    'max-depth': ['error', 4],
    'max-nested-callbacks': ['error', 3],
    'max-params': ['error', 4],

    // No duplication
    'sonarjs/no-duplicate-string': ['error', { threshold: 3 }],
    'sonarjs/no-identical-functions': 'error',

    // Import rules (dependency management)
    'import/no-cycle': 'error',
    'import/no-self-import': 'error',
    'import/no-useless-path-segments': 'error',
  },
}
```

Install required packages:

```bash
pnpm add -D eslint-plugin-sonarjs eslint-plugin-import
```

### 4. Cross-Language Duplication Detection

Create `.jscpd.json`:

```json
{
  "threshold": 3,
  "reporters": ["console"],
  "ignore": [
    "**/node_modules/**",
    "**/.next/**",
    "**/.expo/**",
    "**/dist/**",
    "**/coverage/**",
    "**/__pycache__/**",
    "**/vendor/**",
    "**/*.min.js",
    "**/*.generated.*"
  ],
  "format": ["typescript", "javascript", "python", "go"],
  "minLines": 5,
  "minTokens": 50,
  "skipLocal": false,
  "absolute": true
}
```

Add to `scripts/verify/cross.sh`:

```bash
#!/bin/bash

echo "[Cross-Language]"

# Duplication check
echo -n "  Duplication (jscpd)... "
OUTPUT=$(npx jscpd . --reporters console 2>&1)
PERCENT=$(echo "$OUTPUT" | grep -oP '\d+\.\d+%' | head -1 | tr -d '%')

if [ -z "$PERCENT" ]; then
    PERCENT="0.0"
fi

THRESHOLD=3.0
if (( $(echo "$PERCENT <= $THRESHOLD" | bc -l) )); then
    echo "✅ ${PERCENT}% (threshold: ${THRESHOLD}%)"
else
    echo "❌ ${PERCENT}% > ${THRESHOLD}%"
    exit 1
fi

echo ""
```

### 5. Update Main Verify Script

Add cross-language checks to `scripts/verify/main.sh`:

```bash
# Add to parallel execution
./scripts/verify/cross.sh &
pids+=($!)
```

## Success Criteria

- [x] Cyclomatic complexity <10 enforced (all languages)
- [x] Function length <50 lines enforced (all languages)
- [x] Code duplication <3% enforced
- [x] No circular dependencies
- [x] `.golangci.yml` fully configured
- [x] Ruff fully configured
- [x] jscpd configured for cross-language duplication

## Deliverables

```
.golangci.yml (updated)
apps/workers/pyproject.toml (updated)
.eslintrc.js (updated)
.jscpd.json (new)
scripts/verify/cross.sh (new)
```

## Testing

```bash
# Full verification
make verify

# Test complexity detection
# Create a function with high complexity and verify it fails

# Test duplication detection
# Copy a function and verify jscpd catches it
```

---

**Previous**: [M3: Type Safety Maximum](./03-type-safety.md)
**Next**: [M5: Security Scanning](./05-security-scanning.md)
