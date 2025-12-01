# Phase 04: Go-Live

> **Final launch checklist and public launch**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      04 - Go-Live                                      ║
║  Initiative: Launch                                            ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     2 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Final preparations and public launch of the MVP.

## Tasks

- [ ] Final launch checklist
- [ ] Soft launch (friends & family)
- [ ] Fix critical issues
- [ ] Public launch
- [ ] Post-launch monitoring

## Pre-Launch Checklist

### Infrastructure ✅
- [ ] All services healthy in Dokploy
- [ ] Cloudflare Tunnel stable
- [ ] SSL certificates valid
- [ ] Database backups verified
- [ ] Redis persistence confirmed

### Data ✅
- [ ] >500 products in database
- [ ] All 6 retailers scraping
- [ ] Price history > 7 days
- [ ] No duplicate products
- [ ] Prices accurate (spot check)

### Security ✅
- [ ] Environment variables secured
- [ ] Database passwords rotated
- [ ] Internal API tokens set
- [ ] Rate limiting enabled
- [ ] CORS configured

### SEO ✅
- [ ] Sitemap.xml generated
- [ ] Robots.txt correct
- [ ] Meta tags on all pages
- [ ] JSON-LD structured data
- [ ] Google Search Console setup

### Legal ✅
- [ ] Privacy policy published
- [ ] Terms of service published
- [ ] Cookie consent working
- [ ] Affiliate disclosure visible

### Analytics ✅
- [ ] Google Analytics configured
- [ ] Events tracking working
- [ ] Affiliate click tracking working

### Mobile Apps ✅
- [ ] iOS app approved (or in review)
- [ ] Android app approved (or in review)
- [ ] Deep links working

## Soft Launch Plan

### Day 1: Friends & Family
```
Timeline:
09:00 - Final deployment check
10:00 - Send invites to 10-20 people
10:00-18:00 - Monitor and collect feedback
18:00 - Triage feedback, prioritize fixes
```

### Feedback Collection
```markdown
# Soft Launch Feedback Form

1. What device/browser did you use?
2. Did you encounter any errors? (screenshot if possible)
3. Was the site easy to navigate? (1-5)
4. Did prices match what you see on retailer sites?
5. Would you use this site again? Why/why not?
6. Any other feedback?
```

### Day 2: Fix Critical Issues
- Address any critical bugs
- Fix major UX issues
- Optimize performance if needed
- Re-test fixed issues

## Public Launch Plan

### Pre-Launch (Morning)
```
08:00 - Final health checks
08:30 - Backup database
09:00 - Clear caches
09:30 - Final smoke test
```

### Launch (10:00)
```
10:00 - 🚀 Site is live!
10:01 - Post announcement
10:05 - Verify everything working
```

### Launch Announcement

```markdown
# Twitter/X
🚀 Pareto est lancé !

Le comparateur de smartphones intelligent qui utilise
l'optimisation Pareto pour trouver le meilleur rapport qualité-prix.

✅ 500+ smartphones
✅ 6 retailers français
✅ Historique des prix
✅ Web + iOS + Android

👉 pareto.fr
```

```markdown
# Reddit (r/france, r/bonsplans)
[Projet perso] J'ai créé un comparateur de smartphones avec
optimisation Pareto

Après plusieurs mois de développement, je lance Pareto -
un comparateur de prix de smartphones qui va au-delà du
simple "moins cher".

**Ce que ça fait:**
- Compare les prix sur Amazon, Fnac, Cdiscount, Darty, Boulanger, LDLC
- Utilise l'optimisation Pareto pour trouver les meilleurs compromis
- Historique des prix sur 30 jours
- Apps iOS et Android

**Stack technique:** Go, Python, Next.js, Expo, PostgreSQL

Feedback bienvenu !

👉 pareto.fr
```

## Post-Launch Monitoring

### First 24 Hours

| Check | Frequency |
|-------|-----------|
| Service health | Every 15 min |
| Error logs | Every 30 min |
| Response times | Every hour |
| User feedback | Continuous |
| Traffic stats | Every hour |

### Metrics to Watch

```
Critical:
- Uptime (target: 100% first 24h)
- Error rate (target: <1%)
- P95 response time (target: <500ms)

Important:
- Unique visitors
- Page views
- Bounce rate
- Session duration

Nice to have:
- Click-through rate
- Top products viewed
- Search queries
```

### Incident Response

```
Severity 1 (Site down):
1. Check Uptime Kuma
2. Check Dokploy logs
3. Restart affected service
4. Rollback if needed
5. Post status update

Severity 2 (Feature broken):
1. Log the issue
2. Attempt quick fix
3. Deploy fix or disable feature
4. Plan proper fix

Severity 3 (Minor issue):
1. Log in backlog
2. Fix in next deploy
```

## Launch Success Criteria

| Metric | Day 1 Target | Week 1 Target |
|--------|-------------|---------------|
| Uptime | 100% | >99% |
| Unique visitors | 10 | 100 |
| Page views | 50 | 500 |
| Errors | 0 critical | 0 critical |
| User feedback | Collected | Addressed |

## Post-Launch Roadmap

### Week 1
- Monitor and fix bugs
- Respond to user feedback
- Optimize based on real usage

### Week 2-4
- Apply for affiliate programs (with traffic proof)
- Add more products
- Improve SEO

### Month 2+
- Add new categories (laptops, tablets)
- User accounts (wishlists, alerts)
- Performance optimizations

## Deliverables

- [ ] Pre-launch checklist complete
- [ ] Soft launch completed
- [ ] Critical issues fixed
- [ ] Public launch executed
- [ ] Post-launch monitoring active
- [ ] 🎉 MVP LIVE!

---

**Previous Phase**: [03-testing.md](./03-testing.md)
**Back to**: [Launch README](./README.md)

---

## 🎉 CONGRATULATIONS!

You've completed the Pareto Comparator MVP!

Next steps:
1. Monitor and iterate
2. Apply for affiliate programs
3. Grow organic traffic
4. Plan v1.1 features
