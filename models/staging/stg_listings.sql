with source as (
    select * from raw.listings
),

renamed as (
    select
        -- ids
        id                          as listing_id,
        host_id,

        -- listing details
        name                        as listing_name,
        description,
        neighbourhood_cleansed      as neighbourhood,
        latitude,
        longitude,
        property_type,
        room_type,
        accommodates,
        bathrooms_text,
        bedrooms,
        beds,

        -- pricing
        coalesce(cast(replace(replace(price, '$', ''), ',', '') as double), 0) as price_usd,

        -- host details
        host_name,
        host_since,
        host_is_superhost,
        host_total_listings_count,
        host_identity_verified,

        -- review scores
        review_scores_rating,
        review_scores_cleanliness,
        review_scores_location,
        review_scores_value,
        number_of_reviews,

        -- availability
        availability_30,
        availability_60,
        availability_90,
        availability_365,

        -- metadata
        last_scraped

    from source
)

select * from renamed