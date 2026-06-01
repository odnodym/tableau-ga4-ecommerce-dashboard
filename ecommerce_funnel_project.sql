with sessions_info as (

select
    user_pseudo_id,

    concat(
        user_pseudo_id,
        (
            select value.int_value
            from unnest(event_params)
            where key = 'ga_session_id'
        )
    ) as user_session_id,

    regexp_extract(
        (
            select value.string_value
            from unnest(event_params)
            where key = 'page_location'
        ),
        r'(?:https:\/\/shop\.googlemerchandisestore\.com)?(\/.*)'
    ) as landing_page_location,

    traffic_source.source as source,
    traffic_source.medium as medium,
    traffic_source.name as campaign,

    device.category as device_category,
    device.language as device_language,
    device.operating_system as operating_system,

    geo.country as country,

    timestamp_micros(event_timestamp) as session_start_time

from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

where event_name = 'session_start'

),

events as (

select

    concat(
        user_pseudo_id,
        (
            select value.int_value
            from unnest(event_params)
            where key = 'ga_session_id'
        )
    ) as user_session_id,

    timestamp_micros(event_timestamp) as event_timestamp,

    event_name,

    ecommerce.purchase_revenue as purchase_revenue

from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

where event_name in (
    'session_start',
    'view_item',
    'add_to_cart',
    'begin_checkout',
    'add_shipping_info',
    'add_payment_info',
    'purchase'
)

)

select

    s.user_pseudo_id,
    s.user_session_id,

    s.session_start_time,
    date(s.session_start_time) as session_date,

    s.landing_page_location,

    s.source,
    s.medium,
    s.campaign,

    s.device_category,
    s.device_language,
    s.operating_system,

    s.country,

    e.event_timestamp,
    e.event_name,

    e.purchase_revenue

from sessions_info s

left join events e
on s.user_session_id = e.user_session_id