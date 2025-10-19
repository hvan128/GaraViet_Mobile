import 'package:gara/services/api/base_api_service.dart';
import 'package:gara/models/quotation/quotation_model.dart';
import 'package:flutter/foundation.dart';

class QuotationServiceApi {
  /// Tạo báo giá mới cho yêu cầu dịch vụ
  static Future<CreateQuotationResponse> createQuotation({
    required int requestServiceId,
    required int price,
    required String description,
  }) async {
    try {
      final request = CreateQuotationRequest(
        requestServiceId: requestServiceId,
        price: price,
        description: description,
      );

      debugPrint('[QuotationServiceApi.createQuotation] request=${request.toJson()}');

      final response = await BaseApiService.post(
        '/manager-quotation/create-quotation',
        body: request.toJson(),
      );

      debugPrint('[QuotationServiceApi.createQuotation] rawResponse=$response');

      final createResponse = CreateQuotationResponse.fromJson(response);
      debugPrint('[QuotationServiceApi.createQuotation] success=${createResponse.success}, message=${createResponse.message}');
      return createResponse;
    } catch (e) {
      debugPrint('[QuotationServiceApi.createQuotation] error=$e');
      return CreateQuotationResponse(
        success: false,
        message: 'Error creating quotation: $e',
      );
    }
  }

  /// Cập nhật báo giá hiện có
  static Future<UpdateQuotationResponse> updateQuotation({
    required int quotationId,
    required int price,
    required String description,
    required int status,
  }) async {
    try {
      final body = {
        'quotation_id': quotationId,
        'price': price,
        'description': description,
        'status': status,
      };

      debugPrint('[QuotationServiceApi.updateQuotation] body=$body');

      final response = await BaseApiService.put(
        '/manager-quotation/update-quotation',
        body: body,
      );

      debugPrint('[QuotationServiceApi.updateQuotation] rawResponse=$response');

      final updateResponse = UpdateQuotationResponse.fromJson(response);
      debugPrint('[QuotationServiceApi.updateQuotation] success=${updateResponse.success}, message=${updateResponse.message}');
      return updateResponse;
    } catch (e) {
      debugPrint('[QuotationServiceApi.updateQuotation] error=$e');
      return UpdateQuotationResponse(
        success: false,
        message: 'Error updating quotation: $e',
        data: null,
      );
    }
  }

  /// Lấy danh sách báo giá theo ID yêu cầu dịch vụ
  static Future<QuotationListResponse> getQuotationsByRequestId({
    required int requestServiceId,
    int? status,
    String? dateFrom,
    String? dateTo,
    int? priceMin,
    int? priceMax,
  }) async {
    try {
      final queryParams = <String, String>{
        'request_service_id': requestServiceId.toString(),
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
      if (priceMin != null) {
        queryParams['price_min'] = priceMin.toString();
      }
      if (priceMax != null) {
        queryParams['price_max'] = priceMax.toString();
      }

      debugPrint('[QuotationServiceApi.getQuotationsByRequestId] queryParams=$queryParams');

      final response = await BaseApiService.get(
        '/manager-quotation/get-all-quotations-by-request-service-id',
        queryParams: queryParams,
      );

      debugPrint('[QuotationServiceApi.getQuotationsByRequestId] rawResponse=$response');
      try {
        final dynamic rawData = response['data'];
        if (rawData is List && rawData.isNotEmpty) {
          final first = rawData.first;
          if (first is Map<String, dynamic>) {
            debugPrint('[QuotationServiceApi.getQuotationsByRequestId] firstItem.keys=${first.keys.toList()}');
            debugPrint('[QuotationServiceApi.getQuotationsByRequestId] firstItemSample=$first');
          }
        } else {
          debugPrint('[QuotationServiceApi.getQuotationsByRequestId] data is empty or not a list');
        }
      } catch (e) {
        debugPrint('[QuotationServiceApi.getQuotationsByRequestId] debug parse error: $e');
      }

      final quotationResponse = QuotationListResponse.fromJson(response);
      debugPrint('[QuotationServiceApi.getQuotationsByRequestId] message=${quotationResponse.message}, count=${quotationResponse.data.length}');
      return quotationResponse;
    } catch (e) {
      debugPrint('[QuotationServiceApi.getQuotationsByRequestId] error=$e');
      return QuotationListResponse(
        message: 'Error fetching quotations: $e',
        data: [],
      );
    }
  }
}
