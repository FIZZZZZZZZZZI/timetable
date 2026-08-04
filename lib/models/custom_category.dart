import 'package:hive/hive.dart';

part 'custom_category.g.dart';

/// A user-defined activity category (unlocked at level 5), stored
/// alongside — not replacing — the built-in [ActivityCategory] enum.
@HiveType(typeId: 7)
class CustomCategory extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String emoji;

  /// ARGB int, see [Color.toARGB32]/[Color.new].
  @HiveField(3)
  int colorValue;

  CustomCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
  });
}
