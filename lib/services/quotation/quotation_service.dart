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
}
