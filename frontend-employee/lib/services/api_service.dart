import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../models/user_session.dart';
import '../models/citizen_request.dart';
import '../utils/constants.dart';
import 'cache_service.dart';

/// Modern API Service using Dio (2025 best practices)
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );

  final CacheService _cache = CacheService();

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.addAll([
      _AuthInterceptor(),
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    ]);
  }

  // Auth methods
  Future<UserSession> getCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson == null) throw Exception('No active session');
    return UserSession.fromJson(jsonDecode(userJson));
  }

  Future<UserSession> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/employee-login',
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final json = response.data as Map<String, dynamic>;
        final session = UserSession.fromJson(json);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(session.toJson()));
        _logger.i('User logged in: ${session.username}');
        return session;
      }
      throw DioException(
        requestOptions: RequestOptions(path: '/api/auth/employee-login'),
        response: response,
        message: 'Login failed',
      );
    } on DioException catch (e) {
      _logger.e('Login error: ${e.message}');
      rethrow;
    }
  }

  // Citizen Requests
  Future<List<CitizenRequestDto>> getCitizenRequests({
    int? categoryId,
    int? districtId,
    int? statusId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (districtId != null) queryParams['districtId'] = districtId;
      if (statusId != null) queryParams['statusId'] = statusId;

      final response = await _dio.get(
        '/api/citizenrequests',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        _logger.d('GetCitizenRequests response: ${data.runtimeType}');

        if (data is List) {
          _logger.d('Found ${data.length} requests');
          final requests = data
              .map((e) {
                try {
                  return CitizenRequestDto.fromJson(e as Map<String, dynamic>);
                } catch (parseError) {
                  _logger.e('Error parsing request: $parseError | Data: $e');
                  return null;
                }
              })
              .whereType<CitizenRequestDto>()
              .toList();
          _logger.d('Successfully parsed ${requests.length} requests');
          return requests;
        } else {
          _logger.w('Unexpected response type: ${data.runtimeType}');
          return [];
        }
      }
      _logger.w('Unexpected status code: ${response.statusCode}');
      return [];
    } on DioException catch (e) {
      _logger.e(
        'Get requests error: ${e.message} | Status: ${e.response?.statusCode}',
      );
      if (e.response?.statusCode == 404) {
        _logger.d('No requests found (404)');
        return [];
      }
      rethrow;
    } catch (e) {
      _logger.e('Unexpected error in getCitizenRequests: $e');
      rethrow;
    }
  }

  Future<CitizenRequestDto> getRequestById(int id) async {
    try {
      final response = await _dio.get('/api/citizenrequests/$id');

      if (response.statusCode == 200) {
        return CitizenRequestDto.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw Exception('Обращение с ID $id не найдено');
    } on DioException catch (e) {
      _logger.e('Get request by id error: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Обращение с ID $id не найдено');
      }
      throw Exception('Не удалось загрузить обращение: ${e.message}');
    }
  }

  Future<CitizenRequestDto> createRequest(CreateCitizenRequestDto dto) async {
    try {
      final response = await _dio.post(
        '/api/citizenrequests',
        data: {
          'citizenId': dto.citizenId,
          'requestTypeId': dto.requestTypeId,
          'categoryId': dto.categoryId,
          'description': dto.description,
          'acceptedById': dto.acceptedById,
          'assignedToId': dto.assignedToId,
          'incidentTime': dto.incidentTime,
          'incidentLocation': dto.incidentLocation,
          'citizenLocation': dto.citizenLocation,
          'requestStatusId': dto.requestStatusId,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return CitizenRequestDto.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw Exception('Ошибка создания обращения');
    } on DioException catch (e) {
      _logger.e('Create request error: ${e.message}');
      throw Exception('Не удалось создать обращение: ${e.message}');
    }
  }

  Future<void> updateStatus(int id, int statusId) async {
    try {
      await _dio.patch(
        '/api/citizenrequests/$id/status',
        data: {'requestStatusId': statusId},
      );
    } on DioException catch (e) {
      _logger.e('Update status error: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Обращение не найдено');
      }
      throw Exception('Не удалось обновить статус: ${e.message}');
    }
  }

  Future<void> assignRequest(int id, int assignedToId) async {
    try {
      await _dio.patch(
        '/api/citizenrequests/$id/assign',
        data: {'assignedToId': assignedToId},
      );
    } on DioException catch (e) {
      _logger.e('Assign request error: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Обращение не найдено');
      }
      throw Exception('Не удалось назначить исполнителя: ${e.message}');
    }
  }

  Future<void> reclassifyAi(int id) async {
    try {
      await _dio.patch('/api/citizenrequests/$id/reclassify');
    } on DioException catch (e) {
      _logger.e('Reclassify AI error: ${e.message}');
      throw Exception('Не удалось пересчитать AI: ${e.message}');
    }
  }

  Future<void> correctAiCategory(int id, String category) async {
    try {
      await _dio.patch(
        '/api/citizenrequests/$id/correct-category',
        data: '"$category"', // JSON строка в кавычках
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
    } on DioException catch (e) {
      _logger.e('Correct AI category error: ${e.message}');
      _logger.e('Response data: ${e.response?.data}');
      throw Exception('Не удалось скорректировать категорию: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> checkRequestStatus(String requestNumber) async {
    try {
      final response = await _dio.get(
        '/api/citizenrequests/check/$requestNumber',
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _logger.e('Check status error: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Обращение не найдено');
      }
      throw Exception('Не удалось проверить статус: ${e.message}');
    }
  }

  Future<CitizenRequestDto> getRequestByNumber(String requestNumber) async {
    try {
      final response = await _dio.get(
        '/api/citizenrequests/by-number/$requestNumber',
      );
      return CitizenRequestDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _logger.e('Get request by number error: ${e.message}');
      throw Exception('Обращение не найдено: ${e.message}');
    }
  }

  // Analytics
  Future<List<Map<String, dynamic>>> getCategoryStats() async {
    try {
      final response = await _dio.get('/api/analytics/categories');
      return (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .toList();
    } on DioException catch (e) {
      _logger.e('Get category stats error: ${e.message}');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDistrictStats() async {
    try {
      final response = await _dio.get('/api/analytics/districts');
      return (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .toList();
    } on DioException catch (e) {
      _logger.e('Get district stats error: ${e.message}');
      return [];
    }
  }

  Future<Map<String, dynamic>> getAiStats() async {
    try {
      final response = await _dio.get('/api/analytics/ai');
      _logger.d('AI stats response: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _logger.e(
        'Get AI stats error: ${e.message} | Status: ${e.response?.statusCode}',
      );
      if (e.response?.statusCode == 500) {
        _logger.e('Server error details: ${e.response?.data}');
      }
      return {};
    } catch (e) {
      _logger.e('Unexpected error in getAiStats: $e');
      return {};
    }
  }

  // Lookups with caching
  Future<List<Map<String, dynamic>>> getCategories({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _cache.getCachedCategories();
      if (cached != null && cached.isNotEmpty) {
        _logger.d('Using cached categories');
        return cached;
      }
    }

    try {
      final response = await _dio.get('/api/categories');
      final categories = (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .toList();

      if (categories.isNotEmpty) {
        await _cache.cacheCategories(categories);
      }
      return categories;
    } on DioException catch (e) {
      _logger.e('Get categories error: ${e.message}');
      // Return cached data if available even on error
      final cached = await _cache.getCachedCategories();
      return cached ?? [];
    }
  }

  Future<List<Map<String, dynamic>>> getRequestTypes({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _cache.getCachedRequestTypes();
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    try {
      final response = await _dio.get('/api/requesttypes');
      final types = (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .toList();

      if (types.isNotEmpty) {
        await _cache.cacheRequestTypes(types);
      }
      return types;
    } on DioException catch (e) {
      _logger.e('Get request types error: ${e.message}');
      final cached = await _cache.getCachedRequestTypes();
      return cached ?? [];
    }
  }

  Future<List<Map<String, dynamic>>> getRequestStatuses({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _cache.getCachedStatuses();
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    try {
      final response = await _dio.get('/api/requeststatuses');
      final statuses = (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .toList();

      if (statuses.isNotEmpty) {
        await _cache.cacheStatuses(statuses);
      }
      return statuses;
    } on DioException catch (e) {
      _logger.e('Get request statuses error: ${e.message}');
      final cached = await _cache.getCachedStatuses();
      return cached ?? [];
    }
  }

  Future<List<Map<String, dynamic>>> getEmployees({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _cache.getCachedEmployees();
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    try {
      final response = await _dio.get('/api/employees');
      final employees = (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .toList();

      if (employees.isNotEmpty) {
        await _cache.cacheEmployees(employees);
      }
      return employees;
    } on DioException catch (e) {
      _logger.e('Get employees error: ${e.message}');
      final cached = await _cache.getCachedEmployees();
      return cached ?? [];
    }
  }

  Future<List<Map<String, dynamic>>> getDistricts({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _cache.getCachedDistricts();
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    try {
      final response = await _dio.get('/api/districts');
      final districts = (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .toList();

      if (districts.isNotEmpty) {
        await _cache.cacheDistricts(districts);
      }
      return districts;
    } on DioException catch (e) {
      _logger.e('Get districts error: ${e.message}');
      final cached = await _cache.getCachedDistricts();
      return cached ?? [];
    }
  }

  // CRUD Operations
  Future<Map<String, dynamic>> createCategory(String name) async {
    try {
      final response = await _dio.post('/api/categories', data: {'name': name});
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _logger.e('Create category error: ${e.message}');
      throw Exception('Не удалось создать категорию: ${e.message}');
    }
  }

  Future<void> updateCategory(int id, String name) async {
    try {
      await _dio.put('/api/categories/$id', data: {'name': name});
    } on DioException catch (e) {
      _logger.e('Update category error: ${e.message}');
      throw Exception('Не удалось обновить категорию: ${e.message}');
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _dio.delete('/api/categories/$id');
    } on DioException catch (e) {
      _logger.e('Delete category error: ${e.message}');
      throw Exception('Не удалось удалить категорию: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> createRequestType(String name) async {
    try {
      final response = await _dio.post(
        '/api/requesttypes',
        data: {'name': name},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _logger.e('Create request type error: ${e.message}');
      throw Exception('Не удалось создать тип обращения: ${e.message}');
    }
  }

  Future<void> updateRequestType(int id, String name) async {
    try {
      await _dio.put('/api/requesttypes/$id', data: {'name': name});
    } on DioException catch (e) {
      _logger.e('Update request type error: ${e.message}');
      throw Exception('Не удалось обновить тип обращения: ${e.message}');
    }
  }

  Future<void> deleteRequestType(int id) async {
    try {
      await _dio.delete('/api/requesttypes/$id');
    } on DioException catch (e) {
      _logger.e('Delete request type error: ${e.message}');
      throw Exception('Не удалось удалить тип обращения: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> createRequestStatus(String name) async {
    try {
      final response = await _dio.post(
        '/api/requeststatuses',
        data: {'name': name},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _logger.e('Create request status error: ${e.message}');
      throw Exception('Не удалось создать статус: ${e.message}');
    }
  }

  Future<void> updateRequestStatus(int id, String name) async {
    try {
      await _dio.put('/api/requeststatuses/$id', data: {'name': name});
    } on DioException catch (e) {
      _logger.e('Update request status error: ${e.message}');
      throw Exception('Не удалось обновить статус: ${e.message}');
    }
  }

  Future<void> deleteRequestStatus(int id) async {
    try {
      await _dio.delete('/api/requeststatuses/$id');
    } on DioException catch (e) {
      _logger.e('Delete request status error: ${e.message}');
      throw Exception('Не удалось удалить статус: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> createEmployee(
    String lastName,
    String firstName,
    String? patronymic,
  ) async {
    try {
      final response = await _dio.post(
        '/api/employees',
        data: {
          'lastName': lastName,
          'firstName': firstName,
          'patronymic': patronymic ?? '',
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _logger.e('Create employee error: ${e.message}');
      throw Exception('Не удалось создать сотрудника: ${e.message}');
    }
  }

  Future<void> updateEmployee(
    int id,
    String lastName,
    String firstName,
    String? patronymic,
  ) async {
    try {
      await _dio.put(
        '/api/employees/$id',
        data: {
          'lastName': lastName,
          'firstName': firstName,
          'patronymic': patronymic ?? '',
        },
      );
    } on DioException catch (e) {
      _logger.e('Update employee error: ${e.message}');
      throw Exception('Не удалось обновить сотрудника: ${e.message}');
    }
  }

  Future<void> deleteEmployee(int id) async {
    try {
      await _dio.delete('/api/employees/$id');
    } on DioException catch (e) {
      _logger.e('Delete employee error: ${e.message}');
      throw Exception('Не удалось удалить сотрудника: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> createDistrict(String name) async {
    try {
      final response = await _dio.post('/api/districts', data: {'name': name});
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _logger.e('Create district error: ${e.message}');
      throw Exception('Не удалось создать район: ${e.message}');
    }
  }

  Future<void> updateDistrict(int id, String name) async {
    try {
      await _dio.put('/api/districts/$id', data: {'name': name});
    } on DioException catch (e) {
      _logger.e('Update district error: ${e.message}');
      throw Exception('Не удалось обновить район: ${e.message}');
    }
  }

  Future<void> deleteDistrict(int id) async {
    try {
      await _dio.delete('/api/districts/$id');
    } on DioException catch (e) {
      _logger.e('Delete district error: ${e.message}');
      throw Exception('Не удалось удалить район: ${e.message}');
    }
  }

  // Citizen search
  Future<List<Map<String, dynamic>>> searchCitizens(String query) async {
    try {
      final response = await _dio.get(
        '/api/citizens/search',
        queryParameters: {'q': query},
      );
      return (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .toList();
    } on DioException catch (e) {
      _logger.e('Search citizens error: ${e.message}');
      return [];
    }
  }

  // Address search
  Future<List<Map<String, dynamic>>> searchAddress(String query) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': 1,
          'limit': 10,
        },
        options: Options(headers: {'User-Agent': 'MVD-Frontend-App'}),
      );
      return (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .toList();
    } on DioException catch (e) {
      _logger.e('Search address error: ${e.message}');
      return [];
    }
  }

  // Submit new request (for citizens)
  Future<CitizenRequestDto> submitNewRequest({
    required String firstName,
    required String lastName,
    required String middleName,
    required String phone,
    required int requestTypeId,
    required int categoryId,
    required String description,
    required String incidentLocation,
    required String citizenLocation,
    required DateTime incidentTime,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _dio.post(
        '/api/citizenrequests/submit',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'middleName': middleName,
          'phone': phone,
          'requestTypeId': requestTypeId,
          'categoryId': categoryId,
          'description': description,
          'incidentLocation': incidentLocation,
          'citizenLocation': citizenLocation,
          'incidentTime': incidentTime.toIso8601String(),
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      return CitizenRequestDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _logger.e('Submit new request error: ${e.message}');
      throw Exception('Не удалось подать обращение: ${e.message}');
    }
  }

  // Геттер для доступа к Dio (для прямых запросов)
  Dio get dio => _dio;
}

/// Auth interceptor to add token to requests
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson != null) {
        // Add auth token if needed in future
        // options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      // Ignore errors
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401, 403 errors globally
    if (err.response?.statusCode == 401) {
      // Handle unauthorized
    }
    handler.next(err);
  }
}
