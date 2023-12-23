# <p align="center" style="margin-top: 0px;">🥑 Case Study #3 - Foodie-Fi 🥑
## <p align="center"> C. Outside the Box Questions

*A equipe da Foodie-Fi solicitou a criação de uma nova tabela de pagamentos para o ano de 2020, considerando os valores pagos por cada cliente na tabela de inscrições, com algumas diretrizes específicas.*

- Pagamentos mensais ocorrem sempre no mesmo dia do mês que a data de início original de qualquer plano mensal pago.
- Upgrades de planos básicos para mensais ou para planos Pro têm o valor atual pago no mês reduzido, iniciando imediatamente.
- Upgrades de planos mensais Pro para anuais são pagos no final do período de faturamento atual e também começam no final do período do mês.
- Uma vez que um cliente cancela (churns), ele não fará mais pagamentos.
 
```sql
REATE TABLE payments_2020 (
    customer_id INT NOT NULL,
    plan_id INT NOT NULL,
    plan_name VARCHAR(50) NOT NULL,
    payment_date DATE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_order INT NOT NULL
);

WITH RECURSIVE join_table AS (
    SELECT 
        s.customer_id,
        s.plan_id,
        p.plan_name,
        s.start_date AS payment_date,
        s.start_date,
        LEAD(s.start_date, 1) OVER(PARTITION BY s.customer_id ORDER BY s.start_date, s.plan_id) AS next_date,
        p.price AS amount
    FROM subscriptions s
    LEFT JOIN plans p ON p.plan_id = s.plan_id
),
new_join AS (
    SELECT 
        customer_id,
        plan_id,
        plan_name,
        payment_date,
        start_date,
        CASE WHEN next_date IS NULL or next_date > '20201231' THEN '20201231' ELSE next_date END AS next_date,
        amount
    FROM join_table
    WHERE plan_name NOT IN ('trial', 'churn')
),
new_join1 AS (
    SELECT 
        customer_id,
        plan_id,
        plan_name,
        payment_date,
        start_date,
        next_date,
        next_date - INTERVAL '1 month' AS next_date1,
        amount
    FROM new_join
),
Date_CTE AS (
    SELECT 
        customer_id,
        plan_id,
        plan_name,
        start_date,
        (SELECT start_date::timestamp FROM new_join1 WHERE customer_id = a.customer_id AND plan_id = a.plan_id ORDER BY start_date LIMIT 1) AS payment_date,
        next_date, 
        next_date1,
        amount
    FROM new_join1 a

    UNION ALL 
    
    SELECT 
        customer_id,
        plan_id,
        plan_name,
        start_date, 
        (payment_date + INTERVAL '1 month')::timestamp AS payment_date,
        next_date, 
        next_date1,
        amount
    FROM Date_CTE b
    WHERE payment_date < next_date1 AND plan_id != 3
)

INSERT INTO payments_2020 (customer_id, plan_id, plan_name, payment_date, amount, payment_order)
SELECT 
    customer_id,
    plan_id,
    plan_name,
    payment_date,
    amount,
    RANK() OVER(PARTITION BY customer_id ORDER BY customer_id, plan_id, payment_date) AS payment_order
FROM Date_CTE
WHERE EXTRACT(YEAR FROM payment_date) = 2020
ORDER BY customer_id, plan_id, payment_date;
```

*O primeiro passo consiste em criar uma tabela chamada payments_2020 por meio do comando CREATE TABLE. Esta tabela armazenará os dados de pagamento referentes ao ano de 2020, apresentando diversas colunas, tais como customer_id, plan_id, plan_name, payment_date, amount e payment_order.*

*Posteriormente à criação da tabela payments_2020, o próximo passo envolve a inserção de dados nela. Tal operação é realizada por meio de uma Expressão Comum de Tabela (CTE) denominada join_table. A CTE é gerada ao unir as tabelas subscriptions e plans, selecionando colunas específicas como customer_id, plan_id, plan_name, payment_date, start_date, next_date e amount.*

*A CTE join_table é, então, empregada para criar outra CTE chamada new_join. Esta CTE filtra planos de teste e cancelamento da CTE join_table por meio da cláusula WHERE.*

*Uma nova CTE denominada new_join1 é gerada a partir de new_join. Esta CTE adiciona uma nova coluna chamada next_date1, que contém a data correspondente a um mês antes da coluna next_date.*

*A CTE Date_CTE é, então, criada por meio de uma função recursiva. Essa CTE gera datas de pagamento para cada combinação de cliente e plano com base em suas datas de início, término e próxima data. A função continua a ser executada recursivamente até que payment_date seja igual ou superior a next_date1.*

*Finalmente, os dados de pagamento são inseridos na tabela payments_2020 através do comando INSERT INTO. Os dados são selecionados da CTE Date_CTE e filtrados para incluir apenas dados referentes ao ano de 2020, utilizando a cláusula WHERE. Em seguida, os dados são ordenados por customer_id, plan_id e payment_date mediante a cláusula ORDER BY.*

*Adicionalmente, uma coluna payment_order é acrescentada à tabela payments_2020 por meio da função RANK() OVER(). Essa coluna atribui uma classificação única a cada pagamento efetuado por um cliente para um plano específico.*

<p align="center" style="margin-top: 0px;"> <img src="https://miro.medium.com/v2/resize:fit:750/format:webp/1*_-rzYR_QDWjtEDvkckDNag.png">









