# Neighbourhood Intelligence

Where to stay, where to invest, and where to avoid.

---

## Pricing by Neighbourhood (Top 20)

```sql neighbourhood_pricing
select
    neighbourhood,
    avg_price,
    median_price,
    total_listings,
    avg_nights_booked,
    avg_review_score,
    superhost_pct,
    price_rank,
    demand_rank
from airbnb.neighbourhood_pricing
order by avg_price desc
limit 20
```

<DataTable data={neighbourhood_pricing} rows=20/>

<BarChart
    data={neighbourhood_pricing}
    x=neighbourhood
    y=avg_price
    title="Average Nightly Price by Neighbourhood"
    yAxisTitle="Average Price (£)"
    swapXY=true
/>

---

## Price vs Demand

```sql price_vs_demand
select
    neighbourhood,
    avg_price,
    avg_nights_booked,
    total_listings,
    avg_review_score
from airbnb.neighbourhood_pricing
where total_listings > 100
```

<ScatterPlot
    data={price_vs_demand}
    x=avg_nights_booked
    y=avg_price
    series=neighbourhood
    title="Price vs Demand by Neighbourhood"
    xAxisTitle="Average Nights Booked per Year"
    yAxisTitle="Average Nightly Price (£)"
/>

---

## Full Neighbourhood Table

```sql all_neighbourhoods
select
    neighbourhood,
    total_listings,
    avg_price,
    median_price,
    avg_nights_booked,
    avg_review_score,
    superhost_pct,
    total_estimated_revenue,
    price_rank,
    demand_rank,
    revenue_rank
from airbnb.neighbourhood_pricing
order by revenue_rank
```

<DataTable data={all_neighbourhoods} search=true rows=15/>