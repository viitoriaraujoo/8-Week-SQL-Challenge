# <p align="center" style="margin-top: 0px;"> 🏦 Case Study #4 - Foodie-Fi 💰
## <p align="center"> B. Transações de Clientes

**1. Qual é a contagem única e o valor total para cada tipo de transação?**

O script examina os registros de transações dos clientes, identificando o tipo de transação, contando o número total de ocorrências distintas para cada tipo, e somando o valor total das transações. 

Os depósitos contaram com 2671 transações, totalizando cerca de $1,35 milhão. Enquanto isso, o número de transações de Compra e Saque é inferior a 2000, com um montante total inferior a $1 milhão.

```sql
SELECT
	txn_type,
	COUNT(*)  AS contagem_unica,
	SUM(txn_amount) AS custo_total
FROM customer_transactions
GROUP BY txn_type
ORDER BY txn_type
```

**Resposta:**
|txn_type|transaction_count|total_amount|
|:----|:----|:----|
|deposit|2671|1359168|
|purchase|1617|806537|
|withdrawal|1580|793003|

***

**2. Qual é a média do total histórico de contagens e valores de depósitos para todos os clientes?**

Essa análise realiza uma análise sobre os depósitos dos clientes. Primeiramente, cria uma tabela temporária chamada `all_customers`, contando o número total de depósitos e somando os valores de depósito para cada cliente. Em seguida, extrai a média arredondada do número e do valor dos depósitos para todos os clientes, focando especificamente em transações do tipo `deposit`.

Em média, há 5 contagens totais históricas de depósitos, totalizando uma média dos depósitos de $2718.

```sql
WITH all_customers AS (
    SELECT 
        customer_id,
        txn_type,
        COUNT(CASE WHEN txn_type = 'deposit' THEN 1 END) AS deposit_count,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount END) AS deposit_amount
    FROM customer_transactions
    GROUP BY customer_id, txn_type
)

SELECT 
    txn_type,
    ROUND(AVG(deposit_count)) AS avg_deposit_count,
    ROUND(AVG(deposit_amount)) AS avg_deposit_amount
FROM all_customers
WHERE txn_type = 'deposit'
GROUP BY txn_type;
```
**Resposta:**
|txn_type|avg_deposit_count|avg_deposit_amount|
|:----|:----|:----|
|deposit|5|2718

***

**3. Para cada mês, quantos clientes do Data Bank realizam mais de 1 depósito e, simultaneamente, 1 compra ou 1 saque em um único mês?**

Ao explorar os dados de transações dos clientes, nosso objetivo é compreender o comportamento mensal na plataforma. Utilizando o conjunto de instruções SQL abaixo, inicialmente, criamos uma tabela temporária chamada `customer_activity`, detalhando o número de depósitos, compras e saques realizados por cada cliente em cada mês.

A análise principal busca extrair insights sobre o número de clientes ativos em cada mês, considerando como ativos aqueles que efetuaram mais de um depósito e, simultaneamente, pelo menos uma compra ou saque.

Durante o primeiro trimestre do ano, muitos clientes realizaram mais de um depósito e, pelo menos, uma compra ou saque. No entanto, em abril, houve uma diminuição drástica, apenas 70 clientes.

```sql
WITH customer_activity AS
(
    SELECT 
        customer_id,
        EXTRACT(MONTH FROM txn_date) AS month_number,
        TO_CHAR(txn_date, 'Month') AS month_name,
        COUNT(CASE WHEN txn_type = 'deposit' THEN 1 END) AS deposit_count,
        COUNT(CASE WHEN txn_type = 'purchase' THEN 1 END) AS purchase_count,
        COUNT(CASE WHEN txn_type = 'withdrawal' THEN 1 END) AS withdrawal_count
    FROM customer_transactions
    GROUP BY customer_id, month_number, month_name
)
SELECT 
	month_number,
    month_name,
    COUNT(DISTINCT customer_id) AS active_customer_count
FROM customer_activity
WHERE deposit_count > 1
    AND (purchase_count > 0 OR withdrawal_count > 0)
GROUP BY month_number, month_name
ORDER BY month_number ASC;
```

**Resposta:**
|month_number|month_name|active_customer_count|
|:----|:----|:----|
|1|January|168
|2|February|181
|3|March|192
|4|April|70

***

**4. Qual é o saldo final para cada cliente no final do mês?**

Nessa análise mais minuciosa, nosso foco foi compreender detalhadamente o comportamento financeiro mensal de cada cliente. Inicialmente, criamos uma tabela temporária denominada `cte`, onde organizamos os dados por cliente e pelo início de cada mês. Durante esse processo, realizamos cálculos considerando soma em caso de  depósitos, caso contrário, o valor era subtraído do saldo.

Dado o extenso tamanho da query, apenas uma parte foi representada.

```sql
WITH cte AS
(
    SELECT 
        customer_id,
        DATE_TRUNC('MONTH', txn_date) AS month_start,
        SUM(CASE 
            WHEN txn_type = 'deposit' THEN txn_amount
            ELSE -txn_amount 
        END) AS total_amount
    FROM customer_transactions
    GROUP BY customer_id, DATE_TRUNC('MONTH', txn_date)
)

SELECT 
    cte.customer_id,
    EXTRACT(MONTH FROM cte.month_start) AS month,
    TO_CHAR(cte.month_start, 'Month') AS month_name,
    SUM(cte.total_amount) OVER (PARTITION BY cte.customer_id ORDER BY cte.month_start) AS closing_balance
FROM cte;
```
**Resposta:**
|customer_id|month|month_name|closing_balance|
|:----|:----|:----|:----|
|1|1|January|312
|1|3|March|-640
|2|1|January|549
|2|3|March|610
|3|1|January|144
|3|2|February|-821
|3|3|March|-1222
|3|4|April|-729
|4|1|January|848
***

