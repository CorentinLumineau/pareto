# Phase 05: Store Submission

> **App Store and Play Store submission**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      05 - Store Submission                             ║
║  Initiative: Mobile                                            ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     4 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Prepare and submit apps to App Store and Google Play Store.

## Tasks

- [ ] Configure EAS Build
- [ ] Create app icons and screenshots
- [ ] Write store listings
- [ ] Build production apps
- [ ] Submit for review

## EAS Configuration

```json
// apps/mobile/eas.json
{
    "cli": {
        "version": ">= 10.0.0"
    },
    "build": {
        "development": {
            "developmentClient": true,
            "distribution": "internal"
        },
        "preview": {
            "distribution": "internal",
            "ios": {
                "simulator": false
            }
        },
        "production": {
            "ios": {
                "resourceClass": "m-medium"
            },
            "android": {
                "buildType": "apk"
            }
        }
    },
    "submit": {
        "production": {
            "ios": {
                "appleId": "your-apple-id@email.com",
                "ascAppId": "your-app-store-connect-app-id"
            },
            "android": {
                "serviceAccountKeyPath": "./google-service-account.json",
                "track": "internal"
            }
        }
    }
}
```

## App Store Listing

### French (fr-FR)

```yaml
# App Store Connect metadata
name: "Pareto - Comparateur Smartphones"
subtitle: "Trouvez le meilleur rapport qualité-prix"
description: |
  Pareto est le comparateur intelligent qui vous aide à trouver
  le smartphone parfait grâce à l'optimisation Pareto.

  📊 COMPARAISON INTELLIGENTE
  • Comparez les prix de 6 grands retailers français
  • Visualisez les meilleurs compromis avec la frontière de Pareto
  • Découvrez quel produit est vraiment le meilleur pour vous

  💰 ÉCONOMISEZ DE L'ARGENT
  • Trouvez le meilleur prix sur Amazon, Fnac, Cdiscount...
  • Suivez l'historique des prix
  • Recevez des alertes quand le prix baisse

  🏆 NOS RECOMMANDATIONS
  • Meilleur choix global
  • Meilleur rapport qualité-prix
  • Meilleur choix économique
  • Meilleur choix premium

  ✨ FONCTIONNALITÉS
  • Recherche instantanée
  • Fiches produits détaillées
  • Comparaison multi-critères
  • Alertes de prix personnalisées
  • Interface simple et intuitive

  Pareto utilise l'optimisation multi-objectifs pour vous montrer
  les produits qui offrent les meilleurs compromis - pas seulement
  le moins cher, mais le meilleur rapport qualité-prix.

keywords:
  - comparateur
  - smartphone
  - prix
  - iphone
  - samsung
  - android
  - amazon
  - fnac
  - cdiscount

promotional_text: |
  Nouveau: Alertes de prix et comparaison Pareto !

privacy_url: "https://pareto.fr/politique-confidentialite"
support_url: "https://pareto.fr/contact"
```

### Categories
- Primary: Shopping
- Secondary: Utilities

## Play Store Listing

```yaml
# Google Play Console metadata
title: "Pareto - Comparateur Smartphones"
short_description: "Comparez les prix et trouvez le meilleur smartphone"
full_description: |
  Pareto est le comparateur intelligent qui vous aide à trouver
  le smartphone parfait grâce à l'optimisation Pareto.

  [Continue with same description as App Store]

category: "SHOPPING"
content_rating: "Everyone"

# Required graphics
feature_graphic: 1024x500
phone_screenshots: 1080x1920 (min 2, max 8)
tablet_screenshots: 2560x1600 (optional)
```

## Screenshot Requirements

### iOS
- 6.7" (iPhone 15 Pro Max): 1290 x 2796
- 6.5" (iPhone 14 Plus): 1284 x 2778
- 5.5" (iPhone 8 Plus): 1242 x 2208

### Android
- Phone: 1080 x 1920 (min)
- 7" Tablet: 1200 x 1920
- 10" Tablet: 1800 x 2560

### Screenshots to Create
1. Home screen with search
2. Product list
3. Product detail with prices
4. Pareto comparison chart
5. Price history
6. Price alert setup

## Build Commands

```bash
# Login to EAS
eas login

# Configure build credentials
eas credentials

# Build for iOS
eas build --platform ios --profile production

# Build for Android
eas build --platform android --profile production

# Submit to App Store
eas submit --platform ios --latest

# Submit to Play Store
eas submit --platform android --latest
```

## Pre-submission Checklist

### iOS App Store

- [ ] Apple Developer Program membership (99€/year)
- [ ] App icons (1024x1024, no alpha)
- [ ] Screenshots for all required sizes
- [ ] App Store Connect app created
- [ ] Privacy policy URL
- [ ] App Review Information filled
- [ ] Age rating questionnaire completed
- [ ] Test account provided (if login required)

### Google Play Store

- [ ] Google Play Developer account (25$ one-time)
- [ ] App icons and feature graphic
- [ ] Screenshots for phone and tablet
- [ ] Store listing in French
- [ ] Privacy policy URL
- [ ] Content rating questionnaire
- [ ] Target audience declaration
- [ ] Data safety section completed

## Privacy & Data Safety

### App Store Privacy Labels
```yaml
data_collected:
  - Analytics:
      - Usage data (not linked to identity)
  - Identifiers:
      - Device ID (for analytics only)

data_not_collected:
  - Contact info
  - User content
  - Location
  - Health & fitness
```

### Play Store Data Safety
```yaml
data_shared: No data shared with third parties
data_collected:
  - App interactions (analytics)
  - Device identifiers

security_practices:
  - Data encrypted in transit
  - Data deletion available
```

## Post-submission

1. **Monitor review status** in App Store Connect / Play Console
2. **Respond quickly** to any reviewer questions
3. **Fix any rejection reasons** and resubmit
4. **Plan staged rollout** for first version

## Deliverables

- [ ] EAS configuration complete
- [ ] App icons and screenshots created
- [ ] Store listings written (FR)
- [ ] iOS build submitted
- [ ] Android build submitted
- [ ] Apps approved and live

---

**Previous Phase**: [04-native.md](./04-native.md)
**Back to**: [Mobile README](./README.md)
