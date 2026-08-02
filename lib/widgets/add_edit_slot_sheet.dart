import 'package:flutter/material.dart';

import '../models/activity_category.dart';
import '../models/activity_slot.dart';
import '../widgets/category_chip_picker.dart';
import '../widgets/day_tabs.dart';

class AddEditSlotSheet extends StatefulWidget {
  final ActivitySlot? existing;
  final int initialDay;

  const AddEditSlotSheet({
    super.key,
    this.existing,
    required this.initialDay,
  });

  @override
  State<AddEditSlotSheet> createState() => _AddEditSlotSheetState();
}

class _AddEditSlotSheetState extends State<AddEditSlotSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;

  late ActivityCategory _category;
  late int _dayOfWeek;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _locationController = TextEditingController(text: existing?.location ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _category = existing?.category ?? ActivityCategory.kelas;
    _dayOfWeek = existing?.dayOfWeek ?? widget.initialDay;
    _startTime = existing?.startTime ?? const TimeOfDay(hour: 9, minute: 0);
    _endTime = existing?.endTime ?? const TimeOfDay(hour: 10, minute: 0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final slot = ActivitySlot(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      category: _category,
      dayOfWeek: _dayOfWeek,
      startTime: _startTime,
      endTime: _endTime,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    Navigator.of(context).pop(slot);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  _isEditing ? 'Edit Activity' : 'New Activity',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text('Category', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                CategoryChipPicker(
                  selected: _category,
                  onSelected: (c) => setState(() => _category = c),
                ),
                const SizedBox(height: 20),
                Text('Day', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                DayTabs(
                  selectedDay: _dayOfWeek,
                  todayDayOfWeek: DateTime.now().weekday,
                  onDaySelected: (d) => setState(() => _dayOfWeek = d),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _TimeField(
                        label: 'Start',
                        time: _startTime,
                        onTap: () => _pickTime(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimeField(
                        label: 'End',
                        time: _endTime,
                        onTap: () => _pickTime(isStart: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location (optional)',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: Text(_isEditing ? 'Save Changes' : 'Add Activity'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeField({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          time.format(context),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
