import 'package:flutter/material.dart';

import '../models/custom_category.dart';
import '../models/jakim_zone.dart';
import '../services/custom_category_service.dart';
import '../services/gamification_service.dart';
import '../services/prayer_service.dart';

const List<String> _kEmojiPresets = [
  '📖', '🎨', '🎮', '🧘', '🍳', '🚴',
  '🎵', '🛠️', '🌍', '💼', '🧹', '🐾',
  '☕', '🎯', '📷', '✍️',
];

const List<Color> _kColorPresets = [
  Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
  Colors.indigo, Colors.blue, Colors.cyan, Colors.teal,
  Colors.green, Colors.lime, Colors.amber, Colors.orange,
  Colors.brown, Colors.blueGrey,
];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _prayer = PrayerService.instance;
  final _gamification = GamificationService.instance;
  final _customCategories = CustomCategoryService.instance;

  late List<JakimZone> _zones;
  late String _selectedZone;
  bool _saving = false;

  late List<CustomCategory> _myCategories;
  final _newCategoryNameController = TextEditingController();
  String _newCategoryEmoji = _kEmojiPresets.first;
  Color _newCategoryColor = _kColorPresets.first;

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
    _myCategories = _customCategories.getAll();
  }

  @override
  void dispose() {
    _newCategoryNameController.dispose();
    super.dispose();
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

  Future<void> _addCustomCategory() async {
    final name = _newCategoryNameController.text.trim();
    if (name.isEmpty) return;
    await _customCategories.add(name: name, emoji: _newCategoryEmoji, color: _newCategoryColor);
    _newCategoryNameController.clear();
    setState(() {
      _myCategories = _customCategories.getAll();
      _newCategoryEmoji = _kEmojiPresets.first;
      _newCategoryColor = _kColorPresets.first;
    });
  }

  Future<void> _deleteCustomCategory(String id) async {
    await _customCategories.delete(id);
    setState(() => _myCategories = _customCategories.getAll());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentZone = _currentZone;
    final level = _gamification.currentLevel;

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
          const SizedBox(height: 28),
          Text('Custom Categories', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (level >= 5) _buildCustomCategorySection(theme) else _buildLockedCard(
            theme,
            icon: Icons.category_outlined,
            title: 'Custom Categories',
            description: 'Create your own activity categories with a name, emoji and color.',
            unlockLevel: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildLockedCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String description,
    required int unlockLevel,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Unlocks at Level $unlockLevel',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomCategorySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_myCategories.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in _myCategories)
                Chip(
                  avatar: Text(category.emoji, style: const TextStyle(fontSize: 14)),
                  label: Text(category.name),
                  backgroundColor: Color(category.colorValue).withValues(alpha: 0.15),
                  side: BorderSide(color: Color(category.colorValue).withValues(alpha: 0.4)),
                  onDeleted: () => _deleteCustomCategory(category.id),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New category', style: theme.textTheme.labelLarge),
              const SizedBox(height: 10),
              TextField(
                controller: _newCategoryNameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 14),
              Text('Emoji', style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final emoji in _kEmojiPresets)
                    _EmojiOption(
                      emoji: emoji,
                      selected: emoji == _newCategoryEmoji,
                      onTap: () => setState(() => _newCategoryEmoji = emoji),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text('Color', style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final color in _kColorPresets)
                    _ColorOption(
                      color: color,
                      selected: color.toARGB32() == _newCategoryColor.toARGB32(),
                      onTap: () => setState(() => _newCategoryColor = color),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _addCustomCategory,
                icon: const Icon(Icons.add),
                label: const Text('Add category'),
              ),
            ],
          ),
        ),
      ],
    );
  }

}

class _EmojiOption extends StatelessWidget {
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _EmojiOption({required this.emoji, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorOption({required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected ? Border.all(color: Colors.black87, width: 2.5) : null,
        ),
        child: selected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
      ),
    );
  }
}
