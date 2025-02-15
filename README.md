[![Pub popularity](https://badgen.net/pub/popularity/animated_size_and_fade)](https://pub.dev/packages/animated_size_and_fade)
[![Pub Version](https://img.shields.io/pub/v/animated_size_and_fade?style=flat-square&logo=dart)](https://pub.dev/packages/animated_size_and_fade)
[![GitHub stars](https://img.shields.io/github/stars/marcglasberg/animated_size_and_fade?style=social)](https://github.com/marcglasberg/animated_size_and_fade)
![Code Climate issues](https://img.shields.io/github/issues/marcglasberg/animated_size_and_fade?style=flat-square)
![GitHub closed issues](https://img.shields.io/github/issues-closed/marcglasberg/animated_size_and_fade?style=flat-square)
![GitHub repo size](https://img.shields.io/github/repo-size/marcglasberg/animated_size_and_fade?style=flat-square)
![GitHub forks](https://img.shields.io/github/forks/marcglasberg/animated_size_and_fade?style=flat-square)
![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)
[![Developed by Marcelo Glasberg](https://img.shields.io/badge/Developed%20by%20Marcelo%20Glasberg-blue.svg)](https://glasberg.dev/)
[![Glasberg.dev on pub.dev](https://img.shields.io/pub/publisher/animated_size_and_fade.svg)](https://pub.dev/publishers/glasberg.dev/packages)
[![Platforms](https://badgen.net/pub/flutter-platform/animated_size_and_fade)](https://pub.dev/packages/animated_size_and_fade)

#### Sponsor

[![](./example/SponsoredByMyTextAi.png)](https://mytext.ai)

# animated_size_and_fade

The `AnimatedSizeAndFade` widget allows you to:

1. Do a **fade and size transition** between two widgets.
2. **Show and hide** a widget, by resizing it vertically while fading.

<img src="https://github.com/marcglasberg/animated_size_and_fade/blob/master/example/lib/animated_size_and_fade.gif?raw=true" width="280">

### Size and Fade

To do a fade and size transition when you change the `child` widget, 
the "old" and the "new" child must have the same width, 
but can have different heights, 
and you **don't need to know** their sizes in advance.

You can also define a duration and curve for both the fade and the size, separately.

**Important:** If the "new" child is the same widget type as the "old" child, but with different
parameters, then `AnimatedSizeAndFade` will **NOT** do a transition between them, since as far as
the framework is concerned, they are the same widget, and the existing widget can be updated with
the new parameters. To force the transition to occur, set a `Key` (typically a `ValueKey`
taking any widget data that would change the visual appearance of the widget) on each child widget
that you wish to be considered unique.

Example:

    bool toggle=true;
    Widget widget1 = ...;
    Widget widget2 = ...;
    
    AnimatedSizeAndFade(
       child: toggle ? widget1 : widget2
    );

### Show and Hide

The `AnimatedSizeAndFade.showHide` constructor may be used to show/hide a widget, by resizing it
vertically while fading.

Example:

    bool toggle=true;
    Widget widget = ...;    
    
    AnimatedSizeAndFade.showHide(
       show: toggle,
       child: widget,
    );

## How does it compare to other similar widgets?

- With `AnimatedCrossFade` you must provide both the _firstChild_ and _secondChild_ 
  at the same time, but with `AnimatedSizeAndFade` you may simply change its child.

- With `AnimatedSwitcher` you may simply change its child, but then it only animates 
  the fade, not the size.

- `AnimatedContainer` only works if you know the size of the children in advance.

***

Note: See
the [StackOverflow question](https://stackoverflow.com/questions/51736663/in-flutter-how-can-i-change-some-widget-and-see-it-animate-to-its-new-size/)
that prompted this widget development.

***

## By Marcelo Glasberg

<a href="https://glasberg.dev">_glasberg.dev_</a>
<br>
<a href="https://github.com/marcglasberg">_github.com/marcglasberg_</a>
<br>
<a href="https://www.linkedin.com/in/marcglasberg/">_linkedin.com/in/marcglasberg/_</a>
<br>
<a href="https://twitter.com/glasbergmarcelo">_twitter.com/glasbergmarcelo_</a>
<br>
<a href="https://stackoverflow.com/users/3411681/marcg">
_stackoverflow.com/users/3411681/marcg_</a>
<br>
<a href="https://medium.com/@marcglasberg">_medium.com/@marcglasberg_</a>
<br>

*My article in the official Flutter documentation*:

* <a href="https://flutter.dev/docs/development/ui/layout/constraints">Understanding
  constraints</a>

*The Flutter packages I've authored:*

* <a href="https://pub.dev/packages/async_redux">async_redux</a>
* <a href="https://pub.dev/packages/provider_for_redux">provider_for_redux</a>
* <a href="https://pub.dev/packages/i18n_extension">i18n_extension</a>
* <a href="https://pub.dev/packages/align_positioned">align_positioned</a>
* <a href="https://pub.dev/packages/network_to_file_image">network_to_file_image</a>
* <a href="https://pub.dev/packages/image_pixels">image_pixels</a>
* <a href="https://pub.dev/packages/matrix4_transform">matrix4_transform</a>
* <a href="https://pub.dev/packages/back_button_interceptor">back_button_interceptor</a>
* <a href="https://pub.dev/packages/indexed_list_view">indexed_list_view</a>
* <a href="https://pub.dev/packages/animated_size_and_fade">animated_size_and_fade</a>
* <a href="https://pub.dev/packages/assorted_layout_widgets">assorted_layout_widgets</a>
* <a href="https://pub.dev/packages/weak_map">weak_map</a>
* <a href="https://pub.dev/packages/themed">themed</a>
* <a href="https://pub.dev/packages/bdd_framework">bdd_framework</a>
* <a href="https://pub.dev/packages/tiktoken_tokenizer_gpt4o_o1">
  tiktoken_tokenizer_gpt4o_o1</a>

*My Medium Articles:*

* <a href="https://medium.com/flutter-community/https-medium-com-marcglasberg-async-redux-33ac5e27d5f6">
  Async Redux: Flutter’s non-boilerplate version of Redux</a> 
  (versions: <a href="https://medium.com/flutterando/async-redux-pt-brasil-e783ceb13c43">
  Português</a>)
* <a href="https://medium.com/flutter-community/i18n-extension-flutter-b966f4c65df9">
  i18n_extension</a> 
  (versions: <a href="https://medium.com/flutterando/qual-a-forma-f%C3%A1cil-de-traduzir-seu-app-flutter-para-outros-idiomas-ab5178cf0336">
  Português</a>)
* <a href="https://medium.com/flutter-community/flutter-the-advanced-layout-rule-even-beginners-must-know-edc9516d1a2">
  Flutter: The Advanced Layout Rule Even Beginners Must Know</a> 
  (versions: <a href="https://habr.com/ru/post/500210/">русский</a>)
* <a href="https://medium.com/flutter-community/the-new-way-to-create-themes-in-your-flutter-app-7fdfc4f3df5f">
  The New Way to create Themes in your Flutter App</a> 

[![](./example/SponsoredByMyTextAi.png)](https://mytext.ai)
