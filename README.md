# animated_size_and_fade

A widget that does a fade and size transition between a "new" widget and the "old "widget
previously set as a child. The "old" and the "new" child must have the same width,
but can have different heights, and you don't need to know their sizes in advance.

You can also define a duration and curve for both the fade and the size, separately.

**Important:** If the "new" child is the same widget type as the "old" child, but with different
parameters, then [AnimatedSizeAndFade] will **NOT** do a transition between them, since as far as
the framework is concerned, they are the same widget, and the existing widget can be updated
with the new parameters. To force the transition to occur, set a [Key] (typically a [ValueKey]
taking any widget data that would change the visual appearance of the widget) on each child
widget that you wish to be considered unique.
 
**Note:** This is the StackOverflow question that prompted this widget development: https://stackoverflow.com/questions/51736663/in-flutter-how-can-i-change-some-widget-and-see-it-animate-to-its-new-size/ 

### Use it like this:
  
    bool toggle=true;
    Widget widget1 = ...;
    Widget widget2 = ...;
    
    AnimatedSizeAndFade(
       vsync: this, 
       child: toggle ? widget1 : widget2
    );
           
           
### How does AnimatedSizeAndFade compare to other similar widgets?

- With `AnimatedCrossFade` you must keep both the firstChild and secondChild, which is not
necessary with `AnimatedSizeAndFade`.

- With `AnimatedSwitcher` you may simply change its child, but then it only animates
the fade, not the size.

- `AnimatedContainer` also doesn't work unless you know the size of the children in advance.


## Usage

### Import the package

First, add animated_size_and_fade [as a dependency](https://pub.dartlang.org/packages/animated_size_and_fade#-installing-tab-) in your pubspec.yaml

Then, import it:

    import 'package:animated_size_and_fade/animated_size_and_fade.dart';

