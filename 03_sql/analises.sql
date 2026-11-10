-- =====================================================================
-- Gas Intelligence 360° · Análises de negócio em SQL
-- Banco: data/dw/gas_dw.db (SQLite)
-- Cada bloco começa com "-- @nome:" para poder ser executado pelo notebook.
-- =====================================================================

-- @01_kpis_gerais: Visão geral do negócio (2024-01 a 2026-10)
SELECT
    COUNT(DISTINCT f.sk_contrato)                                   AS contratos,
    ROUND(SUM(f.volume_m3), 0)                                      AS volume_m3,
    ROUND(SUM(f.valor_fatura_brl), 2)                               AS faturado_brl,
    ROUND(SUM(f.valor_pago_brl), 2)                                 AS recebido_brl,
    ROUND(SUM(f.valor_fatura_brl) - SUM(f.valor_pago_brl), 2)       AS em_aberto_brl,
    ROUND(100.0 * (SUM(f.valor_fatura_brl) - SUM(f.valor_pago_brl))
          / SUM(f.valor_fatura_brl), 2)                             AS inadimplencia_pct,
    ROUND(AVG(CASE WHEN f.dias_atraso IS NOT NULL THEN f.dias_atraso END), 1) AS atraso_medio_dias
FROM fato_faturamento f;

-- @02_evolucao_mensal: Faturamento x recebimento por mês, com variação mensal (LAG) e acumulado
WITH mensal AS (
    SELECT t.competencia,
           SUM(f.valor_fatura_brl) AS faturado,
           SUM(f.valor_pago_brl)   AS recebido
    FROM fato_faturamento f
    JOIN dim_tempo t USING (sk_tempo)
    GROUP BY t.competencia
)
SELECT competencia,
       ROUND(faturado, 2)                                                  AS faturado_brl,
       ROUND(recebido, 2)                                                  AS recebido_brl,
       ROUND(100.0 * recebido / faturado, 1)                               AS taxa_recebimento_pct,
       ROUND(100.0 * (faturado / LAG(faturado) OVER (ORDER BY competencia) - 1), 1) AS var_faturado_mom_pct,
       ROUND(SUM(faturado) OVER (ORDER BY competencia), 2)                 AS faturado_acumulado_brl
FROM mensal
ORDER BY competencia;

-- @03_receita_por_segmento: Participação de cada segmento na receita e no volume
SELECT c.segmento,
       COUNT(DISTINCT f.sk_contrato)                                         AS contratos,
       ROUND(SUM(f.volume_m3), 0)                                            AS volume_m3,
       ROUND(SUM(f.valor_fatura_brl), 2)                                     AS faturado_brl,
       ROUND(100.0 * SUM(f.valor_fatura_brl) / SUM(SUM(f.valor_fatura_brl)) OVER (), 1) AS participacao_receita_pct,
       ROUND(SUM(f.valor_fatura_brl) / COUNT(DISTINCT f.sk_contrato) / COUNT(DISTINCT f.sk_tempo), 2) AS ticket_medio_mensal_brl
FROM fato_faturamento f
JOIN dim_cliente c USING (sk_cliente)
GROUP BY c.segmento
ORDER BY faturado_brl DESC;

-- @04_inadimplencia_por_cidade: Valor em aberto e % de inadimplência por cidade
SELECT ci.cidade,
       COUNT(*)                                                         AS faturas,
       ROUND(SUM(f.valor_fatura_brl), 2)                                AS faturado_brl,
       ROUND(SUM(f.valor_fatura_brl - f.valor_pago_brl), 2)             AS em_aberto_brl,
       ROUND(100.0 * SUM(f.valor_fatura_brl - f.valor_pago_brl) / SUM(f.valor_fatura_brl), 2) AS inadimplencia_pct,
       SUM(f.status_pagamento = 'Em aberto')                            AS faturas_em_aberto
FROM fato_faturamento f
JOIN dim_cidade ci USING (sk_cidade)
GROUP BY ci.cidade
ORDER BY inadimplencia_pct DESC;

-- @05_status_pagamento: Distribuição das faturas por situação de pagamento
SELECT status_pagamento,
       COUNT(*)                                             AS faturas,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)   AS pct_faturas,
       ROUND(SUM(valor_fatura_brl), 2)                      AS faturado_brl
FROM fato_faturamento
GROUP BY status_pagamento
ORDER BY faturas DESC;

-- @06_atraso_por_meio_pagamento: Pix x Boleto: atraso médio e % pago no prazo
SELECT meio_pagamento,
       COUNT(*)                                                              AS pagamentos,
       ROUND(AVG(dias_atraso), 1)                                            AS atraso_medio_dias,
       ROUND(100.0 * SUM(dias_atraso <= 0) / COUNT(*), 1)                    AS pago_no_prazo_pct,
       ROUND(100.0 * SUM(status_pagamento = 'Pago parcial') / COUNT(*), 1)   AS pago_parcial_pct
FROM fato_faturamento
WHERE meio_pagamento IS NOT NULL
GROUP BY meio_pagamento;

-- @07_top10_devedores: Ranking dos 10 clientes com maior saldo em aberto
WITH saldo AS (
    SELECT c.cliente_id, c.segmento, ci.cidade,
           SUM(f.valor_fatura_brl - f.valor_pago_brl) AS em_aberto,
           SUM(f.status_pagamento IN ('Em aberto', 'Pago parcial')) AS faturas_pendentes
    FROM fato_faturamento f
    JOIN dim_cliente c USING (sk_cliente)
    JOIN dim_cidade ci ON ci.sk_cidade = f.sk_cidade
    GROUP BY c.cliente_id, c.segmento, ci.cidade
)
SELECT RANK() OVER (ORDER BY em_aberto DESC) AS posicao,
       cliente_id, segmento, cidade,
       ROUND(em_aberto, 2) AS em_aberto_brl,
       faturas_pendentes
FROM saldo
ORDER BY em_aberto DESC
LIMIT 10;

-- @08_curva_abc_clientes: Curva ABC (Pareto) de clientes por receita
WITH receita AS (
    SELECT sk_cliente, SUM(valor_fatura_brl) AS faturado
    FROM fato_faturamento
    GROUP BY sk_cliente
), acumulado AS (
    SELECT sk_cliente, faturado,
           100.0 * SUM(faturado) OVER (ORDER BY faturado DESC ROWS UNBOUNDED PRECEDING)
                 / SUM(faturado) OVER () AS pct_acumulado
    FROM receita
), classificado AS (
    SELECT *, CASE WHEN pct_acumulado <= 80 THEN 'A'
                   WHEN pct_acumulado <= 95 THEN 'B'
                   ELSE 'C' END AS classe
    FROM acumulado
)
SELECT classe,
       COUNT(*)                                            AS clientes,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)  AS pct_clientes,
       ROUND(SUM(faturado), 2)                             AS faturado_brl,
       ROUND(100.0 * SUM(faturado) / SUM(SUM(faturado)) OVER (), 1) AS pct_receita
FROM classificado
GROUP BY classe
ORDER BY classe;

-- @09_perda_tecnica_por_cidade: Gás distribuído que não chegou ao medidor + custo por m³
SELECT ci.cidade,
       ROUND(SUM(o.volume_distribuido_m3), 0)                                  AS distribuido_m3,
       ROUND(SUM(o.volume_medido_m3), 0)                                       AS medido_m3,
       ROUND(100.0 * SUM(o.perda_m3) / SUM(o.volume_distribuido_m3), 2)        AS perda_pct,
       ROUND(SUM(o.custo_operacional_brl) / SUM(o.volume_medido_m3), 2)        AS custo_por_m3_medido_brl
FROM fato_operacao o
JOIN dim_cidade ci USING (sk_cidade)
GROUP BY ci.cidade
ORDER BY perda_pct DESC;

-- @10_perda_por_ano: Tendência da perda técnica ao longo dos anos
SELECT t.ano,
       ROUND(100.0 * SUM(o.perda_m3) / SUM(o.volume_distribuido_m3), 2) AS perda_pct,
       ROUND(SUM(o.custo_operacional_brl), 2)                           AS custo_operacional_brl
FROM fato_operacao o
JOIN dim_tempo t USING (sk_tempo)
GROUP BY t.ano
ORDER BY t.ano;

-- @11_ocorrencias_tipo_severidade: Ocorrências por tipo e severidade, com % ainda abertas
SELECT tipo_ocorrencia,
       COUNT(*)                                                    AS total,
       SUM(severidade = 'Alta')                                    AS alta,
       SUM(severidade = 'Média')                                   AS media,
       SUM(severidade = 'Baixa')                                   AS baixa,
       SUM(status_ocorrencia = 'Aberta')                           AS abertas,
       ROUND(100.0 * SUM(status_ocorrencia = 'Aberta') / COUNT(*), 1) AS abertas_pct
FROM fato_ocorrencia
GROUP BY tipo_ocorrencia
ORDER BY total DESC;

-- @12_qualidade_leitura: Leituras inválidas por tipo de leitura (manual x automática)
SELECT tipo_leitura,
       COUNT(*)                                                         AS leituras,
       SUM(status_leitura <> 'Válida')                                  AS invalidas,
       ROUND(100.0 * SUM(status_leitura <> 'Válida') / COUNT(*), 2)     AS invalidas_pct
FROM fato_faturamento
WHERE tipo_leitura IS NOT NULL
GROUP BY tipo_leitura;
