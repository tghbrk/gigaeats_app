import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/driver_earnings.dart';
import '../services/driver_earnings_service.dart';

/// Cached driver earnings repository with SQLite for offline access
class CachedDriverEarningsRepository {
  static const String _databaseName = 'driver_earnings_cache.db';
  static const int _databaseVersion = 1;
  
  // Table names
  static const String _earningsTable = 'earnings_cache';
  static const String _summaryTable = 'summary_cache';
  static const String _metadataTable = 'cache_metadata';
  
  Database? _database;
  final DriverEarningsService _earningsService;
  
  // Cache configuration
  static const Duration _cacheExpiry = Duration(hours: 1);
  static const int _maxCacheEntries = 1000;

  CachedDriverEarningsRepository({
    DriverEarningsService? earningsService,
  }) : _earningsService = earningsService ?? DriverEarningsService();

  /// Initialize the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize SQLite database with tables
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    // Earnings cache table
    await db.execute('''
      CREATE TABLE $_earningsTable (
        id TEXT PRIMARY KEY,
        driver_id TEXT NOT NULL,
        earnings_type TEXT NOT NULL,
        amount REAL NOT NULL,
        base_amount REAL NOT NULL,
        commission_rate REAL NOT NULL,
        platform_fee REAL NOT NULL,
        net_amount REAL NOT NULL,
        bonus_amount REAL DEFAULT 0,
        status TEXT NOT NULL,
        order_id TEXT,
        description TEXT,
        metadata TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        cached_at TEXT NOT NULL,
        INDEX(driver_id),
        INDEX(created_at),
        INDEX(status),
        INDEX(earnings_type)
      )
    ''');

    // Summary cache table
    await db.execute('''
      CREATE TABLE $_summaryTable (
        cache_key TEXT PRIMARY KEY,
        driver_id TEXT NOT NULL,
        start_date TEXT,
        end_date TEXT,
        summary_data TEXT NOT NULL,
        cached_at TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        INDEX(driver_id),
        INDEX(expires_at)
      )
    ''');

    // Cache metadata table
    await db.execute('''
      CREATE TABLE $_metadataTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    debugPrint('CachedDriverEarningsRepository: Database tables created');
  }

  /// Upgrade database schema
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    debugPrint('CachedDriverEarningsRepository: Upgrading database from $oldVersion to $newVersion');
    
    // Handle future schema upgrades here
    if (oldVersion < 2) {
      // Example: Add new columns or tables
    }
  }

  /// Get driver earnings with caching
  Future<List<DriverEarnings>> getDriverEarnings(
    String driverId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    bool useCache = true,
  }) async {
    if (useCache) {
      // Try to get from cache first
      final cachedEarnings = await _getCachedEarnings(
        driverId,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
      
      if (cachedEarnings.isNotEmpty) {
        debugPrint('CachedDriverEarningsRepository: Returning ${cachedEarnings.length} cached earnings');
        return cachedEarnings;
      }
    }

    try {
      // Fetch from remote service
      final earnings = await _earningsService.getDriverEarnings(
        driverId,
        startDate: startDate,
        endDate: endDate,
        limit: limit ?? 50,
      );

      // Cache the results
      await _cacheEarnings(earnings);
      
      debugPrint('CachedDriverEarningsRepository: Fetched and cached ${earnings.length} earnings');
      return earnings;
    } catch (e) {
      debugPrint('CachedDriverEarningsRepository: Remote fetch failed, trying cache: $e');
      
      // If remote fails, try cache as fallback
      return await _getCachedEarnings(
        driverId,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
    }
  }

  /// Get driver earnings summary with caching
  Future<Map<String, dynamic>> getDriverEarningsSummary(
    String driverId, {
    DateTime? startDate,
    DateTime? endDate,
    bool useCache = true,
  }) async {
    final cacheKey = _generateSummaryCacheKey(driverId, startDate, endDate);
    
    if (useCache) {
      // Try to get from cache first
      final cachedSummary = await _getCachedSummary(cacheKey);
      if (cachedSummary != null) {
        debugPrint('CachedDriverEarningsRepository: Returning cached summary');
        return cachedSummary;
      }
    }

    try {
      // Fetch from remote service
      final summary = await _earningsService.getDriverEarningsSummary(
        driverId,
        startDate: startDate,
        endDate: endDate,
      );

      // Cache the summary
      await _cacheSummary(cacheKey, driverId, summary, startDate, endDate);
      
      debugPrint('CachedDriverEarningsRepository: Fetched and cached summary');
      return summary;
    } catch (e) {
      debugPrint('CachedDriverEarningsRepository: Remote summary fetch failed, trying cache: $e');
      
      // If remote fails, try cache as fallback
      final cachedSummary = await _getCachedSummary(cacheKey);
      return cachedSummary ?? {};
    }
  }

  /// Get cached earnings from SQLite
  Future<List<DriverEarnings>> _getCachedEarnings(
    String driverId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final db = await database;
    
    String whereClause = 'driver_id = ?';
    List<dynamic> whereArgs = [driverId];
    
    if (startDate != null) {
      whereClause += ' AND created_at >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      whereClause += ' AND created_at <= ?';
      whereArgs.add(endDate.toIso8601String());
    }
    
    // Check if cache is still valid (within expiry time)
    final expiryTime = DateTime.now().subtract(_cacheExpiry);
    whereClause += ' AND cached_at > ?';
    whereArgs.add(expiryTime.toIso8601String());
    
    final result = await db.query(
      _earningsTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    
    return result.map((row) => _mapRowToDriverEarnings(row)).toList();
  }

  /// Cache earnings to SQLite
  Future<void> _cacheEarnings(List<DriverEarnings> earnings) async {
    if (earnings.isEmpty) return;
    
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    
    for (final earning in earnings) {
      batch.insert(
        _earningsTable,
        _mapDriverEarningsToRow(earning, now),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
    
    // Clean up old cache entries
    await _cleanupOldCacheEntries();
  }

  /// Get cached summary from SQLite
  Future<Map<String, dynamic>?> _getCachedSummary(String cacheKey) async {
    final db = await database;
    
    final result = await db.query(
      _summaryTable,
      where: 'cache_key = ? AND expires_at > ?',
      whereArgs: [cacheKey, DateTime.now().toIso8601String()],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      final summaryData = result.first['summary_data'] as String;
      return Map<String, dynamic>.from(jsonDecode(summaryData));
    }
    
    return null;
  }

  /// Cache summary to SQLite
  Future<void> _cacheSummary(
    String cacheKey,
    String driverId,
    Map<String, dynamic> summary,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final db = await database;
    final now = DateTime.now();
    final expiresAt = now.add(_cacheExpiry);
    
    await db.insert(
      _summaryTable,
      {
        'cache_key': cacheKey,
        'driver_id': driverId,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'summary_data': jsonEncode(summary),
        'cached_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Generate cache key for summary
  String _generateSummaryCacheKey(String driverId, DateTime? startDate, DateTime? endDate) {
    final startStr = startDate?.toIso8601String() ?? 'null';
    final endStr = endDate?.toIso8601String() ?? 'null';
    return 'summary_${driverId}_${startStr}_$endStr';
  }

  /// Map database row to DriverEarnings model
  DriverEarnings _mapRowToDriverEarnings(Map<String, dynamic> row) {
    return DriverEarnings(
      id: row['id'] as String,
      driverId: row['driver_id'] as String,
      earningsType: EarningsType.values.firstWhere(
        (type) => type.value == row['earnings_type'],
        orElse: () => EarningsType.deliveryFee,
      ),
      amount: row['amount'] as double,
      baseAmount: row['base_amount'] as double,
      commissionRate: row['commission_rate'] as double,
      platformFee: row['platform_fee'] as double,
      netAmount: row['net_amount'] as double,
      bonusAmount: row['bonus_amount'] as double? ?? 0.0,
      status: EarningsStatus.values.firstWhere(
        (status) => status.value == row['status'],
        orElse: () => EarningsStatus.pending,
      ),
      orderId: row['order_id'] as String?,
      description: row['description'] as String?,
      metadata: row['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(row['metadata'] as String))
          : null,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  /// Map DriverEarnings model to database row
  Map<String, dynamic> _mapDriverEarningsToRow(DriverEarnings earning, String cachedAt) {
    return {
      'id': earning.id,
      'driver_id': earning.driverId,
      'earnings_type': earning.earningsType.value,
      'amount': earning.amount,
      'base_amount': earning.baseAmount,
      'commission_rate': earning.commissionRate,
      'platform_fee': earning.platformFee,
      'net_amount': earning.netAmount,
      'bonus_amount': earning.bonusAmount,
      'status': earning.status.value,
      'order_id': earning.orderId,
      'description': earning.description,
      'metadata': earning.metadata != null ? jsonEncode(earning.metadata) : null,
      'created_at': earning.createdAt.toIso8601String(),
      'updated_at': earning.updatedAt.toIso8601String(),
      'cached_at': cachedAt,
    };
  }

  /// Clean up old cache entries to maintain performance
  Future<void> _cleanupOldCacheEntries() async {
    final db = await database;
    final expiryTime = DateTime.now().subtract(_cacheExpiry);

    // Remove expired earnings cache
    await db.delete(
      _earningsTable,
      where: 'cached_at < ?',
      whereArgs: [expiryTime.toIso8601String()],
    );

    // Remove expired summary cache
    await db.delete(
      _summaryTable,
      where: 'expires_at < ?',
      whereArgs: [DateTime.now().toIso8601String()],
    );

    // Limit total cache entries to prevent unlimited growth
    final totalCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_earningsTable'),
    ) ?? 0;

    if (totalCount > _maxCacheEntries) {
      // Keep only the most recent entries
      await db.execute('''
        DELETE FROM $_earningsTable
        WHERE id NOT IN (
          SELECT id FROM $_earningsTable
          ORDER BY cached_at DESC
          LIMIT $_maxCacheEntries
        )
      ''');
    }

    debugPrint('CachedDriverEarningsRepository: Cache cleanup completed');
  }

  /// Clear all cached data for a specific driver
  Future<void> clearDriverCache(String driverId) async {
    final db = await database;

    await db.delete(
      _earningsTable,
      where: 'driver_id = ?',
      whereArgs: [driverId],
    );

    await db.delete(
      _summaryTable,
      where: 'driver_id = ?',
      whereArgs: [driverId],
    );

    debugPrint('CachedDriverEarningsRepository: Cleared cache for driver $driverId');
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    final db = await database;

    await db.delete(_earningsTable);
    await db.delete(_summaryTable);
    await db.delete(_metadataTable);

    debugPrint('CachedDriverEarningsRepository: Cleared all cache');
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final db = await database;

    final earningsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_earningsTable'),
    ) ?? 0;

    final summaryCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_summaryTable'),
    ) ?? 0;

    final oldestEntry = await db.rawQuery(
      'SELECT MIN(cached_at) as oldest FROM $_earningsTable',
    );

    final newestEntry = await db.rawQuery(
      'SELECT MAX(cached_at) as newest FROM $_earningsTable',
    );

    return {
      'earnings_count': earningsCount,
      'summary_count': summaryCount,
      'oldest_entry': oldestEntry.isNotEmpty ? oldestEntry.first['oldest'] : null,
      'newest_entry': newestEntry.isNotEmpty ? newestEntry.first['newest'] : null,
      'cache_expiry_hours': _cacheExpiry.inHours,
      'max_entries': _maxCacheEntries,
    };
  }

  /// Check if cache is available (offline mode)
  Future<bool> isCacheAvailable(String driverId) async {
    final db = await database;

    final result = await db.query(
      _earningsTable,
      where: 'driver_id = ?',
      whereArgs: [driverId],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// Force refresh cache from remote
  Future<void> refreshCache(String driverId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Clear existing cache for this driver
    await clearDriverCache(driverId);

    // Fetch fresh data from remote
    await getDriverEarnings(
      driverId,
      startDate: startDate,
      endDate: endDate,
      useCache: false,
    );

    await getDriverEarningsSummary(
      driverId,
      startDate: startDate,
      endDate: endDate,
      useCache: false,
    );

    debugPrint('CachedDriverEarningsRepository: Cache refreshed for driver $driverId');
  }

  /// Preload cache for better performance
  Future<void> preloadCache(String driverId, {
    Duration? period,
  }) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(period ?? const Duration(days: 30));

    try {
      // Preload earnings data
      await getDriverEarnings(
        driverId,
        startDate: startDate,
        endDate: endDate,
        useCache: false,
      );

      // Preload summary data
      await getDriverEarningsSummary(
        driverId,
        startDate: startDate,
        endDate: endDate,
        useCache: false,
      );

      debugPrint('CachedDriverEarningsRepository: Cache preloaded for driver $driverId');
    } catch (e) {
      debugPrint('CachedDriverEarningsRepository: Cache preload failed: $e');
    }
  }



  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      debugPrint('CachedDriverEarningsRepository: Database connection closed');
    }
  }

  /// Dispose resources
  void dispose() {
    close();
  }
}
