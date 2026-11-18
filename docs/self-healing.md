# Self-healing incident runbook

This is a synthetic, isolated ClickHouse Cloud demo. Work only in `raw`, `clean`, and `mart` on the meetup service. Do not touch the legacy `harborside_meetup` database.

1. Identify the exact failing run, asset, revision, error, and execution context. Read the failed step logs, asset definition, upstream schema, lineage, and existing checks. A successful old table does not prove the failed asset recovered.
2. Compare the source contract with the stable stage contract. Explain the evidence and affected downstream assets. If the cause or business meaning is unclear, stop and report what is missing.
3. Make the smallest stage SQL change in a new branch. Never change the Python source generators, data, checks, credentials, or pipeline schedule to make a failure disappear. Do not merge or push to the project's base branch.
4. Show the SQL diff. Run only the repaired stage and then its affected revenue asset, with all checks enabled. Inspect the results rather than relying only on exit codes.
5. Compare raw row count and distinct order IDs against clean order count. Compare raw gross amount separately from clean gross amount and mart order count and revenue, allowing for intentional raw duplicates. Run the repaired stage and revenue asset a second time and verify counts and totals remain stable.
6. Open a PR against the branch used by the failed run. Include the failed run link, root cause, diff, validation evidence, and any unresolved limitation. Do not claim recovery if any verification or PR creation failed. Never expose credentials.

Run commands with the available Cloud connection and the correct project and pipeline. Do not assume a stale report or another pipeline's successful run is evidence for this incident. If GitHub write access or isolated execution is unavailable, explain the blocker instead of fabricating a PR or silently changing production state.
