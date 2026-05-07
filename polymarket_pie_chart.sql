

SELECT
    trader_type,
    COUNT(DISTINCT maker) AS unique_traders,
    SUM(maker_amount) AS total_volume
FROM (
    SELECT
        maker,
        maker_amount,
        CASE
            WHEN maker_amount < 1000000 THEN 'Retail'
            ELSE 'Institutional'
        END AS trader_type
    FROM Trades
    WHERE maker_asset_id IS NOT NULL
    AND maker_amount IS NOT NULL
    LIMIT 500000
) AS classified
GROUP BY trader_type;