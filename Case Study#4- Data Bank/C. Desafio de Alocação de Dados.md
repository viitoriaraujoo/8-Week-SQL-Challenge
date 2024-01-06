# <p align="center" style="margin-top: 0px;"> 🏦 Case Study #4 - Foodie-Fi 💰
## <p align="center"> C. Desafio de Alocação de Dados


**Para testar algumas hipóteses diferentes, a equipe do Data Bank deseja realizar um experimento no qual diferentes grupos de clientes teriam dados alocados usando 3 opções diferentes:**

- Opção 1: dados são alocados com base na quantia de dinheiro no final do mês anterior

- Opção 2: dados são alocados com base na quantia média de dinheiro mantida na conta nos últimos 30 dias

- Opção 3: dados são atualizados em tempo real

**Para esta pergunta desafiadora em várias partes, foi solicitado que você gere os seguintes elementos de dados para ajudar a equipe do Data Bank a estimar quanto dados será necessário provisionar para cada opção:**

**1. Uma coluna de saldo do cliente em execução que inclui o impacto de cada transação.**

Este código realiza uma consulta em nossos dados de transações de clientes. Ele mostra informações importantes, como o ID do cliente, a data da transação, o tipo de transação (depósito, retirada ou compra) e o valor da transação.
O destaque aqui é o cálculo do "saldo em execução" . Essa é uma maneira de acompanhar como o saldo da conta de um cliente evolui ao longo do tempo, considerando todas as transações. Por exemplo, se o cliente faz um depósito, o saldo aumenta; se faz uma retirada ou uma compra, o saldo diminui.
  
````sql
  SELECT customer_id,
       txn_date,
       txn_type,
       txn_amount,
       SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount
		WHEN txn_type = 'withdrawal' THEN -txn_amount
		WHEN txn_type = 'purchase' THEN -txn_amount
		ELSE 0
	   END) OVER(PARTITION BY customer_id ORDER BY txn_date) AS running_balance
FROM customer_transactions;
````
***

**2. Saldo do cliente no final de cada mês.**

Este código SQL analisa as transações mensais dos clientes para entender como o saldo de suas contas evolui. Ele fornece o número e o nome do mês, juntamente com o saldo de fechamento mensal. O saldo é calculado considerando depósitos como adições e retiradas/compras como subtrações. A saída é organizada por cliente e mês, proporcionando uma visão clara dos padrões financeiros ao longo do tempo. 

````sql
SELECT 
    customer_id,
    EXTRACT(MONTH FROM DATE_TRUNC('MONTH', txn_date)) AS month_number,
    TO_CHAR(DATE_TRUNC('MONTH', txn_date), 'Month') AS month_name,
    SUM(
        CASE 
            WHEN txn_type = 'deposit' THEN txn_amount
            ELSE -txn_amount 
        END
    ) AS closing_balance
FROM customer_transactions
GROUP BY customer_id, month_number, month_name, DATE_TRUNC('MONTH', txn_date)
ORDER BY customer_id, month_number;
````
***

**3. Valores mínimo, médio e máximo do saldo em execução para cada cliente.**


Este script SQL examina o histórico de transações dos clientes, fornecendo informações essenciais sobre o estado de suas contas. Ao considerar depósitos, retiradas e compras, o código calcula a média, o mínimo e o máximo do saldo acumulado. 

````sql
  WITH running_balance AS
(
	SELECT customer_id,
	       txn_date,
	       txn_type,
	       txn_amount,
	       SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount
			WHEN txn_type = 'withdrawal' THEN -txn_amount
			WHEN txn_type = 'purchase' THEN -txn_amount
			ELSE 0
		    END) OVER(PARTITION BY customer_id ORDER BY txn_date) AS running_balance
	FROM customer_transactions
)

SELECT customer_id,
       ROUND(AVG(running_balance)) AS avg_running_balance,
       MIN(running_balance) AS min_running_balance,
       MAX(running_balance) AS max_running_balance
FROM running_balance
GROUP BY customer_id;
````
***






