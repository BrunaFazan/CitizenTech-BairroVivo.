BAIRROVIVO | GLOBAL SOLUTION 2 - 2026 | CITIZENTECH
===================================================

1. PROPOSTA
Aplicativo acadêmico Flutter para cidadãos registrarem problemas de espaços
públicos, consultarem o histórico de acompanhamento simulado e visualizarem
indicadores dos relatos presentes no próprio aparelho.

2. ESCOPO REAL DO PROTÓTIPO
- Registro de ocorrência com título, categoria, referência de local e descrição.
- Consulta, pesquisa e filtro por situação.
- Histórico de etapas e avanço simulado de status (uma etapa de cada vez).
- Painel de indicadores locais por situação e categoria.
- Persistência offline SQLite; dados ficam no dispositivo.

ATENÇÃO: NÃO há backend, transmissão a prefeitura, autenticação, integração
com órgãos públicos, notificações, geolocalização, sincronização, IA ou fotos.
A alteração de status é uma simulação acadêmica, NÃO significa ação da prefeitura.
O conjunto Oracle/PLSQL da pasta sql/ é um modelo complementar independente,
para demonstrar modelagem e automação. NÃO está conectado ao Flutter/SQLite.

3. TECNOLOGIAS
- Flutter com Dart: interface Android/iOS multiplataforma e componentes Material 3.
- sqflite: banco de dados SQLite local e transações.
- path: composição do caminho do banco.
- intl: formato de data e hora em pt-BR por padrão especificado.
- Oracle Database 19c+ / PL/SQL: esquema de referência e rotinas transacionais.

4. REQUISITOS DE AMBIENTE
- Flutter SDK instalado e adicionado ao PATH (Dart incluído no Flutter).
- Android Studio com Android SDK e emulador Android, OU aparelho Android com
  depuração USB, OU ambiente macOS com Xcode para executar em iOS.
- Terminal na pasta-raiz do projeto.
- Conexão com internet apenas na instalação inicial das dependências.

5. EXECUÇÃO DO APLICATIVO
  flutter doctor
  flutter pub get
  flutter devices
  flutter run

Se o diretório não tiver as pastas de plataforma android/ e ios/ (este pacote
contém o código-fonte essencial, não os arquivos gerados de plataforma), rode
uma única vez na raiz:
  flutter create --platforms=android,ios --project-name bairro_vivo .
Depois execute novamente flutter pub get e flutter run.

OBS: escolha um emulador ou dispositivo Android/iOS; sqflite não foi configurado
para uso no navegador (flutter run -d chrome não é suportado neste protótipo).

6. EXECUÇÃO DO MODELO ORACLE
No Oracle SQL Developer ou SQLcl conectado a um schema de desenvolvimento
com permissão CREATE TABLE, CREATE PROCEDURE e CREATE PACKAGE:
  @sql/01_schema_oracle.sql
  @sql/02_automacao_plsql.sql
  @sql/03_teste_oracle.sql
Use as rotinas somente em um schema próprio de testes, sem dados de produção.
Ordem obrigatória: esquema, pacote, teste. Os scripts de criação não são
idempotentes; execute uma única vez em schema vazio.

7. CENÁRIO DE DEMONSTRAÇÃO
1) Abrir a aba Registrar e cadastrar um poste apagado com local e descrição.
2) Na aba Ocorrências, localizar pelo título, testar o filtro e abrir o item.
3) Na tela de detalhes, avançar os status até Resolvida e ver o histórico.
4) Na aba Indicadores, conferir total, abertos, resolvidos e percentual.
5) Reiniciar o aplicativo e comprovar persistência do registro.

8. ARQUITETURA E CÓDIGO
lib/main.dart - implementação modular em classes:
Report: entidade e conversão toMap/fromMap.
ReportRepository: inicializa SQLite; addReport cria registro + histórico em
transação; listReports aplica busca/filtro parametrizados; updateStatus
valida avanço sequencial em transação; history lista eventos.
BairroVivoApp: tema, navegação-raiz e configuração Material.
HomeScreen: navegação entre três seções.
ReportsScreen: pesquisa, filtro e consulta.
NewReportScreen: valida formulário e salva registro.
ReportDetailScreen: detalhes e progresso simulado.
DashboardScreen: agrega indicadores a partir dos registros locais.
_Metric: cartão reutilizável para os indicadores.

sql/01_schema_oracle.sql: MER físico (tabelas, FKs, constraints, índices).
sql/02_automacao_plsql.sql: package BV_PKG_OCORRENCIA com registrar,
avançar_status e indicadores.
sql/03_teste_oracle.sql: massa de demonstração + consulta de histórico.
docs/MER_DER.md: modelagem conceitual/lógica e DER Mermaid.
docs/DOCUMENTACAO_TECNICA.md: requisitos, arquitetura, UX, memória, ODS,
limitações, roteiros de verificação e critérios de aceitação.

9. BOAS PRÁTICAS E EFICIÊNCIA
- Singleton ReportRepository mantém uma referência de banco por processo.
- Consultas assíncronas com FutureBuilder evitam bloquear a UI.
- Listas não crescem sem limite de elementos em memória, mas para grande
  volume devem ser substituídas por paginação (limitação documentada).
- TextEditingController descartados em dispose para evitar vazamentos.
- Transações garantem atomicidade entre ocorrência e respectivo histórico.
- Parâmetros SQL em vez de interpolar entrada do usuário em consultas.
- Índices em status e report_id; persistência local evita tráfego de rede.
- Widgets const quando aplicável e atualizações de estado localizadas.

10. TESTES
  flutter analyze
  flutter test
Há testes básicos em test/widget_test.dart. A validação completa de cadastro,
persistência e SQL exige execução manual nos ambientes correspondentes.
Este material não afirma execução validada pelo autor do pacote: é necessário
rodar os comandos no seu ambiente antes da entrega acadêmica.

11. PRIVACIDADE E RESPONSABILIDADE
Os dados ficam no aparelho; não existe consentimento/conta de usuário porque
não há transmissão remota. Evite inserir dados pessoais de terceiros ou dados
sensíveis. Não use esta demonstração para emergência ou solicitações oficiais.

12. PUBLICAÇÃO NO GITHUB
1) Crie um repositório no GitHub (ex.: gs2-2026-bairrovivo).
2) Na raiz, execute: git init; git add .; git commit -m "GS2 BairroVivo".
3) Associe o remote e faça push seguindo as instruções do próprio GitHub.
4) Compartilhe com o tutor e registre a URL real no arquivo LINK_DO_GITHUB/link_github.txt.

13. APRESENTAÇÃO TÉCNICA
O pacote inclui vídeo técnico de 3min36s, sem áudio, e roteiro de narração.
As telas são reconstruções visuais ilustrativas, não filmagem do app real.
O pitch comercial opcional não foi incluído.

14. INTEGRANTES
Bruna Fazan e Giovanni de Aquino Canella
Turma: 3SIOA.

15. LINKS DE ENTREGA
Os dois únicos arquivos reservados à inserção de URLs de publicação estão
em LINK_DO_VIDEO/link_video.txt e LINK_DO_GITHUB/link_github.txt.
O repositório não foi publicado automaticamente e o vídeo ainda não foi
publicado no YouTube.
