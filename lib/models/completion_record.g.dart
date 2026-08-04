// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'completion_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CompletionRecordAdapter extends TypeAdapter<CompletionRecord> {
  @override
  final int typeId = 3;

  @override
  CompletionRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CompletionRecord(
      id: fields[0] as String,
      slotId: fields[1] as String,
      date: fields[2] as DateTime,
      completedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CompletionRecord obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.slotId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompletionRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
