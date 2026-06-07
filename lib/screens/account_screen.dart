import 'package:flutter/material.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon Compte'), centerTitle: true),
      body: const Center(
        child: Text(
          'Page Compte en construction',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
