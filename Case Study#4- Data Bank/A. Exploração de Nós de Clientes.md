# <p align="center" style="margin-top: 0px;"> 🏦 Case Study #4 - Foodie-Fi 💰
## <p align="center"> A. Exploração de Nós de Clientes

*Quantos nós exclusivos (uniques nodes) existem no sistema do Data Bank?* 

Este código SQL conta o número de valores únicos na coluna `node_id` da tabela `customer_nodes` e os renomeia como `unique_nodes`. O resultado mostra que existem 5 nós únicos no sistema do Data Bank.
```sql
SELECT COUNT(DISTINCT node_id) AS unique_nodes 
FROM customer_nodes
```
| unique_nodes |
|:------------:|
|       5      |


*Qual é o número de nós por região?*


Este código SQL conta o número de nós únicos (`unique_nodes`) e o número total de nós (`nodes_regions`) para cada região no sistema do Data Bank. Ele utiliza a tabela `customer_nodes` e a tabela regions com um LEFT JOIN para garantir inclusão de todas as regiões, mesmo aquelas sem nós associados. Os resultados são agrupados por nome da região.

O resultado mostra que, em todas as regiões (Africa, America, Asia, Australia, Europe), há 5 nós únicos.
```sql
SELECT r.region_name, 
	COUNT(DISTINCT c.node_id) AS unique_nodes,
	COUNT (c.node_id) AS nodes_regions 
	FROM customer_nodes c
	LEFT JOIN regions r ON c.region_id = r.region_id
	GROUP BY r.region_name;
```

|region_name|unique_nodes|
|:----|:----|
|Africa|5|
|America|5|
|Asia|5|
|Australia|5|
|Europe|5|

*Quantos clientes são alocados para cada região?*
```sql
SELECT r.region_name, 
    COUNT(DISTINCT c.customer_id) AS total_customer
FROM customer_nodes c
LEFT JOIN regions r ON c.region_id = r.region_id
GROUP BY r.region_name
ORDER BY total_customer DESC
```

*Em média, quantos dias os clientes são realocados para um nó diferente?*

```sql
SELECT 
    ROUND(AVG(EXTRACT(EPOCH FROM (end_date::timestamp - start_date::timestamp)) / 86400)) AS media_dias_realocacao
FROM customer_nodes
WHERE end_date != '9999-12-31';		--the result shows there is an abnormal date which is '9999-12-31' needs to be excluded from the query
```
*Qual é a mediana, o percentil 80 e o percentil 95 para essa mesma métrica de dias de realocação para cada região?*
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
