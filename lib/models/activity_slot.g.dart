// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_slot.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivitySlotAdapter extends TypeAdapter<ActivitySlot> {
  @override
  final int typeId = 1;

  @override
  ActivitySlot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActivitySlot(
      id: fields[0] as String,
      title: fields[1] as String,
      category: fields[2] as ActivityCategory,
      dayOfWeek: fields[3] as int,
      startTime: fields[4] as TimeOfDay,
      endTime: fields[5] as TimeOfDay,
      location: fields[6] as String?,
      notes: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ActivitySlot obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.dayOfWeek)
      ..writeByte(4)
      ..write(obj.startTime)
      ..writeByte(5)
      ..write(obj.endTime)
      ..writeByte(6)
      ..write(obj.location)
      ..writeByte(7)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivitySlotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
