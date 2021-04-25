-- Publishing these measure definitions to BI tools is tricky.
-- For Looker, we could generate LookML.
-- For Tableau, I'm not sure there's any short-term solution.

-- The other piece of the puzzle is using measure definitions to optimize performance.
-- We can generate a set of materialized views that the query planner will use to speed up queries.
-- https://docs.snowflake.com/en/user-guide/views-materialized.html#how-the-query-optimizer-uses-materialized-views
-- https://cloud.google.com/bigquery/docs/materialized-views#query

-- This is the base table with the lowest level of aggregation.
-- The queries from the BI tool should reference this table.
create table model_revenue as
select
  -- Dimensions:
  customer_type,
  acquisition_channel,
  date_trunc(became_customer_date, month) as became_customer_date,
  date_trunc(recognized_date, month) as recognized_date,
  -- Measures:
  account_id, -- count(distinct ___) cannot be pre-aggregated so we will not attempt to optimize it.
  sum(revenue) as revenue,
from fact_revenue
join dim_account using (account_id)
group by 1, 2, 3, 4, 5;

-- Choose a set of materializations that will speed up common queries using the algorithm described in 
--   https://calcite.apache.org/docs/lattice.html
-- Each materialization corresponds to a subset of dimensions and measures.

create materialized vew model_revenue_1 as
select customer_type, acquisition_channel, sum(revenue) as revenue 
from model_revenue;

create materialized vew model_revenue_2 as
select customer_type, became_customer_date, sum(revenue) as revenue 
from model_revenue;

create materialized vew model_revenue_3 as
select customer_type, recognized_date, sum(revenue) as revenue 
from model_revenue;

create materialized vew model_revenue_4 as
select acquisition_channel, became_customer_date, sum(revenue) as revenue 
from model_revenue;

create materialized vew model_revenue_5 as
select acquisition_channel, recognized_date, sum(revenue) as revenue 
from model_revenue;

create materialized vew model_revenue_6 as
select became_customer_date, recognized_date, sum(revenue) as revenue 
from model_revenue;
