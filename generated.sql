-- Publishing these measure definitions to BI tools is tricky.
-- For Looker, we could generate LookML.
-- For Tableau, I'm not sure there's any short-term solution.

-- The other piece of the puzzle is using measure definitions to optimize performance.
-- We can generate a set of materialized views that the query planner will use to speed up queries.
-- https://docs.snowflake.com/en/user-guide/views-materialized.html#how-the-query-optimizer-uses-materialized-views
-- https://cloud.google.com/bigquery/docs/materialized-views#query

-- This is the base model with the lowest level of aggregation.
-- The queries from the BI tool should reference this table.
create table model_revenue as
select
  became_customer_date,
  customer_type,
  acquisition_channel,
  account_id,
  month,
  sum(revenue) as revenue,
from fact_revenue
join dim_account using (account_id)
group by 1, 2, 3, 4, 5;

-- Choose a set of materializations that will speed up common queries using the algorithm described in 
--   https://web.eecs.umich.edu/~jag/eecs584/papers/implementing_data_cube.pdf
-- Each materialization corresponds to a subset of dimensions and measures.
-- We can make this choice more intelligently if we have access to the actual queries using information_schema.
-- We can also give the user the ability to manually specify materializations.

-- month, customers, annual_run_rate
create materialized view model_revenue_1 as
select month, count(distinct account_id), sum(revenue) / count(distinct month) from model_revenue;

-- date_trunc(became_customer_date), 
create materialized view model_revenue_2 as
select m