import 'package:flutter/material.dart';
import '../../../../core/widgets/haccp_top_bar.dart';

class AlarmsPanelScreen extends StatelessWidget {
  const AlarmsPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: HaccpTopBar(title: 'Panel Alarmów'),
      body: Center(
        child: Text('Lista Alarmów (W budowie)'),
      ),
    );
  }
}
