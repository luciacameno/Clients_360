-- =====================================================================
-- setup/02_cargar_bronze.sql · clients_360
-- Parte A: stage, formatos y tablas de Bronze
-- =====================================================================
use role sysadmin;
use warehouse WH_GOLDEN_CLIENTS;

create or replace file format DEV_BRONZE_DB.public.csv_bronze
  type = csv
  skip_header = 1
  field_optionally_enclosed_by = '"'
  encoding = 'UTF8'
  trim_space = false;          -- los espacios sucios los limpia dbt

create or replace file format DEV_BRONZE_DB.public.json_bronze
  type = json
  strip_outer_array = true;    -- una fila por evento

create stage if not exists DEV_BRONZE_DB.public.carga_bronze;

create or replace table DEV_BRONZE_DB.crm.loyalty (
  crm_id varchar, full_name varchar, email varchar, phone varchar,
  tier varchar, join_date varchar,
  _loaded_at timestamp_ltz default current_timestamp()
);

create or replace table DEV_BRONZE_DB.pos.sales (
  ticket_id varchar, line_number varchar, store_id varchar, sale_date varchar,
  customer_email_input varchar, customer_phone_input varchar, product_id varchar,
  amount varchar, transaction_type varchar, original_ticket_id varchar,
  return_reason varchar,
  _loaded_at timestamp_ltz default current_timestamp()
);

create or replace table DEV_BRONZE_DB.web.events_raw (
  raw variant, _source_file varchar,
  _loaded_at timestamp_ltz default current_timestamp()
);

create or replace table DEV_BRONZE_DB.catalog.products (
  product_id varchar, name varchar, price varchar, category varchar,
  subcategory varchar, brand varchar, product_line varchar, shade varchar,
  size varchar,
  _loaded_at timestamp_ltz default current_timestamp()
);=====================================================================
-- setup/02_cargar_bronze.sql · Parte B: carga desde el stage
-- =====================================================================
use role sysadmin;
use warehouse WH_GOLDEN_CLIENTS;

copy into DEV_BRONZE_DB.crm.loyalty
  (crm_id, full_name, email, phone, tier, join_date)          -- sin _loaded_at
  from @DEV_BRONZE_DB.public.carga_bronze files = ('crm_loyalty_6.csv')
  file_format = (format_name = 'DEV_BRONZE_DB.public.csv_bronze');

copy into DEV_BRONZE_DB.pos.sales
  (ticket_id, line_number, store_id, sale_date, customer_email_input,
   customer_phone_input, product_id, amount, transaction_type,
   original_ticket_id, return_reason)
  from @DEV_BRONZE_DB.public.carga_bronze files = ('pos_sales_6.csv')
  file_format = (format_name = 'DEV_BRONZE_DB.public.csv_bronze');

copy into DEV_BRONZE_DB.web.events_raw (raw, _source_file)
  from (select $1, metadata$filename from @DEV_BRONZE_DB.public.carga_bronze)
  files = ('web_logs_6.json')
  file_format = (format_name = 'DEV_BRONZE_DB.public.json_bronze');

copy into DEV_BRONZE_DB.catalog.products
  (product_id, name, price, category, subcategory, brand, product_line, shade, size)
  from @DEV_BRONZE_DB.public.carga_bronze files = ('dim_products_6.csv')
  file_format = (format_name = 'DEV_BRONZE_DB.public.csv_bronze');