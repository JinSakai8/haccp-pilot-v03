import 'package:flutter/material.dart';
import '../../../../core/widgets/haccp_top_bar.dart';

class SensorChartScreen extends StatelessWidget {
  final String deviceId;
  const SensorChartScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HaccpTopBar(title: 'Wykres: $deviceId'),
      body: Center(
        child: Text('Wykres historyczny dla $deviceId (W budowie)'),
      ),
    );
  }
}
