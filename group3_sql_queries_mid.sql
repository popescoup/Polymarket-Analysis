use polymarket ;
#Group 3 Working session with Luca Popescu, Ethan To, Minh Tran, Sreeram Sai

 #Total number of markets
-- SELECT COUNT(*) AS total_markets 
-- FROM markets;

# Basic Queries (2 each x 4 = 8 total)
# Q1: Top 5 highest volume markets  minh 
SELECT question, volume 
FROM markets 
ORDER BY volume DESC LIMIT 5;

# Q2. Show the markets questions with their implied probability. Luca
SELECT
    m.question,
    t.outcome_label,
    ROUND(CAST(t.outcome_price AS DECIMAL(10,4)), 4) AS outcome_price
FROM markets m
JOIN tokens t ON m.id = t.market_id
WHERE t.outcome_label IN ('Yes', 'No')
ORDER BY m.volume DESC
LIMIT 15;



# sizes of trades 
# What are the top 5 longest-running markets by duration ? Sreeram
SELECT question, created_at, end_date, 
    DATEDIFF(end_date, created_at) AS duration_days
FROM markets 
WHERE end_date IS NOT NULL 
ORDER BY duration_days DESC 
LIMIT 5;


# Q4: How many markets were created each month?  Ethan 
SELECT DATE_FORMAT(created_at, '%Y-%m') AS month, COUNT(*) AS markets_created
FROM markets
GROUP BY DATE_FORMAT(created_at, '%Y-%m')
ORDER BY month;
# Insight : Polymarket growth is exponential 

# Q5: Top 5 most active makers by number of trades Minh 
SELECT maker, total_trades, ROUND(total_volume, 2) AS total_volume
FROM maker
ORDER BY total_trades DESC
LIMIT 5;


# Q6: Top 5 takers by total trade volume Ethan
SELECT taker, total_trades, ROUND(total_volume, 2) AS total_volume
FROM taker
ORDER BY total_volume DESC
LIMIT 5;

# Q7 What is the average predicted probability for outcomes across all markets? Luca
SELECT COUNT(*) AS total_tokens, outcome_label, 
ROUND(AVG(CAST(outcome_price AS DECIMAL(10,4))), 4) AS avg_price 
FROM tokens 
WHERE outcome_label = 'Yes' OR outcome_label ='No' 
GROUP BY outcome_label;

# 8. How many markets does each market maker manage? -n?? Sreeram 
SELECT market_maker_address, COUNT(*) AS markets_managed 
FROM markets 
GROUP BY market_maker_address 
ORDER BY markets_managed DESC LIMIT 10;

# Advanced
# 1. Which markets have volume higher than the overall average volume? Minh
SELECT question, ROUND(volume, 2) AS volume
FROM markets
WHERE volume > (SELECT AVG(volume) FROM markets)
ORDER BY volume DESC
LIMIT 15;

#2 What percentage of total volume does each of the top 10 markets represent? Ethan
WITH total AS (
    SELECT SUM(volume) AS total_volume FROM markets
)
SELECT 
    m.question,
    ROUND(m.volume, 2) AS volume,
    ROUND(m.volume * 100.0 / t.total_volume, 2) AS pct_of_total
FROM markets m, total t
ORDER BY m.volume DESC
LIMIT 10;

# 3. Rank markets by volume and show their percentile Sreeram
SELECT 
    question,
    ROUND(volume, 2) AS volume,
    RANK() OVER (ORDER BY volume DESC) AS volume_rank,
    ROUND(PERCENT_RANK() OVER (ORDER BY volume) * 100, 2) AS percentile
FROM markets
ORDER BY volume_rank
LIMIT 15;


# 4. Running total of markets created over time. Luca
SELECT 
    DATE_FORMAT(created_at, '%Y-%m') AS month,
    COUNT(*) AS monthly_markets,
    SUM(COUNT(*)) OVER (ORDER BY DATE_FORMAT(created_at, '%Y-%m') ROWS UNBOUNDED PRECEDING) AS cumulative_markets
FROM markets
GROUP BY DATE_FORMAT(created_at, '%Y-%m')
ORDER BY month;


# 5 Luca Bucketed distribution of biggest market movers
SELECT 
    CASE 
        WHEN maker_amount < 1000000 THEN 'Small (< 1M)'
        WHEN maker_amount BETWEEN 1000000 AND 10000000 THEN 'Medium (1M-10M)'
        WHEN maker_amount BETWEEN 10000001 AND 100000000 THEN 'Large (10M-100M)'
        ELSE 'Whale (> 100M)'
    END AS trade_size_bucket,
    COUNT(*) AS num_trades,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM (SELECT 1 FROM trades LIMIT 500000) t), 2) AS pct_of_trades
FROM (SELECT maker_amount FROM trades LIMIT 500000) AS sample
GROUP BY trade_size_bucket
ORDER BY num_trades DESC;



# 6 Which markets are generating the most trading activity relative to the capital locked in them (high ratio = capital-efficient market)
# Minh
WITH liquidity_stats AS (
    SELECT
        question,
        ROUND(volume, 2)    AS volume,
        ROUND(liquidity, 2) AS liquidity,
        ROUND(volume / NULLIF(liquidity, 0), 4) AS vol_to_liq_ratio
    FROM markets
    WHERE liquidity > 0 AND volume > 0
),
ranked AS (
    SELECT *,
        RANK() OVER (ORDER BY vol_to_liq_ratio DESC) AS efficiency_rank
    FROM liquidity_stats
)
SELECT question, volume, liquidity, vol_to_liq_ratio, efficiency_rank
FROM ranked
ORDER BY efficiency_rank
LIMIT 5;



# 7 Wallets that are participants who both provide and consume liquidity in Top 10 from maker and taker. Ethan


WITH top_makers AS (
    SELECT maker AS address,
           total_trades  AS maker_trades,
           total_volume  AS maker_volume
    FROM maker
    ORDER BY total_trades DESC
    LIMIT 10
),
top_takers AS (
    SELECT taker AS address,
           total_trades  AS taker_trades,
           total_volume  AS taker_volume
    FROM taker
    ORDER BY total_trades DESC
    LIMIT 10
)
SELECT
    tm.address,
    tm.maker_trades,
    ROUND(tm.maker_volume, 2)  AS maker_volume,
    tt.taker_trades,
    ROUND(tt.taker_volume, 2)  AS taker_volume,
    tm.maker_trades + tt.taker_trades AS combined_trades
FROM top_makers tm
JOIN top_takers tt ON tm.address = tt.address
ORDER BY combined_trades DESC
LIMIT 10;


# 8 View of particpants on Polymarket and their respective role. Sreeram
SELECT maker AS address, 'Maker' AS role
FROM maker
WHERE maker NOT IN (SELECT taker FROM taker)

UNION

SELECT taker AS address, 'Taker' AS role
FROM taker
WHERE taker NOT IN (SELECT maker FROM maker)

UNION

SELECT mk.maker AS address, 'Both Maker & Taker' AS role
FROM maker mk
JOIN taker tk ON mk.maker = tk.taker

ORDER BY role, address
LIMIT 10;