// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SemestersTable extends Semesters
    with TableInfo<$SemestersTable, SemesterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SemestersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _semesterNumberMeta = const VerificationMeta(
    'semesterNumber',
  );
  @override
  late final GeneratedColumn<int> semesterNumber = GeneratedColumn<int>(
    'semester_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _academicYearMeta = const VerificationMeta(
    'academicYear',
  );
  @override
  late final GeneratedColumn<String> academicYear = GeneratedColumn<String>(
    'academic_year',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> startDate =
      GeneratedColumn<int>(
        'start_date',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SemestersTable.$converterstartDate);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> endDate =
      GeneratedColumn<int>(
        'end_date',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SemestersTable.$converterendDate);
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: currentUtcMilliseconds,
      ).withConverter<DateTime>($SemestersTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: currentUtcMilliseconds,
      ).withConverter<DateTime>($SemestersTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    semesterNumber,
    academicYear,
    startDate,
    endDate,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'semesters';
  @override
  VerificationContext validateIntegrity(
    Insertable<SemesterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('semester_number')) {
      context.handle(
        _semesterNumberMeta,
        semesterNumber.isAcceptableOrUnknown(
          data['semester_number']!,
          _semesterNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_semesterNumberMeta);
    }
    if (data.containsKey('academic_year')) {
      context.handle(
        _academicYearMeta,
        academicYear.isAcceptableOrUnknown(
          data['academic_year']!,
          _academicYearMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_academicYearMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SemesterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SemesterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      semesterNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}semester_number'],
      )!,
      academicYear: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}academic_year'],
      )!,
      startDate: $SemestersTable.$converterstartDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}start_date'],
        )!,
      ),
      endDate: $SemestersTable.$converterendDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}end_date'],
        )!,
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: $SemestersTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $SemestersTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $SemestersTable createAlias(String alias) {
    return $SemestersTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterstartDate =
      const EpochDayConverter();
  static TypeConverter<DateTime, int> $converterendDate =
      const EpochDayConverter();
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class SemesterRow extends DataClass implements Insertable<SemesterRow> {
  final int id;
  final String name;
  final int semesterNumber;
  final String academicYear;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SemesterRow({
    required this.id,
    required this.name,
    required this.semesterNumber,
    required this.academicYear,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['semester_number'] = Variable<int>(semesterNumber);
    map['academic_year'] = Variable<String>(academicYear);
    {
      map['start_date'] = Variable<int>(
        $SemestersTable.$converterstartDate.toSql(startDate),
      );
    }
    {
      map['end_date'] = Variable<int>(
        $SemestersTable.$converterendDate.toSql(endDate),
      );
    }
    map['is_active'] = Variable<bool>(isActive);
    {
      map['created_at'] = Variable<int>(
        $SemestersTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $SemestersTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  SemestersCompanion toCompanion(bool nullToAbsent) {
    return SemestersCompanion(
      id: Value(id),
      name: Value(name),
      semesterNumber: Value(semesterNumber),
      academicYear: Value(academicYear),
      startDate: Value(startDate),
      endDate: Value(endDate),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SemesterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SemesterRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      semesterNumber: serializer.fromJson<int>(json['semesterNumber']),
      academicYear: serializer.fromJson<String>(json['academicYear']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime>(json['endDate']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'semesterNumber': serializer.toJson<int>(semesterNumber),
      'academicYear': serializer.toJson<String>(academicYear),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime>(endDate),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SemesterRow copyWith({
    int? id,
    String? name,
    int? semesterNumber,
    String? academicYear,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SemesterRow(
    id: id ?? this.id,
    name: name ?? this.name,
    semesterNumber: semesterNumber ?? this.semesterNumber,
    academicYear: academicYear ?? this.academicYear,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SemesterRow copyWithCompanion(SemestersCompanion data) {
    return SemesterRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      semesterNumber: data.semesterNumber.present
          ? data.semesterNumber.value
          : this.semesterNumber,
      academicYear: data.academicYear.present
          ? data.academicYear.value
          : this.academicYear,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SemesterRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('semesterNumber: $semesterNumber, ')
          ..write('academicYear: $academicYear, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    semesterNumber,
    academicYear,
    startDate,
    endDate,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SemesterRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.semesterNumber == this.semesterNumber &&
          other.academicYear == this.academicYear &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SemestersCompanion extends UpdateCompanion<SemesterRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> semesterNumber;
  final Value<String> academicYear;
  final Value<DateTime> startDate;
  final Value<DateTime> endDate;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SemestersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.semesterNumber = const Value.absent(),
    this.academicYear = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SemestersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int semesterNumber,
    required String academicYear,
    required DateTime startDate,
    required DateTime endDate,
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name),
       semesterNumber = Value(semesterNumber),
       academicYear = Value(academicYear),
       startDate = Value(startDate),
       endDate = Value(endDate);
  static Insertable<SemesterRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? semesterNumber,
    Expression<String>? academicYear,
    Expression<int>? startDate,
    Expression<int>? endDate,
    Expression<bool>? isActive,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (semesterNumber != null) 'semester_number': semesterNumber,
      if (academicYear != null) 'academic_year': academicYear,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SemestersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? semesterNumber,
    Value<String>? academicYear,
    Value<DateTime>? startDate,
    Value<DateTime>? endDate,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SemestersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      semesterNumber: semesterNumber ?? this.semesterNumber,
      academicYear: academicYear ?? this.academicYear,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (semesterNumber.present) {
      map['semester_number'] = Variable<int>(semesterNumber.value);
    }
    if (academicYear.present) {
      map['academic_year'] = Variable<String>(academicYear.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<int>(
        $SemestersTable.$converterstartDate.toSql(startDate.value),
      );
    }
    if (endDate.present) {
      map['end_date'] = Variable<int>(
        $SemestersTable.$converterendDate.toSql(endDate.value),
      );
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $SemestersTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $SemestersTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SemestersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('semesterNumber: $semesterNumber, ')
          ..write('academicYear: $academicYear, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SubjectsTable extends Subjects
    with TableInfo<$SubjectsTable, SubjectRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _semesterIdMeta = const VerificationMeta(
    'semesterId',
  );
  @override
  late final GeneratedColumn<int> semesterId = GeneratedColumn<int>(
    'semester_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES semesters (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shortCodeMeta = const VerificationMeta(
    'shortCode',
  );
  @override
  late final GeneratedColumn<String> shortCode = GeneratedColumn<String>(
    'short_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _professorMeta = const VerificationMeta(
    'professor',
  );
  @override
  late final GeneratedColumn<String> professor = GeneratedColumn<String>(
    'professor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _roomMeta = const VerificationMeta('room');
  @override
  late final GeneratedColumn<String> room = GeneratedColumn<String>(
    'room',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _attendanceTargetMeta = const VerificationMeta(
    'attendanceTarget',
  );
  @override
  late final GeneratedColumn<double> attendanceTarget = GeneratedColumn<double>(
    'attendance_target',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.75),
  );
  static const VerificationMeta _displayColorMeta = const VerificationMeta(
    'displayColor',
  );
  @override
  late final GeneratedColumn<int> displayColor = GeneratedColumn<int>(
    'display_color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: currentUtcMilliseconds,
      ).withConverter<DateTime>($SubjectsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: currentUtcMilliseconds,
      ).withConverter<DateTime>($SubjectsTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    semesterId,
    name,
    shortCode,
    professor,
    room,
    attendanceTarget,
    displayColor,
    isArchived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subjects';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubjectRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('semester_id')) {
      context.handle(
        _semesterIdMeta,
        semesterId.isAcceptableOrUnknown(data['semester_id']!, _semesterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('short_code')) {
      context.handle(
        _shortCodeMeta,
        shortCode.isAcceptableOrUnknown(data['short_code']!, _shortCodeMeta),
      );
    }
    if (data.containsKey('professor')) {
      context.handle(
        _professorMeta,
        professor.isAcceptableOrUnknown(data['professor']!, _professorMeta),
      );
    }
    if (data.containsKey('room')) {
      context.handle(
        _roomMeta,
        room.isAcceptableOrUnknown(data['room']!, _roomMeta),
      );
    }
    if (data.containsKey('attendance_target')) {
      context.handle(
        _attendanceTargetMeta,
        attendanceTarget.isAcceptableOrUnknown(
          data['attendance_target']!,
          _attendanceTargetMeta,
        ),
      );
    }
    if (data.containsKey('display_color')) {
      context.handle(
        _displayColorMeta,
        displayColor.isAcceptableOrUnknown(
          data['display_color']!,
          _displayColorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayColorMeta);
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubjectRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubjectRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      semesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}semester_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      shortCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}short_code'],
      )!,
      professor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}professor'],
      )!,
      room: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room'],
      )!,
      attendanceTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}attendance_target'],
      )!,
      displayColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_color'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: $SubjectsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $SubjectsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $SubjectsTable createAlias(String alias) {
    return $SubjectsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class SubjectRow extends DataClass implements Insertable<SubjectRow> {
  final int id;
  final int semesterId;
  final String name;
  final String shortCode;
  final String professor;
  final String room;
  final double attendanceTarget;
  final int displayColor;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SubjectRow({
    required this.id,
    required this.semesterId,
    required this.name,
    required this.shortCode,
    required this.professor,
    required this.room,
    required this.attendanceTarget,
    required this.displayColor,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['semester_id'] = Variable<int>(semesterId);
    map['name'] = Variable<String>(name);
    map['short_code'] = Variable<String>(shortCode);
    map['professor'] = Variable<String>(professor);
    map['room'] = Variable<String>(room);
    map['attendance_target'] = Variable<double>(attendanceTarget);
    map['display_color'] = Variable<int>(displayColor);
    map['is_archived'] = Variable<bool>(isArchived);
    {
      map['created_at'] = Variable<int>(
        $SubjectsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $SubjectsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  SubjectsCompanion toCompanion(bool nullToAbsent) {
    return SubjectsCompanion(
      id: Value(id),
      semesterId: Value(semesterId),
      name: Value(name),
      shortCode: Value(shortCode),
      professor: Value(professor),
      room: Value(room),
      attendanceTarget: Value(attendanceTarget),
      displayColor: Value(displayColor),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SubjectRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubjectRow(
      id: serializer.fromJson<int>(json['id']),
      semesterId: serializer.fromJson<int>(json['semesterId']),
      name: serializer.fromJson<String>(json['name']),
      shortCode: serializer.fromJson<String>(json['shortCode']),
      professor: serializer.fromJson<String>(json['professor']),
      room: serializer.fromJson<String>(json['room']),
      attendanceTarget: serializer.fromJson<double>(json['attendanceTarget']),
      displayColor: serializer.fromJson<int>(json['displayColor']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'semesterId': serializer.toJson<int>(semesterId),
      'name': serializer.toJson<String>(name),
      'shortCode': serializer.toJson<String>(shortCode),
      'professor': serializer.toJson<String>(professor),
      'room': serializer.toJson<String>(room),
      'attendanceTarget': serializer.toJson<double>(attendanceTarget),
      'displayColor': serializer.toJson<int>(displayColor),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SubjectRow copyWith({
    int? id,
    int? semesterId,
    String? name,
    String? shortCode,
    String? professor,
    String? room,
    double? attendanceTarget,
    int? displayColor,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SubjectRow(
    id: id ?? this.id,
    semesterId: semesterId ?? this.semesterId,
    name: name ?? this.name,
    shortCode: shortCode ?? this.shortCode,
    professor: professor ?? this.professor,
    room: room ?? this.room,
    attendanceTarget: attendanceTarget ?? this.attendanceTarget,
    displayColor: displayColor ?? this.displayColor,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SubjectRow copyWithCompanion(SubjectsCompanion data) {
    return SubjectRow(
      id: data.id.present ? data.id.value : this.id,
      semesterId: data.semesterId.present
          ? data.semesterId.value
          : this.semesterId,
      name: data.name.present ? data.name.value : this.name,
      shortCode: data.shortCode.present ? data.shortCode.value : this.shortCode,
      professor: data.professor.present ? data.professor.value : this.professor,
      room: data.room.present ? data.room.value : this.room,
      attendanceTarget: data.attendanceTarget.present
          ? data.attendanceTarget.value
          : this.attendanceTarget,
      displayColor: data.displayColor.present
          ? data.displayColor.value
          : this.displayColor,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubjectRow(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('name: $name, ')
          ..write('shortCode: $shortCode, ')
          ..write('professor: $professor, ')
          ..write('room: $room, ')
          ..write('attendanceTarget: $attendanceTarget, ')
          ..write('displayColor: $displayColor, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    semesterId,
    name,
    shortCode,
    professor,
    room,
    attendanceTarget,
    displayColor,
    isArchived,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubjectRow &&
          other.id == this.id &&
          other.semesterId == this.semesterId &&
          other.name == this.name &&
          other.shortCode == this.shortCode &&
          other.professor == this.professor &&
          other.room == this.room &&
          other.attendanceTarget == this.attendanceTarget &&
          other.displayColor == this.displayColor &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SubjectsCompanion extends UpdateCompanion<SubjectRow> {
  final Value<int> id;
  final Value<int> semesterId;
  final Value<String> name;
  final Value<String> shortCode;
  final Value<String> professor;
  final Value<String> room;
  final Value<double> attendanceTarget;
  final Value<int> displayColor;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SubjectsCompanion({
    this.id = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.name = const Value.absent(),
    this.shortCode = const Value.absent(),
    this.professor = const Value.absent(),
    this.room = const Value.absent(),
    this.attendanceTarget = const Value.absent(),
    this.displayColor = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SubjectsCompanion.insert({
    this.id = const Value.absent(),
    required int semesterId,
    required String name,
    this.shortCode = const Value.absent(),
    this.professor = const Value.absent(),
    this.room = const Value.absent(),
    this.attendanceTarget = const Value.absent(),
    required int displayColor,
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : semesterId = Value(semesterId),
       name = Value(name),
       displayColor = Value(displayColor);
  static Insertable<SubjectRow> custom({
    Expression<int>? id,
    Expression<int>? semesterId,
    Expression<String>? name,
    Expression<String>? shortCode,
    Expression<String>? professor,
    Expression<String>? room,
    Expression<double>? attendanceTarget,
    Expression<int>? displayColor,
    Expression<bool>? isArchived,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (semesterId != null) 'semester_id': semesterId,
      if (name != null) 'name': name,
      if (shortCode != null) 'short_code': shortCode,
      if (professor != null) 'professor': professor,
      if (room != null) 'room': room,
      if (attendanceTarget != null) 'attendance_target': attendanceTarget,
      if (displayColor != null) 'display_color': displayColor,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SubjectsCompanion copyWith({
    Value<int>? id,
    Value<int>? semesterId,
    Value<String>? name,
    Value<String>? shortCode,
    Value<String>? professor,
    Value<String>? room,
    Value<double>? attendanceTarget,
    Value<int>? displayColor,
    Value<bool>? isArchived,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SubjectsCompanion(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      name: name ?? this.name,
      shortCode: shortCode ?? this.shortCode,
      professor: professor ?? this.professor,
      room: room ?? this.room,
      attendanceTarget: attendanceTarget ?? this.attendanceTarget,
      displayColor: displayColor ?? this.displayColor,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<int>(semesterId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (shortCode.present) {
      map['short_code'] = Variable<String>(shortCode.value);
    }
    if (professor.present) {
      map['professor'] = Variable<String>(professor.value);
    }
    if (room.present) {
      map['room'] = Variable<String>(room.value);
    }
    if (attendanceTarget.present) {
      map['attendance_target'] = Variable<double>(attendanceTarget.value);
    }
    if (displayColor.present) {
      map['display_color'] = Variable<int>(displayColor.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $SubjectsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $SubjectsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectsCompanion(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('name: $name, ')
          ..write('shortCode: $shortCode, ')
          ..write('professor: $professor, ')
          ..write('room: $room, ')
          ..write('attendanceTarget: $attendanceTarget, ')
          ..write('displayColor: $displayColor, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SubjectFilesTable extends SubjectFiles
    with TableInfo<$SubjectFilesTable, SubjectFileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubjectFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<int> subjectId = GeneratedColumn<int>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES subjects (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _semesterIdMeta = const VerificationMeta(
    'semesterId',
  );
  @override
  late final GeneratedColumn<int> semesterId = GeneratedColumn<int>(
    'semester_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES semesters (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileExtensionMeta = const VerificationMeta(
    'fileExtension',
  );
  @override
  late final GeneratedColumn<String> fileExtension = GeneratedColumn<String>(
    'file_extension',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeBytesMeta = const VerificationMeta(
    'fileSizeBytes',
  );
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
    'file_size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _relativeFilePathMeta = const VerificationMeta(
    'relativeFilePath',
  );
  @override
  late final GeneratedColumn<String> relativeFilePath = GeneratedColumn<String>(
    'relative_file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: currentUtcMilliseconds,
      ).withConverter<DateTime>($SubjectFilesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: currentUtcMilliseconds,
      ).withConverter<DateTime>($SubjectFilesTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    subjectId,
    semesterId,
    title,
    fileName,
    fileExtension,
    fileSizeBytes,
    mimeType,
    relativeFilePath,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subject_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubjectFileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('semester_id')) {
      context.handle(
        _semesterIdMeta,
        semesterId.isAcceptableOrUnknown(data['semester_id']!, _semesterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('file_extension')) {
      context.handle(
        _fileExtensionMeta,
        fileExtension.isAcceptableOrUnknown(
          data['file_extension']!,
          _fileExtensionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fileExtensionMeta);
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
        _fileSizeBytesMeta,
        fileSizeBytes.isAcceptableOrUnknown(
          data['file_size_bytes']!,
          _fileSizeBytesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fileSizeBytesMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    if (data.containsKey('relative_file_path')) {
      context.handle(
        _relativeFilePathMeta,
        relativeFilePath.isAcceptableOrUnknown(
          data['relative_file_path']!,
          _relativeFilePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativeFilePathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubjectFileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubjectFileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subject_id'],
      )!,
      semesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}semester_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      fileExtension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_extension'],
      )!,
      fileSizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size_bytes'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      relativeFilePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_file_path'],
      )!,
      createdAt: $SubjectFilesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $SubjectFilesTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $SubjectFilesTable createAlias(String alias) {
    return $SubjectFilesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class SubjectFileRow extends DataClass implements Insertable<SubjectFileRow> {
  final int id;
  final int subjectId;
  final int semesterId;
  final String title;
  final String fileName;
  final String fileExtension;
  final int fileSizeBytes;
  final String mimeType;
  final String relativeFilePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SubjectFileRow({
    required this.id,
    required this.subjectId,
    required this.semesterId,
    required this.title,
    required this.fileName,
    required this.fileExtension,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.relativeFilePath,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['subject_id'] = Variable<int>(subjectId);
    map['semester_id'] = Variable<int>(semesterId);
    map['title'] = Variable<String>(title);
    map['file_name'] = Variable<String>(fileName);
    map['file_extension'] = Variable<String>(fileExtension);
    map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    map['mime_type'] = Variable<String>(mimeType);
    map['relative_file_path'] = Variable<String>(relativeFilePath);
    {
      map['created_at'] = Variable<int>(
        $SubjectFilesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $SubjectFilesTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  SubjectFilesCompanion toCompanion(bool nullToAbsent) {
    return SubjectFilesCompanion(
      id: Value(id),
      subjectId: Value(subjectId),
      semesterId: Value(semesterId),
      title: Value(title),
      fileName: Value(fileName),
      fileExtension: Value(fileExtension),
      fileSizeBytes: Value(fileSizeBytes),
      mimeType: Value(mimeType),
      relativeFilePath: Value(relativeFilePath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SubjectFileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubjectFileRow(
      id: serializer.fromJson<int>(json['id']),
      subjectId: serializer.fromJson<int>(json['subjectId']),
      semesterId: serializer.fromJson<int>(json['semesterId']),
      title: serializer.fromJson<String>(json['title']),
      fileName: serializer.fromJson<String>(json['fileName']),
      fileExtension: serializer.fromJson<String>(json['fileExtension']),
      fileSizeBytes: serializer.fromJson<int>(json['fileSizeBytes']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      relativeFilePath: serializer.fromJson<String>(json['relativeFilePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'subjectId': serializer.toJson<int>(subjectId),
      'semesterId': serializer.toJson<int>(semesterId),
      'title': serializer.toJson<String>(title),
      'fileName': serializer.toJson<String>(fileName),
      'fileExtension': serializer.toJson<String>(fileExtension),
      'fileSizeBytes': serializer.toJson<int>(fileSizeBytes),
      'mimeType': serializer.toJson<String>(mimeType),
      'relativeFilePath': serializer.toJson<String>(relativeFilePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SubjectFileRow copyWith({
    int? id,
    int? subjectId,
    int? semesterId,
    String? title,
    String? fileName,
    String? fileExtension,
    int? fileSizeBytes,
    String? mimeType,
    String? relativeFilePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SubjectFileRow(
    id: id ?? this.id,
    subjectId: subjectId ?? this.subjectId,
    semesterId: semesterId ?? this.semesterId,
    title: title ?? this.title,
    fileName: fileName ?? this.fileName,
    fileExtension: fileExtension ?? this.fileExtension,
    fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    mimeType: mimeType ?? this.mimeType,
    relativeFilePath: relativeFilePath ?? this.relativeFilePath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SubjectFileRow copyWithCompanion(SubjectFilesCompanion data) {
    return SubjectFileRow(
      id: data.id.present ? data.id.value : this.id,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      semesterId: data.semesterId.present
          ? data.semesterId.value
          : this.semesterId,
      title: data.title.present ? data.title.value : this.title,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      fileExtension: data.fileExtension.present
          ? data.fileExtension.value
          : this.fileExtension,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      relativeFilePath: data.relativeFilePath.present
          ? data.relativeFilePath.value
          : this.relativeFilePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubjectFileRow(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('semesterId: $semesterId, ')
          ..write('title: $title, ')
          ..write('fileName: $fileName, ')
          ..write('fileExtension: $fileExtension, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('relativeFilePath: $relativeFilePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    subjectId,
    semesterId,
    title,
    fileName,
    fileExtension,
    fileSizeBytes,
    mimeType,
    relativeFilePath,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubjectFileRow &&
          other.id == this.id &&
          other.subjectId == this.subjectId &&
          other.semesterId == this.semesterId &&
          other.title == this.title &&
          other.fileName == this.fileName &&
          other.fileExtension == this.fileExtension &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.mimeType == this.mimeType &&
          other.relativeFilePath == this.relativeFilePath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SubjectFilesCompanion extends UpdateCompanion<SubjectFileRow> {
  final Value<int> id;
  final Value<int> subjectId;
  final Value<int> semesterId;
  final Value<String> title;
  final Value<String> fileName;
  final Value<String> fileExtension;
  final Value<int> fileSizeBytes;
  final Value<String> mimeType;
  final Value<String> relativeFilePath;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SubjectFilesCompanion({
    this.id = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.title = const Value.absent(),
    this.fileName = const Value.absent(),
    this.fileExtension = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.relativeFilePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SubjectFilesCompanion.insert({
    this.id = const Value.absent(),
    required int subjectId,
    required int semesterId,
    this.title = const Value.absent(),
    required String fileName,
    required String fileExtension,
    required int fileSizeBytes,
    this.mimeType = const Value.absent(),
    required String relativeFilePath,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : subjectId = Value(subjectId),
       semesterId = Value(semesterId),
       fileName = Value(fileName),
       fileExtension = Value(fileExtension),
       fileSizeBytes = Value(fileSizeBytes),
       relativeFilePath = Value(relativeFilePath);
  static Insertable<SubjectFileRow> custom({
    Expression<int>? id,
    Expression<int>? subjectId,
    Expression<int>? semesterId,
    Expression<String>? title,
    Expression<String>? fileName,
    Expression<String>? fileExtension,
    Expression<int>? fileSizeBytes,
    Expression<String>? mimeType,
    Expression<String>? relativeFilePath,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subjectId != null) 'subject_id': subjectId,
      if (semesterId != null) 'semester_id': semesterId,
      if (title != null) 'title': title,
      if (fileName != null) 'file_name': fileName,
      if (fileExtension != null) 'file_extension': fileExtension,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (mimeType != null) 'mime_type': mimeType,
      if (relativeFilePath != null) 'relative_file_path': relativeFilePath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SubjectFilesCompanion copyWith({
    Value<int>? id,
    Value<int>? subjectId,
    Value<int>? semesterId,
    Value<String>? title,
    Value<String>? fileName,
    Value<String>? fileExtension,
    Value<int>? fileSizeBytes,
    Value<String>? mimeType,
    Value<String>? relativeFilePath,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SubjectFilesCompanion(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      semesterId: semesterId ?? this.semesterId,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      fileExtension: fileExtension ?? this.fileExtension,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      relativeFilePath: relativeFilePath ?? this.relativeFilePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<int>(subjectId.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<int>(semesterId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (fileExtension.present) {
      map['file_extension'] = Variable<String>(fileExtension.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (relativeFilePath.present) {
      map['relative_file_path'] = Variable<String>(relativeFilePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $SubjectFilesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $SubjectFilesTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectFilesCompanion(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('semesterId: $semesterId, ')
          ..write('title: $title, ')
          ..write('fileName: $fileName, ')
          ..write('fileExtension: $fileExtension, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('relativeFilePath: $relativeFilePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class PdfSearchMetadata extends Table
    with TableInfo<PdfSearchMetadata, PdfSearchMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PdfSearchMetadata(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  late final GeneratedColumn<int> fileId = GeneratedColumn<int>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL PRIMARY KEY REFERENCES subject_files(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _indexedAtMeta = const VerificationMeta(
    'indexedAt',
  );
  late final GeneratedColumn<int> indexedAt = GeneratedColumn<int>(
    'indexed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _lastIndexedPageMeta = const VerificationMeta(
    'lastIndexedPage',
  );
  late final GeneratedColumn<int> lastIndexedPage = GeneratedColumn<int>(
    'last_indexed_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    fileId,
    status,
    pageCount,
    indexedAt,
    lastIndexedPage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pdf_search_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<PdfSearchMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    }
    if (data.containsKey('indexed_at')) {
      context.handle(
        _indexedAtMeta,
        indexedAt.isAcceptableOrUnknown(data['indexed_at']!, _indexedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_indexedAtMeta);
    }
    if (data.containsKey('last_indexed_page')) {
      context.handle(
        _lastIndexedPageMeta,
        lastIndexedPage.isAcceptableOrUnknown(
          data['last_indexed_page']!,
          _lastIndexedPageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fileId};
  @override
  PdfSearchMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PdfSearchMetadataData(
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      )!,
      indexedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}indexed_at'],
      )!,
      lastIndexedPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_indexed_page'],
      )!,
    );
  }

  @override
  PdfSearchMetadata createAlias(String alias) {
    return PdfSearchMetadata(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class PdfSearchMetadataData extends DataClass
    implements Insertable<PdfSearchMetadataData> {
  final int fileId;
  final String status;
  final int pageCount;
  final int indexedAt;

  /// Highest page number already extracted into pdf_page_fts for this file.
  /// An interrupted run resumes from last_indexed_page + 1 instead of wiping
  /// the pages it already stored.  0 means "nothing extracted yet".
  final int lastIndexedPage;
  const PdfSearchMetadataData({
    required this.fileId,
    required this.status,
    required this.pageCount,
    required this.indexedAt,
    required this.lastIndexedPage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['file_id'] = Variable<int>(fileId);
    map['status'] = Variable<String>(status);
    map['page_count'] = Variable<int>(pageCount);
    map['indexed_at'] = Variable<int>(indexedAt);
    map['last_indexed_page'] = Variable<int>(lastIndexedPage);
    return map;
  }

  PdfSearchMetadataCompanion toCompanion(bool nullToAbsent) {
    return PdfSearchMetadataCompanion(
      fileId: Value(fileId),
      status: Value(status),
      pageCount: Value(pageCount),
      indexedAt: Value(indexedAt),
      lastIndexedPage: Value(lastIndexedPage),
    );
  }

  factory PdfSearchMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PdfSearchMetadataData(
      fileId: serializer.fromJson<int>(json['file_id']),
      status: serializer.fromJson<String>(json['status']),
      pageCount: serializer.fromJson<int>(json['page_count']),
      indexedAt: serializer.fromJson<int>(json['indexed_at']),
      lastIndexedPage: serializer.fromJson<int>(json['last_indexed_page']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'file_id': serializer.toJson<int>(fileId),
      'status': serializer.toJson<String>(status),
      'page_count': serializer.toJson<int>(pageCount),
      'indexed_at': serializer.toJson<int>(indexedAt),
      'last_indexed_page': serializer.toJson<int>(lastIndexedPage),
    };
  }

  PdfSearchMetadataData copyWith({
    int? fileId,
    String? status,
    int? pageCount,
    int? indexedAt,
    int? lastIndexedPage,
  }) => PdfSearchMetadataData(
    fileId: fileId ?? this.fileId,
    status: status ?? this.status,
    pageCount: pageCount ?? this.pageCount,
    indexedAt: indexedAt ?? this.indexedAt,
    lastIndexedPage: lastIndexedPage ?? this.lastIndexedPage,
  );
  PdfSearchMetadataData copyWithCompanion(PdfSearchMetadataCompanion data) {
    return PdfSearchMetadataData(
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      status: data.status.present ? data.status.value : this.status,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      indexedAt: data.indexedAt.present ? data.indexedAt.value : this.indexedAt,
      lastIndexedPage: data.lastIndexedPage.present
          ? data.lastIndexedPage.value
          : this.lastIndexedPage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PdfSearchMetadataData(')
          ..write('fileId: $fileId, ')
          ..write('status: $status, ')
          ..write('pageCount: $pageCount, ')
          ..write('indexedAt: $indexedAt, ')
          ..write('lastIndexedPage: $lastIndexedPage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(fileId, status, pageCount, indexedAt, lastIndexedPage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PdfSearchMetadataData &&
          other.fileId == this.fileId &&
          other.status == this.status &&
          other.pageCount == this.pageCount &&
          other.indexedAt == this.indexedAt &&
          other.lastIndexedPage == this.lastIndexedPage);
}

class PdfSearchMetadataCompanion
    extends UpdateCompanion<PdfSearchMetadataData> {
  final Value<int> fileId;
  final Value<String> status;
  final Value<int> pageCount;
  final Value<int> indexedAt;
  final Value<int> lastIndexedPage;
  const PdfSearchMetadataCompanion({
    this.fileId = const Value.absent(),
    this.status = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.indexedAt = const Value.absent(),
    this.lastIndexedPage = const Value.absent(),
  });
  PdfSearchMetadataCompanion.insert({
    this.fileId = const Value.absent(),
    required String status,
    this.pageCount = const Value.absent(),
    required int indexedAt,
    this.lastIndexedPage = const Value.absent(),
  }) : status = Value(status),
       indexedAt = Value(indexedAt);
  static Insertable<PdfSearchMetadataData> custom({
    Expression<int>? fileId,
    Expression<String>? status,
    Expression<int>? pageCount,
    Expression<int>? indexedAt,
    Expression<int>? lastIndexedPage,
  }) {
    return RawValuesInsertable({
      if (fileId != null) 'file_id': fileId,
      if (status != null) 'status': status,
      if (pageCount != null) 'page_count': pageCount,
      if (indexedAt != null) 'indexed_at': indexedAt,
      if (lastIndexedPage != null) 'last_indexed_page': lastIndexedPage,
    });
  }

  PdfSearchMetadataCompanion copyWith({
    Value<int>? fileId,
    Value<String>? status,
    Value<int>? pageCount,
    Value<int>? indexedAt,
    Value<int>? lastIndexedPage,
  }) {
    return PdfSearchMetadataCompanion(
      fileId: fileId ?? this.fileId,
      status: status ?? this.status,
      pageCount: pageCount ?? this.pageCount,
      indexedAt: indexedAt ?? this.indexedAt,
      lastIndexedPage: lastIndexedPage ?? this.lastIndexedPage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fileId.present) {
      map['file_id'] = Variable<int>(fileId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (indexedAt.present) {
      map['indexed_at'] = Variable<int>(indexedAt.value);
    }
    if (lastIndexedPage.present) {
      map['last_indexed_page'] = Variable<int>(lastIndexedPage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PdfSearchMetadataCompanion(')
          ..write('fileId: $fileId, ')
          ..write('status: $status, ')
          ..write('pageCount: $pageCount, ')
          ..write('indexedAt: $indexedAt, ')
          ..write('lastIndexedPage: $lastIndexedPage')
          ..write(')'))
        .toString();
  }
}

class PdfPageFts extends Table
    with
        TableInfo<PdfPageFts, PdfPageFt>,
        VirtualTableInfo<PdfPageFts, PdfPageFt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PdfPageFts(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const VerificationMeta _pageNumberMeta = const VerificationMeta(
    'pageNumber',
  );
  late final GeneratedColumn<String> pageNumber = GeneratedColumn<String>(
    'page_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const VerificationMeta _pageTextMeta = const VerificationMeta(
    'pageText',
  );
  late final GeneratedColumn<String> pageText = GeneratedColumn<String>(
    'page_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [fileId, pageNumber, pageText];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pdf_page_fts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PdfPageFt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIdMeta);
    }
    if (data.containsKey('page_number')) {
      context.handle(
        _pageNumberMeta,
        pageNumber.isAcceptableOrUnknown(data['page_number']!, _pageNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_pageNumberMeta);
    }
    if (data.containsKey('page_text')) {
      context.handle(
        _pageTextMeta,
        pageText.isAcceptableOrUnknown(data['page_text']!, _pageTextMeta),
      );
    } else if (isInserting) {
      context.missing(_pageTextMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  PdfPageFt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PdfPageFt(
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      pageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_number'],
      )!,
      pageText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_text'],
      )!,
    );
  }

  @override
  PdfPageFts createAlias(String alias) {
    return PdfPageFts(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs =>
      'fts5(file_id UNINDEXED, page_number UNINDEXED, page_text, tokenize=\'porter unicode61\')';
}

class PdfPageFt extends DataClass implements Insertable<PdfPageFt> {
  final String fileId;
  final String pageNumber;
  final String pageText;
  const PdfPageFt({
    required this.fileId,
    required this.pageNumber,
    required this.pageText,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['file_id'] = Variable<String>(fileId);
    map['page_number'] = Variable<String>(pageNumber);
    map['page_text'] = Variable<String>(pageText);
    return map;
  }

  PdfPageFtsCompanion toCompanion(bool nullToAbsent) {
    return PdfPageFtsCompanion(
      fileId: Value(fileId),
      pageNumber: Value(pageNumber),
      pageText: Value(pageText),
    );
  }

  factory PdfPageFt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PdfPageFt(
      fileId: serializer.fromJson<String>(json['file_id']),
      pageNumber: serializer.fromJson<String>(json['page_number']),
      pageText: serializer.fromJson<String>(json['page_text']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'file_id': serializer.toJson<String>(fileId),
      'page_number': serializer.toJson<String>(pageNumber),
      'page_text': serializer.toJson<String>(pageText),
    };
  }

  PdfPageFt copyWith({String? fileId, String? pageNumber, String? pageText}) =>
      PdfPageFt(
        fileId: fileId ?? this.fileId,
        pageNumber: pageNumber ?? this.pageNumber,
        pageText: pageText ?? this.pageText,
      );
  PdfPageFt copyWithCompanion(PdfPageFtsCompanion data) {
    return PdfPageFt(
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      pageNumber: data.pageNumber.present
          ? data.pageNumber.value
          : this.pageNumber,
      pageText: data.pageText.present ? data.pageText.value : this.pageText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PdfPageFt(')
          ..write('fileId: $fileId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('pageText: $pageText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(fileId, pageNumber, pageText);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PdfPageFt &&
          other.fileId == this.fileId &&
          other.pageNumber == this.pageNumber &&
          other.pageText == this.pageText);
}

class PdfPageFtsCompanion extends UpdateCompanion<PdfPageFt> {
  final Value<String> fileId;
  final Value<String> pageNumber;
  final Value<String> pageText;
  final Value<int> rowid;
  const PdfPageFtsCompanion({
    this.fileId = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.pageText = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PdfPageFtsCompanion.insert({
    required String fileId,
    required String pageNumber,
    required String pageText,
    this.rowid = const Value.absent(),
  }) : fileId = Value(fileId),
       pageNumber = Value(pageNumber),
       pageText = Value(pageText);
  static Insertable<PdfPageFt> custom({
    Expression<String>? fileId,
    Expression<String>? pageNumber,
    Expression<String>? pageText,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fileId != null) 'file_id': fileId,
      if (pageNumber != null) 'page_number': pageNumber,
      if (pageText != null) 'page_text': pageText,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PdfPageFtsCompanion copyWith({
    Value<String>? fileId,
    Value<String>? pageNumber,
    Value<String>? pageText,
    Value<int>? rowid,
  }) {
    return PdfPageFtsCompanion(
      fileId: fileId ?? this.fileId,
      pageNumber: pageNumber ?? this.pageNumber,
      pageText: pageText ?? this.pageText,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (pageNumber.present) {
      map['page_number'] = Variable<String>(pageNumber.value);
    }
    if (pageText.present) {
      map['page_text'] = Variable<String>(pageText.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PdfPageFtsCompanion(')
          ..write('fileId: $fileId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('pageText: $pageText, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimetableEntriesTable extends TimetableEntries
    with TableInfo<$TimetableEntriesTable, TimetableEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimetableEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _semesterIdMeta = const VerificationMeta(
    'semesterId',
  );
  @override
  late final GeneratedColumn<int> semesterId = GeneratedColumn<int>(
    'semester_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES semesters (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<int> subjectId = GeneratedColumn<int>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<int> startTime = GeneratedColumn<int>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<int> endTime = GeneratedColumn<int>(
    'end_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roomMeta = const VerificationMeta('room');
  @override
  late final GeneratedColumn<String> room = GeneratedColumn<String>(
    'room',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> effectiveFrom =
      GeneratedColumn<int>(
        'effective_from',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>(
        $TimetableEntriesTable.$convertereffectiveFromn,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> effectiveUntil =
      GeneratedColumn<int>(
        'effective_until',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>(
        $TimetableEntriesTable.$convertereffectiveUntiln,
      );
  static const VerificationMeta _reminderMinutesBeforeMeta =
      const VerificationMeta('reminderMinutesBefore');
  @override
  late final GeneratedColumn<int> reminderMinutesBefore = GeneratedColumn<int>(
    'reminder_minutes_before',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    semesterId,
    subjectId,
    weekday,
    startTime,
    endTime,
    room,
    note,
    effectiveFrom,
    effectiveUntil,
    reminderMinutesBefore,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timetable_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimetableEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('semester_id')) {
      context.handle(
        _semesterIdMeta,
        semesterId.isAcceptableOrUnknown(data['semester_id']!, _semesterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    } else if (isInserting) {
      context.missing(_weekdayMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('room')) {
      context.handle(
        _roomMeta,
        room.isAcceptableOrUnknown(data['room']!, _roomMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('reminder_minutes_before')) {
      context.handle(
        _reminderMinutesBeforeMeta,
        reminderMinutesBefore.isAcceptableOrUnknown(
          data['reminder_minutes_before']!,
          _reminderMinutesBeforeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimetableEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimetableEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      semesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}semester_id'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subject_id'],
      )!,
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_time'],
      )!,
      room: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      effectiveFrom: $TimetableEntriesTable.$convertereffectiveFromn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}effective_from'],
        ),
      ),
      effectiveUntil: $TimetableEntriesTable.$convertereffectiveUntiln.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}effective_until'],
        ),
      ),
      reminderMinutesBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minutes_before'],
      ),
    );
  }

  @override
  $TimetableEntriesTable createAlias(String alias) {
    return $TimetableEntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertereffectiveFrom =
      const EpochDayConverter();
  static TypeConverter<DateTime?, int?> $convertereffectiveFromn =
      NullAwareTypeConverter.wrap($convertereffectiveFrom);
  static TypeConverter<DateTime, int> $convertereffectiveUntil =
      const EpochDayConverter();
  static TypeConverter<DateTime?, int?> $convertereffectiveUntiln =
      NullAwareTypeConverter.wrap($convertereffectiveUntil);
}

class TimetableEntryRow extends DataClass
    implements Insertable<TimetableEntryRow> {
  final int id;
  final int semesterId;
  final int subjectId;
  final int weekday;
  final int startTime;
  final int endTime;
  final String room;
  final String note;
  final DateTime? effectiveFrom;
  final DateTime? effectiveUntil;

  /// Lead time, in minutes before [startTime], for this class's reminder.
  ///
  /// `null` means the class has no reminder. The lead time is relative to each
  /// occurrence, so a weekly class reminds before every one of its classes.
  /// Declared last so a migration that only adds this column produces the same
  /// table SQL as a fresh create.
  final int? reminderMinutesBefore;
  const TimetableEntryRow({
    required this.id,
    required this.semesterId,
    required this.subjectId,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.note,
    this.effectiveFrom,
    this.effectiveUntil,
    this.reminderMinutesBefore,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['semester_id'] = Variable<int>(semesterId);
    map['subject_id'] = Variable<int>(subjectId);
    map['weekday'] = Variable<int>(weekday);
    map['start_time'] = Variable<int>(startTime);
    map['end_time'] = Variable<int>(endTime);
    map['room'] = Variable<String>(room);
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || effectiveFrom != null) {
      map['effective_from'] = Variable<int>(
        $TimetableEntriesTable.$convertereffectiveFromn.toSql(effectiveFrom),
      );
    }
    if (!nullToAbsent || effectiveUntil != null) {
      map['effective_until'] = Variable<int>(
        $TimetableEntriesTable.$convertereffectiveUntiln.toSql(effectiveUntil),
      );
    }
    if (!nullToAbsent || reminderMinutesBefore != null) {
      map['reminder_minutes_before'] = Variable<int>(reminderMinutesBefore);
    }
    return map;
  }

  TimetableEntriesCompanion toCompanion(bool nullToAbsent) {
    return TimetableEntriesCompanion(
      id: Value(id),
      semesterId: Value(semesterId),
      subjectId: Value(subjectId),
      weekday: Value(weekday),
      startTime: Value(startTime),
      endTime: Value(endTime),
      room: Value(room),
      note: Value(note),
      effectiveFrom: effectiveFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(effectiveFrom),
      effectiveUntil: effectiveUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(effectiveUntil),
      reminderMinutesBefore: reminderMinutesBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderMinutesBefore),
    );
  }

  factory TimetableEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimetableEntryRow(
      id: serializer.fromJson<int>(json['id']),
      semesterId: serializer.fromJson<int>(json['semesterId']),
      subjectId: serializer.fromJson<int>(json['subjectId']),
      weekday: serializer.fromJson<int>(json['weekday']),
      startTime: serializer.fromJson<int>(json['startTime']),
      endTime: serializer.fromJson<int>(json['endTime']),
      room: serializer.fromJson<String>(json['room']),
      note: serializer.fromJson<String>(json['note']),
      effectiveFrom: serializer.fromJson<DateTime?>(json['effectiveFrom']),
      effectiveUntil: serializer.fromJson<DateTime?>(json['effectiveUntil']),
      reminderMinutesBefore: serializer.fromJson<int?>(
        json['reminderMinutesBefore'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'semesterId': serializer.toJson<int>(semesterId),
      'subjectId': serializer.toJson<int>(subjectId),
      'weekday': serializer.toJson<int>(weekday),
      'startTime': serializer.toJson<int>(startTime),
      'endTime': serializer.toJson<int>(endTime),
      'room': serializer.toJson<String>(room),
      'note': serializer.toJson<String>(note),
      'effectiveFrom': serializer.toJson<DateTime?>(effectiveFrom),
      'effectiveUntil': serializer.toJson<DateTime?>(effectiveUntil),
      'reminderMinutesBefore': serializer.toJson<int?>(reminderMinutesBefore),
    };
  }

  TimetableEntryRow copyWith({
    int? id,
    int? semesterId,
    int? subjectId,
    int? weekday,
    int? startTime,
    int? endTime,
    String? room,
    String? note,
    Value<DateTime?> effectiveFrom = const Value.absent(),
    Value<DateTime?> effectiveUntil = const Value.absent(),
    Value<int?> reminderMinutesBefore = const Value.absent(),
  }) => TimetableEntryRow(
    id: id ?? this.id,
    semesterId: semesterId ?? this.semesterId,
    subjectId: subjectId ?? this.subjectId,
    weekday: weekday ?? this.weekday,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    room: room ?? this.room,
    note: note ?? this.note,
    effectiveFrom: effectiveFrom.present
        ? effectiveFrom.value
        : this.effectiveFrom,
    effectiveUntil: effectiveUntil.present
        ? effectiveUntil.value
        : this.effectiveUntil,
    reminderMinutesBefore: reminderMinutesBefore.present
        ? reminderMinutesBefore.value
        : this.reminderMinutesBefore,
  );
  TimetableEntryRow copyWithCompanion(TimetableEntriesCompanion data) {
    return TimetableEntryRow(
      id: data.id.present ? data.id.value : this.id,
      semesterId: data.semesterId.present
          ? data.semesterId.value
          : this.semesterId,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      room: data.room.present ? data.room.value : this.room,
      note: data.note.present ? data.note.value : this.note,
      effectiveFrom: data.effectiveFrom.present
          ? data.effectiveFrom.value
          : this.effectiveFrom,
      effectiveUntil: data.effectiveUntil.present
          ? data.effectiveUntil.value
          : this.effectiveUntil,
      reminderMinutesBefore: data.reminderMinutesBefore.present
          ? data.reminderMinutesBefore.value
          : this.reminderMinutesBefore,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimetableEntryRow(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('subjectId: $subjectId, ')
          ..write('weekday: $weekday, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('room: $room, ')
          ..write('note: $note, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('effectiveUntil: $effectiveUntil, ')
          ..write('reminderMinutesBefore: $reminderMinutesBefore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    semesterId,
    subjectId,
    weekday,
    startTime,
    endTime,
    room,
    note,
    effectiveFrom,
    effectiveUntil,
    reminderMinutesBefore,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimetableEntryRow &&
          other.id == this.id &&
          other.semesterId == this.semesterId &&
          other.subjectId == this.subjectId &&
          other.weekday == this.weekday &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.room == this.room &&
          other.note == this.note &&
          other.effectiveFrom == this.effectiveFrom &&
          other.effectiveUntil == this.effectiveUntil &&
          other.reminderMinutesBefore == this.reminderMinutesBefore);
}

class TimetableEntriesCompanion extends UpdateCompanion<TimetableEntryRow> {
  final Value<int> id;
  final Value<int> semesterId;
  final Value<int> subjectId;
  final Value<int> weekday;
  final Value<int> startTime;
  final Value<int> endTime;
  final Value<String> room;
  final Value<String> note;
  final Value<DateTime?> effectiveFrom;
  final Value<DateTime?> effectiveUntil;
  final Value<int?> reminderMinutesBefore;
  const TimetableEntriesCompanion({
    this.id = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.weekday = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.room = const Value.absent(),
    this.note = const Value.absent(),
    this.effectiveFrom = const Value.absent(),
    this.effectiveUntil = const Value.absent(),
    this.reminderMinutesBefore = const Value.absent(),
  });
  TimetableEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int semesterId,
    required int subjectId,
    required int weekday,
    required int startTime,
    required int endTime,
    this.room = const Value.absent(),
    this.note = const Value.absent(),
    this.effectiveFrom = const Value.absent(),
    this.effectiveUntil = const Value.absent(),
    this.reminderMinutesBefore = const Value.absent(),
  }) : semesterId = Value(semesterId),
       subjectId = Value(subjectId),
       weekday = Value(weekday),
       startTime = Value(startTime),
       endTime = Value(endTime);
  static Insertable<TimetableEntryRow> custom({
    Expression<int>? id,
    Expression<int>? semesterId,
    Expression<int>? subjectId,
    Expression<int>? weekday,
    Expression<int>? startTime,
    Expression<int>? endTime,
    Expression<String>? room,
    Expression<String>? note,
    Expression<int>? effectiveFrom,
    Expression<int>? effectiveUntil,
    Expression<int>? reminderMinutesBefore,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (semesterId != null) 'semester_id': semesterId,
      if (subjectId != null) 'subject_id': subjectId,
      if (weekday != null) 'weekday': weekday,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (room != null) 'room': room,
      if (note != null) 'note': note,
      if (effectiveFrom != null) 'effective_from': effectiveFrom,
      if (effectiveUntil != null) 'effective_until': effectiveUntil,
      if (reminderMinutesBefore != null)
        'reminder_minutes_before': reminderMinutesBefore,
    });
  }

  TimetableEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? semesterId,
    Value<int>? subjectId,
    Value<int>? weekday,
    Value<int>? startTime,
    Value<int>? endTime,
    Value<String>? room,
    Value<String>? note,
    Value<DateTime?>? effectiveFrom,
    Value<DateTime?>? effectiveUntil,
    Value<int?>? reminderMinutesBefore,
  }) {
    return TimetableEntriesCompanion(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      subjectId: subjectId ?? this.subjectId,
      weekday: weekday ?? this.weekday,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      note: note ?? this.note,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveUntil: effectiveUntil ?? this.effectiveUntil,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<int>(semesterId.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<int>(subjectId.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<int>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<int>(endTime.value);
    }
    if (room.present) {
      map['room'] = Variable<String>(room.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (effectiveFrom.present) {
      map['effective_from'] = Variable<int>(
        $TimetableEntriesTable.$convertereffectiveFromn.toSql(
          effectiveFrom.value,
        ),
      );
    }
    if (effectiveUntil.present) {
      map['effective_until'] = Variable<int>(
        $TimetableEntriesTable.$convertereffectiveUntiln.toSql(
          effectiveUntil.value,
        ),
      );
    }
    if (reminderMinutesBefore.present) {
      map['reminder_minutes_before'] = Variable<int>(
        reminderMinutesBefore.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimetableEntriesCompanion(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('subjectId: $subjectId, ')
          ..write('weekday: $weekday, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('room: $room, ')
          ..write('note: $note, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('effectiveUntil: $effectiveUntil, ')
          ..write('reminderMinutesBefore: $reminderMinutesBefore')
          ..write(')'))
        .toString();
  }
}

class $AttendanceSessionsTable extends AttendanceSessions
    with TableInfo<$AttendanceSessionsTable, AttendanceSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<int> subjectId = GeneratedColumn<int>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES subjects (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> date =
      GeneratedColumn<int>(
        'date',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($AttendanceSessionsTable.$converterdate);
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  @override
  late final GeneratedColumn<int> period = GeneratedColumn<int>(
    'period',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AttendanceStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AttendanceStatus>(
        $AttendanceSessionsTable.$converterstatus,
      );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: currentUtcMilliseconds,
      ).withConverter<DateTime>($AttendanceSessionsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: currentUtcMilliseconds,
      ).withConverter<DateTime>($AttendanceSessionsTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    subjectId,
    date,
    period,
    status,
    note,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttendanceSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('period')) {
      context.handle(
        _periodMeta,
        period.isAcceptableOrUnknown(data['period']!, _periodMeta),
      );
    } else if (isInserting) {
      context.missing(_periodMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttendanceSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subject_id'],
      )!,
      date: $AttendanceSessionsTable.$converterdate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}date'],
        )!,
      ),
      period: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}period'],
      )!,
      status: $AttendanceSessionsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      createdAt: $AttendanceSessionsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $AttendanceSessionsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $AttendanceSessionsTable createAlias(String alias) {
    return $AttendanceSessionsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterdate =
      const EpochDayConverter();
  static JsonTypeConverter2<AttendanceStatus, String, String> $converterstatus =
      const EnumNameConverter<AttendanceStatus>(AttendanceStatus.values);
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class AttendanceSessionRow extends DataClass
    implements Insertable<AttendanceSessionRow> {
  final int id;
  final int subjectId;
  final DateTime date;
  final int period;
  final AttendanceStatus status;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AttendanceSessionRow({
    required this.id,
    required this.subjectId,
    required this.date,
    required this.period,
    required this.status,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['subject_id'] = Variable<int>(subjectId);
    {
      map['date'] = Variable<int>(
        $AttendanceSessionsTable.$converterdate.toSql(date),
      );
    }
    map['period'] = Variable<int>(period);
    {
      map['status'] = Variable<String>(
        $AttendanceSessionsTable.$converterstatus.toSql(status),
      );
    }
    map['note'] = Variable<String>(note);
    {
      map['created_at'] = Variable<int>(
        $AttendanceSessionsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $AttendanceSessionsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  AttendanceSessionsCompanion toCompanion(bool nullToAbsent) {
    return AttendanceSessionsCompanion(
      id: Value(id),
      subjectId: Value(subjectId),
      date: Value(date),
      period: Value(period),
      status: Value(status),
      note: Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AttendanceSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceSessionRow(
      id: serializer.fromJson<int>(json['id']),
      subjectId: serializer.fromJson<int>(json['subjectId']),
      date: serializer.fromJson<DateTime>(json['date']),
      period: serializer.fromJson<int>(json['period']),
      status: $AttendanceSessionsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'subjectId': serializer.toJson<int>(subjectId),
      'date': serializer.toJson<DateTime>(date),
      'period': serializer.toJson<int>(period),
      'status': serializer.toJson<String>(
        $AttendanceSessionsTable.$converterstatus.toJson(status),
      ),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AttendanceSessionRow copyWith({
    int? id,
    int? subjectId,
    DateTime? date,
    int? period,
    AttendanceStatus? status,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AttendanceSessionRow(
    id: id ?? this.id,
    subjectId: subjectId ?? this.subjectId,
    date: date ?? this.date,
    period: period ?? this.period,
    status: status ?? this.status,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AttendanceSessionRow copyWithCompanion(AttendanceSessionsCompanion data) {
    return AttendanceSessionRow(
      id: data.id.present ? data.id.value : this.id,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      date: data.date.present ? data.date.value : this.date,
      period: data.period.present ? data.period.value : this.period,
      status: data.status.present ? data.status.value : this.status,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceSessionRow(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('date: $date, ')
          ..write('period: $period, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    subjectId,
    date,
    period,
    status,
    note,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceSessionRow &&
          other.id == this.id &&
          other.subjectId == this.subjectId &&
          other.date == this.date &&
          other.period == this.period &&
          other.status == this.status &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AttendanceSessionsCompanion
    extends UpdateCompanion<AttendanceSessionRow> {
  final Value<int> id;
  final Value<int> subjectId;
  final Value<DateTime> date;
  final Value<int> period;
  final Value<AttendanceStatus> status;
  final Value<String> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const AttendanceSessionsCompanion({
    this.id = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.date = const Value.absent(),
    this.period = const Value.absent(),
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AttendanceSessionsCompanion.insert({
    this.id = const Value.absent(),
    required int subjectId,
    required DateTime date,
    required int period,
    required AttendanceStatus status,
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : subjectId = Value(subjectId),
       date = Value(date),
       period = Value(period),
       status = Value(status);
  static Insertable<AttendanceSessionRow> custom({
    Expression<int>? id,
    Expression<int>? subjectId,
    Expression<int>? date,
    Expression<int>? period,
    Expression<String>? status,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subjectId != null) 'subject_id': subjectId,
      if (date != null) 'date': date,
      if (period != null) 'period': period,
      if (status != null) 'status': status,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AttendanceSessionsCompanion copyWith({
    Value<int>? id,
    Value<int>? subjectId,
    Value<DateTime>? date,
    Value<int>? period,
    Value<AttendanceStatus>? status,
    Value<String>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return AttendanceSessionsCompanion(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      date: date ?? this.date,
      period: period ?? this.period,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<int>(subjectId.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(
        $AttendanceSessionsTable.$converterdate.toSql(date.value),
      );
    }
    if (period.present) {
      map['period'] = Variable<int>(period.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $AttendanceSessionsTable.$converterstatus.toSql(status.value),
      );
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $AttendanceSessionsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $AttendanceSessionsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceSessionsCompanion(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('date: $date, ')
          ..write('period: $period, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DailyAttendanceRecordsTable extends DailyAttendanceRecords
    with TableInfo<$DailyAttendanceRecordsTable, DailyAttendanceRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyAttendanceRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> date =
      GeneratedColumn<int>(
        'date',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      ).withConverter<DateTime>($DailyAttendanceRecordsTable.$converterdate);
  @override
  late final GeneratedColumnWithTypeConverter<DailyAttendanceStatus, String>
  status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DailyAttendanceStatus>(
        $DailyAttendanceRecordsTable.$converterstatus,
      );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: currentUtcMilliseconds,
      ).withConverter<DateTime>(
        $DailyAttendanceRecordsTable.$convertercreatedAt,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: currentUtcMilliseconds,
      ).withConverter<DateTime>(
        $DailyAttendanceRecordsTable.$converterupdatedAt,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    status,
    note,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_attendance_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyAttendanceRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyAttendanceRecordRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyAttendanceRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: $DailyAttendanceRecordsTable.$converterdate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}date'],
        )!,
      ),
      status: $DailyAttendanceRecordsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      createdAt: $DailyAttendanceRecordsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $DailyAttendanceRecordsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $DailyAttendanceRecordsTable createAlias(String alias) {
    return $DailyAttendanceRecordsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterdate =
      const EpochDayConverter();
  static JsonTypeConverter2<DailyAttendanceStatus, String, String>
  $converterstatus = const EnumNameConverter<DailyAttendanceStatus>(
    DailyAttendanceStatus.values,
  );
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class DailyAttendanceRecordRow extends DataClass
    implements Insertable<DailyAttendanceRecordRow> {
  final int id;
  final DateTime date;
  final DailyAttendanceStatus status;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DailyAttendanceRecordRow({
    required this.id,
    required this.date,
    required this.status,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['date'] = Variable<int>(
        $DailyAttendanceRecordsTable.$converterdate.toSql(date),
      );
    }
    {
      map['status'] = Variable<String>(
        $DailyAttendanceRecordsTable.$converterstatus.toSql(status),
      );
    }
    map['note'] = Variable<String>(note);
    {
      map['created_at'] = Variable<int>(
        $DailyAttendanceRecordsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $DailyAttendanceRecordsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  DailyAttendanceRecordsCompanion toCompanion(bool nullToAbsent) {
    return DailyAttendanceRecordsCompanion(
      id: Value(id),
      date: Value(date),
      status: Value(status),
      note: Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DailyAttendanceRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyAttendanceRecordRow(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      status: $DailyAttendanceRecordsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'status': serializer.toJson<String>(
        $DailyAttendanceRecordsTable.$converterstatus.toJson(status),
      ),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DailyAttendanceRecordRow copyWith({
    int? id,
    DateTime? date,
    DailyAttendanceStatus? status,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DailyAttendanceRecordRow(
    id: id ?? this.id,
    date: date ?? this.date,
    status: status ?? this.status,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DailyAttendanceRecordRow copyWithCompanion(
    DailyAttendanceRecordsCompanion data,
  ) {
    return DailyAttendanceRecordRow(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      status: data.status.present ? data.status.value : this.status,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyAttendanceRecordRow(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, status, note, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyAttendanceRecordRow &&
          other.id == this.id &&
          other.date == this.date &&
          other.status == this.status &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DailyAttendanceRecordsCompanion
    extends UpdateCompanion<DailyAttendanceRecordRow> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<DailyAttendanceStatus> status;
  final Value<String> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const DailyAttendanceRecordsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DailyAttendanceRecordsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required DailyAttendanceStatus status,
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : date = Value(date),
       status = Value(status);
  static Insertable<DailyAttendanceRecordRow> custom({
    Expression<int>? id,
    Expression<int>? date,
    Expression<String>? status,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (status != null) 'status': status,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DailyAttendanceRecordsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<DailyAttendanceStatus>? status,
    Value<String>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return DailyAttendanceRecordsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(
        $DailyAttendanceRecordsTable.$converterdate.toSql(date.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $DailyAttendanceRecordsTable.$converterstatus.toSql(status.value),
      );
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $DailyAttendanceRecordsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $DailyAttendanceRecordsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyAttendanceRecordsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ScheduledClassAttendanceTable extends ScheduledClassAttendance
    with
        TableInfo<$ScheduledClassAttendanceTable, ScheduledClassAttendanceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduledClassAttendanceTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _semesterIdMeta = const VerificationMeta(
    'semesterId',
  );
  @override
  late final GeneratedColumn<int> semesterId = GeneratedColumn<int>(
    'semester_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES semesters (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _timetableEntryIdMeta = const VerificationMeta(
    'timetableEntryId',
  );
  @override
  late final GeneratedColumn<int> timetableEntryId = GeneratedColumn<int>(
    'timetable_entry_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES timetable_entries (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<int> subjectId = GeneratedColumn<int>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES subjects (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> date =
      GeneratedColumn<int>(
        'date',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ScheduledClassAttendanceTable.$converterdate);
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<int> startTime = GeneratedColumn<int>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<int> endTime = GeneratedColumn<int>(
    'end_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ClassAttendanceStatus, String>
  attendanceStatus =
      GeneratedColumn<String>(
        'attendance_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ClassAttendanceStatus>(
        $ScheduledClassAttendanceTable.$converterattendanceStatus,
      );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _manuallyModifiedMeta = const VerificationMeta(
    'manuallyModified',
  );
  @override
  late final GeneratedColumn<bool> manuallyModified = GeneratedColumn<bool>(
    'manually_modified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("manually_modified" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: currentUtcMilliseconds,
      ).withConverter<DateTime>(
        $ScheduledClassAttendanceTable.$convertercreatedAt,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: currentUtcMilliseconds,
      ).withConverter<DateTime>(
        $ScheduledClassAttendanceTable.$converterupdatedAt,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    semesterId,
    timetableEntryId,
    subjectId,
    date,
    startTime,
    endTime,
    attendanceStatus,
    note,
    manuallyModified,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scheduled_class_attendance';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScheduledClassAttendanceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('semester_id')) {
      context.handle(
        _semesterIdMeta,
        semesterId.isAcceptableOrUnknown(data['semester_id']!, _semesterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('timetable_entry_id')) {
      context.handle(
        _timetableEntryIdMeta,
        timetableEntryId.isAcceptableOrUnknown(
          data['timetable_entry_id']!,
          _timetableEntryIdMeta,
        ),
      );
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('manually_modified')) {
      context.handle(
        _manuallyModifiedMeta,
        manuallyModified.isAcceptableOrUnknown(
          data['manually_modified']!,
          _manuallyModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScheduledClassAttendanceRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduledClassAttendanceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      semesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}semester_id'],
      )!,
      timetableEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timetable_entry_id'],
      ),
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subject_id'],
      )!,
      date: $ScheduledClassAttendanceTable.$converterdate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}date'],
        )!,
      ),
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_time'],
      )!,
      attendanceStatus: $ScheduledClassAttendanceTable
          .$converterattendanceStatus
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}attendance_status'],
            )!,
          ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      manuallyModified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}manually_modified'],
      )!,
      createdAt: $ScheduledClassAttendanceTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $ScheduledClassAttendanceTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $ScheduledClassAttendanceTable createAlias(String alias) {
    return $ScheduledClassAttendanceTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterdate =
      const EpochDayConverter();
  static JsonTypeConverter2<ClassAttendanceStatus, String, String>
  $converterattendanceStatus = const EnumNameConverter<ClassAttendanceStatus>(
    ClassAttendanceStatus.values,
  );
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class ScheduledClassAttendanceRow extends DataClass
    implements Insertable<ScheduledClassAttendanceRow> {
  final int id;
  final int semesterId;
  final int? timetableEntryId;
  final int subjectId;
  final DateTime date;
  final int startTime;
  final int endTime;
  final ClassAttendanceStatus attendanceStatus;
  final String note;
  final bool manuallyModified;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ScheduledClassAttendanceRow({
    required this.id,
    required this.semesterId,
    this.timetableEntryId,
    required this.subjectId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.attendanceStatus,
    required this.note,
    required this.manuallyModified,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['semester_id'] = Variable<int>(semesterId);
    if (!nullToAbsent || timetableEntryId != null) {
      map['timetable_entry_id'] = Variable<int>(timetableEntryId);
    }
    map['subject_id'] = Variable<int>(subjectId);
    {
      map['date'] = Variable<int>(
        $ScheduledClassAttendanceTable.$converterdate.toSql(date),
      );
    }
    map['start_time'] = Variable<int>(startTime);
    map['end_time'] = Variable<int>(endTime);
    {
      map['attendance_status'] = Variable<String>(
        $ScheduledClassAttendanceTable.$converterattendanceStatus.toSql(
          attendanceStatus,
        ),
      );
    }
    map['note'] = Variable<String>(note);
    map['manually_modified'] = Variable<bool>(manuallyModified);
    {
      map['created_at'] = Variable<int>(
        $ScheduledClassAttendanceTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $ScheduledClassAttendanceTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  ScheduledClassAttendanceCompanion toCompanion(bool nullToAbsent) {
    return ScheduledClassAttendanceCompanion(
      id: Value(id),
      semesterId: Value(semesterId),
      timetableEntryId: timetableEntryId == null && nullToAbsent
          ? const Value.absent()
          : Value(timetableEntryId),
      subjectId: Value(subjectId),
      date: Value(date),
      startTime: Value(startTime),
      endTime: Value(endTime),
      attendanceStatus: Value(attendanceStatus),
      note: Value(note),
      manuallyModified: Value(manuallyModified),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ScheduledClassAttendanceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduledClassAttendanceRow(
      id: serializer.fromJson<int>(json['id']),
      semesterId: serializer.fromJson<int>(json['semesterId']),
      timetableEntryId: serializer.fromJson<int?>(json['timetableEntryId']),
      subjectId: serializer.fromJson<int>(json['subjectId']),
      date: serializer.fromJson<DateTime>(json['date']),
      startTime: serializer.fromJson<int>(json['startTime']),
      endTime: serializer.fromJson<int>(json['endTime']),
      attendanceStatus: $ScheduledClassAttendanceTable
          .$converterattendanceStatus
          .fromJson(serializer.fromJson<String>(json['attendanceStatus'])),
      note: serializer.fromJson<String>(json['note']),
      manuallyModified: serializer.fromJson<bool>(json['manuallyModified']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'semesterId': serializer.toJson<int>(semesterId),
      'timetableEntryId': serializer.toJson<int?>(timetableEntryId),
      'subjectId': serializer.toJson<int>(subjectId),
      'date': serializer.toJson<DateTime>(date),
      'startTime': serializer.toJson<int>(startTime),
      'endTime': serializer.toJson<int>(endTime),
      'attendanceStatus': serializer.toJson<String>(
        $ScheduledClassAttendanceTable.$converterattendanceStatus.toJson(
          attendanceStatus,
        ),
      ),
      'note': serializer.toJson<String>(note),
      'manuallyModified': serializer.toJson<bool>(manuallyModified),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ScheduledClassAttendanceRow copyWith({
    int? id,
    int? semesterId,
    Value<int?> timetableEntryId = const Value.absent(),
    int? subjectId,
    DateTime? date,
    int? startTime,
    int? endTime,
    ClassAttendanceStatus? attendanceStatus,
    String? note,
    bool? manuallyModified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ScheduledClassAttendanceRow(
    id: id ?? this.id,
    semesterId: semesterId ?? this.semesterId,
    timetableEntryId: timetableEntryId.present
        ? timetableEntryId.value
        : this.timetableEntryId,
    subjectId: subjectId ?? this.subjectId,
    date: date ?? this.date,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    attendanceStatus: attendanceStatus ?? this.attendanceStatus,
    note: note ?? this.note,
    manuallyModified: manuallyModified ?? this.manuallyModified,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ScheduledClassAttendanceRow copyWithCompanion(
    ScheduledClassAttendanceCompanion data,
  ) {
    return ScheduledClassAttendanceRow(
      id: data.id.present ? data.id.value : this.id,
      semesterId: data.semesterId.present
          ? data.semesterId.value
          : this.semesterId,
      timetableEntryId: data.timetableEntryId.present
          ? data.timetableEntryId.value
          : this.timetableEntryId,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      date: data.date.present ? data.date.value : this.date,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      attendanceStatus: data.attendanceStatus.present
          ? data.attendanceStatus.value
          : this.attendanceStatus,
      note: data.note.present ? data.note.value : this.note,
      manuallyModified: data.manuallyModified.present
          ? data.manuallyModified.value
          : this.manuallyModified,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduledClassAttendanceRow(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('timetableEntryId: $timetableEntryId, ')
          ..write('subjectId: $subjectId, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('attendanceStatus: $attendanceStatus, ')
          ..write('note: $note, ')
          ..write('manuallyModified: $manuallyModified, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    semesterId,
    timetableEntryId,
    subjectId,
    date,
    startTime,
    endTime,
    attendanceStatus,
    note,
    manuallyModified,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduledClassAttendanceRow &&
          other.id == this.id &&
          other.semesterId == this.semesterId &&
          other.timetableEntryId == this.timetableEntryId &&
          other.subjectId == this.subjectId &&
          other.date == this.date &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.attendanceStatus == this.attendanceStatus &&
          other.note == this.note &&
          other.manuallyModified == this.manuallyModified &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ScheduledClassAttendanceCompanion
    extends UpdateCompanion<ScheduledClassAttendanceRow> {
  final Value<int> id;
  final Value<int> semesterId;
  final Value<int?> timetableEntryId;
  final Value<int> subjectId;
  final Value<DateTime> date;
  final Value<int> startTime;
  final Value<int> endTime;
  final Value<ClassAttendanceStatus> attendanceStatus;
  final Value<String> note;
  final Value<bool> manuallyModified;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ScheduledClassAttendanceCompanion({
    this.id = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.timetableEntryId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.date = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.attendanceStatus = const Value.absent(),
    this.note = const Value.absent(),
    this.manuallyModified = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ScheduledClassAttendanceCompanion.insert({
    this.id = const Value.absent(),
    required int semesterId,
    this.timetableEntryId = const Value.absent(),
    required int subjectId,
    required DateTime date,
    required int startTime,
    required int endTime,
    required ClassAttendanceStatus attendanceStatus,
    this.note = const Value.absent(),
    this.manuallyModified = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : semesterId = Value(semesterId),
       subjectId = Value(subjectId),
       date = Value(date),
       startTime = Value(startTime),
       endTime = Value(endTime),
       attendanceStatus = Value(attendanceStatus);
  static Insertable<ScheduledClassAttendanceRow> custom({
    Expression<int>? id,
    Expression<int>? semesterId,
    Expression<int>? timetableEntryId,
    Expression<int>? subjectId,
    Expression<int>? date,
    Expression<int>? startTime,
    Expression<int>? endTime,
    Expression<String>? attendanceStatus,
    Expression<String>? note,
    Expression<bool>? manuallyModified,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (semesterId != null) 'semester_id': semesterId,
      if (timetableEntryId != null) 'timetable_entry_id': timetableEntryId,
      if (subjectId != null) 'subject_id': subjectId,
      if (date != null) 'date': date,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (attendanceStatus != null) 'attendance_status': attendanceStatus,
      if (note != null) 'note': note,
      if (manuallyModified != null) 'manually_modified': manuallyModified,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ScheduledClassAttendanceCompanion copyWith({
    Value<int>? id,
    Value<int>? semesterId,
    Value<int?>? timetableEntryId,
    Value<int>? subjectId,
    Value<DateTime>? date,
    Value<int>? startTime,
    Value<int>? endTime,
    Value<ClassAttendanceStatus>? attendanceStatus,
    Value<String>? note,
    Value<bool>? manuallyModified,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ScheduledClassAttendanceCompanion(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      timetableEntryId: timetableEntryId ?? this.timetableEntryId,
      subjectId: subjectId ?? this.subjectId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      note: note ?? this.note,
      manuallyModified: manuallyModified ?? this.manuallyModified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<int>(semesterId.value);
    }
    if (timetableEntryId.present) {
      map['timetable_entry_id'] = Variable<int>(timetableEntryId.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<int>(subjectId.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(
        $ScheduledClassAttendanceTable.$converterdate.toSql(date.value),
      );
    }
    if (startTime.present) {
      map['start_time'] = Variable<int>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<int>(endTime.value);
    }
    if (attendanceStatus.present) {
      map['attendance_status'] = Variable<String>(
        $ScheduledClassAttendanceTable.$converterattendanceStatus.toSql(
          attendanceStatus.value,
        ),
      );
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (manuallyModified.present) {
      map['manually_modified'] = Variable<bool>(manuallyModified.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $ScheduledClassAttendanceTable.$convertercreatedAt.toSql(
          createdAt.value,
        ),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $ScheduledClassAttendanceTable.$converterupdatedAt.toSql(
          updatedAt.value,
        ),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduledClassAttendanceCompanion(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('timetableEntryId: $timetableEntryId, ')
          ..write('subjectId: $subjectId, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('attendanceStatus: $attendanceStatus, ')
          ..write('note: $note, ')
          ..write('manuallyModified: $manuallyModified, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CalendarDayOverridesTable extends CalendarDayOverrides
    with TableInfo<$CalendarDayOverridesTable, CalendarDayOverrideRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarDayOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _semesterIdMeta = const VerificationMeta(
    'semesterId',
  );
  @override
  late final GeneratedColumn<int> semesterId = GeneratedColumn<int>(
    'semester_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES semesters (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> date =
      GeneratedColumn<int>(
        'date',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CalendarDayOverridesTable.$converterdate);
  @override
  late final GeneratedColumnWithTypeConverter<CalendarDayOverrideType, String>
  type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CalendarDayOverrideType>(
        $CalendarDayOverridesTable.$convertertype,
      );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: currentUtcMilliseconds,
      ).withConverter<DateTime>($CalendarDayOverridesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: currentUtcMilliseconds,
      ).withConverter<DateTime>($CalendarDayOverridesTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    semesterId,
    date,
    type,
    note,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_day_overrides';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalendarDayOverrideRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('semester_id')) {
      context.handle(
        _semesterIdMeta,
        semesterId.isAcceptableOrUnknown(data['semester_id']!, _semesterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalendarDayOverrideRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarDayOverrideRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      semesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}semester_id'],
      )!,
      date: $CalendarDayOverridesTable.$converterdate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}date'],
        )!,
      ),
      type: $CalendarDayOverridesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      createdAt: $CalendarDayOverridesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $CalendarDayOverridesTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $CalendarDayOverridesTable createAlias(String alias) {
    return $CalendarDayOverridesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterdate =
      const EpochDayConverter();
  static JsonTypeConverter2<CalendarDayOverrideType, String, String>
  $convertertype = const EnumNameConverter<CalendarDayOverrideType>(
    CalendarDayOverrideType.values,
  );
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class CalendarDayOverrideRow extends DataClass
    implements Insertable<CalendarDayOverrideRow> {
  final int id;
  final int semesterId;
  final DateTime date;
  final CalendarDayOverrideType type;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CalendarDayOverrideRow({
    required this.id,
    required this.semesterId,
    required this.date,
    required this.type,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['semester_id'] = Variable<int>(semesterId);
    {
      map['date'] = Variable<int>(
        $CalendarDayOverridesTable.$converterdate.toSql(date),
      );
    }
    {
      map['type'] = Variable<String>(
        $CalendarDayOverridesTable.$convertertype.toSql(type),
      );
    }
    map['note'] = Variable<String>(note);
    {
      map['created_at'] = Variable<int>(
        $CalendarDayOverridesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $CalendarDayOverridesTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  CalendarDayOverridesCompanion toCompanion(bool nullToAbsent) {
    return CalendarDayOverridesCompanion(
      id: Value(id),
      semesterId: Value(semesterId),
      date: Value(date),
      type: Value(type),
      note: Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CalendarDayOverrideRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarDayOverrideRow(
      id: serializer.fromJson<int>(json['id']),
      semesterId: serializer.fromJson<int>(json['semesterId']),
      date: serializer.fromJson<DateTime>(json['date']),
      type: $CalendarDayOverridesTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'semesterId': serializer.toJson<int>(semesterId),
      'date': serializer.toJson<DateTime>(date),
      'type': serializer.toJson<String>(
        $CalendarDayOverridesTable.$convertertype.toJson(type),
      ),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CalendarDayOverrideRow copyWith({
    int? id,
    int? semesterId,
    DateTime? date,
    CalendarDayOverrideType? type,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CalendarDayOverrideRow(
    id: id ?? this.id,
    semesterId: semesterId ?? this.semesterId,
    date: date ?? this.date,
    type: type ?? this.type,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CalendarDayOverrideRow copyWithCompanion(CalendarDayOverridesCompanion data) {
    return CalendarDayOverrideRow(
      id: data.id.present ? data.id.value : this.id,
      semesterId: data.semesterId.present
          ? data.semesterId.value
          : this.semesterId,
      date: data.date.present ? data.date.value : this.date,
      type: data.type.present ? data.type.value : this.type,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarDayOverrideRow(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, semesterId, date, type, note, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarDayOverrideRow &&
          other.id == this.id &&
          other.semesterId == this.semesterId &&
          other.date == this.date &&
          other.type == this.type &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CalendarDayOverridesCompanion
    extends UpdateCompanion<CalendarDayOverrideRow> {
  final Value<int> id;
  final Value<int> semesterId;
  final Value<DateTime> date;
  final Value<CalendarDayOverrideType> type;
  final Value<String> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CalendarDayOverridesCompanion({
    this.id = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.date = const Value.absent(),
    this.type = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CalendarDayOverridesCompanion.insert({
    this.id = const Value.absent(),
    required int semesterId,
    required DateTime date,
    required CalendarDayOverrideType type,
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : semesterId = Value(semesterId),
       date = Value(date),
       type = Value(type);
  static Insertable<CalendarDayOverrideRow> custom({
    Expression<int>? id,
    Expression<int>? semesterId,
    Expression<int>? date,
    Expression<String>? type,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (semesterId != null) 'semester_id': semesterId,
      if (date != null) 'date': date,
      if (type != null) 'type': type,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CalendarDayOverridesCompanion copyWith({
    Value<int>? id,
    Value<int>? semesterId,
    Value<DateTime>? date,
    Value<CalendarDayOverrideType>? type,
    Value<String>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CalendarDayOverridesCompanion(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      date: date ?? this.date,
      type: type ?? this.type,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<int>(semesterId.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(
        $CalendarDayOverridesTable.$converterdate.toSql(date.value),
      );
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $CalendarDayOverridesTable.$convertertype.toSql(type.value),
      );
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $CalendarDayOverridesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $CalendarDayOverridesTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarDayOverridesCompanion(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AcademicCalendarEventsTable extends AcademicCalendarEvents
    with TableInfo<$AcademicCalendarEventsTable, AcademicCalendarEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AcademicCalendarEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _semesterIdMeta = const VerificationMeta(
    'semesterId',
  );
  @override
  late final GeneratedColumn<int> semesterId = GeneratedColumn<int>(
    'semester_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES semesters (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AcademicCalendarEventType, String>
  type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AcademicCalendarEventType>(
        $AcademicCalendarEventsTable.$convertertype,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> startDate =
      GeneratedColumn<int>(
        'start_date',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>(
        $AcademicCalendarEventsTable.$converterstartDate,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> endDate =
      GeneratedColumn<int>(
        'end_date',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($AcademicCalendarEventsTable.$converterendDate);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: currentUtcMilliseconds,
      ).withConverter<DateTime>(
        $AcademicCalendarEventsTable.$convertercreatedAt,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: currentUtcMilliseconds,
      ).withConverter<DateTime>(
        $AcademicCalendarEventsTable.$converterupdatedAt,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    semesterId,
    title,
    type,
    startDate,
    endDate,
    note,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'academic_calendar_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<AcademicCalendarEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('semester_id')) {
      context.handle(
        _semesterIdMeta,
        semesterId.isAcceptableOrUnknown(data['semester_id']!, _semesterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AcademicCalendarEventRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AcademicCalendarEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      semesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}semester_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      type: $AcademicCalendarEventsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      startDate: $AcademicCalendarEventsTable.$converterstartDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}start_date'],
        )!,
      ),
      endDate: $AcademicCalendarEventsTable.$converterendDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}end_date'],
        )!,
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      createdAt: $AcademicCalendarEventsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $AcademicCalendarEventsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $AcademicCalendarEventsTable createAlias(String alias) {
    return $AcademicCalendarEventsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AcademicCalendarEventType, String, String>
  $convertertype = const EnumNameConverter<AcademicCalendarEventType>(
    AcademicCalendarEventType.values,
  );
  static TypeConverter<DateTime, int> $converterstartDate =
      const EpochDayConverter();
  static TypeConverter<DateTime, int> $converterendDate =
      const EpochDayConverter();
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class AcademicCalendarEventRow extends DataClass
    implements Insertable<AcademicCalendarEventRow> {
  final int id;
  final int semesterId;
  final String title;
  final AcademicCalendarEventType type;
  final DateTime startDate;
  final DateTime endDate;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AcademicCalendarEventRow({
    required this.id,
    required this.semesterId,
    required this.title,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['semester_id'] = Variable<int>(semesterId);
    map['title'] = Variable<String>(title);
    {
      map['type'] = Variable<String>(
        $AcademicCalendarEventsTable.$convertertype.toSql(type),
      );
    }
    {
      map['start_date'] = Variable<int>(
        $AcademicCalendarEventsTable.$converterstartDate.toSql(startDate),
      );
    }
    {
      map['end_date'] = Variable<int>(
        $AcademicCalendarEventsTable.$converterendDate.toSql(endDate),
      );
    }
    map['note'] = Variable<String>(note);
    {
      map['created_at'] = Variable<int>(
        $AcademicCalendarEventsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $AcademicCalendarEventsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  AcademicCalendarEventsCompanion toCompanion(bool nullToAbsent) {
    return AcademicCalendarEventsCompanion(
      id: Value(id),
      semesterId: Value(semesterId),
      title: Value(title),
      type: Value(type),
      startDate: Value(startDate),
      endDate: Value(endDate),
      note: Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AcademicCalendarEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AcademicCalendarEventRow(
      id: serializer.fromJson<int>(json['id']),
      semesterId: serializer.fromJson<int>(json['semesterId']),
      title: serializer.fromJson<String>(json['title']),
      type: $AcademicCalendarEventsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime>(json['endDate']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'semesterId': serializer.toJson<int>(semesterId),
      'title': serializer.toJson<String>(title),
      'type': serializer.toJson<String>(
        $AcademicCalendarEventsTable.$convertertype.toJson(type),
      ),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime>(endDate),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AcademicCalendarEventRow copyWith({
    int? id,
    int? semesterId,
    String? title,
    AcademicCalendarEventType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AcademicCalendarEventRow(
    id: id ?? this.id,
    semesterId: semesterId ?? this.semesterId,
    title: title ?? this.title,
    type: type ?? this.type,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AcademicCalendarEventRow copyWithCompanion(
    AcademicCalendarEventsCompanion data,
  ) {
    return AcademicCalendarEventRow(
      id: data.id.present ? data.id.value : this.id,
      semesterId: data.semesterId.present
          ? data.semesterId.value
          : this.semesterId,
      title: data.title.present ? data.title.value : this.title,
      type: data.type.present ? data.type.value : this.type,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AcademicCalendarEventRow(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    semesterId,
    title,
    type,
    startDate,
    endDate,
    note,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AcademicCalendarEventRow &&
          other.id == this.id &&
          other.semesterId == this.semesterId &&
          other.title == this.title &&
          other.type == this.type &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AcademicCalendarEventsCompanion
    extends UpdateCompanion<AcademicCalendarEventRow> {
  final Value<int> id;
  final Value<int> semesterId;
  final Value<String> title;
  final Value<AcademicCalendarEventType> type;
  final Value<DateTime> startDate;
  final Value<DateTime> endDate;
  final Value<String> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const AcademicCalendarEventsCompanion({
    this.id = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.title = const Value.absent(),
    this.type = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AcademicCalendarEventsCompanion.insert({
    this.id = const Value.absent(),
    required int semesterId,
    required String title,
    required AcademicCalendarEventType type,
    required DateTime startDate,
    required DateTime endDate,
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : semesterId = Value(semesterId),
       title = Value(title),
       type = Value(type),
       startDate = Value(startDate),
       endDate = Value(endDate);
  static Insertable<AcademicCalendarEventRow> custom({
    Expression<int>? id,
    Expression<int>? semesterId,
    Expression<String>? title,
    Expression<String>? type,
    Expression<int>? startDate,
    Expression<int>? endDate,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (semesterId != null) 'semester_id': semesterId,
      if (title != null) 'title': title,
      if (type != null) 'type': type,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AcademicCalendarEventsCompanion copyWith({
    Value<int>? id,
    Value<int>? semesterId,
    Value<String>? title,
    Value<AcademicCalendarEventType>? type,
    Value<DateTime>? startDate,
    Value<DateTime>? endDate,
    Value<String>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return AcademicCalendarEventsCompanion(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      title: title ?? this.title,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<int>(semesterId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $AcademicCalendarEventsTable.$convertertype.toSql(type.value),
      );
    }
    if (startDate.present) {
      map['start_date'] = Variable<int>(
        $AcademicCalendarEventsTable.$converterstartDate.toSql(startDate.value),
      );
    }
    if (endDate.present) {
      map['end_date'] = Variable<int>(
        $AcademicCalendarEventsTable.$converterendDate.toSql(endDate.value),
      );
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $AcademicCalendarEventsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $AcademicCalendarEventsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AcademicCalendarEventsCompanion(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CollegeTasksTable extends CollegeTasks
    with TableInfo<$CollegeTasksTable, TaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollegeTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _semesterIdMeta = const VerificationMeta(
    'semesterId',
  );
  @override
  late final GeneratedColumn<int> semesterId = GeneratedColumn<int>(
    'semester_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES semesters (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<int> subjectId = GeneratedColumn<int>(
    'subject_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CollegeTaskType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CollegeTaskType>($CollegeTasksTable.$convertertype);
  @override
  late final GeneratedColumnWithTypeConverter<TaskPriority, String> priority =
      GeneratedColumn<String>(
        'priority',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TaskPriority>($CollegeTasksTable.$converterpriority);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> dueDate =
      GeneratedColumn<int>(
        'due_date',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($CollegeTasksTable.$converterdueDaten);
  static const VerificationMeta _dueTimeMeta = const VerificationMeta(
    'dueTime',
  );
  @override
  late final GeneratedColumn<int> dueTime = GeneratedColumn<int>(
    'due_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> reminderAt =
      GeneratedColumn<int>(
        'reminder_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($CollegeTasksTable.$converterreminderAtn);
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> completedAt =
      GeneratedColumn<int>(
        'completed_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($CollegeTasksTable.$convertercompletedAtn);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: currentUtcMilliseconds,
      ).withConverter<DateTime>($CollegeTasksTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: currentUtcMilliseconds,
      ).withConverter<DateTime>($CollegeTasksTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    semesterId,
    subjectId,
    title,
    description,
    type,
    priority,
    dueDate,
    dueTime,
    reminderAt,
    isCompleted,
    completedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('semester_id')) {
      context.handle(
        _semesterIdMeta,
        semesterId.isAcceptableOrUnknown(data['semester_id']!, _semesterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('due_time')) {
      context.handle(
        _dueTimeMeta,
        dueTime.isAcceptableOrUnknown(data['due_time']!, _dueTimeMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      semesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}semester_id'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subject_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      type: $CollegeTasksTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      priority: $CollegeTasksTable.$converterpriority.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}priority'],
        )!,
      ),
      dueDate: $CollegeTasksTable.$converterdueDaten.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}due_date'],
        ),
      ),
      dueTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_time'],
      ),
      reminderAt: $CollegeTasksTable.$converterreminderAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}reminder_at'],
        ),
      ),
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      completedAt: $CollegeTasksTable.$convertercompletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}completed_at'],
        ),
      ),
      createdAt: $CollegeTasksTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $CollegeTasksTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $CollegeTasksTable createAlias(String alias) {
    return $CollegeTasksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CollegeTaskType, String, String> $convertertype =
      const EnumNameConverter<CollegeTaskType>(CollegeTaskType.values);
  static JsonTypeConverter2<TaskPriority, String, String> $converterpriority =
      const EnumNameConverter<TaskPriority>(TaskPriority.values);
  static TypeConverter<DateTime, int> $converterdueDate =
      const EpochDayConverter();
  static TypeConverter<DateTime?, int?> $converterdueDaten =
      NullAwareTypeConverter.wrap($converterdueDate);
  static TypeConverter<DateTime, int> $converterreminderAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime?, int?> $converterreminderAtn =
      NullAwareTypeConverter.wrap($converterreminderAt);
  static TypeConverter<DateTime, int> $convertercompletedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime?, int?> $convertercompletedAtn =
      NullAwareTypeConverter.wrap($convertercompletedAt);
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class TaskRow extends DataClass implements Insertable<TaskRow> {
  final int id;
  final int semesterId;
  final int? subjectId;
  final String title;
  final String description;
  final CollegeTaskType type;
  final TaskPriority priority;
  final DateTime? dueDate;
  final int? dueTime;
  final DateTime? reminderAt;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TaskRow({
    required this.id,
    required this.semesterId,
    this.subjectId,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    this.dueDate,
    this.dueTime,
    this.reminderAt,
    required this.isCompleted,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['semester_id'] = Variable<int>(semesterId);
    if (!nullToAbsent || subjectId != null) {
      map['subject_id'] = Variable<int>(subjectId);
    }
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    {
      map['type'] = Variable<String>(
        $CollegeTasksTable.$convertertype.toSql(type),
      );
    }
    {
      map['priority'] = Variable<String>(
        $CollegeTasksTable.$converterpriority.toSql(priority),
      );
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<int>(
        $CollegeTasksTable.$converterdueDaten.toSql(dueDate),
      );
    }
    if (!nullToAbsent || dueTime != null) {
      map['due_time'] = Variable<int>(dueTime);
    }
    if (!nullToAbsent || reminderAt != null) {
      map['reminder_at'] = Variable<int>(
        $CollegeTasksTable.$converterreminderAtn.toSql(reminderAt),
      );
    }
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(
        $CollegeTasksTable.$convertercompletedAtn.toSql(completedAt),
      );
    }
    {
      map['created_at'] = Variable<int>(
        $CollegeTasksTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $CollegeTasksTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  CollegeTasksCompanion toCompanion(bool nullToAbsent) {
    return CollegeTasksCompanion(
      id: Value(id),
      semesterId: Value(semesterId),
      subjectId: subjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectId),
      title: Value(title),
      description: Value(description),
      type: Value(type),
      priority: Value(priority),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      dueTime: dueTime == null && nullToAbsent
          ? const Value.absent()
          : Value(dueTime),
      reminderAt: reminderAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderAt),
      isCompleted: Value(isCompleted),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRow(
      id: serializer.fromJson<int>(json['id']),
      semesterId: serializer.fromJson<int>(json['semesterId']),
      subjectId: serializer.fromJson<int?>(json['subjectId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      type: $CollegeTasksTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      priority: $CollegeTasksTable.$converterpriority.fromJson(
        serializer.fromJson<String>(json['priority']),
      ),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      dueTime: serializer.fromJson<int?>(json['dueTime']),
      reminderAt: serializer.fromJson<DateTime?>(json['reminderAt']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'semesterId': serializer.toJson<int>(semesterId),
      'subjectId': serializer.toJson<int?>(subjectId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'type': serializer.toJson<String>(
        $CollegeTasksTable.$convertertype.toJson(type),
      ),
      'priority': serializer.toJson<String>(
        $CollegeTasksTable.$converterpriority.toJson(priority),
      ),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'dueTime': serializer.toJson<int?>(dueTime),
      'reminderAt': serializer.toJson<DateTime?>(reminderAt),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TaskRow copyWith({
    int? id,
    int? semesterId,
    Value<int?> subjectId = const Value.absent(),
    String? title,
    String? description,
    CollegeTaskType? type,
    TaskPriority? priority,
    Value<DateTime?> dueDate = const Value.absent(),
    Value<int?> dueTime = const Value.absent(),
    Value<DateTime?> reminderAt = const Value.absent(),
    bool? isCompleted,
    Value<DateTime?> completedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TaskRow(
    id: id ?? this.id,
    semesterId: semesterId ?? this.semesterId,
    subjectId: subjectId.present ? subjectId.value : this.subjectId,
    title: title ?? this.title,
    description: description ?? this.description,
    type: type ?? this.type,
    priority: priority ?? this.priority,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    dueTime: dueTime.present ? dueTime.value : this.dueTime,
    reminderAt: reminderAt.present ? reminderAt.value : this.reminderAt,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TaskRow copyWithCompanion(CollegeTasksCompanion data) {
    return TaskRow(
      id: data.id.present ? data.id.value : this.id,
      semesterId: data.semesterId.present
          ? data.semesterId.value
          : this.semesterId,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      type: data.type.present ? data.type.value : this.type,
      priority: data.priority.present ? data.priority.value : this.priority,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      dueTime: data.dueTime.present ? data.dueTime.value : this.dueTime,
      reminderAt: data.reminderAt.present
          ? data.reminderAt.value
          : this.reminderAt,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRow(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('subjectId: $subjectId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('priority: $priority, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueTime: $dueTime, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    semesterId,
    subjectId,
    title,
    description,
    type,
    priority,
    dueDate,
    dueTime,
    reminderAt,
    isCompleted,
    completedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRow &&
          other.id == this.id &&
          other.semesterId == this.semesterId &&
          other.subjectId == this.subjectId &&
          other.title == this.title &&
          other.description == this.description &&
          other.type == this.type &&
          other.priority == this.priority &&
          other.dueDate == this.dueDate &&
          other.dueTime == this.dueTime &&
          other.reminderAt == this.reminderAt &&
          other.isCompleted == this.isCompleted &&
          other.completedAt == this.completedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CollegeTasksCompanion extends UpdateCompanion<TaskRow> {
  final Value<int> id;
  final Value<int> semesterId;
  final Value<int?> subjectId;
  final Value<String> title;
  final Value<String> description;
  final Value<CollegeTaskType> type;
  final Value<TaskPriority> priority;
  final Value<DateTime?> dueDate;
  final Value<int?> dueTime;
  final Value<DateTime?> reminderAt;
  final Value<bool> isCompleted;
  final Value<DateTime?> completedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CollegeTasksCompanion({
    this.id = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.priority = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.dueTime = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CollegeTasksCompanion.insert({
    this.id = const Value.absent(),
    required int semesterId,
    this.subjectId = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    required CollegeTaskType type,
    required TaskPriority priority,
    this.dueDate = const Value.absent(),
    this.dueTime = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : semesterId = Value(semesterId),
       title = Value(title),
       type = Value(type),
       priority = Value(priority);
  static Insertable<TaskRow> custom({
    Expression<int>? id,
    Expression<int>? semesterId,
    Expression<int>? subjectId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? type,
    Expression<String>? priority,
    Expression<int>? dueDate,
    Expression<int>? dueTime,
    Expression<int>? reminderAt,
    Expression<bool>? isCompleted,
    Expression<int>? completedAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (semesterId != null) 'semester_id': semesterId,
      if (subjectId != null) 'subject_id': subjectId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (priority != null) 'priority': priority,
      if (dueDate != null) 'due_date': dueDate,
      if (dueTime != null) 'due_time': dueTime,
      if (reminderAt != null) 'reminder_at': reminderAt,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (completedAt != null) 'completed_at': completedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CollegeTasksCompanion copyWith({
    Value<int>? id,
    Value<int>? semesterId,
    Value<int?>? subjectId,
    Value<String>? title,
    Value<String>? description,
    Value<CollegeTaskType>? type,
    Value<TaskPriority>? priority,
    Value<DateTime?>? dueDate,
    Value<int?>? dueTime,
    Value<DateTime?>? reminderAt,
    Value<bool>? isCompleted,
    Value<DateTime?>? completedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CollegeTasksCompanion(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      reminderAt: reminderAt ?? this.reminderAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<int>(semesterId.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<int>(subjectId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $CollegeTasksTable.$convertertype.toSql(type.value),
      );
    }
    if (priority.present) {
      map['priority'] = Variable<String>(
        $CollegeTasksTable.$converterpriority.toSql(priority.value),
      );
    }
    if (dueDate.present) {
      map['due_date'] = Variable<int>(
        $CollegeTasksTable.$converterdueDaten.toSql(dueDate.value),
      );
    }
    if (dueTime.present) {
      map['due_time'] = Variable<int>(dueTime.value);
    }
    if (reminderAt.present) {
      map['reminder_at'] = Variable<int>(
        $CollegeTasksTable.$converterreminderAtn.toSql(reminderAt.value),
      );
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(
        $CollegeTasksTable.$convertercompletedAtn.toSql(completedAt.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $CollegeTasksTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $CollegeTasksTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollegeTasksCompanion(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('subjectId: $subjectId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('priority: $priority, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueTime: $dueTime, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ExamsTable extends Exams with TableInfo<$ExamsTable, ExamRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _semesterIdMeta = const VerificationMeta(
    'semesterId',
  );
  @override
  late final GeneratedColumn<int> semesterId = GeneratedColumn<int>(
    'semester_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES semesters (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<int> subjectId = GeneratedColumn<int>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _examTypeMeta = const VerificationMeta(
    'examType',
  );
  @override
  late final GeneratedColumn<String> examType = GeneratedColumn<String>(
    'exam_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> examDate =
      GeneratedColumn<int>(
        'exam_date',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ExamsTable.$converterexamDate);
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<int> startTime = GeneratedColumn<int>(
    'start_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<int> endTime = GeneratedColumn<int>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roomMeta = const VerificationMeta('room');
  @override
  late final GeneratedColumn<String> room = GeneratedColumn<String>(
    'room',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _syllabusMeta = const VerificationMeta(
    'syllabus',
  );
  @override
  late final GeneratedColumn<String> syllabus = GeneratedColumn<String>(
    'syllabus',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _maxMarksMeta = const VerificationMeta(
    'maxMarks',
  );
  @override
  late final GeneratedColumn<double> maxMarks = GeneratedColumn<double>(
    'max_marks',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _obtainedMarksMeta = const VerificationMeta(
    'obtainedMarks',
  );
  @override
  late final GeneratedColumn<double> obtainedMarks = GeneratedColumn<double>(
    'obtained_marks',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> reminderAt =
      GeneratedColumn<int>(
        'reminder_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($ExamsTable.$converterreminderAtn);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: currentUtcMilliseconds,
      ).withConverter<DateTime>($ExamsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: currentUtcMilliseconds,
      ).withConverter<DateTime>($ExamsTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    semesterId,
    subjectId,
    name,
    examType,
    examDate,
    startTime,
    endTime,
    room,
    syllabus,
    maxMarks,
    obtainedMarks,
    reminderAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exams';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExamRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('semester_id')) {
      context.handle(
        _semesterIdMeta,
        semesterId.isAcceptableOrUnknown(data['semester_id']!, _semesterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('exam_type')) {
      context.handle(
        _examTypeMeta,
        examType.isAcceptableOrUnknown(data['exam_type']!, _examTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_examTypeMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('room')) {
      context.handle(
        _roomMeta,
        room.isAcceptableOrUnknown(data['room']!, _roomMeta),
      );
    }
    if (data.containsKey('syllabus')) {
      context.handle(
        _syllabusMeta,
        syllabus.isAcceptableOrUnknown(data['syllabus']!, _syllabusMeta),
      );
    }
    if (data.containsKey('max_marks')) {
      context.handle(
        _maxMarksMeta,
        maxMarks.isAcceptableOrUnknown(data['max_marks']!, _maxMarksMeta),
      );
    }
    if (data.containsKey('obtained_marks')) {
      context.handle(
        _obtainedMarksMeta,
        obtainedMarks.isAcceptableOrUnknown(
          data['obtained_marks']!,
          _obtainedMarksMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExamRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExamRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      semesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}semester_id'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subject_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      examType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exam_type'],
      )!,
      examDate: $ExamsTable.$converterexamDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}exam_date'],
        )!,
      ),
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_time'],
      ),
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_time'],
      ),
      room: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room'],
      )!,
      syllabus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}syllabus'],
      )!,
      maxMarks: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_marks'],
      ),
      obtainedMarks: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}obtained_marks'],
      ),
      reminderAt: $ExamsTable.$converterreminderAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}reminder_at'],
        ),
      ),
      createdAt: $ExamsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $ExamsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $ExamsTable createAlias(String alias) {
    return $ExamsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterexamDate =
      const EpochDayConverter();
  static TypeConverter<DateTime, int> $converterreminderAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime?, int?> $converterreminderAtn =
      NullAwareTypeConverter.wrap($converterreminderAt);
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class ExamRow extends DataClass implements Insertable<ExamRow> {
  final int id;
  final int semesterId;
  final int subjectId;
  final String name;
  final String examType;
  final DateTime examDate;
  final int? startTime;
  final int? endTime;
  final String room;
  final String syllabus;
  final double? maxMarks;
  final double? obtainedMarks;
  final DateTime? reminderAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ExamRow({
    required this.id,
    required this.semesterId,
    required this.subjectId,
    required this.name,
    required this.examType,
    required this.examDate,
    this.startTime,
    this.endTime,
    required this.room,
    required this.syllabus,
    this.maxMarks,
    this.obtainedMarks,
    this.reminderAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['semester_id'] = Variable<int>(semesterId);
    map['subject_id'] = Variable<int>(subjectId);
    map['name'] = Variable<String>(name);
    map['exam_type'] = Variable<String>(examType);
    {
      map['exam_date'] = Variable<int>(
        $ExamsTable.$converterexamDate.toSql(examDate),
      );
    }
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<int>(startTime);
    }
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<int>(endTime);
    }
    map['room'] = Variable<String>(room);
    map['syllabus'] = Variable<String>(syllabus);
    if (!nullToAbsent || maxMarks != null) {
      map['max_marks'] = Variable<double>(maxMarks);
    }
    if (!nullToAbsent || obtainedMarks != null) {
      map['obtained_marks'] = Variable<double>(obtainedMarks);
    }
    if (!nullToAbsent || reminderAt != null) {
      map['reminder_at'] = Variable<int>(
        $ExamsTable.$converterreminderAtn.toSql(reminderAt),
      );
    }
    {
      map['created_at'] = Variable<int>(
        $ExamsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $ExamsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  ExamsCompanion toCompanion(bool nullToAbsent) {
    return ExamsCompanion(
      id: Value(id),
      semesterId: Value(semesterId),
      subjectId: Value(subjectId),
      name: Value(name),
      examType: Value(examType),
      examDate: Value(examDate),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      room: Value(room),
      syllabus: Value(syllabus),
      maxMarks: maxMarks == null && nullToAbsent
          ? const Value.absent()
          : Value(maxMarks),
      obtainedMarks: obtainedMarks == null && nullToAbsent
          ? const Value.absent()
          : Value(obtainedMarks),
      reminderAt: reminderAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ExamRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExamRow(
      id: serializer.fromJson<int>(json['id']),
      semesterId: serializer.fromJson<int>(json['semesterId']),
      subjectId: serializer.fromJson<int>(json['subjectId']),
      name: serializer.fromJson<String>(json['name']),
      examType: serializer.fromJson<String>(json['examType']),
      examDate: serializer.fromJson<DateTime>(json['examDate']),
      startTime: serializer.fromJson<int?>(json['startTime']),
      endTime: serializer.fromJson<int?>(json['endTime']),
      room: serializer.fromJson<String>(json['room']),
      syllabus: serializer.fromJson<String>(json['syllabus']),
      maxMarks: serializer.fromJson<double?>(json['maxMarks']),
      obtainedMarks: serializer.fromJson<double?>(json['obtainedMarks']),
      reminderAt: serializer.fromJson<DateTime?>(json['reminderAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'semesterId': serializer.toJson<int>(semesterId),
      'subjectId': serializer.toJson<int>(subjectId),
      'name': serializer.toJson<String>(name),
      'examType': serializer.toJson<String>(examType),
      'examDate': serializer.toJson<DateTime>(examDate),
      'startTime': serializer.toJson<int?>(startTime),
      'endTime': serializer.toJson<int?>(endTime),
      'room': serializer.toJson<String>(room),
      'syllabus': serializer.toJson<String>(syllabus),
      'maxMarks': serializer.toJson<double?>(maxMarks),
      'obtainedMarks': serializer.toJson<double?>(obtainedMarks),
      'reminderAt': serializer.toJson<DateTime?>(reminderAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ExamRow copyWith({
    int? id,
    int? semesterId,
    int? subjectId,
    String? name,
    String? examType,
    DateTime? examDate,
    Value<int?> startTime = const Value.absent(),
    Value<int?> endTime = const Value.absent(),
    String? room,
    String? syllabus,
    Value<double?> maxMarks = const Value.absent(),
    Value<double?> obtainedMarks = const Value.absent(),
    Value<DateTime?> reminderAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ExamRow(
    id: id ?? this.id,
    semesterId: semesterId ?? this.semesterId,
    subjectId: subjectId ?? this.subjectId,
    name: name ?? this.name,
    examType: examType ?? this.examType,
    examDate: examDate ?? this.examDate,
    startTime: startTime.present ? startTime.value : this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    room: room ?? this.room,
    syllabus: syllabus ?? this.syllabus,
    maxMarks: maxMarks.present ? maxMarks.value : this.maxMarks,
    obtainedMarks: obtainedMarks.present
        ? obtainedMarks.value
        : this.obtainedMarks,
    reminderAt: reminderAt.present ? reminderAt.value : this.reminderAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ExamRow copyWithCompanion(ExamsCompanion data) {
    return ExamRow(
      id: data.id.present ? data.id.value : this.id,
      semesterId: data.semesterId.present
          ? data.semesterId.value
          : this.semesterId,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      name: data.name.present ? data.name.value : this.name,
      examType: data.examType.present ? data.examType.value : this.examType,
      examDate: data.examDate.present ? data.examDate.value : this.examDate,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      room: data.room.present ? data.room.value : this.room,
      syllabus: data.syllabus.present ? data.syllabus.value : this.syllabus,
      maxMarks: data.maxMarks.present ? data.maxMarks.value : this.maxMarks,
      obtainedMarks: data.obtainedMarks.present
          ? data.obtainedMarks.value
          : this.obtainedMarks,
      reminderAt: data.reminderAt.present
          ? data.reminderAt.value
          : this.reminderAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExamRow(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('subjectId: $subjectId, ')
          ..write('name: $name, ')
          ..write('examType: $examType, ')
          ..write('examDate: $examDate, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('room: $room, ')
          ..write('syllabus: $syllabus, ')
          ..write('maxMarks: $maxMarks, ')
          ..write('obtainedMarks: $obtainedMarks, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    semesterId,
    subjectId,
    name,
    examType,
    examDate,
    startTime,
    endTime,
    room,
    syllabus,
    maxMarks,
    obtainedMarks,
    reminderAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExamRow &&
          other.id == this.id &&
          other.semesterId == this.semesterId &&
          other.subjectId == this.subjectId &&
          other.name == this.name &&
          other.examType == this.examType &&
          other.examDate == this.examDate &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.room == this.room &&
          other.syllabus == this.syllabus &&
          other.maxMarks == this.maxMarks &&
          other.obtainedMarks == this.obtainedMarks &&
          other.reminderAt == this.reminderAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ExamsCompanion extends UpdateCompanion<ExamRow> {
  final Value<int> id;
  final Value<int> semesterId;
  final Value<int> subjectId;
  final Value<String> name;
  final Value<String> examType;
  final Value<DateTime> examDate;
  final Value<int?> startTime;
  final Value<int?> endTime;
  final Value<String> room;
  final Value<String> syllabus;
  final Value<double?> maxMarks;
  final Value<double?> obtainedMarks;
  final Value<DateTime?> reminderAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ExamsCompanion({
    this.id = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.name = const Value.absent(),
    this.examType = const Value.absent(),
    this.examDate = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.room = const Value.absent(),
    this.syllabus = const Value.absent(),
    this.maxMarks = const Value.absent(),
    this.obtainedMarks = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ExamsCompanion.insert({
    this.id = const Value.absent(),
    required int semesterId,
    required int subjectId,
    required String name,
    required String examType,
    required DateTime examDate,
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.room = const Value.absent(),
    this.syllabus = const Value.absent(),
    this.maxMarks = const Value.absent(),
    this.obtainedMarks = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : semesterId = Value(semesterId),
       subjectId = Value(subjectId),
       name = Value(name),
       examType = Value(examType),
       examDate = Value(examDate);
  static Insertable<ExamRow> custom({
    Expression<int>? id,
    Expression<int>? semesterId,
    Expression<int>? subjectId,
    Expression<String>? name,
    Expression<String>? examType,
    Expression<int>? examDate,
    Expression<int>? startTime,
    Expression<int>? endTime,
    Expression<String>? room,
    Expression<String>? syllabus,
    Expression<double>? maxMarks,
    Expression<double>? obtainedMarks,
    Expression<int>? reminderAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (semesterId != null) 'semester_id': semesterId,
      if (subjectId != null) 'subject_id': subjectId,
      if (name != null) 'name': name,
      if (examType != null) 'exam_type': examType,
      if (examDate != null) 'exam_date': examDate,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (room != null) 'room': room,
      if (syllabus != null) 'syllabus': syllabus,
      if (maxMarks != null) 'max_marks': maxMarks,
      if (obtainedMarks != null) 'obtained_marks': obtainedMarks,
      if (reminderAt != null) 'reminder_at': reminderAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ExamsCompanion copyWith({
    Value<int>? id,
    Value<int>? semesterId,
    Value<int>? subjectId,
    Value<String>? name,
    Value<String>? examType,
    Value<DateTime>? examDate,
    Value<int?>? startTime,
    Value<int?>? endTime,
    Value<String>? room,
    Value<String>? syllabus,
    Value<double?>? maxMarks,
    Value<double?>? obtainedMarks,
    Value<DateTime?>? reminderAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ExamsCompanion(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      examType: examType ?? this.examType,
      examDate: examDate ?? this.examDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      syllabus: syllabus ?? this.syllabus,
      maxMarks: maxMarks ?? this.maxMarks,
      obtainedMarks: obtainedMarks ?? this.obtainedMarks,
      reminderAt: reminderAt ?? this.reminderAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<int>(semesterId.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<int>(subjectId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (examType.present) {
      map['exam_type'] = Variable<String>(examType.value);
    }
    if (examDate.present) {
      map['exam_date'] = Variable<int>(
        $ExamsTable.$converterexamDate.toSql(examDate.value),
      );
    }
    if (startTime.present) {
      map['start_time'] = Variable<int>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<int>(endTime.value);
    }
    if (room.present) {
      map['room'] = Variable<String>(room.value);
    }
    if (syllabus.present) {
      map['syllabus'] = Variable<String>(syllabus.value);
    }
    if (maxMarks.present) {
      map['max_marks'] = Variable<double>(maxMarks.value);
    }
    if (obtainedMarks.present) {
      map['obtained_marks'] = Variable<double>(obtainedMarks.value);
    }
    if (reminderAt.present) {
      map['reminder_at'] = Variable<int>(
        $ExamsTable.$converterreminderAtn.toSql(reminderAt.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $ExamsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $ExamsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExamsCompanion(')
          ..write('id: $id, ')
          ..write('semesterId: $semesterId, ')
          ..write('subjectId: $subjectId, ')
          ..write('name: $name, ')
          ..write('examType: $examType, ')
          ..write('examDate: $examDate, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('room: $room, ')
          ..write('syllabus: $syllabus, ')
          ..write('maxMarks: $maxMarks, ')
          ..write('obtainedMarks: $obtainedMarks, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MarksTable extends Marks with TableInfo<$MarksTable, MarkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<int> subjectId = GeneratedColumn<int>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES subjects (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<int> examId = GeneratedColumn<int>(
    'exam_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _obtainedMarksMeta = const VerificationMeta(
    'obtainedMarks',
  );
  @override
  late final GeneratedColumn<double> obtainedMarks = GeneratedColumn<double>(
    'obtained_marks',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxMarksMeta = const VerificationMeta(
    'maxMarks',
  );
  @override
  late final GeneratedColumn<double> maxMarks = GeneratedColumn<double>(
    'max_marks',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> date =
      GeneratedColumn<int>(
        'date',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($MarksTable.$converterdate);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    subjectId,
    examId,
    category,
    obtainedMarks,
    maxMarks,
    date,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'marks';
  @override
  VerificationContext validateIntegrity(
    Insertable<MarkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('exam_id')) {
      context.handle(
        _examIdMeta,
        examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('obtained_marks')) {
      context.handle(
        _obtainedMarksMeta,
        obtainedMarks.isAcceptableOrUnknown(
          data['obtained_marks']!,
          _obtainedMarksMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_obtainedMarksMeta);
    }
    if (data.containsKey('max_marks')) {
      context.handle(
        _maxMarksMeta,
        maxMarks.isAcceptableOrUnknown(data['max_marks']!, _maxMarksMeta),
      );
    } else if (isInserting) {
      context.missing(_maxMarksMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MarkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MarkRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subject_id'],
      )!,
      examId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exam_id'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      obtainedMarks: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}obtained_marks'],
      )!,
      maxMarks: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_marks'],
      )!,
      date: $MarksTable.$converterdate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}date'],
        )!,
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
    );
  }

  @override
  $MarksTable createAlias(String alias) {
    return $MarksTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterdate =
      const EpochDayConverter();
}

class MarkRow extends DataClass implements Insertable<MarkRow> {
  final int id;
  final int subjectId;
  final int? examId;
  final String category;
  final double obtainedMarks;
  final double maxMarks;
  final DateTime date;
  final String note;
  const MarkRow({
    required this.id,
    required this.subjectId,
    this.examId,
    required this.category,
    required this.obtainedMarks,
    required this.maxMarks,
    required this.date,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['subject_id'] = Variable<int>(subjectId);
    if (!nullToAbsent || examId != null) {
      map['exam_id'] = Variable<int>(examId);
    }
    map['category'] = Variable<String>(category);
    map['obtained_marks'] = Variable<double>(obtainedMarks);
    map['max_marks'] = Variable<double>(maxMarks);
    {
      map['date'] = Variable<int>($MarksTable.$converterdate.toSql(date));
    }
    map['note'] = Variable<String>(note);
    return map;
  }

  MarksCompanion toCompanion(bool nullToAbsent) {
    return MarksCompanion(
      id: Value(id),
      subjectId: Value(subjectId),
      examId: examId == null && nullToAbsent
          ? const Value.absent()
          : Value(examId),
      category: Value(category),
      obtainedMarks: Value(obtainedMarks),
      maxMarks: Value(maxMarks),
      date: Value(date),
      note: Value(note),
    );
  }

  factory MarkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MarkRow(
      id: serializer.fromJson<int>(json['id']),
      subjectId: serializer.fromJson<int>(json['subjectId']),
      examId: serializer.fromJson<int?>(json['examId']),
      category: serializer.fromJson<String>(json['category']),
      obtainedMarks: serializer.fromJson<double>(json['obtainedMarks']),
      maxMarks: serializer.fromJson<double>(json['maxMarks']),
      date: serializer.fromJson<DateTime>(json['date']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'subjectId': serializer.toJson<int>(subjectId),
      'examId': serializer.toJson<int?>(examId),
      'category': serializer.toJson<String>(category),
      'obtainedMarks': serializer.toJson<double>(obtainedMarks),
      'maxMarks': serializer.toJson<double>(maxMarks),
      'date': serializer.toJson<DateTime>(date),
      'note': serializer.toJson<String>(note),
    };
  }

  MarkRow copyWith({
    int? id,
    int? subjectId,
    Value<int?> examId = const Value.absent(),
    String? category,
    double? obtainedMarks,
    double? maxMarks,
    DateTime? date,
    String? note,
  }) => MarkRow(
    id: id ?? this.id,
    subjectId: subjectId ?? this.subjectId,
    examId: examId.present ? examId.value : this.examId,
    category: category ?? this.category,
    obtainedMarks: obtainedMarks ?? this.obtainedMarks,
    maxMarks: maxMarks ?? this.maxMarks,
    date: date ?? this.date,
    note: note ?? this.note,
  );
  MarkRow copyWithCompanion(MarksCompanion data) {
    return MarkRow(
      id: data.id.present ? data.id.value : this.id,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      examId: data.examId.present ? data.examId.value : this.examId,
      category: data.category.present ? data.category.value : this.category,
      obtainedMarks: data.obtainedMarks.present
          ? data.obtainedMarks.value
          : this.obtainedMarks,
      maxMarks: data.maxMarks.present ? data.maxMarks.value : this.maxMarks,
      date: data.date.present ? data.date.value : this.date,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MarkRow(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('examId: $examId, ')
          ..write('category: $category, ')
          ..write('obtainedMarks: $obtainedMarks, ')
          ..write('maxMarks: $maxMarks, ')
          ..write('date: $date, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    subjectId,
    examId,
    category,
    obtainedMarks,
    maxMarks,
    date,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MarkRow &&
          other.id == this.id &&
          other.subjectId == this.subjectId &&
          other.examId == this.examId &&
          other.category == this.category &&
          other.obtainedMarks == this.obtainedMarks &&
          other.maxMarks == this.maxMarks &&
          other.date == this.date &&
          other.note == this.note);
}

class MarksCompanion extends UpdateCompanion<MarkRow> {
  final Value<int> id;
  final Value<int> subjectId;
  final Value<int?> examId;
  final Value<String> category;
  final Value<double> obtainedMarks;
  final Value<double> maxMarks;
  final Value<DateTime> date;
  final Value<String> note;
  const MarksCompanion({
    this.id = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.examId = const Value.absent(),
    this.category = const Value.absent(),
    this.obtainedMarks = const Value.absent(),
    this.maxMarks = const Value.absent(),
    this.date = const Value.absent(),
    this.note = const Value.absent(),
  });
  MarksCompanion.insert({
    this.id = const Value.absent(),
    required int subjectId,
    this.examId = const Value.absent(),
    required String category,
    required double obtainedMarks,
    required double maxMarks,
    required DateTime date,
    this.note = const Value.absent(),
  }) : subjectId = Value(subjectId),
       category = Value(category),
       obtainedMarks = Value(obtainedMarks),
       maxMarks = Value(maxMarks),
       date = Value(date);
  static Insertable<MarkRow> custom({
    Expression<int>? id,
    Expression<int>? subjectId,
    Expression<int>? examId,
    Expression<String>? category,
    Expression<double>? obtainedMarks,
    Expression<double>? maxMarks,
    Expression<int>? date,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subjectId != null) 'subject_id': subjectId,
      if (examId != null) 'exam_id': examId,
      if (category != null) 'category': category,
      if (obtainedMarks != null) 'obtained_marks': obtainedMarks,
      if (maxMarks != null) 'max_marks': maxMarks,
      if (date != null) 'date': date,
      if (note != null) 'note': note,
    });
  }

  MarksCompanion copyWith({
    Value<int>? id,
    Value<int>? subjectId,
    Value<int?>? examId,
    Value<String>? category,
    Value<double>? obtainedMarks,
    Value<double>? maxMarks,
    Value<DateTime>? date,
    Value<String>? note,
  }) {
    return MarksCompanion(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      examId: examId ?? this.examId,
      category: category ?? this.category,
      obtainedMarks: obtainedMarks ?? this.obtainedMarks,
      maxMarks: maxMarks ?? this.maxMarks,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<int>(subjectId.value);
    }
    if (examId.present) {
      map['exam_id'] = Variable<int>(examId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (obtainedMarks.present) {
      map['obtained_marks'] = Variable<double>(obtainedMarks.value);
    }
    if (maxMarks.present) {
      map['max_marks'] = Variable<double>(maxMarks.value);
    }
    if (date.present) {
      map['date'] = Variable<int>($MarksTable.$converterdate.toSql(date.value));
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MarksCompanion(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('examId: $examId, ')
          ..write('category: $category, ')
          ..write('obtainedMarks: $obtainedMarks, ')
          ..write('maxMarks: $maxMarks, ')
          ..write('date: $date, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _studentNameMeta = const VerificationMeta(
    'studentName',
  );
  @override
  late final GeneratedColumn<String> studentName = GeneratedColumn<String>(
    'student_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _collegeNameMeta = const VerificationMeta(
    'collegeName',
  );
  @override
  late final GeneratedColumn<String> collegeName = GeneratedColumn<String>(
    'college_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _courseMeta = const VerificationMeta('course');
  @override
  late final GeneratedColumn<String> course = GeneratedColumn<String>(
    'course',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _branchMeta = const VerificationMeta('branch');
  @override
  late final GeneratedColumn<String> branch = GeneratedColumn<String>(
    'branch',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int>
  academicYearStartDate =
      GeneratedColumn<int>(
        'academic_year_start_date',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>(
        $AppSettingsTable.$converteracademicYearStartDaten,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int>
  academicYearEndDate = GeneratedColumn<int>(
    'academic_year_end_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<DateTime?>($AppSettingsTable.$converteracademicYearEndDaten);
  static const VerificationMeta _defaultAttendanceTargetMeta =
      const VerificationMeta('defaultAttendanceTarget');
  @override
  late final GeneratedColumn<double> defaultAttendanceTarget =
      GeneratedColumn<double>(
        'default_attendance_target',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.75),
      );
  @override
  late final GeneratedColumnWithTypeConverter<CollegeThemeMode, String>
  themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  ).withConverter<CollegeThemeMode>($AppSettingsTable.$converterthemeMode);
  static const VerificationMeta _onboardingCompletedMeta =
      const VerificationMeta('onboardingCompleted');
  @override
  late final GeneratedColumn<bool> onboardingCompleted = GeneratedColumn<bool>(
    'onboarding_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notificationsEnabledMeta =
      const VerificationMeta('notificationsEnabled');
  @override
  late final GeneratedColumn<bool> notificationsEnabled = GeneratedColumn<bool>(
    'notifications_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notifications_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _automaticLocalBackupMeta =
      const VerificationMeta('automaticLocalBackup');
  @override
  late final GeneratedColumn<bool> automaticLocalBackup = GeneratedColumn<bool>(
    'automatic_local_backup',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("automatic_local_backup" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _classRemindersEnabledMeta =
      const VerificationMeta('classRemindersEnabled');
  @override
  late final GeneratedColumn<bool> classRemindersEnabled =
      GeneratedColumn<bool>(
        'class_reminders_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("class_reminders_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _classReminderMinutesBeforeMeta =
      const VerificationMeta('classReminderMinutesBefore');
  @override
  late final GeneratedColumn<int> classReminderMinutesBefore =
      GeneratedColumn<int>(
        'class_reminder_minutes_before',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(10),
      );
  static const VerificationMeta _sundayOffMeta = const VerificationMeta(
    'sundayOff',
  );
  @override
  late final GeneratedColumn<bool> sundayOff = GeneratedColumn<bool>(
    'sunday_off',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sunday_off" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _secondSaturdayOffMeta = const VerificationMeta(
    'secondSaturdayOff',
  );
  @override
  late final GeneratedColumn<bool> secondSaturdayOff = GeneratedColumn<bool>(
    'second_saturday_off',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("second_saturday_off" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _governmentHolidaysOffMeta =
      const VerificationMeta('governmentHolidaysOff');
  @override
  late final GeneratedColumn<bool> governmentHolidaysOff =
      GeneratedColumn<bool>(
        'government_holidays_off',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("government_holidays_off" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    studentName,
    collegeName,
    course,
    branch,
    academicYearStartDate,
    academicYearEndDate,
    defaultAttendanceTarget,
    themeMode,
    onboardingCompleted,
    notificationsEnabled,
    automaticLocalBackup,
    classRemindersEnabled,
    classReminderMinutesBefore,
    sundayOff,
    secondSaturdayOff,
    governmentHolidaysOff,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('student_name')) {
      context.handle(
        _studentNameMeta,
        studentName.isAcceptableOrUnknown(
          data['student_name']!,
          _studentNameMeta,
        ),
      );
    }
    if (data.containsKey('college_name')) {
      context.handle(
        _collegeNameMeta,
        collegeName.isAcceptableOrUnknown(
          data['college_name']!,
          _collegeNameMeta,
        ),
      );
    }
    if (data.containsKey('course')) {
      context.handle(
        _courseMeta,
        course.isAcceptableOrUnknown(data['course']!, _courseMeta),
      );
    }
    if (data.containsKey('branch')) {
      context.handle(
        _branchMeta,
        branch.isAcceptableOrUnknown(data['branch']!, _branchMeta),
      );
    }
    if (data.containsKey('default_attendance_target')) {
      context.handle(
        _defaultAttendanceTargetMeta,
        defaultAttendanceTarget.isAcceptableOrUnknown(
          data['default_attendance_target']!,
          _defaultAttendanceTargetMeta,
        ),
      );
    }
    if (data.containsKey('onboarding_completed')) {
      context.handle(
        _onboardingCompletedMeta,
        onboardingCompleted.isAcceptableOrUnknown(
          data['onboarding_completed']!,
          _onboardingCompletedMeta,
        ),
      );
    }
    if (data.containsKey('notifications_enabled')) {
      context.handle(
        _notificationsEnabledMeta,
        notificationsEnabled.isAcceptableOrUnknown(
          data['notifications_enabled']!,
          _notificationsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('automatic_local_backup')) {
      context.handle(
        _automaticLocalBackupMeta,
        automaticLocalBackup.isAcceptableOrUnknown(
          data['automatic_local_backup']!,
          _automaticLocalBackupMeta,
        ),
      );
    }
    if (data.containsKey('class_reminders_enabled')) {
      context.handle(
        _classRemindersEnabledMeta,
        classRemindersEnabled.isAcceptableOrUnknown(
          data['class_reminders_enabled']!,
          _classRemindersEnabledMeta,
        ),
      );
    }
    if (data.containsKey('class_reminder_minutes_before')) {
      context.handle(
        _classReminderMinutesBeforeMeta,
        classReminderMinutesBefore.isAcceptableOrUnknown(
          data['class_reminder_minutes_before']!,
          _classReminderMinutesBeforeMeta,
        ),
      );
    }
    if (data.containsKey('sunday_off')) {
      context.handle(
        _sundayOffMeta,
        sundayOff.isAcceptableOrUnknown(data['sunday_off']!, _sundayOffMeta),
      );
    }
    if (data.containsKey('second_saturday_off')) {
      context.handle(
        _secondSaturdayOffMeta,
        secondSaturdayOff.isAcceptableOrUnknown(
          data['second_saturday_off']!,
          _secondSaturdayOffMeta,
        ),
      );
    }
    if (data.containsKey('government_holidays_off')) {
      context.handle(
        _governmentHolidaysOffMeta,
        governmentHolidaysOff.isAcceptableOrUnknown(
          data['government_holidays_off']!,
          _governmentHolidaysOffMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      studentName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_name'],
      )!,
      collegeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}college_name'],
      )!,
      course: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course'],
      )!,
      branch: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch'],
      )!,
      academicYearStartDate: $AppSettingsTable.$converteracademicYearStartDaten
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.int,
              data['${effectivePrefix}academic_year_start_date'],
            ),
          ),
      academicYearEndDate: $AppSettingsTable.$converteracademicYearEndDaten
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.int,
              data['${effectivePrefix}academic_year_end_date'],
            ),
          ),
      defaultAttendanceTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}default_attendance_target'],
      )!,
      themeMode: $AppSettingsTable.$converterthemeMode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}theme_mode'],
        )!,
      ),
      onboardingCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_completed'],
      )!,
      notificationsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notifications_enabled'],
      )!,
      automaticLocalBackup: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}automatic_local_backup'],
      )!,
      classRemindersEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}class_reminders_enabled'],
      )!,
      classReminderMinutesBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}class_reminder_minutes_before'],
      )!,
      sundayOff: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sunday_off'],
      )!,
      secondSaturdayOff: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}second_saturday_off'],
      )!,
      governmentHolidaysOff: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}government_holidays_off'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converteracademicYearStartDate =
      const EpochDayConverter();
  static TypeConverter<DateTime?, int?> $converteracademicYearStartDaten =
      NullAwareTypeConverter.wrap($converteracademicYearStartDate);
  static TypeConverter<DateTime, int> $converteracademicYearEndDate =
      const EpochDayConverter();
  static TypeConverter<DateTime?, int?> $converteracademicYearEndDaten =
      NullAwareTypeConverter.wrap($converteracademicYearEndDate);
  static JsonTypeConverter2<CollegeThemeMode, String, String>
  $converterthemeMode = const EnumNameConverter<CollegeThemeMode>(
    CollegeThemeMode.values,
  );
}

class AppSettingsRow extends DataClass implements Insertable<AppSettingsRow> {
  final int id;
  final String studentName;
  final String collegeName;
  final String course;
  final String branch;
  final DateTime? academicYearStartDate;
  final DateTime? academicYearEndDate;
  final double defaultAttendanceTarget;
  final CollegeThemeMode themeMode;
  final bool onboardingCompleted;
  final bool notificationsEnabled;
  final bool automaticLocalBackup;

  /// Whether the student wants reminders for timetable classes at all.
  ///
  /// Independent of [notificationsEnabled]: the global switch pauses every
  /// reminder type, while this one pauses only classes. Both must be on before
  /// a class alarm is handed to Android.
  final bool classRemindersEnabled;

  /// Lead time, in minutes before a class start, offered to every class that
  /// has no reminder of its own.
  ///
  /// Mirrored by the `class_reminder_minutes_before` CHECK constraint below and
  /// by `minClassReminderLeadMinutes`/`maxClassReminderLeadMinutes`, so the
  /// database, the Settings picker and a class's own reminder agree on exactly
  /// one range. Declared last so a migration that only adds these columns
  /// produces the same table SQL as a fresh create.
  final int classReminderMinutesBefore;

  /// Whether Sundays are treated as holidays without a stored calendar row.
  ///
  /// The rule is derived, never persisted per day: a class scheduled on a
  /// Sunday is still a normal class, it is simply excluded while this is on.
  final bool sundayOff;

  /// Whether the second Saturday of each month is treated as a holiday.
  ///
  /// Derived the same way as [sundayOff], and combined with it: a month whose
  /// second Saturday is also its Sunday keeps both rules.
  final bool secondSaturdayOff;

  /// Whether the fixed-date national holidays are treated as holidays.
  ///
  /// The dates are constants rather than stored events, so the rule needs no
  /// yearly data: Republic Day (26 January), Independence Day (15 August) and
  /// Gandhi Jayanti (2 October). Declared last so a migration that only adds
  /// these columns produces the same table SQL as a fresh create.
  final bool governmentHolidaysOff;
  const AppSettingsRow({
    required this.id,
    required this.studentName,
    required this.collegeName,
    required this.course,
    required this.branch,
    this.academicYearStartDate,
    this.academicYearEndDate,
    required this.defaultAttendanceTarget,
    required this.themeMode,
    required this.onboardingCompleted,
    required this.notificationsEnabled,
    required this.automaticLocalBackup,
    required this.classRemindersEnabled,
    required this.classReminderMinutesBefore,
    required this.sundayOff,
    required this.secondSaturdayOff,
    required this.governmentHolidaysOff,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['student_name'] = Variable<String>(studentName);
    map['college_name'] = Variable<String>(collegeName);
    map['course'] = Variable<String>(course);
    map['branch'] = Variable<String>(branch);
    if (!nullToAbsent || academicYearStartDate != null) {
      map['academic_year_start_date'] = Variable<int>(
        $AppSettingsTable.$converteracademicYearStartDaten.toSql(
          academicYearStartDate,
        ),
      );
    }
    if (!nullToAbsent || academicYearEndDate != null) {
      map['academic_year_end_date'] = Variable<int>(
        $AppSettingsTable.$converteracademicYearEndDaten.toSql(
          academicYearEndDate,
        ),
      );
    }
    map['default_attendance_target'] = Variable<double>(
      defaultAttendanceTarget,
    );
    {
      map['theme_mode'] = Variable<String>(
        $AppSettingsTable.$converterthemeMode.toSql(themeMode),
      );
    }
    map['onboarding_completed'] = Variable<bool>(onboardingCompleted);
    map['notifications_enabled'] = Variable<bool>(notificationsEnabled);
    map['automatic_local_backup'] = Variable<bool>(automaticLocalBackup);
    map['class_reminders_enabled'] = Variable<bool>(classRemindersEnabled);
    map['class_reminder_minutes_before'] = Variable<int>(
      classReminderMinutesBefore,
    );
    map['sunday_off'] = Variable<bool>(sundayOff);
    map['second_saturday_off'] = Variable<bool>(secondSaturdayOff);
    map['government_holidays_off'] = Variable<bool>(governmentHolidaysOff);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      studentName: Value(studentName),
      collegeName: Value(collegeName),
      course: Value(course),
      branch: Value(branch),
      academicYearStartDate: academicYearStartDate == null && nullToAbsent
          ? const Value.absent()
          : Value(academicYearStartDate),
      academicYearEndDate: academicYearEndDate == null && nullToAbsent
          ? const Value.absent()
          : Value(academicYearEndDate),
      defaultAttendanceTarget: Value(defaultAttendanceTarget),
      themeMode: Value(themeMode),
      onboardingCompleted: Value(onboardingCompleted),
      notificationsEnabled: Value(notificationsEnabled),
      automaticLocalBackup: Value(automaticLocalBackup),
      classRemindersEnabled: Value(classRemindersEnabled),
      classReminderMinutesBefore: Value(classReminderMinutesBefore),
      sundayOff: Value(sundayOff),
      secondSaturdayOff: Value(secondSaturdayOff),
      governmentHolidaysOff: Value(governmentHolidaysOff),
    );
  }

  factory AppSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      studentName: serializer.fromJson<String>(json['studentName']),
      collegeName: serializer.fromJson<String>(json['collegeName']),
      course: serializer.fromJson<String>(json['course']),
      branch: serializer.fromJson<String>(json['branch']),
      academicYearStartDate: serializer.fromJson<DateTime?>(
        json['academicYearStartDate'],
      ),
      academicYearEndDate: serializer.fromJson<DateTime?>(
        json['academicYearEndDate'],
      ),
      defaultAttendanceTarget: serializer.fromJson<double>(
        json['defaultAttendanceTarget'],
      ),
      themeMode: $AppSettingsTable.$converterthemeMode.fromJson(
        serializer.fromJson<String>(json['themeMode']),
      ),
      onboardingCompleted: serializer.fromJson<bool>(
        json['onboardingCompleted'],
      ),
      notificationsEnabled: serializer.fromJson<bool>(
        json['notificationsEnabled'],
      ),
      automaticLocalBackup: serializer.fromJson<bool>(
        json['automaticLocalBackup'],
      ),
      classRemindersEnabled: serializer.fromJson<bool>(
        json['classRemindersEnabled'],
      ),
      classReminderMinutesBefore: serializer.fromJson<int>(
        json['classReminderMinutesBefore'],
      ),
      sundayOff: serializer.fromJson<bool>(json['sundayOff']),
      secondSaturdayOff: serializer.fromJson<bool>(json['secondSaturdayOff']),
      governmentHolidaysOff: serializer.fromJson<bool>(
        json['governmentHolidaysOff'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'studentName': serializer.toJson<String>(studentName),
      'collegeName': serializer.toJson<String>(collegeName),
      'course': serializer.toJson<String>(course),
      'branch': serializer.toJson<String>(branch),
      'academicYearStartDate': serializer.toJson<DateTime?>(
        academicYearStartDate,
      ),
      'academicYearEndDate': serializer.toJson<DateTime?>(academicYearEndDate),
      'defaultAttendanceTarget': serializer.toJson<double>(
        defaultAttendanceTarget,
      ),
      'themeMode': serializer.toJson<String>(
        $AppSettingsTable.$converterthemeMode.toJson(themeMode),
      ),
      'onboardingCompleted': serializer.toJson<bool>(onboardingCompleted),
      'notificationsEnabled': serializer.toJson<bool>(notificationsEnabled),
      'automaticLocalBackup': serializer.toJson<bool>(automaticLocalBackup),
      'classRemindersEnabled': serializer.toJson<bool>(classRemindersEnabled),
      'classReminderMinutesBefore': serializer.toJson<int>(
        classReminderMinutesBefore,
      ),
      'sundayOff': serializer.toJson<bool>(sundayOff),
      'secondSaturdayOff': serializer.toJson<bool>(secondSaturdayOff),
      'governmentHolidaysOff': serializer.toJson<bool>(governmentHolidaysOff),
    };
  }

  AppSettingsRow copyWith({
    int? id,
    String? studentName,
    String? collegeName,
    String? course,
    String? branch,
    Value<DateTime?> academicYearStartDate = const Value.absent(),
    Value<DateTime?> academicYearEndDate = const Value.absent(),
    double? defaultAttendanceTarget,
    CollegeThemeMode? themeMode,
    bool? onboardingCompleted,
    bool? notificationsEnabled,
    bool? automaticLocalBackup,
    bool? classRemindersEnabled,
    int? classReminderMinutesBefore,
    bool? sundayOff,
    bool? secondSaturdayOff,
    bool? governmentHolidaysOff,
  }) => AppSettingsRow(
    id: id ?? this.id,
    studentName: studentName ?? this.studentName,
    collegeName: collegeName ?? this.collegeName,
    course: course ?? this.course,
    branch: branch ?? this.branch,
    academicYearStartDate: academicYearStartDate.present
        ? academicYearStartDate.value
        : this.academicYearStartDate,
    academicYearEndDate: academicYearEndDate.present
        ? academicYearEndDate.value
        : this.academicYearEndDate,
    defaultAttendanceTarget:
        defaultAttendanceTarget ?? this.defaultAttendanceTarget,
    themeMode: themeMode ?? this.themeMode,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    automaticLocalBackup: automaticLocalBackup ?? this.automaticLocalBackup,
    classRemindersEnabled: classRemindersEnabled ?? this.classRemindersEnabled,
    classReminderMinutesBefore:
        classReminderMinutesBefore ?? this.classReminderMinutesBefore,
    sundayOff: sundayOff ?? this.sundayOff,
    secondSaturdayOff: secondSaturdayOff ?? this.secondSaturdayOff,
    governmentHolidaysOff: governmentHolidaysOff ?? this.governmentHolidaysOff,
  );
  AppSettingsRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      studentName: data.studentName.present
          ? data.studentName.value
          : this.studentName,
      collegeName: data.collegeName.present
          ? data.collegeName.value
          : this.collegeName,
      course: data.course.present ? data.course.value : this.course,
      branch: data.branch.present ? data.branch.value : this.branch,
      academicYearStartDate: data.academicYearStartDate.present
          ? data.academicYearStartDate.value
          : this.academicYearStartDate,
      academicYearEndDate: data.academicYearEndDate.present
          ? data.academicYearEndDate.value
          : this.academicYearEndDate,
      defaultAttendanceTarget: data.defaultAttendanceTarget.present
          ? data.defaultAttendanceTarget.value
          : this.defaultAttendanceTarget,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      onboardingCompleted: data.onboardingCompleted.present
          ? data.onboardingCompleted.value
          : this.onboardingCompleted,
      notificationsEnabled: data.notificationsEnabled.present
          ? data.notificationsEnabled.value
          : this.notificationsEnabled,
      automaticLocalBackup: data.automaticLocalBackup.present
          ? data.automaticLocalBackup.value
          : this.automaticLocalBackup,
      classRemindersEnabled: data.classRemindersEnabled.present
          ? data.classRemindersEnabled.value
          : this.classRemindersEnabled,
      classReminderMinutesBefore: data.classReminderMinutesBefore.present
          ? data.classReminderMinutesBefore.value
          : this.classReminderMinutesBefore,
      sundayOff: data.sundayOff.present ? data.sundayOff.value : this.sundayOff,
      secondSaturdayOff: data.secondSaturdayOff.present
          ? data.secondSaturdayOff.value
          : this.secondSaturdayOff,
      governmentHolidaysOff: data.governmentHolidaysOff.present
          ? data.governmentHolidaysOff.value
          : this.governmentHolidaysOff,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsRow(')
          ..write('id: $id, ')
          ..write('studentName: $studentName, ')
          ..write('collegeName: $collegeName, ')
          ..write('course: $course, ')
          ..write('branch: $branch, ')
          ..write('academicYearStartDate: $academicYearStartDate, ')
          ..write('academicYearEndDate: $academicYearEndDate, ')
          ..write('defaultAttendanceTarget: $defaultAttendanceTarget, ')
          ..write('themeMode: $themeMode, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('automaticLocalBackup: $automaticLocalBackup, ')
          ..write('classRemindersEnabled: $classRemindersEnabled, ')
          ..write('classReminderMinutesBefore: $classReminderMinutesBefore, ')
          ..write('sundayOff: $sundayOff, ')
          ..write('secondSaturdayOff: $secondSaturdayOff, ')
          ..write('governmentHolidaysOff: $governmentHolidaysOff')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    studentName,
    collegeName,
    course,
    branch,
    academicYearStartDate,
    academicYearEndDate,
    defaultAttendanceTarget,
    themeMode,
    onboardingCompleted,
    notificationsEnabled,
    automaticLocalBackup,
    classRemindersEnabled,
    classReminderMinutesBefore,
    sundayOff,
    secondSaturdayOff,
    governmentHolidaysOff,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsRow &&
          other.id == this.id &&
          other.studentName == this.studentName &&
          other.collegeName == this.collegeName &&
          other.course == this.course &&
          other.branch == this.branch &&
          other.academicYearStartDate == this.academicYearStartDate &&
          other.academicYearEndDate == this.academicYearEndDate &&
          other.defaultAttendanceTarget == this.defaultAttendanceTarget &&
          other.themeMode == this.themeMode &&
          other.onboardingCompleted == this.onboardingCompleted &&
          other.notificationsEnabled == this.notificationsEnabled &&
          other.automaticLocalBackup == this.automaticLocalBackup &&
          other.classRemindersEnabled == this.classRemindersEnabled &&
          other.classReminderMinutesBefore == this.classReminderMinutesBefore &&
          other.sundayOff == this.sundayOff &&
          other.secondSaturdayOff == this.secondSaturdayOff &&
          other.governmentHolidaysOff == this.governmentHolidaysOff);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingsRow> {
  final Value<int> id;
  final Value<String> studentName;
  final Value<String> collegeName;
  final Value<String> course;
  final Value<String> branch;
  final Value<DateTime?> academicYearStartDate;
  final Value<DateTime?> academicYearEndDate;
  final Value<double> defaultAttendanceTarget;
  final Value<CollegeThemeMode> themeMode;
  final Value<bool> onboardingCompleted;
  final Value<bool> notificationsEnabled;
  final Value<bool> automaticLocalBackup;
  final Value<bool> classRemindersEnabled;
  final Value<int> classReminderMinutesBefore;
  final Value<bool> sundayOff;
  final Value<bool> secondSaturdayOff;
  final Value<bool> governmentHolidaysOff;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.studentName = const Value.absent(),
    this.collegeName = const Value.absent(),
    this.course = const Value.absent(),
    this.branch = const Value.absent(),
    this.academicYearStartDate = const Value.absent(),
    this.academicYearEndDate = const Value.absent(),
    this.defaultAttendanceTarget = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.automaticLocalBackup = const Value.absent(),
    this.classRemindersEnabled = const Value.absent(),
    this.classReminderMinutesBefore = const Value.absent(),
    this.sundayOff = const Value.absent(),
    this.secondSaturdayOff = const Value.absent(),
    this.governmentHolidaysOff = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.studentName = const Value.absent(),
    this.collegeName = const Value.absent(),
    this.course = const Value.absent(),
    this.branch = const Value.absent(),
    this.academicYearStartDate = const Value.absent(),
    this.academicYearEndDate = const Value.absent(),
    this.defaultAttendanceTarget = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.automaticLocalBackup = const Value.absent(),
    this.classRemindersEnabled = const Value.absent(),
    this.classReminderMinutesBefore = const Value.absent(),
    this.sundayOff = const Value.absent(),
    this.secondSaturdayOff = const Value.absent(),
    this.governmentHolidaysOff = const Value.absent(),
  });
  static Insertable<AppSettingsRow> custom({
    Expression<int>? id,
    Expression<String>? studentName,
    Expression<String>? collegeName,
    Expression<String>? course,
    Expression<String>? branch,
    Expression<int>? academicYearStartDate,
    Expression<int>? academicYearEndDate,
    Expression<double>? defaultAttendanceTarget,
    Expression<String>? themeMode,
    Expression<bool>? onboardingCompleted,
    Expression<bool>? notificationsEnabled,
    Expression<bool>? automaticLocalBackup,
    Expression<bool>? classRemindersEnabled,
    Expression<int>? classReminderMinutesBefore,
    Expression<bool>? sundayOff,
    Expression<bool>? secondSaturdayOff,
    Expression<bool>? governmentHolidaysOff,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentName != null) 'student_name': studentName,
      if (collegeName != null) 'college_name': collegeName,
      if (course != null) 'course': course,
      if (branch != null) 'branch': branch,
      if (academicYearStartDate != null)
        'academic_year_start_date': academicYearStartDate,
      if (academicYearEndDate != null)
        'academic_year_end_date': academicYearEndDate,
      if (defaultAttendanceTarget != null)
        'default_attendance_target': defaultAttendanceTarget,
      if (themeMode != null) 'theme_mode': themeMode,
      if (onboardingCompleted != null)
        'onboarding_completed': onboardingCompleted,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
      if (automaticLocalBackup != null)
        'automatic_local_backup': automaticLocalBackup,
      if (classRemindersEnabled != null)
        'class_reminders_enabled': classRemindersEnabled,
      if (classReminderMinutesBefore != null)
        'class_reminder_minutes_before': classReminderMinutesBefore,
      if (sundayOff != null) 'sunday_off': sundayOff,
      if (secondSaturdayOff != null) 'second_saturday_off': secondSaturdayOff,
      if (governmentHolidaysOff != null)
        'government_holidays_off': governmentHolidaysOff,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? studentName,
    Value<String>? collegeName,
    Value<String>? course,
    Value<String>? branch,
    Value<DateTime?>? academicYearStartDate,
    Value<DateTime?>? academicYearEndDate,
    Value<double>? defaultAttendanceTarget,
    Value<CollegeThemeMode>? themeMode,
    Value<bool>? onboardingCompleted,
    Value<bool>? notificationsEnabled,
    Value<bool>? automaticLocalBackup,
    Value<bool>? classRemindersEnabled,
    Value<int>? classReminderMinutesBefore,
    Value<bool>? sundayOff,
    Value<bool>? secondSaturdayOff,
    Value<bool>? governmentHolidaysOff,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      studentName: studentName ?? this.studentName,
      collegeName: collegeName ?? this.collegeName,
      course: course ?? this.course,
      branch: branch ?? this.branch,
      academicYearStartDate:
          academicYearStartDate ?? this.academicYearStartDate,
      academicYearEndDate: academicYearEndDate ?? this.academicYearEndDate,
      defaultAttendanceTarget:
          defaultAttendanceTarget ?? this.defaultAttendanceTarget,
      themeMode: themeMode ?? this.themeMode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      automaticLocalBackup: automaticLocalBackup ?? this.automaticLocalBackup,
      classRemindersEnabled:
          classRemindersEnabled ?? this.classRemindersEnabled,
      classReminderMinutesBefore:
          classReminderMinutesBefore ?? this.classReminderMinutesBefore,
      sundayOff: sundayOff ?? this.sundayOff,
      secondSaturdayOff: secondSaturdayOff ?? this.secondSaturdayOff,
      governmentHolidaysOff:
          governmentHolidaysOff ?? this.governmentHolidaysOff,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (studentName.present) {
      map['student_name'] = Variable<String>(studentName.value);
    }
    if (collegeName.present) {
      map['college_name'] = Variable<String>(collegeName.value);
    }
    if (course.present) {
      map['course'] = Variable<String>(course.value);
    }
    if (branch.present) {
      map['branch'] = Variable<String>(branch.value);
    }
    if (academicYearStartDate.present) {
      map['academic_year_start_date'] = Variable<int>(
        $AppSettingsTable.$converteracademicYearStartDaten.toSql(
          academicYearStartDate.value,
        ),
      );
    }
    if (academicYearEndDate.present) {
      map['academic_year_end_date'] = Variable<int>(
        $AppSettingsTable.$converteracademicYearEndDaten.toSql(
          academicYearEndDate.value,
        ),
      );
    }
    if (defaultAttendanceTarget.present) {
      map['default_attendance_target'] = Variable<double>(
        defaultAttendanceTarget.value,
      );
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(
        $AppSettingsTable.$converterthemeMode.toSql(themeMode.value),
      );
    }
    if (onboardingCompleted.present) {
      map['onboarding_completed'] = Variable<bool>(onboardingCompleted.value);
    }
    if (notificationsEnabled.present) {
      map['notifications_enabled'] = Variable<bool>(notificationsEnabled.value);
    }
    if (automaticLocalBackup.present) {
      map['automatic_local_backup'] = Variable<bool>(
        automaticLocalBackup.value,
      );
    }
    if (classRemindersEnabled.present) {
      map['class_reminders_enabled'] = Variable<bool>(
        classRemindersEnabled.value,
      );
    }
    if (classReminderMinutesBefore.present) {
      map['class_reminder_minutes_before'] = Variable<int>(
        classReminderMinutesBefore.value,
      );
    }
    if (sundayOff.present) {
      map['sunday_off'] = Variable<bool>(sundayOff.value);
    }
    if (secondSaturdayOff.present) {
      map['second_saturday_off'] = Variable<bool>(secondSaturdayOff.value);
    }
    if (governmentHolidaysOff.present) {
      map['government_holidays_off'] = Variable<bool>(
        governmentHolidaysOff.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('studentName: $studentName, ')
          ..write('collegeName: $collegeName, ')
          ..write('course: $course, ')
          ..write('branch: $branch, ')
          ..write('academicYearStartDate: $academicYearStartDate, ')
          ..write('academicYearEndDate: $academicYearEndDate, ')
          ..write('defaultAttendanceTarget: $defaultAttendanceTarget, ')
          ..write('themeMode: $themeMode, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('automaticLocalBackup: $automaticLocalBackup, ')
          ..write('classRemindersEnabled: $classRemindersEnabled, ')
          ..write('classReminderMinutesBefore: $classReminderMinutesBefore, ')
          ..write('sundayOff: $sundayOff, ')
          ..write('secondSaturdayOff: $secondSaturdayOff, ')
          ..write('governmentHolidaysOff: $governmentHolidaysOff')
          ..write(')'))
        .toString();
  }
}

class $SubjectNotesTable extends SubjectNotes
    with TableInfo<$SubjectNotesTable, SubjectNoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubjectNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<int> subjectId = GeneratedColumn<int>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES subjects (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _semesterIdMeta = const VerificationMeta(
    'semesterId',
  );
  @override
  late final GeneratedColumn<int> semesterId = GeneratedColumn<int>(
    'semester_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES semesters (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: currentUtcMilliseconds,
      ).withConverter<DateTime>($SubjectNotesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: currentUtcMilliseconds,
      ).withConverter<DateTime>($SubjectNotesTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    subjectId,
    semesterId,
    title,
    body,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subject_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubjectNoteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('semester_id')) {
      context.handle(
        _semesterIdMeta,
        semesterId.isAcceptableOrUnknown(data['semester_id']!, _semesterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubjectNoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubjectNoteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subject_id'],
      )!,
      semesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}semester_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAt: $SubjectNotesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $SubjectNotesTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $SubjectNotesTable createAlias(String alias) {
    return $SubjectNotesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class SubjectNoteRow extends DataClass implements Insertable<SubjectNoteRow> {
  final int id;
  final int subjectId;
  final int semesterId;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SubjectNoteRow({
    required this.id,
    required this.subjectId,
    required this.semesterId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['subject_id'] = Variable<int>(subjectId);
    map['semester_id'] = Variable<int>(semesterId);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    {
      map['created_at'] = Variable<int>(
        $SubjectNotesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $SubjectNotesTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  SubjectNotesCompanion toCompanion(bool nullToAbsent) {
    return SubjectNotesCompanion(
      id: Value(id),
      subjectId: Value(subjectId),
      semesterId: Value(semesterId),
      title: Value(title),
      body: Value(body),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SubjectNoteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubjectNoteRow(
      id: serializer.fromJson<int>(json['id']),
      subjectId: serializer.fromJson<int>(json['subjectId']),
      semesterId: serializer.fromJson<int>(json['semesterId']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'subjectId': serializer.toJson<int>(subjectId),
      'semesterId': serializer.toJson<int>(semesterId),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SubjectNoteRow copyWith({
    int? id,
    int? subjectId,
    int? semesterId,
    String? title,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SubjectNoteRow(
    id: id ?? this.id,
    subjectId: subjectId ?? this.subjectId,
    semesterId: semesterId ?? this.semesterId,
    title: title ?? this.title,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SubjectNoteRow copyWithCompanion(SubjectNotesCompanion data) {
    return SubjectNoteRow(
      id: data.id.present ? data.id.value : this.id,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      semesterId: data.semesterId.present
          ? data.semesterId.value
          : this.semesterId,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubjectNoteRow(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('semesterId: $semesterId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, subjectId, semesterId, title, body, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubjectNoteRow &&
          other.id == this.id &&
          other.subjectId == this.subjectId &&
          other.semesterId == this.semesterId &&
          other.title == this.title &&
          other.body == this.body &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SubjectNotesCompanion extends UpdateCompanion<SubjectNoteRow> {
  final Value<int> id;
  final Value<int> subjectId;
  final Value<int> semesterId;
  final Value<String> title;
  final Value<String> body;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SubjectNotesCompanion({
    this.id = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.semesterId = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SubjectNotesCompanion.insert({
    this.id = const Value.absent(),
    required int subjectId,
    required int semesterId,
    this.title = const Value.absent(),
    required String body,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : subjectId = Value(subjectId),
       semesterId = Value(semesterId),
       body = Value(body);
  static Insertable<SubjectNoteRow> custom({
    Expression<int>? id,
    Expression<int>? subjectId,
    Expression<int>? semesterId,
    Expression<String>? title,
    Expression<String>? body,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subjectId != null) 'subject_id': subjectId,
      if (semesterId != null) 'semester_id': semesterId,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SubjectNotesCompanion copyWith({
    Value<int>? id,
    Value<int>? subjectId,
    Value<int>? semesterId,
    Value<String>? title,
    Value<String>? body,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SubjectNotesCompanion(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      semesterId: semesterId ?? this.semesterId,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<int>(subjectId.value);
    }
    if (semesterId.present) {
      map['semester_id'] = Variable<int>(semesterId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $SubjectNotesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $SubjectNotesTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectNotesCompanion(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('semesterId: $semesterId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SemestersTable semesters = $SemestersTable(this);
  late final $SubjectsTable subjects = $SubjectsTable(this);
  late final $SubjectFilesTable subjectFiles = $SubjectFilesTable(this);
  late final PdfSearchMetadata pdfSearchMetadata = PdfSearchMetadata(this);
  late final PdfPageFts pdfPageFts = PdfPageFts(this);
  late final Index subjectFilesSubjectCreated = Index(
    'subject_files_subject_created',
    'CREATE INDEX subject_files_subject_created ON subject_files (subject_id, created_at)',
  );
  late final Index subjectsSemesterArchivedName = Index(
    'subjects_semester_archived_name',
    'CREATE INDEX subjects_semester_archived_name ON subjects (semester_id, is_archived, name)',
  );
  late final Index semestersOneActive = Index(
    'semesters_one_active',
    'CREATE UNIQUE INDEX semesters_one_active ON semesters (is_active) WHERE is_active = 1',
  );
  late final Index semestersAcademicYearNumber = Index(
    'semesters_academic_year_number',
    'CREATE INDEX semesters_academic_year_number ON semesters (academic_year, semester_number)',
  );
  late final $TimetableEntriesTable timetableEntries = $TimetableEntriesTable(
    this,
  );
  late final $AttendanceSessionsTable attendanceSessions =
      $AttendanceSessionsTable(this);
  late final $DailyAttendanceRecordsTable dailyAttendanceRecords =
      $DailyAttendanceRecordsTable(this);
  late final $ScheduledClassAttendanceTable scheduledClassAttendance =
      $ScheduledClassAttendanceTable(this);
  late final $CalendarDayOverridesTable calendarDayOverrides =
      $CalendarDayOverridesTable(this);
  late final $AcademicCalendarEventsTable academicCalendarEvents =
      $AcademicCalendarEventsTable(this);
  late final $CollegeTasksTable collegeTasks = $CollegeTasksTable(this);
  late final $ExamsTable exams = $ExamsTable(this);
  late final $MarksTable marks = $MarksTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $SubjectNotesTable subjectNotes = $SubjectNotesTable(this);
  late final Index timetableSemesterWeekdayStart = Index(
    'timetable_semester_weekday_start',
    'CREATE INDEX timetable_semester_weekday_start ON timetable_entries (semester_id, weekday, start_time)',
  );
  late final Index timetableSubject = Index(
    'timetable_subject',
    'CREATE INDEX timetable_subject ON timetable_entries (subject_id)',
  );
  late final Index attendanceSubjectDatePeriod = Index(
    'attendance_subject_date_period',
    'CREATE INDEX attendance_subject_date_period ON attendance_sessions (subject_id, date, period)',
  );
  late final Index attendanceSubjectStatus = Index(
    'attendance_subject_status',
    'CREATE INDEX attendance_subject_status ON attendance_sessions (subject_id, status)',
  );
  late final Index dailyAttendanceStatus = Index(
    'daily_attendance_status',
    'CREATE INDEX daily_attendance_status ON daily_attendance_records (status)',
  );
  late final Index scheduledAttendanceDateTimetable = Index(
    'scheduled_attendance_date_timetable',
    'CREATE UNIQUE INDEX scheduled_attendance_date_timetable ON scheduled_class_attendance (date, timetable_entry_id)',
  );
  late final Index scheduledAttendanceSubjectDate = Index(
    'scheduled_attendance_subject_date',
    'CREATE INDEX scheduled_attendance_subject_date ON scheduled_class_attendance (subject_id, date)',
  );
  late final Index scheduledAttendanceSemesterDate = Index(
    'scheduled_attendance_semester_date',
    'CREATE INDEX scheduled_attendance_semester_date ON scheduled_class_attendance (semester_id, date)',
  );
  late final Index calendarOverrideSemesterDate = Index(
    'calendar_override_semester_date',
    'CREATE UNIQUE INDEX calendar_override_semester_date ON calendar_day_overrides (semester_id, date)',
  );
  late final Index academicCalendarSemesterDates = Index(
    'academic_calendar_semester_dates',
    'CREATE INDEX academic_calendar_semester_dates ON academic_calendar_events (semester_id, start_date, end_date)',
  );
  late final Index tasksSemesterCompletedDue = Index(
    'tasks_semester_completed_due',
    'CREATE INDEX tasks_semester_completed_due ON tasks (semester_id, is_completed, due_date)',
  );
  late final Index tasksSubjectCompleted = Index(
    'tasks_subject_completed',
    'CREATE INDEX tasks_subject_completed ON tasks (subject_id, is_completed)',
  );
  late final Index examsSemesterDateStart = Index(
    'exams_semester_date_start',
    'CREATE INDEX exams_semester_date_start ON exams (semester_id, exam_date, start_time)',
  );
  late final Index examsSubjectDate = Index(
    'exams_subject_date',
    'CREATE INDEX exams_subject_date ON exams (subject_id, exam_date)',
  );
  late final Index marksSubjectDate = Index(
    'marks_subject_date',
    'CREATE INDEX marks_subject_date ON marks (subject_id, date)',
  );
  late final Index marksExam = Index(
    'marks_exam',
    'CREATE INDEX marks_exam ON marks (exam_id)',
  );
  late final Index subjectNotesSubjectCreated = Index(
    'subject_notes_subject_created',
    'CREATE INDEX subject_notes_subject_created ON subject_notes (subject_id, created_at)',
  );
  late final SemestersDao semestersDao = SemestersDao(this as AppDatabase);
  late final SubjectsDao subjectsDao = SubjectsDao(this as AppDatabase);
  late final TimetableDao timetableDao = TimetableDao(this as AppDatabase);
  late final AttendanceDao attendanceDao = AttendanceDao(this as AppDatabase);
  late final DailyAttendanceDao dailyAttendanceDao = DailyAttendanceDao(
    this as AppDatabase,
  );
  late final AttendanceEngineDao attendanceEngineDao = AttendanceEngineDao(
    this as AppDatabase,
  );
  late final AcademicCalendarDao academicCalendarDao = AcademicCalendarDao(
    this as AppDatabase,
  );
  late final TasksDao tasksDao = TasksDao(this as AppDatabase);
  late final ExamsDao examsDao = ExamsDao(this as AppDatabase);
  late final MarksDao marksDao = MarksDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final SubjectNotesDao subjectNotesDao = SubjectNotesDao(
    this as AppDatabase,
  );
  late final SubjectFilesDao subjectFilesDao = SubjectFilesDao(
    this as AppDatabase,
  );
  late final PdfSearchDao pdfSearchDao = PdfSearchDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    semesters,
    subjects,
    subjectFiles,
    pdfSearchMetadata,
    pdfPageFts,
    subjectFilesSubjectCreated,
    subjectsSemesterArchivedName,
    semestersOneActive,
    semestersAcademicYearNumber,
    timetableEntries,
    attendanceSessions,
    dailyAttendanceRecords,
    scheduledClassAttendance,
    calendarDayOverrides,
    academicCalendarEvents,
    collegeTasks,
    exams,
    marks,
    appSettings,
    subjectNotes,
    timetableSemesterWeekdayStart,
    timetableSubject,
    attendanceSubjectDatePeriod,
    attendanceSubjectStatus,
    dailyAttendanceStatus,
    scheduledAttendanceDateTimetable,
    scheduledAttendanceSubjectDate,
    scheduledAttendanceSemesterDate,
    calendarOverrideSemesterDate,
    academicCalendarSemesterDates,
    tasksSemesterCompletedDue,
    tasksSubjectCompleted,
    examsSemesterDateStart,
    examsSubjectDate,
    marksSubjectDate,
    marksExam,
    subjectNotesSubjectCreated,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'semesters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('subjects', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'subjects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('subject_files', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'semesters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('subject_files', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'subject_files',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('pdf_search_metadata', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'semesters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('timetable_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'subjects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('attendance_sessions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'semesters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('scheduled_class_attendance', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'timetable_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('scheduled_class_attendance', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'subjects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('scheduled_class_attendance', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'semesters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('calendar_day_overrides', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'semesters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('academic_calendar_events', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'semesters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'semesters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('exams', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'subjects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('marks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'subjects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('subject_notes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'semesters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('subject_notes', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SemestersTableCreateCompanionBuilder =
    SemestersCompanion Function({
      Value<int> id,
      required String name,
      required int semesterNumber,
      required String academicYear,
      required DateTime startDate,
      required DateTime endDate,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$SemestersTableUpdateCompanionBuilder =
    SemestersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> semesterNumber,
      Value<String> academicYear,
      Value<DateTime> startDate,
      Value<DateTime> endDate,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$SemestersTableReferences
    extends BaseReferences<_$AppDatabase, $SemestersTable, SemesterRow> {
  $$SemestersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SubjectsTable, List<SubjectRow>>
  _subjectsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.subjects,
    aliasName: 'semesters__id__subjects__semester_id',
  );

  $$SubjectsTableProcessedTableManager get subjectsRefs {
    final manager = $$SubjectsTableTableManager(
      $_db,
      $_db.subjects,
    ).filter((f) => f.semesterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_subjectsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SubjectFilesTable, List<SubjectFileRow>>
  _subjectFilesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.subjectFiles,
    aliasName: 'semesters__id__subject_files__semester_id',
  );

  $$SubjectFilesTableProcessedTableManager get subjectFilesRefs {
    final manager = $$SubjectFilesTableTableManager(
      $_db,
      $_db.subjectFiles,
    ).filter((f) => f.semesterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_subjectFilesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TimetableEntriesTable, List<TimetableEntryRow>>
  _timetableEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.timetableEntries,
    aliasName: 'semesters__id__timetable_entries__semester_id',
  );

  $$TimetableEntriesTableProcessedTableManager get timetableEntriesRefs {
    final manager = $$TimetableEntriesTableTableManager(
      $_db,
      $_db.timetableEntries,
    ).filter((f) => f.semesterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _timetableEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ScheduledClassAttendanceTable,
    List<ScheduledClassAttendanceRow>
  >
  _scheduledClassAttendanceRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.scheduledClassAttendance,
        aliasName: 'semesters__id__scheduled_class_attendance__semester_id',
      );

  $$ScheduledClassAttendanceTableProcessedTableManager
  get scheduledClassAttendanceRefs {
    final manager = $$ScheduledClassAttendanceTableTableManager(
      $_db,
      $_db.scheduledClassAttendance,
    ).filter((f) => f.semesterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _scheduledClassAttendanceRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CalendarDayOverridesTable,
    List<CalendarDayOverrideRow>
  >
  _calendarDayOverridesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.calendarDayOverrides,
        aliasName: 'semesters__id__calendar_day_overrides__semester_id',
      );

  $$CalendarDayOverridesTableProcessedTableManager
  get calendarDayOverridesRefs {
    final manager = $$CalendarDayOverridesTableTableManager(
      $_db,
      $_db.calendarDayOverrides,
    ).filter((f) => f.semesterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _calendarDayOverridesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AcademicCalendarEventsTable,
    List<AcademicCalendarEventRow>
  >
  _academicCalendarEventsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.academicCalendarEvents,
        aliasName: 'semesters__id__academic_calendar_events__semester_id',
      );

  $$AcademicCalendarEventsTableProcessedTableManager
  get academicCalendarEventsRefs {
    final manager = $$AcademicCalendarEventsTableTableManager(
      $_db,
      $_db.academicCalendarEvents,
    ).filter((f) => f.semesterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _academicCalendarEventsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CollegeTasksTable, List<TaskRow>>
  _collegeTasksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.collegeTasks,
    aliasName: 'semesters__id__tasks__semester_id',
  );

  $$CollegeTasksTableProcessedTableManager get collegeTasksRefs {
    final manager = $$CollegeTasksTableTableManager(
      $_db,
      $_db.collegeTasks,
    ).filter((f) => f.semesterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_collegeTasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExamsTable, List<ExamRow>> _examsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.exams,
    aliasName: 'semesters__id__exams__semester_id',
  );

  $$ExamsTableProcessedTableManager get examsRefs {
    final manager = $$ExamsTableTableManager(
      $_db,
      $_db.exams,
    ).filter((f) => f.semesterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_examsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SubjectNotesTable, List<SubjectNoteRow>>
  _subjectNotesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.subjectNotes,
    aliasName: 'semesters__id__subject_notes__semester_id',
  );

  $$SubjectNotesTableProcessedTableManager get subjectNotesRefs {
    final manager = $$SubjectNotesTableTableManager(
      $_db,
      $_db.subjectNotes,
    ).filter((f) => f.semesterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_subjectNotesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SemestersTableFilterComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get semesterNumber => $composableBuilder(
    column: $table.semesterNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get academicYear => $composableBuilder(
    column: $table.academicYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get startDate =>
      $composableBuilder(
        column: $table.startDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get endDate =>
      $composableBuilder(
        column: $table.endDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  Expression<bool> subjectsRefs(
    Expression<bool> Function($$SubjectsTableFilterComposer f) f,
  ) {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.semesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableFilterComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> subjectFilesRefs(
    Expression<bool> Function($$SubjectFilesTableFilterComposer f) f,
  ) {
    final $$SubjectFilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subjectFiles,
      getReferencedColumn: (t) => t.semesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectFilesTableFilterComposer(
            $db: $db,
            $table: $db.subjectFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> timetableEntriesRefs(
    Expression<bool> Function($$TimetableEntriesTableFilterComposer f) f,
  ) {
    final $$TimetableEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timetableEntries,
      getReferencedColumn: (t) => t.semesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimetableEntriesTableFilterComposer(
            $db: $db,
            $table: $db.timetableEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> scheduledClassAttendanceRefs(
    Expression<bool> Function($$ScheduledClassAttendanceTableFilterComposer f)
    f,
  ) {
    final $$ScheduledClassAttendanceTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.scheduledClassAttendance,
          getReferencedColumn: (t) => t.semesterId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ScheduledClassAttendanceTableFilterComposer(
                $db: $db,
                $table: $db.scheduledClassAttendance,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> calendarDayOverridesRefs(
    Expression<bool> Function($$CalendarDayOverridesTableFilterComposer f) f,
  ) {
    final $$CalendarDayOverridesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.calendarDayOverrides,
      getReferencedColumn: (t) => t.semesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarDayOverridesTableFilterComposer(
            $db: $db,
            $table: $db.calendarDayOverrides,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> academicCalendarEventsRefs(
    Expression<bool> Function($$AcademicCalendarEventsTableFilterComposer f) f,
  ) {
    final $$AcademicCalendarEventsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.academicCalendarEvents,
          getReferencedColumn: (t) => t.semesterId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AcademicCalendarEventsTableFilterComposer(
                $db: $db,
                $table: $db.academicCalendarEvents,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> collegeTasksRefs(
    Expression<bool> Function($$CollegeTasksTableFilterComposer f) f,
  ) {
    final $$CollegeTasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collegeTasks,
      getReferencedColumn: (t) => t.semesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollegeTasksTableFilterComposer(
            $db: $db,
            $table: $db.collegeTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> examsRefs(
    Expression<bool> Function($$ExamsTableFilterComposer f) f,
  ) {
    final $$ExamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.semesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableFilterComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> subjectNotesRefs(
    Expression<bool> Function($$SubjectNotesTableFilterComposer f) f,
  ) {
    final $$SubjectNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subjectNotes,
      getReferencedColumn: (t) => t.semesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectNotesTableFilterComposer(
            $db: $db,
            $table: $db.subjectNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SemestersTableOrderingComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get semesterNumber => $composableBuilder(
    column: $table.semesterNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get academicYear => $composableBuilder(
    column: $table.academicYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SemestersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get semesterNumber => $composableBuilder(
    column: $table.semesterNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get academicYear => $composableBuilder(
    column: $table.academicYear,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> subjectsRefs<T extends Object>(
    Expression<T> Function($$SubjectsTableAnnotationComposer a) f,
  ) {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.semesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> subjectFilesRefs<T extends Object>(
    Expression<T> Function($$SubjectFilesTableAnnotationComposer a) f,
  ) {
    final $$SubjectFilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subjectFiles,
      getReferencedColumn: (t) => t.semesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectFilesTableAnnotationComposer(
            $db: $db,
            $table: $db.subjectFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> timetableEntriesRefs<T extends Object>(
    Expression<T> Function($$TimetableEntriesTableAnnotationComposer a) f,
  ) {
    final $$TimetableEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timetableEntries,
      getReferencedColumn: (t) => t.semesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimetableEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.timetableEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> scheduledClassAttendanceRefs<T extends Object>(
    Expression<T> Function($$ScheduledClassAttendanceTableAnnotationComposer a)
    f,
  ) {
    final $$ScheduledClassAttendanceTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.scheduledClassAttendance,
          getReferencedColumn: (t) => t.semesterId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ScheduledClassAttendanceTableAnnotationComposer(
                $db: $db,
                $table: $db.scheduledClassAttendance,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> calendarDayOverridesRefs<T extends Object>(
    Expression<T> Function($$CalendarDayOverridesTableAnnotationComposer a) f,
  ) {
    final $$CalendarDayOverridesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.calendarDayOverrides,
          getReferencedColumn: (t) => t.semesterId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CalendarDayOverridesTableAnnotationComposer(
                $db: $db,
                $table: $db.calendarDayOverrides,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> academicCalendarEventsRefs<T extends Object>(
    Expression<T> Function($$AcademicCalendarEventsTableAnnotationComposer a) f,
  ) {
    final $$AcademicCalendarEventsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.academicCalendarEvents,
          getReferencedColumn: (t) => t.semesterId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AcademicCalendarEventsTableAnnotationComposer(
                $db: $db,
                $table: $db.academicCalendarEvents,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> collegeTasksRefs<T extends Object>(
    Expression<T> Function($$CollegeTasksTableAnnotationComposer a) f,
  ) {
    final $$CollegeTasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collegeTasks,
      getReferencedColumn: (t) => t.semesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollegeTasksTableAnnotationComposer(
            $db: $db,
            $table: $db.collegeTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> examsRefs<T extends Object>(
    Expression<T> Function($$ExamsTableAnnotationComposer a) f,
  ) {
    final $$ExamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.semesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableAnnotationComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> subjectNotesRefs<T extends Object>(
    Expression<T> Function($$SubjectNotesTableAnnotationComposer a) f,
  ) {
    final $$SubjectNotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subjectNotes,
      getReferencedColumn: (t) => t.semesterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectNotesTableAnnotationComposer(
            $db: $db,
            $table: $db.subjectNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SemestersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SemestersTable,
          SemesterRow,
          $$SemestersTableFilterComposer,
          $$SemestersTableOrderingComposer,
          $$SemestersTableAnnotationComposer,
          $$SemestersTableCreateCompanionBuilder,
          $$SemestersTableUpdateCompanionBuilder,
          (SemesterRow, $$SemestersTableReferences),
          SemesterRow,
          PrefetchHooks Function({
            bool subjectsRefs,
            bool subjectFilesRefs,
            bool timetableEntriesRefs,
            bool scheduledClassAttendanceRefs,
            bool calendarDayOverridesRefs,
            bool academicCalendarEventsRefs,
            bool collegeTasksRefs,
            bool examsRefs,
            bool subjectNotesRefs,
          })
        > {
  $$SemestersTableTableManager(_$AppDatabase db, $SemestersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SemestersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SemestersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SemestersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> semesterNumber = const Value.absent(),
                Value<String> academicYear = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> endDate = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SemestersCompanion(
                id: id,
                name: name,
                semesterNumber: semesterNumber,
                academicYear: academicYear,
                startDate: startDate,
                endDate: endDate,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int semesterNumber,
                required String academicYear,
                required DateTime startDate,
                required DateTime endDate,
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SemestersCompanion.insert(
                id: id,
                name: name,
                semesterNumber: semesterNumber,
                academicYear: academicYear,
                startDate: startDate,
                endDate: endDate,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SemestersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                subjectsRefs = false,
                subjectFilesRefs = false,
                timetableEntriesRefs = false,
                scheduledClassAttendanceRefs = false,
                calendarDayOverridesRefs = false,
                academicCalendarEventsRefs = false,
                collegeTasksRefs = false,
                examsRefs = false,
                subjectNotesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (subjectsRefs) db.subjects,
                    if (subjectFilesRefs) db.subjectFiles,
                    if (timetableEntriesRefs) db.timetableEntries,
                    if (scheduledClassAttendanceRefs)
                      db.scheduledClassAttendance,
                    if (calendarDayOverridesRefs) db.calendarDayOverrides,
                    if (academicCalendarEventsRefs) db.academicCalendarEvents,
                    if (collegeTasksRefs) db.collegeTasks,
                    if (examsRefs) db.exams,
                    if (subjectNotesRefs) db.subjectNotes,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (subjectsRefs)
                        await $_getPrefetchedData<
                          SemesterRow,
                          $SemestersTable,
                          SubjectRow
                        >(
                          currentTable: table,
                          referencedTable: $$SemestersTableReferences
                              ._subjectsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SemestersTableReferences(
                                db,
                                table,
                                p0,
                              ).subjectsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.semesterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (subjectFilesRefs)
                        await $_getPrefetchedData<
                          SemesterRow,
                          $SemestersTable,
                          SubjectFileRow
                        >(
                          currentTable: table,
                          referencedTable: $$SemestersTableReferences
                              ._subjectFilesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SemestersTableReferences(
                                db,
                                table,
                                p0,
                              ).subjectFilesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.semesterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (timetableEntriesRefs)
                        await $_getPrefetchedData<
                          SemesterRow,
                          $SemestersTable,
                          TimetableEntryRow
                        >(
                          currentTable: table,
                          referencedTable: $$SemestersTableReferences
                              ._timetableEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SemestersTableReferences(
                                db,
                                table,
                                p0,
                              ).timetableEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.semesterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (scheduledClassAttendanceRefs)
                        await $_getPrefetchedData<
                          SemesterRow,
                          $SemestersTable,
                          ScheduledClassAttendanceRow
                        >(
                          currentTable: table,
                          referencedTable: $$SemestersTableReferences
                              ._scheduledClassAttendanceRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SemestersTableReferences(
                                db,
                                table,
                                p0,
                              ).scheduledClassAttendanceRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.semesterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (calendarDayOverridesRefs)
                        await $_getPrefetchedData<
                          SemesterRow,
                          $SemestersTable,
                          CalendarDayOverrideRow
                        >(
                          currentTable: table,
                          referencedTable: $$SemestersTableReferences
                              ._calendarDayOverridesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SemestersTableReferences(
                                db,
                                table,
                                p0,
                              ).calendarDayOverridesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.semesterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (academicCalendarEventsRefs)
                        await $_getPrefetchedData<
                          SemesterRow,
                          $SemestersTable,
                          AcademicCalendarEventRow
                        >(
                          currentTable: table,
                          referencedTable: $$SemestersTableReferences
                              ._academicCalendarEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SemestersTableReferences(
                                db,
                                table,
                                p0,
                              ).academicCalendarEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.semesterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (collegeTasksRefs)
                        await $_getPrefetchedData<
                          SemesterRow,
                          $SemestersTable,
                          TaskRow
                        >(
                          currentTable: table,
                          referencedTable: $$SemestersTableReferences
                              ._collegeTasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SemestersTableReferences(
                                db,
                                table,
                                p0,
                              ).collegeTasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.semesterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (examsRefs)
                        await $_getPrefetchedData<
                          SemesterRow,
                          $SemestersTable,
                          ExamRow
                        >(
                          currentTable: table,
                          referencedTable: $$SemestersTableReferences
                              ._examsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SemestersTableReferences(
                                db,
                                table,
                                p0,
                              ).examsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.semesterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (subjectNotesRefs)
                        await $_getPrefetchedData<
                          SemesterRow,
                          $SemestersTable,
                          SubjectNoteRow
                        >(
                          currentTable: table,
                          referencedTable: $$SemestersTableReferences
                              ._subjectNotesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SemestersTableReferences(
                                db,
                                table,
                                p0,
                              ).subjectNotesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.semesterId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SemestersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SemestersTable,
      SemesterRow,
      $$SemestersTableFilterComposer,
      $$SemestersTableOrderingComposer,
      $$SemestersTableAnnotationComposer,
      $$SemestersTableCreateCompanionBuilder,
      $$SemestersTableUpdateCompanionBuilder,
      (SemesterRow, $$SemestersTableReferences),
      SemesterRow,
      PrefetchHooks Function({
        bool subjectsRefs,
        bool subjectFilesRefs,
        bool timetableEntriesRefs,
        bool scheduledClassAttendanceRefs,
        bool calendarDayOverridesRefs,
        bool academicCalendarEventsRefs,
        bool collegeTasksRefs,
        bool examsRefs,
        bool subjectNotesRefs,
      })
    >;
typedef $$SubjectsTableCreateCompanionBuilder =
    SubjectsCompanion Function({
      Value<int> id,
      required int semesterId,
      required String name,
      Value<String> shortCode,
      Value<String> professor,
      Value<String> room,
      Value<double> attendanceTarget,
      required int displayColor,
      Value<bool> isArchived,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$SubjectsTableUpdateCompanionBuilder =
    SubjectsCompanion Function({
      Value<int> id,
      Value<int> semesterId,
      Value<String> name,
      Value<String> shortCode,
      Value<String> professor,
      Value<String> room,
      Value<double> attendanceTarget,
      Value<int> displayColor,
      Value<bool> isArchived,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$SubjectsTableReferences
    extends BaseReferences<_$AppDatabase, $SubjectsTable, SubjectRow> {
  $$SubjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SemestersTable _semesterIdTable(_$AppDatabase db) =>
      db.semesters.createAlias('subjects__semester_id__semesters__id');

  $$SemestersTableProcessedTableManager get semesterId {
    final $_column = $_itemColumn<int>('semester_id')!;

    final manager = $$SemestersTableTableManager(
      $_db,
      $_db.semesters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_semesterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SubjectFilesTable, List<SubjectFileRow>>
  _subjectFilesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.subjectFiles,
    aliasName: 'subjects__id__subject_files__subject_id',
  );

  $$SubjectFilesTableProcessedTableManager get subjectFilesRefs {
    final manager = $$SubjectFilesTableTableManager(
      $_db,
      $_db.subjectFiles,
    ).filter((f) => f.subjectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_subjectFilesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AttendanceSessionsTable,
    List<AttendanceSessionRow>
  >
  _attendanceSessionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.attendanceSessions,
        aliasName: 'subjects__id__attendance_sessions__subject_id',
      );

  $$AttendanceSessionsTableProcessedTableManager get attendanceSessionsRefs {
    final manager = $$AttendanceSessionsTableTableManager(
      $_db,
      $_db.attendanceSessions,
    ).filter((f) => f.subjectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _attendanceSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ScheduledClassAttendanceTable,
    List<ScheduledClassAttendanceRow>
  >
  _scheduledClassAttendanceRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.scheduledClassAttendance,
        aliasName: 'subjects__id__scheduled_class_attendance__subject_id',
      );

  $$ScheduledClassAttendanceTableProcessedTableManager
  get scheduledClassAttendanceRefs {
    final manager = $$ScheduledClassAttendanceTableTableManager(
      $_db,
      $_db.scheduledClassAttendance,
    ).filter((f) => f.subjectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _scheduledClassAttendanceRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MarksTable, List<MarkRow>> _marksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.marks,
    aliasName: 'subjects__id__marks__subject_id',
  );

  $$MarksTableProcessedTableManager get marksRefs {
    final manager = $$MarksTableTableManager(
      $_db,
      $_db.marks,
    ).filter((f) => f.subjectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_marksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SubjectNotesTable, List<SubjectNoteRow>>
  _subjectNotesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.subjectNotes,
    aliasName: 'subjects__id__subject_notes__subject_id',
  );

  $$SubjectNotesTableProcessedTableManager get subjectNotesRefs {
    final manager = $$SubjectNotesTableTableManager(
      $_db,
      $_db.subjectNotes,
    ).filter((f) => f.subjectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_subjectNotesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SubjectsTableFilterComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shortCode => $composableBuilder(
    column: $table.shortCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get professor => $composableBuilder(
    column: $table.professor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get room => $composableBuilder(
    column: $table.room,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get attendanceTarget => $composableBuilder(
    column: $table.attendanceTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayColor => $composableBuilder(
    column: $table.displayColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$SemestersTableFilterComposer get semesterId {
    final $$SemestersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableFilterComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> subjectFilesRefs(
    Expression<bool> Function($$SubjectFilesTableFilterComposer f) f,
  ) {
    final $$SubjectFilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subjectFiles,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectFilesTableFilterComposer(
            $db: $db,
            $table: $db.subjectFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> attendanceSessionsRefs(
    Expression<bool> Function($$AttendanceSessionsTableFilterComposer f) f,
  ) {
    final $$AttendanceSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attendanceSessions,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttendanceSessionsTableFilterComposer(
            $db: $db,
            $table: $db.attendanceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> scheduledClassAttendanceRefs(
    Expression<bool> Function($$ScheduledClassAttendanceTableFilterComposer f)
    f,
  ) {
    final $$ScheduledClassAttendanceTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.scheduledClassAttendance,
          getReferencedColumn: (t) => t.subjectId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ScheduledClassAttendanceTableFilterComposer(
                $db: $db,
                $table: $db.scheduledClassAttendance,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> marksRefs(
    Expression<bool> Function($$MarksTableFilterComposer f) f,
  ) {
    final $$MarksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.marks,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MarksTableFilterComposer(
            $db: $db,
            $table: $db.marks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> subjectNotesRefs(
    Expression<bool> Function($$SubjectNotesTableFilterComposer f) f,
  ) {
    final $$SubjectNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subjectNotes,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectNotesTableFilterComposer(
            $db: $db,
            $table: $db.subjectNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SubjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shortCode => $composableBuilder(
    column: $table.shortCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get professor => $composableBuilder(
    column: $table.professor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get room => $composableBuilder(
    column: $table.room,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get attendanceTarget => $composableBuilder(
    column: $table.attendanceTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayColor => $composableBuilder(
    column: $table.displayColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SemestersTableOrderingComposer get semesterId {
    final $$SemestersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableOrderingComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get shortCode =>
      $composableBuilder(column: $table.shortCode, builder: (column) => column);

  GeneratedColumn<String> get professor =>
      $composableBuilder(column: $table.professor, builder: (column) => column);

  GeneratedColumn<String> get room =>
      $composableBuilder(column: $table.room, builder: (column) => column);

  GeneratedColumn<double> get attendanceTarget => $composableBuilder(
    column: $table.attendanceTarget,
    builder: (column) => column,
  );

  GeneratedColumn<int> get displayColor => $composableBuilder(
    column: $table.displayColor,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SemestersTableAnnotationComposer get semesterId {
    final $$SemestersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableAnnotationComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> subjectFilesRefs<T extends Object>(
    Expression<T> Function($$SubjectFilesTableAnnotationComposer a) f,
  ) {
    final $$SubjectFilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subjectFiles,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectFilesTableAnnotationComposer(
            $db: $db,
            $table: $db.subjectFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> attendanceSessionsRefs<T extends Object>(
    Expression<T> Function($$AttendanceSessionsTableAnnotationComposer a) f,
  ) {
    final $$AttendanceSessionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.attendanceSessions,
          getReferencedColumn: (t) => t.subjectId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AttendanceSessionsTableAnnotationComposer(
                $db: $db,
                $table: $db.attendanceSessions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> scheduledClassAttendanceRefs<T extends Object>(
    Expression<T> Function($$ScheduledClassAttendanceTableAnnotationComposer a)
    f,
  ) {
    final $$ScheduledClassAttendanceTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.scheduledClassAttendance,
          getReferencedColumn: (t) => t.subjectId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ScheduledClassAttendanceTableAnnotationComposer(
                $db: $db,
                $table: $db.scheduledClassAttendance,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> marksRefs<T extends Object>(
    Expression<T> Function($$MarksTableAnnotationComposer a) f,
  ) {
    final $$MarksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.marks,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MarksTableAnnotationComposer(
            $db: $db,
            $table: $db.marks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> subjectNotesRefs<T extends Object>(
    Expression<T> Function($$SubjectNotesTableAnnotationComposer a) f,
  ) {
    final $$SubjectNotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subjectNotes,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectNotesTableAnnotationComposer(
            $db: $db,
            $table: $db.subjectNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SubjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubjectsTable,
          SubjectRow,
          $$SubjectsTableFilterComposer,
          $$SubjectsTableOrderingComposer,
          $$SubjectsTableAnnotationComposer,
          $$SubjectsTableCreateCompanionBuilder,
          $$SubjectsTableUpdateCompanionBuilder,
          (SubjectRow, $$SubjectsTableReferences),
          SubjectRow,
          PrefetchHooks Function({
            bool semesterId,
            bool subjectFilesRefs,
            bool attendanceSessionsRefs,
            bool scheduledClassAttendanceRefs,
            bool marksRefs,
            bool subjectNotesRefs,
          })
        > {
  $$SubjectsTableTableManager(_$AppDatabase db, $SubjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> semesterId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> shortCode = const Value.absent(),
                Value<String> professor = const Value.absent(),
                Value<String> room = const Value.absent(),
                Value<double> attendanceTarget = const Value.absent(),
                Value<int> displayColor = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SubjectsCompanion(
                id: id,
                semesterId: semesterId,
                name: name,
                shortCode: shortCode,
                professor: professor,
                room: room,
                attendanceTarget: attendanceTarget,
                displayColor: displayColor,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int semesterId,
                required String name,
                Value<String> shortCode = const Value.absent(),
                Value<String> professor = const Value.absent(),
                Value<String> room = const Value.absent(),
                Value<double> attendanceTarget = const Value.absent(),
                required int displayColor,
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SubjectsCompanion.insert(
                id: id,
                semesterId: semesterId,
                name: name,
                shortCode: shortCode,
                professor: professor,
                room: room,
                attendanceTarget: attendanceTarget,
                displayColor: displayColor,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SubjectsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                semesterId = false,
                subjectFilesRefs = false,
                attendanceSessionsRefs = false,
                scheduledClassAttendanceRefs = false,
                marksRefs = false,
                subjectNotesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (subjectFilesRefs) db.subjectFiles,
                    if (attendanceSessionsRefs) db.attendanceSessions,
                    if (scheduledClassAttendanceRefs)
                      db.scheduledClassAttendance,
                    if (marksRefs) db.marks,
                    if (subjectNotesRefs) db.subjectNotes,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (semesterId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.semesterId,
                                    referencedTable: $$SubjectsTableReferences
                                        ._semesterIdTable(db),
                                    referencedColumn: $$SubjectsTableReferences
                                        ._semesterIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (subjectFilesRefs)
                        await $_getPrefetchedData<
                          SubjectRow,
                          $SubjectsTable,
                          SubjectFileRow
                        >(
                          currentTable: table,
                          referencedTable: $$SubjectsTableReferences
                              ._subjectFilesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SubjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).subjectFilesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.subjectId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (attendanceSessionsRefs)
                        await $_getPrefetchedData<
                          SubjectRow,
                          $SubjectsTable,
                          AttendanceSessionRow
                        >(
                          currentTable: table,
                          referencedTable: $$SubjectsTableReferences
                              ._attendanceSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SubjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).attendanceSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.subjectId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (scheduledClassAttendanceRefs)
                        await $_getPrefetchedData<
                          SubjectRow,
                          $SubjectsTable,
                          ScheduledClassAttendanceRow
                        >(
                          currentTable: table,
                          referencedTable: $$SubjectsTableReferences
                              ._scheduledClassAttendanceRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SubjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).scheduledClassAttendanceRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.subjectId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (marksRefs)
                        await $_getPrefetchedData<
                          SubjectRow,
                          $SubjectsTable,
                          MarkRow
                        >(
                          currentTable: table,
                          referencedTable: $$SubjectsTableReferences
                              ._marksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SubjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).marksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.subjectId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (subjectNotesRefs)
                        await $_getPrefetchedData<
                          SubjectRow,
                          $SubjectsTable,
                          SubjectNoteRow
                        >(
                          currentTable: table,
                          referencedTable: $$SubjectsTableReferences
                              ._subjectNotesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SubjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).subjectNotesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.subjectId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SubjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubjectsTable,
      SubjectRow,
      $$SubjectsTableFilterComposer,
      $$SubjectsTableOrderingComposer,
      $$SubjectsTableAnnotationComposer,
      $$SubjectsTableCreateCompanionBuilder,
      $$SubjectsTableUpdateCompanionBuilder,
      (SubjectRow, $$SubjectsTableReferences),
      SubjectRow,
      PrefetchHooks Function({
        bool semesterId,
        bool subjectFilesRefs,
        bool attendanceSessionsRefs,
        bool scheduledClassAttendanceRefs,
        bool marksRefs,
        bool subjectNotesRefs,
      })
    >;
typedef $$SubjectFilesTableCreateCompanionBuilder =
    SubjectFilesCompanion Function({
      Value<int> id,
      required int subjectId,
      required int semesterId,
      Value<String> title,
      required String fileName,
      required String fileExtension,
      required int fileSizeBytes,
      Value<String> mimeType,
      required String relativeFilePath,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$SubjectFilesTableUpdateCompanionBuilder =
    SubjectFilesCompanion Function({
      Value<int> id,
      Value<int> subjectId,
      Value<int> semesterId,
      Value<String> title,
      Value<String> fileName,
      Value<String> fileExtension,
      Value<int> fileSizeBytes,
      Value<String> mimeType,
      Value<String> relativeFilePath,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$SubjectFilesTableReferences
    extends BaseReferences<_$AppDatabase, $SubjectFilesTable, SubjectFileRow> {
  $$SubjectFilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SubjectsTable _subjectIdTable(_$AppDatabase db) =>
      db.subjects.createAlias('subject_files__subject_id__subjects__id');

  $$SubjectsTableProcessedTableManager get subjectId {
    final $_column = $_itemColumn<int>('subject_id')!;

    final manager = $$SubjectsTableTableManager(
      $_db,
      $_db.subjects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SemestersTable _semesterIdTable(_$AppDatabase db) =>
      db.semesters.createAlias('subject_files__semester_id__semesters__id');

  $$SemestersTableProcessedTableManager get semesterId {
    final $_column = $_itemColumn<int>('semester_id')!;

    final manager = $$SemestersTableTableManager(
      $_db,
      $_db.semesters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_semesterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<PdfSearchMetadata, List<PdfSearchMetadataData>>
  _pdfSearchMetadataRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.pdfSearchMetadata,
        aliasName: 'subject_files__id__pdf_search_metadata__file_id',
      );

  $PdfSearchMetadataProcessedTableManager get pdfSearchMetadataRefs {
    final manager = $PdfSearchMetadataTableManager(
      $_db,
      $_db.pdfSearchMetadata,
    ).filter((f) => f.fileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _pdfSearchMetadataRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SubjectFilesTableFilterComposer
    extends Composer<_$AppDatabase, $SubjectFilesTable> {
  $$SubjectFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileExtension => $composableBuilder(
    column: $table.fileExtension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relativeFilePath => $composableBuilder(
    column: $table.relativeFilePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$SubjectsTableFilterComposer get subjectId {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableFilterComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SemestersTableFilterComposer get semesterId {
    final $$SemestersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableFilterComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> pdfSearchMetadataRefs(
    Expression<bool> Function($PdfSearchMetadataFilterComposer f) f,
  ) {
    final $PdfSearchMetadataFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pdfSearchMetadata,
      getReferencedColumn: (t) => t.fileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PdfSearchMetadataFilterComposer(
            $db: $db,
            $table: $db.pdfSearchMetadata,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SubjectFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $SubjectFilesTable> {
  $$SubjectFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileExtension => $composableBuilder(
    column: $table.fileExtension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relativeFilePath => $composableBuilder(
    column: $table.relativeFilePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SubjectsTableOrderingComposer get subjectId {
    final $$SubjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableOrderingComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SemestersTableOrderingComposer get semesterId {
    final $$SemestersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableOrderingComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubjectFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubjectFilesTable> {
  $$SubjectFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get fileExtension => $composableBuilder(
    column: $table.fileExtension,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<String> get relativeFilePath => $composableBuilder(
    column: $table.relativeFilePath,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SubjectsTableAnnotationComposer get subjectId {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SemestersTableAnnotationComposer get semesterId {
    final $$SemestersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableAnnotationComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> pdfSearchMetadataRefs<T extends Object>(
    Expression<T> Function($PdfSearchMetadataAnnotationComposer a) f,
  ) {
    final $PdfSearchMetadataAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pdfSearchMetadata,
      getReferencedColumn: (t) => t.fileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PdfSearchMetadataAnnotationComposer(
            $db: $db,
            $table: $db.pdfSearchMetadata,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SubjectFilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubjectFilesTable,
          SubjectFileRow,
          $$SubjectFilesTableFilterComposer,
          $$SubjectFilesTableOrderingComposer,
          $$SubjectFilesTableAnnotationComposer,
          $$SubjectFilesTableCreateCompanionBuilder,
          $$SubjectFilesTableUpdateCompanionBuilder,
          (SubjectFileRow, $$SubjectFilesTableReferences),
          SubjectFileRow,
          PrefetchHooks Function({
            bool subjectId,
            bool semesterId,
            bool pdfSearchMetadataRefs,
          })
        > {
  $$SubjectFilesTableTableManager(_$AppDatabase db, $SubjectFilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubjectFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubjectFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubjectFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> subjectId = const Value.absent(),
                Value<int> semesterId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> fileExtension = const Value.absent(),
                Value<int> fileSizeBytes = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<String> relativeFilePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SubjectFilesCompanion(
                id: id,
                subjectId: subjectId,
                semesterId: semesterId,
                title: title,
                fileName: fileName,
                fileExtension: fileExtension,
                fileSizeBytes: fileSizeBytes,
                mimeType: mimeType,
                relativeFilePath: relativeFilePath,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int subjectId,
                required int semesterId,
                Value<String> title = const Value.absent(),
                required String fileName,
                required String fileExtension,
                required int fileSizeBytes,
                Value<String> mimeType = const Value.absent(),
                required String relativeFilePath,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SubjectFilesCompanion.insert(
                id: id,
                subjectId: subjectId,
                semesterId: semesterId,
                title: title,
                fileName: fileName,
                fileExtension: fileExtension,
                fileSizeBytes: fileSizeBytes,
                mimeType: mimeType,
                relativeFilePath: relativeFilePath,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SubjectFilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                subjectId = false,
                semesterId = false,
                pdfSearchMetadataRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (pdfSearchMetadataRefs) db.pdfSearchMetadata,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (subjectId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.subjectId,
                                    referencedTable:
                                        $$SubjectFilesTableReferences
                                            ._subjectIdTable(db),
                                    referencedColumn:
                                        $$SubjectFilesTableReferences
                                            ._subjectIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (semesterId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.semesterId,
                                    referencedTable:
                                        $$SubjectFilesTableReferences
                                            ._semesterIdTable(db),
                                    referencedColumn:
                                        $$SubjectFilesTableReferences
                                            ._semesterIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (pdfSearchMetadataRefs)
                        await $_getPrefetchedData<
                          SubjectFileRow,
                          $SubjectFilesTable,
                          PdfSearchMetadataData
                        >(
                          currentTable: table,
                          referencedTable: $$SubjectFilesTableReferences
                              ._pdfSearchMetadataRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SubjectFilesTableReferences(
                                db,
                                table,
                                p0,
                              ).pdfSearchMetadataRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.fileId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SubjectFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubjectFilesTable,
      SubjectFileRow,
      $$SubjectFilesTableFilterComposer,
      $$SubjectFilesTableOrderingComposer,
      $$SubjectFilesTableAnnotationComposer,
      $$SubjectFilesTableCreateCompanionBuilder,
      $$SubjectFilesTableUpdateCompanionBuilder,
      (SubjectFileRow, $$SubjectFilesTableReferences),
      SubjectFileRow,
      PrefetchHooks Function({
        bool subjectId,
        bool semesterId,
        bool pdfSearchMetadataRefs,
      })
    >;
typedef $PdfSearchMetadataCreateCompanionBuilder =
    PdfSearchMetadataCompanion Function({
      Value<int> fileId,
      required String status,
      Value<int> pageCount,
      required int indexedAt,
      Value<int> lastIndexedPage,
    });
typedef $PdfSearchMetadataUpdateCompanionBuilder =
    PdfSearchMetadataCompanion Function({
      Value<int> fileId,
      Value<String> status,
      Value<int> pageCount,
      Value<int> indexedAt,
      Value<int> lastIndexedPage,
    });

final class $PdfSearchMetadataReferences
    extends
        BaseReferences<
          _$AppDatabase,
          PdfSearchMetadata,
          PdfSearchMetadataData
        > {
  $PdfSearchMetadataReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SubjectFilesTable _fileIdTable(_$AppDatabase db) => db.subjectFiles
      .createAlias('pdf_search_metadata__file_id__subject_files__id');

  $$SubjectFilesTableProcessedTableManager get fileId {
    final $_column = $_itemColumn<int>('file_id')!;

    final manager = $$SubjectFilesTableTableManager(
      $_db,
      $_db.subjectFiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $PdfSearchMetadataFilterComposer
    extends Composer<_$AppDatabase, PdfSearchMetadata> {
  $PdfSearchMetadataFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastIndexedPage => $composableBuilder(
    column: $table.lastIndexedPage,
    builder: (column) => ColumnFilters(column),
  );

  $$SubjectFilesTableFilterComposer get fileId {
    final $$SubjectFilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fileId,
      referencedTable: $db.subjectFiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectFilesTableFilterComposer(
            $db: $db,
            $table: $db.subjectFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PdfSearchMetadataOrderingComposer
    extends Composer<_$AppDatabase, PdfSearchMetadata> {
  $PdfSearchMetadataOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastIndexedPage => $composableBuilder(
    column: $table.lastIndexedPage,
    builder: (column) => ColumnOrderings(column),
  );

  $$SubjectFilesTableOrderingComposer get fileId {
    final $$SubjectFilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fileId,
      referencedTable: $db.subjectFiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectFilesTableOrderingComposer(
            $db: $db,
            $table: $db.subjectFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PdfSearchMetadataAnnotationComposer
    extends Composer<_$AppDatabase, PdfSearchMetadata> {
  $PdfSearchMetadataAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<int> get indexedAt =>
      $composableBuilder(column: $table.indexedAt, builder: (column) => column);

  GeneratedColumn<int> get lastIndexedPage => $composableBuilder(
    column: $table.lastIndexedPage,
    builder: (column) => column,
  );

  $$SubjectFilesTableAnnotationComposer get fileId {
    final $$SubjectFilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fileId,
      referencedTable: $db.subjectFiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectFilesTableAnnotationComposer(
            $db: $db,
            $table: $db.subjectFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PdfSearchMetadataTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          PdfSearchMetadata,
          PdfSearchMetadataData,
          $PdfSearchMetadataFilterComposer,
          $PdfSearchMetadataOrderingComposer,
          $PdfSearchMetadataAnnotationComposer,
          $PdfSearchMetadataCreateCompanionBuilder,
          $PdfSearchMetadataUpdateCompanionBuilder,
          (PdfSearchMetadataData, $PdfSearchMetadataReferences),
          PdfSearchMetadataData,
          PrefetchHooks Function({bool fileId})
        > {
  $PdfSearchMetadataTableManager(_$AppDatabase db, PdfSearchMetadata table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PdfSearchMetadataFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PdfSearchMetadataOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PdfSearchMetadataAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> fileId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
                Value<int> indexedAt = const Value.absent(),
                Value<int> lastIndexedPage = const Value.absent(),
              }) => PdfSearchMetadataCompanion(
                fileId: fileId,
                status: status,
                pageCount: pageCount,
                indexedAt: indexedAt,
                lastIndexedPage: lastIndexedPage,
              ),
          createCompanionCallback:
              ({
                Value<int> fileId = const Value.absent(),
                required String status,
                Value<int> pageCount = const Value.absent(),
                required int indexedAt,
                Value<int> lastIndexedPage = const Value.absent(),
              }) => PdfSearchMetadataCompanion.insert(
                fileId: fileId,
                status: status,
                pageCount: pageCount,
                indexedAt: indexedAt,
                lastIndexedPage: lastIndexedPage,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $PdfSearchMetadataReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({fileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (fileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.fileId,
                                referencedTable: $PdfSearchMetadataReferences
                                    ._fileIdTable(db),
                                referencedColumn: $PdfSearchMetadataReferences
                                    ._fileIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $PdfSearchMetadataProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      PdfSearchMetadata,
      PdfSearchMetadataData,
      $PdfSearchMetadataFilterComposer,
      $PdfSearchMetadataOrderingComposer,
      $PdfSearchMetadataAnnotationComposer,
      $PdfSearchMetadataCreateCompanionBuilder,
      $PdfSearchMetadataUpdateCompanionBuilder,
      (PdfSearchMetadataData, $PdfSearchMetadataReferences),
      PdfSearchMetadataData,
      PrefetchHooks Function({bool fileId})
    >;
typedef $PdfPageFtsCreateCompanionBuilder =
    PdfPageFtsCompanion Function({
      required String fileId,
      required String pageNumber,
      required String pageText,
      Value<int> rowid,
    });
typedef $PdfPageFtsUpdateCompanionBuilder =
    PdfPageFtsCompanion Function({
      Value<String> fileId,
      Value<String> pageNumber,
      Value<String> pageText,
      Value<int> rowid,
    });

class $PdfPageFtsFilterComposer extends Composer<_$AppDatabase, PdfPageFts> {
  $PdfPageFtsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pageText => $composableBuilder(
    column: $table.pageText,
    builder: (column) => ColumnFilters(column),
  );
}

class $PdfPageFtsOrderingComposer extends Composer<_$AppDatabase, PdfPageFts> {
  $PdfPageFtsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pageText => $composableBuilder(
    column: $table.pageText,
    builder: (column) => ColumnOrderings(column),
  );
}

class $PdfPageFtsAnnotationComposer
    extends Composer<_$AppDatabase, PdfPageFts> {
  $PdfPageFtsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<String> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pageText =>
      $composableBuilder(column: $table.pageText, builder: (column) => column);
}

class $PdfPageFtsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          PdfPageFts,
          PdfPageFt,
          $PdfPageFtsFilterComposer,
          $PdfPageFtsOrderingComposer,
          $PdfPageFtsAnnotationComposer,
          $PdfPageFtsCreateCompanionBuilder,
          $PdfPageFtsUpdateCompanionBuilder,
          (PdfPageFt, BaseReferences<_$AppDatabase, PdfPageFts, PdfPageFt>),
          PdfPageFt,
          PrefetchHooks Function()
        > {
  $PdfPageFtsTableManager(_$AppDatabase db, PdfPageFts table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PdfPageFtsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PdfPageFtsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PdfPageFtsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> fileId = const Value.absent(),
                Value<String> pageNumber = const Value.absent(),
                Value<String> pageText = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PdfPageFtsCompanion(
                fileId: fileId,
                pageNumber: pageNumber,
                pageText: pageText,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fileId,
                required String pageNumber,
                required String pageText,
                Value<int> rowid = const Value.absent(),
              }) => PdfPageFtsCompanion.insert(
                fileId: fileId,
                pageNumber: pageNumber,
                pageText: pageText,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $PdfPageFtsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      PdfPageFts,
      PdfPageFt,
      $PdfPageFtsFilterComposer,
      $PdfPageFtsOrderingComposer,
      $PdfPageFtsAnnotationComposer,
      $PdfPageFtsCreateCompanionBuilder,
      $PdfPageFtsUpdateCompanionBuilder,
      (PdfPageFt, BaseReferences<_$AppDatabase, PdfPageFts, PdfPageFt>),
      PdfPageFt,
      PrefetchHooks Function()
    >;
typedef $$TimetableEntriesTableCreateCompanionBuilder =
    TimetableEntriesCompanion Function({
      Value<int> id,
      required int semesterId,
      required int subjectId,
      required int weekday,
      required int startTime,
      required int endTime,
      Value<String> room,
      Value<String> note,
      Value<DateTime?> effectiveFrom,
      Value<DateTime?> effectiveUntil,
      Value<int?> reminderMinutesBefore,
    });
typedef $$TimetableEntriesTableUpdateCompanionBuilder =
    TimetableEntriesCompanion Function({
      Value<int> id,
      Value<int> semesterId,
      Value<int> subjectId,
      Value<int> weekday,
      Value<int> startTime,
      Value<int> endTime,
      Value<String> room,
      Value<String> note,
      Value<DateTime?> effectiveFrom,
      Value<DateTime?> effectiveUntil,
      Value<int?> reminderMinutesBefore,
    });

final class $$TimetableEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TimetableEntriesTable,
          TimetableEntryRow
        > {
  $$TimetableEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SemestersTable _semesterIdTable(_$AppDatabase db) =>
      db.semesters.createAlias('timetable_entries__semester_id__semesters__id');

  $$SemestersTableProcessedTableManager get semesterId {
    final $_column = $_itemColumn<int>('semester_id')!;

    final manager = $$SemestersTableTableManager(
      $_db,
      $_db.semesters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_semesterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ScheduledClassAttendanceTable,
    List<ScheduledClassAttendanceRow>
  >
  _scheduledClassAttendanceRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.scheduledClassAttendance,
    aliasName:
        'timetable_entries__id__scheduled_class_attendance__timetable_entry_id',
  );

  $$ScheduledClassAttendanceTableProcessedTableManager
  get scheduledClassAttendanceRefs {
    final manager = $$ScheduledClassAttendanceTableTableManager(
      $_db,
      $_db.scheduledClassAttendance,
    ).filter((f) => f.timetableEntryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _scheduledClassAttendanceRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TimetableEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $TimetableEntriesTable> {
  $$TimetableEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get room => $composableBuilder(
    column: $table.room,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get effectiveFrom =>
      $composableBuilder(
        column: $table.effectiveFrom,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get effectiveUntil =>
      $composableBuilder(
        column: $table.effectiveUntil,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get reminderMinutesBefore => $composableBuilder(
    column: $table.reminderMinutesBefore,
    builder: (column) => ColumnFilters(column),
  );

  $$SemestersTableFilterComposer get semesterId {
    final $$SemestersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableFilterComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> scheduledClassAttendanceRefs(
    Expression<bool> Function($$ScheduledClassAttendanceTableFilterComposer f)
    f,
  ) {
    final $$ScheduledClassAttendanceTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.scheduledClassAttendance,
          getReferencedColumn: (t) => t.timetableEntryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ScheduledClassAttendanceTableFilterComposer(
                $db: $db,
                $table: $db.scheduledClassAttendance,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TimetableEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TimetableEntriesTable> {
  $$TimetableEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get room => $composableBuilder(
    column: $table.room,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get effectiveUntil => $composableBuilder(
    column: $table.effectiveUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinutesBefore => $composableBuilder(
    column: $table.reminderMinutesBefore,
    builder: (column) => ColumnOrderings(column),
  );

  $$SemestersTableOrderingComposer get semesterId {
    final $$SemestersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableOrderingComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimetableEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimetableEntriesTable> {
  $$TimetableEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<int> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get room =>
      $composableBuilder(column: $table.room, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get effectiveFrom =>
      $composableBuilder(
        column: $table.effectiveFrom,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, int> get effectiveUntil =>
      $composableBuilder(
        column: $table.effectiveUntil,
        builder: (column) => column,
      );

  GeneratedColumn<int> get reminderMinutesBefore => $composableBuilder(
    column: $table.reminderMinutesBefore,
    builder: (column) => column,
  );

  $$SemestersTableAnnotationComposer get semesterId {
    final $$SemestersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableAnnotationComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> scheduledClassAttendanceRefs<T extends Object>(
    Expression<T> Function($$ScheduledClassAttendanceTableAnnotationComposer a)
    f,
  ) {
    final $$ScheduledClassAttendanceTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.scheduledClassAttendance,
          getReferencedColumn: (t) => t.timetableEntryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ScheduledClassAttendanceTableAnnotationComposer(
                $db: $db,
                $table: $db.scheduledClassAttendance,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TimetableEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimetableEntriesTable,
          TimetableEntryRow,
          $$TimetableEntriesTableFilterComposer,
          $$TimetableEntriesTableOrderingComposer,
          $$TimetableEntriesTableAnnotationComposer,
          $$TimetableEntriesTableCreateCompanionBuilder,
          $$TimetableEntriesTableUpdateCompanionBuilder,
          (TimetableEntryRow, $$TimetableEntriesTableReferences),
          TimetableEntryRow,
          PrefetchHooks Function({
            bool semesterId,
            bool scheduledClassAttendanceRefs,
          })
        > {
  $$TimetableEntriesTableTableManager(
    _$AppDatabase db,
    $TimetableEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimetableEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimetableEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimetableEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> semesterId = const Value.absent(),
                Value<int> subjectId = const Value.absent(),
                Value<int> weekday = const Value.absent(),
                Value<int> startTime = const Value.absent(),
                Value<int> endTime = const Value.absent(),
                Value<String> room = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime?> effectiveFrom = const Value.absent(),
                Value<DateTime?> effectiveUntil = const Value.absent(),
                Value<int?> reminderMinutesBefore = const Value.absent(),
              }) => TimetableEntriesCompanion(
                id: id,
                semesterId: semesterId,
                subjectId: subjectId,
                weekday: weekday,
                startTime: startTime,
                endTime: endTime,
                room: room,
                note: note,
                effectiveFrom: effectiveFrom,
                effectiveUntil: effectiveUntil,
                reminderMinutesBefore: reminderMinutesBefore,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int semesterId,
                required int subjectId,
                required int weekday,
                required int startTime,
                required int endTime,
                Value<String> room = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime?> effectiveFrom = const Value.absent(),
                Value<DateTime?> effectiveUntil = const Value.absent(),
                Value<int?> reminderMinutesBefore = const Value.absent(),
              }) => TimetableEntriesCompanion.insert(
                id: id,
                semesterId: semesterId,
                subjectId: subjectId,
                weekday: weekday,
                startTime: startTime,
                endTime: endTime,
                room: room,
                note: note,
                effectiveFrom: effectiveFrom,
                effectiveUntil: effectiveUntil,
                reminderMinutesBefore: reminderMinutesBefore,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TimetableEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({semesterId = false, scheduledClassAttendanceRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (scheduledClassAttendanceRefs)
                      db.scheduledClassAttendance,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (semesterId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.semesterId,
                                    referencedTable:
                                        $$TimetableEntriesTableReferences
                                            ._semesterIdTable(db),
                                    referencedColumn:
                                        $$TimetableEntriesTableReferences
                                            ._semesterIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (scheduledClassAttendanceRefs)
                        await $_getPrefetchedData<
                          TimetableEntryRow,
                          $TimetableEntriesTable,
                          ScheduledClassAttendanceRow
                        >(
                          currentTable: table,
                          referencedTable: $$TimetableEntriesTableReferences
                              ._scheduledClassAttendanceRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TimetableEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).scheduledClassAttendanceRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.timetableEntryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TimetableEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimetableEntriesTable,
      TimetableEntryRow,
      $$TimetableEntriesTableFilterComposer,
      $$TimetableEntriesTableOrderingComposer,
      $$TimetableEntriesTableAnnotationComposer,
      $$TimetableEntriesTableCreateCompanionBuilder,
      $$TimetableEntriesTableUpdateCompanionBuilder,
      (TimetableEntryRow, $$TimetableEntriesTableReferences),
      TimetableEntryRow,
      PrefetchHooks Function({
        bool semesterId,
        bool scheduledClassAttendanceRefs,
      })
    >;
typedef $$AttendanceSessionsTableCreateCompanionBuilder =
    AttendanceSessionsCompanion Function({
      Value<int> id,
      required int subjectId,
      required DateTime date,
      required int period,
      required AttendanceStatus status,
      Value<String> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$AttendanceSessionsTableUpdateCompanionBuilder =
    AttendanceSessionsCompanion Function({
      Value<int> id,
      Value<int> subjectId,
      Value<DateTime> date,
      Value<int> period,
      Value<AttendanceStatus> status,
      Value<String> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$AttendanceSessionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AttendanceSessionsTable,
          AttendanceSessionRow
        > {
  $$AttendanceSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SubjectsTable _subjectIdTable(_$AppDatabase db) =>
      db.subjects.createAlias('attendance_sessions__subject_id__subjects__id');

  $$SubjectsTableProcessedTableManager get subjectId {
    final $_column = $_itemColumn<int>('subject_id')!;

    final manager = $$SubjectsTableTableManager(
      $_db,
      $_db.subjects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttendanceSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $AttendanceSessionsTable> {
  $$AttendanceSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get date =>
      $composableBuilder(
        column: $table.date,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AttendanceStatus, AttendanceStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$SubjectsTableFilterComposer get subjectId {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableFilterComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttendanceSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendanceSessionsTable> {
  $$AttendanceSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SubjectsTableOrderingComposer get subjectId {
    final $$SubjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableOrderingComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttendanceSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendanceSessionsTable> {
  $$AttendanceSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AttendanceStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SubjectsTableAnnotationComposer get subjectId {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttendanceSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttendanceSessionsTable,
          AttendanceSessionRow,
          $$AttendanceSessionsTableFilterComposer,
          $$AttendanceSessionsTableOrderingComposer,
          $$AttendanceSessionsTableAnnotationComposer,
          $$AttendanceSessionsTableCreateCompanionBuilder,
          $$AttendanceSessionsTableUpdateCompanionBuilder,
          (AttendanceSessionRow, $$AttendanceSessionsTableReferences),
          AttendanceSessionRow,
          PrefetchHooks Function({bool subjectId})
        > {
  $$AttendanceSessionsTableTableManager(
    _$AppDatabase db,
    $AttendanceSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttendanceSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttendanceSessionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> subjectId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> period = const Value.absent(),
                Value<AttendanceStatus> status = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AttendanceSessionsCompanion(
                id: id,
                subjectId: subjectId,
                date: date,
                period: period,
                status: status,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int subjectId,
                required DateTime date,
                required int period,
                required AttendanceStatus status,
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AttendanceSessionsCompanion.insert(
                id: id,
                subjectId: subjectId,
                date: date,
                period: period,
                status: status,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AttendanceSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({subjectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (subjectId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.subjectId,
                                referencedTable:
                                    $$AttendanceSessionsTableReferences
                                        ._subjectIdTable(db),
                                referencedColumn:
                                    $$AttendanceSessionsTableReferences
                                        ._subjectIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AttendanceSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttendanceSessionsTable,
      AttendanceSessionRow,
      $$AttendanceSessionsTableFilterComposer,
      $$AttendanceSessionsTableOrderingComposer,
      $$AttendanceSessionsTableAnnotationComposer,
      $$AttendanceSessionsTableCreateCompanionBuilder,
      $$AttendanceSessionsTableUpdateCompanionBuilder,
      (AttendanceSessionRow, $$AttendanceSessionsTableReferences),
      AttendanceSessionRow,
      PrefetchHooks Function({bool subjectId})
    >;
typedef $$DailyAttendanceRecordsTableCreateCompanionBuilder =
    DailyAttendanceRecordsCompanion Function({
      Value<int> id,
      required DateTime date,
      required DailyAttendanceStatus status,
      Value<String> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$DailyAttendanceRecordsTableUpdateCompanionBuilder =
    DailyAttendanceRecordsCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<DailyAttendanceStatus> status,
      Value<String> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$DailyAttendanceRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyAttendanceRecordsTable> {
  $$DailyAttendanceRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get date =>
      $composableBuilder(
        column: $table.date,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<
    DailyAttendanceStatus,
    DailyAttendanceStatus,
    String
  >
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$DailyAttendanceRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyAttendanceRecordsTable> {
  $$DailyAttendanceRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyAttendanceRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyAttendanceRecordsTable> {
  $$DailyAttendanceRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DailyAttendanceStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DailyAttendanceRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyAttendanceRecordsTable,
          DailyAttendanceRecordRow,
          $$DailyAttendanceRecordsTableFilterComposer,
          $$DailyAttendanceRecordsTableOrderingComposer,
          $$DailyAttendanceRecordsTableAnnotationComposer,
          $$DailyAttendanceRecordsTableCreateCompanionBuilder,
          $$DailyAttendanceRecordsTableUpdateCompanionBuilder,
          (
            DailyAttendanceRecordRow,
            BaseReferences<
              _$AppDatabase,
              $DailyAttendanceRecordsTable,
              DailyAttendanceRecordRow
            >,
          ),
          DailyAttendanceRecordRow,
          PrefetchHooks Function()
        > {
  $$DailyAttendanceRecordsTableTableManager(
    _$AppDatabase db,
    $DailyAttendanceRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyAttendanceRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DailyAttendanceRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DailyAttendanceRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<DailyAttendanceStatus> status = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DailyAttendanceRecordsCompanion(
                id: id,
                date: date,
                status: status,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required DailyAttendanceStatus status,
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DailyAttendanceRecordsCompanion.insert(
                id: id,
                date: date,
                status: status,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyAttendanceRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyAttendanceRecordsTable,
      DailyAttendanceRecordRow,
      $$DailyAttendanceRecordsTableFilterComposer,
      $$DailyAttendanceRecordsTableOrderingComposer,
      $$DailyAttendanceRecordsTableAnnotationComposer,
      $$DailyAttendanceRecordsTableCreateCompanionBuilder,
      $$DailyAttendanceRecordsTableUpdateCompanionBuilder,
      (
        DailyAttendanceRecordRow,
        BaseReferences<
          _$AppDatabase,
          $DailyAttendanceRecordsTable,
          DailyAttendanceRecordRow
        >,
      ),
      DailyAttendanceRecordRow,
      PrefetchHooks Function()
    >;
typedef $$ScheduledClassAttendanceTableCreateCompanionBuilder =
    ScheduledClassAttendanceCompanion Function({
      Value<int> id,
      required int semesterId,
      Value<int?> timetableEntryId,
      required int subjectId,
      required DateTime date,
      required int startTime,
      required int endTime,
      required ClassAttendanceStatus attendanceStatus,
      Value<String> note,
      Value<bool> manuallyModified,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$ScheduledClassAttendanceTableUpdateCompanionBuilder =
    ScheduledClassAttendanceCompanion Function({
      Value<int> id,
      Value<int> semesterId,
      Value<int?> timetableEntryId,
      Value<int> subjectId,
      Value<DateTime> date,
      Value<int> startTime,
      Value<int> endTime,
      Value<ClassAttendanceStatus> attendanceStatus,
      Value<String> note,
      Value<bool> manuallyModified,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$ScheduledClassAttendanceTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ScheduledClassAttendanceTable,
          ScheduledClassAttendanceRow
        > {
  $$ScheduledClassAttendanceTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SemestersTable _semesterIdTable(_$AppDatabase db) => db.semesters
      .createAlias('scheduled_class_attendance__semester_id__semesters__id');

  $$SemestersTableProcessedTableManager get semesterId {
    final $_column = $_itemColumn<int>('semester_id')!;

    final manager = $$SemestersTableTableManager(
      $_db,
      $_db.semesters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_semesterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TimetableEntriesTable _timetableEntryIdTable(_$AppDatabase db) =>
      db.timetableEntries.createAlias(
        'scheduled_class_attendance__timetable_entry_id__timetable_entries__id',
      );

  $$TimetableEntriesTableProcessedTableManager? get timetableEntryId {
    final $_column = $_itemColumn<int>('timetable_entry_id');
    if ($_column == null) return null;
    final manager = $$TimetableEntriesTableTableManager(
      $_db,
      $_db.timetableEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_timetableEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SubjectsTable _subjectIdTable(_$AppDatabase db) => db.subjects
      .createAlias('scheduled_class_attendance__subject_id__subjects__id');

  $$SubjectsTableProcessedTableManager get subjectId {
    final $_column = $_itemColumn<int>('subject_id')!;

    final manager = $$SubjectsTableTableManager(
      $_db,
      $_db.subjects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ScheduledClassAttendanceTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduledClassAttendanceTable> {
  $$ScheduledClassAttendanceTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get date =>
      $composableBuilder(
        column: $table.date,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    ClassAttendanceStatus,
    ClassAttendanceStatus,
    String
  >
  get attendanceStatus => $composableBuilder(
    column: $table.attendanceStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get manuallyModified => $composableBuilder(
    column: $table.manuallyModified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$SemestersTableFilterComposer get semesterId {
    final $$SemestersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableFilterComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TimetableEntriesTableFilterComposer get timetableEntryId {
    final $$TimetableEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timetableEntryId,
      referencedTable: $db.timetableEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimetableEntriesTableFilterComposer(
            $db: $db,
            $table: $db.timetableEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SubjectsTableFilterComposer get subjectId {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableFilterComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScheduledClassAttendanceTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduledClassAttendanceTable> {
  $$ScheduledClassAttendanceTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attendanceStatus => $composableBuilder(
    column: $table.attendanceStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get manuallyModified => $composableBuilder(
    column: $table.manuallyModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SemestersTableOrderingComposer get semesterId {
    final $$SemestersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableOrderingComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TimetableEntriesTableOrderingComposer get timetableEntryId {
    final $$TimetableEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timetableEntryId,
      referencedTable: $db.timetableEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimetableEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.timetableEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SubjectsTableOrderingComposer get subjectId {
    final $$SubjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableOrderingComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScheduledClassAttendanceTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduledClassAttendanceTable> {
  $$ScheduledClassAttendanceTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ClassAttendanceStatus, String>
  get attendanceStatus => $composableBuilder(
    column: $table.attendanceStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get manuallyModified => $composableBuilder(
    column: $table.manuallyModified,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SemestersTableAnnotationComposer get semesterId {
    final $$SemestersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableAnnotationComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TimetableEntriesTableAnnotationComposer get timetableEntryId {
    final $$TimetableEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timetableEntryId,
      referencedTable: $db.timetableEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimetableEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.timetableEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SubjectsTableAnnotationComposer get subjectId {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScheduledClassAttendanceTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScheduledClassAttendanceTable,
          ScheduledClassAttendanceRow,
          $$ScheduledClassAttendanceTableFilterComposer,
          $$ScheduledClassAttendanceTableOrderingComposer,
          $$ScheduledClassAttendanceTableAnnotationComposer,
          $$ScheduledClassAttendanceTableCreateCompanionBuilder,
          $$ScheduledClassAttendanceTableUpdateCompanionBuilder,
          (
            ScheduledClassAttendanceRow,
            $$ScheduledClassAttendanceTableReferences,
          ),
          ScheduledClassAttendanceRow,
          PrefetchHooks Function({
            bool semesterId,
            bool timetableEntryId,
            bool subjectId,
          })
        > {
  $$ScheduledClassAttendanceTableTableManager(
    _$AppDatabase db,
    $ScheduledClassAttendanceTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduledClassAttendanceTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ScheduledClassAttendanceTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ScheduledClassAttendanceTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> semesterId = const Value.absent(),
                Value<int?> timetableEntryId = const Value.absent(),
                Value<int> subjectId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> startTime = const Value.absent(),
                Value<int> endTime = const Value.absent(),
                Value<ClassAttendanceStatus> attendanceStatus =
                    const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<bool> manuallyModified = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ScheduledClassAttendanceCompanion(
                id: id,
                semesterId: semesterId,
                timetableEntryId: timetableEntryId,
                subjectId: subjectId,
                date: date,
                startTime: startTime,
                endTime: endTime,
                attendanceStatus: attendanceStatus,
                note: note,
                manuallyModified: manuallyModified,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int semesterId,
                Value<int?> timetableEntryId = const Value.absent(),
                required int subjectId,
                required DateTime date,
                required int startTime,
                required int endTime,
                required ClassAttendanceStatus attendanceStatus,
                Value<String> note = const Value.absent(),
                Value<bool> manuallyModified = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ScheduledClassAttendanceCompanion.insert(
                id: id,
                semesterId: semesterId,
                timetableEntryId: timetableEntryId,
                subjectId: subjectId,
                date: date,
                startTime: startTime,
                endTime: endTime,
                attendanceStatus: attendanceStatus,
                note: note,
                manuallyModified: manuallyModified,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ScheduledClassAttendanceTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                semesterId = false,
                timetableEntryId = false,
                subjectId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (semesterId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.semesterId,
                                    referencedTable:
                                        $$ScheduledClassAttendanceTableReferences
                                            ._semesterIdTable(db),
                                    referencedColumn:
                                        $$ScheduledClassAttendanceTableReferences
                                            ._semesterIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (timetableEntryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.timetableEntryId,
                                    referencedTable:
                                        $$ScheduledClassAttendanceTableReferences
                                            ._timetableEntryIdTable(db),
                                    referencedColumn:
                                        $$ScheduledClassAttendanceTableReferences
                                            ._timetableEntryIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (subjectId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.subjectId,
                                    referencedTable:
                                        $$ScheduledClassAttendanceTableReferences
                                            ._subjectIdTable(db),
                                    referencedColumn:
                                        $$ScheduledClassAttendanceTableReferences
                                            ._subjectIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ScheduledClassAttendanceTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScheduledClassAttendanceTable,
      ScheduledClassAttendanceRow,
      $$ScheduledClassAttendanceTableFilterComposer,
      $$ScheduledClassAttendanceTableOrderingComposer,
      $$ScheduledClassAttendanceTableAnnotationComposer,
      $$ScheduledClassAttendanceTableCreateCompanionBuilder,
      $$ScheduledClassAttendanceTableUpdateCompanionBuilder,
      (ScheduledClassAttendanceRow, $$ScheduledClassAttendanceTableReferences),
      ScheduledClassAttendanceRow,
      PrefetchHooks Function({
        bool semesterId,
        bool timetableEntryId,
        bool subjectId,
      })
    >;
typedef $$CalendarDayOverridesTableCreateCompanionBuilder =
    CalendarDayOverridesCompanion Function({
      Value<int> id,
      required int semesterId,
      required DateTime date,
      required CalendarDayOverrideType type,
      Value<String> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$CalendarDayOverridesTableUpdateCompanionBuilder =
    CalendarDayOverridesCompanion Function({
      Value<int> id,
      Value<int> semesterId,
      Value<DateTime> date,
      Value<CalendarDayOverrideType> type,
      Value<String> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$CalendarDayOverridesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CalendarDayOverridesTable,
          CalendarDayOverrideRow
        > {
  $$CalendarDayOverridesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SemestersTable _semesterIdTable(_$AppDatabase db) => db.semesters
      .createAlias('calendar_day_overrides__semester_id__semesters__id');

  $$SemestersTableProcessedTableManager get semesterId {
    final $_column = $_itemColumn<int>('semester_id')!;

    final manager = $$SemestersTableTableManager(
      $_db,
      $_db.semesters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_semesterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CalendarDayOverridesTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarDayOverridesTable> {
  $$CalendarDayOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get date =>
      $composableBuilder(
        column: $table.date,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<
    CalendarDayOverrideType,
    CalendarDayOverrideType,
    String
  >
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$SemestersTableFilterComposer get semesterId {
    final $$SemestersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableFilterComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalendarDayOverridesTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarDayOverridesTable> {
  $$CalendarDayOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SemestersTableOrderingComposer get semesterId {
    final $$SemestersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableOrderingComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalendarDayOverridesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarDayOverridesTable> {
  $$CalendarDayOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CalendarDayOverrideType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SemestersTableAnnotationComposer get semesterId {
    final $$SemestersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableAnnotationComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalendarDayOverridesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalendarDayOverridesTable,
          CalendarDayOverrideRow,
          $$CalendarDayOverridesTableFilterComposer,
          $$CalendarDayOverridesTableOrderingComposer,
          $$CalendarDayOverridesTableAnnotationComposer,
          $$CalendarDayOverridesTableCreateCompanionBuilder,
          $$CalendarDayOverridesTableUpdateCompanionBuilder,
          (CalendarDayOverrideRow, $$CalendarDayOverridesTableReferences),
          CalendarDayOverrideRow,
          PrefetchHooks Function({bool semesterId})
        > {
  $$CalendarDayOverridesTableTableManager(
    _$AppDatabase db,
    $CalendarDayOverridesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarDayOverridesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarDayOverridesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CalendarDayOverridesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> semesterId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<CalendarDayOverrideType> type = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CalendarDayOverridesCompanion(
                id: id,
                semesterId: semesterId,
                date: date,
                type: type,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int semesterId,
                required DateTime date,
                required CalendarDayOverrideType type,
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CalendarDayOverridesCompanion.insert(
                id: id,
                semesterId: semesterId,
                date: date,
                type: type,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CalendarDayOverridesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({semesterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (semesterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.semesterId,
                                referencedTable:
                                    $$CalendarDayOverridesTableReferences
                                        ._semesterIdTable(db),
                                referencedColumn:
                                    $$CalendarDayOverridesTableReferences
                                        ._semesterIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CalendarDayOverridesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalendarDayOverridesTable,
      CalendarDayOverrideRow,
      $$CalendarDayOverridesTableFilterComposer,
      $$CalendarDayOverridesTableOrderingComposer,
      $$CalendarDayOverridesTableAnnotationComposer,
      $$CalendarDayOverridesTableCreateCompanionBuilder,
      $$CalendarDayOverridesTableUpdateCompanionBuilder,
      (CalendarDayOverrideRow, $$CalendarDayOverridesTableReferences),
      CalendarDayOverrideRow,
      PrefetchHooks Function({bool semesterId})
    >;
typedef $$AcademicCalendarEventsTableCreateCompanionBuilder =
    AcademicCalendarEventsCompanion Function({
      Value<int> id,
      required int semesterId,
      required String title,
      required AcademicCalendarEventType type,
      required DateTime startDate,
      required DateTime endDate,
      Value<String> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$AcademicCalendarEventsTableUpdateCompanionBuilder =
    AcademicCalendarEventsCompanion Function({
      Value<int> id,
      Value<int> semesterId,
      Value<String> title,
      Value<AcademicCalendarEventType> type,
      Value<DateTime> startDate,
      Value<DateTime> endDate,
      Value<String> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$AcademicCalendarEventsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AcademicCalendarEventsTable,
          AcademicCalendarEventRow
        > {
  $$AcademicCalendarEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SemestersTable _semesterIdTable(_$AppDatabase db) => db.semesters
      .createAlias('academic_calendar_events__semester_id__semesters__id');

  $$SemestersTableProcessedTableManager get semesterId {
    final $_column = $_itemColumn<int>('semester_id')!;

    final manager = $$SemestersTableTableManager(
      $_db,
      $_db.semesters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_semesterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AcademicCalendarEventsTableFilterComposer
    extends Composer<_$AppDatabase, $AcademicCalendarEventsTable> {
  $$AcademicCalendarEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    AcademicCalendarEventType,
    AcademicCalendarEventType,
    String
  >
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get startDate =>
      $composableBuilder(
        column: $table.startDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get endDate =>
      $composableBuilder(
        column: $table.endDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$SemestersTableFilterComposer get semesterId {
    final $$SemestersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableFilterComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AcademicCalendarEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $AcademicCalendarEventsTable> {
  $$AcademicCalendarEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SemestersTableOrderingComposer get semesterId {
    final $$SemestersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableOrderingComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AcademicCalendarEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AcademicCalendarEventsTable> {
  $$AcademicCalendarEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AcademicCalendarEventType, String>
  get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SemestersTableAnnotationComposer get semesterId {
    final $$SemestersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableAnnotationComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AcademicCalendarEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AcademicCalendarEventsTable,
          AcademicCalendarEventRow,
          $$AcademicCalendarEventsTableFilterComposer,
          $$AcademicCalendarEventsTableOrderingComposer,
          $$AcademicCalendarEventsTableAnnotationComposer,
          $$AcademicCalendarEventsTableCreateCompanionBuilder,
          $$AcademicCalendarEventsTableUpdateCompanionBuilder,
          (AcademicCalendarEventRow, $$AcademicCalendarEventsTableReferences),
          AcademicCalendarEventRow,
          PrefetchHooks Function({bool semesterId})
        > {
  $$AcademicCalendarEventsTableTableManager(
    _$AppDatabase db,
    $AcademicCalendarEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AcademicCalendarEventsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AcademicCalendarEventsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AcademicCalendarEventsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> semesterId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<AcademicCalendarEventType> type = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> endDate = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AcademicCalendarEventsCompanion(
                id: id,
                semesterId: semesterId,
                title: title,
                type: type,
                startDate: startDate,
                endDate: endDate,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int semesterId,
                required String title,
                required AcademicCalendarEventType type,
                required DateTime startDate,
                required DateTime endDate,
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AcademicCalendarEventsCompanion.insert(
                id: id,
                semesterId: semesterId,
                title: title,
                type: type,
                startDate: startDate,
                endDate: endDate,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AcademicCalendarEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({semesterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (semesterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.semesterId,
                                referencedTable:
                                    $$AcademicCalendarEventsTableReferences
                                        ._semesterIdTable(db),
                                referencedColumn:
                                    $$AcademicCalendarEventsTableReferences
                                        ._semesterIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AcademicCalendarEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AcademicCalendarEventsTable,
      AcademicCalendarEventRow,
      $$AcademicCalendarEventsTableFilterComposer,
      $$AcademicCalendarEventsTableOrderingComposer,
      $$AcademicCalendarEventsTableAnnotationComposer,
      $$AcademicCalendarEventsTableCreateCompanionBuilder,
      $$AcademicCalendarEventsTableUpdateCompanionBuilder,
      (AcademicCalendarEventRow, $$AcademicCalendarEventsTableReferences),
      AcademicCalendarEventRow,
      PrefetchHooks Function({bool semesterId})
    >;
typedef $$CollegeTasksTableCreateCompanionBuilder =
    CollegeTasksCompanion Function({
      Value<int> id,
      required int semesterId,
      Value<int?> subjectId,
      required String title,
      Value<String> description,
      required CollegeTaskType type,
      required TaskPriority priority,
      Value<DateTime?> dueDate,
      Value<int?> dueTime,
      Value<DateTime?> reminderAt,
      Value<bool> isCompleted,
      Value<DateTime?> completedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$CollegeTasksTableUpdateCompanionBuilder =
    CollegeTasksCompanion Function({
      Value<int> id,
      Value<int> semesterId,
      Value<int?> subjectId,
      Value<String> title,
      Value<String> description,
      Value<CollegeTaskType> type,
      Value<TaskPriority> priority,
      Value<DateTime?> dueDate,
      Value<int?> dueTime,
      Value<DateTime?> reminderAt,
      Value<bool> isCompleted,
      Value<DateTime?> completedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$CollegeTasksTableReferences
    extends BaseReferences<_$AppDatabase, $CollegeTasksTable, TaskRow> {
  $$CollegeTasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SemestersTable _semesterIdTable(_$AppDatabase db) =>
      db.semesters.createAlias('tasks__semester_id__semesters__id');

  $$SemestersTableProcessedTableManager get semesterId {
    final $_column = $_itemColumn<int>('semester_id')!;

    final manager = $$SemestersTableTableManager(
      $_db,
      $_db.semesters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_semesterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CollegeTasksTableFilterComposer
    extends Composer<_$AppDatabase, $CollegeTasksTable> {
  $$CollegeTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CollegeTaskType, CollegeTaskType, String>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskPriority, TaskPriority, String>
  get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get dueDate =>
      $composableBuilder(
        column: $table.dueDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get dueTime => $composableBuilder(
    column: $table.dueTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get reminderAt =>
      $composableBuilder(
        column: $table.reminderAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get completedAt =>
      $composableBuilder(
        column: $table.completedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$SemestersTableFilterComposer get semesterId {
    final $$SemestersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableFilterComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollegeTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $CollegeTasksTable> {
  $$CollegeTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueTime => $composableBuilder(
    column: $table.dueTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SemestersTableOrderingComposer get semesterId {
    final $$SemestersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableOrderingComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollegeTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollegeTasksTable> {
  $$CollegeTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<CollegeTaskType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskPriority, String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<int> get dueTime =>
      $composableBuilder(column: $table.dueTime, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get reminderAt =>
      $composableBuilder(
        column: $table.reminderAt,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get completedAt =>
      $composableBuilder(
        column: $table.completedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SemestersTableAnnotationComposer get semesterId {
    final $$SemestersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableAnnotationComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollegeTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollegeTasksTable,
          TaskRow,
          $$CollegeTasksTableFilterComposer,
          $$CollegeTasksTableOrderingComposer,
          $$CollegeTasksTableAnnotationComposer,
          $$CollegeTasksTableCreateCompanionBuilder,
          $$CollegeTasksTableUpdateCompanionBuilder,
          (TaskRow, $$CollegeTasksTableReferences),
          TaskRow,
          PrefetchHooks Function({bool semesterId})
        > {
  $$CollegeTasksTableTableManager(_$AppDatabase db, $CollegeTasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollegeTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollegeTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollegeTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> semesterId = const Value.absent(),
                Value<int?> subjectId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<CollegeTaskType> type = const Value.absent(),
                Value<TaskPriority> priority = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<int?> dueTime = const Value.absent(),
                Value<DateTime?> reminderAt = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CollegeTasksCompanion(
                id: id,
                semesterId: semesterId,
                subjectId: subjectId,
                title: title,
                description: description,
                type: type,
                priority: priority,
                dueDate: dueDate,
                dueTime: dueTime,
                reminderAt: reminderAt,
                isCompleted: isCompleted,
                completedAt: completedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int semesterId,
                Value<int?> subjectId = const Value.absent(),
                required String title,
                Value<String> description = const Value.absent(),
                required CollegeTaskType type,
                required TaskPriority priority,
                Value<DateTime?> dueDate = const Value.absent(),
                Value<int?> dueTime = const Value.absent(),
                Value<DateTime?> reminderAt = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CollegeTasksCompanion.insert(
                id: id,
                semesterId: semesterId,
                subjectId: subjectId,
                title: title,
                description: description,
                type: type,
                priority: priority,
                dueDate: dueDate,
                dueTime: dueTime,
                reminderAt: reminderAt,
                isCompleted: isCompleted,
                completedAt: completedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CollegeTasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({semesterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (semesterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.semesterId,
                                referencedTable: $$CollegeTasksTableReferences
                                    ._semesterIdTable(db),
                                referencedColumn: $$CollegeTasksTableReferences
                                    ._semesterIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CollegeTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollegeTasksTable,
      TaskRow,
      $$CollegeTasksTableFilterComposer,
      $$CollegeTasksTableOrderingComposer,
      $$CollegeTasksTableAnnotationComposer,
      $$CollegeTasksTableCreateCompanionBuilder,
      $$CollegeTasksTableUpdateCompanionBuilder,
      (TaskRow, $$CollegeTasksTableReferences),
      TaskRow,
      PrefetchHooks Function({bool semesterId})
    >;
typedef $$ExamsTableCreateCompanionBuilder =
    ExamsCompanion Function({
      Value<int> id,
      required int semesterId,
      required int subjectId,
      required String name,
      required String examType,
      required DateTime examDate,
      Value<int?> startTime,
      Value<int?> endTime,
      Value<String> room,
      Value<String> syllabus,
      Value<double?> maxMarks,
      Value<double?> obtainedMarks,
      Value<DateTime?> reminderAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$ExamsTableUpdateCompanionBuilder =
    ExamsCompanion Function({
      Value<int> id,
      Value<int> semesterId,
      Value<int> subjectId,
      Value<String> name,
      Value<String> examType,
      Value<DateTime> examDate,
      Value<int?> startTime,
      Value<int?> endTime,
      Value<String> room,
      Value<String> syllabus,
      Value<double?> maxMarks,
      Value<double?> obtainedMarks,
      Value<DateTime?> reminderAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$ExamsTableReferences
    extends BaseReferences<_$AppDatabase, $ExamsTable, ExamRow> {
  $$ExamsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SemestersTable _semesterIdTable(_$AppDatabase db) =>
      db.semesters.createAlias('exams__semester_id__semesters__id');

  $$SemestersTableProcessedTableManager get semesterId {
    final $_column = $_itemColumn<int>('semester_id')!;

    final manager = $$SemestersTableTableManager(
      $_db,
      $_db.semesters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_semesterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExamsTableFilterComposer extends Composer<_$AppDatabase, $ExamsTable> {
  $$ExamsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get examType => $composableBuilder(
    column: $table.examType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get examDate =>
      $composableBuilder(
        column: $table.examDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get room => $composableBuilder(
    column: $table.room,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syllabus => $composableBuilder(
    column: $table.syllabus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxMarks => $composableBuilder(
    column: $table.maxMarks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get obtainedMarks => $composableBuilder(
    column: $table.obtainedMarks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get reminderAt =>
      $composableBuilder(
        column: $table.reminderAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$SemestersTableFilterComposer get semesterId {
    final $$SemestersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableFilterComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExamsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExamsTable> {
  $$ExamsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get examType => $composableBuilder(
    column: $table.examType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get examDate => $composableBuilder(
    column: $table.examDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get room => $composableBuilder(
    column: $table.room,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syllabus => $composableBuilder(
    column: $table.syllabus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxMarks => $composableBuilder(
    column: $table.maxMarks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get obtainedMarks => $composableBuilder(
    column: $table.obtainedMarks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SemestersTableOrderingComposer get semesterId {
    final $$SemestersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableOrderingComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExamsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExamsTable> {
  $$ExamsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get examType =>
      $composableBuilder(column: $table.examType, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get examDate =>
      $composableBuilder(column: $table.examDate, builder: (column) => column);

  GeneratedColumn<int> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get room =>
      $composableBuilder(column: $table.room, builder: (column) => column);

  GeneratedColumn<String> get syllabus =>
      $composableBuilder(column: $table.syllabus, builder: (column) => column);

  GeneratedColumn<double> get maxMarks =>
      $composableBuilder(column: $table.maxMarks, builder: (column) => column);

  GeneratedColumn<double> get obtainedMarks => $composableBuilder(
    column: $table.obtainedMarks,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get reminderAt =>
      $composableBuilder(
        column: $table.reminderAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SemestersTableAnnotationComposer get semesterId {
    final $$SemestersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableAnnotationComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExamsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExamsTable,
          ExamRow,
          $$ExamsTableFilterComposer,
          $$ExamsTableOrderingComposer,
          $$ExamsTableAnnotationComposer,
          $$ExamsTableCreateCompanionBuilder,
          $$ExamsTableUpdateCompanionBuilder,
          (ExamRow, $$ExamsTableReferences),
          ExamRow,
          PrefetchHooks Function({bool semesterId})
        > {
  $$ExamsTableTableManager(_$AppDatabase db, $ExamsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExamsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExamsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExamsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> semesterId = const Value.absent(),
                Value<int> subjectId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> examType = const Value.absent(),
                Value<DateTime> examDate = const Value.absent(),
                Value<int?> startTime = const Value.absent(),
                Value<int?> endTime = const Value.absent(),
                Value<String> room = const Value.absent(),
                Value<String> syllabus = const Value.absent(),
                Value<double?> maxMarks = const Value.absent(),
                Value<double?> obtainedMarks = const Value.absent(),
                Value<DateTime?> reminderAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ExamsCompanion(
                id: id,
                semesterId: semesterId,
                subjectId: subjectId,
                name: name,
                examType: examType,
                examDate: examDate,
                startTime: startTime,
                endTime: endTime,
                room: room,
                syllabus: syllabus,
                maxMarks: maxMarks,
                obtainedMarks: obtainedMarks,
                reminderAt: reminderAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int semesterId,
                required int subjectId,
                required String name,
                required String examType,
                required DateTime examDate,
                Value<int?> startTime = const Value.absent(),
                Value<int?> endTime = const Value.absent(),
                Value<String> room = const Value.absent(),
                Value<String> syllabus = const Value.absent(),
                Value<double?> maxMarks = const Value.absent(),
                Value<double?> obtainedMarks = const Value.absent(),
                Value<DateTime?> reminderAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ExamsCompanion.insert(
                id: id,
                semesterId: semesterId,
                subjectId: subjectId,
                name: name,
                examType: examType,
                examDate: examDate,
                startTime: startTime,
                endTime: endTime,
                room: room,
                syllabus: syllabus,
                maxMarks: maxMarks,
                obtainedMarks: obtainedMarks,
                reminderAt: reminderAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ExamsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({semesterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (semesterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.semesterId,
                                referencedTable: $$ExamsTableReferences
                                    ._semesterIdTable(db),
                                referencedColumn: $$ExamsTableReferences
                                    ._semesterIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExamsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExamsTable,
      ExamRow,
      $$ExamsTableFilterComposer,
      $$ExamsTableOrderingComposer,
      $$ExamsTableAnnotationComposer,
      $$ExamsTableCreateCompanionBuilder,
      $$ExamsTableUpdateCompanionBuilder,
      (ExamRow, $$ExamsTableReferences),
      ExamRow,
      PrefetchHooks Function({bool semesterId})
    >;
typedef $$MarksTableCreateCompanionBuilder =
    MarksCompanion Function({
      Value<int> id,
      required int subjectId,
      Value<int?> examId,
      required String category,
      required double obtainedMarks,
      required double maxMarks,
      required DateTime date,
      Value<String> note,
    });
typedef $$MarksTableUpdateCompanionBuilder =
    MarksCompanion Function({
      Value<int> id,
      Value<int> subjectId,
      Value<int?> examId,
      Value<String> category,
      Value<double> obtainedMarks,
      Value<double> maxMarks,
      Value<DateTime> date,
      Value<String> note,
    });

final class $$MarksTableReferences
    extends BaseReferences<_$AppDatabase, $MarksTable, MarkRow> {
  $$MarksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SubjectsTable _subjectIdTable(_$AppDatabase db) =>
      db.subjects.createAlias('marks__subject_id__subjects__id');

  $$SubjectsTableProcessedTableManager get subjectId {
    final $_column = $_itemColumn<int>('subject_id')!;

    final manager = $$SubjectsTableTableManager(
      $_db,
      $_db.subjects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MarksTableFilterComposer extends Composer<_$AppDatabase, $MarksTable> {
  $$MarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get examId => $composableBuilder(
    column: $table.examId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get obtainedMarks => $composableBuilder(
    column: $table.obtainedMarks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxMarks => $composableBuilder(
    column: $table.maxMarks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get date =>
      $composableBuilder(
        column: $table.date,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$SubjectsTableFilterComposer get subjectId {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableFilterComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MarksTableOrderingComposer
    extends Composer<_$AppDatabase, $MarksTable> {
  $$MarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get examId => $composableBuilder(
    column: $table.examId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get obtainedMarks => $composableBuilder(
    column: $table.obtainedMarks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxMarks => $composableBuilder(
    column: $table.maxMarks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$SubjectsTableOrderingComposer get subjectId {
    final $$SubjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableOrderingComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $MarksTable> {
  $$MarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get examId =>
      $composableBuilder(column: $table.examId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get obtainedMarks => $composableBuilder(
    column: $table.obtainedMarks,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maxMarks =>
      $composableBuilder(column: $table.maxMarks, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$SubjectsTableAnnotationComposer get subjectId {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MarksTable,
          MarkRow,
          $$MarksTableFilterComposer,
          $$MarksTableOrderingComposer,
          $$MarksTableAnnotationComposer,
          $$MarksTableCreateCompanionBuilder,
          $$MarksTableUpdateCompanionBuilder,
          (MarkRow, $$MarksTableReferences),
          MarkRow,
          PrefetchHooks Function({bool subjectId})
        > {
  $$MarksTableTableManager(_$AppDatabase db, $MarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> subjectId = const Value.absent(),
                Value<int?> examId = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<double> obtainedMarks = const Value.absent(),
                Value<double> maxMarks = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => MarksCompanion(
                id: id,
                subjectId: subjectId,
                examId: examId,
                category: category,
                obtainedMarks: obtainedMarks,
                maxMarks: maxMarks,
                date: date,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int subjectId,
                Value<int?> examId = const Value.absent(),
                required String category,
                required double obtainedMarks,
                required double maxMarks,
                required DateTime date,
                Value<String> note = const Value.absent(),
              }) => MarksCompanion.insert(
                id: id,
                subjectId: subjectId,
                examId: examId,
                category: category,
                obtainedMarks: obtainedMarks,
                maxMarks: maxMarks,
                date: date,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$MarksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({subjectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (subjectId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.subjectId,
                                referencedTable: $$MarksTableReferences
                                    ._subjectIdTable(db),
                                referencedColumn: $$MarksTableReferences
                                    ._subjectIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MarksTable,
      MarkRow,
      $$MarksTableFilterComposer,
      $$MarksTableOrderingComposer,
      $$MarksTableAnnotationComposer,
      $$MarksTableCreateCompanionBuilder,
      $$MarksTableUpdateCompanionBuilder,
      (MarkRow, $$MarksTableReferences),
      MarkRow,
      PrefetchHooks Function({bool subjectId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> studentName,
      Value<String> collegeName,
      Value<String> course,
      Value<String> branch,
      Value<DateTime?> academicYearStartDate,
      Value<DateTime?> academicYearEndDate,
      Value<double> defaultAttendanceTarget,
      Value<CollegeThemeMode> themeMode,
      Value<bool> onboardingCompleted,
      Value<bool> notificationsEnabled,
      Value<bool> automaticLocalBackup,
      Value<bool> classRemindersEnabled,
      Value<int> classReminderMinutesBefore,
      Value<bool> sundayOff,
      Value<bool> secondSaturdayOff,
      Value<bool> governmentHolidaysOff,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> studentName,
      Value<String> collegeName,
      Value<String> course,
      Value<String> branch,
      Value<DateTime?> academicYearStartDate,
      Value<DateTime?> academicYearEndDate,
      Value<double> defaultAttendanceTarget,
      Value<CollegeThemeMode> themeMode,
      Value<bool> onboardingCompleted,
      Value<bool> notificationsEnabled,
      Value<bool> automaticLocalBackup,
      Value<bool> classRemindersEnabled,
      Value<int> classReminderMinutesBefore,
      Value<bool> sundayOff,
      Value<bool> secondSaturdayOff,
      Value<bool> governmentHolidaysOff,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studentName => $composableBuilder(
    column: $table.studentName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collegeName => $composableBuilder(
    column: $table.collegeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get course => $composableBuilder(
    column: $table.course,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branch => $composableBuilder(
    column: $table.branch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int>
  get academicYearStartDate => $composableBuilder(
    column: $table.academicYearStartDate,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int>
  get academicYearEndDate => $composableBuilder(
    column: $table.academicYearEndDate,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get defaultAttendanceTarget => $composableBuilder(
    column: $table.defaultAttendanceTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CollegeThemeMode, CollegeThemeMode, String>
  get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get automaticLocalBackup => $composableBuilder(
    column: $table.automaticLocalBackup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get classRemindersEnabled => $composableBuilder(
    column: $table.classRemindersEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get classReminderMinutesBefore => $composableBuilder(
    column: $table.classReminderMinutesBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sundayOff => $composableBuilder(
    column: $table.sundayOff,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get secondSaturdayOff => $composableBuilder(
    column: $table.secondSaturdayOff,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get governmentHolidaysOff => $composableBuilder(
    column: $table.governmentHolidaysOff,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studentName => $composableBuilder(
    column: $table.studentName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collegeName => $composableBuilder(
    column: $table.collegeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get course => $composableBuilder(
    column: $table.course,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branch => $composableBuilder(
    column: $table.branch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get academicYearStartDate => $composableBuilder(
    column: $table.academicYearStartDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get academicYearEndDate => $composableBuilder(
    column: $table.academicYearEndDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get defaultAttendanceTarget => $composableBuilder(
    column: $table.defaultAttendanceTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get automaticLocalBackup => $composableBuilder(
    column: $table.automaticLocalBackup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get classRemindersEnabled => $composableBuilder(
    column: $table.classRemindersEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get classReminderMinutesBefore => $composableBuilder(
    column: $table.classReminderMinutesBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sundayOff => $composableBuilder(
    column: $table.sundayOff,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get secondSaturdayOff => $composableBuilder(
    column: $table.secondSaturdayOff,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get governmentHolidaysOff => $composableBuilder(
    column: $table.governmentHolidaysOff,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get studentName => $composableBuilder(
    column: $table.studentName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get collegeName => $composableBuilder(
    column: $table.collegeName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get course =>
      $composableBuilder(column: $table.course, builder: (column) => column);

  GeneratedColumn<String> get branch =>
      $composableBuilder(column: $table.branch, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get academicYearStartDate =>
      $composableBuilder(
        column: $table.academicYearStartDate,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, int> get academicYearEndDate =>
      $composableBuilder(
        column: $table.academicYearEndDate,
        builder: (column) => column,
      );

  GeneratedColumn<double> get defaultAttendanceTarget => $composableBuilder(
    column: $table.defaultAttendanceTarget,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<CollegeThemeMode, String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get automaticLocalBackup => $composableBuilder(
    column: $table.automaticLocalBackup,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get classRemindersEnabled => $composableBuilder(
    column: $table.classRemindersEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get classReminderMinutesBefore => $composableBuilder(
    column: $table.classReminderMinutesBefore,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get sundayOff =>
      $composableBuilder(column: $table.sundayOff, builder: (column) => column);

  GeneratedColumn<bool> get secondSaturdayOff => $composableBuilder(
    column: $table.secondSaturdayOff,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get governmentHolidaysOff => $composableBuilder(
    column: $table.governmentHolidaysOff,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingsRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingsRow,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingsRow>,
          ),
          AppSettingsRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> studentName = const Value.absent(),
                Value<String> collegeName = const Value.absent(),
                Value<String> course = const Value.absent(),
                Value<String> branch = const Value.absent(),
                Value<DateTime?> academicYearStartDate = const Value.absent(),
                Value<DateTime?> academicYearEndDate = const Value.absent(),
                Value<double> defaultAttendanceTarget = const Value.absent(),
                Value<CollegeThemeMode> themeMode = const Value.absent(),
                Value<bool> onboardingCompleted = const Value.absent(),
                Value<bool> notificationsEnabled = const Value.absent(),
                Value<bool> automaticLocalBackup = const Value.absent(),
                Value<bool> classRemindersEnabled = const Value.absent(),
                Value<int> classReminderMinutesBefore = const Value.absent(),
                Value<bool> sundayOff = const Value.absent(),
                Value<bool> secondSaturdayOff = const Value.absent(),
                Value<bool> governmentHolidaysOff = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                studentName: studentName,
                collegeName: collegeName,
                course: course,
                branch: branch,
                academicYearStartDate: academicYearStartDate,
                academicYearEndDate: academicYearEndDate,
                defaultAttendanceTarget: defaultAttendanceTarget,
                themeMode: themeMode,
                onboardingCompleted: onboardingCompleted,
                notificationsEnabled: notificationsEnabled,
                automaticLocalBackup: automaticLocalBackup,
                classRemindersEnabled: classRemindersEnabled,
                classReminderMinutesBefore: classReminderMinutesBefore,
                sundayOff: sundayOff,
                secondSaturdayOff: secondSaturdayOff,
                governmentHolidaysOff: governmentHolidaysOff,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> studentName = const Value.absent(),
                Value<String> collegeName = const Value.absent(),
                Value<String> course = const Value.absent(),
                Value<String> branch = const Value.absent(),
                Value<DateTime?> academicYearStartDate = const Value.absent(),
                Value<DateTime?> academicYearEndDate = const Value.absent(),
                Value<double> defaultAttendanceTarget = const Value.absent(),
                Value<CollegeThemeMode> themeMode = const Value.absent(),
                Value<bool> onboardingCompleted = const Value.absent(),
                Value<bool> notificationsEnabled = const Value.absent(),
                Value<bool> automaticLocalBackup = const Value.absent(),
                Value<bool> classRemindersEnabled = const Value.absent(),
                Value<int> classReminderMinutesBefore = const Value.absent(),
                Value<bool> sundayOff = const Value.absent(),
                Value<bool> secondSaturdayOff = const Value.absent(),
                Value<bool> governmentHolidaysOff = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                studentName: studentName,
                collegeName: collegeName,
                course: course,
                branch: branch,
                academicYearStartDate: academicYearStartDate,
                academicYearEndDate: academicYearEndDate,
                defaultAttendanceTarget: defaultAttendanceTarget,
                themeMode: themeMode,
                onboardingCompleted: onboardingCompleted,
                notificationsEnabled: notificationsEnabled,
                automaticLocalBackup: automaticLocalBackup,
                classRemindersEnabled: classRemindersEnabled,
                classReminderMinutesBefore: classReminderMinutesBefore,
                sundayOff: sundayOff,
                secondSaturdayOff: secondSaturdayOff,
                governmentHolidaysOff: governmentHolidaysOff,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingsRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingsRow,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingsRow>,
      ),
      AppSettingsRow,
      PrefetchHooks Function()
    >;
typedef $$SubjectNotesTableCreateCompanionBuilder =
    SubjectNotesCompanion Function({
      Value<int> id,
      required int subjectId,
      required int semesterId,
      Value<String> title,
      required String body,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$SubjectNotesTableUpdateCompanionBuilder =
    SubjectNotesCompanion Function({
      Value<int> id,
      Value<int> subjectId,
      Value<int> semesterId,
      Value<String> title,
      Value<String> body,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$SubjectNotesTableReferences
    extends BaseReferences<_$AppDatabase, $SubjectNotesTable, SubjectNoteRow> {
  $$SubjectNotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SubjectsTable _subjectIdTable(_$AppDatabase db) =>
      db.subjects.createAlias('subject_notes__subject_id__subjects__id');

  $$SubjectsTableProcessedTableManager get subjectId {
    final $_column = $_itemColumn<int>('subject_id')!;

    final manager = $$SubjectsTableTableManager(
      $_db,
      $_db.subjects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SemestersTable _semesterIdTable(_$AppDatabase db) =>
      db.semesters.createAlias('subject_notes__semester_id__semesters__id');

  $$SemestersTableProcessedTableManager get semesterId {
    final $_column = $_itemColumn<int>('semester_id')!;

    final manager = $$SemestersTableTableManager(
      $_db,
      $_db.semesters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_semesterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SubjectNotesTableFilterComposer
    extends Composer<_$AppDatabase, $SubjectNotesTable> {
  $$SubjectNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$SubjectsTableFilterComposer get subjectId {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableFilterComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SemestersTableFilterComposer get semesterId {
    final $$SemestersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableFilterComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubjectNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $SubjectNotesTable> {
  $$SubjectNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SubjectsTableOrderingComposer get subjectId {
    final $$SubjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableOrderingComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SemestersTableOrderingComposer get semesterId {
    final $$SemestersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableOrderingComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubjectNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubjectNotesTable> {
  $$SubjectNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SubjectsTableAnnotationComposer get subjectId {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SemestersTableAnnotationComposer get semesterId {
    final $$SemestersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semesterId,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableAnnotationComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubjectNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubjectNotesTable,
          SubjectNoteRow,
          $$SubjectNotesTableFilterComposer,
          $$SubjectNotesTableOrderingComposer,
          $$SubjectNotesTableAnnotationComposer,
          $$SubjectNotesTableCreateCompanionBuilder,
          $$SubjectNotesTableUpdateCompanionBuilder,
          (SubjectNoteRow, $$SubjectNotesTableReferences),
          SubjectNoteRow,
          PrefetchHooks Function({bool subjectId, bool semesterId})
        > {
  $$SubjectNotesTableTableManager(_$AppDatabase db, $SubjectNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubjectNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubjectNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubjectNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> subjectId = const Value.absent(),
                Value<int> semesterId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SubjectNotesCompanion(
                id: id,
                subjectId: subjectId,
                semesterId: semesterId,
                title: title,
                body: body,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int subjectId,
                required int semesterId,
                Value<String> title = const Value.absent(),
                required String body,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SubjectNotesCompanion.insert(
                id: id,
                subjectId: subjectId,
                semesterId: semesterId,
                title: title,
                body: body,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SubjectNotesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({subjectId = false, semesterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (subjectId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.subjectId,
                                referencedTable: $$SubjectNotesTableReferences
                                    ._subjectIdTable(db),
                                referencedColumn: $$SubjectNotesTableReferences
                                    ._subjectIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (semesterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.semesterId,
                                referencedTable: $$SubjectNotesTableReferences
                                    ._semesterIdTable(db),
                                referencedColumn: $$SubjectNotesTableReferences
                                    ._semesterIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SubjectNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubjectNotesTable,
      SubjectNoteRow,
      $$SubjectNotesTableFilterComposer,
      $$SubjectNotesTableOrderingComposer,
      $$SubjectNotesTableAnnotationComposer,
      $$SubjectNotesTableCreateCompanionBuilder,
      $$SubjectNotesTableUpdateCompanionBuilder,
      (SubjectNoteRow, $$SubjectNotesTableReferences),
      SubjectNoteRow,
      PrefetchHooks Function({bool subjectId, bool semesterId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SemestersTableTableManager get semesters =>
      $$SemestersTableTableManager(_db, _db.semesters);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db, _db.subjects);
  $$SubjectFilesTableTableManager get subjectFiles =>
      $$SubjectFilesTableTableManager(_db, _db.subjectFiles);
  $PdfSearchMetadataTableManager get pdfSearchMetadata =>
      $PdfSearchMetadataTableManager(_db, _db.pdfSearchMetadata);
  $PdfPageFtsTableManager get pdfPageFts =>
      $PdfPageFtsTableManager(_db, _db.pdfPageFts);
  $$TimetableEntriesTableTableManager get timetableEntries =>
      $$TimetableEntriesTableTableManager(_db, _db.timetableEntries);
  $$AttendanceSessionsTableTableManager get attendanceSessions =>
      $$AttendanceSessionsTableTableManager(_db, _db.attendanceSessions);
  $$DailyAttendanceRecordsTableTableManager get dailyAttendanceRecords =>
      $$DailyAttendanceRecordsTableTableManager(
        _db,
        _db.dailyAttendanceRecords,
      );
  $$ScheduledClassAttendanceTableTableManager get scheduledClassAttendance =>
      $$ScheduledClassAttendanceTableTableManager(
        _db,
        _db.scheduledClassAttendance,
      );
  $$CalendarDayOverridesTableTableManager get calendarDayOverrides =>
      $$CalendarDayOverridesTableTableManager(_db, _db.calendarDayOverrides);
  $$AcademicCalendarEventsTableTableManager get academicCalendarEvents =>
      $$AcademicCalendarEventsTableTableManager(
        _db,
        _db.academicCalendarEvents,
      );
  $$CollegeTasksTableTableManager get collegeTasks =>
      $$CollegeTasksTableTableManager(_db, _db.collegeTasks);
  $$ExamsTableTableManager get exams =>
      $$ExamsTableTableManager(_db, _db.exams);
  $$MarksTableTableManager get marks =>
      $$MarksTableTableManager(_db, _db.marks);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$SubjectNotesTableTableManager get subjectNotes =>
      $$SubjectNotesTableTableManager(_db, _db.subjectNotes);
}
