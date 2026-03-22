import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  var db = await databaseFactoryFfi.openDatabase('/Users/doug/repos/stuff-reader/assets/dictionary.db');
  
  var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table';");
  print('Tables: $tables');
  
  for (var table in tables) {
    var name = table['name'] as String;
    if (name.startsWith('sqlite_')) continue;
    var columns = await db.rawQuery("PRAGMA table_info($name);");
    print('Table $name columns: $columns');
    try {
      var count = await db.rawQuery("SELECT COUNT(*) as count FROM $name;");
      print('Table $name count: ${count.first['count']}');
      var sample = await db.rawQuery("SELECT * FROM $name LIMIT 1;");
      print('Table $name sample: $sample');
    } catch (e) {
      print('Could not query table $name: $e');
    }
  }
  
  await db.close();
  exit(0);
}
