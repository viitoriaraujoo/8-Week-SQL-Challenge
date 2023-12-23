# <p align="center" style="margin-top: 0px;"> 🥑 Case Study #3 - Foodie-Fi 🥑
## <p align="center"> A. Jornada do Cliente

*Com base nos 8 primeiros clientes de exemplo fornecidos na amostra da tabela de assinaturas, escreva uma breve descrição da jornada de integração de cada cliente.*

```sql
SELECT s.customer_id,
       p.plan_id, 
       p.plan_name, 
       s.start_date
FROM plans AS p
INNER JOIN subscriptions AS s
ON p.plan_id = s.plan_id
WHERE s.customer_id IN (1,2,4,5,6,7,8)-- seleção de apenas 8 clientes

```

<p align="center" style="margin-top: 0px;"> <img src="https://miro.medium.com/v2/resize:fit:640/format:webp/1*dPM5lhKPwO74g7el-9-KLw.png">

A partir dos dados filtrados irei analisar as atividades dos quatro primeiros clientes correspondentes ao customer_id.

- Customer 1 começa com um plano de teste gratuito em 01/08/2020 e quando o teste termina, atualiza para um plano mensal básico em 08/08/2020.

- Customer 2 começa com um plano de teste gratuito em 20/09/2020 e quando o teste termina, atualiza para um plano pro anual em 27/08/2020.

- Customer 4 começa com um plano de teste gratuito em 17/01/2020 e quando o teste termina, atualiza para um plano mensal básico em 24/01/2020. No dia 21/04/2020, o cliente decide encerrar o plano.

- Customer 5 começa com um plano de teste gratuito em 03/08/2020 e quando o teste termina, atualiza para um plano mensal básico em 10/08/2020.
