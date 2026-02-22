import psycopg2
import random 
from psycopg2 import OperationalError
from datetime import datetime

DB_HOST = "steamdb.cximu3gskw3g.us-east-1.rds.amazonaws.com"
DB_NAME = "postgres"
DB_USER = "professor"
DB_PASS = "professor"
DB_PORT = "5432"

def campo_obrigatorio(mensagem, tipo=str):
    while True:
        valor = input(mensagem).strip()
        if not valor:
            print("Erro: Este campo é obrigatório e não pode ser nulo!")
            continue
        try:
            return tipo(valor)
        except ValueError:
            print(f"Erro: Formato inválido. Esperado tipo: {tipo.__name__}")

def create_connection():
    try:
        conn = psycopg2.connect(
            host=DB_HOST, database=DB_NAME, user=DB_USER, password=DB_PASS, port=DB_PORT
        )
        return conn
    except OperationalError as e:
        print(f"Erro de conexão: {e}")
        return None

def get_produto_preco(conn, id_produto):
    cursor = conn.cursor()
    cursor.execute("SELECT preco FROM steam.Produto WHERE id_produto = %s", (id_produto,))
    result = cursor.fetchone()
    cursor.close()
    return result[0] if result else 0.0

def insert_usuario(conn):
    print("\n--- Inserir Novo Usuário ---")
    nome = campo_obrigatorio("Nome Completo: ")
    email = campo_obrigatorio("E-mail: ")
    senha = campo_obrigatorio("Senha: ")
    nivel = 1 
    
    cursor = conn.cursor()
    try:
        print("Criando carteira automática...")
        sql_cart = "INSERT INTO steam.Carteira (Moeda, saldo_atual) VALUES (%s, %s) RETURNING id_carteira"
        cursor.execute(sql_cart, ('BRL', 0.00))
        id_carteira = cursor.fetchone()[0]

        sql_user = """
            INSERT INTO steam.Usuario (Nome_Completo, email, senha, nivel, Carteira_id_carteira) 
            VALUES (%s, %s, %s, %s, %s)
        """
        cursor.execute(sql_user, (nome, email, senha, nivel, id_carteira))
        
        conn.commit()
        print(f"Sucesso! Usuário criado (Carteira ID: {id_carteira})")
    except Exception as e:
        conn.rollback()
        print(f"Erro ao inserir usuário: {e}")
    finally:
        cursor.close()

def read_usuarios(conn):
    print("\n--- Usuários Cadastrados ---")
    cursor = conn.cursor()
    cursor.execute("SELECT id_usuario, Nome_Completo, email, nivel FROM steam.Usuario")
    for row in cursor.fetchall():
        print(f"ID: {row[0]} | Nome: {row[1]} | Email: {row[2]} | Nível: {row[3]}")
    cursor.close()

def update_usuario(conn):
    print("\n--- Atualizar E-mail ---")
    id_user = campo_obrigatorio("ID do Usuário: ", int)
    novo_email = campo_obrigatorio("Novo E-mail: ")
    cursor = conn.cursor()
    try:
        cursor.execute("UPDATE steam.Usuario SET email = %s WHERE id_usuario = %s", (novo_email, id_user))
        conn.commit()
        if cursor.rowcount == 0:
            print("Aviso: Nenhum usuário encontrado com esse ID.")
        else:
            print("Usuário atualizado com sucesso.")
    except Exception as e:
        print(f"Erro: {e}")
    finally:
        cursor.close()

def delete_usuario(conn):
    print("\n--- Deletar Usuário ---")
    id_user = campo_obrigatorio("ID do Usuário: ", int)
    cursor = conn.cursor()
    try:
        cursor.execute("DELETE FROM steam.Usuario WHERE id_usuario = %s", (id_user,))
        conn.commit()
        if cursor.rowcount == 0:
            print("Aviso: Usuário não encontrado.")
        else:
            print("Usuário deletado.")
    except Exception as e:
        conn.rollback()
        print(f"Erro: Violação de integridade ou erro de banco. Detalhe: {e}")
    finally:
        cursor.close()

def insert_produto(conn):
    print("\n--- Inserir Produto ---")
    titulo = campo_obrigatorio("Título: ")
    preco = campo_obrigatorio("Preço: ", float)
    descricao = campo_obrigatorio("Descrição: ")
    data = campo_obrigatorio("Data (YYYY-MM-DD): ")
    
    cursor = conn.cursor()
    try:
        pub_nome = "Valve" 
        cursor.execute("INSERT INTO steam.Publicadora (Nome_Publicadora, contato) VALUES (%s, %s) ON CONFLICT DO NOTHING", (pub_nome, "contact@valve.com"))
        
        sql = """
            INSERT INTO steam.Produto (Titulo, preco, Descricao, Data_lancamento, Publicadora_Nome_Publicadora) 
            VALUES (%s, %s, %s, %s, %s)
        """
        cursor.execute(sql, (titulo, preco, descricao, data, pub_nome))
        conn.commit()
        print("Produto inserido com sucesso.")
    except Exception as e:
        conn.rollback()
        print(f"Erro: {e}")
    finally:
        cursor.close()

def read_produtos(conn):
    print("\n--- Produtos Disponíveis ---")
    cursor = conn.cursor()
    cursor.execute("SELECT id_produto, Titulo, preco FROM steam.Produto")
    for row in cursor.fetchall():
        print(f"ID: {row[0]} | Jogo: {row[1]} | R$ {row[2]}")
    cursor.close()

def insert_compra_carrinho(conn):
    print("\n--- Novo Carrinho de Compras ---")
    id_user = campo_obrigatorio("ID do Usuário: ", int)
    input_prods = campo_obrigatorio("IDs dos Jogos (separados por espaço): ")
    ids_produtos = input_prods.split()
    metodo = campo_obrigatorio("Método de Pagamento: ")

    cursor = conn.cursor()
    try:
        total_carrinho = 0
        itens_para_inserir = []

        for id_p in ids_produtos:
            cursor.execute("SELECT Titulo, preco FROM steam.Produto WHERE id_produto = %s", (id_p,))
            res = cursor.fetchone()
            if res:
                total_carrinho += float(res[1])
                itens_para_inserir.append({'id': id_p, 'preco': res[1]})
            else:
                print(f"Aviso: Produto ID {id_p} não encontrado.")

        if not itens_para_inserir:
            print("Carrinho vazio ou produtos inválidos.")
            return

        sql_compra = """
            INSERT INTO steam.Compra (status, metodo_pagamento, valor_pago, data_compra, Usuario_id_usuario) 
            VALUES (1, %s, %s, NOW(), %s) RETURNING id_compra
        """
        cursor.execute(sql_compra, (metodo, total_carrinho, id_user))
        id_compra = cursor.fetchone()[0]

        for item in itens_para_inserir:
            sql_item = """
                INSERT INTO steam.Item_compra (Compra_id_compra, Produto_id_produto, Quantidade, valor_unitario_pago) 
                VALUES (%s, %s, 1, %s)
            """
            cursor.execute(sql_item, (id_compra, item['id'], item['preco']))

        num_serie = random.randint(100000, 999999)
        sql_nf = """
            INSERT INTO steam.Nota_Fiscal (numero_serie, valor_total, data_emissao, Compra_id_compra) 
            VALUES (%s, %s, NOW(), %s)
        """
        cursor.execute(sql_nf, (num_serie, total_carrinho, id_compra))

        conn.commit()
        print(f"\nSUCESSO! Compra #{id_compra} finalizada com NF: {num_serie}")

    except Exception as e:
        conn.rollback()
        print(f"Erro na transação: {e}")
    finally:
        cursor.close()

def read_compras(conn):
    print("\n--- Histórico de Compras ---")
    sql = """
        SELECT c.id_compra, u.Nome_Completo, p.Titulo, i.valor_unitario_pago, c.data_compra
        FROM steam.Compra c
        JOIN steam.Usuario u ON c.Usuario_id_usuario = u.id_usuario
        JOIN steam.Item_compra i ON c.id_compra = i.Compra_id_compra
        JOIN steam.Produto p ON i.Produto_id_produto = p.id_produto
    """
    cursor = conn.cursor()
    cursor.execute(sql)
    for row in cursor.fetchall():
        print(f"Compra #{row[0]} | User: {row[1]} | Jogo: {row[2]} | Valor: {row[3]} | Data: {row[4]}")
    cursor.close()

def delete_compra(conn):
    print("\n--- Estornar Compra ---")
    id_compra = campo_obrigatorio("ID da Compra: ", int)
    cursor = conn.cursor()
    try:
        # Deletar nota fiscal primeiro (dependência)
        cursor.execute("DELETE FROM steam.Nota_Fiscal WHERE Compra_id_compra = %s", (id_compra,))
        cursor.execute("DELETE FROM steam.Item_compra WHERE Compra_id_compra = %s", (id_compra,))
        cursor.execute("DELETE FROM steam.Compra WHERE id_compra = %s", (id_compra,))
        conn.commit()
        if cursor.rowcount == 0:
            print("Aviso: Compra não encontrada.")
        else:
            print("Compra estornada com sucesso.")
    except Exception as e:
        conn.rollback()
        print(f"Erro ao deletar: {e}")
    finally:
        cursor.close()

def main():
    conn = create_connection()
    if not conn: return
    
    with conn.cursor() as cur:
        cur.execute("SET search_path TO steam;")
        conn.commit()

    while True:
        print("\n=== STEAM ADMIN (MODO ESTRITO) ===")
        print("1. Novo Usuario")
        print("2. Ver Usuarios")
        print("3. Atualizar Usuario")
        print("4. Deletar Usuario")
        print("---")
        print("5. Novo Produto")
        print("6. Ver Produtos")
        print("---")
        print("7. Comprar Jogos (Carrinho)")
        print("8. Ver Vendas")
        print("9. Cancelar Venda")
        print("0. Sair")
        
        op = input("Opção: ")
        if op == '1': insert_usuario(conn)
        elif op == '2': read_usuarios(conn)
        elif op == '3': update_usuario(conn)
        elif op == '4': delete_usuario(conn)
        elif op == '5': insert_produto(conn)
        elif op == '6': read_produtos(conn)
        elif op == '7': insert_compra_carrinho(conn)
        elif op == '8': read_compras(conn)
        elif op == '9': delete_compra(conn)
        elif op == '0': break
    
    conn.close()

if __name__ == "__main__":
    main()