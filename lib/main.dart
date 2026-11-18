import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BairroVivoApp());
}

/// Categorias de problemas relatáveis no protótipo.
const categories = <String>[
  'Iluminação pública',
  'Calçada e acessibilidade',
  'Buraco na via',
  'Limpeza urbana',
  'Drenagem e alagamento',
  'Outros',
];

const statuses = <String>['Registrada', 'Em análise', 'Em atendimento', 'Resolvida'];

/// Ocorrência criada pelo cidadão. Não representa protocolo governamental.
class Report {
  final int? id;
  final String title;
  final String category;
  final String address;
  final String description;
  final String status;
  final DateTime createdAt;

  const Report({
    this.id,
    required this.title,
    required this.category,
    required this.address,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'title': title,
        'category': category,
        'address': address,
        'description': description,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  factory Report.fromMap(Map<String, Object?> row) => Report(
        id: row['id'] as int,
        title: row['title'] as String,
        category: row['category'] as String,
        address: row['address'] as String,
        description: row['description'] as String,
        status: row['status'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}

/// Persistência SQLite local. Banco aberto uma vez e reutilizado.
class ReportRepository {
  ReportRepository._();
  static final ReportRepository instance = ReportRepository._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final base = await getDatabasesPath();
    _database = await openDatabase(
      join(base, 'bairro_vivo.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE reports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            address TEXT NOT NULL,
            description TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE report_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            report_id INTEGER NOT NULL,
            old_status TEXT,
            new_status TEXT NOT NULL,
            changed_at TEXT NOT NULL,
            FOREIGN KEY (report_id) REFERENCES reports(id)
          )
        ''');
        await db.execute('CREATE INDEX idx_reports_status ON reports(status)');
        await db.execute('CREATE INDEX idx_history_report ON report_history(report_id)');
      },
    );
    return _database!;
  }

  Future<int> addReport(Report report) async {
    final db = await database;
    return db.transaction((txn) async {
      final id = await txn.insert('reports', report.toMap());
      await txn.insert('report_history', {
        'report_id': id,
        'old_status': null,
        'new_status': report.status,
        'changed_at': DateTime.now().toIso8601String(),
      });
      return id;
    });
  }

  Future<List<Report>> listReports({String? status, String search = ''}) async {
    final db = await database;
    final conditions = <String>[];
    final arguments = <Object?>[];
    if (status != null && status != 'Todos') {
      conditions.add('status = ?');
      arguments.add(status);
    }
    if (search.trim().isNotEmpty) {
      conditions.add('(title LIKE ? OR address LIKE ? OR category LIKE ?)');
      final value = '%${search.trim()}%';
      arguments.addAll([value, value, value]);
    }
    final rows = await db.query('reports',
        where: conditions.isEmpty ? null : conditions.join(' AND '),
        whereArgs: arguments,
        orderBy: 'created_at DESC');
    return rows.map(Report.fromMap).toList(growable: false);
  }

  Future<void> updateStatus(int id, String status) async {
    if (!statuses.contains(status)) throw ArgumentError('Status inválido');
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query('reports',
          columns: ['status'], where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) throw StateError('Ocorrência não encontrada');
      final old = rows.first['status'] as String;
      if (old == status) return;
      if (old == 'Resolvida') throw StateError('Ocorrência encerrada');
      final oldIndex = statuses.indexOf(old);
      final nextIndex = statuses.indexOf(status);
      if (nextIndex != oldIndex + 1) {
        throw StateError('Avance apenas para a próxima etapa');
      }
      await txn.update('reports', {'status': status},
          where: 'id = ?', whereArgs: [id]);
      await txn.insert('report_history', {
        'report_id': id,
        'old_status': old,
        'new_status': status,
        'changed_at': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<List<Map<String, Object?>>> history(int id) async {
    final db = await database;
    return db.query('report_history',
        where: 'report_id = ?', whereArgs: [id], orderBy: 'id DESC');
  }
}

class BairroVivoApp extends StatelessWidget {
  const BairroVivoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BairroVivo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF126B57),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8F7),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  int refresh = 0;
  void reload() => setState(() => refresh++);

  @override
  Widget build(BuildContext context) {
    final pages = [
      ReportsScreen(key: ValueKey('reports-$refresh'), onChanged: reload),
      NewReportScreen(key: ValueKey('new-$refresh'), onSaved: () {
        reload();
        setState(() => tab = 0);
      }),
      DashboardScreen(key: ValueKey('dashboard-$refresh')),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('BairroVivo', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (index) => setState(() => tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), label: 'Ocorrências'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Registrar'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Indicadores'),
        ],
      ),
    );
  }
}

class ReportsScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const ReportsScreen({super.key, required this.onChanged});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String filter = 'Todos';
  String query = '';
  late Future<List<Report>> future;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() => future = ReportRepository.instance.listReports(status: filter, search: query);

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Problemas do bairro', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      const Text('Acompanhe relatos registrados neste dispositivo.'),
      const SizedBox(height: 18),
      TextField(
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Buscar por título, local ou categoria'),
        onChanged: (value) => setState(() { query = value; load(); }),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: filter,
        decoration: const InputDecoration(labelText: 'Filtrar por situação'),
        items: ['Todos', ...statuses].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: (value) => setState(() { filter = value!; load(); }),
      ),
      const SizedBox(height: 16),
      FutureBuilder<List<Report>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Text('Não foi possível carregar os dados locais.');
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final reports = snapshot.data!;
          if (reports.isEmpty) return const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(child: Text('Nenhuma ocorrência encontrada. Use “Registrar” para começar.')),
          );
          return Column(children: reports.map((report) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(report.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${report.category}\n${report.address}\nSituação: ${report.status}'),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ReportDetailScreen(report: report),
                ));
                if (!mounted) return;
                setState(load);
                widget.onChanged();
              },
            ),
          )).toList());
        },
      ),
      const SizedBox(height: 10),
      const Text('Protótipo acadêmico: o registro não é enviado à prefeitura.', style: TextStyle(fontSize: 12)),
    ]);
  }
}

class NewReportScreen extends StatefulWidget {
  final VoidCallback onSaved;
  const NewReportScreen({super.key, required this.onSaved});
  @override
  State<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends State<NewReportScreen> {
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final address = TextEditingController();
  final description = TextEditingController();
  String category = categories.first;
  bool saving = false;

  @override
  void dispose() {
    title.dispose();
    address.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate() || saving) return;
    setState(() => saving = true);
    try {
      await ReportRepository.instance.addReport(Report(
        title: title.text.trim(), category: category, address: address.text.trim(),
        description: description.text.trim(), status: statuses.first,
        createdAt: DateTime.now(),
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocorrência registrada neste dispositivo.')),
      );
      widget.onSaved();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar. Tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(key: formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Nova ocorrência', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      const Text('Descreva um problema em um espaço público. Não inclua dados pessoais de terceiros.'),
      const SizedBox(height: 20),
      TextFormField(controller: title, maxLength: 90,
        decoration: const InputDecoration(labelText: 'Título *', hintText: 'Ex.: Poste apagado'),
        validator: (v) => (v?.trim().length ?? 0) < 5 ? 'Informe pelo menos 5 caracteres' : null),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: category,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Categoria *'),
        items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) => setState(() => category = v!),
      ),
      const SizedBox(height: 18),
      TextFormField(controller: address, maxLength: 140,
        decoration: const InputDecoration(labelText: 'Local de referência *', hintText: 'Rua, bairro ou ponto de referência'),
        validator: (v) => (v?.trim().length ?? 0) < 5 ? 'Informe o local do problema' : null),
      const SizedBox(height: 12),
      TextFormField(controller: description, maxLength: 600, minLines: 3, maxLines: 6,
        decoration: const InputDecoration(labelText: 'Descrição *', hintText: 'Explique o que está acontecendo'),
        validator: (v) => (v?.trim().length ?? 0) < 10 ? 'Informe pelo menos 10 caracteres' : null),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: saving ? null : save,
        icon: const Icon(Icons.send_outlined),
        label: Text(saving ? 'Salvando...' : 'Registrar ocorrência')),
      const SizedBox(height: 14),
      const Text('Os dados permanecem localmente e podem ser excluídos ao remover o aplicativo.',
        style: TextStyle(fontSize: 12)),
    ]));
  }
}

class ReportDetailScreen extends StatefulWidget {
  final Report report;
  const ReportDetailScreen({super.key, required this.report});
  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late String current;
  late Future<List<Map<String, Object?>>> timeline;
  bool updating = false;

  @override
  void initState() {
    super.initState();
    current = widget.report.status;
    timeline = ReportRepository.instance.history(widget.report.id!);
  }

  Future<void> advance() async {
    final next = statuses[statuses.indexOf(current) + 1];
    setState(() => updating = true);
    try {
      await ReportRepository.instance.updateStatus(widget.report.id!, next);
      if (!mounted) return;
      setState(() { current = next; timeline = ReportRepository.instance.history(widget.report.id!); });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Etapa atualizada no protótipo.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível atualizar a etapa.')));
    } finally {
      if (mounted) setState(() => updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da ocorrência')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(widget.report.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 14),
        Text('Categoria: ${widget.report.category}'),
        Text('Local: ${widget.report.address}'),
        Text('Criada em: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.report.createdAt)}'),
        const SizedBox(height: 16),
        Text(widget.report.description),
        const Divider(height: 36),
        Text('Situação atual: $current', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (current != 'Resolvida') FilledButton(
          onPressed: updating ? null : advance,
          child: Text(updating ? 'Atualizando...' : 'Simular próxima etapa: ${statuses[statuses.indexOf(current) + 1]}'),
        ),
        const SizedBox(height: 8),
        const Text('A mudança de etapa é uma simulação local, não um atendimento oficial.',
          style: TextStyle(fontSize: 12)),
        const Divider(height: 36),
        const Text('Histórico de acompanhamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        FutureBuilder<List<Map<String, Object?>>>(
          future: timeline,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            return Column(children: snap.data!.map((row) {
              final date = DateTime.parse(row['changed_at'] as String);
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(row['new_status'] as String),
                subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(date)),
              );
            }).toList());
          },
        ),
      ]),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Report>>(
      future: ReportRepository.instance.listReports(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final reports = snapshot.data!;
        final total = reports.length;
        final resolved = reports.where((e) => e.status == 'Resolvida').length;
        final active = total - resolved;
        final rate = total == 0 ? 0.0 : resolved * 100 / total;
        return ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Indicadores comunitários',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Resumo dos registros armazenados neste aparelho.'),
          const SizedBox(height: 20),
          Wrap(spacing: 10, runSpacing: 10, children: [
            _Metric(label: 'Total de relatos', value: '$total', icon: Icons.assignment_outlined),
            _Metric(label: 'Em aberto', value: '$active', icon: Icons.pending_actions_outlined),
            _Metric(label: 'Resolvidos', value: '$resolved', icon: Icons.check_circle_outline),
            _Metric(label: 'Taxa de resolução', value: '${rate.toStringAsFixed(0)}%', icon: Icons.insights_outlined),
          ]),
          const SizedBox(height: 26),
          const Text('Ocorrências por categoria',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (total == 0) const Text('Registre uma ocorrência para visualizar indicadores.'),
          for (final category in categories) if (reports.any((r) => r.category == category)) ...[
            Text('$category (${reports.where((r) => r.category == category).length})'),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: reports.where((r) => r.category == category).length / total,
              minHeight: 9,
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 10),
          const Text('Indicadores demonstrativos. Não representam estatísticas do poder público.',
              style: TextStyle(fontSize: 12)),
        ]);
      },
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Metric({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 165,
    child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Icon(icon), const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        Text(label)],
    ))),
  );
}
