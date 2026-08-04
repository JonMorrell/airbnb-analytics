with listings as (
    select * from {{ ref('stg_listings') }}
),

reviews as (
    select
        listing_id,
        count(*)                                    as total_reviews,
        min(review_date)                            as first_review_date,
        max(review_date)                            as last_review_date,
        datediff('day', min(review_date), 
                        max(review_date))           as review_span_days
    from {{ ref('stg_reviews') }}
    group by listing_id
),

enriched as (
    select
        l.*,

        -- review activity
        coalesce(r.total_reviews, 0)                as total_reviews,
        r.first_review_date,
        r.last_review_date,
        r.review_span_days,

        -- derived metrics
        case
            when r.review_span_days > 0
            then round(r.total_reviews / (r.review_span_days / 30.0), 2)
            else 0
        end                                         as reviews_per_month,

        -- estimated revenue proxy
        round(l.price_usd * (365 - l.availability_365), 2) as estimated_annual_revenue,

        -- host tenure in days (time between host's join date and this scrape)
        datediff('day',
            cast(l.host_since as date),
            cast(l.last_scraped as date))           as host_tenure_days

    from listings l
    left join reviews r on l.listing_id = r.listing_id
)

select * from enriched