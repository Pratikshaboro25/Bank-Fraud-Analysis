-- Bank Transaction Fraud Risk Analysis
-- Schema definition

CREATE DATABASE IF NOT EXISTS bank_risk_analysis;
USE bank_risk_analysis;

CREATE TABLE accounts (
    account_id   INT PRIMARY KEY AUTO_INCREMENT,
    account_type VARCHAR(20) DEFAULT 'Card',
    status       VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE transactions (
    txn_id      INT PRIMARY KEY AUTO_INCREMENT,
    account_id  INT,
    txn_time    INT,
    amount      DECIMAL(12,2),
    is_fraud    TINYINT,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

-- Raw staging table used to import the original Kaggle CSV
CREATE TABLE creditcard_raw (
    Time    INT,
    V1 DECIMAL(20,15), V2 DECIMAL(20,15), V3 DECIMAL(20,15), V4 DECIMAL(20,15),
    V5 DECIMAL(20,15), V6 DECIMAL(20,15), V7 DECIMAL(20,15), V8 DECIMAL(20,15),
    V9 DECIMAL(20,15), V10 DECIMAL(20,15), V11 DECIMAL(20,15), V12 DECIMAL(20,15),
    V13 DECIMAL(20,15), V14 DECIMAL(20,15), V15 DECIMAL(20,15), V16 DECIMAL(20,15),
    V17 DECIMAL(20,15), V18 DECIMAL(20,15), V19 DECIMAL(20,15), V20 DECIMAL(20,15),
    V21 DECIMAL(20,15), V22 DECIMAL(20,15), V23 DECIMAL(20,15), V24 DECIMAL(20,15),
    V25 DECIMAL(20,15), V26 DECIMAL(20,15), V27 DECIMAL(20,15), V28 DECIMAL(20,15),
    Amount  DECIMAL(12,2),
    Class   TINYINT
);
