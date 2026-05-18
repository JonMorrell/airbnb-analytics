with hosts as (
    select * from {{ ref('int_host_summary') }}
),

final as (
    select
        host_id,
        host_name,
        host_since,
        is_superhost,
        is_identity_verified,

        -- portfolio
        total_listings,
        neighbourhoods_count,
        room_types_count,

        -- revenue
        total_estimated_revenue,
        avg_revenue_per_listing,

        -- ranking
        rank() over (order by total_estimated_revenue desc)     as revenue_rank,
        rank() over (order by total_listings desc)              as portfolio_size_rank,
        rank() over (order by avg_review_score desc)            as review_rank,

        -- review scores
        avg_review_score,
        avg_cleanliness_score,
        avg_location_score,
        avg_value_score,
        total_reviews,

        -- pricing
        avg_listing_price,
        min_listing_price,
        max_listing_price,

        -- superhost comparison label
        case
            when is_superhost = 'True' then 'Superhost'
            else 'Standard Host'
        end                                                     as host_tier

    from hosts
)

select * from final