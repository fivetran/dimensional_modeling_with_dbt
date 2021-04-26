# Extending dbt with Dimensional Modeling
Suppose we have a simple dbt project with two models, `dim_account` and `fact_revenue`:

```sql
select 
  ___ as account_id, 
  ___ as customer_type, 
  ___ as acquisition_channel,
  ___ as became_customer_date,
  ...
from ...
```

```sql
select 
  ___ as account_id,
  ___ as recognized_date, 
  ___ as revenue, 
  ...
from ...
```

We extend dbt with a new concept: dimensional modeling. 

```python
dimension(
  "dim_account.customer_type",
  type = string,
)

dimension(
  "dim_account.acquisition_channel",
  type = string,
)

dimension(
  "dim_account.became_customer_date",
  type = date,
  levels = [year, quarter, month],
)

dimension(
  "fact_revenue.recognized_date",
  type = date,
  levels = [year, quarter, month],
)

measure(
  "fact_revenue.account_id",
  type = count,
  distinct = True,
)

measure(
  "fact_revenue.revenue",
  type = sum,
)

model(
  "fact_revenue",
  joins = [
    join(
      "dim_account", 
      using = "account_id",
      type = many_to_one,
    ),
  ]
)
```

This dimensional model serves two goals:
1. Define dimension, measure and join metadata in one place where it can be consumed by all BI tools.
2. Enable alternative query implementational strategies.

## Query Acceleration Strategies

Goal (2) can be accomplished in many ways. A few alternatives are enumerated below.

### Materialized Views

All the major data warehouses are capable of rewriting queries at runtime to use materialized views.
- https://docs.snowflake.com/en/user-guide/views-materialized.html#how-the-query-optimizer-uses-materialized-views
- https://cloud.google.com/bigquery/docs/materialized-views#query
- https://docs.aws.amazon.com/redshift/latest/dg/materialized-view-auto-rewrite.html

First, we need to materialize a base table at the lowest level of aggregation. The queries from the BI tool should reference this table.

```sql
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
```

Next, we choose a set of materializations that will speed up common queries using the algorithm described in https://calcite.apache.org/docs/lattice.html. Each materialization corresponds to a subset of dimensions and measures.

```sql
create materialized view model_revenue_1 as
select customer_type, acquisition_channel, sum(revenue) as revenue 
from model_revenue;

create materialized view model_revenue_2 as
select customer_type, became_customer_date, sum(revenue) as revenue 
from model_revenue;

create materialized view model_revenue_3 as
select customer_type, recognized_date, sum(revenue) as revenue 
from model_revenue;

create materialized view model_revenue_4 as
select acquisition_channel, became_customer_date, sum(revenue) as revenue 
from model_revenue;

create materialized view model_revenue_5 as
select acquisition_channel, recognized_date, sum(revenue) as revenue 
from model_revenue;

create materialized view model_revenue_6 as
select became_customer_date, recognized_date, sum(revenue) as revenue 
from model_revenue;
```

### Proxy

A separate proxy sits between the BI tool and the data warehouse:

```
BI Tool --(SQL)--> Proxy --(SQL)--> Data Warehouse
```

This proxy is a classic "cube" which maintains a cache of pre-aggregated data. Not all queries can be served from the cache; some queries have to be passed on to the data warehouse.

### Lightweight Proxy

A slight variation of the proxy concept is to have a proxy that stores no data, but instead uses the data warehouse to materialize various pre-aggregates, as described in [Materialized Views](#materialized-views). There are two benefits versus the materialized view strategy:

- You don't need to physically materialize the base table.
- The proxy guarantees the materializations are used by directly rewriting the query.