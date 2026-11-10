# Dicionário de dados (Data Warehouse)

## Dimensões

| Tabela | Coluna | Descrição |
|---|---|---|
| dim_tempo | sk_tempo | Chave no formato AAAAMM |
| dim_tempo | competencia / data_inicio_mes | Mês de referência (`2024-01` / `2024-01-01`) |
| dim_tempo | ano, mes, nome_mes, trimestre | Atributos de calendário |
| dim_cidade | sk_cidade, cidade | Cidade de atendimento (-1 = Desconhecida) |
| dim_cliente | sk_cliente | Chave substituta (-1 = Cliente desconhecido) |
| dim_cliente | segmento | Residencial, Comercial ou Industrial |
| dim_cliente | segmento_inferido | 1 se o segmento foi deduzido pela tarifa |
| dim_cliente | status_cliente, data_cadastro | Situação e data de cadastro |
| dim_contrato | plano | Convencional ou Flexível |
| dim_contrato | status_contrato, data_inicio | Situação e início do contrato |
| dim_contrato | cliente_orfao | 1 se o cliente não existe no cadastro |

## Fatos

| Tabela | Coluna | Descrição |
|---|---|---|
| fato_faturamento | volume_m3 | Volume lido no mês (nulo se a leitura foi invalidada) |
| fato_faturamento | status_leitura | Válida, Ausente ou Negativa (invalidada) |
| fato_faturamento | tarifa_brl_m3 | Tarifa do segmento (R$/m³) |
| fato_faturamento | valor_fatura_brl | Valor faturado |
| fato_faturamento | status_fatura | Original, Recalculada ou Zerada (leitura inválida) |
| fato_faturamento | valor_pago_brl | Valor recebido (0 se não pago) |
| fato_faturamento | dias_atraso | Data de pagamento − vencimento (negativo = antecipado) |
| fato_faturamento | status_pagamento | Pago no prazo, Pago com atraso, Pago parcial, Em aberto, Sem cobrança |
| fato_operacao | volume_distribuido_m3 / volume_medido_m3 | Gás injetado na rede × gás medido nos clientes |
| fato_operacao | perda_m3 | Diferença entre distribuído e medido |
| fato_operacao | custo_operacional_brl | Custo da operação no mês |
| fato_ocorrencia | tipo_ocorrencia, severidade, status_ocorrencia | Chamados técnicos |
