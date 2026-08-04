import 'package:hive/hive.dart';

part 'app_theme.g.dart';

/// A full app color theme — either one of the built-in presets or a
/// user-created custom theme. All color fields are stored as ARGB ints
/// (see [Color.toARGB32]/[Color.new]).
@HiveType(typeId: 8)
class AppTheme extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  bool isCustom;

  @HiveField(3)
  int background;

  /// Surface / card color.
  @HiveField(4)
  int card;

  @HiveField(5)
  int primary;

  @HiveField(6)
  int accent;

  @HiveField(7)
  int textPrimary;

  @HiveField(8)
  int textSecondary;

  @HiveField(9)
  int streakColor;

  /// Corner radius for cards/tiles. Not a field the custom builder exposes
  /// (it only picks the 5 colors listed above); presets set it directly to
  /// express their visual identity — e.g. Ninja's sharp 4-6px corners vs.
  /// Default's soft 16px ones. Custom themes default to 16.
  @HiveField(10, defaultValue: 16.0)
  double borderRadius;

  AppTheme({
    required this.id,
    required this.name,
    required this.isCustom,
    required this.background,
    required this.card,
    required this.primary,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.streakColor,
    this.borderRadius = 16.0,
  });
}
