# Roblox in-game items: sales guide and game audit

Policy checked: October 16, 2026  
Purpose: suggest products and review a fishing, chest, and pet-egg game's monetization.

## 1. Scope and how to use this file

This is a Roblox platform-policy guide, not a certificate that every product is lawful everywhere. Local game publishing, consumer, tax, and gambling requirements require a separate jurisdiction-specific review. This document does not determine Vietnam licensing obligations.

Policy statements reference official sources [1]–[12]. Product ideas, engineering checks, and launch priorities are recommendations, not additional Roblox requirements. Recheck sources before launch or changing monetization.

The preliminary audit below uses only the fishing/chest/pet concepts discussed in this chat. No current Roblox project, full economy configuration, or purchase implementation was inspected. The supplied web-project attachments are not evidence of Roblox implementation.

Use this file to:

1. Inventory every sale and route to a reward.
2. Classify the product using section 2.
3. Review restrictions in sections 3–4.
4. Record evidence using sections 5–6.
5. Give section 7 to a reviewer or coding assistant with your actual game files.

## 2. Products you can offer

Passes support one-time purchases of lasting benefits. Developer Products support repeat purchases. These are sales mechanisms, not automatic delivery systems; implement the promised benefits. [1][2]

The following are proposed examples, not blanket approvals of any implementation.

| Product idea | What the buyer receives | Suggested mechanism | Review focus |
| --- | --- | --- | --- |
| Rod appearance | A named cosmetic skin | Pass for one permanent unlock | No hidden luck effect |
| Boat decoration | Specified paint or decoration | Pass | Accurate preview |
| Inventory expansion | One fixed permanent capacity increase | Pass | Restore benefit on rejoin |
| Additional pet slots | A stated number of extra equip slots | Pass | Define the exact limit |
| VIP package | Listed title, cosmetics, and lounge access | Pass | List every benefit |
| Auto-sell | A permanent convenience feature | Pass | Explain its behavior |
| Movement upgrade | A stated permanent speed increase | Pass | Balance and honest description |
| Coin pack | A fixed currency quantity | Developer Product | Trace what coins can buy |
| Timed coin boost | A defined reward multiplier and duration | Developer Product | State stacking and expiry |
| Bait pack | A fixed number of consumables | Developer Product | Check reward/odds effects |
| Named pet | The specific pet displayed | Pass if unique; product if repeatable | No hidden random stats or variant |
| Mystery egg/chest | A random reward | Usually Developer Product | Paid-random-item review |
| Private fishing server | Access to a private game session | Roblox private servers | Access and parental restrictions |

Private servers can be free or charge monthly Robux. They cannot be enabled together with paid game access. [6]

An in-game pet or skin is not automatically a Roblox avatar Marketplace item. Selling accessories wearable across Roblox has a separate publishing, moderation, eligibility, and fee process. [8]

### Suggested first shop

Start with a rod appearance, fixed inventory expansion, guaranteed pet, and clearly defined coin boost. This is a simplicity recommendation. Your first release can contain purchases; a free-only first version is not a publishing requirement. Keep the basic loop enjoyable without purchases. [1][2][7]

Do not set prices from this document: choose them after testing progression, benefits, and applicable managed prices.

## 3. Random rewards and payment paths

Random rewards paid for directly or through Robux-purchasable currency are covered by paid-random-item rules. Keys, rerolls, combinations, and probability modifiers also need review. [3]

| Reward path | Classification for review |
| --- | --- |
| Complete a fishing action for an unpaid random catch | Gameplay reward; confirm no payment dependency |
| Spend Robux to open a chest | Paid random item |
| Buy coins with Robux, then buy a mystery egg | Paid random item |
| Buy a key that opens an otherwise free chest | Paid random item |
| Buy a named pet with fixed properties | Guaranteed purchase |
| Buy a pet whose appearance or stats are randomized | Contains a paid random outcome |
| Buy a rod that improves rare-item probabilities | Paid probability modifier |
| Buy a guaranteed bundle containing a mystery egg | Paid random bundle |

The table applies the policy to proposed mechanics; exact classification depends on the implemented payment path. A currency earned through play is not automatically exempt if it is also purchasable with Robux.

### Required policy checks

- Reveal all final outcomes and numerical percentage odds before purchase; probabilities must total 100%, subject to the documented display-rounding guidance. Rarity labels alone do not identify individual outcomes. [3]
- Keep probabilities consistent with the player's current state, including modifiers and duplicate exclusions. [3]
- Explain paid odds changes numerically; show updated odds when active. [3]
- Use `PolicyService:GetPolicyInfoForPlayerAsync()`: respect `ArePaidRandomItemsRestricted` for paid randomness and `IsPaidItemTradingAllowed` for paid-item trading. Permission to acquire does not establish permission to trade. [4][11]
- Each paid random outcome must give a benefit, rather than simply lose the payment. [4]

Recommendation: if policy lookup fails, keep affected purchases unavailable while retrying; leave unrelated gameplay working. Enforce decisions on the server, not only by hiding buttons. This is defensive implementation guidance. [9]

### Paid speed, bait, and auto-fishing

A purchase improving catch frequency without explicitly changing probabilities can still affect a random-reward economy. Do not declare it exempt based only on its name. Document what payment buys, what is consumed, how outcomes are generated, and whether odds change. Treat ambiguous designs as NEEDS_REVIEW before selling them. This is a conservative audit approach, not a quoted Roblox ruling.

## 4. Sales boundaries and technical checks

### Platform boundaries

Roblox prohibits gambling activities, unauthorized off-platform sales of virtual content, misleading offers, and intellectual-property infringement. Do not independently offer Robux or real-money-value prizes through competitions or games of chance without Roblox's involvement. A paid egg following the random-item rules is not permission to add betting. [4]

For this game's design, exclude cash-out promises, Robux jackpots, external payment links for pets, and copied characters or music without appropriate rights. These are applications of those rules. Keep asset ownership/license evidence.

Do not describe bought advantages as permanent and then silently remove them. Review changes to existing purchases against the original promise and current policy. [4]

### Purchase implementation

Fulfill Developer Products through Roblox's documented server receipt handling, such as `MarketplaceService.ProcessReceipt`. The current API reference also documents `BindReceiptHandler` for Developer Product receipts; review compatibility before changing an existing handler. A purchase prompt closing is not proof that the item was delivered. [2][12]

Engineering checks recommended for this game:

- The server maps approved product IDs to fixed reward definitions.
- Receipt processing handles retries without granting twice.
- A disconnect or full inventory does not silently destroy a purchase.
- A failed persistence operation is recoverable before acknowledging delivery.
- Pass benefits are checked and reapplied when the player joins. [1]
- Clients cannot choose their own catch, currency award, or purchase result. [9]
- Tests cover canceled prompts, duplicate receipt delivery, reconnects, and storage failures.

With managed pricing, retrieve prices dynamically for custom shop UI; do not hard-code a Robux price that differs from the actual prompt. Regional pricing is enabled by default for passes. Trading or gifting across price regions needs review for arbitrage. [5]

### Costs and publishing

For standard own-game pass/product sales, Roblox's introductory guide describes a 70% creator share and 30% platform fee. Avatar Marketplace sales use different rules. [7][8]

Publishing eligibility is separate from the shop. Initial 16+ publishing and reaching younger audiences have different requirements; an old account alone is insufficient. Review current verification, content rating, fee/subscription, and evaluation requirements before launch. [10]

## 5. Preliminary audit of the discussed game concept

No PASS below is implied. These are conditional findings, not observed code defects.

| ID | Proposed feature | Preliminary assessment | Evidence needed / next action |
| --- | --- | --- | --- |
| C01 | Fishing yields chests and eggs | NEEDS_REVIEW | Map every payment, consumption, and reward step |
| C02 | Eggs contain random pets | NEEDS_REVIEW | Identify free, paid, and mixed acquisition routes |
| C03 | Chests contain items, coins, or movement boosts | NEEDS_REVIEW | Inspect reward tables, duration, and purchase dependencies |
| C04 | Cosmetic rod or boat skins | SUGGESTED | Confirm rights, preview, and absence of hidden random effects |
| C05 | Selling a specific pet | SUGGESTED | Freeze promised variant and stats; decide duplicates |
| C06 | Coins for Robux | NEEDS_REVIEW | List all sinks; locate any random-reward purchases |
| C07 | Paid luck, bait, or rods | NEEDS_REVIEW | Describe probability and reward-frequency changes |
| C08 | Pet trading | UNVERIFIED | Confirm feature exists; inspect policy checks and provenance |
| C09 | Receipt fulfillment and saving | UNVERIFIED | Inspect server code and failure/retry tests |
| C10 | Audience eligibility | UNVERIFIED | Inspect Creator Hub eligibility and rating settings |

Recommended release decision: approve individual products only after evidence review. Defer ambiguous monetization while keeping a tested direct-purchase shop possible. No implementation has been certified ready.

## 6. Fill-in product record and release checklist

Duplicate this record for every product:

```yaml
product_id: TODO
name: TODO
purchase_type: pass_or_developer_product_or_private_server
promised_reward: TODO
duration_and_quantity: TODO
repeat_purchase_behavior: TODO
currency_and_payment_path: TODO
random_outcomes_or_stats: TODO
odds_modifiers: TODO
trading_or_gifting: TODO
player_restrictions: TODO
ui_and_code_evidence: TODO
delivery_and_retry_evidence: TODO
asset_rights_evidence: TODO
review_status: UNVERIFIED
reviewer_and_date: TODO
```

These are reviewer workflow checks, with policy references in sections 2–4:

- [ ] Every sale and indirect reward route is recorded.
- [ ] Each policy requirement is linked to current official guidance.
- [ ] Random-reward and trading restrictions have evidence.
- [ ] Prices and benefits match the purchase prompt.
- [ ] Delivery, saving, and retry tests have results.
- [ ] Product descriptions match actual quantities and durations.
- [ ] Asset rights and audience settings are reviewed.
- [ ] Missing evidence is marked UNVERIFIED, never assumed compliant.
- [ ] Country-specific questions have a separate review owner where applicable.

Use PASS, FAIL, NEEDS_REVIEW, UNVERIFIED, or NOT_APPLICABLE. A failed critical payment or policy check blocks the affected feature; missing evidence prevents approval. A completed checklist is not Roblox approval or a legal opinion.

## 7. Reusable instruction for auditing this game

Copy this instruction into a new review with your GDD, product list, reward tables, screenshots, and relevant server scripts:

```text
Audit my Roblox game's monetization using this Markdown guide.

First inventory the provided evidence. Do not claim to have inspected
files, Creator Hub settings, or running behavior that are unavailable.
Never request passwords, tokens, private keys, or unrelated secrets.

Check current official Roblox sources and state the review date.
Separate platform policy, engineering recommendations, balance concerns,
and jurisdiction-specific legal questions. Do not invent policies or
describe a product as lawful in every country.

Trace Robux -> currency/key/bait/boost -> chest/egg/catch -> reward -> trade.
Find direct and indirect randomness, hidden randomized properties,
paid probability changes, and mixed free/paid currency routes.

Review receipt delivery, retry safety, persistence, pass restoration,
dynamic prices, server validation, player policy restrictions,
asset rights, and the promises shown to buyers.

For each finding provide:
ID | feature | status | policy or recommendation | evidence location |
source | practical impact | smallest corrective change | verification.

Use PASS, FAIL, NEEDS_REVIEW, UNVERIFIED, or NOT_APPLICABLE.
Distinguish confirmed defects from conditional risks.
Suggest up to five suitable products based on the actual game loop.
Give launch blockers and a prioritized fix list.
Only change code if separately requested; follow existing patterns and
keep fixes simple. Do not invent prices or revenue forecasts.
End with the evidence still needed to approve each unresolved feature.
```

## 8. Official references

Accessed October 16, 2026. Links are included so this file remains useful outside ChatGPT.

1. [Passes](https://create.roblox.com/docs/production/monetization/passes)
2. [Developer Products](https://create.roblox.com/docs/production/monetization/developer-products)
3. [Paid random items policy guidelines](https://create.roblox.com/docs/production/monetization/paid-random-items)
4. [Roblox Community Standards](https://about.roblox.com/community-standards) — economy, paid items, gambling, integrity, and intellectual property.
5. [Regional pricing](https://create.roblox.com/docs/production/monetization/regional-pricing)
6. [Private servers](https://create.roblox.com/docs/production/monetization/private-servers)
7. [How do I make money?](https://create.roblox.com/docs/get-started/monetization)
8. [Marketplace fees and commissions](https://create.roblox.com/docs/marketplace/marketplace-fees-and-commissions)
9. [Server-side detection and consequencing](https://create.roblox.com/docs/scripting/security/server-side-detection)
10. [Roblox Kids and Select](https://create.roblox.com/docs/production/publishing/kids-and-select)
11. [PolicyService](https://create.roblox.com/docs/reference/engine/classes/PolicyService)
12. [MarketplaceService — ProcessReceipt](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService#ProcessReceipt)
