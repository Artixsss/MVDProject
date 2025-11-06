import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

/// API Service Provider (Singleton)
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// Cache Service Provider (Singleton)
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

/// Categories Provider with caching
final categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final cache = ref.read(cacheServiceProvider);

  // Try cache first
  final cached = await cache.getCachedCategories();
  if (cached != null && cached.isNotEmpty) {
    return cached;
  }

  // Fetch from API
  final categories = await api.getCategories();
  if (categories.isNotEmpty) {
    await cache.cacheCategories(categories);
  }
  return categories;
});

/// Request Types Provider with caching
final requestTypesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final cache = ref.read(cacheServiceProvider);

  final cached = await cache.getCachedRequestTypes();
  if (cached != null && cached.isNotEmpty) {
    return cached;
  }

  final types = await api.getRequestTypes();
  if (types.isNotEmpty) {
    await cache.cacheRequestTypes(types);
  }
  return types;
});

/// Request Statuses Provider with caching
final requestStatusesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final cache = ref.read(cacheServiceProvider);

  final cached = await cache.getCachedStatuses();
  if (cached != null && cached.isNotEmpty) {
    return cached;
  }

  final statuses = await api.getRequestStatuses();
  if (statuses.isNotEmpty) {
    await cache.cacheStatuses(statuses);
  }
  return statuses;
});

/// Employees Provider with caching
final employeesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final cache = ref.read(cacheServiceProvider);

  final cached = await cache.getCachedEmployees();
  if (cached != null && cached.isNotEmpty) {
    return cached;
  }

  final employees = await api.getEmployees();
  if (employees.isNotEmpty) {
    await cache.cacheEmployees(employees);
  }
  return employees;
});

/// Districts Provider with caching
final districtsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final cache = ref.read(cacheServiceProvider);

  final cached = await cache.getCachedDistricts();
  if (cached != null && cached.isNotEmpty) {
    return cached;
  }

  final districts = await api.getDistricts();
  if (districts.isNotEmpty) {
    await cache.cacheDistricts(districts);
  }
  return districts;
});

