import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:benta_lacos/shared/widgets/product_form.dart';
import 'package:flutter/material.dart';
import 'package:benta_lacos/pages/admin/pedidos/admin_order_list.dart';
import 'package:benta_lacos/pages/admin/widgets/admin_catalog_summary.dart';
import 'package:benta_lacos/pages/admin/widgets/admin_access_view.dart';
import 'package:benta_lacos/core/pdf/admin_report_pdf.dart';
import 'package:benta_lacos/core/pdf/admin_inventory_pdf.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:benta_lacos/domain/services/admin_metrics.dart';
import 'package:benta_lacos/domain/services/order_policy.dart';
import 'package:benta_lacos/domain/models/product_model.dart';
import 'package:benta_lacos/pages/admin/widgets/admin_ui.dart';
import 'package:benta_lacos/pages/admin/dashboard/admin_overview.dart';
import 'package:benta_lacos/shared/theme/tema_site.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Montserrat',
    )..addFont(rootBundle.load('assets/fonts/Montserrat.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  Map<String, dynamic> order(
    String status,
    double total, {
    int quantity = 1,
    DateTime? date,
    bool archived = false,
  }) => {
    'status': status,
    'total': total,
    'arquivado': archived,
    'dataPedido': Timestamp.fromDate(date ?? DateTime(2026, 10, 8)),
    'metodoPagamento': 'Cartão (crédito ou débito)',
    'itens': [
      {'nome': 'Laço floral', 'quantidade': quantity},
    ],
  };
  test(
    'reports exclude pending and canceled sales and sum units rather than lines',
    () {
      final m = AdminMetrics.fromOrders([
        order('Pago', 100, quantity: 3),
        order('Enviado', 50, quantity: 2),
        order('Entregue', 20, quantity: 4, archived: true),
        order('Pendente', 80, quantity: 8),
        order('Cancelado', 90, quantity: 9),
        order('Excluido', 120, quantity: 7),
      ]);
      expect(m.revenue, 170);
      expect(m.confirmed.length, 3);
      expect(m.units, 9);
      expect(m.pendingValue, 80);
      expect(m.products['Laço floral'], 9);
      expect(m.fees, 0);
      expect(m.daily.values.single, 170);
    },
  );
  test(
    'one period applies to revenue, units, payments, chart and pending totals',
    () {
      final m = AdminMetrics.fromOrders(
        [
          order('Pago', 100, quantity: 3, date: DateTime(2026, 10, 8, 23, 59)),
          order('Pago', 200, quantity: 4, date: DateTime(2026, 10, 9)),
          order('Pendente', 30, date: DateTime(2026, 10, 8)),
          order('Pendente', 80, date: DateTime(2026, 10, 7)),
          {'status': 'Pago', 'total': 500},
        ],
        start: DateTime(2026, 10, 8),
        end: DateTime(2026, 10, 8),
      );
      expect(m.orders.length, 2);
      expect(m.revenue, 100);
      expect(m.units, 3);
      expect(m.pendingValue, 30);
      expect(m.payments.values.single, 100);
      expect(m.daily.values.single, 100);
    },
  );
  test(
    'generic card does not become debit; confirmed method takes precedence',
    () {
      expect(paymentCategory('Cartão'), 'Cartão a confirmar');
      expect(
        paymentCategory('Cartão (crédito ou débito)'),
        'Cartão a confirmar',
      );
      final m = AdminMetrics.fromOrders([
        {...order('Pago', 100), 'pagamentoConfirmado': 'Débito', 'taxas': 2.5},
        {...order('Pendente', 80), 'metodoPagamento': 'Cartão'},
      ]);
      expect(m.payments, {'Débito': 100});
      expect(m.preferences, {'Cartão a confirmar': 1});
      expect(m.fees, 2.5);
    },
  );
  test(
    'shipping requires payment; payment requires freight and actual method',
    () {
      expect(
        () => validateOrderTransition({'status': 'Pendente'}, 'Enviado'),
        throwsStateError,
      );
      expect(
        () => validateOrderTransition(
          {'status': 'Pendente', 'freteACombinar': true},
          'Pago',
          paymentMethod: 'Pix',
        ),
        throwsStateError,
      );
      expect(
        () => validateOrderTransition(
          {'status': 'Pendente'},
          'Pago',
          paymentMethod: 'Cartão',
        ),
        throwsStateError,
      );
      validateOrderTransition(
        {'status': 'Pendente', 'freteACombinar': false},
        'Pago',
        paymentMethod: 'Crédito',
      );
      validateOrderTransition({'status': 'Pago'}, 'Enviado');
      validateOrderTransition({'status': 'Enviado'}, 'Entregue');
      expect(
        () => validateOrderTransition(
          {'status': 'Cancelado'},
          'Pago',
          paymentMethod: 'Pix',
        ),
        throwsStateError,
      );
    },
  );
  test('product archival is reversible and preserves catalog metadata', () {
    final p = Product.fromMap({
      'name': 'Laço',
      'price': 20,
      'quantity': 3,
      'views': 15,
      'oldPrice': 25.0,
      'discountPix': 5.0,
      'galleryUrls': ['https://example.com/photo.png'],
    }, 'p1');
    expect(p.isArchived, false);
    final next = p.copyWith(isArchived: true, description: 'Atualizada');
    expect(next.id, p.id);
    expect(next.views, 15);
    expect(next.oldPrice, 25);
    expect(next.discountPix, 5);
    expect(next.galleryUrls, p.galleryUrls);
    expect(Product.fromMap(next.toMap(), 'p1').isArchived, true);
  });
  test(
    'reports and inventory generate multiple PDF pages for a large selection',
    () async {
      final orders = List.generate(
        160,
        (i) => {
          ...order('Pago', 20, quantity: 3),
          'pedidoId': 'pedido-$i',
          'nomeCliente': 'Cliente de teste $i',
        },
      );
      final bytes = await AdminReportPdf.build(
        orders,
        period: 'Período de teste',
      );
      final raw = latin1.decode(bytes);
      expect(raw.startsWith('%PDF'), isTrue);
      expect(RegExp(r'/Type\s*/Page\b').allMatches(raw).length, greaterThan(1));
      final products = List.generate(
        160,
        (i) => Product(
          id: 'p$i',
          name: 'Laço floral $i',
          price: 20,
          quantity: 3,
          description: '',
          color: '',
          composition: '',
          category: 'Laços',
        ),
      );
      final inventory = latin1.decode(await AdminInventoryPdf.build(products));
      expect(inventory.startsWith('%PDF'), isTrue);
      expect(
        RegExp(r'/Type\s*/Page\b').allMatches(inventory).length,
        greaterThan(1),
      );
    },
  );
  for (final width in [375.0, 1440.0]) {
    testWidgets('populated admin layout preview at $width pixels', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final now = DateTime.now();
      final p = Product(
        id: 'fixture',
        name: 'Laço floral de demonstração',
        price: 29.9,
        quantity: 3,
        description: '',
        color: 'Rosa',
        composition: 'Gorgurão',
        category: 'Laços',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: TemaSite.tema,
          home: RepaintBoundary(
            key: const ValueKey('admin-preview'),
            child: AdminLayout(
              selected: 0,
              onSelect: (_) {},
              onStore: () {},
              onLogout: () {},
              child: AdminOverviewContent(
                orders: [
                  {
                    ...order('Pendente', 59.8, date: now),
                    'pedidoId': 'Demonstração 001',
                    'nomeCliente': 'Cliente de demonstração',
                  },
                  {
                    ...order('Pago', 89.7, date: now),
                    'pedidoId': 'Demonstração 002',
                    'nomeCliente': 'Cliente de demonstração',
                  },
                ],
                products: [p],
                onOpen: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('admin-preview')),
        );
        final img = await boundary.toImage();
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        await Directory('artifacts').create(recursive: true);
        await File(
          'artifacts/admin-layout-${width.toInt()}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        img.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('editing a legacy product with a custom category fits mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final p = Product(
      id: 'existing',
      name: 'Produto legado',
      price: 20,
      quantity: 3,
      description: 'Descrição',
      color: 'Rosa',
      composition: 'Fita',
      category: 'Categoria personalizada',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaSite.tema,
        home: Scaffold(
          body: ProductForm(product: p, onSave: (_) async {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Categoria personalizada'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('dashboard pending shortcut opens the pending order filter', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaSite.tema,
        home: Scaffold(
          body: AdminOverviewContent(
            orders: [],
            products: [],
            onOpen: (_) {},
            onOpenOrders: (v) => selected = v,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final metric = find.widgetWithText(AdminMetric, 'Pedidos pendentes');
    await tester.ensureVisible(metric);
    await tester.tap(metric);
    await tester.pumpAndSettle();
    expect(selected, 'Pendente');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'inventory summary excludes archived units and indicates unavailable data',
    (tester) async {
      final products = [
        Product(
          id: 'one',
          name: 'Laço',
          price: 20,
          quantity: 3,
          description: '',
          color: '',
          composition: '',
        ),
        Product(
          id: 'two',
          name: 'Tiara',
          price: 10,
          quantity: 10,
          description: '',
          color: '',
          composition: '',
        ),
        Product(
          id: 'old',
          name: 'Arquivado',
          price: 100,
          quantity: 99,
          isArchived: true,
          description: '',
          color: '',
          composition: '',
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminCatalogSummary(products: products, stock: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final metrics = tester
          .widgetList<AdminMetric>(find.byType(AdminMetric))
          .toList();
      expect(metrics.first.value, '13');
      expect(metrics[1].value, '0');
      expect(metrics[2].value, '1');
      expect(metrics[3].value.replaceAll('\u00a0', ' '), 'R\$ 160,00');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminCatalogSummary(
                products: products,
                stock: true,
                unavailable: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<AdminMetric>(find.byType(AdminMetric))
            .every((m) => m.value == '—'),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final width in [320.0, 1440.0]) {
    testWidgets('order list opens the complete order ID at $width pixels', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? opened;
      await tester.pumpWidget(
        MaterialApp(
          theme: TemaSite.tema,
          home: AdminLayout(
            selected: 1,
            onSelect: (_) {},
            onStore: () {},
            onLogout: () {},
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: AdminOrderList(
                orders: [
                  {
                    ...order('Pendente', 90),
                    'pedidoId': 'complete-order-id-123456789',
                    'nomeCliente': 'Cliente de teste',
                  },
                ],
                onOpen: (id) => opened = id,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cliente de teste'));
      await tester.pumpAndSettle();
      expect(opened, 'complete-order-id-123456789');
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('administration access page fits mobile and opens login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    bool login = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaSite.tema,
        home: AdminAccessView(
          message: 'Entre com uma conta administradora para acessar o painel.',
          onStore: () {},
          onLogin: () => login = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Entrar na administração'));
    expect(login, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final width in [320.0, 375.0, 768.0, 1440.0]) {
    testWidgets('admin overview fits $width pixels and navigation works', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      int selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: TemaSite.tema,
          home: StatefulBuilder(
            builder: (context, setState) => AdminLayout(
              selected: selected,
              onSelect: (v) => setState(() => selected = v),
              onStore: () {},
              onLogout: () {},
              child: AdminOverviewContent(
                orders: [],
                products: [],
                onOpen: (v) => setState(() => selected = v),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (width < 1000) {
        await tester.tap(find.byTooltip('Open navigation menu'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Produtos').first);
      await tester.pumpAndSettle();
      expect(selected, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
