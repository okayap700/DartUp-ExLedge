import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'expense.dart';

class SQLiteDbProvider {
  SQLiteDbProvider._();

  static final SQLiteDbProvider db = SQLiteDbProvider._();

  static Database? _database;

  Future<Database?> get database async {

    _database = await initDB();
    return _database;
  }

  initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "ExpenseDB2.db");
    return await openDatabase(
      path,
      version: 1,
      onOpen: (db) {},
      onCreate: (Database db, int version) async {
        await db.execute("CREATE TABLE Expense ("
          "id INTEGER PRIMARY KEY,"
          "amount REAL,"
          "date TEXT,"
          "category TEXT"
        ")"
        );

        /* input to database
        await db.execute(
          "INSERT INTO Expense ('id', 'amount', 'date', 'category') values (?, ?, ?, ?)",
          [1, 1000, '2019-04-01 10:00:00', "FOOD"]
        );

        await db.execute(
          "INSERT INTO Product('id', 'name', 'description', 'price', 'image') values (?, ?, ?, ?)",
          [2, "Pixel", "Lorem ipsum pixel", 800, "00000.jpg"]
        );

        await db.execute(
            "INSERT INTO Product('id', 'name', 'description', 'price', 'image') values (?, ?, ?, ?)",
            [3, "Laptop", "Lorem ipsum laptop", 2000, "11111.jpg"]
        );

        await db.execute(
            "INSERT INTO Product('id', 'name', 'description', 'price', 'image') values (?, ?, ?, ?)",
            [4, "Pen-drive", "Lorem ipsum pend-rive", 100, "33333.jpg"]
        );

        await db.execute(
            "INSERT INTO Product('id', 'name', 'description', 'price', 'image') values (?, ?, ?, ?)",
            [2, "Floppy Drive", "Lorem ipsum flop", 20, "44444.jpg"]
        );
        */
      }
    );
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;

    List<Map> results = await db?.query("Expense", columns: Expense.columns, orderBy: "date DESC") as dynamic;

    List<Expense> expenses = [];
    results.forEach((result) {
      Expense expense = Expense.fromMap(result);
      expenses.add(expense);
    });

    return expenses;
  }

  Future<Object> getExpenseById(int id) async {
    final db = await database;

    var result = await db?.query("Expense", where: "id = ", whereArgs: [id]);

    return Expense.fromMap(result?.first as dynamic);
  }

  Future<double> getTotalExpense() async {
    final db = await database;

    List<Map> list = await db?.rawQuery("Select SUM(amount) as amount from expense") as dynamic;

    return list.isNotEmpty ? list[0]["amount"] : Null;
  }

  Future<Expense> insert(Expense expense) async {
    final db = await database;

    var maxIdResult = await db?.rawQuery("SELECT MAX(id)+1 as last_inserted_id FROM Expense");
    String id = maxIdResult?.first["last_inserted_id"].toString() as dynamic;

    var result = await db?.rawInsert(
      "INSERT Into Expense (id, amount, date, category)"
          "VALUES (?, ?, ?, ?)",
      [id, expense.amount, expense.date.toString(), expense.category]
    );

    return Expense(int.parse(id), expense.amount, expense.date, expense.category);
  }

  update(Expense product) async {
    final db = await database;

    var result = await db?.update("Expense", product.toMap(), where: "id = ?", whereArgs: [product.id]);

    return result;
  }

  delete(int id) async {
    final db = await database;

    db?.delete("Expense", where: "id = ?", whereArgs: [id]);
  }
}