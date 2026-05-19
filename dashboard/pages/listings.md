# Listing Positioning

How listings are priced relative to their neighbourhood.

---

## Price Positioning Distribution

```sql positioning
select
    price_positioning,
    count(*) as total_listings,
    round(avg(price_usd), 0) as avg_price,
    round(avg(review_scores_rating), 2) as avg_review_score
from airbnb.listing_positioning
group by price_positioning
```

<DataTable data={positioning}/>

<BarChart
    data={positioning}
    x=price_positioning
    y=total_listings
    title="Listings by Price Positioning"
    yAxisTitle="Number of Listings"
/>

---

## Listing Tier Distribution

```sql tiers
select
    listing_tier,
    count(*) as total_listings,
    round(avg(price_usd), 0) as avg_price,
    round(avg(review_scores_rating), 2) as avg_review_score,
    round(avg(estimated_annual_revenue), 0) as avg_revenue
from airbnb.listing_positioning
group by listing_tier
```

<DataTable data={tiers}/>

---

## Top Value Listings

```sql best_value
select
    listing_name,
    neighbourhood,
    room_type,
    price_usd,
    review_scores_rating,
    total_reviews,
    estimated_annual_revenue,
    listing_tier,
    price_vs_avg
from airbnb.listing_positioning
where listing_tier = 'Best Value'
order by review_scores_rating desc
limit 20
```

<DataTable data={best_value} rows=20 search=true/>