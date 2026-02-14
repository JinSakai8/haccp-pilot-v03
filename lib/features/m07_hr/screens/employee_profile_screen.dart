import 'package:flutter/material.dart';

class EmployeeProfileScreen extends StatelessWidget {
  final String employeeId;
  
  const EmployeeProfileScreen({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Profile for $employeeId - Placeholder')),
    );
  }
}
