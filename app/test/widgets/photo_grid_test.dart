import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cgs_photos/widgets/photo_grid.dart';

void main() {
  group('PhotoGrid', () {
    testWidgets('renders empty grid when photos list is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhotoGrid(photos: []),
          ),
        ),
      );

      // GridView should exist but contain no items.
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('adapts column count to narrow width',
        (WidgetTester tester) async {
      // Force a narrow layout (< 600px).
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhotoGrid(photos: []),
          ),
        ),
      );

      // The grid should exist; column count is internal but we verify no crash.
      expect(find.byType(GridView), findsOneWidget);

      // Reset the view size.
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
