-- ============================================================
-- PREDICTION MARKET ANALYTICS — Final Project Queries
-- DATA 201 | SJSU | Spring 2026
-- 4 Basic + 16 Advanced = 20 New Queries
-- Database: polymarket
-- ============================================================

USE polymarket;

-- ************************************************************
-- BASIC QUERIES (4)
-- ************************************************************

-- ============================================================
-- B1: Top 10 markets with highest liquidity that are closed
-- Technique: JOIN, WHERE, ORDER BY, LIMIT
-- ============================================================
SELECT 
    m.question,
    ROUND(m.liquidity, 2) AS liquidity,
    ROUND(m.volume, 2) AS volume,
    m.end_date
FROM markets m
JOIN status s ON m.id = s.id
WHERE s.closed = 1
ORDER BY m.liquidity DESC
LIMIT 10;


-- ============================================================
-- B2: Markets created per year with average volume
-- Technique: YEAR, GROUP BY, COUNT, AVG
-- ============================================================
SELECT 
    YEAR(created_at) AS year,
    COUNT(*) AS markets_created,
    ROUND(AVG(volume), 2) AS avg_volume,
    ROUND(SUM(volume), 2) AS total_volume
FROM markets
GROUP BY YEAR(created_at)
ORDER BY year;


-- ============================================================
-- B3: Average, min, max market duration by open vs closed
-- Technique: JOIN, DATEDIFF, GROUP BY, AVG, MIN, MAX, CASE
-- ============================================================
SELECT 
    CASE 
        WHEN s.closed = 1 THEN 'Closed'
        ELSE 'Open'
    END AS market_status,
    COUNT(*) AS num_markets,
    ROUND(AVG(DATEDIFF(m.end_date, m.created_at)), 1) AS avg_duration_days,
    MIN(DATEDIFF(m.end_date, m.created_at)) AS min_duration_days,
    MAX(DATEDIFF(m.end_date, m.created_at)) AS max_duration_days
FROM markets m
JOIN status s ON m.id = s.id
WHERE m.end_date IS NOT NULL
GROUP BY s.closed;


-- ============================================================
-- B4: 10 markets with the soonest expiring end_date
-- Technique: WHERE, ORDER BY, LIMIT
-- ============================================================
SELECT 
    question,
    end_date,
    ROUND(volume, 2) AS volume,
    ROUND(liquidity, 2) AS liquidity
FROM markets
WHERE end_date > NOW()
ORDER BY end_date ASC
LIMIT 10;


-- ************************************************************
-- ADVANCED QUERIES (16)
-- ************************************************************

-- ============================================================
-- A1: Makers with trades above avg of makers who have 100+ trades
-- Technique: HAVING + Subquery
-- ============================================================
SELECT 
    maker,
    total_trades,
    ROUND(total_volume, 2) AS total_volume
FROM maker
WHERE total_trades > (
    SELECT AVG(total_trades)
    FROM maker
    WHERE total_trades > 100
)
ORDER BY total_trades DESC
LIMIT 15;


-- ============================================================
-- A2: Difference between Yes and No prices for each market
-- Technique: JOIN + CAST + Self-join on tokens
-- ============================================================
SELECT 
    m.question,
    ROUND(m.volume, 2) AS volume,
    CAST(yes_t.outcome_price AS DECIMAL(10,4)) AS yes_price,
    CAST(no_t.outcome_price AS DECIMAL(10,4)) AS no_price,
    ROUND(
        ABS(CAST(yes_t.outcome_price AS DECIMAL(10,4)) - CAST(no_t.outcome_price AS DECIMAL(10,4))), 4
    ) AS price_spread
FROM markets m
JOIN tokens yes_t ON m.id = yes_t.market_id AND yes_t.outcome_label = 'Yes'
JOIN tokens no_t ON m.id = no_t.market_id AND no_t.outcome_label = 'No'
ORDER BY price_spread DESC
LIMIT 15;


-- ============================================================
-- A3: Markets where Yes > 0.80 but liquidity below average
-- Technique: Correlated Subquery
-- ============================================================
SELECT 
    m.question,
    CAST(t.outcome_price AS DECIMAL(10,4)) AS yes_price,
    ROUND(m.liquidity, 2) AS liquidity,
    ROUND(m.volume, 2) AS volume
FROM markets m
JOIN tokens t ON m.id = t.market_id
WHERE t.outcome_label = 'Yes'
    AND CAST(t.outcome_price AS DECIMAL(10,4)) > 0.80
    AND m.liquidity < (SELECT AVG(liquidity) FROM markets WHERE liquidity > 0)
ORDER BY yes_price DESC
LIMIT 15;


-- ============================================================
-- A4: View of top 100 traded markets with status and prices
-- Technique: VIEW + Multi-table JOIN (3 tables)
-- ============================================================
CREATE OR REPLACE VIEW vw_top_markets AS
SELECT 
    m.id,
    m.question,
    ROUND(m.volume, 2) AS volume,
    ROUND(m.liquidity, 2) AS liquidity,
    s.active,
    s.closed,
    t.outcome_label,
    CAST(t.outcome_price AS DECIMAL(10,4)) AS outcome_price
FROM markets m
JOIN status s ON m.id = s.id
JOIN tokens t ON m.id = t.market_id
ORDER BY m.volume DESC
LIMIT 100;

-- Query the view
SELECT * FROM vw_top_markets;


-- ============================================================
-- A5: Classify makers into 4 tiers by total volume
-- Technique: NTILE window function
-- ============================================================
SELECT 
    maker,
    total_trades,
    ROUND(total_volume, 2) AS total_volume,
    NTILE(4) OVER (ORDER BY total_volume DESC) AS volume_tier,
    CASE NTILE(4) OVER (ORDER BY total_volume DESC)
        WHEN 1 THEN 'Whale'
        WHEN 2 THEN 'Large'
        WHEN 3 THEN 'Medium'
        WHEN 4 THEN 'Small'
    END AS tier_label
FROM maker
WHERE total_trades > 0
ORDER BY total_volume DESC
LIMIT 20;


-- ============================================================
-- A6: Each maker's rank and previous maker's trade count
-- Technique: LAG window function
-- ============================================================
SELECT 
    maker,
    total_trades,
    ROUND(total_volume, 2) AS total_volume,
    RANK() OVER (ORDER BY total_trades DESC) AS trade_rank,
    LAG(total_trades) OVER (ORDER BY total_trades DESC) AS prev_maker_trades,
    total_trades - LAG(total_trades) OVER (ORDER BY total_trades DESC) AS gap_from_prev
FROM maker
ORDER BY total_trades DESC
LIMIT 20;



-- ============================================================
-- A7: Month-over-month growth rate of new markets
-- Technique: CTE + LAG
-- ============================================================
WITH monthly AS (
    SELECT 
        DATE_FORMAT(created_at, '%Y-%m') AS month,
        COUNT(*) AS markets_created
    FROM markets
    GROUP BY DATE_FORMAT(created_at, '%Y-%m')
)
SELECT 
    month,
    markets_created,
    LAG(markets_created) OVER (ORDER BY month) AS prev_month,
    CASE 
        WHEN LAG(markets_created) OVER (ORDER BY month) > 0 
        THEN ROUND(
            (markets_created - LAG(markets_created) OVER (ORDER BY month)) * 100.0 
            / LAG(markets_created) OVER (ORDER BY month), 2
        )
        ELSE NULL
    END AS growth_rate_pct
FROM monthly
ORDER BY month;


-- ============================================================
-- A8: Markets with more than 5 tokens and their volumes
-- Technique: GROUP BY + HAVING + JOIN
-- ============================================================
SELECT 
    m.question,
    ROUND(m.volume, 2) AS volume,
    COUNT(t.token_id) AS token_count
FROM markets m
JOIN tokens t ON m.id = t.market_id
GROUP BY m.id, m.question, m.volume
HAVING COUNT(t.token_id) > 5
ORDER BY token_count DESC
LIMIT 15;


-- ============================================================
-- A9: What percentage of markets have Yes price above 0.50
-- Technique: Subquery in SELECT
-- ============================================================
SELECT 
    COUNT(*) AS total_markets,
    SUM(CASE WHEN CAST(t.outcome_price AS DECIMAL(10,4)) > 0.50 THEN 1 ELSE 0 END) AS yes_above_50,
    ROUND(
        SUM(CASE WHEN CAST(t.outcome_price AS DECIMAL(10,4)) > 0.50 THEN 1 ELSE 0 END) * 100.0 
        / COUNT(*), 2
    ) AS pct_above_50,
    (SELECT ROUND(AVG(CAST(outcome_price AS DECIMAL(10,4))), 4) 
     FROM tokens WHERE outcome_label = 'Yes') AS overall_avg_yes_price
FROM tokens t
WHERE t.outcome_label = 'Yes';


-- ============================================================
-- A10: Add index on trades(maker) and show index info
-- Technique: Indexing
-- ============================================================
-- Check existing indexes
SHOW INDEX FROM trades;

-- Create index for performance
CREATE INDEX idx_trades_maker_asset ON trades(maker_asset_id);

-- Verify the new index
SHOW INDEX FROM trades WHERE Key_name = 'idx_trades_maker_asset';


-- ============================================================
-- A11: Markets where Yes + No prices don't sum to ~1.0
-- Technique: JOIN + HAVING
-- ============================================================
SELECT 
    m.question,
    CAST(yes_t.outcome_price AS DECIMAL(10,4)) AS yes_price,
    CAST(no_t.outcome_price AS DECIMAL(10,4)) AS no_price,
    ROUND(
        CAST(yes_t.outcome_price AS DECIMAL(10,4)) + CAST(no_t.outcome_price AS DECIMAL(10,4)), 4
    ) AS price_sum,
    ROUND(m.volume, 2) AS volume
FROM markets m
JOIN tokens yes_t ON m.id = yes_t.market_id AND yes_t.outcome_label = 'Yes'
JOIN tokens no_t ON m.id = no_t.market_id AND no_t.outcome_label = 'No'
HAVING price_sum < 0.95 OR price_sum > 1.05
ORDER BY ABS(price_sum - 1.0) DESC
LIMIT 15;



-- ============================================================
-- A12: For each market, find the maker with highest trade amount
-- Technique: CTE + ROW_NUMBER
-- ============================================================
WITH market_top_maker AS (
    SELECT 
        t.maker_asset_id,
        t.maker,
        SUM(t.maker_amount) AS total_amount,
        COUNT(*) AS trade_count,
        ROW_NUMBER() OVER (
            PARTITION BY t.maker_asset_id 
            ORDER BY SUM(t.maker_amount) DESC
        ) AS rn
    FROM (SELECT * FROM trades LIMIT 500000) t
    GROUP BY t.maker_asset_id, t.maker
)
SELECT 
    mtm.maker_asset_id,
    mtm.maker,
    mtm.total_amount,
    mtm.trade_count
FROM market_top_maker mtm
WHERE mtm.rn = 1
ORDER BY mtm.total_amount DESC
LIMIT 15;


-- ============================================================
-- A13: Summary view: market, status, tokens, trade count
-- Technique: VIEW + 3-table JOIN
-- ============================================================
CREATE OR REPLACE VIEW vw_market_summary AS
SELECT 
    m.question,
    ROUND(m.volume, 2) AS volume,
    s.active,
    s.closed,
    CAST(t.outcome_price AS DECIMAL(10,4)) AS yes_price,
    m.created_at,
    m.end_date
FROM markets m
JOIN status s ON m.id = s.id
JOIN tokens t ON m.id = t.market_id AND t.outcome_label = 'Yes'
ORDER BY m.volume DESC;

-- Query the view
SELECT * FROM vw_market_summary LIMIT 15;


-- ============================================================
-- A14: 3-month moving average of market creation
-- Technique: CTE + AVG window function with ROWS BETWEEN
-- ============================================================
WITH monthly AS (
    SELECT 
        DATE_FORMAT(created_at, '%Y-%m') AS month,
        COUNT(*) AS markets_created
    FROM markets
    GROUP BY DATE_FORMAT(created_at, '%Y-%m')
)
SELECT 
    month,
    markets_created,
    ROUND(
        AVG(markets_created) OVER (
            ORDER BY month 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 1
    ) AS moving_avg_3month
FROM monthly
ORDER BY month;
