# Etapa 4: Dashboard no Power BI

![Protótipo do dashboard](prototipo_dashboard.png)

*Protótipo da página "Visão Executiva", gerado a partir dos mesmos dados do DW.*

## Arquivos desta pasta

| Arquivo | Uso |
|---|---|
| [`GasIntelligence360.pbip`](GasIntelligence360.pbip) | **Projeto do Power BI**: abra este arquivo no Power BI Desktop |
| `GasIntelligence360.SemanticModel/` | Modelo semântico: tabelas, relacionamentos e medidas |
| `GasIntelligence360.Report/` | Relatório com 3 páginas |
| [`medidas.dax`](medidas.dax) | As 23 medidas DAX, para leitura e estudo |
| [`tema_gas360.json`](tema_gas360.json) | Tema de cores do relatório |

O projeto está no formato **Power BI Project (.pbip)**: em vez de um binário `.pbix`, o modelo e o relatório ficam em arquivos de texto, versionáveis no Git.

## Como abrir

1. Baixe ou clone o repositório e abra `GasIntelligence360.pbip` no Power BI Desktop.
   - Se aparecer erro de formato, ative em **Arquivo › Opções › Recursos de visualização › "Salvar projeto do Power BI (.pbip)"** e reinicie o Desktop.
2. Clique em **Atualizar**. Os dados são lidos direto deste repositório no GitHub (parâmetro `UrlBase`).
   - Se pedir credenciais, escolha **Anônimo**.
3. Aplique o tema: **Exibir › Temas › Procurar temas** › `tema_gas360.json`.

> Para usar os CSVs locais em vez do GitHub, altere o parâmetro `UrlBase` em **Transformar dados › Gerenciar parâmetros**.

## Modelo de dados (estrela)

| De (muitos) | Para (um) | Ativa? |
|---|---|---|
| `fato_faturamento[sk_tempo / sk_cidade / sk_cliente / sk_contrato]` | dimensões correspondentes | ✅ |
| `fato_operacao[sk_tempo / sk_cidade]` | `dim_tempo`, `dim_cidade` | ✅ |
| `fato_ocorrencia[sk_tempo / sk_cidade / sk_cliente / sk_contrato]` | dimensões correspondentes | ✅ |
| `dim_contrato[sk_cliente]` | `dim_cliente[sk_cliente]` | ❌ inativa |
| `dim_cliente[sk_cidade]` | `dim_cidade[sk_cidade]` | ❌ inativa |

As duas últimas ficam **inativas** para evitar caminhos ambíguos: as fatos já carregam todas as chaves.
As medidas de tempo (`Faturado Mês Anterior`, `Faturado YTD`) usam a chave `sk_tempo` (AAAAMM), porque o calendário do DW é mensal.

## Páginas do relatório

**1. Visão Executiva**: cartões de Faturado, Recebido, Em Aberto, % Inadimplência, Atraso Médio e % Perda Técnica; Faturado × Recebido por mês; receita por segmento; inadimplência por cidade; ranking de devedores.

**2. Cobrança**: % pago no prazo e com atraso; faturas por situação; atraso por meio de pagamento; em aberto por segmento; matriz de inadimplência cidade × ano.

**3. Operação**: perda técnica por mês e por cidade; custo por m³; ocorrências por tipo × severidade e por status.

Todas as páginas têm segmentações por ano e por segmento ou cidade.
