import 'package:flutter/material.dart';
import 'package:haccp_pilot/core/widgets/haccp_top_bar.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HaccpTopBar(title: title),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("Moduł w budowie", style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
