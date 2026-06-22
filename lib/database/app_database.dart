import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class IncomeCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

class IncomeRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get totalIncome => real()();
  RealColumn get epfAmount => real()();
  RealColumn get socsoAmount => real()();
  RealColumn get pcbAmount => real()();
  RealColumn get netIncome => real()();
  TextColumn get category => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get incomeDate => dateTime()();
  TextColumn get proofImagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [IncomeCategories, IncomeRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Streams for reactive UI
  Stream<List<IncomeRecord>> watchAllIncomes() => select(incomeRecords).watch();

  // Insert Income
  Future<int> insertIncome(IncomeRecordsCompanion entry) =>
      into(incomeRecords).insert(entry);

  // Delete Income
  Future<int> deleteIncome(int id) =>
      (delete(incomeRecords)..where((t) => t.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final path = p.join(p.dirname(dbFolder.path), 'databases');
    final file = File(p.join(path, 'finance_tracker.db'));

    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    return NativeDatabase(
      file,
      logStatements: true,
      setup: (db) {
        // Switch to WAL mode to allow the Inspector and App to work simultaneously
        db.execute('PRAGMA journal_mode = WAL');
        // Add a timeout so the inspector doesn't give up immediately if the DB is busy
        db.execute('PRAGMA busy_timeout = 5000');
      },
    );
  });
}