// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $IncomeCategoriesTable extends IncomeCategories
    with TableInfo<$IncomeCategoriesTable, IncomeCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IncomeCategoriesTable(this.attachedDatabase, [this._alias]);
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
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'income_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<IncomeCategory> instance, {
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IncomeCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IncomeCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $IncomeCategoriesTable createAlias(String alias) {
    return $IncomeCategoriesTable(attachedDatabase, alias);
  }
}

class IncomeCategory extends DataClass implements Insertable<IncomeCategory> {
  final int id;
  final String name;
  const IncomeCategory({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  IncomeCategoriesCompanion toCompanion(bool nullToAbsent) {
    return IncomeCategoriesCompanion(id: Value(id), name: Value(name));
  }

  factory IncomeCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IncomeCategory(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  IncomeCategory copyWith({int? id, String? name}) =>
      IncomeCategory(id: id ?? this.id, name: name ?? this.name);
  IncomeCategory copyWithCompanion(IncomeCategoriesCompanion data) {
    return IncomeCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IncomeCategory(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IncomeCategory &&
          other.id == this.id &&
          other.name == this.name);
}

class IncomeCategoriesCompanion extends UpdateCompanion<IncomeCategory> {
  final Value<int> id;
  final Value<String> name;
  const IncomeCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  IncomeCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<IncomeCategory> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  IncomeCategoriesCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return IncomeCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IncomeCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $IncomeRecordsTable extends IncomeRecords
    with TableInfo<$IncomeRecordsTable, IncomeRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IncomeRecordsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _totalIncomeMeta = const VerificationMeta(
    'totalIncome',
  );
  @override
  late final GeneratedColumn<double> totalIncome = GeneratedColumn<double>(
    'total_income',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _epfAmountMeta = const VerificationMeta(
    'epfAmount',
  );
  @override
  late final GeneratedColumn<double> epfAmount = GeneratedColumn<double>(
    'epf_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _socsoAmountMeta = const VerificationMeta(
    'socsoAmount',
  );
  @override
  late final GeneratedColumn<double> socsoAmount = GeneratedColumn<double>(
    'socso_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pcbAmountMeta = const VerificationMeta(
    'pcbAmount',
  );
  @override
  late final GeneratedColumn<double> pcbAmount = GeneratedColumn<double>(
    'pcb_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _netIncomeMeta = const VerificationMeta(
    'netIncome',
  );
  @override
  late final GeneratedColumn<double> netIncome = GeneratedColumn<double>(
    'net_income',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _incomeDateMeta = const VerificationMeta(
    'incomeDate',
  );
  @override
  late final GeneratedColumn<DateTime> incomeDate = GeneratedColumn<DateTime>(
    'income_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proofImagePathMeta = const VerificationMeta(
    'proofImagePath',
  );
  @override
  late final GeneratedColumn<String> proofImagePath = GeneratedColumn<String>(
    'proof_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    totalIncome,
    epfAmount,
    socsoAmount,
    pcbAmount,
    netIncome,
    category,
    description,
    incomeDate,
    proofImagePath,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'income_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<IncomeRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('total_income')) {
      context.handle(
        _totalIncomeMeta,
        totalIncome.isAcceptableOrUnknown(
          data['total_income']!,
          _totalIncomeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalIncomeMeta);
    }
    if (data.containsKey('epf_amount')) {
      context.handle(
        _epfAmountMeta,
        epfAmount.isAcceptableOrUnknown(data['epf_amount']!, _epfAmountMeta),
      );
    } else if (isInserting) {
      context.missing(_epfAmountMeta);
    }
    if (data.containsKey('socso_amount')) {
      context.handle(
        _socsoAmountMeta,
        socsoAmount.isAcceptableOrUnknown(
          data['socso_amount']!,
          _socsoAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_socsoAmountMeta);
    }
    if (data.containsKey('pcb_amount')) {
      context.handle(
        _pcbAmountMeta,
        pcbAmount.isAcceptableOrUnknown(data['pcb_amount']!, _pcbAmountMeta),
      );
    } else if (isInserting) {
      context.missing(_pcbAmountMeta);
    }
    if (data.containsKey('net_income')) {
      context.handle(
        _netIncomeMeta,
        netIncome.isAcceptableOrUnknown(data['net_income']!, _netIncomeMeta),
      );
    } else if (isInserting) {
      context.missing(_netIncomeMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
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
    if (data.containsKey('income_date')) {
      context.handle(
        _incomeDateMeta,
        incomeDate.isAcceptableOrUnknown(data['income_date']!, _incomeDateMeta),
      );
    } else if (isInserting) {
      context.missing(_incomeDateMeta);
    }
    if (data.containsKey('proof_image_path')) {
      context.handle(
        _proofImagePathMeta,
        proofImagePath.isAcceptableOrUnknown(
          data['proof_image_path']!,
          _proofImagePathMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IncomeRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IncomeRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      totalIncome: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_income'],
      )!,
      epfAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}epf_amount'],
      )!,
      socsoAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}socso_amount'],
      )!,
      pcbAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pcb_amount'],
      )!,
      netIncome: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}net_income'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      incomeDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}income_date'],
      )!,
      proofImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}proof_image_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $IncomeRecordsTable createAlias(String alias) {
    return $IncomeRecordsTable(attachedDatabase, alias);
  }
}

class IncomeRecord extends DataClass implements Insertable<IncomeRecord> {
  final int id;
  final double totalIncome;
  final double epfAmount;
  final double socsoAmount;
  final double pcbAmount;
  final double netIncome;
  final String category;
  final String? description;
  final DateTime incomeDate;
  final String? proofImagePath;
  final DateTime createdAt;
  const IncomeRecord({
    required this.id,
    required this.totalIncome,
    required this.epfAmount,
    required this.socsoAmount,
    required this.pcbAmount,
    required this.netIncome,
    required this.category,
    this.description,
    required this.incomeDate,
    this.proofImagePath,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['total_income'] = Variable<double>(totalIncome);
    map['epf_amount'] = Variable<double>(epfAmount);
    map['socso_amount'] = Variable<double>(socsoAmount);
    map['pcb_amount'] = Variable<double>(pcbAmount);
    map['net_income'] = Variable<double>(netIncome);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['income_date'] = Variable<DateTime>(incomeDate);
    if (!nullToAbsent || proofImagePath != null) {
      map['proof_image_path'] = Variable<String>(proofImagePath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  IncomeRecordsCompanion toCompanion(bool nullToAbsent) {
    return IncomeRecordsCompanion(
      id: Value(id),
      totalIncome: Value(totalIncome),
      epfAmount: Value(epfAmount),
      socsoAmount: Value(socsoAmount),
      pcbAmount: Value(pcbAmount),
      netIncome: Value(netIncome),
      category: Value(category),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      incomeDate: Value(incomeDate),
      proofImagePath: proofImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(proofImagePath),
      createdAt: Value(createdAt),
    );
  }

  factory IncomeRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IncomeRecord(
      id: serializer.fromJson<int>(json['id']),
      totalIncome: serializer.fromJson<double>(json['totalIncome']),
      epfAmount: serializer.fromJson<double>(json['epfAmount']),
      socsoAmount: serializer.fromJson<double>(json['socsoAmount']),
      pcbAmount: serializer.fromJson<double>(json['pcbAmount']),
      netIncome: serializer.fromJson<double>(json['netIncome']),
      category: serializer.fromJson<String>(json['category']),
      description: serializer.fromJson<String?>(json['description']),
      incomeDate: serializer.fromJson<DateTime>(json['incomeDate']),
      proofImagePath: serializer.fromJson<String?>(json['proofImagePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'totalIncome': serializer.toJson<double>(totalIncome),
      'epfAmount': serializer.toJson<double>(epfAmount),
      'socsoAmount': serializer.toJson<double>(socsoAmount),
      'pcbAmount': serializer.toJson<double>(pcbAmount),
      'netIncome': serializer.toJson<double>(netIncome),
      'category': serializer.toJson<String>(category),
      'description': serializer.toJson<String?>(description),
      'incomeDate': serializer.toJson<DateTime>(incomeDate),
      'proofImagePath': serializer.toJson<String?>(proofImagePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  IncomeRecord copyWith({
    int? id,
    double? totalIncome,
    double? epfAmount,
    double? socsoAmount,
    double? pcbAmount,
    double? netIncome,
    String? category,
    Value<String?> description = const Value.absent(),
    DateTime? incomeDate,
    Value<String?> proofImagePath = const Value.absent(),
    DateTime? createdAt,
  }) => IncomeRecord(
    id: id ?? this.id,
    totalIncome: totalIncome ?? this.totalIncome,
    epfAmount: epfAmount ?? this.epfAmount,
    socsoAmount: socsoAmount ?? this.socsoAmount,
    pcbAmount: pcbAmount ?? this.pcbAmount,
    netIncome: netIncome ?? this.netIncome,
    category: category ?? this.category,
    description: description.present ? description.value : this.description,
    incomeDate: incomeDate ?? this.incomeDate,
    proofImagePath: proofImagePath.present
        ? proofImagePath.value
        : this.proofImagePath,
    createdAt: createdAt ?? this.createdAt,
  );
  IncomeRecord copyWithCompanion(IncomeRecordsCompanion data) {
    return IncomeRecord(
      id: data.id.present ? data.id.value : this.id,
      totalIncome: data.totalIncome.present
          ? data.totalIncome.value
          : this.totalIncome,
      epfAmount: data.epfAmount.present ? data.epfAmount.value : this.epfAmount,
      socsoAmount: data.socsoAmount.present
          ? data.socsoAmount.value
          : this.socsoAmount,
      pcbAmount: data.pcbAmount.present ? data.pcbAmount.value : this.pcbAmount,
      netIncome: data.netIncome.present ? data.netIncome.value : this.netIncome,
      category: data.category.present ? data.category.value : this.category,
      description: data.description.present
          ? data.description.value
          : this.description,
      incomeDate: data.incomeDate.present
          ? data.incomeDate.value
          : this.incomeDate,
      proofImagePath: data.proofImagePath.present
          ? data.proofImagePath.value
          : this.proofImagePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IncomeRecord(')
          ..write('id: $id, ')
          ..write('totalIncome: $totalIncome, ')
          ..write('epfAmount: $epfAmount, ')
          ..write('socsoAmount: $socsoAmount, ')
          ..write('pcbAmount: $pcbAmount, ')
          ..write('netIncome: $netIncome, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('incomeDate: $incomeDate, ')
          ..write('proofImagePath: $proofImagePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    totalIncome,
    epfAmount,
    socsoAmount,
    pcbAmount,
    netIncome,
    category,
    description,
    incomeDate,
    proofImagePath,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IncomeRecord &&
          other.id == this.id &&
          other.totalIncome == this.totalIncome &&
          other.epfAmount == this.epfAmount &&
          other.socsoAmount == this.socsoAmount &&
          other.pcbAmount == this.pcbAmount &&
          other.netIncome == this.netIncome &&
          other.category == this.category &&
          other.description == this.description &&
          other.incomeDate == this.incomeDate &&
          other.proofImagePath == this.proofImagePath &&
          other.createdAt == this.createdAt);
}

class IncomeRecordsCompanion extends UpdateCompanion<IncomeRecord> {
  final Value<int> id;
  final Value<double> totalIncome;
  final Value<double> epfAmount;
  final Value<double> socsoAmount;
  final Value<double> pcbAmount;
  final Value<double> netIncome;
  final Value<String> category;
  final Value<String?> description;
  final Value<DateTime> incomeDate;
  final Value<String?> proofImagePath;
  final Value<DateTime> createdAt;
  const IncomeRecordsCompanion({
    this.id = const Value.absent(),
    this.totalIncome = const Value.absent(),
    this.epfAmount = const Value.absent(),
    this.socsoAmount = const Value.absent(),
    this.pcbAmount = const Value.absent(),
    this.netIncome = const Value.absent(),
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.incomeDate = const Value.absent(),
    this.proofImagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  IncomeRecordsCompanion.insert({
    this.id = const Value.absent(),
    required double totalIncome,
    required double epfAmount,
    required double socsoAmount,
    required double pcbAmount,
    required double netIncome,
    required String category,
    this.description = const Value.absent(),
    required DateTime incomeDate,
    this.proofImagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : totalIncome = Value(totalIncome),
       epfAmount = Value(epfAmount),
       socsoAmount = Value(socsoAmount),
       pcbAmount = Value(pcbAmount),
       netIncome = Value(netIncome),
       category = Value(category),
       incomeDate = Value(incomeDate);
  static Insertable<IncomeRecord> custom({
    Expression<int>? id,
    Expression<double>? totalIncome,
    Expression<double>? epfAmount,
    Expression<double>? socsoAmount,
    Expression<double>? pcbAmount,
    Expression<double>? netIncome,
    Expression<String>? category,
    Expression<String>? description,
    Expression<DateTime>? incomeDate,
    Expression<String>? proofImagePath,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (totalIncome != null) 'total_income': totalIncome,
      if (epfAmount != null) 'epf_amount': epfAmount,
      if (socsoAmount != null) 'socso_amount': socsoAmount,
      if (pcbAmount != null) 'pcb_amount': pcbAmount,
      if (netIncome != null) 'net_income': netIncome,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (incomeDate != null) 'income_date': incomeDate,
      if (proofImagePath != null) 'proof_image_path': proofImagePath,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  IncomeRecordsCompanion copyWith({
    Value<int>? id,
    Value<double>? totalIncome,
    Value<double>? epfAmount,
    Value<double>? socsoAmount,
    Value<double>? pcbAmount,
    Value<double>? netIncome,
    Value<String>? category,
    Value<String?>? description,
    Value<DateTime>? incomeDate,
    Value<String?>? proofImagePath,
    Value<DateTime>? createdAt,
  }) {
    return IncomeRecordsCompanion(
      id: id ?? this.id,
      totalIncome: totalIncome ?? this.totalIncome,
      epfAmount: epfAmount ?? this.epfAmount,
      socsoAmount: socsoAmount ?? this.socsoAmount,
      pcbAmount: pcbAmount ?? this.pcbAmount,
      netIncome: netIncome ?? this.netIncome,
      category: category ?? this.category,
      description: description ?? this.description,
      incomeDate: incomeDate ?? this.incomeDate,
      proofImagePath: proofImagePath ?? this.proofImagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (totalIncome.present) {
      map['total_income'] = Variable<double>(totalIncome.value);
    }
    if (epfAmount.present) {
      map['epf_amount'] = Variable<double>(epfAmount.value);
    }
    if (socsoAmount.present) {
      map['socso_amount'] = Variable<double>(socsoAmount.value);
    }
    if (pcbAmount.present) {
      map['pcb_amount'] = Variable<double>(pcbAmount.value);
    }
    if (netIncome.present) {
      map['net_income'] = Variable<double>(netIncome.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (incomeDate.present) {
      map['income_date'] = Variable<DateTime>(incomeDate.value);
    }
    if (proofImagePath.present) {
      map['proof_image_path'] = Variable<String>(proofImagePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IncomeRecordsCompanion(')
          ..write('id: $id, ')
          ..write('totalIncome: $totalIncome, ')
          ..write('epfAmount: $epfAmount, ')
          ..write('socsoAmount: $socsoAmount, ')
          ..write('pcbAmount: $pcbAmount, ')
          ..write('netIncome: $netIncome, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('incomeDate: $incomeDate, ')
          ..write('proofImagePath: $proofImagePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $IncomeCategoriesTable incomeCategories = $IncomeCategoriesTable(
    this,
  );
  late final $IncomeRecordsTable incomeRecords = $IncomeRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    incomeCategories,
    incomeRecords,
  ];
}

typedef $$IncomeCategoriesTableCreateCompanionBuilder =
    IncomeCategoriesCompanion Function({Value<int> id, required String name});
typedef $$IncomeCategoriesTableUpdateCompanionBuilder =
    IncomeCategoriesCompanion Function({Value<int> id, Value<String> name});

class $$IncomeCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $IncomeCategoriesTable> {
  $$IncomeCategoriesTableFilterComposer({
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
}

class $$IncomeCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $IncomeCategoriesTable> {
  $$IncomeCategoriesTableOrderingComposer({
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
}

class $$IncomeCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IncomeCategoriesTable> {
  $$IncomeCategoriesTableAnnotationComposer({
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
}

class $$IncomeCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IncomeCategoriesTable,
          IncomeCategory,
          $$IncomeCategoriesTableFilterComposer,
          $$IncomeCategoriesTableOrderingComposer,
          $$IncomeCategoriesTableAnnotationComposer,
          $$IncomeCategoriesTableCreateCompanionBuilder,
          $$IncomeCategoriesTableUpdateCompanionBuilder,
          (
            IncomeCategory,
            BaseReferences<
              _$AppDatabase,
              $IncomeCategoriesTable,
              IncomeCategory
            >,
          ),
          IncomeCategory,
          PrefetchHooks Function()
        > {
  $$IncomeCategoriesTableTableManager(
    _$AppDatabase db,
    $IncomeCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IncomeCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IncomeCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IncomeCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
              }) => IncomeCategoriesCompanion(id: id, name: name),
          createCompanionCallback:
              ({Value<int> id = const Value.absent(), required String name}) =>
                  IncomeCategoriesCompanion.insert(id: id, name: name),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IncomeCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IncomeCategoriesTable,
      IncomeCategory,
      $$IncomeCategoriesTableFilterComposer,
      $$IncomeCategoriesTableOrderingComposer,
      $$IncomeCategoriesTableAnnotationComposer,
      $$IncomeCategoriesTableCreateCompanionBuilder,
      $$IncomeCategoriesTableUpdateCompanionBuilder,
      (
        IncomeCategory,
        BaseReferences<_$AppDatabase, $IncomeCategoriesTable, IncomeCategory>,
      ),
      IncomeCategory,
      PrefetchHooks Function()
    >;
typedef $$IncomeRecordsTableCreateCompanionBuilder =
    IncomeRecordsCompanion Function({
      Value<int> id,
      required double totalIncome,
      required double epfAmount,
      required double socsoAmount,
      required double pcbAmount,
      required double netIncome,
      required String category,
      Value<String?> description,
      required DateTime incomeDate,
      Value<String?> proofImagePath,
      Value<DateTime> createdAt,
    });
typedef $$IncomeRecordsTableUpdateCompanionBuilder =
    IncomeRecordsCompanion Function({
      Value<int> id,
      Value<double> totalIncome,
      Value<double> epfAmount,
      Value<double> socsoAmount,
      Value<double> pcbAmount,
      Value<double> netIncome,
      Value<String> category,
      Value<String?> description,
      Value<DateTime> incomeDate,
      Value<String?> proofImagePath,
      Value<DateTime> createdAt,
    });

class $$IncomeRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $IncomeRecordsTable> {
  $$IncomeRecordsTableFilterComposer({
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

  ColumnFilters<double> get totalIncome => $composableBuilder(
    column: $table.totalIncome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get epfAmount => $composableBuilder(
    column: $table.epfAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get socsoAmount => $composableBuilder(
    column: $table.socsoAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pcbAmount => $composableBuilder(
    column: $table.pcbAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get netIncome => $composableBuilder(
    column: $table.netIncome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get incomeDate => $composableBuilder(
    column: $table.incomeDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get proofImagePath => $composableBuilder(
    column: $table.proofImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IncomeRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $IncomeRecordsTable> {
  $$IncomeRecordsTableOrderingComposer({
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

  ColumnOrderings<double> get totalIncome => $composableBuilder(
    column: $table.totalIncome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get epfAmount => $composableBuilder(
    column: $table.epfAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get socsoAmount => $composableBuilder(
    column: $table.socsoAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pcbAmount => $composableBuilder(
    column: $table.pcbAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get netIncome => $composableBuilder(
    column: $table.netIncome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get incomeDate => $composableBuilder(
    column: $table.incomeDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get proofImagePath => $composableBuilder(
    column: $table.proofImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IncomeRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IncomeRecordsTable> {
  $$IncomeRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get totalIncome => $composableBuilder(
    column: $table.totalIncome,
    builder: (column) => column,
  );

  GeneratedColumn<double> get epfAmount =>
      $composableBuilder(column: $table.epfAmount, builder: (column) => column);

  GeneratedColumn<double> get socsoAmount => $composableBuilder(
    column: $table.socsoAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pcbAmount =>
      $composableBuilder(column: $table.pcbAmount, builder: (column) => column);

  GeneratedColumn<double> get netIncome =>
      $composableBuilder(column: $table.netIncome, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get incomeDate => $composableBuilder(
    column: $table.incomeDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get proofImagePath => $composableBuilder(
    column: $table.proofImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$IncomeRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IncomeRecordsTable,
          IncomeRecord,
          $$IncomeRecordsTableFilterComposer,
          $$IncomeRecordsTableOrderingComposer,
          $$IncomeRecordsTableAnnotationComposer,
          $$IncomeRecordsTableCreateCompanionBuilder,
          $$IncomeRecordsTableUpdateCompanionBuilder,
          (
            IncomeRecord,
            BaseReferences<_$AppDatabase, $IncomeRecordsTable, IncomeRecord>,
          ),
          IncomeRecord,
          PrefetchHooks Function()
        > {
  $$IncomeRecordsTableTableManager(_$AppDatabase db, $IncomeRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IncomeRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IncomeRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IncomeRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> totalIncome = const Value.absent(),
                Value<double> epfAmount = const Value.absent(),
                Value<double> socsoAmount = const Value.absent(),
                Value<double> pcbAmount = const Value.absent(),
                Value<double> netIncome = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> incomeDate = const Value.absent(),
                Value<String?> proofImagePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => IncomeRecordsCompanion(
                id: id,
                totalIncome: totalIncome,
                epfAmount: epfAmount,
                socsoAmount: socsoAmount,
                pcbAmount: pcbAmount,
                netIncome: netIncome,
                category: category,
                description: description,
                incomeDate: incomeDate,
                proofImagePath: proofImagePath,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double totalIncome,
                required double epfAmount,
                required double socsoAmount,
                required double pcbAmount,
                required double netIncome,
                required String category,
                Value<String?> description = const Value.absent(),
                required DateTime incomeDate,
                Value<String?> proofImagePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => IncomeRecordsCompanion.insert(
                id: id,
                totalIncome: totalIncome,
                epfAmount: epfAmount,
                socsoAmount: socsoAmount,
                pcbAmount: pcbAmount,
                netIncome: netIncome,
                category: category,
                description: description,
                incomeDate: incomeDate,
                proofImagePath: proofImagePath,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IncomeRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IncomeRecordsTable,
      IncomeRecord,
      $$IncomeRecordsTableFilterComposer,
      $$IncomeRecordsTableOrderingComposer,
      $$IncomeRecordsTableAnnotationComposer,
      $$IncomeRecordsTableCreateCompanionBuilder,
      $$IncomeRecordsTableUpdateCompanionBuilder,
      (
        IncomeRecord,
        BaseReferences<_$AppDatabase, $IncomeRecordsTable, IncomeRecord>,
      ),
      IncomeRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$IncomeCategoriesTableTableManager get incomeCategories =>
      $$IncomeCategoriesTableTableManager(_db, _db.incomeCategories);
  $$IncomeRecordsTableTableManager get incomeRecords =>
      $$IncomeRecordsTableTableManager(_db, _db.incomeRecords);
}
