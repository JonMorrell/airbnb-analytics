{% snapshot listings_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='listing_id',
        strategy='check',
        check_cols=['price_usd', 'room_type', 'bedrooms', 'beds', 'accommodates'],
    )
}}

select
    listing_id,
    host_id,
    listing_name,
    neighbourhood,
    room_type,
    bedrooms,
    beds,
    accommodates,
    price_usd
from {{ ref('stg_listings') }}

{% endsnapshot %}