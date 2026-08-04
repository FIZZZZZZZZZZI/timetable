import 'package:hive/hive.dart';

part 'completion_record.g.dart';

/// Marks a single [ActivitySlot] occurrence as done on a specific calendar
/// [date] (slots repeat weekly, so the same slot can have many records
/// across different weeks).
@HiveType(typeId: 3)
class CompletionRecord extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String slotId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  DateTime completedAt;

  CompletionRecord({
    required this.id,
    required this.slotId,
    required this.date,
    required this.completedAt,
  });
}
