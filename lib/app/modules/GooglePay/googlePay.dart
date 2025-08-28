import 'package:flutter/material.dart';

class GooglePayView extends StatefulWidget {
  const GooglePayView({super.key});

  @override
  State<GooglePayView> createState() => _GooglePayViewState();
}

class _GooglePayViewState extends State<GooglePayView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Center(
        child: Text("Google Pay "),
      ),
    );
  }
}
