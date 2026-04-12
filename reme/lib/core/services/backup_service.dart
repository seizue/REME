import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  static const _dbName = 'reme.db';
  static const _backupPrefix = 'reme_backup_';

  static Future<String> _dbPath() async {
    final dbDir = await getDatabasesPath();
    return p.join(dbDir, _dbName);
  }

  static Future<Directory> _backupDir() async {
    final extDir = await getExternalStorageDirectory();
    final dir = Directory(p.join(
        (extDir ?? await getApplicationDocumentsDirectory()).path,
        'REME_Backups'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Export: copies DB to REME_Backups folder
  static Future<String?> exportBackup() async {
    try {
      final src = await _dbPath();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final dir = await _backupDir();
      final dest = p.join(dir.path, '$_backupPrefix$stamp.db');
      await File(src).copy(dest);
      return dest;
    } catch (_) {
      return null;
    }
  }

  /// List all available backups
  static Future<List<FileSystemEntity>> listBackups() async {
    final dir = await _backupDir();
    final files = await dir.list().toList();
    files.sort((a, b) => b.path.compareTo(a.path)); // newest first
    return files.where((f) => f.path.endsWith('.db')).toList();
  }

  /// Restore from a specific backup file path
  static Future<bool> restoreBackup(String backupPath) async {
    try {
      final dbPath = await _dbPath();
      // Close DB
      final db = await openDatabase(dbPath);
      await db.close();
      await File(backupPath).copy(dbPath);
      return true;
    } catch (_) {
      return false;
    }
  }
}
