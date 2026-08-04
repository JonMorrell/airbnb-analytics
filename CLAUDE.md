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
- `int_listings_enriched` — listings joined with review stats; adds `estimated_annual_revenue = price_usd * (365 - availability_365)`, `reviews_per_month`, and `host_tenure_days`
- `int_host_summary` — aggregates `int_listings_enriched` to host level (portfolio size, avg scores, total revenue). Filters to `price_usd > 0` before aggregating, so hosts whose entire portfolio has an unpriced (coalesced-to-zero) listing don't get ranked with `$0` revenue — see the price_usd note below.

**Marts** (implemented) answer four business questions:
- `mart_host_performance` — host ranking by revenue, superhost comparison (built on `int_host_summary`)
- `mart_neighbourhood_pricing` — pricing/demand aggregates by neighbourhood (built on `int_listings_enriched`, filters `price_usd > 0`)
- `mart_listing_positioning` — per-listing price positioning vs. neighbourhood benchmarks (built on `int_listings_enriched`, filters `price_usd > 0`)
- `mart_market_trends` — monthly review-volume trends (built on `stg_reviews` + `stg_listings`, no price filter needed)

A dbt snapshot (`snapshots/listings_snapshot.sql`) tracks SCD Type 2 history on `stg_listings` (price, room_type, bedrooms, beds, accommodates) using the `check` strategy.

An Evidence.dev dashboard lives in `dashboard/` (separate npm project) and reads from the marts via `dashboard/sources/airbnb/*.sql`, which query `dev.mart_*` directly against `data/airbnb.duckdb`. Run it with `cd dashboard && npm install && npm run dev`.

## Key Conventions

- All models use CTEs with named stages (`source`, `renamed`, `enriched`, etc.)
- `estimated_annual_revenue` is a proxy metric — actual booking data is unavailable; this is `price × booked_nights` where booked nights = `365 - availability_365`
- Staging models reference raw tables directly (`from raw.listings`), not via `source()` — there is no `sources.yml` defined yet
- Marts are materialised as tables; staging and intermediate are views (set in `dbt_project.yml`)
- `price_usd` is `coalesce(..., 0)` in `stg_listings` (34,908 listings / ~38% have no source price). Any model that aggregates or ranks by price/revenue must filter `where price_usd > 0` — three of the four marts already do this; check for this filter before adding new price-sensitive logic downstream of `int_listings_enriched`.
- `host_is_superhost` stays a native DuckDB `BOOLEAN` through staging — compare with the bare column or `not host_is_superhost`, not string literals like `'True'`.

## What's Not Yet Built

`tests/`, `macros/`, and `seeds/` directories exist but contain only `.gitkeep` placeholders — no custom singular tests or macros yet, only generic schema tests (`not_null`, `unique`, `accepted_values`, `relationships`) defined in each layer's `schema.yml`. The CI/CD workflow at `.github/workflows/dbt_ci.yml` does exist and runs `dbt build` + `dbt snapshot` + docs deploy to GitHub Pages on push/PR to `main`.
