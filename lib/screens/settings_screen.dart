import 'package:flutter/material.dart';

import '../models/jakim_zone.dart';
import '../services/prayer_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _prayer = PrayerService.instance;
  late String _selectedZone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedZone = _prayer.selectedZone;
  }

  Future<void> _onZoneChanged(String? code) async {
    if (code == null || code == _selectedZone) return;
    setState(() {
      _selectedZone = code;
      _saving = true;
    });
    await _prayer.setZone(code);
    if (mounted) setState(() => _saving = false);
  }

  List<DropdownMenuItem<String>> _buildGroupedItems(ThemeData theme) {
    final items = <DropdownMenuItem<String>>[];
    for (final stateEntry in jakimZonesByState.entries) {
      items.add(
        DropdownMenuItem<String>(
          enabled: false,
          value: '__header_${stateEntry.key}',
          child: Text(
            stateEntry.key,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
      for (final zone in stateEntry.value) {
        items.add(
          DropdownMenuItem<String>(
            value: zone.code,
            child: Text(
              '${zone.code} — ${zone.area}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentZone = kJakimZones.firstWhere((z) => z.code == _selectedZone);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Prayer Time Zone', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Choose your JAKIM zone for accurate prayer times in the daily view and notifications.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedZone,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Zone',
            ),
            isExpanded: true,
            menuMaxHeight: 420,
            items: _buildGroupedItems(theme),
            onChanged: _saving ? null : _onZoneChanged,
          ),
          const SizedBox(height: 8),
          Text(
            '${currentZone.state} — ${currentZone.area}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (_saving) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  'Updating prayer times…',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
