-- =====================================================================
-- Gas Intelligence 360° · Data Warehouse (modelo estrela)
-- Dialeto: SQLite (compatível com a maioria dos bancos com ajustes mínimos)
-- =====================================================================

DROP TABLE IF EXISTS fato_faturamento;
DROP TABLE IF EXISTS fato_operacao;
DROP TABLE IF EXISTS fato_ocorrencia;
DROP TABLE IF EXISTS dim_contrato;
DROP TABLE IF EXISTS dim_cliente;
DROP TABLE IF EXISTS dim_cidade;
DROP TABLE IF EXISTS dim_tempo;

-- ---------------------------------------------------------------------
-- DIMENSÕES
-- ---------------------------------------------------------------------

-- Calendário mensal (grão das competências)
CREATE TABLE dim_tempo (
    sk_tempo        INTEGER PRIMARY KEY,   -- AAAAMM, ex.: 202401
    competencia     TEXT    NOT NULL,      -- '2024-01'
    data_inicio_mes TEXT    NOT NULL,      -- '2024-01-01' (útil no Power BI)
    ano             INTEGER NOT NULL,
    mes             INTEGER NOT NULL,
    nome_mes        TEXT    NOT NULL,
    trimestre       TEXT    NOT NULL       -- '2024-T1'
);

CREATE TABLE dim_cidade (
    sk_cidade INTEGER PRIMARY KEY,         -- -1 = Desconhecida
    cidade    TEXT NOT NULL
);

CREATE TABLE dim_cliente (
    sk_cliente        INTEGER PRIMARY KEY, -- -1 = Cliente desconhecido (chave órfã)
    cliente_id        TEXT NOT NULL,
    nome_ficticio     TEXT,
    sk_cidade         INTEGER NOT NULL REFERENCES dim_cidade(sk_cidade),
    segmento          TEXT,
    data_cadastro     TEXT,
    status_cliente    TEXT,
    segmento_inferido INTEGER DEFAULT 0
);

CREATE TABLE dim_contrato (
    sk_contrato     INTEGER PRIMARY KEY,
    contrato_id     TEXT NOT NULL,
    sk_cliente      INTEGER NOT NULL REFERENCES dim_cliente(sk_cliente),
    plano           TEXT,
    status_contrato TEXT,
    data_inicio     TEXT,
    cliente_orfao   INTEGER DEFAULT 0
);

-- ---------------------------------------------------------------------
-- FATOS
-- ---------------------------------------------------------------------

-- Grão: 1 linha por contrato × competência (leitura + fatura + pagamento)
CREATE TABLE fato_faturamento (
    fatura_id          TEXT PRIMARY KEY,
    sk_contrato        INTEGER NOT NULL REFERENCES dim_contrato(sk_contrato),
    sk_cliente         INTEGER NOT NULL REFERENCES dim_cliente(sk_cliente),
    sk_cidade          INTEGER NOT NULL REFERENCES dim_cidade(sk_cidade),
    sk_tempo           INTEGER NOT NULL REFERENCES dim_tempo(sk_tempo),
    volume_m3          REAL,               -- nulo quando a leitura foi invalidada
    tipo_leitura       TEXT,
    status_leitura     TEXT,
    tarifa_brl_m3      REAL,
    valor_fatura_brl   REAL,
    status_fatura      TEXT,
    data_vencimento    TEXT,
    valor_pago_brl     REAL DEFAULT 0,
    data_pagamento     TEXT,
    meio_pagamento     TEXT,
    dias_atraso        INTEGER,            -- negativo = pago antes do vencimento
    status_pagamento   TEXT                -- Pago no prazo | Pago com atraso | Pago parcial | Em aberto
);

-- Grão: 1 linha por cidade × competência
CREATE TABLE fato_operacao (
    operacao_id           TEXT PRIMARY KEY,
    sk_cidade             INTEGER NOT NULL REFERENCES dim_cidade(sk_cidade),
    sk_tempo              INTEGER NOT NULL REFERENCES dim_tempo(sk_tempo),
    volume_distribuido_m3 REAL,
    volume_medido_m3      REAL,
    perda_m3              REAL,
    custo_operacional_brl REAL
);

-- Grão: 1 linha por ocorrência técnica
CREATE TABLE fato_ocorrencia (
    ocorrencia_id     TEXT PRIMARY KEY,
    sk_contrato       INTEGER NOT NULL REFERENCES dim_contrato(sk_contrato),
    sk_cliente        INTEGER NOT NULL REFERENCES dim_cliente(sk_cliente),
    sk_cidade         INTEGER NOT NULL REFERENCES dim_cidade(sk_cidade),
    sk_tempo          INTEGER NOT NULL REFERENCES dim_tempo(sk_tempo),
    data_ocorrencia   TEXT,
    tipo_ocorrencia   TEXT,
    severidade        TEXT,
    status_ocorrencia TEXT
);

CREATE INDEX ix_fat_tempo    ON fato_faturamento(sk_tempo);
CREATE INDEX ix_fat_contrato ON fato_faturamento(sk_contrato);
CREATE INDEX ix_op_tempo     ON fato_operacao(sk_tempo);
