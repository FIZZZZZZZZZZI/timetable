import 'package:hive/hive.dart';

part 'achievement.g.dart';

/// Records that a badge (see lib/data/badges.dart) has been unlocked, and
/// when. Keyed by badge id in its box, so one record per badge ever.
@HiveType(typeId: 6)
class Achievement extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime unlockedAt;

  Achievement({required this.id, required this.unlockedAt});
}
