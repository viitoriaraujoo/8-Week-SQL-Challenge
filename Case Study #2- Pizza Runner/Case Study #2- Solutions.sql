
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



