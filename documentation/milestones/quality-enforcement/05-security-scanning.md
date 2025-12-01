# M5: Security Scanning

> **Scan for vulnerabilities in dependencies and code**

```
╔════════════════════════════════════════════════════════════════╗
║  Milestone: Security Scanning                                   ║
║  Status:    ✅ COMPLETE                                         ║
║  Effort:    1 day                                               ║
║  ROI:       🟡 Medium                                           ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Scan for security vulnerabilities in dependencies and code. Block on critical/high severity issues.

## Tasks

### 1. Go Security Scanning

Update `scripts/verify/go.sh`:

```bash
#!/bin/bash
cd apps/api

echo "[Go API]"

# ... previous checks ...

# Security - govulncheck
echo -n "  Security (govulncheck)... "
if command -v govulncheck &> /dev/null; then
    OUTPUT=$(govulncheck ./... 2>&1)
    if echo "$OUTPUT" | grep -q "No vulnerabilities found"; then
        echo "✅"
    elif echo "$OUTPUT" | grep -q "Vulnerability"; then
        echo "❌ Vulnerabilities found"
        echo "$OUTPUT" | head -20
        exit 1
    else
        echo "✅"
    fi
else
    echo "⚠️ govulncheck not installed"
fi

# Security - gosec
echo -n "  Security (gosec)... "
if command -v gosec &> /dev/null; then
    if gosec -quiet ./... > /dev/null 2>&1; then
        echo "✅"
    else
        echo "❌"
        gosec ./... 2>&1 | head -20
        exit 1
    fi
else
    echo "⚠️ gosec not installed"
fi

echo ""
```

Install Go security tools:

```bash
go install golang.org/x/vuln/cmd/govulncheck@latest
go install github.com/securego/gosec/v2/cmd/gosec@latest
```

Add to `.golangci.yml`:

```yaml
linters:
  enable:
    # ... previous linters ...
    - gosec  # Security issues
```

### 2. Python Security Scanning

Update `scripts/verify/python.sh`:

```bash
#!/bin/bash
cd apps/workers

echo "[Python Workers]"

# ... previous checks ...

# Security - pip-audit
echo -n "  Security (pip-audit)... "
if command -v pip-audit &> /dev/null; then
    OUTPUT=$(pip-audit 2>&1)
    if [ $? -eq 0 ]; then
        echo "✅"
    else
        CRITICAL=$(echo "$OUTPUT" | grep -c "CRITICAL\|HIGH" || true)
        if [ "$CRITICAL" -gt 0 ]; then
            echo "❌ $CRITICAL critical/high vulnerabilities"
            echo "$OUTPUT" | head -20
            exit 1
        else
            echo "⚠️ Low/medium vulnerabilities (not blocking)"
        fi
    fi
else
    echo "⚠️ pip-audit not installed"
fi

# Security - bandit
echo -n "  Security (bandit)... "
if command -v bandit &> /dev/null; then
    OUTPUT=$(bandit -r src/ -ll 2>&1)
    if [ $? -eq 0 ]; then
        echo "✅"
    else
        echo "❌"
        echo "$OUTPUT" | head -20
        exit 1
    fi
else
    echo "⚠️ bandit not installed"
fi

echo ""
```

Add to `apps/workers/pyproject.toml`:

```toml
[project.optional-dependencies]
dev = [
    # ... existing ...
    "pip-audit>=2.7.0",
    "bandit>=1.7.0",
]
```

### 3. TypeScript/Node.js Security Scanning

Update `scripts/verify/typescript.sh`:

```bash
#!/bin/bash

echo "[TypeScript]"

# ... previous checks ...

# Security - pnpm audit
echo -n "  Security (pnpm audit)... "
OUTPUT=$(pnpm audit --audit-level=high 2>&1)
if [ $? -eq 0 ]; then
    echo "✅"
else
    CRITICAL=$(echo "$OUTPUT" | grep -c "critical\|high" || true)
    if [ "$CRITICAL" -gt 0 ]; then
        echo "❌ $CRITICAL critical/high vulnerabilities"
        echo "$OUTPUT" | head -20
        exit 1
    else
        echo "⚠️ Low/moderate vulnerabilities (not blocking)"
    fi
fi

echo ""
```

### 4. Docker Security Scanning (Optional)

Create `scripts/verify/docker.sh`:

```bash
#!/bin/bash

echo "[Docker]"

# Security - trivy (if available)
echo -n "  Security (trivy)... "
if command -v trivy &> /dev/null; then
    # Scan Dockerfiles
    DOCKERFILE_ISSUES=0
    for dockerfile in $(find . -name "Dockerfile*" -not -path "./node_modules/*"); do
        OUTPUT=$(trivy config --severity HIGH,CRITICAL "$dockerfile" 2>&1)
        if echo "$OUTPUT" | grep -q "CRITICAL\|HIGH"; then
            DOCKERFILE_ISSUES=$((DOCKERFILE_ISSUES + 1))
        fi
    done

    if [ $DOCKERFILE_ISSUES -eq 0 ]; then
        echo "✅"
    else
        echo "❌ $DOCKERFILE_ISSUES Dockerfile(s) with issues"
        exit 1
    fi
else
    echo "⚠️ trivy not installed (optional)"
fi

echo ""
```

### 5. Security Configuration Files

Create `.trivyignore` for false positives:

```
# Trivy ignore file
# Add specific CVEs to ignore (with justification in comments)

# Example:
# CVE-2023-XXXXX  # Reason: Not exploitable in our context
```

Create `.banditrc`:

```yaml
# Bandit configuration
exclude_dirs:
  - tests
  - .venv
  - node_modules

skips:
  # Skip low confidence issues
  - B101  # assert_used (OK in tests)
```

## Success Criteria

- [x] Go: govulncheck integrated in verify scripts
- [x] Go: gosec enabled in golangci-lint
- [x] Python: pip-audit integrated in verify scripts
- [x] Python: flake8-bandit (S rules) enabled in ruff
- [x] Node.js: pnpm audit integrated in verify scripts
- [x] Security checks integrated in `make verify`

## Deliverables

```
scripts/verify/go.sh (updated)
scripts/verify/python.sh (updated)
scripts/verify/typescript.sh (updated)
scripts/verify/docker.sh (new, optional)
.trivyignore (new)
.banditrc (new)
apps/workers/pyproject.toml (updated dev deps)
```

## Testing

```bash
# Full verification with security
make verify

# Individual security checks
govulncheck ./...          # Go
pip-audit                  # Python
pnpm audit                 # Node.js
bandit -r apps/workers/src # Python code scan
```

---

**Previous**: [M4: SOLID/Complexity Checks](./04-solid-complexity.md)
**Next**: [M6: Pre-commit + CI Gates](./06-precommit-ci.md)
