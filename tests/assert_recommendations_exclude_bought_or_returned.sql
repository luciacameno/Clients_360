-- R8/R10: el top 3 nunca puede incluir un producto que la clienta ya compró o devolvió.
select
    recommendations.customer_key,
    recommendations.product_key,
    recommendations.product_name
from {{ ref('agg_clienteling_recommendations') }} recommendations
inner join {{ ref('fct_sales') }} sales
        on recommendations.customer_key = sales.customer_key
       and recommendations.product_key = sales.product_key