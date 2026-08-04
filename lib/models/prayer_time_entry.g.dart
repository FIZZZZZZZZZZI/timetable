// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer_time_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PrayerTimeEntryAdapter extends TypeAdapter<PrayerTimeEntry> {
  @override
  final int typeId = 5;

  @override
  PrayerTimeEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrayerTimeEntry(
      id: fields[0] as String,
      zone: fields[1] as String,
      date: fields[2] as DateTime,
      subuh: fields[3] as TimeOfDay,
      zohor: fields[4] as TimeOfDay,
      asar: fields[5] as TimeOfDay,
      maghrib: fields[6] as TimeOfDay,
      isyak: fields[7] as TimeOfDay,
    );
  }

  @override
  void write(BinaryWriter writer, PrayerTimeEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.zone)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.subuh)
      ..writeByte(4)
      ..write(obj.zohor)
      ..writeByte(5)
      ..write(obj.asar)
      ..writeByte(6)
      ..write(obj.maghrib)
      ..writeByte(7)
      ..write(obj.isyak);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerTimeEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
