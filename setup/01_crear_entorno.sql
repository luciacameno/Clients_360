-- setup/01_crear_entorno.sql · clients_360

use role sysadmin;

create warehouse if not exists WH_GOLDEN_CLIENTS
  warehouse_size = 'XSMALL'
  auto_suspend = 60
  auto_resume = true;

create database if not exists DEV_BRONZE_DB;
create database if not exists DEV_SILVER_DB;
create database if not exists DEV_GOLD_DB;
create database if not exists PRO_SILVER_DB;
create database if not exists PRO_GOLD_DB;

create schema if not exists DEV_BRONZE_DB.crm;
create schema if not exists DEV_BRONZE_DB.pos;
create schema if not exists DEV_BRONZE_DB.web;
create schema if not exists DEV_BRONZE_DB.catalog;

use role securityadmin;

create role if not exists DEV_TRANSFORM_ROLE;
create role if not exists PRO_TRANSFORM_ROLE;
create role if not exists REPORTING_ROLE;

grant role DEV_TRANSFORM_ROLE to role sysadmin;
grant role PRO_TRANSFORM_ROLE to role sysadmin;
grant role REPORTING_ROLE     to role sysadmin;

grant usage on warehouse WH_GOLDEN_CLIENTS to role DEV_TRANSFORM_ROLE;
grant usage on warehouse WH_GOLDEN_CLIENTS to role PRO_TRANSFORM_ROLE;
grant usage on warehouse WH_GOLDEN_CLIENTS to role REPORTING_ROLE;

grant usage on database DEV_BRONZE_DB to role DEV_TRANSFORM_ROLE;
grant usage on all schemas in database DEV_BRONZE_DB to role DEV_TRANSFORM_ROLE;
grant select on all tables in database DEV_BRONZE_DB to role DEV_TRANSFORM_ROLE;
grant select on future tables in database DEV_BRONZE_DB to role DEV_TRANSFORM_ROLE;

grant usage, create schema on database DEV_SILVER_DB to role DEV_TRANSFORM_ROLE;
grant usage, create schema on database DEV_GOLD_DB   to role DEV_TRANSFORM_ROLE;

grant usage, create schema on database PRO_SILVER_DB to role PRO_TRANSFORM_ROLE;
grant usage, create schema on database PRO_GOLD_DB   to role PRO_TRANSFORM_ROLE;

grant role DEV_TRANSFORM_ROLE to user <lucameno>;
grant role PRO_TRANSFORM_ROLE to user <lucameno>;