import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

// DEVELOPED BY MARCELO GLASBERG 2018.
// See: https://stackoverflow.com/questions/51736663/in-flutter-how-can-i-change-some-widget-and-see-it-animate-to-its-new-size/

/// A widget that does a fade and size transition between a "new" widget and the "old "widget
/// previously set as a child. The "old" and the "new" child must have the same width,
/// but can have different heights.
///
/// You can also define a duration and curve for both the fade and the size, separately.
///
/// Important: If the "new" child is the same widget type as the "old" child, but with different
/// parameters, then [AnimatedSizeAndFade] will NOT do a transition between them, since as far as
/// the framework is concerned, they are the same widget, and the existing widget can be updated
/// with the new parameters. To force the transition to occur, set a [Key] (typically a [ValueKey]
/// taking any widget data that would change the visual appearance of the widget) on each child
/// widget that you wish to be considered unique.
///
/// ## Use it like this:
///
/// ```
/// bool toggle=true;
/// Widget widget1 = ...;
/// Widget widget2 = ...;
/// AnimatedSizeAndFade(vsync: this, child: toggle ? widget1 : widget2)
/// ```
///
/// ## How does AnimatedSizeAndFade compare to other similar widgets?
///
/// - With AnimatedCrossFade you must keep both the firstChild and secondChild, which is not
/// necessary with AnimatedSizeAndFade.
///
/// - With AnimatedSwitcher you may simply change its child, but then it only animates
/// the fade, not the size.
///
/// - AnimatedContainer also doesn't work unless you know the size of the children in advance.
///
class AnimatedSizeAndFade extends StatelessWidget {
  final Widget child;
  final TickerProvider vsync;
  final Duration fadeDuration;
  final Duration sizeDuration;
  final Curve fadeCurve;
  final Curve sizeCurve;
  final Alignment alignment;

  AnimatedSizeAndFade({
    Key key,
    this.child,
    @required this.vsync,
    this.fadeDuration = const Duration(milliseconds: 500),
    this.sizeDuration = const Duration(milliseconds: 500),
    this.fadeCurve = Curves.easeInOut,
    this.sizeCurve = Curves.easeInOut,
    this.alignment = Alignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var animatedSize = AnimatedSize(
      vsync: vsync,
      child: AnimatedSwitcher(
        child: child,
        duration: fadeDuration,
        layoutBuilder: _layoutBuilder,
      ),
      duration: sizeDuration,
      curve: Curves.easeInOut,
    );

    return ClipPath(child: animatedSize);
  }

  Widget _layoutBuilder(Widget currentChild, List<Widget> previousChildren) {
    List<Widget> children = previousChildren;

    if (currentChild != null) {
      if (previousChildren == null || previousChildren.isEmpty)
        children = [currentChild];
      else {
        children = [
          Positioned(
            left: 0.0,
            right: 0.0,
            child: Container(
              child: previousChildren[0],
            ),
          ),
          Container(
            child: currentChild,
          ),
        ];
      }
    }

    return Stack(
      overflow: Overflow.visible,
      children: children,
      alignment: alignment,
    );
  }
}
