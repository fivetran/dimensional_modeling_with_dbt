# New idea: define models centrally.
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