/* @bruin
type: clickhouse.sql
connection: clickhouse-meetup
description: 'Daily storefront revenue broken down by country and product category. One row per (order_date,
  country, category). Joins conformed orders to the conformed product catalog, so the product-category
  rename in the source is already normalized away. This is Finance''s slice-and-dice revenue table.

  '
depends:
- clean.orders_clean
- clean.products_clean
materialization:
  type: table
  strategy: create+replace
  partition_by: toYYYYMM(order_date)
owner: dana@harborside.example
tags:
- harborside
- shop
- report
- revenue
domains:
- commerce
- finance
meta:
  layer: report
  tier: gold
  team: finance
  cost_center: FIN-204
  sla: 06:00 UTC
columns:
- name: order_date
  type: Date
  description: UTC calendar date of the orders.
  primary_key: true
  nullable: false
  checks:
  - name: not_null
- name: country
  type: String
  description: ISO 3166-1 alpha-2 country code.
  primary_key: true
  nullable: false
- name: category
  type: String
  description: Product category, normalized in the stage layer.
  primary_key: true
  nullable: false
- name: order_count
  type: UInt64
  description: Number of orders in the slice.
  checks:
  - name: positive
- name: distinct_users
  type: UInt64
  description: Number of distinct customers in the slice.
  checks:
  - name: positive
- name: revenue_usd
  type: Float64
  description: Gross order revenue in USD for the slice.
  checks:
  - name: positive
custom_checks:
- name: revenue_reconciles_to_clean_orders
  description: Category joins must not lose or multiply revenue. Compare cents to avoid Float64 aggregation
    noise.
  query: 'WITH

    expected AS (SELECT toInt64(round(sum(amount_usd) * 100)) AS cents FROM clean.orders_clean),

    actual AS (SELECT toInt64(round(sum(revenue_usd) * 100)) AS cents FROM mart.revenue_daily)

    SELECT count() FROM expected CROSS JOIN actual WHERE expected.cents != actual.cents'
  value: 0
- name: all_orders_have_products
  description: A missing catalog key must fail instead of silently losing orders.
  query: SELECT count() FROM clean.orders_clean AS o LEFT ANTI JOIN clean.products_clean
    AS p ON o.product_id = p.product_id
  value: 0
unit_tests:
- name: joins_orders_to_categories_and_sums_revenue
  description: 'Two same-day, same-country, same-category orders should collapse to one row with the order
    count, distinct users, and summed revenue.

    '
  inputs:
  - asset: clean.orders_clean
    rows:
    - order_id: O1
      user_id: U1
      product_id: P001
      country: US
      amount_usd: 100.0
      created_at: '2026-05-01 10:00:00'
      order_date: '2026-05-01'
    - order_id: O2
      user_id: U2
      product_id: P002
      country: US
      amount_usd: 50.0
      created_at: '2026-05-01 11:00:00'
      order_date: '2026-05-01'
  - asset: clean.products_clean
    rows:
    - product_id: P001
      name: Throw Blanket
      category: home
      price_usd: 100.0
    - product_id: P002
      name: Ceramic Mug
      category: home
      price_usd: 50.0
  expected:
    match: exact
    rows:
    - order_date: '2026-05-01'
      country: US
      category: home
      order_count: 2
      distinct_users: 2
      revenue_usd: 150.0
clickhouse:
  engine: MergeTree()
  settings:
    allow_nullable_key: 1
  order_by:
  - order_date
  - country
  - category
@bruin */

SELECT
    orders.order_date,
    orders.country,
    products.category AS category,
    COUNT(*) AS order_count,
    COUNT(DISTINCT orders.user_id) AS distinct_users,
    ROUND(SUM(orders.amount_usd), 2) AS revenue_usd
FROM clean.orders_clean AS orders
INNER JOIN clean.products_clean AS products
    ON orders.product_id = products.product_id
GROUP BY 1, 2, 3
ORDER BY 1 DESC, 6 DESC
