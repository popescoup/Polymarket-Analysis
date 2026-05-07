
USE polymarket;

-- Create a view for resolved tokens only
CREATE OR REPLACE VIEW resolved_tokens AS
SELECT 
    token_id,
    outcome_label,
    CAST(TRIM(BOTH '\r' FROM outcome_price) AS DECIMAL(10,4)) AS resolution
FROM Tokens
WHERE TRIM(BOTH '\r' FROM outcome_price) IN ('0', '1');


-- Query 1 (Overall calibration analysis)
WITH calibrated_trades AS (
    SELECT
        ROUND(t.taker_amount / t.maker_amount, 2) AS implied_prob,
        CAST(rt.resolution AS UNSIGNED) AS won
    FROM Trades t
    JOIN resolved_tokens rt ON t.maker_asset_id = rt.token_id
    WHERE t.maker_asset_id IS NOT NULL
    AND t.taker_amount <= t.maker_amount
    LIMIT 100000
),
bucketed AS (
    SELECT
        ROUND(implied_prob / 0.05) * 0.05 AS prob_bucket,
        AVG(won) AS actual_win_rate,
        COUNT(*) AS trade_count
    FROM calibrated_trades
    GROUP BY prob_bucket
)
SELECT
    ROUND(prob_bucket, 2) AS predicted_probability,
    ROUND(actual_win_rate, 4) AS actual_win_rate,
    trade_count
FROM bucketed
WHERE prob_bucket BETWEEN 0 AND 1
ORDER BY prob_bucket;


-- Query 2 (maker_amount < 1,000,000)
WITH calibrated_trades AS (
    SELECT
        ROUND(t.taker_amount / t.maker_amount, 2) AS implied_prob,
        CAST(rt.resolution AS UNSIGNED) AS won
    FROM Trades t
    JOIN resolved_tokens rt ON t.maker_asset_id = rt.token_id
    WHERE t.maker_asset_id IS NOT NULL
    AND t.taker_amount <= t.maker_amount
    AND t.maker_amount < 1000000
    LIMIT 100000
),
bucketed AS (
    SELECT
        ROUND(implied_prob / 0.05) * 0.05 AS prob_bucket,
        AVG(won) AS actual_win_rate,
        COUNT(*) AS trade_count
    FROM calibrated_trades
    GROUP BY prob_bucket
)
SELECT
    ROUND(prob_bucket, 2) AS predicted_probability,
    ROUND(actual_win_rate, 4) AS actual_win_rate,
    trade_count
FROM bucketed
WHERE prob_bucket BETWEEN 0 AND 1
ORDER BY prob_bucket;


-- Query 3 (maker_amount >= 1,000,000)
WITH calibrated_trades AS (
    SELECT
        ROUND(t.taker_amount / t.maker_amount, 2) AS implied_prob,
        CAST(rt.resolution AS UNSIGNED) AS won
    FROM Trades t
    JOIN resolved_tokens rt ON t.maker_asset_id = rt.token_id
    WHERE t.maker_asset_id IS NOT NULL
    AND t.taker_amount <= t.maker_amount
    AND t.maker_amount >= 1000000
    LIMIT 100000
),
bucketed AS (
    SELECT
        ROUND(implied_prob / 0.05) * 0.05 AS prob_bucket,
        AVG(won) AS actual_win_rate,
        COUNT(*) AS trade_count
    FROM calibrated_trades
    GROUP BY prob_bucket
)
SELECT
    ROUND(prob_bucket, 2) AS predicted_probability,
    ROUND(actual_win_rate, 4) AS actual_win_rate,
    trade_count
FROM bucketed
WHERE prob_bucket BETWEEN 0 AND 1
ORDER BY prob_bucket;


