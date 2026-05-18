with source as (
    select * from raw.calendar
),

renamed as (
    select
        listing_id,
        date                as calendar_date,
        available           as is_available,
        cast(replace(replace(price, '$', ''), ',', '') as double) as price_usd,
        minimum_nights,
        maximum_nights
    from source
)

select * from renamed