import 'package:gara/models/review/review_model.dart';

class Constant {
  static final List<ReviewModel> recentReviews = [
    ReviewModel(
      id: '1',
      userName: 'Quách Tường B',
      userAvatar: null, // Sẽ hiển thị icon mặc định
      serviceName: 'Độ cốp điện VF8',
      comment: 'tuyệt vời sẽ quay lại lần 2',
      rating: 5,
      context: 'Vietnam car',
    ),
    ReviewModel(
      id: '2',
      userName: 'LNB Lâm',
      userAvatar: null,
      serviceName: 'Độ cốp điện VF8',
      comment: 'tuyệt vời sẽ quay lại lần 2',
      rating: 3,
      context: 'Vietnam car',
    ),
    ReviewModel(
      id: '3',
      userName: 'A2 CNTT',
      userAvatar: null,
      serviceName: 'Độ cốp điện VF8',
      comment: 'tuyệt vời sẽ quay lại lần 2',
      rating: 2,
      context: 'Vietnam car',
    ),
  ];

}