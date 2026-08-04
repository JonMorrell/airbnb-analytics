with listings as (
    -- exclude listings with no recorded price (coalesced to 0 in staging) so
    -- hosts whose entire portfolio is unpriced don't dilute revenue/price
    -- aggregates or get ranked alongside hosts with real pricing data
    select * from {{ ref('int_listings_enriched') }}
    where price_usd > 0
),

host_summary as (
    select
        -- host identity
        host_id,
        max(host_name)                                      as host_name,
        max(host_since)                                     as host_since,
        max(host_is_superhost)                              as is_superhost,
        max(host_identity_verified)                         as is_identity_verified,

        -- portfolio size
        count(listing_id)                                   as total_listings,

        -- pricing
        round(avg(price_usd), 2)                            as avg_listing_price,
        min(price_usd)                                      as min_listing_price,
        max(price_usd)                                      as max_listing_price,

        -- review performance
        round(avg(review_scores_rating), 2)                 as avg_review_score,
        round(avg(review_scores_cleanliness), 2)            as avg_cleanliness_score,
        round(avg(review_scores_location), 2)               as avg_location_score,
        round(avg(review_scores_value), 2)                  as avg_value_score,
        sum(total_reviews)                                  as total_reviews,

        -- revenue
        round(sum(estimated_annual_revenue), 2)             as total_estimated_revenue,
        round(avg(estimated_annual_revenue), 2)             as avg_revenue_per_listing,

        -- neighbourhoods they operate in
        count(distinct neighbourhood)                       as neighbourhoods_count,

        -- room types they offer
        count(distinct room_type)                           as room_types_count

    from listings
    group by host_id
)

select * from host_summary