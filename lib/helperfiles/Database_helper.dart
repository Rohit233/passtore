import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper{
  static DatabaseHelper _databaseHelper;
  static Database _database;
  String passTable="Password_table";
  String colId="id";
  String colSite="Site";
  String colPass="Password";
  DatabaseHelper._createInstance();
  factory DatabaseHelper(){
    if(_databaseHelper==null){
      _databaseHelper=DatabaseHelper._createInstance();
    }
    return _databaseHelper;
  }
  Future <Database> get database async{
    if(_database==null){
      _database=await initializeDatabase();
    }
    return _database;
  }
  Future<Database> initializeDatabase()async{
//    getApplicationDocumentsDirectory()
//     Directory directory=await getExternalStorageDirectory();
//     String path=directory.path+"pass.db";
    Directory directory=await getApplicationDocumentsDirectory();
    String path=directory.path+'database.db';
    var noteDatabase=await openDatabase(
      path,version: 1,onCreate: _createDb
    );
    return noteDatabase;
  }
  void _createDb(Database db,int newVersion) async{
    await db.execute(
      "CREATE TABLE $passTable($colId INTEGER PRIMARY KEY,"
          ' $colSite TEXT,$colPass TEXT)'
    );
  }

  Future<int> insertPass(Map details)async{
    Database db=await this.database;
    var result=await db.insert(passTable, details);
    return result;
  }
  Future <List<Map<String,dynamic>>> getAllPass()async{
    Database db=await this.database;
    var result=await db.query(passTable,orderBy:"$colId ASC");
    return result;
  }
  Future<int> deletePass(int id)async{
    Database db=await this.database;
    var result=await db.rawDelete("DELETE FROM $passTable WHERE $colId=$id");
    return result;
  }
  Future<int> updataPass(Map details)async{
    Database db=await this.database;
    var result=await db.update(passTable, details,where: '$colId=?',whereArgs: [details['id']]);
    return result;
  }
}