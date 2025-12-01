# Phase 01: Infrastructure Setup

> **Local development environment with Dokploy**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      01 - Infrastructure                                ║
║  Initiative: Foundation                                         ║
║  Status:     ✅ COMPLETE                                        ║
║  Effort:     0 days (already done)                             ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Setup production-ready infrastructure for local development.

## Completed Tasks

- [x] Local PC configured as development server
- [x] Dokploy installed and running
- [x] Domain registered with Cloudflare tunneling
- [x] PostgreSQL 17 + TimescaleDB container
- [x] Redis 7.4 container
- [x] Traefik reverse proxy configured
- [x] SSL certificates (via Cloudflare)

## Current Infrastructure

```
┌─────────────────────────────────────────────────────────────┐
│                      LOCAL PC                                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐     ┌─────────────────────────────────┐   │
│  │  Dokploy    │────▶│  Traefik (Reverse Proxy + SSL)  │   │
│  └─────────────┘     └─────────────────────────────────┘   │
│                                  │                          │
│                     ┌────────────┼────────────┐            │
│                     ▼            ▼            ▼            │
│              ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│              │ API (Go) │ │  Web     │ │ Workers  │       │
│              │ :8080    │ │ (Next.js)│ │ (Python) │       │
│              └──────────┘ │ :3000    │ └──────────┘       │
│                           └──────────┘                     │
│                                                             │
│              ┌──────────────────────────────────┐          │
│              │           Databases               │          │
│              │  ┌────────────┐  ┌────────────┐  │          │
│              │  │ PostgreSQL │  │   Redis    │  │          │
│              │  │   :5432    │  │   :6379    │  │          │
│              │  └────────────┘  └────────────┘  │          │
│              └──────────────────────────────────┘          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
              │
              │ Cloudflare Tunnel
              ▼
        [comparateur.fr]
```

## Environment Details

| Service | Version | Port | Status |
|---------|---------|------|--------|
| Dokploy | latest | 3000 | ✅ Running |
| PostgreSQL | 17.2 | 5432 | ✅ Running |
| TimescaleDB | 2.17.0 | - | ✅ Extension |
| Redis | 7.4.1 | 6379 | ✅ Running |
| Traefik | latest | 80/443 | ✅ Running |

## Connection Strings

```bash
# PostgreSQL
DATABASE_URL=postgresql://pareto:password@localhost:5432/pareto

# Redis
REDIS_URL=redis://localhost:6379/0
```

## Notes

- Infrastructure is already available on local PC
- No additional setup required
- Move to Phase 02: Monorepo Setup

---

**Next Phase**: [02-monorepo.md](./02-monorepo.md)
**Back to**: [Foundation README](./README.md)
