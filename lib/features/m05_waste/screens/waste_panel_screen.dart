
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/haccp_top_bar.dart';
import '../../m05_waste/models/waste_record.dart';
import '../../m05_waste/repositories/waste_repository.dart';
import '../../../core/providers/auth_provider.dart';

class WastePanelScreen extends ConsumerStatefulWidget {
  const WastePanelScreen({super.key});

  @override
  ConsumerState<WastePanelScreen> createState() => _WastePanelScreenState();
}

class _WastePanelScreenState extends ConsumerState<WastePanelScreen> {
  final _repository = WasteRepository();
  List<WasteRecord>? _records;
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
      try {
        final data = await _repository.getRecentRecords(user.venues.first);
        if (mounted) setState(() => _records = data);
      } catch (e) {
        // Handle error silently or show snackbar
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HaccpTopBar(
        title: 'Odpady BDO',
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/waste/history'),
            tooltip: 'Pełna historia',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records == null || _records!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.recycling, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Brak wpisów dzisiaj',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _records!.length,
                  itemBuilder: (context, index) {
                    final record = _records![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        title: Text(record.wasteType, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${record.massKg} kg • ${DateFormat('HH:mm').format(record.createdAt)}',
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/waste/register');
          _loadData(); // Refresh on return
        },
        backgroundColor: const Color(0xFFD2661E),
        icon: const Icon(Icons.add),
        label: const Text('Zarejestruj Odpad'),
      ),
    );
  }
}
