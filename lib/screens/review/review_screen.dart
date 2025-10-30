import 'package:flutter/material.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/widgets/app_dialog.dart';
import 'package:gara/widgets/app_toast.dart';
import 'package:gara/widgets/text_field.dart';
import 'package:gara/services/review/review_service.dart';

class ReviewScreen extends StatefulWidget {
  final int quotationId;
  final String garageName;
  final String serviceName;
  final String serviceDescription;

  const ReviewScreen({
    super.key,
    required this.quotationId,
    required this.garageName,
    required this.serviceName,
    required this.serviceDescription,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _selectedRating = 5; // Mặc định 5 sao
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  final List<String> _commentOptions = const [
    'Hoàn toàn tuyệt vời',
    'Dịch vụ tốt',
    'Bình thường',
    'Cần cải thiện',
  ];
  final Set<String> _selectedComments = <String>{};

  @override
  void initState() {
    super.initState();
    // Không đặt giá trị sẵn; chỉ hiển thị theo tùy chọn đã chọn
    _commentController.text = '';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _onRatingChanged(int rating) {
    setState(() {
      _selectedRating = rating;
    });
  }

  Future<void> _submitReview() async {
    final String freeText = _commentController.text.trim();
    final String optionText = _selectedComments.join(', ').trim();
    if (_selectedComments.isEmpty && freeText.isEmpty) {
      AppToastHelper.showError(context, message: 'Vui lòng nhập hoặc chọn nội dung đánh giá');
      return;
    }
    // Hiển thị dialog xác nhận
    final bool? confirmed = await AppDialogHelper.confirm(
      context,
      title: 'Xác nhận đánh giá',
      message: 'Bạn có chắc chắn muốn gửi đánh giá này không?',
      confirmText: 'Gửi',
      cancelText: 'Hủy',
      type: AppDialogType.info,
      confirmButtonType: ButtonType.primary,
      showIconHeader: true,
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final String combinedComment = [optionText, freeText].where((e) => e.isNotEmpty).join(' - ');

      final response = await ReviewService.createReview(
        quotationId: widget.quotationId,
        starRating: _selectedRating.toDouble(),
        comment: combinedComment,
      );

      if (response['success'] == true) {
        if (mounted) {
          AppToastHelper.showSuccess(context, message: 'Đánh giá thành công!');
          // Quay lại và báo cho màn trước biết cần reload
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          AppToastHelper.showError(context, message: response['message'] ?? 'Có lỗi xảy ra');
        }
      }
    } catch (e) {
      if (mounted) {
        AppToastHelper.showError(context, message: 'Lỗi: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.surfaceSecondary,
      body: SafeArea(
        child: Column(
          children: [
            MyHeader(
              title: 'Đánh giá',
              showLeftButton: true,
              showRightButton: false,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thông tin dịch vụ
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DesignTokens.surfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DesignTokens.borderSecondary),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText(
                            text: widget.garageName,
                            textStyle: 'title',
                            textSize: '18',
                            textColor: 'primary',
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              MyText(
                                text: 'Đơn hàng: ',
                                textStyle: 'body',
                                textSize: '14',
                                textColor: 'tertiary',
                              ),
                              MyText(
                                text: widget.serviceName,
                                textStyle: 'body',
                                textSize: '14',
                                textColor: 'primary',
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              MyText(
                                text: 'Mô tả: ',
                                textStyle: 'body',
                                textSize: '14',
                                textColor: 'tertiary',
                              ),
                              MyText(
                                text: widget.serviceDescription,
                                textStyle: 'body',
                                textSize: '14',
                                textColor: 'primary',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tiêu đề đánh giá
                    MyText(
                      text: 'Đánh giá trải nghiệm dịch vụ',
                      textStyle: 'title',
                      textSize: '18',
                      textColor: 'primary',
                    ),
                    const SizedBox(height: 8),

                    // Rating stars
                    Row(
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () => _onRatingChanged(index + 1),
                          child: Padding(
                            padding: EdgeInsets.only(right: index < 4 ? 4 : 0),
                            child: SvgIcon(
                              svgPath: index < _selectedRating
                                  ? 'assets/icons_final/star.svg'
                                  : 'assets/icons_final/star_outline.svg',
                              size: 24,
                              color: index < _selectedRating ? Colors.amber : DesignTokens.textTertiary,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Tùy chọn nội dung đánh giá
                    MyText(
                      text: 'Còn gì khác không?',
                      textStyle: 'body',
                      textSize: '14',
                      textColor: 'tertiary',
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _commentOptions.map((option) {
                        final bool isSelected = _selectedComments.contains(option);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedComments.remove(option);
                              } else {
                                _selectedComments.add(option);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? DesignTokens.primaryBlue2 : DesignTokens.surfacePrimary,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? DesignTokens.primaryBlue : DesignTokens.borderSecondary,
                              ),
                            ),
                            child: MyText(
                              text: option,
                              textStyle: 'label',
                              textSize: '14',
                              textColor: isSelected ? 'invert' : 'primary',
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Trường nhập nội dung bổ sung (tùy chọn)
                    MyTextField(
                      controller: _commentController,
                      hintText: 'Nhập nội dung đánh giá...',
                      obscureText: false,
                      hasError: false,
                      minLines: 4,
                      maxLines: 4,
                      height: 144,
                      backgroundColor: DesignTokens.surfacePrimary,
                      borderColor: DesignTokens.borderSecondary,
                      enabled: true,
                    ),
                  ],
                ),
              ),
            ),

            // Nút gửi
            Padding(
              padding: const EdgeInsets.all(20),
              child: MyButton(
                text: _isSubmitting ? 'Đang gửi...' : 'Gửi',
                onPressed: _isSubmitting ? null : _submitReview,
                buttonType: ButtonType.primary,
                height: 48,
                textStyle: 'label',
                textSize: '16',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
