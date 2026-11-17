""" @bruin
name: harborside_meetup.orders_raw
type: python
image: python:3.11
connection: clickhouse-meetup
description: Synthetic Harborside fixture from Arsalan. Replaces this demo raw snapshot for the selected
  interval; no customer data. One row per source order, including deliberate duplicates from May 16.
materialization:
  type: table
  strategy: create+replace
owner: dana@harborside.example
tags:
- harborside
- shop
- raw
- orders
domains:
- commerce
meta:
  layer: raw
  tier: bronze
  team: finance
  cost_center: FIN-204
  source: harborside-api orders (Postgres via ingestr, emulated)
  contains_incidents: duplicate-keys;revenue-anomaly;source-stall
columns:
- name: order_id
  type: String
  description: Order identifier. The downstream deduplication key. Not unique in raw by design.
  nullable: false
  checks:
  - name: not_null
- name: user_id
  type: String
  description: Customer identifier.
  nullable: false
  checks:
  - name: not_null
- name: product_id
  type: String
  description: Product identifier.
  nullable: false
  checks:
  - name: not_null
- name: country
  type: String
  description: ISO 3166-1 alpha-2 country code.
  nullable: false
  checks:
  - name: pattern
    value: ^[A-Z]{2}$
- name: amount_usd
  type: Float64
  description: Order gross amount in USD.
  nullable: false
  checks:
  - name: positive
- name: created_at
  type: DateTime64(6)
  description: Order creation timestamp (UTC).
  nullable: false
- name: order_date
  type: Date
  description: Order date (UTC, derived from created_at).
  nullable: false
  checks:
  - name: not_null
@bruin """

from bruin import context


import hashlib
import os
import random
from datetime import date, datetime, timedelta

import pandas as pd

COUNTRIES = ["US", "GB", "DE", "FR", "TR", "BR"]
COUNTRY_WEIGHTS = [0.40, 0.15, 0.12, 0.10, 0.08, 0.15]
PRODUCT_IDS = [f"P{i:03d}" for i in range(1, 31)]
AMOUNT_BUCKETS = [(10, 30, 0.35), (30, 80, 0.40), (80, 200, 0.20), (200, 600, 0.05)]

ANOMALY_DATE = date(2026, 5, 20)
DUP_START_DATE = date(2026, 5, 16)
STALL_START_DATE = date(2026, 5, 24)
STALL_END_DATE = date(2026, 5, 25)
ORDER_COLUMNS = [
    "order_id", "user_id", "product_id", "country",
    "amount_usd", "created_at", "order_date",
]


def empty_orders_frame() -> pd.DataFrame:
    return pd.DataFrame({
        "order_id": pd.Series(dtype="string"),
        "user_id": pd.Series(dtype="string"),
        "product_id": pd.Series(dtype="string"),
        "country": pd.Series(dtype="string"),
        "amount_usd": pd.Series(dtype="float64"),
        "created_at": pd.Series(dtype="datetime64[us]"),
        "order_date": pd.Series(dtype="datetime64[ns]"),
    })


def seed_for_date(d: date) -> int:
    return int(hashlib.sha256(d.isoformat().encode()).hexdigest()[:8], 16)


def generate_amount(rng: random.Random) -> float:
    r = rng.random()
    cum = 0.0
    for lo, hi, weight in AMOUNT_BUCKETS:
        cum += weight
        if r < cum:
            return round(rng.uniform(lo, hi), 2)
    return round(rng.uniform(10, 30), 2)


def generate_day(d: date) -> pd.DataFrame:
    rng = random.Random(seed_for_date(d))
    base_count = 1500 + int(2000 * rng.random())

    countries = list(COUNTRIES)
    weights = list(COUNTRY_WEIGHTS)

    if d == ANOMALY_DATE:
        tr_index = countries.index("TR")
        weights[tr_index] = weights[tr_index] * 10
        total = sum(weights)
        weights = [w / total for w in weights]
        base_count = int(base_count * 2.5)

    rows = []
    for i in range(base_count):
        order_id = f"O{d.strftime('%Y%m%d')}{i:05d}"
        country = rng.choices(countries, weights=weights, k=1)[0]
        rows.append({
            "order_id": order_id,
            "user_id": f"U{rng.randint(1, 50000):06d}",
            "product_id": rng.choice(PRODUCT_IDS),
            "country": country,
            "amount_usd": generate_amount(rng),
            "created_at": datetime.combine(d, datetime.min.time())
                          + timedelta(seconds=rng.randint(0, 86399)),
            "order_date": d,
        })

    if d >= DUP_START_DATE:
        dup_count = 12
        for _ in range(dup_count):
            victim = rng.choice(rows)
            rows.append({**victim, "user_id": f"U{rng.randint(1, 50000):06d}"})

    return pd.DataFrame(rows)


def materialize():
    start_str = str(context.args.start_date)
    end_str = str(context.args.end_date)

    start = date.fromisoformat(start_str[:10])
    end = date.fromisoformat(end_str[:10])

    frames = []
    current = start
    while current <= end:
        if STALL_START_DATE <= current <= STALL_END_DATE:
            print(f"[shop] {current}: simulated source stall — returning 0 rows")
        else:
            frames.append(generate_day(current))
        current += timedelta(days=1)

    if not frames:
        return empty_orders_frame()

    df = pd.concat(frames, ignore_index=True)[ORDER_COLUMNS]
    df["amount_usd"] = df["amount_usd"].astype("float64")
    df["created_at"] = pd.to_datetime(df["created_at"]).astype("datetime64[us]")
    df["order_date"] = pd.to_datetime(df["order_date"])
    print(f"[shop] generated {len(df):,} orders across {df['order_date'].nunique()} days")
    return df
