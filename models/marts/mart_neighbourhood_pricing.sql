with listings as (
    select * from {{ ref('int_listings_enriched') }}
),

neighbourhood_stats as (
    select
        neighbourhood,

        -- listing count
        count(listing_id)                                       as total_listings,

        -- pricing
        round(avg(price_usd), 2)                               as avg_price,
        round(median(price_usd), 2)                            as median_price,
        min(price_usd)                                         as min_price,
        max(price_usd)                                         as max_price,

        -- demand proxy (lower availability = more booked)
        round(avg(availability_365), 1)                        as avg_availability_365,
        round(avg(365 - availability_365), 1)                  as avg_nights_booked,
        round(avg(availability_365) / 365.0 * 100, 1)         as avg_availability_pct,

        -- revenue
        round(avg(estimated_annual_revenue), 2)                as avg_estimated_revenue,
        round(sum(estimated_annual_revenue), 2)                as total_estimated_revenue,

        -- quality
        round(avg(review_scores_rating), 2)                    as avg_review_score,
        round(avg(review_scores_location), 2)                  as avg_location_score,
        sum(total_reviews)                                     as total_reviews,

        -- host profile
        round(avg(case when host_is_superhost = 'True' then 1 else 0 end) * 100, 1)
                                                               as superhost_pct,

        -- room type breakdown
        count(case when room_type = 'Entire home/apt' then 1 end)   as entire_home_count,
        count(case when room_type = 'Private room' then 1 end)      as private_room_count,
        count(case when room_type = 'Shared room' then 1 end)       as shared_room_count

    from listings
    where price_usd > 0
    group by neighbourhood
),

final as (
    select
        *,
        rank() over (order by avg_price desc)                  as price_rank,
        rank() over (order by avg_nights_booked desc)          as demand_rank,
        rank() over (order by avg_estimated_revenue desc)      as revenue_rank
    from neighbourhood_stats
)

select * from final