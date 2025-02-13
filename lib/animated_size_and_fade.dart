import 'package:flutter/material.dart';

// DEVELOPED BY MARCELO GLASBERG 2018.
// See: https://stackoverflow.com/questions/51736663/in-flutter-how-can-i-change-some-widget-and-see-it-animate-to-its-new-size/

/// The `AnimatedSizeAndFade` widget does a fade and size transition between a
/// "new" widget and an "old" widget/ previously set as a child. The "old" and
/// the "new" children must have the same width, but can have different heights,
/// and you **don't need to know** their sizes in advance. You can also define
/// a duration and curve for both the fade and the size, separately.
///
/// **Important:** If the "new" child is the same widget type as the "old"
/// child, but with different parameters, then [AnimatedSizeAndFade] will
/// **NOT** do a transition between them, since as far as the framework is
/// concerned, they are the same widget, and the existing widget can be updated
/// with the new parameters. To force the transition to occur, set a [Key]
/// (typically a [ValueKey] taking any widget data that would change the visual
/// appearance of the widget) on each child widget that you wish to be
/// considered unique.
///
/// Example:
/// ```
///  bool toggle=true;
///  Widget widget1 = ...;
///  Widget widget2 = ...;
///  AnimatedSizeAndFade(
///     child: toggle ? widget1 : widget2
///  );
/// ```
///
/// ### Show and Hide
///
/// The `AnimatedSizeAndFade.showHide` constructor may be used
/// to show/hide a widget, by resizing it vertically while fading.
///
/// Example:
/// ```
///  bool toggle=true;
///  Widget widget = ...;
///  AnimatedSizeAndFade.showHide(
///     show: toggle,
///     child: widget,
///  );
///
/// ## How does AnimatedSizeAndFade compare to other similar widgets?
///
/// - With AnimatedCrossFade you must keep both the firstChild and secondChild,
///   which is not necessary with AnimatedSizeAndFade.
///
/// - With AnimatedSwitcher you may simply change its child, but then it only
///   animates the fade, not the size.
///
/// - AnimatedContainer also doesn't work unless you know the size of the
///   children in advance.
///
class AnimatedSizeAndFade extends StatelessWidget {
  static final _key = UniqueKey();

  final Widget? child;
  final Duration fadeDuration;
  final Duration sizeDuration;
  final Curve fadeInCurve;
  final Curve fadeOutCurve;
  final Curve sizeCurve;
  final Alignment alignment;
  final Clip clipBehavior;
  final bool show;

  AnimatedSizeAndFade({
    Key? key,
    this.child,
    this.fadeDuration = const Duration(milliseconds: 500),
    this.sizeDuration = const Duration(milliseconds: 500),
    this.fadeInCurve = Curves.easeInOut,
    this.fadeOutCurve = Curves.easeInOut,
    this.sizeCurve = Curves.easeInOut,
    this.alignment = Alignment.center,
    this.clipBehavior = Clip.hardEdge,
  })  : show = true,
        super(key: key);

  /// Use this constructor when you want to show/hide the child, by doing a
  /// vertical size/fade. To that end, instead of changing the child,
  /// simply change [show]. Note this widget will try to have its width as
  /// big as possible, so put it in a parent with limited width constraints.
  AnimatedSizeAndFade.showHide({
    Key? key,
    this.child,
    required this.show,
    this.fadeDuration = const Duration(milliseconds: 500),
    this.sizeDuration = const Duration(milliseconds: 500),
    this.fadeInCurve = Curves.easeInOut,
    this.fadeOutCurve = Curves.easeInOut,
    this.sizeCurve = Curves.easeInOut,
    this.alignment = Alignment.center,
    this.clipBehavior = Clip.hardEdge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var animatedSize = AnimatedSize(
      clipBehavior: clipBehavior,
      duration: sizeDuration,
      curve: sizeCurve,
      child: AnimatedSwitcher(
        child: show
            ? child
            : Container(
                key: AnimatedSizeAndFade._key,
                width: double.infinity,
                height: 0,
              ),
        duration: fadeDuration,
        switchInCurve: fadeInCurve,
        switchOutCurve: fadeOutCurve,
        layoutBuilder: _layoutBuilder,
      ),
    );

    return ClipRect(
      child: animatedSize,
      clipBehavior: clipBehavior,
    );
  }

  Widget _layoutBuilder(Widget? currentChild, List<Widget> previousChildren) {
    List<Widget> children = previousChildren;

    if (currentChild != null) {
      //
      children = previousChildren.isEmpty
          ? [currentChild]
          : [
              Positioned(
                left: 0,
                right: 0,
                child: previousChildren[0],
              ),
              currentChild,
            ];
    }

    return Stack(
      clipBehavior: Clip.none,
      children: children,
      alignment: alignment,
    );
  }
}
