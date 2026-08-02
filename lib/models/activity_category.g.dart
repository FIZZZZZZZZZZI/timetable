// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityCategoryAdapter extends TypeAdapter<ActivityCategory> {
  @override
  final int typeId = 0;

  @override
  ActivityCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ActivityCategory.kelas;
      case 1:
        return ActivityCategory.gym;
      case 2:
        return ActivityCategory.content;
      case 3:
        return ActivityCategory.study;
      case 4:
        return ActivityCategory.other;
      default:
        return ActivityCategory.kelas;
    }
  }

  @override
  void write(BinaryWriter writer, ActivityCategory obj) {
    switch (obj) {
      case ActivityCategory.kelas:
        writer.writeByte(0);
        break;
      case ActivityCategory.gym:
        writer.writeByte(1);
        break;
      case ActivityCategory.content:
        writer.writeByte(2);
        break;
      case ActivityCategory.study:
        writer.writeByte(3);
        break;
      case ActivityCategory.other:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
