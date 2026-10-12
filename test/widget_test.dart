import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:benta_lacos/domain/models/product_model.dart';
import 'package:benta_lacos/domain/services/stock_policy.dart';
import 'package:benta_lacos/shared/constants/card.dart';
import 'package:benta_lacos/shared/sections/carousel/carrossel_principal.dart';
import 'package:benta_lacos/shared/theme/tema_site.dart';
import 'package:benta_lacos/shared/utils/store_format.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Montserrat')
      ..addFont(rootBundle.load('assets/fonts/Montserrat.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  test('prices use Brazilian decimal and thousands separators', () {
    expect(formatMoney(1234.5).replaceAll('\u00a0', ' '), 'R\$ 1.234,50');
  });
  test('WhatsApp numbers include country code once, including DDD 55', () {
    expect(whatsappPhone('(54) 99926-4865'), '5554999264865');
    expect(whatsappPhone('+55 54 99926-4865'), '5554999264865');
    expect(whatsappPhone('(55) 99999-9999'), '5555999999999');
  });
  test('search matches accented names and categories', () {
    expect(normalizeSearch('  LAÇOS ROSÉ  '), 'lacos rose');
  });
  test('pending requests never deduct stock', () {
    expect(stockDirection(deducted: false, status: 'Pendente'), 0);
  });
  test('payment confirmation deducts once, shipping does not deduct again', () {
    final stock = checkedStock(
      3,
      2,
      stockDirection(deducted: false, status: 'Pago'),
      'Laço',
    );
    expect(stock, 1);
    expect(stockDirection(deducted: true, status: 'Pago'), 0);
    expect(stockDirection(deducted: true, status: 'Enviado'), 0);
  });
  test('cancellation restores only previously deducted stock', () {
    expect(stockDirection(deducted: false, status: 'Cancelado'), 0);
    expect(
      checkedStock(
        1,
        2,
        stockDirection(deducted: true, status: 'Cancelado'),
        'Laço',
      ),
      3,
    );
    expect(stockDirection(deducted: false, status: 'Excluido'), 0);
  });
  test('stock cannot become negative or accept invalid quantities', () {
    expect(() => checkedStock(1, 2, -1, 'Laço'), throwsStateError);
    expect(() => checkedStock(5, 0, -1, 'Laço'), throwsStateError);
  });
  for (final width in [320.0, 375.0, 768.0, 1440.0]) {
    testWidgets('hero and product cards fit a $width px viewport', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      final product = Product(
        id: 'preview',
        name: 'Laço artesanal para momentos especiais',
        price: 29.9,
        description: '',
        color: 'Rosa',
        composition: 'Fita',
        quantity: 0,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: TemaSite.tema,
          home: Scaffold(
            body: SingleChildScrollView(
              child: RepaintBoundary(
                key: key,
                child: Column(
                  children: [
                    const CarrosselPrincipal(),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: width < 400 ? 150 : 260,
                        child: LacoCard(product: product),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Conhecer a coleção'), findsOneWidget);
      expect(find.text('Indisponível'), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Indisponível'),
            )
            .onPressed,
        isNull,
      );
    });
  }
}
