import 'package:hive_flutter/hive_flutter.dart';

import '../models/activity_category.dart';
import '../models/activity_slot.dart';
import '../models/time_of_day_adapter.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const String _boxName = 'activity_slots';

  late Box<ActivitySlot> _box;

  Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ActivityCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ActivitySlotAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TimeOfDayAdapter());
    }

    _box = await Hive.openBox<ActivitySlot>(_boxName);
  }

  List<ActivitySlot> getAll() => _box.values.toList();

  List<ActivitySlot> getForDay(int dayOfWeek) {
    final slots = _box.values.where((s) => s.dayOfWeek == dayOfWeek).toList();
    slots.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return slots;
  }

  Future<void> addSlot(ActivitySlot slot) async {
    await _box.put(slot.id, slot);
  }

  Future<void> updateSlot(ActivitySlot slot) async {
    await _box.put(slot.id, slot);
  }

  Future<void> deleteSlot(String id) async {
    await _box.delete(id);
  }
}
