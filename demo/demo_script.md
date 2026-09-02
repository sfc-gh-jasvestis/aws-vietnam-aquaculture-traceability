# Farm-to-Export Traceability

**Vietnam - Aquaculture & Seafood**
Use case: Supply Chain Traceability

> Farm-to-Export Traceability for Vietnam - ML.FORECAST and Dynamic Tables power real-time supply chain traceability intelligence for aquaculture & seafood in Mekong Delta.

## Why Snowflake

Snowflake delivers supply chain traceability intelligence for Vietnamese aquaculture & seafood - Dynamic Tables maintain real-time dashboards, ML.FORECAST projects key metrics, and Cortex AI generates recommendations

- **ML.FORECAST for supply chain traceability** - Only demo for Vietnamese aquaculture & seafood
- **ML.ANOMALY_DETECTION early warning** - Detects deviations before impact
- **AI recommendations** - Cortex AI actionable guidance
- **Vietnamese context** - Local names, VND economics

## What is deployed

| | |
|---|---|
| Database | `VIETNAM_AQUACULTURE_TRACEABILITY` |
| Service | `VIETNAM_AQUACULTURE_TRACEABILITY_APP` |
| Compute pool | `SEA_DEMOS_VIETNAM_POOL` |
| Dimension table | `RAW.FARMS` (20 rows) |
| Fact table | `RAW.BATCH_MOVEMENTS` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | VND (₫) |

Regions in play: Ho Chi Minh City, Hanoi, Binh Duong, Dong Nai, Can Tho
Segments: Hatchery, Grow-Out Pond, Processing Plant, Export Lot

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh VIETNAM_AQUACULTURE_TRACEABILITY
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| Traceability Coverage | `94%` | average per event |
| Batches Tracked | `42K` | total across Farms |
| Harvest-to-Export | `4.2 days` | average per event |
| Certified Farms | `2,847` | total across Farms |
| QR-Code Scans/Day | `14K` | average per event |
| Farm-to-Plate Time | `6.2 days` | average per event |
| Data Completeness | `97%` | average per event |


## Demo flow

1. Overview
2. Analytics
3. AI Intelligence
4. Ask AI
5. Architecture

## Talking points

- **100K operations** - tracked in Mekong Delta
- **500K metrics** - time-series data points
- **5K assets** - monitored
- **100 docs** - searchable

## Business impact

- Vietnam aquaculture & seafood sector growing rapidly (GSO Vietnam)
- AI improves outcomes 15-30% (McKinsey)
- Vietnam FDI strong in this sector (MPI)
- Real-time analytics reduces response 60-80% (Gartner)

---
Generated from `generator/demo_specs/aws-vietnam-aquaculture-traceability.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-vietnam-aquaculture-traceability` instead.
