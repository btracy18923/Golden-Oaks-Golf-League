import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'database_helper.dart';

class CsvImportService {
  static Future<void> importPlayersFromCsv(String csvFilePath) async {
    try {
      // Get the app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File(join(directory.path, csvFilePath));
      
      if (!await file.exists()) {
        throw Exception('CSV file not found: ${file.path}');
      }

      final content = await file.readAsString();
      final lines = content.split('\n');
      
      if (lines.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Skip header line
      final dataLines = lines.skip(1).where((line) => line.trim().isNotEmpty);
      
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      int importedCount = 0;
      int skippedCount = 0;

      for (final line in dataLines) {
        try {
          final fields = line.split(';');
          
          if (fields.length >= 12) {
            // Parse CSV fields
            final firstName = fields[1].trim();
            final lastName = fields[2].trim();
            final handicap = double.tryParse(fields[3]) ?? 0.0;
            final skatNumber = fields[4].trim().isNotEmpty ? int.tryParse(fields[4]) : null;
            final league = fields[5].trim();
            final active = fields[6] == '1' ? 1 : 0;
            final cell = fields[9].trim();
            final email = fields[10].trim();
            final playerNumber = fields[11].trim().isNotEmpty ? int.tryParse(fields[11]) : null;

            // Check if player already exists (by name and league)
            final existing = await db.query(
              'players',
              where: 'first = ? AND last = ? AND league = ?',
              whereArgs: [firstName, lastName, league],
            );

            if (existing.isEmpty) {
              // Insert new player
              await db.insert('players', {
                'first': firstName,
                'last': lastName,
                'handicap': handicap,
                'skat_number': skatNumber,
                'league': league,
                'active': active,
                'cell': cell,
                'email': email,
                'player_number': playerNumber,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              });
              importedCount++;
            } else {
              // Update existing player
              await db.update(
                'players',
                {
                  'handicap': handicap,
                  'skat_number': skatNumber,
                  'active': active,
                  'cell': cell,
                  'email': email,
                  'player_number': playerNumber,
                  'updated_at': DateTime.now().toIso8601String(),
                },
                where: 'first = ? AND last = ? AND league = ?',
                whereArgs: [firstName, lastName, league],
              );
              skippedCount++;
            }
          }
        } catch (e) {
          skippedCount++;
        }
      }

      await dbHelper.close();

    } catch (e) {
      rethrow;
    }
  }

  static Future<void> importGolfCoursesFromCsv(String csvFilePath) async {
    try {
      // Get the app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File(join(directory.path, csvFilePath));
      
      if (!await file.exists()) {
        throw Exception('CSV file not found: ${file.path}');
      }

      final content = await file.readAsString();
      final lines = content.split('\n');
      
      if (lines.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Skip header line
      final dataLines = lines.skip(1).where((line) => line.trim().isNotEmpty);
      
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      int importedCount = 0;
      int skippedCount = 0;

      for (final line in dataLines) {
        try {
          final fields = line.split(';');
          
          if (fields.length >= 14) {
            // Parse CSV fields
            final name = fields[1].trim();
            final phone = fields[2].trim();
            final holes = int.tryParse(fields[3]) ?? 18;
            final tees = fields[4].trim();
            final slope = int.tryParse(fields[5]) ?? 0;
            final travelTime = fields[6].trim();
            final address = fields[7].trim();
            final city = fields[8].trim();
            final state = fields[9].trim();
            final zip = fields[10].trim();
            final website = fields[11].trim();

            // Check if golf course already exists (by name)
            final existing = await db.query(
              'golf_courses',
              where: 'name = ?',
              whereArgs: [name],
            );

            if (existing.isEmpty) {
              // Insert new golf course
              await db.insert('golf_courses', {
                'name': name,
                'phone': phone,
                'holes': holes,
                'tees': tees,
                'slope': slope,
                'travel_time': travelTime,
                'address': address,
                'city': city,
                'state': state,
                'zip': zip,
                'website': website,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              });
              importedCount++;
            } else {
              // Update existing golf course
              await db.update(
                'golf_courses',
                {
                  'phone': phone,
                  'holes': holes,
                  'tees': tees,
                  'slope': slope,
                  'travel_time': travelTime,
                  'address': address,
                  'city': city,
                  'state': state,
                  'zip': zip,
                  'website': website,
                  'updated_at': DateTime.now().toIso8601String(),
                },
                where: 'name = ?',
                whereArgs: [name],
              );
              skippedCount++;
            }
          }
        } catch (e) {
          skippedCount++;
        }
      }

      await dbHelper.close();

    } catch (e) {
      rethrow;
    }
  }

  static Future<void> importAllCsvData() async {
    try {

      // Import players
      await importPlayersFromCsv('players.csv');
      
      // Import golf courses
      await importGolfCoursesFromCsv('golf_courses.csv');
      
    } catch (e) {
      rethrow;
    }
  }
}