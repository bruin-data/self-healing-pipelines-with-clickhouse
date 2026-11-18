# Self-healing pipelines with ClickHouse

A hands-on meetup demo: a product-source schema change breaks a pipeline; an agent diagnoses and repairs the stage contract, then verifies downstream revenue. Built with Bruin and ClickHouse Cloud. No Docker or local database server.

## Demo

[Shop walkthrough](shop/README.md): deterministic Harborside orders and products, duplicate handling, source schema drift, daily revenue, lineage and data quality checks. Five assets across isolated `raw`, `clean`, and `mart` databases on the dedicated meetup service. Data and incidents are synthetic.

[Agent policy](AGENTS.md) · [Source attribution](PROVENANCE.md) · [Connection template](config.example.yml)

```sh
bruin validate --fast shop
```

SQL credentials belong in a private, ignored `.bruin.yml` or Bruin Cloud connection. Never commit passwords, API keys or downloaded credential files.

Based on Arsalan’s [Harborside reference project](https://github.com/arsalann/demo-self-heal). The existing community Cloud project is backed by [arsalann/bruin-community](https://github.com/arsalann/bruin-community); the larger [data_playground](https://github.com/arsalann/data_playground) includes self-heal-shop, self-heal-iot and self-heal-webevents. This repository keeps the ClickHouse meetup demo independent.
