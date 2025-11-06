import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

/// Modern caching service using Hive (2025 best practices)
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Logger _logger = Logger();
  static const String _categoriesBox = 'categories';
  static const String _requestTypesBox = 'requestTypes';
  static const String _statusesBox = 'statuses';
  static const String _employeesBox = 'employees';
  static const String _districtsBox = 'districts';
  static const String _requestsBox = 'requests';
  static const Duration _cacheExpiry = Duration(hours: 1);

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      await Hive.initFlutter();
      await Future.wait([
        Hive.openBox(_categoriesBox),
        Hive.openBox(_requestTypesBox),
        Hive.openBox(_statusesBox),
        Hive.openBox(_employeesBox),
        Hive.openBox(_districtsBox),
        Hive.openBox(_requestsBox),
      ]);
      _initialized = true;
      _logger.i('Cache service initialized');
    } catch (e) {
      _logger.e('Cache initialization error: $e');
    }
  }

  // Categories cache
  Future<void> cacheCategories(List<Map<String, dynamic>> categories) async {
    if (!_initialized) await init();
    try {
      final box = Hive.box(_categoriesBox);
      await box.put('data', categories);
      await box.put('timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      _logger.e('Cache categories error: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> getCachedCategories() async {
    if (!_initialized) await init();
    try {
      final box = Hive.box(_categoriesBox);
      final timestamp = box.get('timestamp') as int?;
      if (timestamp == null) return null;

      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cachedTime) > _cacheExpiry) {
        return null; // Cache expired
      }

      final data = box.get('data');
      if (data == null) return null;
      // Явное преобразование LinkedMap в Map
      if (data is List) {
        return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
      return null;
    } catch (e) {
      _logger.e('Get cached categories error: $e');
      return null;
    }
  }

  // Request Types cache
  Future<void> cacheRequestTypes(List<Map<String, dynamic>> types) async {
    if (!_initialized) await init();
    try {
      final box = Hive.box(_requestTypesBox);
      await box.put('data', types);
      await box.put('timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      _logger.e('Cache request types error: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> getCachedRequestTypes() async {
    if (!_initialized) await init();
    try {
      final box = Hive.box(_requestTypesBox);
      final timestamp = box.get('timestamp') as int?;
      if (timestamp == null) return null;

      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cachedTime) > _cacheExpiry) {
        return null;
      }

      final data = box.get('data');
      if (data == null) return null;
      // Явное преобразование LinkedMap в Map
      if (data is List) {
        return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Statuses cache
  Future<void> cacheStatuses(List<Map<String, dynamic>> statuses) async {
    if (!_initialized) await init();
    try {
      final box = Hive.box(_statusesBox);
      await box.put('data', statuses);
      await box.put('timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      _logger.e('Cache statuses error: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> getCachedStatuses() async {
    if (!_initialized) await init();
    try {
      final box = Hive.box(_statusesBox);
      final timestamp = box.get('timestamp') as int?;
      if (timestamp == null) return null;

      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cachedTime) > _cacheExpiry) {
        return null;
      }

      final data = box.get('data');
      if (data == null) return null;
      // Явное преобразование LinkedMap в Map
      if (data is List) {
        return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Employees cache
  Future<void> cacheEmployees(List<Map<String, dynamic>> employees) async {
    if (!_initialized) await init();
    try {
      final box = Hive.box(_employeesBox);
      await box.put('data', employees);
      await box.put('timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      _logger.e('Cache employees error: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> getCachedEmployees() async {
    if (!_initialized) await init();
    try {
      final box = Hive.box(_employeesBox);
      final timestamp = box.get('timestamp') as int?;
      if (timestamp == null) return null;

      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cachedTime) > _cacheExpiry) {
        return null;
      }

      final data = box.get('data');
      if (data == null) return null;
      // Явное преобразование LinkedMap в Map
      if (data is List) {
        return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Districts cache
  Future<void> cacheDistricts(List<Map<String, dynamic>> districts) async {
    if (!_initialized) await init();
    try {
      final box = Hive.box(_districtsBox);
      await box.put('data', districts);
      await box.put('timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      _logger.e('Cache districts error: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> getCachedDistricts() async {
    if (!_initialized) await init();
    try {
      final box = Hive.box(_districtsBox);
      final timestamp = box.get('timestamp') as int?;
      if (timestamp == null) return null;

      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cachedTime) > _cacheExpiry) {
        return null;
      }

      final data = box.get('data');
      if (data == null) return null;
      // Явное преобразование LinkedMap в Map
      if (data is List) {
        return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Clear all cache
  Future<void> clearCache() async {
    if (!_initialized) await init();
    try {
      await Future.wait([
        Hive.box(_categoriesBox).clear(),
        Hive.box(_requestTypesBox).clear(),
        Hive.box(_statusesBox).clear(),
        Hive.box(_employeesBox).clear(),
        Hive.box(_districtsBox).clear(),
        Hive.box(_requestsBox).clear(),
      ]);
      _logger.i('Cache cleared');
    } catch (e) {
      _logger.e('Clear cache error: $e');
    }
  }
}

