import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sizeDuration = Duration(milliseconds: 200);

Widget _host({
  double height = 100,
  Object childKey = 'child',
  bool? show,
  VoidCallback? onEnd,
  Duration fadeDuration = const Duration(milliseconds: 100),
  Duration sizeDuration = _sizeDuration,
}) {
  final child = SizedBox(
    key: ValueKey(childKey),
    width: 100,
    height: height,
  );
  final animation = show == null
      ? AnimatedSizeAndFade(
          child: child,
          onEnd: onEnd,
          fadeDuration: fadeDuration,
          sizeDuration: sizeDuration,
          sizeCurve: Curves.linear,
        )
      : AnimatedSizeAndFade.showHide(
          show: show,
          child: child,
          onEnd: onEnd,
          fadeDuration: fadeDuration,
          sizeDuration: sizeDuration,
          sizeCurve: Curves.linear,
        );
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: SizedBox(width: 100, child: animation)),
  );
}

double _height(WidgetTester tester) =>
    tester.getSize(find.byType(AnimatedSize)).height;

Future<void> _startClock(WidgetTester tester) => tester.pump();

void main() {
  testWidgets('initial layout and unchanged rebuild do not call onEnd',
      (tester) async {
    var calls = 0;
    void onEnd() => calls++;
    await tester.pumpWidget(_host(onEnd: onEnd));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_host(onEnd: onEnd));
    await tester.pumpAndSettle();
    expect(calls, 0);
  });

  testWidgets(
      'calls once per completed size change, including same-key updates',
      (tester) async {
    var calls = 0;
    void onEnd() => calls++;
    await tester.pumpWidget(_host(onEnd: onEnd));
    await tester.pumpWidget(_host(height: 200, onEnd: onEnd));
    await _startClock(tester);
    await tester.pump(const Duration(milliseconds: 199));
    expect(calls, 0);
    expect(_height(tester), lessThan(200));
    await tester.pump(const Duration(milliseconds: 11));
    expect(calls, 1);
    expect(_height(tester), 200);
    await tester.pumpAndSettle();
    expect(calls, 1);
    await tester.pumpWidget(_host(height: 50, onEnd: onEnd));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(_height(tester), 50);
  });

  testWidgets('showHide calls once for hiding and once for showing',
      (tester) async {
    var calls = 0;
    void onEnd() => calls++;
    await tester.pumpWidget(_host(show: true, onEnd: onEnd));
    await tester.pumpWidget(_host(show: false, onEnd: onEnd));
    await _startClock(tester);
    await tester.pump(const Duration(milliseconds: 199));
    expect(calls, 0);
    await tester.pump(const Duration(milliseconds: 11));
    expect(calls, 1);
    expect(_height(tester), 0);
    await tester.pumpWidget(_host(show: true, onEnd: onEnd));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(_height(tester), 100);
  });

  testWidgets(
      'equal-size replacements do not add callbacks after a completed resize',
      (tester) async {
    var calls = 0;
    void onEnd() => calls++;
    await tester
        .pumpWidget(_host(height: 50, childKey: 'initial', onEnd: onEnd));
    await tester.pumpWidget(_host(childKey: 'first', onEnd: onEnd));
    await tester.pumpAndSettle();
    expect(calls, 1);
    await tester.pumpWidget(_host(childKey: 'second', onEnd: onEnd));
    await _startClock(tester);
    expect(find.byType(FadeTransition), findsNWidgets(2));
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('completion follows size duration when fade lasts longer',
      (tester) async {
    var calls = 0;
    void onEnd() => calls++;
    const fadeDuration = Duration(milliseconds: 600);
    await tester.pumpWidget(_host(onEnd: onEnd, fadeDuration: fadeDuration));
    await tester.pumpWidget(_host(
      height: 200,
      childKey: 'second',
      onEnd: onEnd,
      fadeDuration: fadeDuration,
    ));
    await _startClock(tester);
    await tester.pump(const Duration(milliseconds: 210));
    expect(calls, 1);
    expect(_height(tester), 200);
    final fade =
        tester.widget<FadeTransition>(find.byType(FadeTransition).last);
    expect(fade.opacity.value, lessThan(1));
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('shorter fade does not call onEnd before size completes',
      (tester) async {
    var calls = 0;
    void onEnd() => calls++;
    await tester.pumpWidget(_host(onEnd: onEnd));
    await tester.pumpWidget(_host(
      height: 200,
      childKey: 'second',
      onEnd: onEnd,
    ));
    await _startClock(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(calls, 0);
    expect(_height(tester), lessThan(200));
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('interrupted resize completes only the replacement animation',
      (tester) async {
    var calls = 0;
    void onEnd() => calls++;
    await tester.pumpWidget(_host(onEnd: onEnd));
    await tester.pumpWidget(_host(height: 200, onEnd: onEnd));
    await _startClock(tester);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(_host(height: 50, onEnd: onEnd));
    await _startClock(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(calls, 0);
    await tester.pump(const Duration(milliseconds: 110));
    expect(calls, 1);
    expect(_height(tester), 50);
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('rebuild uses the latest callback without restarting size',
      (tester) async {
    var oldCalls = 0;
    var newCalls = 0;
    await tester.pumpWidget(_host(onEnd: () => oldCalls++));
    await tester.pumpWidget(_host(height: 200, onEnd: () => oldCalls++));
    await _startClock(tester);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(_host(height: 200, onEnd: () => newCalls++));
    await tester.pump(const Duration(milliseconds: 110));
    expect(oldCalls, 0);
    expect(newCalls, 1);
  });

  testWidgets(
      'reversing showHide mid-animation calls only the final completion',
      (tester) async {
    var calls = 0;
    void onEnd() => calls++;
    await tester.pumpWidget(_host(show: true, onEnd: onEnd));
    await tester.pumpWidget(_host(show: false, onEnd: onEnd));
    await _startClock(tester);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(_host(show: true, onEnd: onEnd));
    await _startClock(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(calls, 0);
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(_height(tester), 100);
  });

  testWidgets('onEnd can call setState to start another resize',
      (tester) async {
    var height = 100.0;
    var calls = 0;
    late StateSetter update;
    await tester.pumpWidget(StatefulBuilder(builder: (context, setState) {
      update = setState;
      return _host(
        height: height,
        onEnd: () {
          calls++;
          if (calls == 1) {
            setState(() => height = 50);
          }
        },
      );
    }));
    update(() => height = 200);
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(_height(tester), 50);
    expect(tester.takeException(), isNull);
  });

  testWidgets('callback can be removed during an animation', (tester) async {
    var calls = 0;
    await tester.pumpWidget(_host(onEnd: () => calls++));
    await tester.pumpWidget(_host(height: 200, onEnd: () => calls++));
    await _startClock(tester);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(_host(height: 200));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(_height(tester), 200);
  });

  testWidgets('disposing during animation prevents a later callback',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(_host(onEnd: () => calls++));
    await tester.pumpWidget(_host(height: 200, onEnd: () => calls++));
    await _startClock(tester);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 0);
    expect(tester.takeException(), isNull);
  });
}
