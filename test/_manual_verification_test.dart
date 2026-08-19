import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fc_manager_plan/main.dart';

void main() {
  testWidgets('the "..." button collapses the panel to the left rail width instead of hiding it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Diziliş'));
    await tester.pumpAndSettle();

    final sidePanel = find.byKey(const Key('pitch-side-panel'));
    expect(tester.getSize(sidePanel).width, 210);

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    // Still visible (not closed), but now the same width as the left rail.
    expect(sidePanel, findsOneWidget);
    expect(tester.getSize(sidePanel).width, 96);
    // The "Diziliş" section header is dropped in compact mode (no room).
    expect(
      find.descendant(of: sidePanel, matching: find.text('Diziliş')),
      findsNothing,
    );
    expect(
      find.descendant(of: sidePanel, matching: find.text('4-3-3')),
      findsOneWidget,
    );

    // Expanding back restores the full labeled list (with header) at 210px.
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    expect(tester.getSize(sidePanel).width, 210);
    expect(
      find.descendant(of: sidePanel, matching: find.text('Diziliş')),
      findsOneWidget,
    );

    // Same collapse behavior for the Taktikler and Araçlar panels.
    await tester.tap(find.text('Taktikler').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    expect(tester.getSize(sidePanel).width, 96);
    expect(
      find.descendant(of: sidePanel, matching: find.text('Tekli Ok')),
      findsNothing,
    );
  });
}