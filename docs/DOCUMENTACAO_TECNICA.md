# GLOBAL SOLUTION 2 — 2026 | CITIZENTECH
## BairroVivo — Participação cidadã no cuidado com o espaço urbano

**Turma:** 3SIOA  
**Integrantes:** Bruna Fazan e Giovanni de Aquino Canella  
**Versão:** 1.0 | Novembro de 2026

## 1. Resumo executivo
BairroVivo é um protótipo acadêmico de aplicativo mobile em Flutter para facilitar
o registro e a organização pessoal de relatos sobre conservação de espaços
públicos. Sua proposta é oferecer uma interface clara, com categorias
compreensíveis, histórico de etapas simulado e indicadores de ocorrências.
O projeto responde ao tema CitizenTech ao colocar o cidadão no centro da
experiência, priorizando simplicidade e acessibilidade. A versão demonstrável
opera offline em SQLite, sem criar a impressão de que existe atendimento
institucional integrado. Um esquema Oracle e rotinas PL/SQL modelam uma
arquitetura de evolução para uso coordenado, mas não estão conectados ao app.

## 2. Problema, público e justificativa
Problemas como iluminação insuficiente, calçadas danificadas, buracos e descarte
irregular afetam o deslocamento, a segurança percebida e a fruição dos espaços
públicos. A informação comunitária sobre essas situações pode ficar dispersa
entre mensagens, anotações e registros não padronizados. O público prioritário
inclui moradores, lideranças de bairro e cidadãos com diferentes níveis de
familiaridade digital. O protótipo centraliza relatos *no próprio dispositivo*
e permite acompanhar a evolução demonstrativa de cada caso.

**Problema recortado:** dificuldade de documentar e organizar relatos urbanos
com categorização e histórico compreensível. **Não se afirma**, na versão atual,
que o app substitui os canais de solicitações municipais ou melhora prazos reais
de atendimento; isso dependeria de integração oficial, pesquisa com usuários e
estudos de impacto.

## 3. Objetivos
**Geral:** demonstrar uma tecnologia móvel de baixo atrito capaz de organizar
relatos de problemas urbanos com transparência do histórico local.

**Específicos:** (i) registrar ocorrências validadas; (ii) pesquisar e filtrar
registros; (iii) consultar histórico e simular transições; (iv) produzir métricas
resumidas; (v) demonstrar modelo Oracle normalizado e automação PL/SQL.

## 4. Público, acessibilidade e ODS
Relaciona-se ao **ODS 11 — Cidades e Comunidades Sustentáveis**, principalmente
à melhoria de espaços públicos e participação cidadã, e ao **ODS 10 — Redução
das Desigualdades**, pelo compromisso de reduzir barreiras de uso digital.
A contribuição é **potencial**, não um impacto quantitativamente comprovado.

A UX apresenta linguagem objetiva, ícones acompanhados de rótulos, validação
de campos, mensagens de feedback, Material 3, navegação inferior com três
seções, conteúdo rolável, suporte nativo a tamanho de texto e alvos de toque
padronizados. O protótipo não passou por auditoria formal WCAG nem por testes
com pessoas com deficiência; estes são passos recomendados na evolução.

## 5. Escopo funcional e critérios de aceitação

| ID | Funcionalidade | Critério observável |
|---|---|---|
| F01 | Cadastro de relatos | Formulário impede título/local/descrição curtos e salva no SQLite. |
| F02 | Busca e filtro | Lista permite buscar título, local ou categoria e filtrar por status. |
| F03 | Acompanhamento | Detalhe mostra situação, histórico e avanço simulado sequencial. |
| F04 | Indicadores | Total, abertos, resolvidos, percentual e distribuição por categoria. |
| F05 | Persistência offline | Dados permanecem disponíveis após fechar e reabrir o app. |

Cadastro e login de usuário não são necessários neste recorte e não são usados
para cumprir a exigência de três funcionalidades.

## 6. Arquitetura
Camada de apresentação: widgets Flutter; camada de domínio: entidade `Report`
e enumeração de situações representada por constantes; camada de persistência:
`ReportRepository`, banco SQLite e histórico em transações.

Fluxo: formulário -> validação -> repository -> transação SQL -> histórico ->
consulta -> indicadores. Não há HTTP, API, servidor, sincronização ou
identificação de operador. O pacote PL/SQL é um artefato separado de referência
para eventual backend futuro. A modelagem do Oracle tem quatro entidades,
contra duas tabelas efetivas no SQLite; consultar `MER_DER.md`.

## 7. Classes, funções e métodos

| Componente | Responsabilidade |
|---|---|
| `Report` | Entidade imutável; `toMap` serializa e `fromMap` reconstrói registros. |
| `ReportRepository.database` | Inicializa e reutiliza banco/índices SQLite. |
| `addReport` | Cria ocorrência e primeiro histórico atomicamente. |
| `listReports` | Pesquisa parametrizada e filtros; consulta assíncrona. |
| `updateStatus` | Valida ordem de transições e insere histórico em transação. |
| `history` | Consulta eventos de uma ocorrência por ID. |
| `BairroVivoApp` | Inicializa MaterialApp e tema. |
| `HomeScreen` | Alterna telas; recria listas após alterações. |
| `ReportsScreen` | Busca, filtros e navegação ao detalhe. |
| `NewReportScreen` | `save` valida entrada e apresenta feedback. |
| `ReportDetailScreen` | `advance` avança etapa simulada e atualiza histórico. |
| `DashboardScreen` | Calcula estatísticas locais e barras proporcionais. |
| `_Metric` | Componente visual dos indicadores. |

## 8. Gerenciamento de memória e eficiência
- `TextEditingController` é descartado em `dispose`, evitando retenção após
  a remoção da tela de cadastro.
- `ReportRepository` reutiliza conexão SQLite, impedindo abertura de múltiplas
  instâncias de banco sem necessidade.
- `FutureBuilder` integra consultas assíncronas sem bloqueio de interface.
- Uso de `const` em widgets estáveis e `setState` para atualizações pontuais.
- Transações reduzem estados intermediários inconsistentes; índices aceleram
  filtros de situação e busca do histórico por ocorrência.
- Consultas utilizam argumentos parametrizados para valores informados pelo
  usuário, reduzindo risco de injeção SQL.
- A consulta atual carrega todos os registros retornados: para grandes bases,
  implementar paginação SQL com `limit`/`offset`, virtualização de listas e
  cache com política de expiração. A busca a cada tecla pode evoluir para
  *debounce*; não se declara que essas otimizações já existem.
- Não há carregamento de imagens pesadas ou processos contínuos em background.

## 9. Segurança e privacidade
Não são coletados nome, CPF, e-mail ou coordenadas. O texto do local e a descrição
podem, entretanto, conter dados pessoais inseridos pelo usuário, por isso o app
orienta que não sejam fornecidos dados de terceiros. O SQLite local não usa
criptografia de banco nesta versão. Em produção: criptografia em repouso,
controle de acesso, autenticação, termos de privacidade, política de retenção,
proteção contra abuso e observância da LGPD, conforme avaliação jurídica.
O app não constitui canal de emergência nem protocolo oficial.

## 10. Modelagem de dados e PL/SQL
O MER/DER em `MER_DER.md` define CIDADÃO (1:N) OCORRÊNCIA, CATEGORIA (1:N)
OCORRÊNCIA e OCORRÊNCIA (1:N) HISTÓRICO. No Oracle, constraints, índices e
chaves estrangeiras reforçam a integridade. `BV_PKG_OCORRENCIA.REGISTRAR`
cria ocorrência e histórico; `AVANCAR_STATUS` valida transições sob `FOR UPDATE`;
`INDICADORES` calcula total, abertas, resolvidas e taxa. O teste demonstrativo
está em `sql/03_teste_oracle.sql`. Esse banco **não atende** o Flutter em tempo
real; sua integração exigiria API e autenticação futuramente.

## 11. Estratégia de testes e evidências
**Testes automatizados incluídos:** verificações iniciais de constantes e de
renderização estática em `test/widget_test.dart`. Eles não substituem testes
integrados de persistência. **Testes manuais sugeridos:**

1. Registro válido: preencher os campos; verificar relato na listagem.
2. Registro inválido: inserir título curto; conferir mensagem de validação.
3. Pesquisa: buscar por palavra do título; verificar subconjunto correto.
4. Filtro: selecionar Registrada; verificar situações apresentadas.
5. Histórico: entrar no detalhe e avançar de Registrada até Resolvida.
6. Indicadores: conferir que a taxa de resolução muda após as transições.
7. Persistência: encerrar e reiniciar o app; verificar dados mantidos.
8. Oracle: executar scripts 01-03 em schema vazio; verificar saída `DBMS_OUTPUT`
   e eventos do histórico. Testar transição inválida e confirmar ORA-20002.

**Status de validação:** o código-fonte e os scripts estão incluídos, mas a execução de Flutter e Oracle não foi verificada neste ambiente. Os testes são disponibilizados para reprodução.

## 12. Limitações, riscos e roadmap
Este é um **MVP offline demonstrativo**: ausência de integração com prefeituras,
usuários, permissões, anexos, georreferenciamento, sincronização, envio de
alertas, SLA e confirmação institucional. Qualquer indicador é apenas da base
local e não deve ser interpretado como resultado da cidade. Evolução proposta:
API autenticada com Oracle, perfis cidadãos/moderadores, consentimento e LGPD,
canais oficiais, moderação de relatos, deduplicação, anexos com consentimento,
indicadores agregados e testes de acessibilidade com usuários reais.

## 13. Requisitos de entrega e publicação
Código e instruções no README.txt; SQL e MER/DER na estrutura do projeto.
A apresentação técnica sem áudio e o roteiro de narração acompanham o pacote. As cenas do aplicativo são reconstruções ilustrativas baseadas no código, não capturas de execução real. O pitch comercial (opcional) não integra este projeto. Os endereços de publicação são organizados exclusivamente nas pastas `LINK_DO_VIDEO/` e `LINK_DO_GITHUB/` do pacote de entrega.

## 14. Referências institucionais e técnicas
- ONU. Objetivos de Desenvolvimento Sustentável: https://brasil.un.org/pt-br/sdgs
- Flutter. Documentação oficial: https://docs.flutter.dev/
- Dart. Documentação oficial: https://dart.dev/guides
- Oracle. PL/SQL Language Reference: https://docs.oracle.com/en/database/oracle/oracle-database/
- W3C. Web Content Accessibility Guidelines: https://www.w3.org/WAI/standards-guidelines/wcag/

Referências de consulta, não representando validação de produção ou métricas
externas verificadas para este protótipo.
