-- Query1 --

select distinct market from gdb023.dim_customer
where customer = 'Atliq Exclusive' and region = 'APAC' ;

-- Query 2 -- 

select 
 SUM(CASE 
		WHEN fiscal_year = 2020 THEN 1 
        ELSE 0 
        END)  as unique_products_2020,
SUM(CASE  
        WHEN fiscal_year = 2021 THEN 1 
        ELSE 0
        END) AS unique_products_2021,
	
round( (SUM(CASE 
		WHEN fiscal_year = 2021 THEN 1 
        ELSE 0 
        END)) /
         (SUM(CASE 
		WHEN fiscal_year = 2020 THEN 1 
        ELSE 0 
        END)-1 ),2
        )* 100 as prc_chng

from 
 (select distinct product_code, fiscal_year from gdb023.fact_sales_monthly) as sub;
 
 -- Query3 --
select segment, count(distinct product) as product_count from gdb023.dim_product
group by segment
order by product_count desc;


-- Query4 --
SELECT * FROM gdb023.dim_product;

With CTE1 as 
(select p.segment as segment, count(distinct p.product_code) as Product_count_2020 
from gdb023.dim_product p join gdb023.fact_sales_monthly s
on p.product_code = s.product_code
where s.fiscal_year = 2020
group by p.segment)
,
CTE2 as 
(select p.segment as segment, count(distinct p.product_code) as Product_count_2021
from gdb023.dim_product p join gdb023.fact_sales_monthly s
on p.product_code = s.product_code
where s.fiscal_year = 2021
group by p.segment)

select CTE1.segment, Product_count_2021, Product_count_2020, (Product_count_2021 - Product_count_2020) as Difference
from CTE1 join CTE2 
ON CTE1.segment = CTE2.segment
ORDER BY difference DESC;

-- Query 5 --

SELECT p.product_code AS product_code, p.product AS product, 
       ROUND(fact_manufacturing_cost.manufacturing_cost,2) AS manufacturing_cost
FROM dim_product p
JOIN fact_manufacturing_cost 
ON p.product_code = fact_manufacturing_cost.product_code
WHERE fact_manufacturing_cost.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost) 
      OR fact_manufacturing_cost.manufacturing_cost =  (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC;

-- Query6 --
select  d.customer_code, c.customer , round(avg(d.pre_invoice_discount_pct),2) as average_discount_percentage
from gdb023.dim_customer c
join gdb023.fact_pre_invoice_deductions d on
c.customer_code = d.customer_code
WHERE c.market = 'India' AND d.fiscal_year = 2021
GROUP BY c.customer, d.customer_code
ORDER BY average_discount_percentage DESC
LIMIT 5;

-- Query7 --

select monthname(s.date) as Month, year(s.date) as Year, 
round(sum(g.gross_price * s.sold_quantity) / 1000000, 2) as gross_sales_amt_mln
from gdb023.fact_sales_monthly s join gdb023.fact_gross_price g 
on s.fiscal_year = g.fiscal_year and s.product_code = g.product_code
join gdb023.dim_customer c on 
c.customer_code = s.customer_code
where c.customer = 'Atliq Exclusive'
group by Month , Year 
order by gross_sales_amt_mln desc;

-- Query8 --

SELECT 
CASE 
  WHEN s.date BETWEEN '2019-09-01' AND '2019-11-01' THEN "Q1"
  WHEN s.date BETWEEN '2019-12-01' AND '2020-02-01' THEN "Q2"
  WHEN s.date BETWEEN '2020-03-01' AND '2020-05-01' THEN "Q3"
  WHEN s.date BETWEEN '2020-06-01' AND '2020-08-01' THEN "Q4"
END AS quarter,
  SUM(s.sold_quantity) AS total_sold_quantity  
FROM fact_sales_monthly s
WHERE s.fiscal_year = '2020'
GROUP BY quarter
ORDER BY quarter;

-- Query9 --

with CTE1 as 
( select c.channel as channel , round(sum(s.sold_quantity * g.gross_price)/1000000,2) as gross_sales_in_million 
from gdb023.dim_customer c join gdb023.fact_sales_monthly s on
c.customer_code = s.customer_code 
join gdb023.fact_gross_price g on 
s.product_code = g.product_code and s.fiscal_year = g.fiscal_year
where s.fiscal_year = '2021'
group by channel
order by gross_sales_in_million),
CTE2 as(
select  round(sum(gross_sales_in_million),2) as total_gross_sales_mln from CTE1)

select CTE1.* , round((gross_sales_in_million *100 / total_gross_sales_mln) ,2 ) as Percentage from CTE1 
join CTE2;



-- Query10 --

With CTE1 as
(select p.product_code , p.division, p.product, 
sum(s.sold_quantity) as total_sold_quantity from gdb023.dim_product p 
join gdb023.fact_sales_monthly s on p.product_code = s.product_code 
where  s.fiscal_year  = 2021
group by p.product_code, p.division, p.product
order by total_sold_quantity desc )
, 
CTE2 as 
(select *, DENSE_RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
		 FROM CTE1)
select * from CTE2 
where rank_order <= 3;





