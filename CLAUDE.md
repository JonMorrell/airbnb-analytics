# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A dbt + DuckDB analytics project over the London Inside Airbnb dataset (~90k listings, ~1.2M reviews, ~31M calendar rows). The goal is a multi-layer data model feeding a business analytics dashboard.

## Commands

```bash
# Activate virtual environment (Windows)
venv\Scripts\activate

# Load raw CSVs into DuckDB (run once, or after raw data changes)
python load_data.py

# Run and test all models
dbt build

# Run all models without tests
dbt run

# Run tests only
dbt test

# Run a single model
dbt run --select stg_listings
dbt run --select int_listings_enriched

# Run a model and all its downstream dependents
dbt run --select int_listings_enriched+

# Compile SQL without executing
dbt compile
```

The DuckDB database file is at `data/airbnb.duckdb`. Raw CSVs live in `data/raw/` (gitignored).

## Architecture

The data flows through three dbt layers, all backed by a local DuckDB file:

```
raw.* (DuckDB tables, loaded by load_data.py)
  └── staging/          (views) — rename + type-cast only, no business logic
        └── intermediate/  (views) — joins and derived metrics
              └── marts/      (tables) — business-facing aggregates
```

**Staging** reads directly from `raw.*` schema tables. No joins, no logic — only column renames to `snake_case` and type casts (e.g. price strings like `$120.00` → `double`).

**Intermediate** builds two reusable models consumed by all marts:
- `int_listings_enriched` — listings joined with review stats; adds `estimated_annual_revenue = price_usd * (365 - availability_365)` and `reviews_per_month`
- `int_host_summary` — aggregates `int_listings_enriched` to host level (portfolio size, avg scores, total revenue)

**Marts** (planned, not yet implemented) answer four business questions: host performance, neighbourhood pricing, listing positioning, and market trends.

## Key Conventions

- All models use CTEs with named stages (`source`, `renamed`, `enriched`, etc.)
- `estimated_annual_revenue` is a proxy metric — actual booking data is unavailable; this is `price × booked_nights` where booked nights = `365 - availability_365`
- Staging models reference raw tables directly (`from raw.listings`), not via `source()` — there is no `sources.yml` defined yet
- Marts are materialised as tables; staging and intermediate are views (set in `dbt_project.yml`)

## What's Not Yet Built

The `models/marts/` directory is empty. `tests/`, `macros/`, `snapshots/`, and `seeds/` directories exist but contain only `.gitkeep` placeholders. The CI/CD workflow (`.github/workflows/dbt_ci.yml`) referenced in the README does not exist yet.
