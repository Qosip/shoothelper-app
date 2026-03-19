import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShootHelper',
      theme: ThemeData(
        colorSchemeSeed: Colors.blueGrey,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('ShootHelper — Setup OK')),
      ),
    );
  }
}
