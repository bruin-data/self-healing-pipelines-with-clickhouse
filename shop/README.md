# Harborside self-healing demo for ClickHouse Cloud

Synthetic data, adapted from Arsalan’s Shop example. Five assets run on the dedicated meetup ClickHouse service: Python extracts in `raw`, latest conformed data in `clean`, and daily revenue in `mart`. See ../PROVENANCE.md.

`orders_raw` and `products_raw` append extracts. The 30 original products and generated daily orders are repeatable; each non-empty extract also adds a few new synthetic records. Replaying an interval intentionally appends existing records again, so raw counts grow. The clean assets deduplicate by their business keys. Orders use an inclusive date loop; overlapping windows also repeat boundary days. This is a demo, not exactly-once ingestion.

The product API changes `category` to `product_category` at 2026-05-18. In a table seeded with an old extract and then an appended new extract, both nullable physical columns exist: historical rows use the former and current rows the latter. Before repair, the product stage reads only `category`. Its `not_null` check catches missing categories on the latest new-schema rows. The stable downstream output is still called `category`.

## Connection and execution

Use the private ignored `.bruin.yml` with `clickhouse-meetup`. Never commit credentials. A Cloud API key is not a ClickHouse SQL credential. Keep Cloud schedules disabled while rehearsing; run individual assets.

```sh
bruin validate --fast shop
bruin run shop/assets/raw/orders_raw.py --start-date 2026-05-01 --end-date 2026-05-17
bruin run shop/assets/raw/products_raw.py --start-date 2026-05-16 --end-date 2026-05-17
bruin run shop/assets/clean/orders_clean.sql
bruin run shop/assets/clean/products_clean.sql
bruin run shop/assets/mart/revenue_daily.sql
```

After a clean pre-change baseline, append the new product extract with `--start-date 2026-05-18 --end-date 2026-05-19`, then run only `clean.products_clean`. Expect its `category.not_null` check to fail. The table may already have been rebuilt when the check fails, so downstream data must not be treated as recovered until rebuilt and checked.

Diagnose the actual failed run, inspect the source columns, and preserve both historical and new categories. A repair can use `coalesce(product_category, category)` when both columns are present, while retaining the not-null check. A direct reference to a missing column fails before COALESCE runs, so verify both columns exist when testing the repaired projection. Verify historical and new records using isolated synthetic fixtures. Rebuild the stage and revenue separately, compare raw/deduplicated order counts and revenue, and repeat to prove stable results. See [the self-healing runbook](../docs/self-healing.md).
