import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haccp_pilot/core/theme/app_theme.dart';
import 'package:haccp_pilot/features/m06_reports/providers/reports_provider.dart';
import 'package:haccp_pilot/core/widgets/haccp_top_bar.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:intl/intl.dart';

class DriveStatusScreen extends ConsumerStatefulWidget {
  const DriveStatusScreen({super.key});

  @override
  ConsumerState<DriveStatusScreen> createState() => _DriveStatusScreenState();
}

class _DriveStatusScreenState extends ConsumerState<DriveStatusScreen> {
  bool _isLoading = true;
  List<drive.File> _files = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final files = await ref.read(driveServiceProvider).listFiles();
      if (mounted) {
        setState(() { _files = files; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HaccpTopBar(title: 'Google Drive Status'),
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildStatusHeader(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                ? Center(child: Text('Błąd: $_error', style: const TextStyle(color: AppTheme.error)))
                : _buildFilesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadFiles,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surface,
      child: Row(
        children: [
          const Icon(Icons.cloud_done, color: AppTheme.success, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Service Account', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.onSurfaceVariant)),
              const Text('Połączono (BDO HACCP)', style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList() {
    if (_files.isEmpty) {
      return const Center(child: Text('Folder jest pusty', style: TextStyle(color: AppTheme.onSurfaceVariant)));
    }

    return ListView.separated(
      itemCount: _files.length,
      separatorBuilder: (_, __) => const Divider(color: AppTheme.outline),
      itemBuilder: (context, index) {
        final file = _files[index];
        final date = file.createdTime != null 
          ? DateFormat('yyyy-MM-dd HH:mm').format(file.createdTime!) 
          : '-';
        
        return ListTile(
          leading: const Icon(Icons.description, color: AppTheme.primary),
          title: Text(file.name ?? 'Bez nazwy', style: const TextStyle(color: AppTheme.onSurface)),
          subtitle: Text(date, style: const TextStyle(color: AppTheme.onSurfaceVariant)),
          trailing: file.size != null 
            ? Text('${(int.parse(file.size!) / 1024).toStringAsFixed(1)} KB', style: const TextStyle(color: AppTheme.onSurfaceVariant))
            : null,
        );
      },
    );
  }
}
