import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/haccp_top_bar.dart';
import '../../../../core/constants/design_tokens.dart';
import '../../../../core/widgets/haccp_long_press_button.dart';
import '../providers/ghp_provider.dart';

class GhpChemicalsScreen extends ConsumerStatefulWidget {
  const GhpChemicalsScreen({super.key});

  @override
  ConsumerState<GhpChemicalsScreen> createState() => _GhpChemicalsScreenState();
}

class _GhpChemicalsScreenState extends ConsumerState<GhpChemicalsScreen> {
  // Mock chemicals list - in real app fetch from DB or config
  final List<String> _chemicals = [
    'Płyn do naczyń (L)',
    'Środek do podłóg (L)',
    'Dezynfekcja rąk (L)',
    'Odtłuszczacz (L)',
    'Płyn do szyb (L)'
  ];

  final Map<String, double> _usage = {};

  @override
  Widget build(BuildContext context) {
    final submissionState = ref.watch(ghpFormSubmissionProvider);
    
    return Scaffold(
      appBar: const HaccpTopBar(title: 'Rejestr Chemii'),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _chemicals.length,
              separatorBuilder: (c, i) => const Divider(color: Colors.white12),
              itemBuilder: (context, index) {
                final chemical = _chemicals[index];
                final currentVal = _usage[chemical] ?? 0.0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(chemical, style: Theme.of(context).textTheme.titleMedium),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (currentVal > 0) {
                                  setState(() {
                                    _usage[chemical] = (currentVal - 0.5).clamp(0.0, 100.0);
                                  });
                                }
                              },
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                currentVal.toStringAsFixed(1),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  _usage[chemical] = currentVal + 0.5;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: submissionState.maybeWhen(
              loading: () => const Center(child: CircularProgressIndicator()),
              orElse: () => HaccpLongPressButton(
                label: 'ZAPISZ ZUŻYCIE',
                color: _hasUsage ? HaccpDesignTokens.success : Colors.grey,
                onCompleted: _hasUsage ? () => _submit(context) : () {},
              )
            ),
          ),
        ],
      ),
    );
  }
  
  bool get _hasUsage => _usage.values.any((v) => v > 0);

  Future<void> _submit(BuildContext context) async {
    // Filter only used chemicals
    final data = Map.fromEntries(_usage.entries.where((e) => e.value > 0));
    
    final success = await ref.read(ghpFormSubmissionProvider.notifier).submitChecklist(
      formId: 'ghp_chemicals',
      data: data,
    );

    if (success && context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           content: Text('Zapisano zużycie chemii'),
           backgroundColor: HaccpDesignTokens.success,
         ),
       );
       setState(() {
         _usage.clear();
       });
    }
  }
}
