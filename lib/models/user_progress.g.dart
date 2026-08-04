// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProgressAdapter extends TypeAdapter<UserProgress> {
  @override
  final int typeId = 4;

  @override
  UserProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProgress(
      totalXp: fields[0] as int,
      currentStreak: fields[1] as int,
      longestStreak: fields[2] as int,
      lastCompletedDate: fields[3] as DateTime?,
      bonusDates: fields[4] == null ? [] : (fields[4] as List?)?.cast<String>(),
      prayerCurrentStreak: fields[5] == null ? 0 : fields[5] as int,
      prayerLongestStreak: fields[6] == null ? 0 : fields[6] as int,
      lastPrayerCompletedDate: fields[7] as DateTime?,
      prayerBonusDates:
          fields[8] == null ? [] : (fields[8] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserProgress obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.totalXp)
      ..writeByte(1)
      ..write(obj.currentStreak)
      ..writeByte(2)
      ..write(obj.longestStreak)
      ..writeByte(3)
      ..write(obj.lastCompletedDate)
      ..writeByte(4)
      ..write(obj.bonusDates)
      ..writeByte(5)
      ..write(obj.prayerCurrentStreak)
      ..writeByte(6)
      ..write(obj.prayerLongestStreak)
      ..writeByte(7)
      ..write(obj.lastPrayerCompletedDate)
      ..writeByte(8)
      ..write(obj.prayerBonusDates);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
