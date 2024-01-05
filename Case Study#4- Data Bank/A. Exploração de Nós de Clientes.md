# <p align="center" style="margin-top: 0px;"> 🏦 Case Study #4 - Foodie-Fi 💰
## <p align="center"> A. Exploração de Nós de Clientes

**1. Quantos nós exclusivos (uniques nodes) existem no sistema do Data Bank?** 

Este código SQL conta o número de valores únicos na coluna `node_id` da tabela `customer_nodes` e os renomeia como `unique_nodes`. O resultado mostra que existem 5 nós únicos no sistema do Data Bank.

```sql
SELECT COUNT(DISTINCT node_id) AS unique_nodes 
FROM customer_nodes
```

**Resposta:**

| unique_nodes |
|:------------:|
|       5      |

***

**2. Qual é o número de nós por região?**

Este código SQL conta o número de nós únicos (`unique_nodes`) e o número total de nós (`nodes_regions`) para cada região no sistema do Data Bank. Ele utiliza a tabela `customer_nodes` e a tabela regions com um LEFT JOIN para garantir inclusão de todas as regiões, mesmo aquelas sem nós associados. Os resultados são agrupados por nome da região.

O resultado mostra que, em todas as regiões há 5 nós únicos.

```sql
SELECT regions.region_name, 
  COUNT(DISTINCT customers.node_id) AS node_count
FROM data_bank.regions
JOIN data_bank.customer_nodes AS customers
  ON regions.region_id = customers.region_id
GROUP BY regions.region_name;
```

**Resposta:**

|region_name|unique_nodes|
|:----|:----|
|Africa|5|
|America|5|
|Asia|5|
|Australia|5|
|Europe|5|

***

**3. Quantos clientes são alocados para cada região?**

Este código SQL é utilizado para obter informações sobre a quantidade de clientes em diferentes regiões no sistema do Data Bank. Ele conta quantos clientes distintos existem em cada região, exibindo esses resultados em ordem decrescente, começando pela região com o maior número de clientes.

Para realizar isso, o código utiliza duas tabelas: `customer_nodes` (que contém informações sobre os clientes) e `regions` (que possui dados sobre as diferentes regiões). A instrução LEFT JOIN é empregada para garantir que todas as regiões sejam incluídas, mesmo aquelas que não têm clientes associados.

Os resultados são agrupados pelo nome da região e a contagem de clientes distintos é renomeada como `total_customer`. Essa abordagem proporciona uma visão clara da distribuição geográfica dos clientes, sendo útil para identificar as regiões mais relevantes em termos de quantidade de clientes. 

Os clientes são mais alocados na Australia e o menor alocado na Europa.

```sql
SELECT r.region_name, 
    COUNT(DISTINCT c.customer_id) AS total_customer
FROM customer_nodes c
LEFT JOIN regions r ON c.region_id = r.region_id
GROUP BY r.region_name
ORDER BY total_customer DESC
```

**Resposta:**

|region_name|total_customer|
|:----|:----|
|Australia|110|
|America|105|
|Africa|102|
|Asia|95|
|Europe|88|
***

**4. Em média, quantos dias os clientes são realocados para um nó diferente?**

Este código SQL tem como objetivo calcular a média de dias de realocação para os clientes no sistema do Data Bank, considerando as datas de início e términodas realocações.

A parte do código `EXTRACT(EPOCH FROM (end_date::timestamp - start_date::timestamp))` calcula a diferença de tempo entre as datas de início e término em segundos. Em seguida, a divisão por 86400 é realizada para converter essa diferença de tempo de segundos para dias.

O resultado final, obtido pela função `ROUND(AVG(...))`, fornece a média arredondada de dias de realocação para os clientes. A cláusula `WHERE end_date != '9999-12-31'` é utilizada para excluir casos onde a data de término é '`9999-12-31'`, que é considerada uma data anormal ou indefinida.
Em média, os clientes são realocados para diferentes nós, o que representa um período de 15 dias.

```sql
SELECT 
    ROUND(AVG(EXTRACT(EPOCH FROM (end_date::timestamp - start_date::timestamp)) / 86400)) AS media_dias_realocacao
FROM customer_nodes
WHERE end_date != '9999-12-31';		--the result shows there is an abnormal date which is '9999-12-31' needs to be excluded from the query
```

**Resposta:**

|media_dias_realocacao|
|:----|
|15|
***

**5. Qual é a mediana, o percentil 80 e o percentil 95 para essa mesma métrica de dias de realocação para cada região?**

Este trecho de código SQL analisa a distribuição dos dias de realocação dos clientes em diferentes regiões no sistema do Data Bank. Primeiramente, calcula a diferença em dias entre as datas de início e término das realocações usando a função `EXTRACT(EPOCH FROM ...) / 86400` para converter o resultado de segundos para dias.

Em seguida, para cada região, são determinadas três estatísticas importantes usando a função `PERCENTILE_CONT`:
- **Mediana (`PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY dias_realocacao) AS mediana`):** Representa o valor central dos dias de realocação.
- **Percentil 80 (`PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY dias_realocacao) AS percentil_80`):** Indica o valor abaixo do qual 80% dos dados se encontram.
- **Percentil 95 (`PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY dias_realocacao) AS percentil_95`):** Indica o valor abaixo do qual 95% dos dados se encontram.

A mediana dos dias de realocação é de 15 para todas as regiões, enquanto o percentil 80 está em 23 dias. Notavelmente, o percentil 95 varia entre 23 dias para a maioria das regiões e 24 dias para África e Europa.

```sql
WITH regiao_dias_realocacao AS (
    SELECT 
        r.region_name,
        EXTRACT(EPOCH FROM (c.end_date::timestamp - c.start_date::timestamp)) / 86400 AS dias_realocacao
    FROM customer_nodes c
    LEFT JOIN regions r ON c.region_id = r.region_id
    WHERE c.end_date != '9999-12-31'
)
SELECT 
    region_name,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY dias_realocacao) AS mediana,
    PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY dias_realocacao) AS percentil_80,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY dias_realocacao) AS percentil_95
FROM regiao_dias_realocacao
GROUP BY region_name;
```

**Resposta:**

|region_name|mediana|percentil_80|percentil_95
|:----|:----|:----|:----|
|Africa|15|24|28
|America|15|23|28
|Asia|15|23|28
|Australia|15|23|28
|Europe|15|24|28
***
