// File: lib/helpers/db_helper.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user_model.dart';
import '../models/complaint_model.dart';

class DBHelper {
  static late final Database _db;

  /// Initialize the database. On web this is a no-op.
  static Future<void> initDb() async {
    if (kIsWeb) return;

    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, 'asset_maintenance.db');

    _db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        // Users table
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT    NOT NULL,
            email TEXT   NOT NULL UNIQUE,
            password TEXT NOT NULL,
            role TEXT    NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          );
        ''');

        // Complaints table
        await db.execute('''
          CREATE TABLE complaints(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            description TEXT,
            mediaPath TEXT,
            mediaIsVideo INTEGER,
            status TEXT,
            teacherId INTEGER,
            staffId INTEGER,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            FOREIGN KEY(teacherId) REFERENCES users(id),
            FOREIGN KEY(staffId)  REFERENCES users(id)
          );
        ''');

        // Indexes
        await db.execute('CREATE INDEX idx_complaints_status ON complaints(status);');
        await db.execute('CREATE INDEX idx_complaints_teacher ON complaints(teacherId);');
        await db.execute('CREATE INDEX idx_complaints_staff ON complaints(staffId);');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE complaints ADD COLUMN mediaPath TEXT;');
          await db.execute('ALTER TABLE complaints ADD COLUMN mediaIsVideo INTEGER;');
        }
        if (oldVersion < 3) {
          // Add timestamps
          await db.execute('ALTER TABLE users ADD COLUMN createdAt TEXT DEFAULT "";');
          await db.execute('ALTER TABLE users ADD COLUMN updatedAt TEXT DEFAULT "";');
          await db.execute('ALTER TABLE complaints ADD COLUMN createdAt TEXT DEFAULT "";');
          await db.execute('ALTER TABLE complaints ADD COLUMN updatedAt TEXT DEFAULT "";');

          // Create indexes
          await db.execute('CREATE INDEX IF NOT EXISTS idx_complaints_status ON complaints(status);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_complaints_teacher ON complaints(teacherId);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_complaints_staff ON complaints(staffId);');
        }
      },
    );
  }

  // ─── USER METHODS ─────────────────────────────────────────────────────────────

  /// Insert a new user, returns the new row ID.
  static Future<int> insertUser(User user) async {
    return _db.insert('users', user.toMap());
  }

  /// Fetch a user by email, or null if not found.
  static Future<User?> getUserByEmail(String email) async {
    final maps = await _db.query(
      'users',
      where:    'email = ?',
      whereArgs:[email],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  /// Fetch a user by their integer ID, or null if not found.
  static Future<User?> getUserById(int id) async {
    final maps = await _db.query(
      'users',
      where:    'id = ?',
      whereArgs:[id],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  /// Update an existing user, returns number of rows affected.
  static Future<int> updateUser(User user) async {
    return _db.update(
      'users',
      user.toMap(),
      where:    'id = ?',
      whereArgs:[user.id],
    );
  }

  // ─── COMPLAINT METHODS ─────────────────────────────────────────────────────────

  /// Insert a new complaint.
  static Future<int> insertComplaint(Complaint c) async {
    return _db.insert('complaints', c.toMap());
  }

  /// Get all complaints filed by a specific teacher.
  static Future<List<Complaint>> getComplaintsByTeacher(int teacherId) async {
    final maps = await _db.query(
      'complaints',
      where:    'teacherId = ?',
      whereArgs:[teacherId],
    );
    return maps.map(Complaint.fromMap).toList();
  }

  /// Get all unassigned complaints.
  static Future<List<Complaint>> getUnassignedComplaints() async {
    final maps = await _db.query(
      'complaints',
      where:    'status = ?',
      whereArgs:['unassigned'],
    );
    return maps.map(Complaint.fromMap).toList();
  }

  /// Get all complaints assigned to a given staff member.
  static Future<List<Complaint>> getAssignedComplaintsByStaff(int staffId) async {
    final maps = await _db.query(
      'complaints',
      where:    'staffId = ? AND status = ?',
      whereArgs:[staffId, 'assigned'],
    );
    return maps.map(Complaint.fromMap).toList();
  }

  /// Get all complaints that need verification.
  static Future<List<Complaint>> getNeedsVerificationComplaints() async {
    final maps = await _db.query(
      'complaints',
      where:    'status = ?',
      whereArgs:['needs_verification'],
    );
    return maps.map(Complaint.fromMap).toList();
  }

  /// Get every complaint in the system.
  static Future<List<Complaint>> getAllComplaints() async {
    final maps = await _db.query('complaints');
    return maps.map(Complaint.fromMap).toList();
  }

  /// Update a complaint record.
  static Future<int> updateComplaint(Complaint c) async {
    return _db.update(
      'complaints',
      c.toMap(),
      where:    'id = ?',
      whereArgs:[c.id],
    );
  }
}
