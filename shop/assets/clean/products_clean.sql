/* @bruin
type: clickhouse.sql
connection: clickhouse-meetup
description: One row per product. Normalizes the renamed source field to the stable downstream category contract.
depends:
- raw.products_raw
materialization:
  type: table
  strategy: create+replace
owner: dana@harborside.example
tags:
- harborside
- shop
- stage
- products
domains:
- commerce
meta:
  layer: stage
  tier: silver
  team: finance
  cost_center: FIN-204
  grain: one row per product
columns:
- name: product_id
  type: String
  description: Product identifier. Unique after deduplication.
  primary_key: true
  nullable: false
  checks:
  - name: not_null
  - name: unique
- name: name
  type: String
  description: Product display name.
- name: category
  type: String
  description: 'Product category, normalized from either source column name. `unknown` when the source
    omitted it.

    '
  checks:
  - name: not_null
  - name: accepted_values
    value:
    - apparel
    - electronics
    - home
    - books
    - outdoors
    - beauty
    - unknown
- name: price_usd
  type: Float64
  description: List price in USD.
  checks:
  - name: positive
clickhouse:
  engine: MergeTree()
  order_by:
  - product_id
@bruin */

SELECT
    assumeNotNull(product_id) AS product_id,
    name,
    coalesce(category, 'unknown') AS category,
    price_usd
FROM raw.products_raw
