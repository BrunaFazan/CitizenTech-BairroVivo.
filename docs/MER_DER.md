# BairroVivo — MER e DER

## MER (Modelo Entidade-Relacionamento)

**CIDADÃO**: pessoa que cria uma ocorrência no futuro sistema compartilhado.
**CATEGORIA**: classificação padronizada de problema urbano.
**OCORRÊNCIA**: registro com título, descrição, local, situação e datas.
**HISTÓRICO**: evento imutável de entrada ou mudança de situação.

Cardinalidades: um cidadão pode criar zero ou muitas ocorrências (1:N); uma
categoria pode classificar zero ou muitas ocorrências (1:N); uma ocorrência
tem um ou muitos eventos de histórico (1:N). Cada ocorrência pertence a um
cidadão e uma categoria. Cada histórico pertence a uma ocorrência.

## DER (Diagrama Entidade-Relacionamento, modelo Oracle)

```mermaid
erDiagram
    BV_CIDADAO ||--o{ BV_OCORRENCIA : registra
    BV_CATEGORIA ||--o{ BV_OCORRENCIA : classifica
    BV_OCORRENCIA ||--|{ BV_HISTORICO : possui
    BV_CIDADAO {
        number ID_CIDADAO PK
        varchar NOME_EXIBICAO
        timestamp CRIADO_EM
    }
    BV_CATEGORIA {
        number ID_CATEGORIA PK
        varchar NOME UK
    }
    BV_OCORRENCIA {
        number ID_OCORRENCIA PK
        number ID_CIDADAO FK
        number ID_CATEGORIA FK
        varchar TITULO
        varchar DESCRICAO
        varchar LOCAL_REFERENCIA
        varchar STATUS
        timestamp CRIADO_EM
        timestamp ATUALIZADO_EM
    }
    BV_HISTORICO {
        number ID_HISTORICO PK
        number ID_OCORRENCIA FK
        varchar STATUS_ANTERIOR
        varchar STATUS_NOVO
        timestamp ALTERADO_EM
        varchar OBSERVACAO
    }
```

### Regras de integridade

- PK em todas as entidades e FK nas associações.
- `BV_OCORRENCIA.STATUS` aceita apenas REGISTRADA, EM_ANALISE,
  EM_ATENDIMENTO e RESOLVIDA (CHECK).
- `BV_PKG_OCORRENCIA.AVANCAR_STATUS` só permite passagem para o próximo estado.
- O histórico registra a transição no mesmo contexto transacional do registro.
- O pacote não efetua COMMIT: a transação é encerrada pelo chamador.
- No aplicativo Flutter offline, não há CIDADÃO nem CATEGORIA como tabela:
  a categoria é uma string no registro; o banco SQLite contém `reports` e
  `report_history`. O Oracle representa uma **arquitetura evolutiva**, não
  uma integração implementada.

## DER do protótipo SQLite efetivamente executado

```mermaid
erDiagram
    reports ||--|{ report_history : registra
    reports {
        int id PK
        text title
        text category
        text address
        text description
        text status
        text created_at
    }
    report_history {
        int id PK
        int report_id FK
        text old_status
        text new_status
        text changed_at
    }
```
