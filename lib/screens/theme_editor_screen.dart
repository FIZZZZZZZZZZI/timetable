import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../models/app_theme.dart';
import '../services/theme_service.dart';
import '../utils/theme_color_utils.dart';
import '../widgets/theme_preview_card.dart';

/// Full-screen custom theme builder (unlocked at level 12). Users pick 5
/// colors — background, card, primary, accent, streak — text colors are
/// always auto-derived from background luminance, never picked directly.
class ThemeEditorScreen extends StatefulWidget {
  final AppTheme? existing;

  const ThemeEditorScreen({super.key, this.existing});

  @override
  State<ThemeEditorScreen> createState() => _ThemeEditorScreenState();
}

class _ThemeEditorScreenState extends State<ThemeEditorScreen> {
  final _nameController = TextEditingController();
  late Color _background;
  late Color _card;
  late Color _primary;
  late Color _accent;
  late Color _streak;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController.text = existing?.name ?? '';
    _background = existing != null ? Color(existing.background) : const Color(0xFF1F1220);
    _card = existing != null ? Color(existing.card) : const Color(0xFF2E1B2E);
    _primary = existing != null ? Color(existing.primary) : const Color(0xFF3F51B5);
    _accent = existing != null ? Color(existing.accent) : const Color(0xFF5C6BC0);
    _streak = existing != null ? Color(existing.streakColor) : const Color(0xFFFF5722);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  AppTheme get _previewTheme {
    final derived = deriveTextColors(_background);
    return AppTheme(
      id: 'preview',
      name: _nameController.text.trim().isEmpty ? 'Preview' : _nameController.text.trim(),
      isCustom: true,
      background: _background.toARGB32(),
      card: _card.toARGB32(),
      primary: _primary.toARGB32(),
      accent: _accent.toARGB32(),
      textPrimary: derived.textPrimary,
      textSecondary: derived.textSecondary,
      streakColor: _streak.toARGB32(),
    );
  }

  Future<void> _pickColor({
    required String label,
    required Color initial,
    required ValueChanged<Color> onSelected,
  }) async {
    var picked = initial;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pick $label color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: initial,
            onColorChanged: (c) => picked = c,
            enableAlpha: false,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Select'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      onSelected(picked);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your theme a name')),
      );
      return;
    }

    await ThemeService.instance.saveCustomTheme(
      id: widget.existing?.id,
      name: name,
      background: _background,
      card: _card,
      primary: _primary,
      accent: _accent,
      streakColor: _streak,
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete theme?'),
        content: Text('"${existing.name}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ThemeService.instance.deleteCustomTheme(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Theme' : 'New Theme'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete theme',
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Theme name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Text('Preview', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ThemePreviewCard(theme: _previewTheme),
          ),
          const SizedBox(height: 20),
          Text('Colors', style: theme.textTheme.labelLarge),
          _ColorRow(
            label: 'Background',
            color: _background,
            onTap: () => _pickColor(
              label: 'background',
              initial: _background,
              onSelected: (c) => setState(() => _background = c),
            ),
          ),
          _ColorRow(
            label: 'Card',
            color: _card,
            onTap: () => _pickColor(
              label: 'card',
              initial: _card,
              onSelected: (c) => setState(() => _card = c),
            ),
          ),
          _ColorRow(
            label: 'Primary',
            color: _primary,
            onTap: () => _pickColor(
              label: 'primary',
              initial: _primary,
              onSelected: (c) => setState(() => _primary = c),
            ),
          ),
          _ColorRow(
            label: 'Accent',
            color: _accent,
            onTap: () => _pickColor(
              label: 'accent',
              initial: _accent,
              onSelected: (c) => setState(() => _accent = c),
            ),
          ),
          _ColorRow(
            label: 'Streak',
            color: _streak,
            onTap: () => _pickColor(
              label: 'streak',
              initial: _streak,
              onSelected: (c) => setState(() => _streak = c),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: Text(_isEditing ? 'Save Changes' : 'Create Theme'),
          ),
        ],
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ColorRow({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
            Text(
              '#$hex',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
