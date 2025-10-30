import 'package:gara/config.dart';
import 'package:gara/services/auth/token_cache.dart';
import 'package:gara/services/api/base_api_service.dart';
import 'package:gara/models/review/garage_review_response_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReviewService {
  static Future<Map<String, dynamic>> createReview({
    required int quotationId,
    required double starRating,
    required String comment,
  }) async {
    try {
      final token = TokenCache.getAccessToken();
      if (token == null) {
        throw Exception('Token không tồn tại');
      }

      final url = Uri.parse('${Config.baseUrl}/review/create');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = {
        'quotation_id': quotationId,
        'star_rating': starRating,
        'comment': comment,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Có lỗi xảy ra khi tạo đánh giá');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  /// Lấy danh sách đánh giá của một garage
  static Future<GarageReviewResponse?> getReviewsByGarage(int garageId) async {
    try {
      final response = await BaseApiService.get(
        '/review/by-garage',
        queryParams: {'garage_id': garageId.toString()},
      );

      if (response['success'] == true && response['data'] != null) {
        return GarageReviewResponse.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Có lỗi xảy ra khi lấy danh sách đánh giá');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }
}
