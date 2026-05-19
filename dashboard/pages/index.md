# Airbnb London Market Intelligence

An analysis of **London's short-term rental market** using 31 million rows of Inside Airbnb data.

---

## Top 10 Hosts by Estimated Annual Revenue

```sql top_hosts
select 
    host_name,
    total_listings,
    host_tier,
    avg_review_score,
    round(total_estimated_revenue, 0) as total_estimated_revenue
from airbnb.host_performance
order by total_estimated_revenue desc
limit 10
```

<DataTable data={top_hosts} rows=10/>

<BarChart 
    data={top_hosts} 
    x=host_name 
    y=total_estimated_revenue
    title="Top 10 Hosts by Estimated Annual Revenue"
    yAxisTitle="Estimated Annual Revenue (£)"
/>

---

## Superhosts vs Standard Hosts

```sql host_comparison
select
    host_tier,
    count(*) as total_hosts,
    round(avg(avg_review_score), 2) as avg_review_score,
    round(avg(total_estimated_revenue), 0) as avg_revenue,
    round(avg(avg_listing_price), 0) as avg_price
from airbnb.host_performance
group by host_tier
```

<DataTable data={host_comparison}/>