# Market Trends

How London's Airbnb market has grown over time.

---

## Monthly Review Activity

```sql monthly_trends
select
    review_month,
    total_reviews,
    active_listings,
    unique_reviewers,
    rolling_3m_avg_reviews,
    review_growth_pct
from airbnb.market_trends
order by review_month
```

<LineChart
    data={monthly_trends}
    x=review_month
    y=total_reviews
    title="Monthly Reviews (Demand Proxy)"
    yAxisTitle="Total Reviews"
/>

---

## Rolling 3 Month Average

<LineChart
    data={monthly_trends}
    x=review_month
    y=rolling_3m_avg_reviews
    title="Rolling 3-Month Average Reviews"
    yAxisTitle="Reviews (3m avg)"
/>

---

## Month on Month Growth

```sql growth
select
    review_month,
    review_growth_pct
from airbnb.market_trends
where review_growth_pct is not null
order by review_month
```

<LineChart
    data={growth}
    x=review_month
    y=review_growth_pct
    title="Month on Month Review Growth %"
    yAxisTitle="Growth %"
/>