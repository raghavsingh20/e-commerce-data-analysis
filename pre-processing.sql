-- Dropping redundant column with no analytical value
alter table amazon drop column `Unnamed: 22`


-- Renaming columns for consistency and easier SQL querying
alter table amazon rename column "Order ID" TO order_id;
alter table amazon rename column "Sales Channel " TO sales_channel;
alter table amazon rename column "ship-service-level" TO ship_service_level;
alter table amazon rename column "Courier Status" TO courier_status;
alter table amazon rename column "Qty" TO quantity;
alter table amazon rename column "ship-city" TO ship_city;
alter table amazon rename column "ship-state" TO ship_state;
alter table amazon rename column "ship-postal-code" TO ship_postal_code;
alter table amazon rename column "ship-country" TO ship_country;
alter table amazon rename column "promotion-ids" TO promotion_ids;
alter table amazon rename column "fulfilled-by" TO fulfilled_by;


-- Checking for duplicate records based on order_id
select * from (
select *, row_number() over (partition by order_id) AS rn
from amazon
)
where rn > 1
order by order_id


-- Standardizing inconsistent entries of ship_state column
update amazon
set ship_state = case
    when lower(ship_state) in ('pb', 'punjab/mohali/zirakpur') then 'punjab'
    when lower(ship_state) in ('rj', 'rajsthan', 'rajshthan') then 'rajasthan'
    when lower(ship_state) = 'orissa' then 'odisha'
    when lower(ship_state) = 'new delhi' then 'delhi'
    when lower(ship_state) = 'pondicherry' then 'puducherry'
    when lower(ship_state) = 'ar' then 'arunachal pradesh'
    when lower(ship_state) = 'nl' then 'nagaland'
    else ship_state
end
