DROP SCHEMA pizza_runner;

CREATE SCHEMA pizza_runner;
USE pizza_runner;

-- A tabela dos entregadores (runners) exibe a data de registro (registration_date) para cada novo entregador.
DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  runner_id INTEGER,
  registration_date DATE
);
INSERT INTO runners
  (runner_id, registration_date)
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');

-- Os pedidos de pizza dos clientes são registrados na tabela customer_orders, com uma linha para cada pizza individual que faz parte do pedido.
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
  (order_id, customer_id, pizza_id, exclusions, extras, order_time)
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
  
  -- Após cada pedido ser recebido pelo sistema, ele é atribuído a um entregador; no entanto, nem todos os pedidos são totalmente concluídos e podem ser cancelados pelo restaurante ou pelo cliente.
  DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  order_id INTEGER,
  runner_id INTEGER,
  pickup_time VARCHAR(19),
  distance VARCHAR(7),
  duration VARCHAR(10),
  cancellation VARCHAR(23)
);

INSERT INTO runner_orders
  (order_id, runner_id, pickup_time, distance, duration, cancellation)
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

-- O Pizza Runner tem apenas 2 pizzas disponíveis: a Meat Lovers (Amantes de Carne) ou a Vegetariana!
DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  pizza_id INTEGER,
  pizza_name TEXT
);
INSERT INTO pizza_names
  (pizza_id, pizza_name)
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');

-- Cada pizza_id possui um conjunto padrão de ingredientes que são usados como parte da receita da pizza.
DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  pizza_id INTEGER,
  toppings TEXT
);
INSERT INTO pizza_recipes
  (pizza_id, toppings)
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');

-- A tabela contém todos os valores de topping_name com seus respectivos valores de topping_id.
DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  topping_id INTEGER,
  topping_name TEXT
);
INSERT INTO pizza_toppings
  (topping_id, topping_name)
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

