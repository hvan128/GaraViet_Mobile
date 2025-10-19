import 'package:gara/config.dart';
import 'package:gara/services/api/auth_http_client.dart';

class NotificationService {
  /// Fetch danh sách thông báo (raw JSON) để phục vụ tạo model sau
  static Future<Map<String, dynamic>> fetchList({
    int page = 1,
    int perPage = 20,
    String? status, // '1' chưa đọc, '2' đã đọc
    String? type,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }
    if (type != null && type.isNotEmpty) {
      query['type'] = type;
    }

    return await AuthHttpClient.get(
      Config.notificationListUrl,
      queryParams: query,
      includeAuth: true,
    );
  }
}



