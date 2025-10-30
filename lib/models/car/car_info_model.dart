import 'package:gara/models/file/file_info_model.dart';

class CarInfo {
  final int id;
  final int userId;
  final String typeCar;
  final String yearModel;
  final String vehicleLicensePlate;
  final String? description;
  final int status;
  final FileInfo? files;
  final List<FileInfo>? listFiles;

  const CarInfo({
    required this.id,
    required this.userId,
    required this.typeCar,
    required this.yearModel,
    required this.vehicleLicensePlate,
    this.description,
    required this.status,
    this.files,
    this.listFiles,
  });

  factory CarInfo.fromJson(Map<String, dynamic> json) {
    return CarInfo(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id'] ?? json['userId']),
      typeCar: (json['type_car'] ?? json['typeCar'] ?? '').toString(),
      yearModel: (json['year_model'] ?? json['yearModel'] ?? '').toString(),
      vehicleLicensePlate: (json['vehicle_license_plate'] ?? json['vehicleLicensePlate'] ?? '').toString(),
      description: json['description']?.toString(),
      status: _toInt(json['status']),
      files: _parseFiles(json['files'] ?? json['file'] ?? json['image']),
      listFiles: _parseListFiles(json['files'] ?? json['list_files'] ?? json['listFiles']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type_car': typeCar,
      'year_model': yearModel,
      'vehicle_license_plate': vehicleLicensePlate,
      'description': description,
      'status': status,
      'files': files?.toJson(),
      'listFiles': listFiles?.map((f) => f.toJson()).toList(),
    };
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      return int.tryParse(v) ?? 0;
    }
    return 0;
  }

  static FileInfo? _parseFiles(dynamic v) {
    if (v == null) return null;
    if (v is Map<String, dynamic>) return FileInfo.fromJson(v);
    // Một số API có thể trả về danh sách, lấy phần tử đầu tiên
    if (v is List) {
      final first = v.isNotEmpty ? v.first : null;
      if (first is Map<String, dynamic>) return FileInfo.fromJson(first);
    }
    return null;
  }

  static List<FileInfo>? _parseListFiles(dynamic v) {
    if (v == null) return null;
    if (v is List) {
      return v
          .map((item) {
            if (item is Map<String, dynamic>) {
              return FileInfo.fromJson(item);
            }
            return null;
          })
          .where((item) => item != null)
          .cast<FileInfo>()
          .toList();
    }
    if (v is Map<String, dynamic>) {
      // Nếu chỉ có 1 file, chuyển thành list
      return [FileInfo.fromJson(v)];
    }
    return null;
  }
}
