/* @bruin
name: harborside_meetup.products_clean
type: clickhouse.sql
connection: clickhouse-meetup
description: One row per product. Stable downstream category contract. Intentionally expects the pre-May-18
  source column; recover by adapting this stage projection to the documented rename.
depends:
- harborside_meetup.products_raw
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
    product_id,
    name,
    category,
    price_usd
FROM harborside_meetup.products_raw
