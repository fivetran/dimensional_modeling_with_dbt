# Extending dbt with Dimensional Modeling
Suppose we have a simple dbt project with two models, `dim_account` and `fact_revenue`:

```sql
-- dim_account.sql
select 
  ___ as account_id, 
  ___ as customer_type, 
  ___ as acquisition_channel,
  ___ as became_customer_date,
  ...
from ...
```

```sql
-- fact_revenue.sql
select 
  ___ as account_id,
  ___ as recognized_date, 
  ___ as revenue, 
  ...
from ...
```

```yaml
models:
  - name: dim_account
    columns: 
      - name: account_id
      - name: customer_type
      - name: acquisition_channel
      - name: became_customer_date
    # NEW!
    measures:
      - name: customer_count
        type: count
        sql: account_id
        distinct: true

  - name: fact_revenue
    columns: 
      - name: account_id
      - name: recognized_date
      - name: revenue
    # NEW!
    measures:
      - name: total_revenue
        type: sum
        sql: revenue

# NEW!
joins:
  - name: revenue
    tables: 
      - name: fact_revenue
      - name: dim_account
        using: [account_id]
        type: many_to_one
```

BI tools will use this metadata to populate their internal semantic model. Analysts who use dbt will use this standard to define their measures and joins once, under source control, instead of repeatedly using the UI of each BI tool. Fivetran will add this metadata to our [published dbt packages](https://github.com/fivetran?q=dbt), so a newly-installed Fivetran connection will be BI-ready immediately.
