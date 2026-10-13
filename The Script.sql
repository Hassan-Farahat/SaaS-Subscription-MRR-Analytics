--Database Schema Creation

-- Create the SaaS analytics database
CREATE DATABASE SaasSubscriptionAnalytics;
GO

USE SaasSubscriptionAnalytics;
GO

-- Plan Dimension
CREATE TABLE Dim_Plans (
    plan_id INT PRIMARY KEY,
    plan_name VARCHAR(50),
    monthly_rate DECIMAL(10,2),
    tier_level INT
);

-- Customer Dimension
CREATE TABLE Dim_Customers (
    customer_id INT PRIMARY KEY,
    company_name VARCHAR(100),
    industry VARCHAR(50),
    signup_date DATE
);

-- Subscription Events Fact Table
CREATE TABLE Fact_Subscriptions (
    subscription_id INT PRIMARY KEY,
    customer_id INT FOREIGN KEY REFERENCES Dim_Customers(customer_id),
    plan_id INT FOREIGN KEY REFERENCES Dim_Plans(plan_id),
    start_date DATE,
    end_date DATE,
    status VARCHAR(20) -- 'Active', 'Cancelled', 'Upgraded'
);

-- Billing & Revenue Fact Table
CREATE TABLE Fact_Billing (
    billing_id INT PRIMARY KEY,
    customer_id INT FOREIGN KEY REFERENCES Dim_Customers(customer_id),
    billing_date DATE,
    amount_paid DECIMAL(10,2)
);



--Data Ingestion
-- Insert Subscription Plans
INSERT INTO Dim_Plans VALUES 
(1, 'Starter', 49.00, 1),
(2, 'Professional', 199.00, 2),
(3, 'Enterprise', 499.00, 3);

-- Insert SaaS Customers
INSERT INTO Dim_Customers VALUES 
(101, 'Apex Tech Solutions', 'Software', '2025-01-15'),
(102, 'Global Logistics Corp', 'Logistics', '2025-03-01'),
(103, 'Fintech Innovations', 'Finance', '2025-06-10'),
(104, 'HealthPlus Systems', 'Healthcare', '2026-01-20'),
(105, 'EduLearn Platform', 'Education', '2026-02-15');

-- Insert Subscription Events
INSERT INTO Fact_Subscriptions VALUES 
(1, 101, 2, '2025-01-15', NULL, 'Active'),          -- Professional Plan ($199/mo)
(2, 102, 3, '2025-03-01', '2026-08-31', 'Cancelled'), -- Enterprise Plan ($499/mo) - Churned
(3, 103, 1, '2025-06-10', '2026-01-01', 'Upgraded'),  -- Upgraded from Starter...
(4, 103, 3, '2026-01-02', NULL, 'Active'),          -- ...to Enterprise ($499/mo) - Expansion
(5, 104, 2, '2026-01-20', NULL, 'Active'),          -- Professional Plan ($199/mo)
(6, 105, 1, '2026-02-15', '2026-07-15', 'Cancelled'); -- Starter Plan ($499/mo) - Churned

-- Insert Historic Billing Transactions
INSERT INTO Fact_Billing VALUES 
(1001, 101, '2026-07-01', 199.00),
(1002, 101, '2026-08-01', 199.00),
(1003, 101, '2026-09-01', 199.00),
(1004, 102, '2026-07-01', 499.00),
(1005, 102, '2026-08-01', 499.00), -- Last payment before cancellation
(1006, 103, '2026-07-01', 499.00),
(1007, 103, '2026-08-01', 499.00),
(1008, 103, '2026-09-01', 499.00),
(1009, 104, '2026-07-01', 199.00),
(1010, 104, '2026-08-01', 199.00),
(1011, 104, '2026-09-01', 199.00);


-- ============================================================================
-- QUERY 1: Current Monthly Recurring Revenue (MRR) by Subscription Plan
-- Business Goal: Measure total recurring revenue generated active subscriptions.
-- ============================================================================

SELECT 
    p.plan_name,
    p.monthly_rate,
    COUNT(s.subscription_id) AS active_subscribers,
    -- Calculate total MRR per plan (Active Subscribers * Monthly Rate)
    (COUNT(s.subscription_id) * p.monthly_rate) AS total_plan_mrr
FROM Fact_Subscriptions s
JOIN Dim_Plans p ON s.plan_id = p.plan_id
WHERE s.status = 'Active'
GROUP BY p.plan_name, p.monthly_rate
ORDER BY total_plan_mrr DESC;


-- ============================================================================
-- QUERY 2: Total Revenue Contribution by Customer & Industry
-- Business Goal: Identify highest-paying enterprise accounts and core revenue industries.
-- ============================================================================

SELECT 
    c.company_name,
    c.industry,
    COUNT(b.billing_id) AS total_billing_cycles,
    SUM(b.amount_paid) AS total_revenue_contributed
FROM Dim_Customers c
JOIN Fact_Billing b ON c.customer_id = b.customer_id
GROUP BY c.company_name, c.industry
ORDER BY total_revenue_contributed DESC;


-- ============================================================================
-- QUERY 3: Customer Churn & Account Health Breakdown (Window Functions)
-- Business Goal: Analyze subscription lifecycle states and rank accounts by billing contributions.
-- ============================================================================

WITH Customer_Billing_Totals AS (
    SELECT 
        c.customer_id,
        c.company_name,
        c.industry,
        ISNULL(SUM(b.amount_paid), 0) AS lifetime_paid
    FROM Dim_Customers c
    LEFT JOIN Fact_Billing b ON c.customer_id = b.customer_id
    GROUP BY c.customer_id, c.company_name, c.industry
)
SELECT 
    bt.customer_id,
    bt.company_name,
    bt.industry,
    s.status AS subscription_status,
    bt.lifetime_paid,
    -- Rank customers globally based on total lifetime revenue contribution using a window function
    DENSE_RANK() OVER (ORDER BY bt.lifetime_paid DESC) AS revenue_tier_rank
FROM Customer_Billing_Totals bt
JOIN Fact_Subscriptions s ON bt.customer_id = s.customer_id
ORDER BY revenue_tier_rank;
