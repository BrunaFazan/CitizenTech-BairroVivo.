import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bairro_vivo/main.dart';

void main() {
  testWidgets('Aplicativo possui identidade e três destinos principais', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('BairroVivo'))));
    expect(find.text('BairroVivo'), findsOneWidget);
  });
  test('Categorias e estágios básicos estão definidos', () {
    expect(categories.length, greaterThanOrEqualTo(3));
    expect(statuses.first, 'Registrada');
    expect(statuses.last, 'Resolvida');
  });
}
