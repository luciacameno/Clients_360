-- =====================================================================
-- setup/03_clonar_bronze.sql · clients_360
-- Bronze de PRO como zero-copy clone de DEV
-- =====================================================================
use role sysadmin;
create or replace database PRO_BRONZE_DB clone DEV_BRONZE_DB;

use role securityadmin;
grant usage on database PRO_BRONZE_DB to role PRO_TRANSFORM_ROLE;
grant usage on all schemas in database PRO_BRONZE_DB to role PRO_TRANSFORM_ROLE;
grant select on all tables in database PRO_BRONZE_DB to role PRO_TRANSFORM_ROLE;


--comprobamos 
show databases like '%_DB';    -- ahora 6: aparece PRO_BRONZE_DB

select count(*) from PRO_BRONZE_DB.web.events_raw;   -- 171.946, igual que DEV