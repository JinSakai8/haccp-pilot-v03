
import 'package:flutter/material.dart';
import 'package:haccp_pilot/core/widgets/haccp_top_bar.dart';
import 'package:haccp_pilot/features/m05_waste/models/waste_record.dart';
import 'package:haccp_pilot/features/m05_waste/repositories/waste_repository.dart';
import 'package:haccp_pilot/features/m05_waste/screens/waste_registration_form_screen.dart';
import 'package:intl/intl.dart';

class WastePanelScreen extends StatefulWidget {
  const WastePanelScreen({super.key});

  @override
  State<WastePanelScreen> createState() => _WastePanelScreenState();
}

class _WastePanelScreenState extends State<WastePanelScreen> {
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
    try {
      final data = await _repository.getRecentRecords('test_venue_id'); // TODO: Real ID
      setState(() => _records = data);
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HaccpTopBar(title: 'Odpady BDO'),
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
                            image: record.photoUrl != null
                                // Since photoUrl is a path, we can't easily show it 
                                // without a signed URL generator. 
                                // Just showing icon for now.
                                ? null 
                                : null,
                          ),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        title: Text(record.wasteType, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${record.massKg} kg • ${DateFormat('HH:mm').format(record.createdAt)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WasteRegistrationFormScreen()),
          );
          _loadData(); // Refresh on return
        },
        backgroundColor: const Color(0xFFD2661E),
        icon: const Icon(Icons.add),
        label: const Text('Zarejestruj Odpad'),
      ),
    );
  }
}
