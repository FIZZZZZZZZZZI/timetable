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
  late List<JakimZone> _zones;
  late String _selectedZone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _zones = _prayer.getAvailableZones();
    _selectedZone = _prayer.selectedZone;
    // The persisted zone should normally be one of _zones, but if the
    // fetched/fallback list ever doesn't contain it (API changed codes,
    // corrupted cache, etc), fall back to the first available zone rather
    // than crashing the dropdown's "exactly one matching item" assertion.
    if (!_zones.any((z) => z.code == _selectedZone) && _zones.isNotEmpty) {
      _selectedZone = _zones.first.code;
    }
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

  Map<String, List<JakimZone>> get _zonesByState {
    final map = <String, List<JakimZone>>{};
    for (final zone in _zones) {
      map.putIfAbsent(zone.state, () => []).add(zone);
    }
    return map;
  }

  List<DropdownMenuItem<String>> _buildGroupedItems(ThemeData theme) {
    final items = <DropdownMenuItem<String>>[];
    for (final stateEntry in _zonesByState.entries) {
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

  JakimZone? get _currentZone {
    for (final zone in _zones) {
      if (zone.code == _selectedZone) return zone;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentZone = _currentZone;

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
          if (currentZone != null) ...[
            const SizedBox(height: 8),
            Text(
              '${currentZone.state} — ${currentZone.area}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
