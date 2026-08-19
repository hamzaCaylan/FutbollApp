import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('panel can be dragged repeatedly and buttons stay clickable', (
    tester,
  ) async {
    Offset offset = Offset.zero;
    int playTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Transform.translate(
                        offset: offset,
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          color: Colors.black87,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanUpdate: (details) {
                                  setState(() => offset += details.delta);
                                },
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(
                                    Icons.drag_indicator,
                                    key: Key('handle'),
                                    size: 20,
                                  ),
                                ),
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                iconSize: 26,
                                onPressed: () => playTaps++,
                                icon: const Icon(
                                  Icons.play_circle_filled,
                                  key: Key('play'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    final handleFinder = find.byKey(const Key('handle'));

    // First drag.
    final gesture1 = await tester.startGesture(
      tester.getCenter(handleFinder),
    );
    await gesture1.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture1.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture1.up();
    await tester.pump();

    expect(offset, const Offset(60, 40));

    // Second, separate drag - this is the part the user says fails ("only
    // once"). Locate the handle again since it moved.
    final gesture2 = await tester.startGesture(
      tester.getCenter(handleFinder),
    );
    await gesture2.moveBy(const Offset(15, 10));
    await tester.pump();
    await gesture2.up();
    await tester.pump();

    expect(offset, const Offset(75, 50));

    // Play button should still be tappable after the panel has moved.
    await tester.tap(find.byKey(const Key('play')));
    await tester.pump();
    expect(playTaps, 1);
  });
}
