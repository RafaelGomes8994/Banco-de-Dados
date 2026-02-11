-- PostgreSQL Script - Conversão do MySQL Workbench
-- Modelo: Steam Database    Versão: 1.0
-- PostgreSQL Forward Engineering

-- -----------------------------------------------------
-- Schema steam
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS steam;
SET search_path TO steam;

-- -----------------------------------------------------
-- Table steam.Carteira
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Carteira (
  id_carteira SERIAL PRIMARY KEY,
  Moeda VARCHAR(16) NOT NULL,
  saldo_atual NUMERIC(10,2) NOT NULL
);

-- -----------------------------------------------------
-- Table steam.Usuario
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Usuario (
  Nome_Completo VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  senha VARCHAR(32) NOT NULL,
  nivel INT NOT NULL,
  id_usuario SERIAL PRIMARY KEY,
  Carteira_id_carteira INT NOT NULL UNIQUE,
  CONSTRAINT fk_Usuario_Carteira
    FOREIGN KEY (Carteira_id_carteira)
    REFERENCES Carteira (id_carteira)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

CREATE INDEX idx_Usuario_Carteira ON Usuario(Carteira_id_carteira);

-- -----------------------------------------------------
-- Table steam.Genero
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Genero (
  id_genero SERIAL PRIMARY KEY,
  nome VARCHAR(255) NOT NULL UNIQUE
);

-- -----------------------------------------------------
-- Table steam.Desenvolvedora
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Desenvolvedora (
  Nome_empresa VARCHAR(255) PRIMARY KEY,
  pais_sede VARCHAR(45) NOT NULL,
  website VARCHAR(100) NULL
);

-- -----------------------------------------------------
-- Table steam.Publicadora
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Publicadora (
  Nome_Publicadora VARCHAR(255) PRIMARY KEY,
  contato VARCHAR(45) NOT NULL
);

-- -----------------------------------------------------
-- Table steam.Produto
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Produto (
  Titulo VARCHAR(100) NOT NULL,
  id_produto SERIAL PRIMARY KEY,
  preco NUMERIC(10,2) NOT NULL,
  Descricao VARCHAR(255) NOT NULL,
  Data_lancamento DATE NOT NULL,
  Publicadora_Nome_Publicadora VARCHAR(255) NOT NULL,
  CONSTRAINT fk_Produto_Publicadora1
    FOREIGN KEY (Publicadora_Nome_Publicadora)
    REFERENCES Publicadora (Nome_Publicadora)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

CREATE INDEX idx_Produto_Publicadora ON Produto(Publicadora_Nome_Publicadora);

-- -----------------------------------------------------
-- Table steam.Jogos
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Jogos (
  Suporte_Controle BOOLEAN NOT NULL,
  Faixa_etaria VARCHAR(45) NOT NULL,
  Produto_id_produto INT PRIMARY KEY,
  idiomas VARCHAR(45)[] NOT NULL,
  Desenvolvedora_Nome_empresa VARCHAR(255) NOT NULL,
  CONSTRAINT fk_Jogos_Produto1
    FOREIGN KEY (Produto_id_produto)
    REFERENCES Produto (id_produto)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Jogos_Desenvolvedora1
    FOREIGN KEY (Desenvolvedora_Nome_empresa)
    REFERENCES Desenvolvedora (Nome_empresa)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

CREATE INDEX idx_Jogos_Desenvolvedora ON Jogos(Desenvolvedora_Nome_empresa);

-- -----------------------------------------------------
-- Table steam.Avaliacao
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Avaliacao (
  voto SMALLINT NULL,
  Texto_analise VARCHAR(255) NULL,
  data_postagem TIMESTAMP NULL,
  Usuario_id_usuario INT NOT NULL,
  Jogos_Produto_id_produto INT NOT NULL,
  PRIMARY KEY (Jogos_Produto_id_produto, Usuario_id_usuario),
  CONSTRAINT fk_Avaliacao_Usuario1
    FOREIGN KEY (Usuario_id_usuario)
    REFERENCES Usuario (id_usuario)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Avaliacao_Jogos1
    FOREIGN KEY (Jogos_Produto_id_produto)
    REFERENCES Jogos (Produto_id_produto)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

CREATE INDEX idx_Avaliacao_Usuario ON Avaliacao(Usuario_id_usuario);
CREATE INDEX idx_Avaliacao_Jogos ON Avaliacao(Jogos_Produto_id_produto);

-- -----------------------------------------------------
-- Table steam.Biblioteca
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Biblioteca (
  tempo_jogado INT NULL,
  status_instalacao BOOLEAN NOT NULL,
  Usuario_id_usuario1 INT NOT NULL,
  Produto_id_produto INT NOT NULL,
  PRIMARY KEY (Usuario_id_usuario1, Produto_id_produto),
  CONSTRAINT fk_Biblioteca_Usuario1
    FOREIGN KEY (Usuario_id_usuario1)
    REFERENCES Usuario (id_usuario)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Biblioteca_Produto1
    FOREIGN KEY (Produto_id_produto)
    REFERENCES Produto (id_produto)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

CREATE INDEX idx_Biblioteca_Usuario ON Biblioteca(Usuario_id_usuario1);
CREATE INDEX idx_Biblioteca_Produto ON Biblioteca(Produto_id_produto);

-- -----------------------------------------------------
-- Table steam.Compra
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Compra (
  id_compra SERIAL PRIMARY KEY,
  status SMALLINT NOT NULL,
  metodo_pagamento VARCHAR(32) NOT NULL,
  valor_pago NUMERIC(10,2) NOT NULL,
  data_compra TIMESTAMP NOT NULL,
  Usuario_id_usuario INT NOT NULL,
  CONSTRAINT fk_Compra_Usuario1
    FOREIGN KEY (Usuario_id_usuario)
    REFERENCES Usuario (id_usuario)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

CREATE INDEX idx_Compra_Usuario ON Compra(Usuario_id_usuario);

-- -----------------------------------------------------
-- Table steam.Nota_Fiscal
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Nota_Fiscal (
  id_nota SERIAL PRIMARY KEY,
  numero_serie INT NOT NULL,
  valor_total NUMERIC(10,2) NOT NULL,
  data_emissao TIMESTAMP NOT NULL,
  Compra_id_compra INT NOT NULL,
  CONSTRAINT fk_Nota_Fiscal_Compra1
    FOREIGN KEY (Compra_id_compra)
    REFERENCES Compra (id_compra)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

CREATE INDEX idx_Nota_Fiscal_Compra ON Nota_Fiscal(Compra_id_compra);

-- -----------------------------------------------------
-- Table steam.Conquista
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Conquista (
  Titulo VARCHAR(100) NOT NULL,
  descricao VARCHAR(45) NOT NULL,
  imagem_icone BYTEA NOT NULL,
  id_conquista SERIAL,
  Jogos_Produto_id_produto INT NOT NULL,
  PRIMARY KEY (id_conquista, Jogos_Produto_id_produto),
  CONSTRAINT fk_Conquista_Jogos1
    FOREIGN KEY (Jogos_Produto_id_produto)
    REFERENCES Jogos (Produto_id_produto)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

CREATE INDEX idx_Conquista_Jogos ON Conquista(Jogos_Produto_id_produto);

-- -----------------------------------------------------
-- Table steam.RequisitoSistema
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS RequisitoSistema (
  CPU VARCHAR(46) NULL,
  sistema_operacional VARCHAR(45) NOT NULL,
  tipo VARCHAR(45) NOT NULL,
  Jogos_Produto_id_produto INT NOT NULL,
  GPU VARCHAR(45) NULL,
  Memoria_ram VARCHAR(45) NULL,
  armazenamento_disco VARCHAR(45) NULL,
  PRIMARY KEY (Jogos_Produto_id_produto, tipo),
  CONSTRAINT fk_RequisitoSistema_Jogos1
    FOREIGN KEY (Jogos_Produto_id_produto)
    REFERENCES Jogos (Produto_id_produto)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

CREATE INDEX idx_RequisitoSistema_Jogos ON RequisitoSistema(Jogos_Produto_id_produto);

-- -----------------------------------------------------
-- Table steam.Software
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Software (
  versao_software VARCHAR(32) NOT NULL,
  tipo_licenca VARCHAR(45) NOT NULL,
  Produto_id_produto INT PRIMARY KEY,
  CONSTRAINT fk_Software_Produto1
    FOREIGN KEY (Produto_id_produto)
    REFERENCES Produto (id_produto)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

CREATE INDEX idx_Software_Produto ON Software(Produto_id_produto);

-- -----------------------------------------------------
-- Table steam.DLC
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS DLC (
  id_jogo_base INT NOT NULL,
  tamanho_download INT NOT NULL,
  Produto_id_produto INT NOT NULL,
  PRIMARY KEY (Produto_id_produto, id_jogo_base),
  CONSTRAINT fk_DLC_Produto1
    FOREIGN KEY (Produto_id_produto)
    REFERENCES Produto (id_produto)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_DLC_Jogos1
    FOREIGN KEY (id_jogo_base)
    REFERENCES Jogos (Produto_id_produto)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

CREATE INDEX idx_DLC_Jogos ON DLC(id_jogo_base);

-- -----------------------------------------------------
-- Table steam.Jogos_has_Genero
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Jogos_has_Genero (
  Jogos_Produto_id_produto INT NOT NULL,
  Genero_id_genero INT NOT NULL,
  PRIMARY KEY (Genero_id_genero, Jogos_Produto_id_produto),
  CONSTRAINT fk_Jogos_has_Genero_Jogos1
    FOREIGN KEY (Jogos_Produto_id_produto)
    REFERENCES Jogos (Produto_id_produto)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Jogos_has_Genero_Genero1
    FOREIGN KEY (Genero_id_genero)
    REFERENCES Genero (id_genero)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

CREATE INDEX idx_Jogos_has_Genero_Genero ON Jogos_has_Genero(Genero_id_genero);
CREATE INDEX idx_Jogos_has_Genero_Jogos ON Jogos_has_Genero(Jogos_Produto_id_produto);

-- -----------------------------------------------------
-- Table steam.Item_compra
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Item_compra (
  Compra_id_compra INT NOT NULL,
  Produto_id_produto INT NOT NULL,
  Quantidade INT NULL,
  valor_unitario_pago NUMERIC(10,2) NULL,
  PRIMARY KEY (Produto_id_produto, Compra_id_compra),
  CONSTRAINT fk_Item_compra_Compra1
    FOREIGN KEY (Compra_id_compra)
    REFERENCES Compra (id_compra)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Item_compra_Produto1
    FOREIGN KEY (Produto_id_produto)
    REFERENCES Produto (id_produto)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

CREATE INDEX idx_Item_compra_Compra ON Item_compra(Compra_id_compra);

-- -----------------------------------------------------
-- Criar usuário professor
-- -----------------------------------------------------
DROP USER IF EXISTS professor;
CREATE USER professor WITH PASSWORD 'professor';
GRANT ALL PRIVILEGES ON SCHEMA steam TO professor;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA steam TO professor;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA steam TO professor;