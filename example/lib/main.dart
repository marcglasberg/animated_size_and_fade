import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  bool toggle;

  @override
  void initState() {
    super.initState();
    toggle = false;
  }

  @override
  Widget build(BuildContext context) {
    var toggleButton = Padding(
      padding: const EdgeInsets.all(8.0),
      child: MaterialButton(
        child: const Text("Toggle"),
        color: Colors.grey,
        onPressed: () {
          setState(() {
            toggle = !toggle;
          });
        },
      ),
    );

    var widget1 = Container(
      key: ValueKey("first"),
      color: Colors.blue,
      width: 200.0,
      child: const Text(
        "And I promise you I'll never desert you again because after 'Salome' "
        "we'll make another picture and another picture. "
        "You see, this is my life! "
        "It always will be! Nothing else! "
        "Just us, the cameras, and those wonderful people out there in the dark!...",
      ),
    );

    var widget2 = Container(
      key: ValueKey("second"),
      color: Colors.red,
      width: 200.0,
      child: const Text(
        "I am ready for my closeup.",
      ),
    );

    return MaterialApp(
      home: Material(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(height: 100.0),
            toggleButton,
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text("Some text above."),
                AnimatedSizeAndFade(
                  vsync: this,
                  child: toggle ? widget1 : widget2,
                  fadeDuration: const Duration(milliseconds: 300),
                  sizeDuration: const Duration(milliseconds: 600),
                ),
                const Text("Some text below."),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
