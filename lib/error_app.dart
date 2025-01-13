import 'package:flutter/material.dart';

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Error initializing app. Please try again.',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
