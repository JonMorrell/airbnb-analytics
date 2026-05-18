with reviews as (
    select * from {{ ref('stg_reviews') }}
),

listings as (
    select
        listing_id,
        neighbourhood,
        room_type,
        price_usd
    from {{ ref('stg_listings') }}
),

monthly_reviews as (
    select
        date_trunc('month', review_date)                        as review_month,
        count(review_id)                                        as total_reviews,
        count(distinct listing_id)                              as active_listings,
        count(distinct reviewer_id)                             as unique_reviewers
    from reviews
    where review_date is not null
    group by date_trunc('month', review_date)
),

neighbourhood_growth as (
    select
        date_trunc('month', r.review_date)                      as review_month,
        l.neighbourhood,
        count(r.review_id)                                      as total_reviews,
        count(distinct r.listing_id)                            as active_listings
    from reviews r
    left join listings l on r.listing_id = l.listing_id
    where r.review_date is not null
        and l.neighbourhood is not null
    group by
        date_trunc('month', r.review_date),
        l.neighbourhood
),

final as (
    select
        m.review_month,
        m.total_reviews,
        m.active_listings,
        m.unique_reviewers,

        -- month over month growth
        lag(m.total_reviews) over (order by m.review_month)    as prev_month_reviews,
        round(
            (m.total_reviews - lag(m.total_reviews) over (order by m.review_month))
            / nullif(lag(m.total_reviews) over (order by m.review_month), 0) * 100
        , 1)                                                    as review_growth_pct,

        -- rolling 3 month average
        round(avg(m.total_reviews) over (
            order by m.review_month
            rows between 2 preceding and current row
        ), 0)                                                   as rolling_3m_avg_reviews

    from monthly_reviews m
)

select * from final
order by review_month