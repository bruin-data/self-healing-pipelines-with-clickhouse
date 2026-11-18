# Harborside self-healing demo for ClickHouse Cloud

A ClickHouse adaptation of [Arsalan’s Shop example](https://github.com/arsalann/demo-self-heal/tree/main/shop). Synthetic fixtures, no customer data. See ../PROVENANCE.md.

Python orders/products → raw tables → cleaned orders/products → category/country daily revenue. Five assets across three databases on the dedicated Cloud service: `raw`, `clean`, and `mart`. Raw snapshots intentionally replace this small demo window for repeatable rehearsal; this is not an incremental production ingestion design.

## Connection

Use a NEW private `.bruin.yml` from ../config.example.yml, or an explicit private config path. TLS ports 9440/8443. Never overwrite an existing config without approval. A ClickHouse Cloud management API key is not a SQL username/password. Database creation requires a SQL identity with CREATE DATABASE; normal demo operations are scoped to raw, clean, and mart on the dedicated meetup service.

## Rehearsal

To rehearse from the healthy pre-rename baseline, first change the products stage projection from `coalesce(product_category, 'unknown')` to `coalesce(category, 'unknown')`. Run each command separately, with the selected private `--config-file` when needed:

```sh
bruin validate --fast shop
bruin run shop/assets/raw/orders_raw.py --start-date 2026-05-01 --end-date 2026-05-17
bruin run shop/assets/raw/products_raw.py --start-date 2026-05-01 --end-date 2026-05-17
bruin run shop/assets/clean/orders_clean.sql
bruin run shop/assets/clean/products_clean.sql
bruin run shop/assets/mart/revenue_daily.sql
```

For a rehearsal, first switch the products stage projection back to `category` and establish the pre-rename baseline. Then run **only products_raw.py** with `--start-date 2026-05-18 --end-date 2026-05-19`, then products_clean.sql. The raw snapshot now contains product_category; the old stage SQL should fail with an unknown identifier. Existing stage/report tables can remain stale: inspect the failed run, not only the presence of tables.

Agent prompt: “Diagnose the failed products_clean asset using logs, lineage and the documented source change. Repair the stable category contract without changing raw generators or weakening checks. Rerun the affected assets and prove recovery.”

Expected stage repair: `coalesce(product_category, 'unknown') AS category`. Rebuild products_clean then revenue_daily; repeat both and verify counts and revenue remain stable. This repair targets the current post-rename schema. To replay the old baseline, restore the old projection as well as the pre-rename source snapshot.

## Cloud

Cloud deployment is pending the user's Bruin Cloud API key and SQL credentials. Keep scheduling disabled during setup. Import the same clickhouse-meetup connection, connect a repository containing this pipeline, verify parsing, run selected assets and inspect real logs. Do not equate deployment with a working self-healing trigger; configure and verify agent access and triggers separately.
