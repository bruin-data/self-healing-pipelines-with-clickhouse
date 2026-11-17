# Harborside self-healing demo for ClickHouse Cloud

A ClickHouse adaptation of [Arsalan’s Shop example](https://github.com/arsalann/demo-self-heal/tree/main/shop). Synthetic fixtures, no customer data. See ../PROVENANCE.md.

Python orders/products → raw tables → cleaned orders/products → category/country daily revenue. Five assets, one dedicated Cloud database. Raw snapshots intentionally replace this small demo window for repeatable rehearsal; this is not an incremental production ingestion design.

## Connection

Use a NEW private `.bruin.yml` from ../config.example.yml, or an explicit private config path. TLS ports 9440/8443. Never overwrite an existing config without approval. A ClickHouse Cloud management API key is not a SQL username/password. Database creation requires a SQL identity with CREATE DATABASE; normal demo operations should be scoped to harborside_meetup.

## Rehearsal

Run each command separately, with the selected private `--config-file` when needed:

```sh
bruin validate --fast shop
bruin run shop/assets/harborside_meetup/orders_raw.py --start-date 2026-05-01 --end-date 2026-05-17
bruin run shop/assets/harborside_meetup/products_raw.py --start-date 2026-05-01 --end-date 2026-05-17
bruin run shop/assets/harborside_meetup/orders_clean.sql
bruin run shop/assets/harborside_meetup/products_clean.sql
bruin run shop/assets/harborside_meetup/revenue_daily.sql
```

After establishing the healthy baseline, run **only products_raw.py** for 2026-05-18, then products_clean.sql. The raw snapshot now contains product_category; the old stage SQL should fail with an unknown identifier. Existing stage/report tables can remain stale: inspect the failed run, not only the presence of tables.

Agent prompt: “Diagnose the failed products_clean asset using logs, lineage and the documented source change. Repair the stable category contract without changing raw generators or weakening checks. Rerun the affected assets and prove recovery.”

Expected minimal stage repair: `product_category AS category`. Rebuild products_clean then revenue_daily; repeat both and verify counts and revenue remain stable. This repair targets the current post-rename schema. To replay the old baseline, restore the old projection as well as the pre-rename source snapshot.

## Cloud

Cloud deployment is pending the user's Bruin Cloud API key and SQL credentials. Keep scheduling disabled during setup. Import the same clickhouse-meetup connection, connect a repository containing this pipeline, verify parsing, run selected assets and inspect real logs. Do not equate deployment with a working self-healing trigger; configure and verify agent access and triggers separately.
