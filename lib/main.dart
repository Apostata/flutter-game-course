import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_game/main_game_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen(); // flame defined full screen

  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RayWorld',
      home: MainGamePage(),
    );
  }
}
