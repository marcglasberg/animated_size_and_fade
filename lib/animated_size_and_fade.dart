import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

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
/// **NOT** cross-fade between them, since as far as the framework is
/// concerned, they are the same widget, and the existing widget can be updated
/// with the new parameters. To force the transition to occur, set a [Key]
/// (typically a [ValueKey] taking any widget data that would change the visual
/// appearance of the widget) on each child widget that you wish to be
/// considered unique. Changes to the child's size still animate.
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
/// ```
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

  /// Called after the current transition's incoming and outgoing fades finish.
  /// No callback is made for a size-only change. Zero-duration fades count.
  final VoidCallback? onFadeEnd;

  /// Called after the current transition's changed size settles.
  /// No callback is made for an equal-size replacement. Zero-duration changes
  /// count. If the child resizes again during a fade, a later settled size can
  /// produce another size completion before [onEnd].
  final VoidCallback? onSizeEnd;

  /// Called once after both parts of the current transition finish.
  /// A part that did not change is already finished. Initial layout and no-op
  /// rebuilds do not count. Interrupted transitions do not call this callback.
  /// All callbacks run after layout and use the latest supplied callbacks.
  /// When both components finish together, [onFadeEnd] precedes [onSizeEnd].
  /// This callback runs in the following frame, so a component callback's
  /// setState can replace the transition or dispose the widget first.
  final VoidCallback? onEnd;

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
    this.onFadeEnd,
    this.onSizeEnd,
    this.onEnd,
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
    this.onFadeEnd,
    this.onSizeEnd,
    this.onEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => _AnimatedSizeAndFade(animation: this);
}

class _AnimatedSizeAndFade extends StatefulWidget {
  const _AnimatedSizeAndFade({required this.animation});
  final AnimatedSizeAndFade animation;

  @override
  State<_AnimatedSizeAndFade> createState() => _AnimatedSizeAndFadeState();
}

class _AnimatedSizeAndFadeState extends State<_AnimatedSizeAndFade> {
  AnimatedSizeAndFade get _animation => widget.animation;
  final _switcherKey = GlobalKey();
  final Set<Animation<double>> _fades = {};
  Size? _target;
  RenderAnimatedSize? _sizeRender;
  bool get _sizeAnimating => _sizeRender?.isAnimating ?? false;
  bool _active = false;
  bool _fadeChanged = false;
  bool _sizeChanged = false;
  bool _fadeReported = false;
  bool _sizeReported = false;
  bool _checkScheduled = false;

  Widget? _child(AnimatedSizeAndFade value) => value.show
      ? value.child
      : Container(
          key: AnimatedSizeAndFade._key, width: double.infinity, height: 0);

  bool get _fading => _fades.any((animation) =>
      animation.status == AnimationStatus.forward ||
      animation.status == AnimationStatus.reverse);

  void _begin({required bool fadeChanged}) {
    _active = true;
    _fadeChanged = fadeChanged || _fading;
    _sizeChanged = _sizeChanged && _sizeAnimating;
    _fadeReported = false;
    _sizeReported = false;
  }

  @override
  void didUpdateWidget(_AnimatedSizeAndFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldChild = _child(oldWidget.animation);
    final child = _child(_animation);
    if ((oldChild == null) != (child == null) ||
        (oldChild != null &&
            child != null &&
            !Widget.canUpdate(oldChild, child))) {
      _begin(fadeChanged: true);
    }
    _scheduleCheck();
  }

  void _layout(Size target, RenderAnimatedSize? render) {
    if (_target != null && target != _target) {
      if (!_active) {
        _begin(fadeChanged: false);
      }
      _sizeChanged = true;
      _sizeReported = false;
    }
    _target = target;
    _scheduleCheck();
  }

  void _animationLayout(Size size, RenderAnimatedSize? render) {
    _sizeRender = render;
    _scheduleCheck();
  }

  void _fadeStatus(AnimationStatus status) {
    _fades.removeWhere((animation) {
      if (animation.status == AnimationStatus.dismissed) {
        animation.removeStatusListener(_fadeStatus);
        return true;
      }
      return false;
    });
    _scheduleCheck();
  }

  Widget _transitionBuilder(Widget child, Animation<double> animation) {
    if (_fades.add(animation)) {
      animation.addStatusListener(_fadeStatus);
    }
    return FadeTransition(opacity: animation, child: child);
  }

  void _scheduleCheck() {
    if (_checkScheduled || !mounted) return;
    _checkScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      if (!mounted) return;
      if (!_active) return;
      final fadeDone = !_fading;
      // Ignore AnimatedSize's initial equal-size controller activity.
      final sizeDone = !_sizeChanged || !_sizeAnimating;
      var reported = false;
      if (_fadeChanged && !_fadeReported && fadeDone) {
        _fadeReported = true;
        reported = true;
        _animation.onFadeEnd?.call();
      }
      if (_sizeChanged && !_sizeReported && sizeDone) {
        _sizeReported = true;
        reported = true;
        _animation.onSizeEnd?.call();
      }
      if (fadeDone && sizeDone) {
        if (reported) {
          // Let a component callback's setState rebuild or dispose us before
          // considering the combined completion on the following frame.
          _scheduleCheck();
        } else {
          _active = false;
          _animation.onEnd?.call();
        }
      }
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    for (final animation in _fades) {
      animation.removeStatusListener(_fadeStatus);
    }
    _fades.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final switcher = _SizeObserver(
        onLayout: _layout,
        child: AnimatedSwitcher(
          key: _switcherKey,
          child: _child(_animation),
          duration: _animation.fadeDuration,
          switchInCurve: _animation.fadeInCurve,
          switchOutCurve: _animation.fadeOutCurve,
          transitionBuilder: _transitionBuilder,
          layoutBuilder: _layoutBuilder,
        ));
    return ClipRect(
      clipBehavior: _animation.clipBehavior,
      child: _SizeObserver(
        onLayout: _animationLayout,
        // AnimatedSize with Duration.zero can assert while dirtying itself
        // during layout. An immediate size change needs no size controller.
        child: _animation.sizeDuration == Duration.zero
            ? switcher
            : AnimatedSize(
                clipBehavior: _animation.clipBehavior,
                duration: _animation.sizeDuration,
                curve: _animation.sizeCurve,
                onEnd: _scheduleCheck,
                child: switcher,
              ),
      ),
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
      alignment: _animation.alignment,
    );
  }
}

class _SizeObserver extends SingleChildRenderObjectWidget {
  const _SizeObserver({required this.onLayout, required super.child});
  final void Function(Size, RenderAnimatedSize?) onLayout;

  @override
  _RenderSizeObserver createRenderObject(BuildContext context) =>
      _RenderSizeObserver(onLayout);

  @override
  void updateRenderObject(
      BuildContext context, _RenderSizeObserver renderObject) {
    renderObject.onLayout = onLayout;
  }
}

class _RenderSizeObserver extends RenderProxyBox {
  _RenderSizeObserver(this.onLayout);
  void Function(Size, RenderAnimatedSize?) onLayout;

  @override
  void performLayout() {
    super.performLayout();
    final box = child;
    onLayout(size, box is RenderAnimatedSize ? box : null);
  }
}
