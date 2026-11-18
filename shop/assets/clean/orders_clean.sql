/* @bruin
type: clickhouse.sql
connection: clickhouse-meetup
description: 'Conformed storefront orders: one row per order. Deduplicates the append-only raw table on
  order_id, keeping the latest row by created_at, so repeated source keys never inflate revenue. This
  is the stable interface every shop report builds on, and it is exposed by `uri:` so other pipelines
  (marketing web events) can reference it as a cross-pipeline dependency.

  '
depends:
- raw.orders_raw
materialization:
  type: table
  strategy: create+replace
owner: dana@harborside.example
tags:
- harborside
- shop
- stage
- orders
domains:
- commerce
meta:
  layer: stage
  tier: silver
  team: finance
  cost_center: FIN-204
  grain: one row per order
columns:
- name: order_id
  type: String
  description: Storefront order identifier. Unique after deduplication; this states the grain.
  primary_key: true
  nullable: false
  checks:
  - name: not_null
  - name: unique
- name: user_id
  type: String
  description: Customer identifier who placed the order.
  checks:
  - name: not_null
- name: product_id
  type: String
  description: Product ordered. Joins to `shop_stage.products_clean`.
  checks:
  - name: not_null
- name: country
  type: String
  description: ISO 3166-1 alpha-2 country code of the order.
  checks:
  - name: pattern
    value: ^[A-Z]{2}$
- name: amount_usd
  type: Float64
  description: Order gross amount in USD.
  checks:
  - name: positive
- name: created_at
  type: DateTime64(6)
  description: UTC timestamp the order was created.
- name: order_date
  type: Date
  description: UTC calendar date of the order, derived from created_at.
  checks:
  - name: not_null
clickhouse:
  engine: MergeTree()
  order_by:
  - order_id
@bruin */

SELECT
    assumeNotNull(order_id) AS order_id,
    user_id,
    product_id,
    assumeNotNull(country) AS country,
    amount_usd,
    created_at,
    toDate(assumeNotNull(order_date)) AS order_date
FROM raw.orders_raw
WHERE order_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY order_id
    ORDER BY created_at DESC, user_id DESC, product_id DESC, country DESC, amount_usd DESC
) = 1
