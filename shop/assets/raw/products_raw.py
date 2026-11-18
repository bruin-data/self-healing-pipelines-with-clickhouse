""" @bruin
type: python
image: python:3.11
connection: clickhouse-meetup
description: Synthetic Harborside product extracts. Stable catalog records recur in each extract, with
  a few new synthetic products per run. The source renames category to product_category from 2026-05-18.
materialization:
  type: table
  strategy: append
owner: dana@harborside.example
tags:
- harborside
- shop
- raw
- products
domains:
- commerce
meta:
  layer: raw
  tier: bronze
  team: finance
  cost_center: FIN-204
  source: harborside-api products (emulated)
  contains_incidents: schema-drift-column-rename
columns:
- name: product_id
  type: String
  description: Product identifier.
  nullable: false
  checks:
  - name: not_null
- name: name
  type: String
  description: Product display name.
  nullable: false
- name: price_usd
  type: Float64
  description: List price in USD.
  nullable: false
  checks:
  - name: positive
- name: extracted_at
  type: DateTime64(6)
  description: UTC timestamp when this catalog snapshot was generated.
  nullable: false
@bruin """

from bruin import context


import os
import random
import uuid
from datetime import date, datetime, timezone

import pandas as pd

CATEGORIES = ["apparel", "electronics", "home", "books", "outdoors", "beauty"]
DRIFT_DATE = date(2026, 5, 18)


def materialize():
    rng = random.Random(42)
    rows = []
    for i in range(1, 31):
        rows.append({
            "product_id": f"P{i:03d}",
            "name": f"Product {i:03d}",
            "category": rng.choice(CATEGORIES),
            "price_usd": round(rng.uniform(10, 400), 2),
        })

    # Keep the original 30 products stable; each extract also brings new products.
    for _ in range(random.SystemRandom().randint(3, 6)):
        product_id = f"N{uuid.uuid4().hex[:16]}"
        rows.append({
            "product_id": product_id,
            "name": f"Product {product_id}",
            "category": random.SystemRandom().choice(CATEGORIES),
            "price_usd": round(random.SystemRandom().uniform(10, 400), 2),
        })

    df = pd.DataFrame(rows)
    df["extracted_at"] = datetime.fromisoformat(str(context.end_date)[:10])
    df["extracted_at"] = pd.to_datetime(df["extracted_at"]).astype("datetime64[us]")

    end_str = str(context.end_date)
    end = date.fromisoformat(end_str[:10])

    if end >= DRIFT_DATE:
        df = df.rename(columns={"category": "product_category"})
        print(f"[shop] schema drift active: 'category' -> 'product_category' (end_date={end})")

    print(f"[shop] emitted {len(df)} products with columns {list(df.columns)}")
    return df
