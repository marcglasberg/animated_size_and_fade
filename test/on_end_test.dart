import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({
  double? height = 100,
  Object childKey = 'a',
  bool? show,
  Widget? content,
  List<String>? events,
  VoidCallback? onFadeEnd,
  VoidCallback? onSizeEnd,
  VoidCallback? onEnd,
  Duration fadeDuration = const Duration(milliseconds: 100),
  Duration sizeDuration = const Duration(milliseconds: 200),
  Curve fadeInCurve = Curves.linear,
  Curve fadeOutCurve = Curves.linear,
  Curve sizeCurve = Curves.linear,
  Alignment alignment = Alignment.center,
  Clip clipBehavior = Clip.hardEdge,
  bool tickerEnabled = true,
}) {
  final child = content ??
      (height == null
          ? null
          : SizedBox(
              key: ValueKey(childKey),
              width: 100,
              height: height,
            ));
  final fadeEnd =
      onFadeEnd ?? (events == null ? null : () => events.add('fade'));
  final sizeEnd =
      onSizeEnd ?? (events == null ? null : () => events.add('size'));
  final end = onEnd ?? (events == null ? null : () => events.add('end'));
  final animation = show == null
      ? AnimatedSizeAndFade(
          child: child,
          onFadeEnd: fadeEnd,
          onSizeEnd: sizeEnd,
          onEnd: end,
          fadeDuration: fadeDuration,
          sizeDuration: sizeDuration,
          fadeInCurve: fadeInCurve,
          fadeOutCurve: fadeOutCurve,
          sizeCurve: sizeCurve,
          alignment: alignment,
          clipBehavior: clipBehavior,
        )
      : AnimatedSizeAndFade.showHide(
          show: show,
          child: child,
          onFadeEnd: fadeEnd,
          onSizeEnd: sizeEnd,
          onEnd: end,
          fadeDuration: fadeDuration,
          sizeDuration: sizeDuration,
          fadeInCurve: fadeInCurve,
          fadeOutCurve: fadeOutCurve,
          sizeCurve: sizeCurve,
          alignment: alignment,
          clipBehavior: clipBehavior,
        );
  return Directionality(
    textDirection: TextDirection.ltr,
    child: TickerMode(
        enabled: tickerEnabled,
        child: Center(child: SizedBox(width: 100, child: animation))),
  );
}

double _height(WidgetTester tester) =>
    tester.getSize(find.byType(AnimatedSizeAndFade)).height;

Future<void> _advance(WidgetTester tester, int milliseconds) async {
  await tester.pump(); // Establish the animation clock before advancing it.
  await tester.pump(Duration(milliseconds: milliseconds));
}

void main() {
  testWidgets('rapid equal-size replacements never report a resize',
      (tester) async {
    final events = <String>[];
    const size = Duration(milliseconds: 500);
    await tester.pumpWidget(_host(events: events, sizeDuration: size));
    await tester
        .pumpWidget(_host(childKey: 'b', events: events, sizeDuration: size));
    await _advance(tester, 20);
    await tester
        .pumpWidget(_host(childKey: 'c', events: events, sizeDuration: size));
    await tester.pumpAndSettle();
    expect(events, ['fade', 'end']);
  });

  testWidgets('muted tickers do not report completion before resuming',
      (tester) async {
    final events = <String>[];
    const duration = Duration(milliseconds: 400);
    await tester.pumpWidget(_host(events: events, fadeDuration: duration));
    await tester.pumpWidget(_host(
        height: 200, childKey: 'b', events: events, fadeDuration: duration));
    await _advance(tester, 50);
    await tester.pumpWidget(_host(
        height: 200,
        childKey: 'b',
        events: events,
        fadeDuration: duration,
        tickerEnabled: false));
    await tester.pump(const Duration(seconds: 1));
    expect(events, isEmpty);
    await tester.pumpWidget(_host(
        height: 200, childKey: 'b', events: events, fadeDuration: duration));
    await tester.pumpAndSettle();
    expect(events.where((event) => event == 'end'), hasLength(1));
    expect(events.last, 'end');
  });

  testWidgets(
      'adding a callback after its component finished does not replay it',
      (tester) async {
    final events = <String>[];
    await tester.pumpWidget(_host());
    await tester.pumpWidget(_host(height: 200, childKey: 'b'));
    await _advance(tester, 110);
    await tester.pumpWidget(_host(height: 200, childKey: 'b', events: events));
    await tester.pumpAndSettle();
    expect(events, ['size', 'end']);
  });

  testWidgets('initial layout and no-op rebuilds stay silent', (tester) async {
    final events = <String>[];
    await tester.pumpWidget(_host(events: events));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_host(events: events));
    await tester.pumpAndSettle();
    expect(events, isEmpty);
  });

  testWidgets('short fade finishes before size and combined completion',
      (tester) async {
    final events = <String>[];
    await tester.pumpWidget(_host(events: events));
    await tester.pumpWidget(_host(height: 200, childKey: 'b', events: events));
    await _advance(tester, 110);
    expect(events, ['fade']);
    expect(_height(tester), lessThan(200));
    await tester.pumpAndSettle();
    expect(events, ['fade', 'size', 'end']);
    expect(_height(tester), 200);
  });

  testWidgets('long fade keeps combined completion waiting after size',
      (tester) async {
    final events = <String>[];
    const fade = Duration(milliseconds: 600);
    await tester.pumpWidget(_host(events: events, fadeDuration: fade));
    await tester.pumpWidget(
        _host(height: 200, childKey: 'b', events: events, fadeDuration: fade));
    await _advance(tester, 210);
    expect(events, ['size']);
    expect(_height(tester), 200);
    final incoming =
        tester.widget<FadeTransition>(find.byType(FadeTransition).last);
    expect(incoming.opacity.value, lessThan(1));
    await tester.pumpAndSettle();
    expect(events, ['size', 'fade', 'end']);
  });

  testWidgets('equal durations report each component once then combined',
      (tester) async {
    final events = <String>[];
    const duration = Duration(milliseconds: 200);
    await tester.pumpWidget(_host(events: events, fadeDuration: duration));
    await tester.pumpWidget(_host(
        height: 200, childKey: 'b', events: events, fadeDuration: duration));
    await tester.pumpAndSettle();
    expect(events, ['fade', 'size', 'end']);
    await tester.pump(const Duration(seconds: 1));
    expect(events, ['fade', 'size', 'end']);
  });

  testWidgets('equal-size replacements report fade and combined only',
      (tester) async {
    final events = <String>[];
    await tester.pumpWidget(_host(events: events));
    await tester.pumpWidget(_host(childKey: 'b', events: events));
    await tester.pumpAndSettle();
    expect(events, ['fade', 'end']);
    await tester.pumpWidget(_host(childKey: 'c', events: events));
    await tester.pumpAndSettle();
    expect(events, ['fade', 'end', 'fade', 'end']);
  });

  testWidgets('same-key height updates report size and combined only',
      (tester) async {
    final events = <String>[];
    await tester.pumpWidget(_host(events: events));
    await tester.pumpWidget(_host(height: 200, events: events));
    await tester.pumpAndSettle();
    expect(events, ['size', 'end']);
    await tester.pumpWidget(_host(height: 50, events: events));
    await tester.pumpAndSettle();
    expect(events, ['size', 'end', 'size', 'end']);
  });

  testWidgets('showHide reports all callbacks on hide and show',
      (tester) async {
    final events = <String>[];
    await tester.pumpWidget(_host(show: true, events: events));
    await tester.pumpWidget(_host(show: false, events: events));
    await tester.pumpAndSettle();
    expect(events, ['fade', 'size', 'end']);
    expect(_height(tester), 0);
    await tester.pumpWidget(_host(show: true, events: events));
    await tester.pumpAndSettle();
    expect(events, ['fade', 'size', 'end', 'fade', 'size', 'end']);
    expect(_height(tester), 100);
  });

  testWidgets('hidden-child updates do not start a transition', (tester) async {
    final events = <String>[];
    await tester.pumpWidget(_host(show: false, events: events));
    await tester.pumpWidget(
        _host(show: false, height: 200, childKey: 'b', events: events));
    await tester.pumpAndSettle();
    expect(events, isEmpty);
  });

  testWidgets('interrupted resize reports only the replacement completion',
      (tester) async {
    final events = <String>[];
    await tester.pumpWidget(_host(events: events));
    await tester.pumpWidget(_host(height: 200, events: events));
    await _advance(tester, 100);
    await tester.pumpWidget(_host(height: 50, events: events));
    await _advance(tester, 100);
    expect(events, isEmpty);
    await tester.pumpAndSettle();
    expect(events, ['size', 'end']);
    expect(_height(tester), 50);
  });

  testWidgets('interrupted fade and size do not report stale combined end',
      (tester) async {
    final events = <String>[];
    const fade = Duration(milliseconds: 600);
    await tester.pumpWidget(_host(events: events, fadeDuration: fade));
    await tester.pumpWidget(
        _host(height: 200, childKey: 'b', events: events, fadeDuration: fade));
    await _advance(tester, 100);
    await tester.pumpWidget(
        _host(height: 50, childKey: 'c', events: events, fadeDuration: fade));
    await _advance(tester, 110);
    expect(events, isEmpty);
    await tester.pumpAndSettle();
    expect(events, ['size', 'fade', 'end']);
  });

  testWidgets('rapid replacements wait for every surviving outgoing fade',
      (tester) async {
    final events = <String>[];
    const longFade = Duration(milliseconds: 600);
    const shortFade = Duration(milliseconds: 100);
    await tester.pumpWidget(_host(events: events, fadeDuration: longFade));
    await tester.pumpWidget(_host(
        height: 200, childKey: 'b', events: events, fadeDuration: longFade));
    await _advance(tester, 100);
    await tester.pumpWidget(_host(
        height: 50, childKey: 'c', events: events, fadeDuration: shortFade));
    await _advance(tester, 210);
    expect(events, ['size']);
    await tester.pumpAndSettle();
    expect(events, ['size', 'fade', 'end']);
  });

  testWidgets('showHide reversal reports the final transition once',
      (tester) async {
    final events = <String>[];
    const fade = Duration(milliseconds: 400);
    await tester
        .pumpWidget(_host(show: true, events: events, fadeDuration: fade));
    await tester
        .pumpWidget(_host(show: false, events: events, fadeDuration: fade));
    await _advance(tester, 100);
    await tester
        .pumpWidget(_host(show: true, events: events, fadeDuration: fade));
    await tester.pumpAndSettle();
    expect(events, ['size', 'fade', 'end']);
    expect(_height(tester), 100);
  });

  testWidgets('callback-only rebuilds use latest callbacks without restart',
      (tester) async {
    final oldEvents = <String>[];
    final newEvents = <String>[];
    const duration = Duration(milliseconds: 400);
    await tester.pumpWidget(_host(
        events: oldEvents, fadeDuration: duration, sizeDuration: duration));
    await tester.pumpWidget(_host(
        height: 200,
        childKey: 'b',
        events: oldEvents,
        fadeDuration: duration,
        sizeDuration: duration));
    await _advance(tester, 100);
    await tester.pumpWidget(_host(
        height: 200,
        childKey: 'b',
        events: newEvents,
        fadeDuration: duration,
        sizeDuration: duration));
    await tester.pump(const Duration(milliseconds: 310));
    await tester.pump();
    expect(oldEvents, isEmpty);
    expect(newEvents, ['fade', 'size', 'end']);
  });

  testWidgets('callbacks can be added during an animation', (tester) async {
    final events = <String>[];
    await tester.pumpWidget(_host());
    await tester.pumpWidget(_host(height: 200, childKey: 'b'));
    await _advance(tester, 50);
    await tester.pumpWidget(_host(height: 200, childKey: 'b', events: events));
    await tester.pumpAndSettle();
    expect(events, ['fade', 'size', 'end']);
  });

  testWidgets('all callbacks can be removed during an animation',
      (tester) async {
    final events = <String>[];
    await tester.pumpWidget(_host(events: events));
    await tester.pumpWidget(_host(height: 200, childKey: 'b', events: events));
    await _advance(tester, 50);
    await tester.pumpWidget(_host(height: 200, childKey: 'b'));
    await tester.pumpAndSettle();
    expect(events, isEmpty);
    expect(_height(tester), 200);
  });

  for (final zero in ['fade', 'size', 'both']) {
    testWidgets('zero-duration $zero still reports changed components',
        (tester) async {
      final events = <String>[];
      final fade =
          zero == 'size' ? const Duration(milliseconds: 100) : Duration.zero;
      final size =
          zero == 'fade' ? const Duration(milliseconds: 200) : Duration.zero;
      await tester.pumpWidget(
          _host(events: events, fadeDuration: fade, sizeDuration: size));
      await tester.pumpAndSettle();
      expect(events, isEmpty);
      await tester.pumpWidget(_host(
          height: 200,
          childKey: 'b',
          events: events,
          fadeDuration: fade,
          sizeDuration: size));
      await tester.pumpAndSettle();
      expect(events,
          zero == 'size' ? ['size', 'fade', 'end'] : ['fade', 'size', 'end']);
      expect(_height(tester), 200);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('zero-duration equal-size replacement has no size callback',
      (tester) async {
    final events = <String>[];
    await tester.pumpWidget(_host(
        events: events,
        fadeDuration: Duration.zero,
        sizeDuration: Duration.zero));
    await tester.pumpWidget(_host(
        childKey: 'b',
        events: events,
        fadeDuration: Duration.zero,
        sizeDuration: Duration.zero));
    await tester.pumpAndSettle();
    expect(events, ['fade', 'end']);
  });

  testWidgets('changing size duration to zero preserves an ongoing fade',
      (tester) async {
    final events = <String>[];
    const fade = Duration(milliseconds: 400);
    await tester.pumpWidget(_host(events: events, fadeDuration: fade));
    await tester.pumpWidget(
        _host(height: 200, childKey: 'b', events: events, fadeDuration: fade));
    await _advance(tester, 50);
    await tester.pumpWidget(_host(
        height: 200,
        childKey: 'b',
        events: events,
        fadeDuration: fade,
        sizeDuration: Duration.zero));
    expect(events, ['size']);
    await tester.pumpAndSettle();
    expect(events, ['size', 'fade', 'end']);
  });

  testWidgets(
      'null-child removal waits for fade then the resulting size change',
      (tester) async {
    final events = <String>[];
    await tester.pumpWidget(_host(events: events));
    await tester.pumpWidget(_host(height: null, events: events));
    await _advance(tester, 110);
    expect(events, ['fade']);
    await tester.pumpAndSettle();
    expect(events, ['fade', 'size', 'end']);
    await tester.pumpWidget(_host(height: 50, events: events));
    await tester.pumpAndSettle();
    expect(events.where((event) => event == 'end'), hasLength(2));
  });

  testWidgets('null initial child and unchanged null rebuild stay silent',
      (tester) async {
    final events = <String>[];
    await tester.pumpWidget(_host(height: null, events: events));
    await tester.pumpWidget(_host(height: null, events: events));
    await tester.pumpAndSettle();
    expect(events, isEmpty);
  });

  testWidgets('internal child-size changes are observed without parent rebuild',
      (tester) async {
    final events = <String>[];
    final height = ValueNotifier(100.0);
    final child = ValueListenableBuilder<double>(
        valueListenable: height,
        builder: (context, value, _) => SizedBox(width: 100, height: value));
    await tester.pumpWidget(_host(content: child, events: events));
    height.value = 200;
    await tester.pumpAndSettle();
    expect(events, ['size', 'end']);
    height.dispose();
  });

  testWidgets('onEnd can call setState to start the next resize',
      (tester) async {
    var height = 100.0;
    var ends = 0;
    late StateSetter update;
    await tester.pumpWidget(StatefulBuilder(builder: (context, setState) {
      update = setState;
      return _host(
          height: height,
          onEnd: () {
            ends++;
            if (ends == 1) setState(() => height = 50);
          });
    }));
    update(() => height = 200);
    await tester.pumpAndSettle();
    expect(ends, 2);
    expect(_height(tester), 50);
  });

  testWidgets(
      'component callback setState supersedes pending combined completion',
      (tester) async {
    final events = <String>[];
    var key = 'a';
    late StateSetter update;
    await tester.pumpWidget(StatefulBuilder(builder: (context, setState) {
      update = setState;
      return _host(
          childKey: key,
          events: events,
          onFadeEnd: () {
            events.add('fade');
            if (key == 'b') setState(() => key = 'c');
          });
    }));
    update(() => key = 'b');
    await tester.pumpAndSettle();
    expect(events, ['fade', 'fade', 'end']);
  });

  testWidgets('component callback can remove widget before combined completion',
      (tester) async {
    final events = <String>[];
    var height = 100.0;
    var removed = false;
    late StateSetter update;
    await tester.pumpWidget(StatefulBuilder(builder: (context, setState) {
      update = setState;
      return removed
          ? const SizedBox.shrink()
          : _host(
              height: height,
              events: events,
              onSizeEnd: () {
                events.add('size');
                setState(() => removed = true);
              });
    }));
    update(() => height = 200);
    await tester.pumpAndSettle();
    expect(events, ['size']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposal during animations prevents later callbacks',
      (tester) async {
    final events = <String>[];
    await tester.pumpWidget(_host(events: events));
    await tester.pumpWidget(_host(height: 200, childKey: 'b', events: events));
    await _advance(tester, 50);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(events, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('early curve endpoint does not finish fade early',
      (tester) async {
    final events = <String>[];
    const curve = Interval(0, 0.1);
    const duration = Duration(milliseconds: 400);
    await tester.pumpWidget(
        _host(events: events, fadeDuration: duration, fadeInCurve: curve));
    await tester.pumpWidget(_host(
        childKey: 'b',
        events: events,
        fadeDuration: duration,
        fadeInCurve: curve));
    await _advance(tester, 100);
    expect(events, isEmpty);
    await tester.pumpAndSettle();
    expect(events, ['fade', 'end']);
  });

  testWidgets('curves alignment and clipping remain configurable',
      (tester) async {
    const fadeIn = Curves.easeIn;
    const fadeOut = Curves.easeOut;
    const size = Curves.bounceOut;
    await tester.pumpWidget(_host(
        fadeInCurve: fadeIn,
        fadeOutCurve: fadeOut,
        sizeCurve: size,
        alignment: Alignment.topLeft,
        clipBehavior: Clip.none));
    final switcher =
        tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher));
    final animatedSize = tester.widget<AnimatedSize>(find.byType(AnimatedSize));
    expect(switcher.switchInCurve, same(fadeIn));
    expect(switcher.switchOutCurve, same(fadeOut));
    expect(animatedSize.curve, same(size));
    expect(animatedSize.clipBehavior, Clip.none);
    expect(
        tester.widget<Stack>(find.byType(Stack)).alignment, Alignment.topLeft);
    expect(tester.widget<ClipRect>(find.byType(ClipRect).first).clipBehavior,
        Clip.none);
  });
}
