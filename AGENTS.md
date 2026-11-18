# Harborside ClickHouse demo

Fictional data, adapted from Arsalan's Harborside reference project. Only `raw`, `clean`, and `mart` on the dedicated ClickHouse Cloud meetup service are in scope; the original `harborside_meetup` database is legacy and must be preserved. No local server or Docker. Do not modify existing credentials/configurations. Never print secrets.

The Python raw assets emulate source systems; do not change them to hide failures. The product API renamed `category` to `product_category` on 2026-05-18; values and business meaning did not change. The stable stage/report field remains `category`. Owner: Dana, Finance (fictional). Revenue here is gross storefront order amount in USD; this fixture has no status/refund fields.

Historical replay is required: the same stage SQL must work with a pre-rename raw snapshot containing only `category` and a post-rename snapshot containing only `product_category`, without changing the raw generators or weakening checks. The raw asset replaces the snapshot, so only one source column exists at a time. A plain `coalesce(category, product_category)` is insufficient: ClickHouse rejects a reference to a missing column before evaluating COALESCE. Validate both schema versions using isolated synthetic fixtures and verify the stable `category` values; do not overwrite the live raw snapshot for a test. If safe backward compatibility cannot be implemented within the stage SQL scope, report the limitation rather than claiming a complete fix.

Repair only stage SQL for this incident. Keep checks and source data. Run individual assets, not the entire pipeline. User has authorized setup and verification in this isolated demo database. Do not enable recurring Cloud schedules until the demo is verified.

Before claiming recovery: show the SQL diff, run the repaired stage then revenue asset with all checks, compare raw/dedup order counts and revenue, rerun and verify stable counts/totals. A stale successful report is not evidence of a recovered stage.

For a pipeline failure, follow [the incident runbook](docs/self-healing.md). Inspect the actual failed run and lineage before proposing changes. Open a pull request with the evidence and validation results; do not merge it. If access, verification, or GitHub permissions are missing, report the precise blocker rather than claiming success.
