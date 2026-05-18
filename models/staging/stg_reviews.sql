with source as (
    select * from raw.reviews
),

renamed as (
    select
        id              as review_id,
        listing_id,
        date            as review_date,
        reviewer_id,
        reviewer_name,
        comments        as review_text
    from source
)

select * from renamed