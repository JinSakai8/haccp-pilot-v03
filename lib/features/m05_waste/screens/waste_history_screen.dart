import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/haccp_top_bar.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/constants/design_tokens.dart';
import '../../m05_waste/repositories/waste_repository.dart';
import '../../m05_waste/models/waste_record.dart';
import '../../../core/providers/auth_provider.dart';

class WasteHistoryScreen extends ConsumerStatefulWidget {
  const WasteHistoryScreen({super.key});

  @override
  ConsumerState<WasteHistoryScreen> createState() => _WasteHistoryScreenState();
}

class _WasteHistoryScreenState extends ConsumerState<WasteHistoryScreen> {
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  List<WasteRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // Use currentZoneProvider for venueId
    final zone = ref.read(currentZoneProvider);
    // If no zone (shouldn't happen in logged in state), fallback to user's first venue or empty
    final venueId = zone?.venueId ?? ref.read(currentUserProvider)?.venues.firstOrNull;

    if (venueId != null) {
      final records = await WasteRepository().getHistory(venueId, fromDate: _fromDate, toDate: _toDate);
      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HaccpTopBar(title: 'Historia Odpadów'),
      body: Column(
        children: [
          _buildFilterBar(),
          if (!_isLoading && _records.isNotEmpty) _buildSummaryCard(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? const HaccpEmptyState(
                        headline: 'Brak wpisów',
                        subtext: 'Brak wpisów w wybranym okresie.',
                        icon: Icons.history,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _records.length,
                        itemBuilder: (context, index) => _buildRecordCard(_records[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: HaccpDesignTokens.surface,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Zakres dat:', style: TextStyle(color: Colors.grey)),
              Text(
                '${DateFormat('dd.MM').format(_fromDate)} - ${DateFormat('dd.MM.yyyy').format(_toDate)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _selectDateRange(context),
            icon: const Icon(Icons.calendar_today),
            label: const Text('Zmień'),
          ),
        ],
      ),
    );
  }



  Widget _buildRecordCard(WasteRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: HaccpDesignTokens.surface,
      child: ListTile(
        leading: const Icon(Icons.delete_outline, color: HaccpDesignTokens.primary),
        title: Text('${record.wasteType} - ${record.massKg} kg'),
        subtitle: Text('Kod: ${record.wasteCode} | ${DateFormat('dd.MM.yyyy HH:mm').format(record.createdAt)}'),
        trailing: record.photoUrl != null 
          ? const Icon(Icons.photo, color: Colors.grey) 
          : null,
      ),
    );
  }
  Widget _buildSummaryCard() {
    final totalMass = _records.fold(0.0, (sum, record) => sum + record.massKg);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: HaccpDesignTokens.primary.withOpacity(0.1),
      child: Column(
        children: [
          Text(
            'SUMA MASY ODPADÓW',
            style: TextStyle(color: HaccpDesignTokens.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 4),
          Text(
            '${totalMass.toStringAsFixed(1)} kg',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
