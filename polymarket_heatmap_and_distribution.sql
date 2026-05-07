
USE polymarket;

WITH calibrated_trades AS (
    SELECT
        ROUND(t.taker_amount / t.maker_amount, 2) AS implied_prob,
        CAST(rt.resolution AS UNSIGNED) AS won,
        CASE
            WHEN t.maker_amount < 1000000 THEN 'Retail'
            ELSE 'Institutional'
        END AS trader_type
    FROM Trades t
    JOIN resolved_tokens rt ON t.maker_asset_id = rt.token_id
    WHERE t.maker_asset_id IS NOT NULL
    AND t.taker_amount <= t.maker_amount
    LIMIT 500000
),
bucketed AS (
    SELECT
        trader_type,
        ROUND(ROUND(implied_prob / 0.05) * 0.05, 2) AS prob_bucket,
        AVG(won) AS actual_win_rate,
        COUNT(*) AS trade_count
    FROM calibrated_trades
    GROUP BY trader_type, prob_bucket
)
SELECT
    trader_type,
    prob_bucket AS predicted_probability,
    ROUND(actual_win_rate, 4) AS actual_win_rate,
    ROUND(actual_win_rate - prob_bucket, 4) AS calibration_error,
    trade_count
FROM bucketed
WHERE prob_bucket BETWEEN 0 AND 1
ORDER BY trader_type, prob_bucket;

