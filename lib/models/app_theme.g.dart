// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_theme.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppThemeAdapter extends TypeAdapter<AppTheme> {
  @override
  final int typeId = 8;

  @override
  AppTheme read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppTheme(
      id: fields[0] as String,
      name: fields[1] as String,
      isCustom: fields[2] as bool,
      background: fields[3] as int,
      card: fields[4] as int,
      primary: fields[5] as int,
      accent: fields[6] as int,
      textPrimary: fields[7] as int,
      textSecondary: fields[8] as int,
      streakColor: fields[9] as int,
      borderRadius: fields[10] == null ? 16.0 : fields[10] as double,
    );
  }

  @override
  void write(BinaryWriter writer, AppTheme obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.isCustom)
      ..writeByte(3)
      ..write(obj.background)
      ..writeByte(4)
      ..write(obj.card)
      ..writeByte(5)
      ..write(obj.primary)
      ..writeByte(6)
      ..write(obj.accent)
      ..writeByte(7)
      ..write(obj.textPrimary)
      ..writeByte(8)
      ..write(obj.textSecondary)
      ..writeByte(9)
      ..write(obj.streakColor)
      ..writeByte(10)
      ..write(obj.borderRadius);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppThemeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
