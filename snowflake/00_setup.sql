-- Generated from generator/demo_specs/aws-vietnam-aquaculture-traceability.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-vietnam-aquaculture-traceability
-- This is the schema that is actually deployed for VIETNAM_AQUACULTURE_TRACEABILITY.

-- VIETNAM_AQUACULTURE_TRACEABILITY  (Farm-to-Export Traceability)
-- generated from generator/demo_specs/aws-vietnam-aquaculture-traceability.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS VIETNAM_AQUACULTURE_TRACEABILITY;
CREATE SCHEMA IF NOT EXISTS VIETNAM_AQUACULTURE_TRACEABILITY.RAW;
CREATE SCHEMA IF NOT EXISTS VIETNAM_AQUACULTURE_TRACEABILITY.CURATED;
CREATE SCHEMA IF NOT EXISTS VIETNAM_AQUACULTURE_TRACEABILITY.APP;
USE DATABASE VIETNAM_AQUACULTURE_TRACEABILITY;

-- 5 real regions; entity names carry their region so the two always agree
