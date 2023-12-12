--Verifica se o esquema já existe antes de tentar criá-lo
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'dannys_diner') THEN
    CREATE SCHEMA dannys_diner;
  END IF;
END $$;

-- Define o caminho de pesquisa apenas se o esquema existir
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

--Criação da Tabela Sales

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);


--Criação da Tabela Menu

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  
--Criação da Tabela Members

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


--1. Qual é o valor total gasto por cada cliente no restaurante?
SELECT sales.customer_id,
	SUM(menu.price) as total_spend
	FROM dannys_diner.sales as sales
	LEFT JOIN dannys_diner.menu
	ON sales.product_id= menu.product_id
	
	GROUP BY 1
	ORDER BY 1;

--2. Quantos dias cada cliente visitou o restaurante?

SELECT sales.customer_id,
	COUNT(DISTINCT sales.order_date)as days_visit
	FROM dannys_diner.sales as sales
	GROUP BY 1
	ORDER BY 1;
	
--3. Qual foi o primeiro item do menu comprado por cada cliente?

WITH first_item AS (
    SELECT 
        sales.customer_id,
        sales.product_id,
        sales.order_date,
        DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY sales.order_date) RANK
    FROM 
        dannys_diner.sales 
)
SELECT 
    f.customer_id,
    menu.product_name,
    f.order_date
FROM 
    first_item as f
JOIN 
    dannys_diner.menu as menu
ON 
    f.product_id = menu.product_id
WHERE 
    RANK=1
	ORDER BY 1;

--4.Qual é o item mais comprado no menu e quantas vezes foi comprado por todos os clientes?

SELECT 
    menu.product_name,
    COUNT(sales.product_id) as purchase_count
	FROM dannys_diner.menu as menu
JOIN 
    dannys_diner.sales as sales
ON 
    menu.product_id = sales.product_id
GROUP BY 
    menu.product_name
ORDER BY 
    purchase_count DESC
LIMIT 1;

--5. Qual item foi o mais popular para cada cliente?

WITH SUB AS (
    SELECT
        sales.customer_id,
        sales.product_id,
        COUNT(sales.product_id) as qt_purchased,
        DENSE_RANK() OVER (
            PARTITION BY sales.customer_id
            ORDER BY COUNT(sales.product_id) DESC
        ) AS RANK
    FROM dannys_diner.sales as sales
    JOIN dannys_diner.menu as menu
    ON menu.product_id = sales.product_id
    GROUP BY sales.customer_id, sales.product_id
)
SELECT
    customer_id,product_id,qt_purchased
FROM SUB
WHERE RANK = 1
ORDER BY 
    customer_id;


--6. Qual item foi comprado primeiro pelo cliente depois que ele se tornou membro?

WITH orders AS (
    SELECT
        sales.customer_id, 
        sales.order_date,
        menu.product_name,
        ROW_NUMBER() OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date) AS number_row
    FROM dannys_diner.sales as sales
    JOIN dannys_diner.menu as menu
    ON sales.product_id = menu.product_id
    JOIN dannys_diner.members as members
    ON sales.customer_id = members.customer_id AND sales.order_date > members.join_date
)

SELECT
    orders.customer_id, 
    orders.product_name
FROM orders
WHERE 
    number_row = 1;

-- 7. Qual item foi comprado pouco antes de o cliente se tornar um membro?
WITH pre_membership_purchase AS (
    SELECT
        sales.customer_id, 
        sales.order_date,
        sales.product_id
    FROM annys_diner.sales AS sales), pmp2 AS (
    SELECT
        pmp.customer_id,
        pmp.order_date,
        menu.product_name
    FROM  pre_membership_purchase pmp
    JOIN dannys_diner.menu menu
    ON pmp.product_id = menu.product_id
), pmp3 AS (
    SELECT
        pmp2.customer_id,
        MAX(pmp2.order_date) AS max_order_date
    FROM  pmp2
    JOIN dannys_diner.members members
    ON pmp2.customer_id = members.customer_id
    WHERE pmp2.order_date < members.join_date
    GROUP BY pmp2.customer_id
)
SELECT 
    pmp2.customer_id,
    pmp2.order_date,
    pmp2.product_name
FROM  pmp2
JOIN pmp3
ON pmp2.customer_id = pmp3.customer_id AND pmp2.order_date = pmp3.max_order_date;



--8. Qual é o total de itens e valor gasto para cada membro antes de se tornar um membro?
    SELECT
        sales.customer_id,
     	COUNT(sales.product_id) as count_of_items,
		SUM(menu.price) as total_spend
	FROM dannys_diner.sales as sales
		JOIN dannys_diner.members as members
		ON sales.customer_id = members.customer_id
		JOIN dannys_diner.menu as menu
		ON sales.product_id = menu.product_id
	WHERE sales.order_date < members.join_date
	GROUP BY sales.customer_id
	ORDER BY 1;
	
--9. Se cada $1 gasto equivale a 10 pontos e o sushi tem um multiplicador de 2x pontos - quantos pontos teria cada cliente?
WITH sub AS
	(SELECT
	 sales.customer_id,
	 menu.product_name,
	 menu.price,
	 CASE WHEN product_name= 'sushi'
	 	THEN menu.price *2 *10
	 	ELSE menu.price *10
	 	END AS points
	 FROM dannys_diner.sales as sales
	 JOIN dannys_diner.menu as menu
	 USING (product_id)
	 )
SELECT customer_id,
SUM (price) as total_spend,
SUM (points) as total_points
FROM sub
GROUP BY 1
ORDER BY 1;

--10. Na primeira semana após um cliente se juntar ao programa (incluindo a data de adesão), eles ganham 2x pontos em todos os itens, 
--não apenas sushi - quantos pontos os clientes A e B têm no final de janeiro?
WITH sub AS
	(SELECT
	 sales.customer_id,
	 sales.product_id,
	 menu.product_name,
	 sales.order_date,
	 menu.price,
	 members.join_date,
	 DATE (members.join_date + INTERVAL '6 days') as validity_date,
	 DATE ('2021-01-31') as month_end
	 FROM dannys_diner.sales as sales
	 JOIN dannys_diner.menu as menu
	 ON sales.product_id = menu.product_id
	 JOIN dannys_diner.members as members
	 ON sales.customer_id = members.customer_id)
	 
SELECT 
 sub.customer_id,
 SUM(CASE 
     WHEN product_name ='sushi' THEN price * 2 * 10
     WHEN order_date BETWEEN join_date AND validity_date THEN price * 2 * 10
     ELSE price * 10 
     END) as total_points
FROM sub
WHERE order_date >= join_date AND order_date <= month_end
GROUP BY 1;

--BÔNUS
SELECT
	 sales.customer_id,
	 members.join_date,	 
	 sales.order_date,
	 menu.product_name
FROM dannys_diner.sales as sales
	JOIN dannys_diner.menu as menu
	ON sales.product_id = menu.product_id
	JOIN dannys_diner.members as members
	ON sales.customer_id= members.customer_id
	WHERE order_date > join_date
	
ORDER BY 1;