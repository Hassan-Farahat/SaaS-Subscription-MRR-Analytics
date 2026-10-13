# SaaS Subscription Analytics, Recurring Revenue (MRR), & Customer LTV

## Executive Overview
This portfolio project models subscription-based business metrics—including Monthly Recurring Revenue (MRR), customer payment histories, and churn status tracking. Designed using a relational schema, it answers core financial and operational questions for SaaS, fintech, and digital platforms.

## Data Model Architecture
The database is structured around core operational entities:
- **Fact Tables:** `Fact_Subscriptions`, `Fact_Billing`
- **Dimension Tables:** `Dim_Plans`, `Dim_Customers`

## Key Business Insights & Analytical Output

### 1. Monthly Recurring Revenue (MRR)
- **Professional & Enterprise Plans** drive the bulk of predictable monthly cash flow.
- Tracking active subscribers per plan highlights product tier adoption rates.

### 2. Revenue Contribution & Industry Focus
- Enterprise accounts (e.g., **Global Logistics Corp** and **Fintech Innovations**) generate high lifetime values before or during lifecycle changes.
- Segmenting by industry uncovers high-value verticals for targeted customer acquisition strategies.

### 3. Account Health & Churn Tracking
- Combined subscription status flags (`Active`, `Cancelled`, `Upgraded`) allow executive teams to monitor retention friction points.
- Window functions (`DENSE_RANK()`) rank accounts by total revenue contribution to isolate top-tier VIP customers.

## Strategic Business Recommendations
1. **Expansion Optimization:** Focus marketing on upgrading active mid-tier subscribers to enterprise plans.
2. **Churn Prevention Workflows:** Implement proactive account check-ins for high-value accounts showing cancellation triggers.