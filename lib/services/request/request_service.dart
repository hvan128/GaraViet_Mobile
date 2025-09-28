import 'package:gara/services/api/base_api_service.dart';
import 'package:gara/models/request/request_service_model.dart';
import 'package:flutter/foundation.dart';

class RequestServiceApi {
  static Future<RequestListResponse> getAllRequests({
    int pageNum = 1,
    int pageSize = 10,
    int? status,
    String? dateFrom,
    String? dateTo,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'pagenum': pageNum.toString(),
      'pagesize': pageSize.toString(),
    };

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

    final response = await BaseApiService.get(
      '/manager-request/get-all-requests',
      queryParams: queryParams,
    );
    debugPrint('[RequestServiceApi.getAllRequests] queryParams=$queryParams');
    debugPrint('[RequestServiceApi.getAllRequests] rawResponse=$response');

    // Response shape: { data: { requests: [], pagination: {} } }
    final dynamic data = response['data'];
    debugPrint('[RequestServiceApi.getAllRequests] data=$data');
    
    if (data is Map<String, dynamic>) {
      final requestResponse = RequestListResponse.fromJson(data);
      debugPrint('[RequestServiceApi.getAllRequests] parsedItems=${requestResponse.requests.length}, pagination=${requestResponse.pagination.total}');
      debugPrint('[RequestServiceApi.getAllRequests] requests=${requestResponse.requests.map((r) => 'id:${r.id}, status:${r.status}, code:${r.requestCode}').toList()}');
      return requestResponse;
    }

    // Fallback: return empty response
    return const RequestListResponse(
      requests: [],
      pagination: PaginationInfo(
        currentPage: 1,
        perPage: 10,
        total: 0,
        totalPages: 0,
      ),
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
    final queryParams = <String, String>{
      'pagenum': pageNum.toString(),
      'pagesize': pageSize.toString(),
    };

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

    final response = await BaseApiService.get(
      '/manager-request/get-all-requests-garage',
      queryParams: queryParams,
    );
    debugPrint('[RequestServiceApi.getAllRequestsForGarage] queryParams=$queryParams');
    debugPrint('[RequestServiceApi.getAllRequestsForGarage] rawResponse=$response');

    // Response shape: { data: { requests: [], pagination: {} } }
    final dynamic data = response['data'];
    debugPrint('[RequestServiceApi.getAllRequestsForGarage] data=$data');
    
    if (data is Map<String, dynamic>) {
      final requestResponse = RequestListResponse.fromJson(data);
      debugPrint('[RequestServiceApi.getAllRequestsForGarage] parsedItems=${requestResponse.requests.length}, pagination=${requestResponse.pagination.total}');
      debugPrint('[RequestServiceApi.getAllRequestsForGarage] requests=${requestResponse.requests.map((r) => 'id:${r.id}, status:${r.status}, code:${r.requestCode}').toList()}');
      return requestResponse;
    }

    // Fallback: return empty response
    return const RequestListResponse(
      requests: [],
      pagination: PaginationInfo(
        currentPage: 1,
        perPage: 10,
        total: 0,
        totalPages: 0,
      ),
    );
  }
}


