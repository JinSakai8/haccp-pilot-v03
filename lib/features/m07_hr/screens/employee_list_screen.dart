import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/haccp_top_bar.dart';
import '../../../../core/constants/design_tokens.dart';
import '../../../../core/models/employee.dart';
import '../providers/hr_provider.dart';

class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  String _selectedFilter = 'wszyscy'; // wszyscy, aktywni, sanepid, nieaktywni

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(hrEmployeesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HaccpTopBar(
              title: 'Pracownicy',
              onBackPressed: () => context.go('/hr'), // Go back to HR Dashboard
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_add, size: 32),
                  onPressed: () async {
                    final success = await context.push<bool>('/hr/add');
                    if (success == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pracownik został dodany!'),
                          backgroundColor: DesignTokens.successColor,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            
            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('Wszyscy', 'wszyscy'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Aktywni', 'aktywni'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Wygasające Badania', 'sanepid'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Nieaktywni', 'nieaktywni'),
                ],
              ),
            ),
            
            // List
            Expanded(
              child: employeesAsync.when(
                data: (employees) {
                  final filteredList = _filterEmployees(employees, _selectedFilter);
                  
                  if (filteredList.isEmpty) {
                    return Center(
                      child: Text(
                        'Brak pracowników',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white54
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final emp = filteredList[index];
                      return _buildEmployeeCard(emp, context);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Błąd: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      backgroundColor: Colors.white10,
      selectedColor: DesignTokens.accentColor.withOpacity(0.3),
      checkmarkColor: DesignTokens.accentColor,
      labelStyle: TextStyle(
        color: isSelected ? DesignTokens.accentColor : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  List<Employee> _filterEmployees(List<Employee> list, String filter) {
    if (filter == 'wszyscy') return list;
    
    if (filter == 'aktywni') {
      return list.where((e) => e.isActive).toList();
    }
    
    if (filter == 'nieaktywni') {
      return list.where((e) => !e.isActive).toList();
    }

    if (filter == 'sanepid') {
      // Logic: expired or expiring within 30 days
      final now = DateTime.now();
      final threshold = now.add(const Duration(days: 30));
      
      return list.where((e) {
        if (!e.isActive || e.sanepidExpiry == null) return false;
        return e.sanepidExpiry!.isBefore(threshold);
      }).toList();
    }
    
    return list;
  }

  Widget _buildEmployeeCard(Employee emp, BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getSanepidStatusColor(emp.sanepidExpiry);
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/hr/employee/${emp.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Sanepid Status Dot
              Container(
                width: 48, // Big readable dot
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                   _getStatusIcon(emp.sanepidExpiry),
                   color: Colors.white,
                   size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp.fullName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      emp.role.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                    if (emp.sanepidExpiry != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Sanepid: ${dateFormat.format(emp.sanepidExpiry!)}',
                         style: theme.textTheme.bodySmall?.copyWith(
                          color: statusColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Arrow
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSanepidStatusColor(DateTime? expiry) {
    if (expiry == null) return Colors.grey;
    
    final now = DateTime.now();
    final difference = expiry.difference(now).inDays;
    
    if (difference < 0) return DesignTokens.errorColor; // Expired
    if (difference <= 30) return DesignTokens.warningColor; // Expiring soon
    return DesignTokens.successColor; // OK
  }

  IconData _getStatusIcon(DateTime? expiry) {
    if (expiry == null) return Icons.help_outline;
    
    final now = DateTime.now();
    final difference = expiry.difference(now).inDays;
    
    if (difference < 0) return Icons.warning_amber_rounded;
    if (difference <= 30) return Icons.priority_high_rounded;
    return Icons.check_rounded; 
  }
}
