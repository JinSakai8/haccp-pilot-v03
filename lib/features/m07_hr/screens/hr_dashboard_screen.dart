import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/design_tokens.dart';
import '../../../../core/models/employee.dart';
import '../../../../core/widgets/haccp_top_bar.dart';
import '../utils/hr_alerts_snapshot.dart';
import '../providers/hr_provider.dart';

class HrDashboardScreen extends ConsumerWidget {
  const HrDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(hrEmployeesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            HaccpTopBar(
              title: 'HR & Personel',
              onBackPressed: () => context.go('/hub'),
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.list, size: 32),
                  onPressed: () => context.push('/hr/list'),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add, size: 32),
                  onPressed: () => context.push('/hr/add'),
                ),
              ],
            ),
            Expanded(
              child: employeesAsync.when(
                data: (employees) => _HrDashboardBody(employees: employees),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Blad: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HrDashboardBody extends StatelessWidget {
  const _HrDashboardBody({required this.employees});

  final List<Employee> employees;

  @override
  Widget build(BuildContext context) {
    final snapshot = HrAlertsSnapshot.fromEmployees(employees, DateTime.now());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _StatusCard(
                title: 'Przeterminowane',
                value: '${snapshot.expired.length}',
                color: DesignTokens.errorColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatusCard(
                title: 'Wygasaja <=30d',
                value: '${snapshot.expiring.length}',
                color: DesignTokens.warningColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatusCard(
                title: 'Wazne',
                value: '${snapshot.valid.length}',
                color: DesignTokens.successColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _AlertSection(
          title: 'Krytyczne alerty',
          color: DesignTokens.errorColor,
          employees: snapshot.expired,
          emptyMessage: 'Brak przeterminowanych badan.',
        ),
        const SizedBox(height: 12),
        _AlertSection(
          title: 'Wygasaja wkrotce',
          color: DesignTokens.warningColor,
          employees: snapshot.expiring,
          emptyMessage: 'Brak badan wygasajacych w ciagu 30 dni.',
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/hr/list'),
                icon: const Icon(Icons.people),
                label: const Text('Lista'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/hr/add'),
                icon: const Icon(Icons.person_add),
                label: const Text('Dodaj'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _AlertSection extends StatelessWidget {
  const _AlertSection({
    required this.title,
    required this.color,
    required this.employees,
    required this.emptyMessage,
  });

  final String title;
  final Color color;
  final List<Employee> employees;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final shown = employees.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.circle, color: color, size: 12),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/hr/list'),
                child: const Text('Zobacz wszystkie'),
              ),
            ],
          ),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                emptyMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ),
          ...shown.map(
            (employee) {
              final expiry = employee.sanepidExpiry;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(employee.fullName),
                subtitle: Text(
                  expiry == null
                      ? employee.role.toString().toUpperCase()
                      : '${employee.role.toString().toUpperCase()}  |  ${dateFormat.format(expiry)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/hr/employee/${employee.id}'),
              );
            },
          ),
        ],
      ),
    );
  }
}
