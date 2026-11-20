# Arquitetura de Banco de Dados Relacional (PostgreSQL) & NoSQL — Plataforma de E-Commerce, Faturamento e Emissão de Nota Fiscal

<div align="center">

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-4EA94B?style=for-the-badge&logo=mongodb&logoColor=white)
![AWS RDS](https://img.shields.io/badge/AWS_RDS-527FFF?style=for-the-badge&logo=amazondatabase&logoColor=white)

</div>

Repositório de engenharia e modelagem de dados (Relacional em **PostgreSQL na AWS RDS** e Documental em **MongoDB**) acompanhado de uma aplicação transacional em **Python (`psycopg2`)** para gestão de usuários, carteira financeira, carrinho de compras, faturamento de itens e **emissão/estorno transacional de Nota Fiscal**.

---

## 1. Visão Geral e Regras de Negócio

O projeto modela o núcleo operacional, comercial e financeiro de uma plataforma digital de distribuição de softwares e jogos (inspirada na Steam), cobrindo:

- **Gestão Financeira e Faturamento (`Carteira`, `Compra`, `Item_compra`, `Nota_Fiscal`):**
  - Criação automática de **Carteira Financeira (`steam.Carteira`)** em transação atômica ao cadastrar um novo usuário (`RETURNING id_carteira`).
  - Fechamento de **Carrinho de Compras** com cálculo dinâmico de preços unitários vigentes no banco, geração do pedido (`steam.Compra`), registro individual dos itens faturados (`steam.Item_compra`) e **emissão automática da `steam.Nota_Fiscal`** com número de série, valor consolidado e carimbo de tempo (`NOW()`).
  - **Estorno Transacional Seguro (`delete_compra`):** Cancelamento de venda respeitando a ordem de integridade referencial (`Nota_Fiscal` $\rightarrow$ `Item_compra` $\rightarrow$ `Compra`) protegido por `COMMIT` / `ROLLBACK`.
- **Catálogo e Especialização (Modelo DEER $\rightarrow$ Relacional):**
  - Hierarquia de `Produto` especializada em `Jogos` (com suporte a arrays nativos do PostgreSQL `VARCHAR(45)[]` para idiomas), `DLC` e `Software`, vinculados a `Desenvolvedora`, `Publicadora` e `Genero`.
  - Controle de posse em `Biblioteca`, sistema de `Conquista`, `Avaliacao` e grafo social de `Amizade`.
- **Modelagem Documental Híbrida (NoSQL / MongoDB):**
  - Script `criar_coleções_steam.js` com validação rigorosa via **`$jsonSchema`** (BSON types, regex de e-mail, enums e documentos embutidos 1:1 para `carteira` e 1:N para `biblioteca` com cache de leitura).

---

## 2. Estrutura do Repositório

```text
Banco-de-Dados/
├── Aplicação/
│   ├── aplicação.py              # CLI transacional em Python + psycopg2 (PostgreSQL / AWS RDS)
│   └── Aplicação.mp4             # Demonstração em vídeo das transações e emissão de Nota Fiscal
├── Bd 2.1/
│   ├── steam-postgresql.sql      # DDL completo para PostgreSQL (Schema, Tabelas, FKs e Índices)
│   ├── steam-sql.sql             # Script original exportado do MySQL Workbench
│   ├── Modelo DEER.jpg           # Diagrama Entidade-Relacionamento Estendido (DEER)
│   ├── MODELO RELACIONAL.png     # Esquema Relacional Mapeado
│   ├── trampo BD.mwb             # Arquivo fonte de modelagem (MySQL Workbench)
│   └── Relatori_BD_2_1.pdf       # Relatório técnico de projeto e normalização
└── Bd 2.2/
    ├── criar_coleções_steam.js   # Modelagem NoSQL (MongoDB) com validação $jsonSchema
    └── Relatorio___BD_2_2.pdf    # Relatório técnico comparativo Relacional vs. NoSQL
```

---

## 3. Esquema Relacional (PostgreSQL)

![Modelo Relacional](Bd%202.1/MODELO%20RELACIONAL.png)

### Principais Tabelas do Schema `steam` ([`Bd 2.1/steam-postgresql.sql`](Bd%202.1/steam-postgresql.sql))

| Tabela | Responsabilidade e Restrições de Integridade |
| :--- | :--- |
| `steam.Carteira` | Saldo financeiro (`NUMERIC(10,2)`) e moeda (`VARCHAR(16)`) vinculados 1:1 ao usuário. |
| `steam.Usuario` | Dados cadastrais com `email UNIQUE`, chave estrangeira `UNIQUE` para `Carteira` e índice `idx_Usuario_Carteira`. |
| `steam.Produto` | Entidade base do catálogo (`Titulo`, `preco NUMERIC(10,2)`, `Data_lancamento`) vinculada à `Publicadora`. |
| `steam.Jogos` / `DLC` / `Software` | Especializações 1:1 de `Produto` (uso de `ARRAY` nativo do PostgreSQL em `Jogos.idiomas`). |
| `steam.Compra` | Cabeçalho do pedido (`status`, `metodo_pagamento`, `valor_pago`, `data_compra`, `Usuario_id_usuario`). |
| `steam.Item_compra` | Itens faturados por pedido (`Compra_id_compra`, `Produto_id_produto`, `Quantidade`, `valor_unitario_pago`). |
| `steam.Nota_Fiscal` | Documento fiscal emitido por transação (`numero_serie UNIQUE`, `valor_total`, `data_emissao`, `Compra_id_compra UNIQUE`). |

---

## 4. Como Executar a Aplicação em Python (`psycopg2`)

### Pré-requisitos
- Python 3.10+
- Instância PostgreSQL (local ou AWS RDS) com o script [`Bd 2.1/steam-postgresql.sql`](Bd%202.1/steam-postgresql.sql) aplicado.

### Instalação e Configuração

```bash
pip install psycopg2-binary
```

Configure as variáveis de ambiente (ou utilize os padrões de desenvolvimento):

```bash
export DB_HOST="localhost"
export DB_PORT="5432"
export DB_NAME="postgres"
export DB_USER="postgres"
export DB_PASS="sua_senha"
```

Execute o cliente transacional:

```bash
python "Aplicação/aplicação.py"
```

### Operações Disponíveis no CLI
1. **Novo Usuário:** Cria automaticamente a `Carteira` (`BRL`, saldo `0.00`) e vincula o novo registro em `steam.Usuario` na mesma transação.
2. **Listar / Atualizar / Remover Usuários:** Consultas SQL parametrizadas e tratamento de exceções de integridade referencial (`ROLLBACK` automático em caso de vínculos ativos).
3. **Cadastrar e Listar Produtos:** Inserção idempotente de publicadora (`ON CONFLICT DO NOTHING`) e cadastro no catálogo.
4. **Carrinho de Compras e Emissão de Nota Fiscal:** Valida os IDs informados, calcula o total, registra `Compra` e `Item_compra`, emite a `Nota_Fiscal` e confirma a transação (`COMMIT`).
5. **Histórico de Vendas (`JOIN` Multi-Tabela) e Estorno de Compra:** Relatório consolidado (`Compra` $\bowtie$ `Usuario` $\bowtie$ `Item_compra` $\bowtie$ `Produto`) e rotina de cancelamento cascata.
