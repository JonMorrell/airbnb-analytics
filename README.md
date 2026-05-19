# Airbnb Market Intelligence Platform
> A production-grade analytics engineering portfolio project built on the London Inside Airbnb dataset.

---

## Overview

This project demonstrates a full modern data stack implementation, from raw data ingestion through to business-ready dashboards. It is designed to showcase senior analytics engineering skills including dimensional modelling, data quality, CI/CD, and business storytelling.

The platform answers four core business questions about the London short-term rental market:

- **Host Performance** — Which hosts generate the most revenue, and do superhosts actually outperform?
- **Neighbourhood Intelligence** — Which areas command the highest prices and have the most demand?
- **Pricing Dynamics** — How does price vary by property type, and which listings are outliers?
- **Market Trends** — How has the London Airbnb market grown over time?

---

## Architecture

```
Raw Data (DuckDB)
    └── Ingestion (Python / dlt)
            └── Staging Layer (dbt)         # 1:1 with source, cleaned & typed
                    └── Intermediate Layer (dbt)   # Joined & enriched
                            └── Marts Layer (dbt)       # Business-facing aggregates
                                    └── Dashboard (Evidence.dev)
```

### Tech Stack

| Layer | Tool | Rationale |
|---|---|---|
| Warehouse | DuckDB | Free, fast, runs locally, no infrastructure needed |
| Transformation | dbt Core | Industry standard, enables testing, docs, and lineage |
| Orchestration | Dagster | Modern orchestrator with excellent dbt integration |
| BI / Dashboard | Evidence.dev | Code-based BI, version controllable, deploys free |
| CI/CD | GitHub Actions | Runs dbt tests on every pull request |
| Language | Python + SQL | Ingestion in Python, all transformation in SQL via dbt |

---

## Data Sources

Data is sourced from [Inside Airbnb](http://insideairbnb.com/get-the-data/), a publicly available dataset scraping Airbnb listings. The London dataset is one of the richest available.

| File | Description | Approx. Rows |
|---|---|---|
| `listings.csv` | Every active listing with ~70 attributes | ~90,000 |
| `reviews.csv` | All guest reviews with dates | ~1.2M |
| `calendar.csv` | Daily availability and price per listing | ~31M |

---

## Project Structure

```
airbnb-analytics/
├── data/
│   ├── raw/                        # Raw CSVs (gitignored)
│   └── airbnb.duckdb               # Local DuckDB database (gitignored)
├── models/
│   ├── staging/                    # Cleaned, typed, renamed source models
│   │   ├── stg_listings.sql
│   │   ├── stg_reviews.sql
│   │   └── stg_calendar.sql
│   ├── intermediate/               # Joined and enriched models
│   │   ├── int_listings_enriched.sql
│   │   └── int_host_summary.sql
│   └── marts/                      # Business-facing aggregates
│       ├── mart_host_performance.sql
│       ├── mart_neighbourhood_pricing.sql
│       ├── mart_listing_positioning.sql
│       └── mart_market_trends.sql
├── tests/                          # Custom dbt tests
├── macros/                         # Reusable dbt macros
├── snapshots/                      # SCD Type 2 snapshots
├── .github/
│   └── workflows/
│       └── dbt_ci.yml              # CI pipeline — runs dbt test on PRs
├── dbt_project.yml
├── packages.yml
└── README.md
```

---

## Data Models

### Staging Layer
Staging models are a 1:1 representation of the source data. The only transformations applied are:
- Renaming columns to a consistent `snake_case` convention
- Casting data types (e.g. price strings like `$120.00` cast to `double`)
- No business logic or joins at this layer

### Intermediate Layer
Intermediate models join and enrich staging models to produce reusable building blocks for the marts layer. Key models:

- **`int_listings_enriched`** — Listings joined with review activity stats and derived metrics including `estimated_annual_revenue` (price × booked nights) and `reviews_per_month`
- **`int_host_summary`** — Listing-level data aggregated to host level, including portfolio size, average review scores, and total estimated revenue

### Marts Layer
Marts are the business-facing layer, designed to directly answer stakeholder questions. Each mart is materialised as a table for query performance.

| Mart | Business Question |
|---|---|
| `mart_host_performance` | Host ranking by revenue, superhost analysis |
| `mart_neighbourhood_pricing` | Price and demand by neighbourhood |
| `mart_listing_positioning` | Price outlier detection, room type analysis |
| `mart_market_trends` | Market growth over time via review proxy |

### Slowly Changing Dimensions (SCD Type 2)
Listing prices change over time. A dbt snapshot tracks historical price changes on listings, enabling point-in-time analysis of how the market has evolved.

---

## Data Quality

Every model includes dbt tests covering:

- `not_null` and `unique` constraints on all primary keys
- `accepted_values` tests on categorical fields (e.g. `room_type`)
- Custom tests for business logic (e.g. price must be > 0, availability must be between 0 and 365)
- `dbt-expectations` package for advanced assertions

Run all tests with:

```bash
dbt test
```

### Data Quality Issues Found and Fixed

Running the test suite against real data surfaced two issues that were investigated and resolved:

**Issue 1: Null prices in `stg_listings`**
34,908 listings (roughly 38% of the dataset) had null values in `price_usd` after the initial cast from the raw string format (`$120.00`). Investigation showed these listings had genuinely empty price fields in the source data — Airbnb listings that were incomplete or inactive at the time of scraping.

Fix: Added a `coalesce(..., 0)` wrapper to the price cast in `stg_listings`, defaulting null prices to 0 and flagging them for exclusion in downstream models via `WHERE price_usd > 0` filters.

**Issue 2: Null `total_estimated_revenue` in `mart_host_performance`**
25,219 hosts had null estimated revenue, which cascaded directly from the null prices above. Once the upstream price fix was applied and the pipeline rebuilt from `stg_listings` downward, this failure resolved automatically.

This is a good example of why testing at the staging layer catches problems early — a single null fix propagated cleanly through the entire downstream pipeline without any further changes.

---

## CI/CD

A GitHub Actions workflow runs on every pull request to `main`:

1. Checks out the repository
2. Installs dbt and dependencies
3. Runs `dbt build` (compile + run + test) against a lightweight CI database
4. Fails the PR if any model or test fails

This ensures no broken models are merged to the main branch.

---

## Getting Started

### Prerequisites
- Python 3.9+
- Git

### Setup

```bash
# Clone the repo
git clone https://github.com/yourusername/airbnb-analytics.git
cd airbnb-analytics

# Create and activate virtual environment
python -m venv venv
venv\Scripts\activate        # Windows
source venv/bin/activate     # Mac/Linux

# Install dependencies
pip install dbt-duckdb

# Download raw data from Inside Airbnb (London dataset)
# Place listings.csv, reviews.csv, calendar.csv in data/raw/

# Load raw data into DuckDB
python load_data.py

# Run dbt
dbt build
```

---

## Design Decisions

**Why DuckDB over Snowflake or BigQuery?**
DuckDB handles the full London dataset (31M+ rows in calendar alone) comfortably on a laptop with no infrastructure, no cost, and no credentials to manage. For a portfolio project this is the right call — it demonstrates cost-conscious tooling decisions, a real senior skill.

**Why Evidence.dev over Tableau or Looker?**
Evidence.dev produces dashboards from SQL and Markdown, meaning the entire project — including the dashboard — lives in version control. This is the direction modern analytics tooling is heading and demonstrates awareness of the current landscape.

**Why the dashboard isn't hosted publicly**
The natural deployment target for an Evidence.dev dashboard is Vercel, which Evidence supports natively. However, Vercel requires a live database connection at build time — it cannot access a local DuckDB file. The two production-grade solutions evaluated were:

- **MotherDuck** (cloud-hosted DuckDB) — connected and working locally, but no longer offers a free tier beyond a 7-day trial, making it unsuitable for a long-running portfolio project
- **Parquet files committed to git** — technically viable but considered bad practice for a code repository, and misrepresents the architecture

The decision was made to prioritise a clean, honest repository over a hosted dashboard. The dashboard runs locally via `npm run dev` and is demonstrated in the project video. In a production context with a cloud warehouse (BigQuery or Snowflake), this would be a non-issue — Evidence connects to those natively and Vercel deployment would be straightforward.

**Why estimated revenue rather than actual revenue?**
Inside Airbnb does not provide actual booking data. `estimated_annual_revenue` is calculated as `price × (365 - availability_365)`, which is a widely used proxy in Airbnb market analysis. This assumption is documented explicitly in the model.

---

## What I Would Do Differently at Scale

- Replace the Python CSV loader with a proper ingestion tool (dlt or Airbyte) with schema evolution handling
- Add a streaming layer for real-time availability updates via Kafka
- Implement row-level access controls in the mart layer for multi-tenant use
- Add a semantic/metrics layer (dbt Metrics or Cube) to enforce consistent metric definitions across dashboards
- Move to a cloud warehouse (BigQuery or Snowflake) and provision infrastructure with Terraform

---

## Author

Built by Jon Morrell as an analytics engineering portfolio project.  
[LinkedIn](https://linkedin.com/in/jondmorrell) · [GitHub](https://github.com/JonMorrell)
```