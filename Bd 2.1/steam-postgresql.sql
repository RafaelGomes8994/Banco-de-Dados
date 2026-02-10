-- =============================================================================
-- PROJETO LOGICO: ECOSSISTEMA STEAM
-- Disciplina: Banco de Dados I
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS steam;
SET search_path TO steam;

-- Limpeza para reinicializacao do ambiente de testes
DROP TABLE IF EXISTS Jogos_has_Genero, DLC, Software, RequisitoSistema, Conquista, 
Nota_Fiscal, Compra, Biblioteca,Biblioteca_has_Produto, Avaliacao, Publicadora, Desenvolvedora, 
Jogos, Produto, Genero, Usuario, Carteira CASCADE;

-- -----------------------------------------------------------------------------
-- NUCLEO: USUARIOS E FINANCEIRO
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS Carteira (
  id_carteira SERIAL PRIMARY KEY,
  Moeda VARCHAR(16) NOT NULL,
  saldo_atual NUMERIC(10, 2) NOT NULL DEFAULT 0.00 
);

CREATE TABLE IF NOT EXISTS Usuario (
  id_usuario SERIAL PRIMARY KEY,
  Nome_Completo VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  senha VARCHAR(32) NOT NULL,
  nivel INT NOT NULL DEFAULT 1,
  id_carteira INT NOT NULL,
  CONSTRAINT fk_Usuario_Carteira FOREIGN KEY (id_carteira)
    REFERENCES Carteira (id_carteira) ON DELETE CASCADE ON UPDATE CASCADE 
);

ALTER TABLE Usuario
  ADD CONSTRAINT uq_Usuario_Carteira UNIQUE (id_carteira);

-- -----------------------------------------------------------------------------
-- CATALOGO E CATEGORIZACAO
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS Genero (
  id_genero SERIAL PRIMARY KEY,
  nome VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS Produto (
  id_produto SERIAL PRIMARY KEY,
  Titulo VARCHAR(100) NOT NULL,
  preco NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
  Descricao TEXT NOT NULL, 
  Data_lancamento DATE NOT NULL,
  Nome_Publicadora VARCHAR(255) NOT NULL
);

-- -----------------------------------------------------------------------------
-- ESPECIALIZACOES (PRODUTO)
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS Jogos (
  id_produto INT PRIMARY KEY,
  Suporte_Controle BOOLEAN NOT NULL DEFAULT FALSE, 
  Faixa_etaria VARCHAR(45) NOT NULL,
  idiomas VARCHAR(45)[] NOT NULL,
  Nome_empresa VARCHAR(255) NOT NULL,
  CONSTRAINT fk_Jogos_Produto FOREIGN KEY (id_produto)
    REFERENCES Produto (id_produto) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_Jogos_Desenvolvedora FOREIGN KEY (Nome_empresa)
    REFERENCES Desenvolvedora (Nome_empresa) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Software (
  id_produto INT PRIMARY KEY,
  versao_software VARCHAR(32) NOT NULL,
  tipo_licenca VARCHAR(45) NOT NULL,
  CONSTRAINT fk_Software_Produto FOREIGN KEY (id_produto)
    REFERENCES Produto (id_produto) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS DLC (
  id_produto INT PRIMARY KEY,
  requer_jogo_base BOOLEAN NOT NULL DEFAULT TRUE,
  tamanho_download VARCHAR(45),
  CONSTRAINT fk_DLC_Produto FOREIGN KEY (id_produto)
    REFERENCES Produto (id_produto) ON DELETE CASCADE ON UPDATE CASCADE
);

-- -----------------------------------------------------------------------------
-- AGENTES DO MERCADO (CHAVES NATURAIS)
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS Desenvolvedora (
  Nome_empresa VARCHAR(255) PRIMARY KEY,
  pais_sede VARCHAR(45) NOT NULL,
  website VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS Publicadora (
  Nome_Publicadora VARCHAR(255) PRIMARY KEY,
  contato VARCHAR(100) NOT NULL
);

ALTER TABLE Produto
  ADD CONSTRAINT fk_Produto_Publicadora FOREIGN KEY (Nome_Publicadora)
    REFERENCES Publicadora (Nome_Publicadora) ON DELETE RESTRICT ON UPDATE CASCADE;

-- -----------------------------------------------------------------------------
-- INTERACAO E AUDITORIA
-- -----------------------------------------------------------------------------

-- PK composta pelas FKs (Identifica a avaliacao unica usuario-jogo)
CREATE TABLE IF NOT EXISTS Avaliacao (
  id_usuario INT NOT NULL,
  id_jogo INT NOT NULL,
  voto SMALLINT CHECK (voto >= 0 AND voto <= 5),   
  Texto_analise TEXT NULL, 
  data_postagem TIMESTAMP NULL, 
  PRIMARY KEY (id_usuario, id_jogo),
  CONSTRAINT fk_Avaliacao_Usuario FOREIGN KEY (id_usuario)
    REFERENCES Usuario (id_usuario) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_Avaliacao_Jogos FOREIGN KEY (id_jogo)
    REFERENCES Jogos (id_produto) ON DELETE CASCADE ON UPDATE CASCADE
);

-- tempo_jogado como INTERVAL para representar duracao
CREATE TABLE IF NOT EXISTS Biblioteca (
  id_usuario INT PRIMARY KEY,
  tempo_jogado INTERVAL NULL, 
  status_instalacao BOOLEAN DEFAULT FALSE,
  CONSTRAINT fk_Biblioteca_Usuario FOREIGN KEY (id_usuario)
    REFERENCES Usuario (id_usuario) ON DELETE CASCADE ON UPDATE CASCADE
);
-- -----------------------------------------------------------------------------
-- RELACIONAMENTO N:M: CONTEÚDO DA BIBLIOTECA
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS Biblioteca_has_Produto (
  id_usuario INT NOT NULL,
  id_produto INT NOT NULL,
  PRIMARY KEY (id_usuario, id_produto), -- Chave composta garante que o jogo não se repita na mesma conta
  CONSTRAINT fk_Biblioteca_Produto_User FOREIGN KEY (id_usuario)
    REFERENCES Biblioteca (id_usuario) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_Biblioteca_Produto_Prod FOREIGN KEY (id_produto)
    REFERENCES Produto (id_produto) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Compra (
  id_compra SERIAL PRIMARY KEY,
  status VARCHAR(20) NOT NULL,
  metodo_pagamento VARCHAR(32) NOT NULL,
  valor_pago NUMERIC(10, 2) NOT NULL,
  data_compra TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  id_produto INT NOT NULL,
  id_usuario INT NOT NULL,
  CONSTRAINT fk_Compra_Produto FOREIGN KEY (id_produto)
    REFERENCES Produto (id_produto) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_Compra_Usuario FOREIGN KEY (id_usuario)
    REFERENCES Usuario (id_usuario) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Nota_Fiscal (
  id_nota SERIAL PRIMARY KEY,
  numero_serie INT NOT NULL,
  valor_total NUMERIC(10, 2) NOT NULL,
  data_emissao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  id_compra INT NOT NULL UNIQUE, 
  CONSTRAINT fk_Nota_Fiscal_Compra FOREIGN KEY (id_compra)
    REFERENCES Compra (id_compra) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE SEQUENCE IF NOT EXISTS nota_fiscal_numero_serie_seq;

ALTER TABLE Nota_Fiscal
  ALTER COLUMN numero_serie SET DEFAULT nextval('nota_fiscal_numero_serie_seq');

-- -----------------------------------------------------------------------------
-- DETALHES TECNICOS E PROGRESSAO
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS Jogos_has_Genero (
  id_jogo INT NOT NULL,
  id_genero INT NOT NULL,
  PRIMARY KEY (id_jogo, id_genero),
  CONSTRAINT fk_Jogos_Genero_Jogo FOREIGN KEY (id_jogo)
    REFERENCES Jogos (id_produto) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_Jogos_Genero_Gen FOREIGN KEY (id_genero)
    REFERENCES Genero (id_genero) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Campos Titulo, descricao e imagem_icone definidos como NOT NULL (NN)
CREATE TABLE IF NOT EXISTS Conquista (
  id_conquista INT NOT NULL,
  id_jogo INT NOT NULL,
  Titulo VARCHAR(100) NOT NULL,
  descricao TEXT NOT NULL,
  imagem_icone BYTEA NOT NULL, 
  PRIMARY KEY (id_conquista, id_jogo), 
  CONSTRAINT fk_Conquista_Jogos FOREIGN KEY (id_jogo)
    REFERENCES Jogos (id_produto) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS RequisitoSistema (
  CPU VARCHAR(100),
  GPU VARCHAR(100),
  Memoria_ram VARCHAR(45),
  armazenamento_disco VARCHAR(45),
  sistema_operacional VARCHAR(45) NOT NULL,
  tipo VARCHAR(45) NOT NULL CHECK (tipo IN ('Minimo', 'Recomendado')),
  id_jogo INT NOT NULL,
  PRIMARY KEY (id_jogo, tipo),
  CONSTRAINT fk_Requisito_Jogos FOREIGN KEY (id_jogo)
    REFERENCES Jogos (id_produto) ON DELETE CASCADE ON UPDATE CASCADE
);

-- -----------------------------------------------------------------------------
-- PERFORMANCE E ACESSO
-- -----------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_usuario_email ON Usuario(email);
CREATE INDEX IF NOT EXISTS idx_compra_data ON Compra(data_compra);

CREATE OR REPLACE FUNCTION cria_biblioteca()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO Biblioteca (id_usuario) VALUES (NEW.id_usuario);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_usuario_biblioteca
AFTER INSERT ON Usuario
FOR EACH ROW EXECUTE FUNCTION cria_biblioteca();

CREATE OR REPLACE FUNCTION cria_nota_fiscal()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO Nota_Fiscal (valor_total, id_compra)
  VALUES (NEW.valor_pago, NEW.id_compra);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_compra_nota
AFTER INSERT ON Compra
FOR EACH ROW EXECUTE FUNCTION cria_nota_fiscal();

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'professor') THEN
    CREATE USER professor WITH PASSWORD 'professor';
  END IF;
END $$;

GRANT USAGE ON SCHEMA steam TO professor;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA steam TO professor;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA steam TO professor;
ALTER USER professor SET search_path TO steam, public;