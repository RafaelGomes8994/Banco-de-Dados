// 1. Criação da Coleção de Usuários (Inclui Biblioteca e Carteira)
db.createCollection("users", {
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["nome_completo", "email", "senha", "carteira", "biblioteca"],
         properties: {
            _id: { bsonType: "objectId" },
            nome_completo: { bsonType: "string" },
            email: { 
               bsonType: "string", 
               pattern: "^.+@.+$" // Regex simples para email
            },
            senha: { bsonType: "string" }, // Hash
            nivel: { bsonType: "int" },
            
            // Tabela Carteira (Embutida 1:1)
            carteira: {
               bsonType: "object",
               required: ["saldo_atual", "moeda"],
               properties: {
                  saldo_atual: { bsonType: ["decimal", "double"] },
                  moeda: { bsonType: "string", minLength: 3, maxLength: 3 }
               }
            },

            // Tabela Biblioteca (Embutida 1:N como Array)
            biblioteca: {
               bsonType: "array",
               description: "Lista de jogos que o usuário possui",
               items: {
                  bsonType: "object",
                  required: ["produto_id", "data_aquisicao", "status_instalacao"],
                  properties: {
                     produto_id: { bsonType: "objectId" }, // Referência para products
                     titulo_cache: { bsonType: "string" }, // Opcional: para listar sem JOIN
                     tempo_jogado_minutos: { bsonType: "int" },
                     status_instalacao: { bsonType: "bool" },
                     data_aquisicao: { bsonType: "date" }
                  }
               }
            }
         }
      }
   }
});

// 2. Criação da Coleção de Produtos
db.createCollection("products", {
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["tipo", "titulo", "preco", "data_lancamento"],
         properties: {
            _id: { bsonType: "objectId" },
            tipo: { enum: ["Jogo", "Software", "DLC"] },
            titulo: { bsonType: "string" },
            preco: { bsonType: ["decimal", "double"] },
            descricao: { bsonType: "string" },
            data_lancamento: { bsonType: "date" },
            publicadora: { bsonType: "string" },
            detalhes: {
               bsonType: "object",
               properties: {
                  idiomas: { bsonType: "array" }, // Array nativo substitui a tabela associativa
                  requisitos: { bsonType: "object" }
               }
            },
            // Polimorfismo: Campos específicos aparecem aqui
            especificacoes_jogo: {
               bsonType: "object",
               properties: {
                  desenvolvedora: { bsonType: "string" },
                  suporte_controle: { bsonType: "bool" },
                  faixa_etaria: { bsonType: "string" },
                  generos: { bsonType: "array" },
                  requisitos_sistema: {
                     bsonType: "object",
                     properties: {
                        minimo: { bsonType: "object" },
                        recomendado: { bsonType: "object" }
                     }
                  },
                  conquistasArray: { bsonType: "array" }
               }
            },
            especificacoes_software: {
               bsonType: "object",
               properties: {
                  versao: { bsonType: "string" },
                  tipo_licenca: { bsonType: "string" }
               }
            },
            especificacoes_dlc: {
               bsonType: "object",
               properties: {
                  id_jogo_base: { bsonType: "objectId" }, // Referência ao pai
                  tamanho_download: { bsonType: "int" }
               }
            }
         }
      }
   }
});

// 3. Criação da Coleção de Pedidos
db.createCollection("orders", {
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["data_compra", "usuario_id", "status", "total_pago", "itens", "nota_fiscal"],
         properties: {
            _id: { bsonType: "objectId" },
            data_compra: { bsonType: "date" },
            usuario_id: { bsonType: "objectId" }, // Referência ao comprador
            status: { enum: ["Pendente", "Aprovado", "Cancelado", "Reembolsado"] },
            metodo_pagamento: { bsonType: "string" },
            total_pago: { bsonType: ["decimal", "double"] },

            // Tabela Item_compra (Array de Subdocumentos)
            itens: {
               bsonType: "array",
               minItems: 1,
               items: {
                  bsonType: "object",
                  required: ["produto_id", "titulo_snapshot", "valor_unitario", "quantidade"],
                  properties: {
                     produto_id: { bsonType: "objectId" },
                     // Snapshot: Nome e Preço congelados no momento da compra
                     titulo_snapshot: { bsonType: "string" }, 
                     valor_unitario: { bsonType: ["decimal", "double"] },
                     quantidade: { bsonType: "int" }
                  }
               }
            },

            // Tabela Nota_Fiscal (Embutida 1:1)
            nota_fiscal: {
               bsonType: "object",
               required: ["numero_serie", "data_emissao"],
               properties: {
                  numero_serie: { bsonType: "int" },
                  data_emissao: { bsonType: "date" },
                  valor_total: { bsonType: ["decimal", "double"] }
               }
            }
         }
      }
   }
});

// 4. Criação da Coleção de Reviews/Avaliações
db.createCollection("reviews", {
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["produto_id", "usuario_id", "voto", "data_postagem"],
         properties: {
            _id: { bsonType: "objectId" },
            
            // Referências para conectar as pontas
            produto_id: { bsonType: "objectId" }, 
            usuario_id: { bsonType: "objectId" },
            
            // Dados Desnormalizados (para exibir review sem buscar dados do user)
            nome_usuario: { bsonType: "string" }, 
            
            voto: { 
               bsonType: "int", 
               minimum: 0, 
               maximum: 5,
               description: "Nota de 0 a 5 ou 0/1 para negativo/positivo" 
            },
            texto_analise: { bsonType: "string" },
            data_postagem: { bsonType: "date" }
         }
      }
   }
});