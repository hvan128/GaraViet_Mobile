import 'package:flutter/material.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/models/request/request_service_model.dart';

class QuotationListScreen extends StatefulWidget {
  final RequestServiceModel request;
  
  const QuotationListScreen({
    super.key,
    required this.request,
  });

  @override
  State<QuotationListScreen> createState() => _QuotationListScreenState();
}

class _QuotationListScreenState extends State<QuotationListScreen> {
  bool _loading = false;

  Future<void> _onRefresh() async {
    setState(() {
      _loading = true;
    });
    
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final quotations = widget.request.listQuotation ?? [];
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            MyHeader(
              title: 'Danh sách báo giá',
              showLeftButton: true,
              onLeftPressed: () => Navigator.pop(context),
            ),
             Expanded(
               child: RefreshIndicator(
                 onRefresh: _onRefresh,
                 child: quotations.isEmpty
                     ? _buildEmptyState()
                     : ListView.separated(
                         padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
                         itemCount: quotations.length,
                         separatorBuilder: (_, __) => const SizedBox(height: 12),
                         itemBuilder: (context, index) {
                           final quotation = quotations[index];
                           return _buildQuotationCard(quotation);
                         },
                       ),
               ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_loading) ...[
                  const CircularProgressIndicator(),
                ] else ...[
                  SvgIcon(
                    svgPath: 'assets/icons_final/document-text.svg',
                    size: 64,
                    color: DesignTokens.gray400,
                  ),
                  const SizedBox(height: 16),
                  MyText(
                    text: 'Chưa có báo giá nào',
                    textStyle: 'head',
                    textSize: '18',
                    textColor: 'secondary',
                  ),
                  const SizedBox(height: 8),
                  MyText(
                    text: 'Các gara sẽ gửi báo giá cho yêu cầu của bạn',
                    textStyle: 'body',
                    textSize: '14',
                    textColor: 'tertiary',
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuotationCard(Quotation quotation) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.borderSecondary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Tên gara và trạng thái
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        text: 'Gara ABC', // TODO: Lấy tên gara từ API
                        textStyle: 'head',
                        textSize: '16',
                        textColor: 'primary',
                      ),
                      const SizedBox(height: 4),
                      MyText(
                        text: 'Báo giá #${quotation.id}',
                        textStyle: 'body',
                        textSize: '12',
                        textColor: 'tertiary',
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(quotation.status),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusBorderColor(quotation.status),
                      width: 1,
                    ),
                  ),
                  child: MyText(
                    text: _getStatusText(quotation.status),
                    textStyle: 'title',
                    textSize: '12',
                    color: _getStatusTextColor(quotation.status),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Giá và bảo hành
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        text: 'Giá dịch vụ',
                        textStyle: 'body',
                        textSize: '12',
                        textColor: 'tertiary',
                      ),
                      const SizedBox(height: 4),
                      MyText(
                        text: '${quotation.price.toString().replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]},',
                        )} VNĐ',
                        textStyle: 'head',
                        textSize: '18',
                        textColor: 'brand',
                      ),
                    ],
                  ),
                ),
                if (quotation.warranty.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          text: 'Bảo hành',
                          textStyle: 'body',
                          textSize: '12',
                          textColor: 'tertiary',
                        ),
                        const SizedBox(height: 4),
                        MyText(
                          text: quotation.warranty,
                          textStyle: 'body',
                          textSize: '14',
                          textColor: 'primary',
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            
            // Mô tả
            if (quotation.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              MyText(
                text: 'Mô tả',
                textStyle: 'body',
                textSize: '12',
                textColor: 'tertiary',
              ),
              const SizedBox(height: 4),
              MyText(
                text: quotation.description,
                textStyle: 'body',
                textSize: '14',
                textColor: 'secondary',
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Thời gian và nút hành động
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      SvgIcon(
                        svgPath: 'assets/icons_final/clock.svg',
                        size: 16,
                        color: DesignTokens.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      MyText(
                        text: quotation.createdAt
                            .replaceFirst('T', ' ')
                            .split('.')
                            .first,
                        textStyle: 'body',
                        textSize: '12',
                        textColor: 'tertiary',
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    MyButton(
                      text: 'Từ chối',
                      width: 80,
                      height: 32,
                      textStyle: 'label',
                      textSize: '12',
                      textColor: 'primary',
                      buttonType: ButtonType.secondary,
                      onPressed: () {
                        // TODO: Implement reject quotation
                      },
                    ),
                    const SizedBox(width: 8),
                    MyButton(
                      text: 'Chấp nhận',
                      width: 80,
                      height: 32,
                      textStyle: 'label',
                      textSize: '12',
                      textColor: 'white',
                      buttonType: ButtonType.primary,
                      onPressed: () {
                        // TODO: Implement accept quotation
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return 'Chờ phản hồi';
      case 2:
        return 'Đã chấp nhận';
      case 3:
        return 'Đã từ chối';
      case 4:
        return 'Hoàn thành';
      default:
        return 'Không xác định';
    }
  }

  Color _getStatusBgColor(int status) {
    switch (status) {
      case 1:
        return DesignTokens.primaryBlue4;
      case 2:
        return const Color(0xFFF5FFF8);
      case 3:
        return const Color(0xFFFFEAEA);
      case 4:
        return const Color(0xFFF5FFF8);
      default:
        return DesignTokens.gray400;
    }
  }

  Color _getStatusTextColor(int status) {
    switch (status) {
      case 1:
        return DesignTokens.textBrand;
      case 2:
        return DesignTokens.secondaryGreen;
      case 3:
        return DesignTokens.secondaryOrange;
      case 4:
        return DesignTokens.secondaryGreen;
      default:
        return DesignTokens.textPrimary;
    }
  }

  Color _getStatusBorderColor(int status) {
    switch (status) {
      case 1:
        return DesignTokens.borderBrandPrimary;
      case 2:
        return DesignTokens.secondaryGreen;
      case 3:
        return DesignTokens.secondaryOrange;
      case 4:
        return DesignTokens.secondaryGreen;
      default:
        return DesignTokens.borderBrandPrimary;
    }
  }

}
