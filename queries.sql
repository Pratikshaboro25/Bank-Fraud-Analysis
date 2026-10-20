-- Bank Transaction Fraud Risk Analysis
-- Analytical queries

-- ============================================
-- 1. Data load: raw CSV -> project schema
-- ============================================
INSERT INTO accounts (account_type, status)
SELECT 'Card', 'Active'
FROM creditcard_raw
LIMIT 5000;

INSERT INTO transactions (account_id, txn_time, amount, is_fraud)
SELECT 1 + FLOOR(RAND() * 5000), Time, Amount, Class
FROM creditcard_raw;

-- ============================================
-- 2. Top 20 riskiest accounts (window function - RANK)
-- ============================================
SELECT account_id, COUNT(*) AS fraud_txns, SUM(amount) AS total_fraud_amount,
       RANK() OVER (ORDER BY COUNT(*) DESC) AS risk_rank
FROM transactions
WHERE is_fraud = 1
GROUP BY account_id
ORDER BY fraud_txns DESC
LIMIT 20;

-- ============================================
-- 3. Rolling 5-transaction average per account (window function)
-- ============================================
SELECT account_id, txn_time, amount,
       AVG(amount) OVER (PARTITION BY account_id ORDER BY txn_time
                          ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS rolling_avg_5txn,
       is_fraud
FROM transactions
ORDER BY account_id, txn_time;

-- ============================================
-- 4a. Heuristic v1: fixed threshold (5x account average)
-- ============================================
WITH account_avg AS (
    SELECT account_id, AVG(amount) AS avg_amt
    FROM transactions
    GROUP BY account_id
)
SELECT t.txn_id, t.account_id, t.amount, a.avg_amt, t.is_fraud
FROM transactions t
JOIN account_avg a ON t.account_id = a.account_id
WHERE t.amount > 5 * a.avg_amt
ORDER BY t.amount DESC;

-- Precision check for v1
WITH account_avg AS (
    SELECT account_id, AVG(amount) AS avg_amt
    FROM transactions
    GROUP BY account_id
),
flagged AS (
    SELECT t.txn_id, t.is_fraud
    FROM transactions t
    JOIN account_avg a ON t.account_id = a.account_id
    WHERE t.amount > 5 * a.avg_amt
)
SELECT
    COUNT(*) AS total_flagged,
    SUM(CASE WHEN is_fraud = 1 THEN 1 ELSE 0 END) AS true_positives,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS precision_pct
FROM flagged;

-- ============================================
-- 4b. Heuristic v2: statistical outlier (3 std dev) + transaction velocity
-- ============================================
WITH account_stats AS (
    SELECT account_id,
           AVG(amount) AS avg_amt,
           STDDEV(amount) AS std_amt
    FROM transactions
    GROUP BY account_id
),
freq_window AS (
    SELECT account_id, txn_time,
           COUNT(*) OVER (PARTITION BY account_id ORDER BY txn_time
                          RANGE BETWEEN 3600 PRECEDING AND CURRENT ROW) AS txns_last_hour
    FROM transactions
),
flagged_v2 AS (
    SELECT t.txn_id, t.account_id, t.amount, t.is_fraud,
           s.avg_amt, s.std_amt, f.txns_last_hour
    FROM transactions t
    JOIN account_stats s ON t.account_id = s.account_id
    JOIN freq_window f ON t.account_id = f.account_id AND t.txn_time = f.txn_time
    WHERE t.amount > (s.avg_amt + 3 * s.std_amt)
      AND f.txns_last_hour >= 2
)
SELECT
    COUNT(*) AS total_flagged,
    SUM(CASE WHEN is_fraud = 1 THEN 1 ELSE 0 END) AS true_positives,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS precision_pct
FROM flagged_v2;
