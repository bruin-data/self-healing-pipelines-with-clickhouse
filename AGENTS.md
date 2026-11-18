# Harborside ClickHouse demo

Fictional data, adapted from Arsalan's Harborside reference project. Only `raw`, `clean`, and `mart` on the dedicated ClickHouse Cloud meetup service are in scope; the original `harborside_meetup` database is legacy and must be preserved. No local server or Docker. Do not modify existing credentials/configurations. Never print secrets.

The Python raw assets emulate source systems; do not change them to hide failures. The product API renamed `category` to `product_category` on 2026-05-18; values and business meaning did not change. The stable stage/report field remains `category`. Owner: Dana, Finance (fictional). Revenue here is gross storefront order amount in USD; this fixture has no status/refund fields.

Historical compatibility is required: raw product extracts are appended, preserving old `category` values and adding `product_category` on the source rename. Old rows have the new field null and new rows have the old field null. Silver must retain one latest row per product and its category `not_null` check must catch new records that the old projection misses. A repair must preserve both old and new values, retain the checks, and be verified against both cohorts. Do not replace or truncate raw history to stage the incident.

Repair only stage SQL for this incident. Keep checks and source data. Run individual assets, not the entire pipeline. User has authorized setup and verification in this isolated demo database. Do not enable recurring Cloud schedules until the demo is verified.

Before claiming recovery: show the SQL diff, run the repaired stage then revenue asset with all checks, compare raw/dedup order counts and revenue, rerun and verify stable counts/totals. A stale successful report is not evidence of a recovered stage.

For a pipeline failure, follow [the incident runbook](docs/self-healing.md). Inspect the actual failed run and lineage before proposing changes. Open a pull request with the evidence and validation results; do not merge it. If access, verification, or GitHub permissions are missing, report the precise blocker rather than claiming success.
