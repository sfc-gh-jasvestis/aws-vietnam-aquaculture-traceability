# Vietnam Aquaculture Farm-to-Export Traceability

**Vietnam - Aquaculture and seafood supply chain**
Use case: Chain of custody for farmed pangasius and shrimp, from registered pond to export lot, in a fictional supply chain

> A fictional Mekong Delta seafood supply chain, 40 processing plants from Ca Mau to Cao Lanh, traced from pond harvest to export lot: dynamic tables for traceability to a registered pond, a holdout-evaluated custody-break classifier, a harvest-lot transfer forecast and grounded AI answers. Custody checks are demo signals, not audit or certification verdicts.

## Why Snowflake

- **Dynamic tables** reconcile harvest-lot custody transfers, traceability to registered pond, custody flags, confirmed custody breaks and mass-balance reconciliation rates from RAW plant data, with checks in `run_core.py`
- **Custody-break classification** gives a holdout-evaluated next-7-day probability per plant
- **Harvest-lot forecast** projects 14 days of network-wide custody transfers with prediction intervals, for plant intake planning
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations
- **Live transfers**: a native receiving-feed simulator (Snowflake only) or Amazon Data Firehose, S3 and Snowpipe (AWS build), then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.PLANTS` (40 rows) |
| Fact table | `RAW.PLANT_DAILY` (3,600 plant-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `SIGNAL_SUMMARY`, `TREND_ANALYSIS` |
| ML | `ML.CUSTODY_RISK_SCORES`, `ML.CUSTODY_RISK_HOLDOUT_METRICS`, `ML.LOT_FORECAST`, `ML.MB_VARIANCE_ANOMALIES` |

Cities: Ca Mau, Bac Lieu, Soc Trang, Can Tho, Long Xuyen, Cao Lanh, Ben Tre, Rach Gia.
Sourcing models: Company farm plant, Cooperative group plant, Household pond plant, Trader-supplied plant, Contract grower plant.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| Traceability to Registered Pond | 80.7% |
| Harvest Lot Transfers | 43,756 |
| Harvest Received (kt) | 345 |
| Custody Flags | 561 |
| Confirmed Custody Breaks | 155 |
| Flag Precision | 27.6% |
| Export Lots Held | 62 |
| Mass-Balance Reconciliation Rate | 81.0% |
| Plants Monitored | 40 |
| Pond Link Coverage | 67.2% |
| Pond Verifications Pending | 1,290 |
| Registered Farm Suppliers | 12,326 |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded; dates are relative to the build day.

## Demo flow

1. Executive Cockpit: KPIs, daily harvest-lot custody transfers against custody flags, flags and confirmed custody breaks by custody signal, plant table
2. Predictive: holdout metrics, risk bands, 14-day harvest-lot transfer forecast, mass-balance variance anomalies
3. Pond Registry: mass-balance reconciliation rate, pond link coverage and pending verifications, reconciliation rate against confirmed breaks, then generate the action memo
4. Live Transfers: run `CALL APP.SIMULATE_TRANSFERS(20)` (Snowflake only) or `python aws/publish_transfers.py --count 20` (AWS build). Then run `EXECUTE ALERT APP.LIVE_TRANSFER_ALERT` and show the alert log and email.
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- Roughly one custody flag in four is confirmed as a custody break (27.6%). The rest are false positives, and that is where the traceability team loses its week.
- A missing pond registration code produces the most confirmed breaks (34 of 69 flags); unregistered pond intake raises the most flags (126), of which 32 are confirmed. Lot-coding system outage flags hit every plant in a city at once and are never confirmed.
- The risk model is evaluated on a time-based holdout: precision 0.42 and recall 0.30 at 0.5, against a 0.22 base rate. Use it to order farm visits, not as a verdict. Forecast and anomaly figures can shift slightly with the build day.
- Lot-coding system outage days are excluded from model training, because the plant did not cause them.

## Business impact

Use only the sourced references in `README.md` (Business Impact).
