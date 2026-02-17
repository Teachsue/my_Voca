// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WordAdapter extends TypeAdapter<Word> {
  @override
  final int typeId = 0;

  @override
  Word read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Word(
      spelling: fields[0] as String,
      meaning: fields[1] as String,
      nextReviewDate: fields[2] as DateTime?,
      reviewInterval: fields[3] as int,
      easeFactor: fields[4] as double,
      category: fields[5] as String,
      level: fields[6] as String,
      type: fields[7] as String,
      correctAnswer: fields[8] as String?,
      options: (fields[9] as List?)?.cast<String>(),
      explanation: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Word obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.spelling)
      ..writeByte(1)
      ..write(obj.meaning)
      ..writeByte(2)
      ..write(obj.nextReviewDate)
      ..writeByte(3)
      ..write(obj.reviewInterval)
      ..writeByte(4)
      ..write(obj.easeFactor)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.level)
      ..writeByte(7)
      ..write(obj.type)
      ..writeByte(8)
      ..write(obj.correctAnswer)
      ..writeByte(9)
      ..write(obj.options)
      ..writeByte(10)
      ..write(obj.explanation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
