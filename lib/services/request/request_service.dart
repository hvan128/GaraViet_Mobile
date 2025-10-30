import 'package:gara/services/api/base_api_service.dart';
import 'package:gara/models/request/request_service_model.dart';

class RequestServiceApi {
  static Future<RequestListResponse> getAllRequests({
    int pageNum = 1,
    int pageSize = 10,
    int? status,
    String? dateFrom,
    String? dateTo,
    String? search,
  }) async {
    final queryParams = <String, String>{'pagenum': pageNum.toString(), 'pagesize': pageSize.toString()};

    if (status != null) {
      queryParams['status'] = status.toString();
    }
    if (dateFrom != null && dateFrom.isNotEmpty) {
      queryParams['date_from'] = dateFrom;
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      queryParams['date_to'] = dateTo;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await BaseApiService.get('/manager-request/get-all-requests', queryParams: queryParams);

    final dynamic data = response['data'];

    if (data is Map<String, dynamic>) {
      final requestResponse = RequestListResponse.fromJson(data);
      return requestResponse;
    }

    // Fallback: return empty response
    return const RequestListResponse(
      requests: [],
      pagination: PaginationInfo(currentPage: 1, perPage: 10, total: 0, totalPages: 0),
    );
  }

  static Future<RequestListResponse> getAllRequestsForGarage({
    int pageNum = 1,
    int pageSize = 10,
    int? status,
    String? dateFrom,
    String? dateTo,
    String? search,
    int? userId,
  }) async {
    final queryParams = <String, String>{'pagenum': pageNum.toString(), 'pagesize': pageSize.toString()};

    if (status != null) {
      queryParams['status'] = status.toString();
    }
    if (dateFrom != null && dateFrom.isNotEmpty) {
      queryParams['date_from'] = dateFrom;
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      queryParams['date_to'] = dateTo;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (userId != null) {
      queryParams['user_id'] = userId.toString();
    }

    final response = await BaseApiService.get('/manager-request/get-all-requests-garage', queryParams: queryParams);

    // Response shape: { data: { requests: [], pagination: {} } }
    final dynamic data = response['data'];

    if (data is Map<String, dynamic>) {
      final requestResponse = RequestListResponse.fromJson(data);
      return requestResponse;
    }

    // Fallback: return empty response
    return const RequestListResponse(
      requests: [],
      pagination: PaginationInfo(currentPage: 1, perPage: 10, total: 0, totalPages: 0),
    );
  }

  // Garages in radius
  static Future<Map<String, dynamic>> getGaragesInRadius({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final response = await BaseApiService.post(
      '/manager-request/garages-in-radius',
      body: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radiusKm,
      },
    );
    return response;
  }
}
