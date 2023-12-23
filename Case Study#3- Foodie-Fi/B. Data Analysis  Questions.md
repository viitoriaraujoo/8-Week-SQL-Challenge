# <p align="center" style="margin-top: 0px;"> 🥑 Case Study #3 - Foodie-Fi 🥑
## <p align="center"> B. Data Analysis  Questions

**1- Quantos clientes o Foodie-Fi já teve?**
```sql
SELECT COUNT (DISTINCT customer_id) AS total_clientes

FROM subscriptions
```
<p align="center" style="margin-top: 0px;"> <p align="center" style="margin-top: 0px;"> <img src="https://miro.medium.com/v2/resize:fit:640/format:webp/1*X3AQW51vgWQJ92oKdktFRw.png">

**2- Qual é a distribuição mensal dos valores destart_date para o plano trial em nosso conjunto de dados?**
```sql
SELECT EXTRACT (MONTH FROM start_date) AS months,
	COUNT(s.plan_id) AS total_plans
FROM subscriptions AS s
INNER JOIN plans AS p
ON s.plan_id = p.plan_id
WHERE plan_name = 'trial'
GROUP BY months
ORDER BY COUNT(s.plan_id) DESC
```
<p align="center" style="margin-top: 0px;"> <p align="center" style="margin-top: 0px;"> <img src="https://miro.medium.com/v2/resize:fit:1100/format:webp/1*5fN_S8-zEC5_ZjFA9785ew.png">

**3-Quais valores de start_date do plano ocorrem após o ano de 2020 em nosso conjunto de dados? Mostre a distribuição por contagem de eventos para cada plan_name.**
```sql
SELECT p.plan_name, 
       p.plan_id,
       COUNT(*) AS inscritos_2021
FROM plans AS p
INNER JOIN  subscriptions AS s
ON p.plan_id = s.plan_id
WHERE s.start_date >= '2021-01-01'
GROUP BY p.plan_id, p.plan_name
ORDER BY p.plan_id;
```
<p align="center" style="margin-top: 0px;"> <p align="center" style="margin-top: 0px;"> <img src="https://miro.medium.com/v2/resize:fit:1100/format:webp/1*VQp6oyRRNaedhRJWqnBudg.png">

**4-Qual é a contagem de customer e a porcentagem de customerque abandonaram, arredondada para 1 casa decimal?**
```sql
SELECT 
  COUNT(CASE WHEN plan_id = 4 THEN customer_id END) AS customers_churned,
  ROUND((COUNT(CASE WHEN plan_id = 4 THEN customer_id END)::numeric / COUNT(DISTINCT customer_id) * 100.0), 1) AS churn_percentage
FROM subscriptions;
```
<p align="center" style="margin-top: 0px;"> <p align="center" style="margin-top: 0px;"> <img src="https://miro.medium.com/v2/resize:fit:1100/format:webp/1*S41betpJTFiCSgr3lG8KqQ.png">

**5-Quantos clientes cancelaram logo após o período de teste gratuito inicial - qual é a porcentagem disso arredondada para o número inteiro mais próximo?**
```sql
WITH cte_churn AS 			
(
SELECT *, 
        LAG(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY plan_id) AS lead_plan   --Esta coluna é preenchida com o tipo de plano da linha anterior para o mesmo cliente. 
FROM subscriptions
)

SELECT COUNT(lead_plan) AS churn_count, 
       ROUND(COUNT(*) * 100 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 0) AS percentage_churn
FROM cte_churn
WHERE plan_id = 4 and lead_plan = 0;
```
<p align="center" style="margin-top: 0px;"> <p align="center" style="margin-top: 0px;"> <img src="https://miro.medium.com/v2/resize:fit:1100/format:webp/1*QTOOT5bBdxPVB7siVKwUbA.png">

**6-Qual é o número e a porcentagem de planos de clientes após o período inicial de teste gratuito?**
```sql
WITH cte_next_plan AS ---tabela temporária com informações sobre o próximo plano de cada cliente
(
	SELECT *,
	       LEAD(plan_id, 1) OVER (PARTITION BY customer_id ORDER BY plan_id) AS next_plan
	FROM subscriptions
),

planning AS ----- crição tabela temporária 
	(
	SELECT z.next_plan,
	       COUNT(DISTINCT customer_id) AS customer_count, 
	       (100 * CAST(COUNT(DISTINCT customer_id) AS FLOAT) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions)) AS percentage 
	FROM cte_next_plan z
	LEFT JOIN plans p 
	ON p.plan_id = z.next_plan
	WHERE z.plan_id = 0 
	      AND z.next_plan is not null
	GROUP BY z.next_plan
	)

SELECT
	p.plan_name, 
	s.customer_count, 
	s.percentage
FROM planning s
LEFT JOIN plans p 
ON p.plan_id = s.next_plan;
```

<p align="center" style="margin-top: 0px;"> <p align="center" style="margin-top: 0px;"> <img src="https://miro.medium.com/v2/resize:fit:1100/format:webp/1*Vjd6GHIXeqwKnXjoSwqi5g.png">

**7- Qual é a contagem de customer e a distribuição percentual de todos os valores de plan_name em 31 de dezembro de 2020?**
```sql
WITH cte_next_date AS (
    SELECT *,
        LEAD(start_date, 1) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_date
    FROM subscriptions
    WHERE start_date <= '2020-12-31'
),
plans_breakdown AS (
    SELECT plan_id,
        COUNT(DISTINCT customer_id)::FLOAT AS total,
        (SELECT COUNT(DISTINCT customer_id)::FLOAT FROM subscriptions) AS total_all
    FROM cte_next_date c
    WHERE next_date IS NULL
    GROUP BY plan_id
)

SELECT
    p.plan_name, 
    pb.total, 
    ROUND((pb.total / pb.total_all * 100.0)::NUMERIC, 1) AS percentage
FROM plans_breakdown pb
LEFT JOIN plans p ON p.plan_id = pb.plan_id
ORDER BY pb.plan_id;
```
<p align="center" style="margin-top: 0px;"> <p align="center" style="margin-top: 0px;"> <img src="https://miro.medium.com/v2/resize:fit:1100/format:webp/1*PoYNJpflS1oKWw0-utsTuA.png">

**8- Quantos clientes fizeram upgrade para um plano anual em 2020?**
```sql
SELECT COUNT (DISTINCT customer_id) AS upgrade_customers
FROM subscriptions s
WHERE plan_id = 3 AND start_date <= '2020-12-31'
```
<p align="center" style="margin-top: 0px;"> <p align="center" style="margin-top: 0px;"> <img src="https://miro.medium.com/v2/resize:fit:828/format:webp/1*Z4z5OhcgXkV7yPsX-2Y68A.png">

**9- Quantos dias, em média, um cliente leva para fazer upgrade para um plano anual a partir do dia em que se inscreve no Foodie-Fi?**
```sql
WITH trial_plan AS (
    SELECT customer_id,
           start_date AS trial_date
    FROM subscriptions
    WHERE plan_id = 0 
),
annual_plan AS (
    SELECT customer_id,
           start_date AS annual_date
    FROM subscriptions
    WHERE plan_id = 3
)

SELECT ROUND(AVG(ABS(EXTRACT(EPOCH FROM age(trial_date, annual_date)) / 86400))::NUMERIC, 0) AS avg_days_to_upgrade
FROM trial_plan tp
JOIN annual_plan ap 
ON tp.customer_id = ap.customer_id;
```
<p align="center" style="margin-top: 0px;"> <p align="center" style="margin-top: 0px;"> <img src="https://miro.medium.com/v2/resize:fit:1100/format:webp/1*ovRUD52UeyhIJz5YxAp0Ag.png">

**10- Quantos clientes fizeram downgrade de um plano mensal Pro para um plano mensal Básico em 2020?**
```sql
WITH dowgraded_plan_cte AS
(
SELECT customer_id,
	plan_id,
	start_date,
	LEAD (plan_id) OVER (PARTITION BY customer_id ORDER BY plan_id) AS dowgraded_plan
FROM subscriptions
)

SELECT COUNT (*) AS downgraded
FROM dowgraded_plan_cte
WHERE start_date <= '2020-12-31'
	AND plan_id = 2 AND dowgraded_plan = 1;
```
<p align="center" style="margin-top: 0px;"> <p align="center" style="margin-top: 0px;"> <img src="https://miro.medium.com/v2/resize:fit:1100/format:webp/1*xlofIxiZLeKvJmypj4Je8g.png">

