-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for Farm-to-Export Traceability
-- ============================================================================
USE DATABASE AQUACULTURE_TRACEABILITY;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.AQUACULTURE_TRACEABILITY_AGENT
  COMMENT = 'Farm-to-Export Traceability AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'AQUACULTURE_TRACEABILITY.APP.AQUACULTURE_TRACEABILITY_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'AQUACULTURE_TRACEABILITY.SEARCH.AQUACULTURE_TRACEABILITY_SEARCH', TOOL_DESCRIPTION => 'Search documents for Aquaculture & Seafood information')
  )
  SYSTEM_PROMPT = 'You are the Supply Chain Traceability Agent for Vietnamese aquaculture & seafood operations in Mekong Delta.';
