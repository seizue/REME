import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  DatabaseHelper._();

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'reme.db');
    return openDatabase(path,
        version: 7, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ingredient_price_history (
          id TEXT PRIMARY KEY,
          ingredient_id TEXT NOT NULL,
          old_cost REAL NOT NULL,
          new_cost REAL NOT NULL,
          changed_at TEXT NOT NULL,
          FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sale_sessions (
          id TEXT PRIMARY KEY,
          label TEXT NOT NULL,
          date TEXT NOT NULL,
          delivery_fee REAL NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sale_items (
          id TEXT PRIMARY KEY,
          sale_session_id TEXT NOT NULL,
          recipe_id TEXT NOT NULL,
          recipe_name TEXT NOT NULL,
          selling_price REAL NOT NULL,
          cost_price REAL NOT NULL,
          quantity INTEGER NOT NULL,
          FOREIGN KEY (sale_session_id) REFERENCES sale_sessions(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sale_expenses (
          id TEXT PRIMARY KEY,
          sale_session_id TEXT NOT NULL,
          label TEXT NOT NULL,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          FOREIGN KEY (sale_session_id) REFERENCES sale_sessions(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 4) {
      // Add delivery_fee column to existing sale_sessions (for devices already on v3)
      try {
        await db.execute(
            'ALTER TABLE sale_sessions ADD COLUMN delivery_fee REAL NOT NULL DEFAULT 0');
      } catch (_) {
        // Column may already exist if created fresh at v3
      }
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sale_expenses (
          id TEXT PRIMARY KEY,
          sale_session_id TEXT NOT NULL,
          label TEXT NOT NULL,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          FOREIGN KEY (sale_session_id) REFERENCES sale_sessions(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS staff (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          role TEXT DEFAULT '',
          salary REAL NOT NULL,
          pay_period TEXT NOT NULL DEFAULT 'monthly'
        )
      ''');
    }
    if (oldVersion < 6) {
      // Add pricing fields to recipes
      try {
        await db.execute(
            'ALTER TABLE recipes ADD COLUMN labor_cost REAL NOT NULL DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE recipes ADD COLUMN markup_percent REAL NOT NULL DEFAULT 30');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE recipes ADD COLUMN pieces INTEGER NOT NULL DEFAULT 1');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE recipes ADD COLUMN total_weight REAL NOT NULL DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE recipes ADD COLUMN weight_unit TEXT NOT NULL DEFAULT \'kilo\'');
      } catch (_) {}
    }
    if (oldVersion < 7) {
      try {
        await db.execute(
            'ALTER TABLE ingredients ADD COLUMN unit_enabled INTEGER NOT NULL DEFAULT 0');
      } catch (_) {}
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE ingredients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        unit_cost REAL NOT NULL,
        unit TEXT NOT NULL DEFAULT '',
        unit_enabled INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE recipes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT DEFAULT '',
        selling_price REAL NOT NULL DEFAULT 0,
        labor_cost REAL NOT NULL DEFAULT 0,
        markup_percent REAL NOT NULL DEFAULT 30,
        pieces INTEGER NOT NULL DEFAULT 1,
        total_weight REAL NOT NULL DEFAULT 0,
        weight_unit TEXT NOT NULL DEFAULT 'kilo',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE recipe_ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id TEXT NOT NULL,
        ingredient_id TEXT NOT NULL,
        ingredient_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        unit_cost REAL NOT NULL,
        FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE recipe_price_history (
        id TEXT PRIMARY KEY,
        recipe_id TEXT NOT NULL,
        old_price REAL NOT NULL,
        new_price REAL NOT NULL,
        old_cost REAL NOT NULL,
        new_cost REAL NOT NULL,
        changed_at TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ingredient_price_history (
        id TEXT PRIMARY KEY,
        ingredient_id TEXT NOT NULL,
        old_cost REAL NOT NULL,
        new_cost REAL NOT NULL,
        changed_at TEXT NOT NULL,
        FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_sessions (
        id TEXT PRIMARY KEY,
        label TEXT NOT NULL,
        date TEXT NOT NULL,
        delivery_fee REAL NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id TEXT PRIMARY KEY,
        sale_session_id TEXT NOT NULL,
        recipe_id TEXT NOT NULL,
        recipe_name TEXT NOT NULL,
        selling_price REAL NOT NULL,
        cost_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (sale_session_id) REFERENCES sale_sessions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_expenses (
        id TEXT PRIMARY KEY,
        sale_session_id TEXT NOT NULL,
        label TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        FOREIGN KEY (sale_session_id) REFERENCES sale_sessions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE staff (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        role TEXT DEFAULT '',
        salary REAL NOT NULL,
        pay_period TEXT NOT NULL DEFAULT 'monthly'
      )
    ''');
  }
}
