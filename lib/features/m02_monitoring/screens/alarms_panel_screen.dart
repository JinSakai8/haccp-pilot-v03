import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:haccp_pilot/core/constants/design_tokens.dart';
import 'package:haccp_pilot/core/providers/auth_provider.dart';
import 'package:haccp_pilot/core/widgets/empty_state_widget.dart';
import 'package:haccp_pilot/core/widgets/haccp_long_press_button.dart';
import 'package:haccp_pilot/core/widgets/haccp_top_bar.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/alarm_list_item.dart';
import 'package:haccp_pilot/features/m02_monitoring/providers/monitoring_provider.dart';

class AlarmsPanelScreen extends ConsumerStatefulWidget {
  const AlarmsPanelScreen({super.key});

  @override
  ConsumerState<AlarmsPanelScreen> createState() => _AlarmsPanelScreenState();
}

class _AlarmsPanelScreenState extends ConsumerState<AlarmsPanelScreen> {
  final Set<String> _pendingAcks = <String>{};

  Future<void> _acknowledge(String logId) async {
    if (_pendingAcks.contains(logId)) {
      return;
    }

    setState(() {
      _pendingAcks.add(logId);
    });

    try {
      await ref.read(alarmActionProvider.notifier).acknowledge(logId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarm potwierdzony')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Blad potwierdzenia alarmu: $error')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _pendingAcks.remove(logId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final zone = ref.watch(currentZoneProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: HaccpTopBar(
          title: 'Alarmy',
          onBackPressed: () => context.pop(),
        ),
        body: Column(
          children: [
            const TabBar(
              indicatorColor: HaccpDesignTokens.primary,
              labelColor: HaccpDesignTokens.primary,
              unselectedLabelColor: Colors.white60,
              tabs: [
                Tab(text: 'AKTYWNE'),
                Tab(text: 'HISTORIA'),
              ],
            ),
            Expanded(
              child: zone == null
                  ? const Center(child: Text('Brak wybranej strefy'))
                  : TabBarView(
                      children: [
                        _AlarmsList(
                          zoneId: zone.id,
                          isActive: true,
                          pendingAcks: _pendingAcks,
                          onAcknowledge: _acknowledge,
                        ),
                        _AlarmsList(
                          zoneId: zone.id,
                          isActive: false,
                          pendingAcks: _pendingAcks,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlarmsList extends ConsumerWidget {
  final String zoneId;
  final bool isActive;
  final Set<String> pendingAcks;
  final Future<void> Function(String logId)? onAcknowledge;

  const _AlarmsList({
    required this.zoneId,
    required this.isActive,
    required this.pendingAcks,
    this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(alarmsProvider(zoneId, activeOnly: isActive));

    return alarmsAsync.when(
      data: (alarms) {
        if (alarms.isEmpty) {
          return HaccpEmptyState(
            headline: isActive
                ? 'Brak aktywnych alarmow'
                : 'Brak historii alarmow',
            subtext: isActive ? 'Wszystkie parametry sa w normie.' : '',
            icon: isActive ? Icons.check_circle_outline : Icons.history,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: alarms.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final alarm = alarms[index];
            final isAckPending = pendingAcks.contains(alarm.logId);

            return _AlarmCard(
              alarm: alarm,
              isActive: isActive,
              isAckPending: isAckPending,
              onAcknowledge: isActive && onAcknowledge != null
                  ? () => onAcknowledge!(alarm.logId)
                  : null,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Blad alarmow: $error')),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  final AlarmListItem alarm;
  final bool isActive;
  final bool isAckPending;
  final VoidCallback? onAcknowledge;

  const _AlarmCard({
    required this.alarm,
    required this.isActive,
    required this.isAckPending,
    this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final recordedAtText = DateFormat('HH:mm').format(alarm.startedAt);
    final lastSeenText = DateFormat('yyyy-MM-dd HH:mm').format(alarm.lastSeenAt);
    final temperatureColor = isActive ? HaccpDesignTokens.error : Colors.white;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? HaccpDesignTokens.error : Colors.white24,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alarm.sensorName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Od: $recordedAtText (${_formatDuration(alarm.durationMinutes)})',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ostatni odczyt: $lastSeenText',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 96),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${alarm.temperature.toStringAsFixed(1)}°C',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: temperatureColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isActive)
              IgnorePointer(
                ignoring: isAckPending,
                child: Opacity(
                  opacity: isAckPending ? 0.6 : 1,
                  child: HaccpLongPressButton(
                    label: isAckPending
                        ? 'Przetwarzanie...'
                        : 'Przyjalem do wiadomosci',
                    color: HaccpDesignTokens.error,
                    onCompleted: onAcknowledge ?? () {},
                  ),
                ),
              )
            else
              _HistoryMeta(alarm: alarm),
          ],
        ),
      ),
    );
  }
}

class _HistoryMeta extends StatelessWidget {
  final AlarmListItem alarm;

  const _HistoryMeta({required this.alarm});

  @override
  Widget build(BuildContext context) {
    final acknowledgedText = alarm.acknowledgedAt == null
        ? 'Potwierdzono'
        : 'Potwierdzono: ${DateFormat('yyyy-MM-dd HH:mm').format(alarm.acknowledgedAt!)}';

    final acknowledgedBy = alarm.acknowledgedBy == null
        ? null
        : 'Przez: ${_shortId(alarm.acknowledgedBy!)}';

    return Wrap(
      runSpacing: 4,
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle, size: 16, color: Colors.green),
              SizedBox(width: 6),
              Text(
                'Potwierdzono',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Text(
          acknowledgedText,
          style: const TextStyle(color: Colors.white70),
        ),
        if (acknowledgedBy != null)
          Text(
            acknowledgedBy,
            style: const TextStyle(color: Colors.white54),
          ),
      ],
    );
  }

  static String _shortId(String id) {
    if (id.length <= 8) return id;
    return '${id.substring(0, 8)}...';
  }
}

String _formatDuration(int minutes) {
  if (minutes <= 0) {
    return '0 min';
  }

  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;

  if (hours == 0) {
    return '$remainingMinutes min';
  }
  if (remainingMinutes == 0) {
    return '${hours}h';
  }

  return '${hours}h ${remainingMinutes} min';
}
