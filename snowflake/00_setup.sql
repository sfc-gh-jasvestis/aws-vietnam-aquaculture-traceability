-- ============================================================================
-- Farm-to-Export Traceability
-- Farm-to-Export Traceability for Vietnam - ML.FORECAST and Dynamic Tables power real-time supply chain traceability intelligence for aquaculture & seafood in Mekong Delta.
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS AQUACULTURE_TRACEABILITY;
CREATE WAREHOUSE IF NOT EXISTS AQUACULTURE_WH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE;
USE DATABASE AQUACULTURE_TRACEABILITY;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS ML;
CREATE SCHEMA IF NOT EXISTS AI;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

USE WAREHOUSE AQUACULTURE_WH;
