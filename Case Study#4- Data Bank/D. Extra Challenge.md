# <p align="center" style="margin-top: 0px;"> 🏦 Case Study #4 - Foodie-Fi 💰
## <p align="center"> D. Extra Challenge

**O Data Bank deseja tentar outra opção que é um pouco mais difícil de implementar - eles querem calcular o crescimento dos dados usando um cálculo de juros, assim como em uma conta poupança tradicional que você pode ter em um banco.**

**Se a taxa de juros anual for definida em 6% e a equipe do Data Bank deseja recompensar seus clientes aumentando a alocação de dados com base no juro calculado diariamente no final de cada dia, quanto de dados seria necessário para essa opção em uma base mensal?**

**Special notes:**

O Data Bank deseja um cálculo inicial que não permite juros compostos, no entanto, eles também podem estar interessados em um cálculo de juros compostos diários, então você pode tentar realizar essa calculadora se tiver disposição!

**Utilizando uma Expressão Comum de Tabela (CTE), efetuamos cálculos para obter dados de juros diários para cada transação de cada cliente. Eis os passos:**

 * A coluna `total_data` é calculada através da função SUM, somando todos os valores de transação para o cliente até a data da transação.

 * A coluna `month_start_date` é calculada utilizando a função DATE_TRUNC, criando uma nova data que representa o primeiro dia do mês em que a transação ocorreu. Isso é feito extraindo o dia da coluna `txn_date` e definindo o restante do componente de data como o primeiro dia do mês.

 * A coluna `days_in_month` é calculada subtraindo o dia do `txn_date` pelo dia do primeiro dia do mês, obtido através da função EXTRACT e DATE_TRUNC.

 * A coluna `daily_interest_data` é calculada utilizando a fórmula para juros diários compostos: P*(1+r/n)^n*t. Aqui, P é o total de dados utilizados pelo cliente até a data da transação, r é a taxa de juros anual (6% ou 0.06), n é o número de dias em um ano (365), e t é o número de dias entre 1 de janeiro de 1900 e a data da transação.

 * Na consulta principal, a CTE é usada para agrupar os dados de juros diários por ID do cliente e mês. O requisito mensal de dados é então calculado multiplicando os dados de juros diários pelo número de dias no mês (`days_in_month`) e somando os resultados. A coluna resultante `data_required` representa a quantidade estimada de dados que cada cliente precisará para cada mês, com base em juros diários compostos.


```sql
WITH cte AS
(
	SELECT 
		customer_id,
		txn_date,
		SUM(txn_amount) AS total_data,
		DATE_TRUNC('MONTH', txn_date) AS month_start_date,
		(EXTRACT(DAY FROM txn_date)::DECIMAL - EXTRACT(DAY FROM DATE_TRUNC('MONTH', txn_date))::DECIMAL) AS days_in_month,
		ROUND(SUM(txn_amount) * POWER((1 + 0.06/365), (EXTRACT(DAY FROM txn_date)::DECIMAL - EXTRACT(DAY FROM '1900-01-01'::date)::DECIMAL)), 2) AS daily_interest_data
	FROM 
		customer_transactions
	GROUP BY 
		customer_id, txn_date
)

SELECT 
	customer_id,
	DATE_TRUNC('MONTH', month_start_date) AS txn_month,
	ROUND(SUM(daily_interest_data * days_in_month), 2) AS data_required
FROM 
	cte
GROUP BY 
	customer_id, DATE_TRUNC('MONTH', month_start_date)
ORDER BY 
	data_required DESC;
```

A saída revela a estimativa da quantidade de dados necessária para cada cliente mensalmente, considerando uma taxa de juros de 6% ao ano, calculada diariamente. Isso implica que a alocação de dados de cada cliente aumentará progressivamente, assemelhando-se ao crescimento de juros em uma conta poupança.

Essa dinâmica cria uma oportunidade para a equipe do banco de dados incentivar os clientes a realizar mais transações, ampliando assim a alocação de dados ao longo do tempo. Essa funcionalidade pode ser promovida aos clientes como uma maneira de adquirir mais dados simplesmente ao efetuarem transações e manterem suas contas ativas. Além disso, ela pode contribuir para reforçar a fidelidade e a retenção dos clientes, premiando os usuários ativos com uma ampliação na alocação de dados.

***

