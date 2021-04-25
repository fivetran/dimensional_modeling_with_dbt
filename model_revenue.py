# New idea: define models centrally.
model(
  "fact_revenue",
  join("dim_account", using = "account_id"),
  dimension(
    "customer_type",
    type = string,
  ),
  dimension(
    "became_customer_date",
    sql = "became_customer_date",
    type = date_month,
  ),
  measure(
    "customers", 
    sql = "account_id", 
    type = sum, 
    distinct = True,
  ),
  measure(
    "count_distinct_month", 
    sql = "month", 
    type = count_distinct, 
    hidden = True,
  ),
  measure(
    "sum_revenue", 
    sql = "revenue", 
    type = "sum", 
    hidden = True,
  ),
  measure(
    "annual_run_rate", 
    sql = "sum_revenue / count_distinct_month",
    type = number,
  ),
)