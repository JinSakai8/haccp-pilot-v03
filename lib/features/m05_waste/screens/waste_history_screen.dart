import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/haccp_top_bar.dart';
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
    final user = ref.read(currentUserProvider);
    if (user != null && user.venues.isNotEmpty) {
      // Assuming first venue for now, or use a provider for current venue
      final venueId = user.venues.first; 
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? _buildEmptyState()
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Brak wpisów w wybranym okresie', style: TextStyle(color: Colors.grey)),
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
}
