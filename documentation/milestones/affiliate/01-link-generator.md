# Phase 01: Link Generator

> **Affiliate URL building per network**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      01 - Link Generator                               ║
║  Initiative: Affiliate                                         ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     2 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Build affiliate URL generators for each network (Amazon Associates, Awin, Effinity).

## Tasks

- [ ] Implement network interface
- [ ] Amazon Associates generator
- [ ] Awin generator (Fnac, Darty, Boulanger, LDLC)
- [ ] Effinity generator (Cdiscount)
- [ ] URL validation
- [ ] Unit tests

## Network Interface

```go
// apps/api/internal/affiliate/network.go
package affiliate

import "net/url"

// Network represents an affiliate network
type Network interface {
    // BuildURL converts a product URL to an affiliate URL
    BuildURL(productURL string) (string, error)

    // GetNetworkID returns the network identifier
    GetNetworkID() string

    // ValidateURL checks if a URL belongs to this network's retailers
    ValidateURL(productURL string) bool
}

// Config holds affiliate credentials
type Config struct {
    AmazonTag       string // Amazon Associates tag
    AwinAffiliateID string // Awin affiliate ID
    AwinMerchantIDs map[string]string // retailer -> merchant ID
    EffinityID      string // Effinity compteur ID
}
```

## Amazon Associates

```go
// apps/api/internal/affiliate/amazon.go
package affiliate

import (
    "fmt"
    "net/url"
    "strings"
)

type AmazonNetwork struct {
    tag string
}

func NewAmazonNetwork(tag string) *AmazonNetwork {
    return &AmazonNetwork{tag: tag}
}

func (n *AmazonNetwork) GetNetworkID() string {
    return "amazon"
}

func (n *AmazonNetwork) ValidateURL(productURL string) bool {
    return strings.Contains(productURL, "amazon.fr")
}

func (n *AmazonNetwork) BuildURL(productURL string) (string, error) {
    parsed, err := url.Parse(productURL)
    if err != nil {
        return "", err
    }

    // Add or replace tag parameter
    q := parsed.Query()
    q.Set("tag", n.tag)
    parsed.RawQuery = q.Encode()

    return parsed.String(), nil
}

// Example:
// Input:  https://www.amazon.fr/dp/B0ABC123
// Output: https://www.amazon.fr/dp/B0ABC123?tag=pareto-21
```

## Awin Network

```go
// apps/api/internal/affiliate/awin.go
package affiliate

import (
    "fmt"
    "net/url"
    "strings"
)

type AwinNetwork struct {
    affiliateID string
    merchantIDs map[string]string // domain -> merchant ID
}

func NewAwinNetwork(affiliateID string, merchantIDs map[string]string) *AwinNetwork {
    return &AwinNetwork{
        affiliateID: affiliateID,
        merchantIDs: merchantIDs,
    }
}

func (n *AwinNetwork) GetNetworkID() string {
    return "awin"
}

func (n *AwinNetwork) ValidateURL(productURL string) bool {
    for domain := range n.merchantIDs {
        if strings.Contains(productURL, domain) {
            return true
        }
    }
    return false
}

func (n *AwinNetwork) BuildURL(productURL string) (string, error) {
    parsed, err := url.Parse(productURL)
    if err != nil {
        return "", err
    }

    // Find merchant ID for this domain
    var merchantID string
    for domain, mid := range n.merchantIDs {
        if strings.Contains(parsed.Host, domain) {
            merchantID = mid
            break
        }
    }

    if merchantID == "" {
        return "", fmt.Errorf("no merchant ID for domain: %s", parsed.Host)
    }

    // Build Awin redirect URL
    // Format: https://www.awin1.com/cread.php?awinmid=XXXXX&awinaffid=YYYYY&ued=ENCODED_URL
    awinURL := fmt.Sprintf(
        "https://www.awin1.com/cread.php?awinmid=%s&awinaffid=%s&ued=%s",
        merchantID,
        n.affiliateID,
        url.QueryEscape(productURL),
    )

    return awinURL, nil
}

// Merchant IDs (example values, get real ones from Awin dashboard):
// Fnac: 12345
// Darty: 12346
// Boulanger: 12347
// LDLC: 12348
```

## Effinity Network

```go
// apps/api/internal/affiliate/effinity.go
package affiliate

import (
    "fmt"
    "net/url"
    "strings"
)

type EffinityNetwork struct {
    compteurID string
}

func NewEffinityNetwork(compteurID string) *EffinityNetwork {
    return &EffinityNetwork{compteurID: compteurID}
}

func (n *EffinityNetwork) GetNetworkID() string {
    return "effinity"
}

func (n *EffinityNetwork) ValidateURL(productURL string) bool {
    return strings.Contains(productURL, "cdiscount.com")
}

func (n *EffinityNetwork) BuildURL(productURL string) (string, error) {
    // Format: https://track.effiliation.com/servlet/effi.click?id_compteur=XXXXX&url=ENCODED_URL
    effinityURL := fmt.Sprintf(
        "https://track.effiliation.com/servlet/effi.click?id_compteur=%s&url=%s",
        n.compteurID,
        url.QueryEscape(productURL),
    )

    return effinityURL, nil
}
```

## Link Generator Service

```go
// apps/api/internal/affiliate/generator.go
package affiliate

import (
    "fmt"
    "pareto/internal/catalog/models"
)

type LinkGenerator struct {
    networks map[string]Network
    retailerToNetwork map[string]string
}

func NewLinkGenerator(config *Config) *LinkGenerator {
    g := &LinkGenerator{
        networks: make(map[string]Network),
        retailerToNetwork: map[string]string{
            "amazon_fr": "amazon",
            "fnac":      "awin",
            "darty":     "awin",
            "boulanger": "awin",
            "ldlc":      "awin",
            "cdiscount": "effinity",
        },
    }

    // Initialize networks
    g.networks["amazon"] = NewAmazonNetwork(config.AmazonTag)
    g.networks["awin"] = NewAwinNetwork(config.AwinAffiliateID, config.AwinMerchantIDs)
    g.networks["effinity"] = NewEffinityNetwork(config.EffinityID)

    return g
}

// GenerateAffiliateURL creates affiliate URL for an offer
func (g *LinkGenerator) GenerateAffiliateURL(offer *models.Offer) (string, error) {
    networkID, ok := g.retailerToNetwork[offer.RetailerID]
    if !ok {
        return "", fmt.Errorf("no affiliate network for retailer: %s", offer.RetailerID)
    }

    network, ok := g.networks[networkID]
    if !ok {
        return "", fmt.Errorf("network not configured: %s", networkID)
    }

    return network.BuildURL(offer.URL)
}

// UpdateOfferAffiliateURLs generates and stores affiliate URLs for all offers
func (g *LinkGenerator) UpdateOfferAffiliateURLs(offers []*models.Offer) error {
    for _, offer := range offers {
        affiliateURL, err := g.GenerateAffiliateURL(offer)
        if err != nil {
            // Log error but continue
            continue
        }
        offer.AffiliateURL = &affiliateURL
    }
    return nil
}
```

## Configuration

```go
// apps/api/internal/affiliate/config.go
package affiliate

import "os"

func LoadConfig() *Config {
    return &Config{
        AmazonTag:       os.Getenv("AMAZON_ASSOCIATE_TAG"),
        AwinAffiliateID: os.Getenv("AWIN_AFFILIATE_ID"),
        AwinMerchantIDs: map[string]string{
            "fnac.com":      os.Getenv("AWIN_FNAC_MERCHANT_ID"),
            "darty.com":     os.Getenv("AWIN_DARTY_MERCHANT_ID"),
            "boulanger.com": os.Getenv("AWIN_BOULANGER_MERCHANT_ID"),
            "ldlc.com":      os.Getenv("AWIN_LDLC_MERCHANT_ID"),
        },
        EffinityID: os.Getenv("EFFINITY_COMPTEUR_ID"),
    }
}
```

## Unit Tests

```go
// apps/api/internal/affiliate/generator_test.go
package affiliate

import (
    "testing"
    "github.com/stretchr/testify/assert"
)

func TestAmazonNetwork(t *testing.T) {
    network := NewAmazonNetwork("pareto-21")

    url, err := network.BuildURL("https://www.amazon.fr/dp/B0ABC123")
    assert.NoError(t, err)
    assert.Contains(t, url, "tag=pareto-21")
}

func TestAwinNetwork(t *testing.T) {
    network := NewAwinNetwork("123456", map[string]string{
        "fnac.com": "789",
    })

    url, err := network.BuildURL("https://www.fnac.com/a123/product")
    assert.NoError(t, err)
    assert.Contains(t, url, "awinmid=789")
    assert.Contains(t, url, "awinaffid=123456")
}

func TestEffinityNetwork(t *testing.T) {
    network := NewEffinityNetwork("999")

    url, err := network.BuildURL("https://www.cdiscount.com/f-123")
    assert.NoError(t, err)
    assert.Contains(t, url, "id_compteur=999")
}
```

## Deliverables

- [ ] Network interface defined
- [ ] Amazon Associates generator
- [ ] Awin generator with merchant IDs
- [ ] Effinity generator
- [ ] Link generator service
- [ ] Unit tests >90% coverage

---

**Next Phase**: [02-click-tracking.md](./02-click-tracking.md)
**Back to**: [Affiliate README](./README.md)
