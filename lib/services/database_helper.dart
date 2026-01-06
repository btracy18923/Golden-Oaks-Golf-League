import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/league.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  /// Global flag to allow duplicate dates in wednesday_scores
  static bool allowDuplicateDates = true;

  /// SharedPreferences key for storing the allow duplicate dates state
  static const String _allowDuplicateDatesKey = 'allow_duplicate_dates_wednesday';

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal() {
    loadAllowDuplicateDatesState();
  }

  /// Load the allow duplicate dates state from SharedPreferences
  static Future<void> loadAllowDuplicateDatesState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      allowDuplicateDates = prefs.getBool(_allowDuplicateDatesKey) ?? true;
      debugPrint('Loaded allow duplicate dates state: $allowDuplicateDates');
    } catch (e) {
      debugPrint('Error loading allow duplicate dates state: $e');
      allowDuplicateDates = true; // Default to enabled on error
    }
  }

  /// Save the allow duplicate dates state to SharedPreferences
  static Future<void> saveAllowDuplicateDatesState(bool allowed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_allowDuplicateDatesKey, allowed);
      allowDuplicateDates = allowed;
      debugPrint('Saved allow duplicate dates state: $allowed');
    } catch (e) {
      debugPrint('Error saving allow duplicate dates state: $e');
    }
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'golden_oaks.db');
    // DatabaseHelper: Initializing database at: $path

    return await openDatabase(
      path,
      version: 22,
      onCreate: (db, version) {
        // DatabaseHelper: Creating new database with version $version
        return _createTables(db, version);
      },
      onUpgrade: (db, oldVersion, newVersion) {
        // DatabaseHelper: Upgrading database from version $oldVersion to $newVersion
        return _upgradeDatabase(db, oldVersion, newVersion);
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // DatabaseHelper: Creating players table...
    // Players table - stores player information for both leagues
    await db.execute('''
      CREATE TABLE players (
        player_number INTEGER PRIMARY KEY,
        first TEXT NOT NULL,
        last TEXT NOT NULL,
        skat_number INTEGER,
        OHC REAL,
        HC REAL,
        cell TEXT,
        email TEXT,
        league TEXT NOT NULL
      )
    ''');
    // DatabaseHelper: Players table created successfully

    // Monday League scores table
    await db.execute('''
      CREATE TABLE monday_scores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        date_played TEXT NOT NULL,
        golf_course TEXT NOT NULL,
        skat_number INTEGER,
        gross_score INTEGER,
        skats_score INTEGER,
        close_pin_winnings REAL DEFAULT 0.0,
        skat_winnings REAL DEFAULT 0.0,
        FOREIGN KEY (player_id) REFERENCES players (player_number)
      )
    ''');

    // Wednesday League scores table
    await db.execute('''
      CREATE TABLE wednesday_scores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        date_played TEXT NOT NULL,
        golf_course TEXT NOT NULL,
        handicap REAL,
        gross_score INTEGER,
        close_pin_winnings REAL DEFAULT 0.0,
        single_winnings REAL DEFAULT 0.0,
        group_winnings REAL DEFAULT 0.0,
        pos TEXT,
        prize_money TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (player_id) REFERENCES players (player_number)
      )
    ''');

    // Legacy scores table - keep for compatibility
    await db.execute('''
      CREATE TABLE scores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL,
        gross_score INTEGER,
        net_score REAL,
        skats_score INTEGER,
        date_played TEXT NOT NULL,
        league TEXT NOT NULL,
        golf_course TEXT,
        close_pin_winnings REAL DEFAULT 0.0,
        monday_skat_winnings REAL DEFAULT 0.0,
        wed_single_winnings REAL DEFAULT 0.0,
        wed_group_winnings REAL DEFAULT 0.0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (player_id) REFERENCES players (player_number)
      )
    ''');

    // Games table - stores game/round information
    await db.execute('''
      CREATE TABLE games (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date_played TEXT NOT NULL,
        league TEXT NOT NULL,
        ante_amount REAL DEFAULT 6.0,
        total_purse REAL DEFAULT 0.0,
        individual_percent INTEGER DEFAULT 40,
        group_percent INTEGER DEFAULT 60,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Game_players table - links players to specific games with their results
    await db.execute('''
      CREATE TABLE game_players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER NOT NULL,
        player_id INTEGER NOT NULL,
        group_number INTEGER DEFAULT 1,
        gross_score INTEGER,
        net_score REAL,
        skats_score INTEGER,
        place_ranking INTEGER,
        individual_winnings REAL DEFAULT 0.0,
        group_winnings REAL DEFAULT 0.0,
        FOREIGN KEY (game_id) REFERENCES games (id),
        FOREIGN KEY (player_id) REFERENCES players (player_number)
      )
    ''');

    // Course_info table - stores golf course information
    await db.execute('''
      CREATE TABLE course_info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        par INTEGER DEFAULT 72,
        slope_rating REAL DEFAULT 113.0,
        course_rating REAL DEFAULT 70.0,
        league TEXT NOT NULL,
        active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Golf_courses table - stores essential golf course information
    await db.execute('''
      CREATE TABLE golf_courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        phone TEXT,
        Par3s INTEGER,
        tees TEXT,
        travel_time TEXT
      )
    ''');

    // Settings table - stores app configuration
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key_name TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL,
        league TEXT,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Mulligans table - stores daily and total mulligan amounts
    await db.execute('''
      CREATE TABLE mulligans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        league TEXT NOT NULL,
        date_recorded TEXT NOT NULL,
        daily_amount REAL DEFAULT 0.0,
        total_amount REAL DEFAULT 0.0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Adjusted mulligan purse table - stores adjusted amounts for persistence between processing steps
    await db.execute('''
      CREATE TABLE adjusted_mulligan_purse (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        league TEXT NOT NULL,
        adjusted_amount REAL NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(date, league)
      )
    ''');

    // Insert default settings
    await _insertDefaultSettings(db);
    
    // Insert sample data for testing
    await _insertSampleData(db);
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add cell and email columns to existing players table
      await db.execute('ALTER TABLE players ADD COLUMN cell TEXT');
      await db.execute('ALTER TABLE players ADD COLUMN email TEXT');
    }
    if (oldVersion < 3) {
      // Add player_number column to existing players table
      await db.execute('ALTER TABLE players ADD COLUMN player_number INTEGER');
    }
    if (oldVersion < 4) {
      // Add updated_at column to existing scores table
      try {
        await db.execute('ALTER TABLE scores ADD COLUMN updated_at TEXT DEFAULT CURRENT_TIMESTAMP');
      } catch (e) {
        // Column might already exist
      }
    }
    if (oldVersion < 5) {
      // Add golf_course column to existing scores table
      try {
        await db.execute('ALTER TABLE scores ADD COLUMN golf_course TEXT');
      } catch (e) {
        // Column might already exist
      }
    }
    if (oldVersion < 6) {
      // Add golf_courses table for detailed course management
      try {
        await db.execute('''
          CREATE TABLE golf_courses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            phone TEXT,
            holes INTEGER,
            tees TEXT,
            slope INTEGER,
            travel_time TEXT,
            address TEXT,
            city TEXT,
            state TEXT,
            zip TEXT,
            website TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      } catch (e) {
        // Table might already exist
      }
    }
    if (oldVersion < 7) {
      // Update golf_courses table to make id_number optional and name unique
      try {
        // Note: SQLite doesn't support modifying constraints easily
        // For existing databases, this would require table recreation
      } catch (e) {
      }
    }
    if (oldVersion < 8) {
      // Recreate golf_courses table with simplified schema (remove unused fields)
      try {
        // Drop existing table and recreate with simplified schema
        await db.execute('DROP TABLE IF EXISTS golf_courses');
        await db.execute('''
          CREATE TABLE golf_courses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            phone TEXT,
            holes INTEGER,
            tees TEXT,
            slope INTEGER,
            travel_time TEXT,
            address TEXT,
            city TEXT,
            state TEXT,
            zip TEXT,
            website TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      } catch (e) {
      }
    }
    if (oldVersion < 9) {
      // Add additional fields for course details (address, city, state, zip, website)
      try {
        await db.execute('DROP TABLE IF EXISTS golf_courses');
        await db.execute('''
          CREATE TABLE golf_courses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            phone TEXT,
            holes INTEGER,
            tees TEXT,
            slope INTEGER,
            travel_time TEXT,
            address TEXT,
            city TEXT,
            state TEXT,
            zip TEXT,
            website TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      } catch (e) {
      }
    }
    if (oldVersion < 10) {
      // Add winnings columns to scores table for simple direct storage
      try {
        await db.execute('ALTER TABLE scores ADD COLUMN close_pin_winnings REAL DEFAULT 0.0');
        await db.execute('ALTER TABLE scores ADD COLUMN monday_skat_winnings REAL DEFAULT 0.0');
        await db.execute('ALTER TABLE scores ADD COLUMN wed_single_winnings REAL DEFAULT 0.0');
        await db.execute('ALTER TABLE scores ADD COLUMN wed_group_winnings REAL DEFAULT 0.0');
      } catch (e) {
      }
    }
    if (oldVersion < 11) {
      // Create separate tables for Monday and Wednesday leagues
      try {
        // Monday League scores table
        await db.execute('''
          CREATE TABLE monday_scores (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            player_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            date_played TEXT NOT NULL,
            golf_course TEXT NOT NULL,
            skat_number INTEGER,
            gross_score INTEGER,
            skats_score INTEGER,
            close_pin_winnings REAL DEFAULT 0.0,
            skat_winnings REAL DEFAULT 0.0,
            FOREIGN KEY (player_id) REFERENCES players (player_number)
          )
        ''');

        // Wednesday League scores table
        await db.execute('''
          CREATE TABLE wednesday_scores (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            player_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            date_played TEXT NOT NULL,
            golf_course TEXT NOT NULL,
            handicap REAL,
            gross_score INTEGER,
            close_pin_winnings REAL DEFAULT 0.0,
            single_winnings REAL DEFAULT 0.0,
            group_winnings REAL DEFAULT 0.0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (player_id) REFERENCES players (player_number)
          )
        ''');
        
      } catch (e) {
      }
    }
    if (oldVersion < 12) {
      // Create mulligans table for tracking daily and total mulligan amounts
      try {
        await db.execute('''
          CREATE TABLE mulligans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            league TEXT NOT NULL,
            date_recorded TEXT NOT NULL,
            daily_amount REAL DEFAULT 0.0,
            total_amount REAL DEFAULT 0.0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      } catch (e) {
      }
    }
    if (oldVersion < 13) {
      // Add Pos and $$$ columns for storing winning positions directly
      try {
        await db.execute('ALTER TABLE monday_scores ADD COLUMN pos TEXT');
        await db.execute('ALTER TABLE monday_scores ADD COLUMN prize_money TEXT');
        await db.execute('ALTER TABLE wednesday_scores ADD COLUMN pos TEXT');
        await db.execute('ALTER TABLE wednesday_scores ADD COLUMN prize_money TEXT');
        // Added Pos and prize_money columns to scores tables
      } catch (e) {
        // Warning: Could not add Pos and prize_money columns: $e
      }
    }
    if (oldVersion < 14) {
      // Create table for storing adjusted mulligan purse amounts
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS adjusted_mulligan_purse (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            league TEXT NOT NULL,
            adjusted_amount REAL NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(date, league)
          )
        ''');
        // Created adjusted_mulligan_purse table
      } catch (e) {
        // Warning: Could not create adjusted_mulligan_purse table: $e
      }
    }
    if (oldVersion < 15) {
      // Remove id, handicap, active, created_at, updated_at fields from players table
      try {
        // Create new players table with simplified schema
        await db.execute('''
          CREATE TABLE players_new (
            player_number INTEGER PRIMARY KEY,
            first TEXT NOT NULL,
            last TEXT NOT NULL,
            skat_number INTEGER,
            cell TEXT,
            email TEXT,
            league TEXT NOT NULL
          )
        ''');
        
        // Copy data from old table to new table (only the fields we want to keep)
        await db.execute('''
          INSERT INTO players_new (player_number, first, last, skat_number, cell, email, league)
          SELECT player_number, first, last, skat_number, cell, email, league FROM players
        ''');
        
        // Drop old table and rename new table
        await db.execute('DROP TABLE players');
        await db.execute('ALTER TABLE players_new RENAME TO players');
        
      } catch (e) {
      }
    }
    if (oldVersion < 16) {
      // Remove unwanted fields from monday_scores table
      try {
        // Create new monday_scores table with simplified schema
        await db.execute('''
          CREATE TABLE monday_scores_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            player_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            date_played TEXT NOT NULL,
            golf_course TEXT NOT NULL,
            skat_number INTEGER,
            gross_score INTEGER,
            skats_score INTEGER,
            close_pin_winnings REAL DEFAULT 0.0,
            skat_winnings REAL DEFAULT 0.0,
            FOREIGN KEY (player_id) REFERENCES players (player_number)
          )
        ''');
        
        // Copy data from old table to new table (only the fields we want to keep)
        await db.execute('''
          INSERT INTO monday_scores_new (player_id, name, date_played, golf_course, skat_number, gross_score, skats_score, close_pin_winnings, skat_winnings)
          SELECT player_id, name, date_played, golf_course, skat_number, gross_score, skats_score, close_pin_winnings, skat_winnings FROM monday_scores
        ''');
        
        // Drop old table and rename new table
        await db.execute('DROP TABLE monday_scores');
        await db.execute('ALTER TABLE monday_scores_new RENAME TO monday_scores');
        
      } catch (e) {
      }
    }
    if (oldVersion < 17) {
      // Remove unwanted fields from golf_courses table
      try {
        // Create new golf_courses table with simplified schema
        await db.execute('''
          CREATE TABLE golf_courses_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            phone TEXT,
            holes INTEGER,
            tees TEXT,
            travel_time TEXT
          )
        ''');
        
        // Copy data from old table to new table (only the fields we want to keep)
        await db.execute('''
          INSERT INTO golf_courses_new (id, name, phone, holes, tees, travel_time)
          SELECT id, name, phone, holes, tees, travel_time FROM golf_courses
        ''');
        
        // Drop old table and rename new table
        await db.execute('DROP TABLE golf_courses');
        await db.execute('ALTER TABLE golf_courses_new RENAME TO golf_courses');
        
      } catch (e) {
      }
    }
    if (oldVersion < 18) {
      // Rename 'holes' field to 'Par3s' in golf_courses table
      try {
        // Create new golf_courses table with Par3s field
        await db.execute('''
          CREATE TABLE golf_courses_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            phone TEXT,
            Par3s INTEGER,
            tees TEXT,
            travel_time TEXT
          )
        ''');
        
        // Copy data from old table to new table (rename holes to Par3s)
        await db.execute('''
          INSERT INTO golf_courses_new (id, name, phone, Par3s, tees, travel_time)
          SELECT id, name, phone, holes, tees, travel_time FROM golf_courses
        ''');
        
        // Drop old table and rename new table
        await db.execute('DROP TABLE golf_courses');
        await db.execute('ALTER TABLE golf_courses_new RENAME TO golf_courses');
        
      } catch (e) {
      }
    }
    if (oldVersion < 19) {
      // Add id column to monday_scores table
      try {
        // Create new monday_scores table with id column
        await db.execute('''
          CREATE TABLE monday_scores_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            player_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            date_played TEXT NOT NULL,
            golf_course TEXT NOT NULL,
            skat_number INTEGER,
            gross_score INTEGER,
            skats_score INTEGER,
            close_pin_winnings REAL DEFAULT 0.0,
            skat_winnings REAL DEFAULT 0.0,
            FOREIGN KEY (player_id) REFERENCES players (player_number)
          )
        ''');
        
        // Copy data from old table to new table
        await db.execute('''
          INSERT INTO monday_scores_new (player_id, name, date_played, golf_course, skat_number, gross_score, skats_score, close_pin_winnings, skat_winnings)
          SELECT player_id, name, date_played, golf_course, skat_number, gross_score, skats_score, close_pin_winnings, skat_winnings FROM monday_scores
        ''');
        
        // Drop old table and rename new table
        await db.execute('DROP TABLE monday_scores');
        await db.execute('ALTER TABLE monday_scores_new RENAME TO monday_scores');
        
      } catch (e) {
      }
    }
    if (oldVersion < 20) {
      // Remove Handicap and other unwanted columns from golf_courses table
      try {
        // Create new golf_courses table with only the 6 required columns
        await db.execute('''
          CREATE TABLE golf_courses_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            phone TEXT,
            Par3s INTEGER,
            tees TEXT,
            travel_time TEXT
          )
        ''');

        // Copy data from old table to new table (only the 6 fields we want to keep)
        await db.execute('''
          INSERT INTO golf_courses_new (id, name, phone, Par3s, tees, travel_time)
          SELECT id, name, phone,
            CASE WHEN typeof(Par3s) = 'integer' THEN Par3s ELSE NULL END,
            tees, travel_time
          FROM golf_courses
        ''');

        // Drop old table and rename new table
        await db.execute('DROP TABLE golf_courses');
        await db.execute('ALTER TABLE golf_courses_new RENAME TO golf_courses');

      } catch (e) {
      }
    }
    if (oldVersion < 21) {
      // Add HC column to players table for Wednesday league handicaps
      try {
        await db.execute('ALTER TABLE players ADD COLUMN HC REAL');
      } catch (e) {
      }
    }
    if (oldVersion < 22) {
      // Add OHC column to players table for Original Handicap (before adjustments)
      try {
        await db.execute('ALTER TABLE players ADD COLUMN OHC REAL');
      } catch (e) {
      }
    }
  }

  Future<void> _insertDefaultSettings(Database db) async {
    await db.insert('settings', {'key_name': 'monday_ante', 'value': '12.00', 'league': 'monday'});
    await db.insert('settings', {'key_name': 'wednesday_ante', 'value': '6.00', 'league': 'wednesday'});
    await db.insert('settings', {'key_name': 'individual_percent', 'value': '40'});
    await db.insert('settings', {'key_name': 'group_percent', 'value': '60'});
    await db.insert('settings', {'key_name': 'firebase_sync_enabled', 'value': 'false'});
  }

  Future<void> _insertSampleData(Database db) async {
    // Insert sample players for both leagues
    List<Map<String, dynamic>> samplePlayers = [
      {'player_number': 101, 'first': 'John', 'last': 'Smith', 'skat_number': 1, 'cell': '555-123-4567', 'email': 'john@example.com', 'league': 'monday'},
      {'player_number': 102, 'first': 'Mike', 'last': 'Jones', 'skat_number': 2, 'cell': '555-234-5678', 'email': 'mike@example.com', 'league': 'monday'},
      {'player_number': 103, 'first': 'Bob', 'last': 'Wilson', 'skat_number': 3, 'cell': '555-345-6789', 'email': 'bob@example.com', 'league': 'monday'},
      {'player_number': 201, 'first': 'Tom', 'last': 'Brown', 'cell': '555-456-7890', 'email': 'tom@example.com', 'league': 'wednesday'},
      {'player_number': 202, 'first': 'Dave', 'last': 'Davis', 'cell': '555-567-8901', 'email': 'dave@example.com', 'league': 'wednesday'},
      {'player_number': 203, 'first': 'Steve', 'last': 'Miller', 'cell': '555-678-9012', 'email': 'steve@example.com', 'league': 'wednesday'},
    ];

    for (var player in samplePlayers) {
      await db.insert('players', player);
    }

    // Insert default course info
    await db.insert('course_info', {
      'name': 'Golden Oaks Golf Course',
      'par': 72,
      'slope_rating': 113.0,
      'course_rating': 70.0,
      'league': 'monday'
    });
    
    await db.insert('course_info', {
      'name': 'Golden Oaks Golf Course',
      'par': 72,
      'slope_rating': 113.0,
      'course_rating': 70.0,
      'league': 'wednesday'
    });

    // Insert sample golf courses
    List<Map<String, dynamic>> sampleCourses = [
      {
        'name': 'Golden Oaks Golf Course',
        'phone': '217-555-0123',
        'Par3s': 4,
        'tees': 'Blue/White',
        'travel_time': '5 minutes'
      },
      {
        'name': 'Riverside Country Club',
        'phone': '217-555-0456',
        'Par3s': 5,
        'tees': 'Championship',
        'travel_time': '15 minutes'
      },
      {
        'name': 'Pine Valley Golf Club',
        'phone': '217-555-0789',
        'Par3s': 6,
        'tees': 'Blue/White/Red',
        'travel_time': '25 minutes'
      }
    ];

    for (var course in sampleCourses) {
      await db.insert('golf_courses', course);
    }
  }

  // PLAYER METHODS
  Future<List<Map<String, dynamic>>> getAllPlayers() async {
    final db = await database;

    return await db.query(
      'players',
      orderBy: 'last ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getPlayersByLeague(League league) async {
    final db = await database;
    String leagueStr = league == League.monday ? 'monday' : 'wednesday';

    // Include players who are in the specific league OR in both leagues
    return await db.query(
      'players',
      where: 'league = ? OR league = ?',
      whereArgs: [leagueStr, 'both'],
      orderBy: 'last ASC',
    );
  }

  Future<Map<String, dynamic>?> getPlayer(int playerId) async {
    final db = await database;

    List<Map<String, dynamic>> results = await db.query(
      'players',
      where: 'player_number = ?',
      whereArgs: [playerId],
      limit: 1,
    );

    return results.isNotEmpty ? results.first : null;
  }

  Future<int> insertPlayer(Map<String, dynamic> player) async {
    final db = await database;
    return await db.insert('players', player);
  }

  Future<int> updatePlayer(int playerId, Map<String, dynamic> player) async {
    final db = await database;

    return await db.update(
      'players',
      player,
      where: 'player_number = ?',
      whereArgs: [playerId],
    );
  }

  Future<int> deletePlayer(int playerId) async {
    final db = await database;

    return await db.delete(
      'players',
      where: 'player_number = ?',
      whereArgs: [playerId],
    );
  }

  // GAME METHODS
  Future<int> createGame(League league, double anteAmount) async {
    final db = await database;
    String leagueStr = league == League.monday ? 'monday' : 'wednesday';
    
    return await db.insert('games', {
      'date_played': DateTime.now().toIso8601String().split('T')[0],
      'league': leagueStr,
      'ante_amount': anteAmount,
      'total_purse': 0.0,
      'individual_percent': 40,
      'group_percent': 60,
    });
  }

  Future<List<Map<String, dynamic>>> getGamesByLeague(League league) async {
    final db = await database;
    String leagueStr = league == League.monday ? 'monday' : 'wednesday';
    
    return await db.query(
      'games',
      where: 'league = ?',
      whereArgs: [leagueStr],
      orderBy: 'date_played DESC',
    );
  }

  // SCORE METHODS
  Future<int> insertScore(Map<String, dynamic> score) async {
    final db = await database;
    score['date_played'] = DateTime.now().toIso8601String().split('T')[0];
    
    return await db.transaction((txn) async {
      // Insert the new score
      int result = await txn.insert('scores', score);
      
      // Clean up old scores to maintain 20 entry limit
      String leagueStr = score['league'] as String;
      await _cleanupOldScoresInTransaction(txn, score['player_id'] as int, leagueStr);
      
      return result;
    });
  }

  Future<List<Map<String, dynamic>>> getPlayerScores(int playerId, League league) async {
    final db = await database;
    String leagueStr = league == League.monday ? 'monday' : 'wednesday';
    
    return await db.query(
      'scores',
      where: 'player_id = ? AND league = ?',
      whereArgs: [playerId, leagueStr],
      orderBy: 'date_played DESC',
    );
  }

  // Get player scores from separate league tables
  Future<List<Map<String, dynamic>>> getPlayerScoresSimple(int playerId, League league) async {
    final db = await database;
    String tableName = league == League.monday ? 'monday_scores' : 'wednesday_scores';
    
    // First, clean up old entries to keep only the latest 20
    await _cleanupOldScoresLeague(playerId, tableName);
    
    return await db.rawQuery('''
      SELECT * FROM $tableName
      WHERE player_id = ?
      ORDER BY id DESC
      LIMIT 20
    ''', [playerId]);
  }

  // Check if a player already has a score for a specific date in a league
  Future<Map<String, dynamic>?> getPlayerScoreByDate(int playerId, String date, League league) async {
    final db = await database;
    String tableName = league == League.monday ? 'monday_scores' : 'wednesday_scores';

    List<Map<String, dynamic>> result = await db.query(
      tableName,
      where: 'player_id = ? AND date_played = ?',
      whereArgs: [playerId, date],
      limit: 1,
    );

    return result.isNotEmpty ? result.first : null;
  }

  // Get the most recent N scores for a player (most recent first)
  // When there are duplicate dates, selects rows from top-down (highest id first)
  Future<List<Map<String, dynamic>>> getPlayerRecentScores(
    int playerId,
    League league, {
    int limit = 20,
  }) async {
    final db = await database;
    String tableName = league == League.monday ? 'monday_scores' : 'wednesday_scores';

    return await db.query(
      tableName,
      where: 'player_id = ?',
      whereArgs: [playerId],
      orderBy: 'date_played DESC, id DESC',
      limit: limit,
    );
  }

  // Update a player's handicap in the players table
  Future<void> updatePlayerHandicap(
    int playerId,
    double handicap,
    League league,
  ) async {
    final db = await database;

    await db.update(
      'players',
      {'HC': handicap},
      where: 'player_number = ?',
      whereArgs: [playerId],
    );
  }

  // Helper method to clean up old score entries for league tables
  Future<void> _cleanupOldScoresLeague(int playerId, String tableName) async {
    final db = await database;
    
    // Get count of scores for this player in this table
    List<Map<String, dynamic>> countResult = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM $tableName 
      WHERE player_id = ?
    ''', [playerId]);
    
    int totalScores = countResult.first['count'] as int;
    
    // If more than 20 scores, delete the oldest ones
    if (totalScores > 20) {
      await db.rawQuery('''
        DELETE FROM $tableName 
        WHERE id IN (
          SELECT id FROM $tableName 
          WHERE player_id = ?
          ORDER BY id ASC 
          LIMIT ?
        )
      ''', [playerId, totalScores - 20]);
    }
  }

  // Insert score into appropriate league table
  // Returns a map with 'insertId' and 'deletedScores' for Firebase sync
  Future<Map<String, dynamic>> insertScoreLeague(Map<String, dynamic> score, League league) async {
    final db = await database;
    String tableName = league == League.monday ? 'monday_scores' : 'wednesday_scores';

    List<Map<String, dynamic>> deletedScores = [];
    int insertId = 0;

    await db.transaction((txn) async {
      // For Wednesday league, check for duplicate dates if flag is disabled
      if (league == League.wednesday && !allowDuplicateDates) {
        // Check if a score already exists for this player and date
        List<Map<String, dynamic>> existingScores = await txn.query(
          tableName,
          where: 'player_id = ? AND date_played = ?',
          whereArgs: [score['player_id'], score['date_played']],
          limit: 1,
        );

        if (existingScores.isNotEmpty) {
          // Duplicate found - update existing score instead of inserting
          insertId = existingScores.first['id'] as int;
          await txn.update(
            tableName,
            score,
            where: 'id = ?',
            whereArgs: [insertId],
          );
          debugPrint('Updated existing score (ID: $insertId) for player ${score['player_id']} on ${score['date_played']}');
          return; // Skip insert and cleanup
        }
      }

      // Insert the new score (or if duplicates are allowed, or if it's Monday league)
      insertId = await txn.insert(tableName, score);

      // Clean up old scores to maintain 15 entry limit
      // This returns the list of scores that were deleted
      deletedScores = await _cleanupOldScoresLeagueInTransaction(txn, score['player_id'] as int, tableName);
    });

    return {
      'insertId': insertId,
      'deletedScores': deletedScores,
    };
  }

  // Update group winnings for the most recent score record only
  Future<int> updateGroupWinnings(int playerId, double groupWinnings, League league) async {

    final db = await database;
    String tableName = league == League.monday ? 'monday_scores' : 'wednesday_scores';
    

    // Find the most recent record for this player (highest ID = most recent)
    List<Map<String, dynamic>> recentRecords = await db.query(
      tableName,
      where: 'player_id = ?',
      whereArgs: [playerId],
      orderBy: 'id DESC',
      limit: 1,
    );
    

    if (recentRecords.isNotEmpty) {
      int mostRecentId = recentRecords.first['id'] as int;

      // Update only the most recent record
      int rowsUpdated = await db.update(
        tableName,
        {'group_winnings': groupWinnings},
        where: 'id = ?',
        whereArgs: [mostRecentId],
      );
      
      return rowsUpdated;
    } else {
    }
    
    return 0; // No records found to update
  }

  // Update a specific field in a score record by record ID
  Future<int> updateScoreField(int recordId, String fieldName, dynamic fieldValue, League league) async {

    final db = await database;
    String tableName = league == League.monday ? 'monday_scores' : 'wednesday_scores';
    
    try {
      // Update the specific field for the record
      int rowsUpdated = await db.update(
        tableName,
        {fieldName: fieldValue},
        where: 'id = ?',
        whereArgs: [recordId],
      );
      
      return rowsUpdated;
    } catch (e) {
      return 0;
    }
  }

  // Transaction-safe cleanup method for league tables
  // Returns list of deleted scores for Firebase sync
  Future<List<Map<String, dynamic>>> _cleanupOldScoresLeagueInTransaction(Transaction txn, int playerId, String tableName) async {
    // Get count of scores for this player in this table
    List<Map<String, dynamic>> countResult = await txn.rawQuery('''
      SELECT COUNT(*) as count
      FROM $tableName
      WHERE player_id = ?
    ''', [playerId]);

    int totalScores = countResult.first['count'] as int;

    // If more than 15 scores, delete the oldest ones
    if (totalScores > 15) {
      // First, get the scores that will be deleted for Firebase sync
      List<Map<String, dynamic>> scoresToDelete = await txn.rawQuery('''
        SELECT * FROM $tableName
        WHERE player_id = ?
        ORDER BY id ASC
        LIMIT ?
      ''', [playerId, totalScores - 15]);

      // Then delete them from local database
      await txn.rawQuery('''
        DELETE FROM $tableName
        WHERE id IN (
          SELECT id FROM $tableName
          WHERE player_id = ?
          ORDER BY id ASC
          LIMIT ?
        )
      ''', [playerId, totalScores - 15]);

      return scoresToDelete;
    }

    return []; // No scores deleted
  }

  // Get player scores simple - directly from old scores table (legacy)
  Future<List<Map<String, dynamic>>> getPlayerScoresSimpleLegacy(int playerId, League league) async {
    final db = await database;
    String leagueStr = league == League.monday ? 'monday' : 'wednesday';
    
    // First, clean up old entries to keep only the latest 20
    await _cleanupOldScores(playerId, leagueStr);
    
    return await db.rawQuery('''
      SELECT
        s.*
      FROM scores s
      JOIN players p ON s.player_id = p.player_number
      WHERE s.player_id = ? AND s.league = ?
      ORDER BY s.id DESC
      LIMIT 20
    ''', [playerId, leagueStr]);
  }

  // Get player scores WITH winnings data from game_players table
  // Returns newest scores first, limited to 20 entries
  Future<List<Map<String, dynamic>>> getPlayerScoresWithWinnings(int playerId, League league) async {
    final db = await database;
    String leagueStr = league == League.monday ? 'monday' : 'wednesday';
    
    // First, clean up old entries to keep only the latest 20
    await _cleanupOldScores(playerId, leagueStr);
    
    return await db.rawQuery('''
      SELECT 
        s.*,
        CASE 
          WHEN s.id = (
            SELECT MAX(s2.id) 
            FROM scores s2 
            WHERE s2.player_id = s.player_id 
            AND s2.date_played = s.date_played 
            AND s2.league = s.league
          ) THEN gp.individual_winnings
          WHEN NOT EXISTS (
            SELECT 1 
            FROM scores s3 
            WHERE s3.player_id = s.player_id 
            AND s3.date_played = s.date_played 
            AND s3.league = s.league 
            AND s3.id > s.id
          ) AND gp.individual_winnings IS NOT NULL THEN gp.individual_winnings
          ELSE 0
        END as individual_winnings,
        CASE 
          WHEN s.id = (
            SELECT MAX(s2.id) 
            FROM scores s2 
            WHERE s2.player_id = s.player_id 
            AND s2.date_played = s.date_played 
            AND s2.league = s.league
          ) THEN gp.group_winnings
          WHEN NOT EXISTS (
            SELECT 1 
            FROM scores s3 
            WHERE s3.player_id = s.player_id 
            AND s3.date_played = s.date_played 
            AND s3.league = s.league 
            AND s3.id > s.id
          ) AND gp.group_winnings IS NOT NULL THEN gp.group_winnings
          ELSE 0
        END as group_winnings,
        CASE 
          WHEN s.id = (
            SELECT MAX(s2.id) 
            FROM scores s2 
            WHERE s2.player_id = s.player_id 
            AND s2.date_played = s.date_played 
            AND s2.league = s.league
          ) THEN gp.place_ranking
          WHEN NOT EXISTS (
            SELECT 1 
            FROM scores s3 
            WHERE s3.player_id = s.player_id 
            AND s3.date_played = s.date_played 
            AND s3.league = s.league 
            AND s3.id > s.id
          ) AND gp.place_ranking IS NOT NULL THEN gp.place_ranking
          ELSE NULL
        END as place_ranking
      FROM scores s
      LEFT JOIN (
        SELECT DISTINCT
          gp.player_id,
          g.date_played,
          gp.individual_winnings,
          gp.group_winnings,
          gp.place_ranking,
          gp.game_id
        FROM game_players gp
        JOIN games g ON gp.game_id = g.id
        WHERE g.league = ?
      ) gp ON (
        s.player_id = gp.player_id 
        AND s.date_played = gp.date_played
      )
      WHERE s.player_id = ? AND s.league = ?
      ORDER BY s.id DESC
      LIMIT 20
    ''', [leagueStr, playerId, leagueStr]);
  }

  // Get player score history by last name and league
  Future<List<Map<String, dynamic>>> getPlayerScoreHistory(String playerLast, League league) async {
    final db = await database;
    String leagueStr = league == League.monday ? 'monday' : 'wednesday';
    String tableName = league == League.monday ? 'monday_scores' : 'wednesday_scores';
    
    return await db.rawQuery('''
      SELECT s.*,
        p.first as first_name,
        p.last as last_name
      FROM $tableName s
      JOIN players p ON s.player_id = p.id
      WHERE p.last = ? AND p.league = ?
      ORDER BY s.date_played DESC
      LIMIT 20
    ''', [playerLast, leagueStr]);
  }

  // Helper method to clean up old score entries, keeping only the latest 20
  Future<void> _cleanupOldScores(int playerId, String league) async {
    final db = await database;
    
    // Get count of scores for this player and league
    List<Map<String, dynamic>> countResult = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM scores 
      WHERE player_id = ? AND league = ?
    ''', [playerId, league]);
    
    int totalScores = countResult.first['count'] as int;
    
    // If more than 20 scores, delete the oldest ones
    if (totalScores > 20) {
      await db.rawQuery('''
        DELETE FROM scores 
        WHERE id IN (
          SELECT id FROM scores 
          WHERE player_id = ? AND league = ? 
          ORDER BY id ASC 
          LIMIT ?
        )
      ''', [playerId, league, totalScores - 20]);
    }
  }

  // Transaction-safe cleanup method for use within database transactions
  Future<void> _cleanupOldScoresInTransaction(Transaction txn, int playerId, String league) async {
    // Get count of scores for this player and league
    List<Map<String, dynamic>> countResult = await txn.rawQuery('''
      SELECT COUNT(*) as count 
      FROM scores 
      WHERE player_id = ? AND league = ?
    ''', [playerId, league]);
    
    int totalScores = countResult.first['count'] as int;
    
    // If more than 20 scores, delete the oldest ones
    if (totalScores > 20) {
      await txn.rawQuery('''
        DELETE FROM scores 
        WHERE id IN (
          SELECT id FROM scores 
          WHERE player_id = ? AND league = ? 
          ORDER BY id ASC 
          LIMIT ?
        )
      ''', [playerId, league, totalScores - 20]);
    }
  }

  Future<List<Map<String, dynamic>>> getScoresByDate(String date, League league) async {
    final db = await database;
    String leagueStr = league == League.monday ? 'monday' : 'wednesday';
    
    return await db.rawQuery('''
      SELECT s.*, p.first, p.last
      FROM scores s
      JOIN players p ON s.player_id = p.player_number
      WHERE s.date_played = ? AND s.league = ?
      ORDER BY s.net_score ASC
    ''', [date, leagueStr]);
  }

  Future<int> updateScore(int scoreId, Map<String, dynamic> score) async {
    final db = await database;
    
    final result = await db.update(
      'scores',
      score,
      where: 'id = ?',
      whereArgs: [scoreId],
    );

    return result;
  }

  Future<int> deleteScore(int scoreId) async {
    final db = await database;

    return await db.delete(
      'scores',
      where: 'id = ?',
      whereArgs: [scoreId],
    );
  }

  // Delete all scores for a specific date in a league
  Future<int> deleteScoresByDate(String date, League league) async {
    final db = await database;
    String tableName = league == League.monday ? 'monday_scores' : 'wednesday_scores';

    return await db.delete(
      tableName,
      where: 'date_played = ?',
      whereArgs: [date],
    );
  }

  // Clear all score data from the database
  Future<void> clearAllScoreData() async {
    final db = await database;

    await db.transaction((txn) async {
      // Clear scores table
      await txn.delete('scores');

      // Clear league-specific score tables
      await txn.delete('monday_scores');
      await txn.delete('wednesday_scores');

      // Clear game_players table
      await txn.delete('game_players');

      // Clear games table
      await txn.delete('games');
    });
  }

  /// Clear score data for Monday league only
  Future<void> clearMondayScoreData() async {
    final db = await database;

    await db.transaction((txn) async {
      // Clear Monday-specific score table
      await txn.delete('monday_scores');

      // Clear legacy scores table for Monday league only
      await txn.delete('scores', where: 'league = ?', whereArgs: ['monday']);

      // Clear game_players and games for Monday league only
      // First get all Monday game IDs
      List<Map<String, dynamic>> mondayGames = await txn.query(
        'games',
        columns: ['id'],
        where: 'league = ?',
        whereArgs: ['monday'],
      );

      // Delete game_players for Monday games
      for (var game in mondayGames) {
        await txn.delete('game_players', where: 'game_id = ?', whereArgs: [game['id']]);
      }

      // Delete Monday games
      await txn.delete('games', where: 'league = ?', whereArgs: ['monday']);
    });
  }

  /// Clear score data for Wednesday league only
  Future<void> clearWednesdayScoreData() async {
    final db = await database;

    await db.transaction((txn) async {
      // Clear Wednesday-specific score table
      await txn.delete('wednesday_scores');

      // Clear legacy scores table for Wednesday league only
      await txn.delete('scores', where: 'league = ?', whereArgs: ['wednesday']);

      // Clear game_players and games for Wednesday league only
      // First get all Wednesday game IDs
      List<Map<String, dynamic>> wednesdayGames = await txn.query(
        'games',
        columns: ['id'],
        where: 'league = ?',
        whereArgs: ['wednesday'],
      );

      // Delete game_players for Wednesday games
      for (var game in wednesdayGames) {
        await txn.delete('game_players', where: 'game_id = ?', whereArgs: [game['id']]);
      }

      // Delete Wednesday games
      await txn.delete('games', where: 'league = ?', whereArgs: ['wednesday']);
    });
  }

  // GAME PLAYER METHODS
  Future<int> insertGamePlayer(Map<String, dynamic> gamePlayer) async {
    final db = await database;
    return await db.insert('game_players', gamePlayer);
  }

  Future<List<Map<String, dynamic>>> getGamePlayers(int gameId) async {
    final db = await database;
    
    return await db.rawQuery('''
      SELECT gp.*, p.first, p.last
      FROM game_players gp
      JOIN players p ON gp.player_id = p.player_number
      WHERE gp.game_id = ?
      ORDER BY gp.place_ranking ASC
    ''', [gameId]);
  }

  Future<int> updateGamePlayer(int gamePlayerId, Map<String, dynamic> gamePlayer) async {
    final db = await database;
    
    return await db.update(
      'game_players',
      gamePlayer,
      where: 'id = ?',
      whereArgs: [gamePlayerId],
    );
  }

  // Save complete game results including scores and winnings
  Future<int> saveGameResults({
    required League league,
    required double anteAmount,
    required List<Map<String, dynamic>> playerResults,
  }) async {
    final db = await database;
    String leagueStr = league == League.monday ? 'monday' : 'wednesday';
    String today = DateTime.now().toIso8601String().split('T')[0];
    
    // Start transaction
    return await db.transaction((txn) async {
      // Check if a game already exists for this date and league
      List<Map<String, dynamic>> existingGames = await txn.query(
        'games',
        where: 'date_played = ? AND league = ?',
        whereArgs: [today, leagueStr],
        limit: 1,
      );
      
      int gameId;
      if (existingGames.isNotEmpty) {
        // Use existing game ID and update it
        gameId = existingGames.first['id'] as int;
        await txn.update('games', {
          'ante_amount': anteAmount,
          'total_purse': playerResults.length * anteAmount,
          'individual_percent': 40,
          'group_percent': 60,
        }, where: 'id = ?', whereArgs: [gameId]);
        
        // Clear existing game_players entries for this game
        await txn.delete('game_players', where: 'game_id = ?', whereArgs: [gameId]);
      } else {
        // Create a new game record
        gameId = await txn.insert('games', {
          'date_played': today,
          'league': leagueStr,
          'ante_amount': anteAmount,
          'total_purse': playerResults.length * anteAmount,
          'individual_percent': 40,
          'group_percent': 60,
        });
      }
      
      // Save each player's results
      for (var player in playerResults) {
        // Save to game_players table with winnings
        await txn.insert('game_players', {
          'game_id': gameId,
          'player_id': player['id'],
          'group_number': player['group_number'] ?? 1,
          'gross_score': player['gross_score'],
          'net_score': player['net_score'],
          'skats_score': player['skats_score'],
          'place_ranking': player['place'],
          'individual_winnings': player['winnings'] ?? 0.0,
          'group_winnings': 0.0, // Will be updated when group processing is implemented
        });
        
        // Always insert new score entry for player history (allow multiple entries per date)
        String golfCourse = leagueStr == 'wednesday' ? 'The Hideout' : 'Golden Oaks Golf Course';
        await txn.insert('scores', {
          'player_id': player['id'],
          'gross_score': player['gross_score'],
          'net_score': player['net_score'],
          'skats_score': player['skats_score'],
          'date_played': today,
          'league': leagueStr,
          'golf_course': golfCourse,
        });
        
        // Clean up old scores to maintain 20 entry limit per player/league
        await _cleanupOldScoresInTransaction(txn, player['id'], leagueStr);
      }
      
      return gameId;
    });
  }

  // SETTINGS METHODS
  Future<String?> getSetting(String keyName, {League? league}) async {
    final db = await database;
    String? leagueStr = league != null 
        ? (league == League.monday ? 'monday' : 'wednesday')
        : null;
    
    List<Map<String, dynamic>> results;
    if (leagueStr != null) {
      results = await db.query(
        'settings',
        where: 'key_name = ? AND (league = ? OR league IS NULL)',
        whereArgs: [keyName, leagueStr],
        limit: 1,
      );
    } else {
      results = await db.query(
        'settings',
        where: 'key_name = ?',
        whereArgs: [keyName],
        limit: 1,
      );
    }
    
    return results.isNotEmpty ? results.first['value'] as String : null;
  }

  Future<int> setSetting(String keyName, String value, {League? league}) async {
    final db = await database;
    String? leagueStr = league != null 
        ? (league == League.monday ? 'monday' : 'wednesday')
        : null;

    Map<String, dynamic> settingData = {
      'key_name': keyName,
      'value': value,
      'league': leagueStr,
      'updated_at': DateTime.now().toIso8601String(),
    };

    return await db.insert(
      'settings',
      settingData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // UTILITY METHODS
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('game_players');
    await db.delete('scores');
    await db.delete('games');
    await db.delete('players');
    await db.delete('course_info');
    await db.delete('settings');
    
    // Reinsert default settings and sample data
    await _insertDefaultSettings(db);
    await _insertSampleData(db);
  }

  Future<Map<String, int>> getDataCounts() async {
    final db = await database;

    List<Map<String, dynamic>> playerCount = await db.rawQuery('SELECT COUNT(*) as count FROM players');
    List<Map<String, dynamic>> gameCount = await db.rawQuery('SELECT COUNT(*) as count FROM games');
    List<Map<String, dynamic>> scoreCount = await db.rawQuery('SELECT COUNT(*) as count FROM scores');

    return {
      'players': playerCount.first['count'] as int,
      'games': gameCount.first['count'] as int,
      'scores': scoreCount.first['count'] as int,
    };
  }

  // GOLF COURSE METHODS
  Future<List<Map<String, dynamic>>> getAllGolfCourses() async {
    final db = await database;
    
    return await db.query(
      'golf_courses',
      orderBy: 'name ASC',
    );
  }

  Future<Map<String, dynamic>?> getGolfCourse(int courseId) async {
    final db = await database;
    
    List<Map<String, dynamic>> results = await db.query(
      'golf_courses',
      where: 'id = ?',
      whereArgs: [courseId],
      limit: 1,
    );
    
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> insertGolfCourse(Map<String, dynamic> course) async {
    final db = await database;
    return await db.insert('golf_courses', course);
  }

  Future<int> updateGolfCourse(int courseId, Map<String, dynamic> course) async {
    final db = await database;
    
    return await db.update(
      'golf_courses',
      course,
      where: 'id = ?',
      whereArgs: [courseId],
    );
  }

  Future<int> deleteGolfCourse(int courseId) async {
    final db = await database;
    
    return await db.delete(
      'golf_courses',
      where: 'id = ?',
      whereArgs: [courseId],
    );
  }

  // MULLIGANS METHODS
  Future<double> getTotalMulligans(League league) async {
    final db = await database;
    String leagueStr = league == League.monday ? 'monday' : 'wednesday';
    
    List<Map<String, dynamic>> results = await db.query(
      'mulligans',
      columns: ['total_amount'],
      where: 'league = ?',
      whereArgs: [leagueStr],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    
    return results.isNotEmpty ? (results.first['total_amount'] as double? ?? 0.0) : 0.0;
  }

  Future<double> getTodaysMulligans(League league) async {
    final db = await database;
    String leagueStr = league == League.monday ? 'monday' : 'wednesday';
    String today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format
    
    List<Map<String, dynamic>> results = await db.query(
      'mulligans',
      columns: ['daily_amount'],
      where: 'league = ? AND date_recorded = ?',
      whereArgs: [leagueStr, today],
      limit: 1,
    );
    
    return results.isNotEmpty ? (results.first['daily_amount'] as double? ?? 0.0) : 0.0;
  }

  Future<void> saveTodaysMulligans(League league, double dailyAmount) async {
    final db = await database;
    String leagueStr = league == League.monday ? 'monday' : 'wednesday';
    String today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format
    
    // Get current total
    double currentTotal = await getTotalMulligans(league);
    
    // Get current daily amount for today
    double currentDaily = await getTodaysMulligans(league);
    
    // Calculate new total (remove old daily amount, add new daily amount)
    double newTotal = currentTotal - currentDaily + dailyAmount;
    
    Map<String, dynamic> mulliganData = {
      'league': leagueStr,
      'date_recorded': today,
      'daily_amount': dailyAmount,
      'total_amount': newTotal,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Check if record exists for today
    List<Map<String, dynamic>> existing = await db.query(
      'mulligans',
      where: 'league = ? AND date_recorded = ?',
      whereArgs: [leagueStr, today],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // Update existing record
      await db.update(
        'mulligans',
        mulliganData,
        where: 'league = ? AND date_recorded = ?',
        whereArgs: [leagueStr, today],
      );
    } else {
      // Insert new record
      mulliganData['created_at'] = DateTime.now().toIso8601String();
      await db.insert('mulligans', mulliganData);
    }
  }

  // Debug method to check if players table exists
  Future<bool> checkPlayersTableExists() async {
    try {
      final db = await database;
      var result = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='players'");
      bool exists = result.isNotEmpty;
      return exists;
    } catch (e) {
      return false;
    }
  }

  // Get the adjusted mulligan purse for the current date and league
  Future<double?> getAdjustedMulliganPurse(String league) async {
    try {
      final db = await database;
      final currentDate = DateTime.now().toIso8601String().split('T')[0];
      
      final result = await db.query(
        'adjusted_mulligan_purse',
        where: 'date = ? AND league = ?',
        whereArgs: [currentDate, league],
        orderBy: 'created_at DESC',
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        return result.first['adjusted_amount'] as double?;
      }
      return null;
    } catch (e) {
      // Error retrieving adjusted mulligan purse: $e
      return null;
    }
  }

  // FIREBASE UPLOAD HELPER METHODS

  /// Get all golf courses (golf courses table doesn't have league-specific data)
  Future<List<Map<String, dynamic>>> getGolfCoursesByLeague(League league) async {
    final db = await database;
    
    // Since golf courses are shared between leagues, return all courses
    return await db.query(
      'golf_courses',
      orderBy: 'name ASC',
    );
  }

  /// Get all scores for a specific league from the league-specific tables
  Future<List<Map<String, dynamic>>> getScoresByLeague(League league) async {
    final db = await database;
    String tableName = league == League.monday ? 'monday_scores' : 'wednesday_scores';
    
    return await db.query(
      tableName,
      orderBy: 'date_played DESC, id DESC',
    );
  }

  /// Update all golf courses to set Par3s field to 4
  Future<void> updateAllGolfCoursesPar3sTo4() async {
    try {
      final db = await database;
      await db.execute('''
        UPDATE golf_courses 
        SET Par3s = 4
      ''');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}