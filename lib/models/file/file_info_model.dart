class FileInfo {
  final int id;
  final String name;
  final String path;
  final String timeUpload;
  final String? fileType; // image, document, etc.
  final int? fileSize; // in bytes
  final String? mimeType;

  const FileInfo({
    required this.id,
    required this.name,
    required this.path,
    required this.timeUpload,
    this.fileType,
    this.fileSize,
    this.mimeType,
  });

  factory FileInfo.fromJson(Map<String, dynamic> json) {
    return FileInfo(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      path: (json['path'] ?? '').toString(),
      timeUpload: (json['time_upload'] ?? json['timeUpload'] ?? '').toString(),
      fileType: json['file_type']?.toString() ?? json['fileType']?.toString(),
      fileSize: _toInt(json['file_size'] ?? json['fileSize']),
      mimeType: json['mime_type']?.toString() ?? json['mimeType']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'time_upload': timeUpload,
      'file_type': fileType,
      'file_size': fileSize,
      'mime_type': mimeType,
    };
  }

  // Helper method to check if file is an image
  bool get isImage {
    if (mimeType != null) {
      return mimeType!.startsWith('image/');
    }
    if (fileType != null) {
      return fileType!.toLowerCase() == 'image';
    }
    // Fallback: check file extension
    final extension = name.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'].contains(extension);
  }

  // Helper method to get file extension
  String get fileExtension {
    return name.toLowerCase().split('.').last;
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      return int.tryParse(v) ?? 0;
    }
    return 0;
  }
}
