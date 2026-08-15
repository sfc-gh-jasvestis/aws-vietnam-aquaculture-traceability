-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for Farm-to-Export Traceability
-- ============================================================================
USE DATABASE AQUACULTURE_TRACEABILITY;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.AQUACULTURE_TRACEABILITY_ANALYTICS
  COMMENT = 'Aquaculture & Seafood supply chain traceability analytics'
AS
  TABLES (
    CURATED.PERFORMANCE_DASHBOARD AS performance_dashboard,CURATED.TREND_ANALYTICS AS trend_analytics,CURATED.FORECAST_INPUT AS forecast_input,CURATED.OPERATIONAL_RISK AS operational_risk
  );
