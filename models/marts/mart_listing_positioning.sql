with listings as (
    select * from {{ ref('int_listings_enriched') }}
),

neighbourhood_benchmarks as (
    select
        neighbourhood,
        round(avg(price_usd), 2)                                as neighbourhood_avg_price,
        round(median(price_usd), 2)                             as neighbourhood_median_price,
        round(avg(review_scores_rating), 2)                     as neighbourhood_avg_rating
    from listings
    where price_usd > 0
    group by neighbourhood
),

final as (
    select
        l.listing_id,
        l.listing_name,
        l.neighbourhood,
        l.room_type,
        l.property_type,
        l.accommodates,
        l.bedrooms,
        l.beds,
        l.price_usd,
        l.review_scores_rating,
        l.total_reviews,
        l.reviews_per_month,
        l.estimated_annual_revenue,
        l.host_id,
        l.host_name,
        l.host_is_superhost,

        -- price positioning vs neighbourhood
        n.neighbourhood_avg_price,
        n.neighbourhood_median_price,
        round(l.price_usd - n.neighbourhood_avg_price, 2)      as price_vs_avg,
        round(l.price_usd / nullif(n.neighbourhood_avg_price, 0) * 100, 1)
                                                                as price_index,

        -- price outlier flag
        case
            when l.price_usd > n.neighbourhood_avg_price * 2   then 'Overpriced'
            when l.price_usd < n.neighbourhood_avg_price * 0.5 then 'Underpriced'
            else 'Fairly Priced'
        end                                                     as price_positioning,

        -- quality vs price label
        case
            when l.price_usd > n.neighbourhood_avg_price
                and l.review_scores_rating >= n.neighbourhood_avg_rating
                then 'Premium'
            when l.price_usd > n.neighbourhood_avg_price
                and l.review_scores_rating < n.neighbourhood_avg_rating
                then 'Overpriced'
            when l.price_usd <= n.neighbourhood_avg_price
                and l.review_scores_rating >= n.neighbourhood_avg_rating
                then 'Best Value'
            else 'Budget'
        end                                                     as listing_tier

    from listings l
    left join neighbourhood_benchmarks n
        on l.neighbourhood = n.neighbourhood
    where l.price_usd > 0
)

select * from final