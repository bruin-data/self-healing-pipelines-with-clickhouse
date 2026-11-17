# Harborside ClickHouse demo

Fictional data, adapted from Arsalan's Harborside reference project. Only `harborside_meetup` on the dedicated ClickHouse Cloud meetup service is in scope. No local server or Docker. Do not modify existing credentials/configurations. Never print secrets.

The Python raw assets emulate source systems; do not change them to hide failures. The product API renamed `category` to `product_category` on 2026-05-18; values and business meaning did not change. The stable stage/report field remains `category`. Owner: Dana, Finance (fictional). Revenue here is gross storefront order amount in USD; this fixture has no status/refund fields.

Repair only stage SQL for this incident. Keep checks and source data. Run individual assets, not the entire pipeline. User has authorized setup and verification in this isolated demo database. Do not enable recurring Cloud schedules until the demo is verified.

Before claiming recovery: show the SQL diff, run the repaired stage then revenue asset with all checks, compare raw/dedup order counts and revenue, rerun and verify stable counts/totals. A stale successful report is not evidence of a recovered stage.
