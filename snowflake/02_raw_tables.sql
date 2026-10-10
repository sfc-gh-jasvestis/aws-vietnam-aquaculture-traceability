-- Synthetic processing-plant observations for a fictional farmed seafood
-- (pangasius and shrimp) supply chain in the Vietnam Mekong Delta.
-- 40 plants = 8 cities x 5 sourcing models. Nothing is seeded as a prediction.
-- Randomness is HASH-seeded, so every rebuild is reproducible: per-plant
-- custody-break propensity, drift between periodic mass-balance
-- reconciliations, missed reconciliations, model-weighted custody signals,
-- false-positive custody flags, and two area-wide lot-coding system outages.
-- Custody checks are demo signals, not audit or certification verdicts.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.PLANTS AS
WITH plants AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS PLANT_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 40))
), draws AS (
  SELECT PLANT_INDEX,
         MOD(ABS(HASH(PLANT_INDEX, 'vnaqt-program')), 1000000) / 1e6 AS U_PROGRAM,
         MOD(ABS(HASH(PLANT_INDEX, 'vnaqt-rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(PLANT_INDEX, 'vnaqt-reconcile')), 1000000) / 1e6 AS U_RECONCILE,
         MOD(ABS(HASH(PLANT_INDEX, 'vnaqt-discipline')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(PLANT_INDEX, 'vnaqt-tier')), 1000000) / 1e6 AS U_TIER,
         MOD(ABS(HASH(PLANT_INDEX, 'vnaqt-size')), 1000000) / 1e6 AS U_SIZE
  FROM plants
), plants_named AS (
  SELECT *,
         -- Every city x sourcing model combination appears exactly once.
         CASE MOD(PLANT_INDEX, 8) WHEN 0 THEN 'Ca Mau' WHEN 1 THEN 'Bac Lieu'
              WHEN 2 THEN 'Soc Trang' WHEN 3 THEN 'Can Tho' WHEN 4 THEN 'Long Xuyen'
              WHEN 5 THEN 'Cao Lanh' WHEN 6 THEN 'Ben Tre'
              ELSE 'Rach Gia' END AS REGION,
         CASE FLOOR(PLANT_INDEX / 8) WHEN 0 THEN 'Company farm plant'
              WHEN 1 THEN 'Cooperative group plant' WHEN 2 THEN 'Household pond plant'
              WHEN 3 THEN 'Trader-supplied plant' ELSE 'Contract grower plant' END AS CATEGORY
  FROM draws
)
SELECT 'PLANT-' || LPAD(PLANT_INDEX::VARCHAR, 4, '0') AS ID,
       REGION || ' ' || CATEGORY AS NAME,
       REGION, CATEGORY, PLANT_INDEX,
       1 + FLOOR(U_TIER * 3) AS RISK_TIER,
       ROUND(0.5 + U_PROGRAM * 6.5, 1) AS PROGRAM_YEARS,
       ROUND(0.65 + U_SIZE * 0.7, 3) AS SIZE_FACTOR,
       -- Base daily probability of a confirmed custody break, higher where
       -- sourcing is indirect; ~15% of plants are weak links (x3).
       (0.004 + U_RATE * 0.019)
         * CASE CATEGORY WHEN 'Company farm plant' THEN 0.45 WHEN 'Cooperative group plant' THEN 0.85
                         WHEN 'Household pond plant' THEN 1.35 WHEN 'Trader-supplied plant' THEN 1.55
                         ELSE 1.1 END
         * IFF(U_RATE > 0.85, 3, 1) AS BASE_BREAK_RATE,
       7 * (1 + FLOOR(U_RECONCILE * 3)) AS RECONCILIATION_INTERVAL_DAYS,
       0.55 + U_DISCIPLINE * 0.45 AS RECONCILIATION_RETURN_PROB,
       -- Share of harvest tonnes that typically cannot be traced to a registered pond.
       CASE CATEGORY WHEN 'Company farm plant' THEN 3 WHEN 'Cooperative group plant' THEN 9
                     WHEN 'Household pond plant' THEN 28 WHEN 'Trader-supplied plant' THEN 37
                     ELSE 15 END AS BASE_UNTRACED_PCT,
       'Active' AS STATUS
FROM plants_named;

CREATE TABLE RAW.PLANT_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), outage_events AS (
  -- Two area-wide lot-coding system outages; every plant in the city gets a flag.
  SELECT * FROM VALUES (27, 'Bac Lieu'), (64, 'Cao Lanh') AS o(DAY_INDEX, REGION)
), base AS (
  SELECT p.ID AS ENTITY_ID, p.PLANT_INDEX, p.CATEGORY, p.REGION, p.PROGRAM_YEARS,
         p.SIZE_FACTOR, p.BASE_UNTRACED_PCT,
         p.BASE_BREAK_RATE, p.RECONCILIATION_INTERVAL_DAYS, p.RECONCILIATION_RETURN_PROB,
         d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         MOD(d.DAY_INDEX + p.PLANT_INDEX * 3, p.RECONCILIATION_INTERVAL_DAYS) AS DAYS_SINCE_RECONCILIATION,
         MOD(ABS(HASH(p.ID, d.DAY_INDEX, 'vnaqt-break')), 1000000) / 1e6 AS U_BREAK,
         MOD(ABS(HASH(p.ID, d.DAY_INDEX, 'vnaqt-detect')), 1000000) / 1e6 AS U_DETECT,
         MOD(ABS(HASH(p.ID, d.DAY_INDEX, 'vnaqt-fp')), 1000000) / 1e6 AS U_FP,
         MOD(ABS(HASH(p.ID, d.DAY_INDEX, 'vnaqt-signal')), 1000000) / 1e6 AS U_SIG,
         MOD(ABS(HASH(p.ID, d.DAY_INDEX, 'vnaqt-done')), 1000000) / 1e6 AS U_DONE,
         MOD(ABS(HASH(p.ID, d.DAY_INDEX, 'vnaqt-lots')), 1000000) / 1e6 AS U_LOTS,
         MOD(ABS(HASH(p.ID, d.DAY_INDEX, 'vnaqt-noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(p.ID, d.DAY_INDEX, 'vnaqt-hold')), 1000000) / 1e6 AS U_HOLD,
         o.REGION IS NOT NULL AS OUTAGE_EVENT
  FROM RAW.PLANTS p CROSS JOIN days d
  LEFT JOIN outage_events o ON o.DAY_INDEX = d.DAY_INDEX AND o.REGION = p.REGION
), reconciliations AS (
  SELECT *,
         IFF(DAYS_SINCE_RECONCILIATION = 0, 1, 0) AS RECONCILIATION_DUE,
         IFF(DAYS_SINCE_RECONCILIATION = 0 AND U_DONE < RECONCILIATION_RETURN_PROB, 1, 0) AS RECONCILIATION_RECEIVED,
         -- Custody drift rises between mass-balance reconciliations; weak discipline carries it over.
         DAYS_SINCE_RECONCILIATION / RECONCILIATION_INTERVAL_DAYS + (1 - RECONCILIATION_RETURN_PROB) AS DRIFT
  FROM base
), activity AS (
  SELECT *,
         CASE WHEN U_BREAK < LEAST(0.5, BASE_BREAK_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + PROGRAM_YEARS))) / 4 THEN 2
              WHEN U_BREAK < LEAST(0.5, BASE_BREAK_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + PROGRAM_YEARS))) THEN 1
              ELSE 0 END AS BREAK_COUNT
  FROM reconciliations
), checks AS (
  SELECT *,
         -- Custody checks catch about 80% of breaks; the rest stays undetected.
         IFF(OUTAGE_EVENT, 0, IFF(U_DETECT < 0.80, BREAK_COUNT, 0)) AS CONFIRMED_COUNT,
         -- False-positive flags: higher where sourcing records are weaker.
         IFF(OUTAGE_EVENT, 1, IFF(U_FP < CASE CATEGORY WHEN 'Household pond plant' THEN 0.15
                                                       WHEN 'Trader-supplied plant' THEN 0.16
                                                       WHEN 'Contract grower plant' THEN 0.12
                                                       WHEN 'Cooperative group plant' THEN 0.10 ELSE 0.06 END, 1, 0)) AS FALSE_POSITIVE_COUNT
  FROM activity
), measured AS (
  SELECT *,
         CONFIRMED_COUNT + FALSE_POSITIVE_COUNT AS FLAG_COUNT,
         ROUND(CASE CATEGORY WHEN 'Company farm plant' THEN 15 WHEN 'Cooperative group plant' THEN 13
                             WHEN 'Household pond plant' THEN 11 WHEN 'Trader-supplied plant' THEN 12 ELSE 9 END
               * SIZE_FACTOR * (0.7 + 0.6 * U_LOTS)) AS LOT_COUNT,
         -- A harvest lot from one pond is roughly 4-12 tonnes of live fish or shrimp.
         CASE CATEGORY WHEN 'Company farm plant' THEN 11 WHEN 'Cooperative group plant' THEN 8
                       WHEN 'Household pond plant' THEN 4.5 WHEN 'Trader-supplied plant' THEN 6 ELSE 9 END
           * (0.9 + 0.2 * U_NOISE) AS AVG_LOT_TONNES,
         LEAST(95, BASE_UNTRACED_PCT + 6 * DRIFT + 8 * BREAK_COUNT + 2 * U_NOISE) AS UNTRACED_SHARE
  FROM checks
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE,
       LOT_COUNT,
       ROUND(LOT_COUNT * AVG_LOT_TONNES * (1 - UNTRACED_SHARE / 100), 2) AS TRACED_TONNES,
       ROUND(LOT_COUNT * AVG_LOT_TONNES, 2) AS HARVEST_TONNES,
       FLAG_COUNT, CONFIRMED_COUNT,
       IFF(CONFIRMED_COUNT > 0 AND U_HOLD < 0.5, 1, 0) AS LOTS_HELD,
       CASE WHEN FLAG_COUNT = 0 THEN 'None'
            WHEN OUTAGE_EVENT THEN 'Lot-coding system outage'
            WHEN CATEGORY = 'Company farm plant' THEN IFF(U_SIG < 0.6, 'Harvest declaration mismatch', 'Truck seal mismatch')
            WHEN CATEGORY = 'Cooperative group plant' THEN IFF(U_SIG < 0.5, 'Truck seal mismatch', 'Pond registration code missing')
            WHEN CATEGORY = 'Household pond plant' THEN IFF(U_SIG < 0.45, 'Unregistered pond intake', IFF(U_SIG < 0.75, 'Farm log gap', 'Mass balance variance'))
            WHEN CATEGORY = 'Trader-supplied plant' THEN IFF(U_SIG < 0.55, 'Trader manifest incomplete', 'Unregistered pond intake')
            ELSE IFF(U_SIG < 0.5, 'Cold store transfer unrecorded', 'Mass balance variance') END AS RISK_SIGNAL,
       RECONCILIATION_DUE, RECONCILIATION_RECEIVED,
       ROUND(0.6 + 2.0 * DRIFT + 3.0 * BREAK_COUNT + U_NOISE * 0.8, 2) AS MB_VARIANCE_PCT,
       ROUND(UNTRACED_SHARE, 1) AS UNTRACED_PCT,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM measured;

-- Farm supplier registry per plant (snapshot): registered farms, farms with a
-- verified pond registration code on file, and verifications still pending.
CREATE TABLE RAW.SUPPLIER_REGISTRY AS
WITH sized AS (
  SELECT ID, CATEGORY,
         ROUND(CASE CATEGORY WHEN 'Company farm plant' THEN 30 WHEN 'Cooperative group plant' THEN 260
                             WHEN 'Household pond plant' THEN 750 WHEN 'Trader-supplied plant' THEN 420 ELSE 140 END
               * (0.6 + MOD(ABS(HASH(ID, 'vnaqt-farms')), 1000000) / 1e6 * 0.8)) AS SUPPLIERS,
         CASE CATEGORY WHEN 'Company farm plant' THEN 1.0 WHEN 'Cooperative group plant' THEN 0.84
                       WHEN 'Household pond plant' THEN 0.52 WHEN 'Trader-supplied plant' THEN 0.40 ELSE 0.62 END
           + MOD(ABS(HASH(ID, 'vnaqt-linked')), 1000000) / 1e6 * 0.25 AS LINK_SHARE
  FROM RAW.PLANTS
)
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Company farm plant' THEN 'Company farm pond register'
                     WHEN 'Cooperative group plant' THEN 'Cooperative member pond list'
                     WHEN 'Household pond plant' THEN 'Household pond supplier register'
                     WHEN 'Trader-supplied plant' THEN 'Trader source pond list'
                     ELSE 'Contract grower pond list' END AS EVIDENCE_TYPE,
       SUPPLIERS AS REQUIRED_QTY,
       LEAST(SUPPLIERS, ROUND(SUPPLIERS * LINK_SHARE)) AS ON_FILE_QTY,
       ROUND((SUPPLIERS - LEAST(SUPPLIERS, ROUND(SUPPLIERS * LINK_SHARE))) * MOD(ABS(HASH(ID, 'vnaqt-pending')), 1000000) / 1e6 * 0.6) AS PENDING_QTY,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM sized;
