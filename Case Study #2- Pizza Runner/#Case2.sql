--Exportação dos dados
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'pizza_runner') THEN
    CREATE SCHEMA pizza_runner;
  END IF;
END $$;

-- Define o caminho de pesquisa apenas se o esquema existir
SET search_path = pizza_runner;

CREATE TABLE pizza_runner.runners (
  runner_id INTEGER,
  registration_date DATE
);
INSERT INTO runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');



DROP TABLE IF EXISTS customer_orders;

CREATE TABLE customer_orders (
  order_id INTEGER,
  customer_id INTEGER,
  pizza_id INTEGER,
  exclusions VARCHAR(4),
  extras VARCHAR(4),
  order_time TIMESTAMP
);

INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');
  
  
  DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" TEXT
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');
  
  
  -- Criar uma tabela temporaria com um nome diferente
SELECT order_id, customer_id, pizza_id, 
       CASE 
          WHEN exclusions IS NULL OR exclusions LIKE 'null' THEN ' '
          ELSE exclusions
       END AS exclusions,
       CASE 
          WHEN extras IS NULL OR extras LIKE 'null' THEN ' '
          ELSE extras 
       END AS extras, 
       order_time
INTO TEMPORARY TABLE temp_customer_orders
FROM customer_orders;

-- Dropa o nome original da tabela
DROP TABLE IF EXISTS customer_orders;

-- Renomear o nome da tabela temporaria
ALTER TABLE temp_customer_orders RENAME TO customer_orders;

select * from runner_orders
-- Limpeza e transformação de dados da tabela runner_orders criando uma tabela temporaria
CREATE TEMP TABLE runner_orders_temp AS
 SELECT 
   order_id, 
   runner_id, 
   CASE
     WHEN pickup_time = 'null' THEN NULL
     ELSE TO_TIMESTAMP(pickup_time, 'YYYY-MM-DD HH24:MI:SS') -- Adapte o formato conforme necessário
   END AS pickup_time,
   CASE
     WHEN distance = 'null' THEN NULL
     WHEN distance LIKE '%km' THEN TRIM('km' from distance)
     ELSE distance 
   END AS distance,
   CASE
     WHEN duration = 'null' THEN NULL
     WHEN duration LIKE '%mins' THEN TRIM('mins' from duration)
     WHEN duration LIKE '%minute' THEN TRIM('minute' from duration)
     WHEN duration LIKE '%minutes' THEN TRIM('minutes' from duration)
     ELSE duration
   END AS duration,
   CASE
     WHEN cancellation IS NULL or cancellation = 'null' THEN ''
     ELSE cancellation
   END AS cancellation
  FROM runner_orders;

DROP TABLE IF EXISTS runner_orders;

ALTER TABLE runner_orders_temp RENAME TO runner_orders;

--Conversão do tipo de dados
ALTER TABLE runner_orders
ALTER COLUMN pickup_time TYPE timestamp USING pickup_time::timestamp without time zone, 
ALTER COLUMN distance TYPE numeric USING distance::numeric,
ALTER COLUMN duration TYPE integer USING duration::integer;



--Quantas pizzas foram pedidas?
SELECT COUNT(pizza_id) AS ordered_pizza 
FROM customer_orders

--Quantos pedidos de clientes únicos foram feitos?
SELECT COUNT(DISTINCT(order_id)) AS unique_customer_orders 
FROM customer_orders;

--Quantos pedidos bem-sucedidos foram entregues por cada corredor?
SELECT runner_id,
	COUNT(runner_id) AS order_count 
FROM runner_orders
	WHERE DISTANCE IS NOT NULL
GROUP BY runner_id
ORDER BY order_count DESC;

--Quantas pizzas de cada tipo foram entregues?
SELECT pizza_name,
COUNT(pizza_id) AS type_count
FROM runner_orders 
JOIN customer_orders 
USING(order_id) 
JOIN pizza_names 
USING(pizza_id)
WHERE IS NOT NULL
GROUP BY pizza_name;

--Quantos Vegetarianos e Meatlovers foram encomendados por cada cliente?
SELECT customer_id, pizza_names.pizza_name, COUNT(customer_orders.pizza_id) AS type_count
FROM customer_orders
JOIN pizza_names ON customer_orders.pizza_id = pizza_names.pizza_id
GROUP BY customer_id, pizza_names.pizza_name
ORDER BY customer_id;

--Qual foi o número máximo de pizzas entregues em um único pedido?
WITH ranking AS (
 SELECT order_id, COUNT(order_id) AS pizza_count,  --A consulta conta o número de pizzas em cada pedido
 RANK() OVER(ORDER BY COUNT(order_id) DESC) --atribui uma classificação a cada linha contagem decrescente de pizzas.
 FROM customer_orders
 JOIN runner_orders --Especificando que os dados devem ser retirados das tabelas. 
 USING (order_id)
 WHERE DISTANCE IS NOT NULL --Filtro para considerar apenas pedidos entregues.
 GROUP BY order_id 
)
SELECT order_id, pizza_count FROM ranking
WHERE rank = 1;   --Seleciona apenas o pedido com maior número de pizza.


-- Criação de uma visualização(delivery_orders)
CREATE VIEW delivered_orders AS
SELECT * FROM customer_orders 
JOIN runner_orders 
USING (order_id)
WHERE distance IS NOT NULL;

--Para cada cliente, quantas pizzas entregues tiveram pelo menos uma alteração e quantas não tiveram nenhuma alteração?
SELECT customer_id, 
	COUNT(
		CASE
			WHEN exclusions <>' ' OR extras <> ' ' THEN 1 
		END 
	) AS changed,
	COUNT(
		CASE
			WHEN exclusions= ' ' AND extras= ' ' THEN 1 
		END
	) AS unchanged
FROM delivered_orders 
GROUP BY customer_id 
ORDER BY customer_id;

--Quantas pizzas foram entregues com exclusões e extras?


--Qual foi o volume total de pizzas encomendadas para cada hora do dia?
SELECT EXTRACT(HOUR FROM order_time) AS hour_of_day, --usada para extrair apenas a informação da hora da coluna 
   count(pizza_id) AS pizza_count
FROM customer_orders
GROUP BY hour_of_day
ORDER BY hour_of_day;

--Qual foi o volume de pedidos para cada dia da semana?
SELECT TO_CHAR(order_time, ‘day’) AS day_of_week,
   COUNT(pizza_id) AS pizza_count
FROM customer_orders
GROUP BY day_of_week
ORDER BY day_of_week;

--Quantos entregadores se cadastraram para cada período de uma semana? (ou seja, a semana começa em 01–01–2021)
SELECT registration_date,
	EXTRACT( WEEK FROM registration_date) AS week_of_year
FROM pizza_runner.runners;

SELECT registration_date,
	EXTRACT( WEEK FROM registration_date + 3 ) AS week_of_year
FROM pizza_runner.runners;

SELECT EXTRACT( WEEK FROM registration_date + 3 ) AS week_of_year
	COUNT(runner_id)
FROM pizza_runner.runners
GROUP BY week_of_year
ORDER BY week_of_year;

--Qual foi o tempo médio, em minutos, que cada entregador levou para chegar à sede da Pizza Runner para retirar o pedido?
WITH order_time_difference AS (
    SELECT DISTINCT order_id, (pickup_time - order_time) AS time_difference 
    FROM delivered_orders
)
SELECT DATE_TRUNC('minute', AVG(time_difference) + INTERVAL '30 second') AS rounded_average
FROM order_time_difference;

--Existe alguma relação entre o número de pizzas e o tempo necessário para preparar o pedido?
WITH orders_group AS (
   SELECT order_id, count(order_id) AS pizza_count, 
      (pickup_time - order_time) AS time_difference
   FROM delivered_orders
   GROUP BY order_id, pickup_time, order_time
   ORDER BY order_id
 )
 SELECT pizza_count, AVG(time_difference) AS avg_time
 FROM orders_group
 GROUP BY pizza_count
 ORDER BY pizza_count;

--Qual foi a distância média percorrida por cada cliente?
SELECT customer_id, ROUND(AVG(distance),2) AS avg_distance
FROM delivered_orders
GROUP BY customer_id
ORDER BY avg_distance DESC;

--Qual foi a diferença entre os tempos de entrega mais longo e mais curto para todos os pedidos?

SELECT MAX(duration) - MIN(duration) AS delivery_time_difference
FROM runner_orders;

--Qual foi a velocidade média para cada entregador em cada entrega, e você percebe alguma tendência para esses valores?
SELECT DISTINCT
	order_id,
	runner_id,
	ROUND(distance / (duration::numeric/60), 2) AS avg_speed
FROM delivered_orders
ORDER BY runner_id, avg_speed

--Qual é a porcentagem de entregas bem-sucedidas para cada entregador?
SELECT runner_id, 
  round(count(distance)::numeric/ count(runner_id) * 100) AS delivery_percentage
FROM runner_orders
GROUP BY runner_id;

--Quais são os ingredientes padrão para cada pizza?

SELECT
  pizza_names.pizza_name,
  STRING_AGG(pizza_toppings.topping_name, ', ') AS ingredientes_padrao
FROM
  pizza_names
JOIN
  pizza_recipes ON pizza_names.pizza_id = pizza_recipes.pizza_id
JOIN
  pizza_toppings ON pizza_toppings.topping_id = ANY(string_to_array(pizza_recipes.toppings, ', ')::int[])
GROUP BY
  pizza_names.pizza_name;


--Qual foi o extra mais comumente adicionado?
SELECT
  pt.topping_name AS extra_mais_comum,
  COUNT(*) AS quantidade
FROM
  customer_orders co
JOIN
  pizza_toppings pt ON pt.topping_id = ANY(string_to_array(co.extras, ', ')::int[])
WHERE
  co.extras IS NOT NULL AND co.extras != 'null' AND co.extras ~ '^[0-9,]+$'
GROUP BY
  pt.topping_name
ORDER BY
  quantidade DESC
LIMIT 1;

--Qual foi a exclusão mais comum?

SELECT
  pt.topping_name AS exclusao_mais_comum,
  COUNT(*) AS quantidade
FROM
  customer_orders co
JOIN
  pizza_toppings pt ON pt.topping_id = ANY(string_to_array(co.exclusions, ', ')::int[])
WHERE
  co.exclusions IS NOT NULL AND co.exclusions != 'null' AND co.exclusions ~ '^[0-9,]+$'
GROUP BY
  pt.topping_name
ORDER BY
  quantidade DESC
LIMIT 1;

-- Qual é a quantidade total de cada ingrediente usado em todas as pizzas entregues, ordenada por mais frequente primeiro?
WITH AllIngredients AS (
  SELECT 
    pt.topping_name,
    COUNT(*) AS ingredient_count
  FROM delivered_orders
  JOIN pizza_names pn ON delivered_orders.pizza_id = pn.pizza_id
  JOIN pizza_recipes pr ON delivered_orders.pizza_id = pr.pizza_id
  JOIN pizza_toppings pt ON pt.topping_id = ANY(string_to_array(pr.toppings, ', ')::int[])
  GROUP BY pt.topping_name
)

SELECT 
  topping_name,
  ingredient_count
FROM AllIngredients
ORDER BY ingredient_count DESC



