import 'package:flutter/material.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/utils/url.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text_field.dart';
import 'package:gara/services/request/request_service.dart';
import 'package:gara/services/quotation/quotation_service.dart';
import 'package:gara/models/request/request_service_model.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/providers/user_provider.dart';
import 'package:provider/provider.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  bool _loading = true;
  bool _loadingMore = false;
  List<RequestServiceModel> _items = [];
  PaginationInfo? _pagination;
  int _currentPage = 1;
  final int _pageSize = 10;

  // Filter states
  int? _selectedStatus;
  String? _searchQuery;

  // Getter for user type
  bool get isGarageUser {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return userProvider.isGarageUser;
  }

  // Handle quotation button press
  void onQuotationPressed(RequestServiceModel item) {
    if (isGarageUser) {
      _showQuotationBottomSheet(item);
    } else {
      Navigator.pushNamed(
        context,
        '/quotation-list',
        arguments: item,
      );
    }
  }

  // Show bottom sheet for garage users
  void _showQuotationBottomSheet(RequestServiceModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuotationBottomSheet(
        item: item,
        onSuccess: () {
          _fetch(refresh: true);
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _items.clear();
    }

    setState(() {
      _loading = refresh || _items.isEmpty;
      _loadingMore = !refresh && _items.isNotEmpty;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      debugPrint(
        '[RequestScreen] _fetch: isGarageUser=${isGarageUser}, page=$_currentPage, status=$_selectedStatus, search=$_searchQuery',
      );

      final response =
          isGarageUser
              ? await RequestServiceApi.getAllRequestsForGarage(
                pageNum: _currentPage,
                pageSize: _pageSize,
                status: _selectedStatus,
                search: _searchQuery,
              )
              : await RequestServiceApi.getAllRequests(
                pageNum: _currentPage,
                pageSize: _pageSize,
                status: _selectedStatus,
                search: _searchQuery,
              );

      if (!mounted) return;

      setState(() {
        if (refresh || _currentPage == 1) {
          _items = response.requests;
        } else {
          _items.addAll(response.requests);
        }
        _pagination = response.pagination;
        _loading = false;
        _loadingMore = false;
      });

      debugPrint(
        '[RequestScreen] fetched page=$_currentPage, items=${_items.length}, total=${_pagination?.total}, isGarage=${isGarageUser}, user=${userProvider.userInfo?.name}',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
      debugPrint('[RequestScreen] error: $e');
    }
  }

  Future<void> _loadMore() async {
    if (_pagination == null ||
        _currentPage >= _pagination!.totalPages ||
        _loadingMore) {
      return;
    }

    _currentPage++;
    await _fetch();
  }

  String _statusText(int status) {
    switch (status) {
      case 1:
        return 'Chờ báo giá';
      case 2:
        return 'Đã xác nhận';
      case 3:
        return 'Từ chối';
      case 4:
        return 'Hoàn thành';
      default:
        return 'Không xác định';
    }
  }

  Color _statusBgColor(int status) {
    switch (status) {
      case 1:
        return DesignTokens.primaryBlue4; // waiting for quotation
      case 2:
        return Color(0xFFFFFDEA); // accepted
      case 3:
        return Color(0xFFFFEAEA); // rejected
      case 4:
        return const Color(0xFFF5FFF8); // completed
      default:
        return DesignTokens.gray400;
    }
  }

  Color _statusTextColor(int status) {
    switch (status) {
      case 1:
        return DesignTokens.textBrand; // waiting for quotation
      case 2:
        return Color(0xFFD0B304); // accepted
      case 3:
        return DesignTokens.secondaryOrange; // rejected
      case 4:
        return DesignTokens.secondaryGreen;
      default:
        return DesignTokens.textPrimary;
    }
  }

  Color _statusBorderColor(int status) {
    switch (status) {
      case 1:
        return DesignTokens.borderBrandPrimary; // waiting for quotation
      case 2:
        return DesignTokens.secondaryYellow; // accepted
      case 3:
        return DesignTokens.secondaryOrange; // rejected
      case 4:
        return DesignTokens.secondaryGreen; // completed
      default:
        return DesignTokens.borderBrandPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.surfacePrimary,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                return MyHeader(
                  title:
                      isGarageUser
                          ? 'Danh sách yêu cầu (Gara)'
                          : 'Danh sách yêu cầu',
                  showLeftButton: false,
                  showRightButton: true,
                  rightIcon: SvgIcon(
                    svgPath: 'assets/icons_final/more.svg',
                    size: 24,
                    color: DesignTokens.textPrimary,
                  ),
                  onRightPressed: () => Navigator.pop(context),
                );
              },
            ),
            Expanded(
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                        onRefresh: () => _fetch(refresh: true),
                        child:
                            _items.isEmpty
                                ? ListView(
                                  children: [
                                    SizedBox(height: 80),
                                    Center(
                                      child: MyText(
                                        text: 'Chưa có yêu cầu nào',
                                        textStyle: 'body',
                                        textSize: '16',
                                        textColor: 'placeholder',
                                      ),
                                    ),
                                  ],
                                )
                                : NotificationListener<ScrollNotification>(
                                  onNotification: (
                                    ScrollNotification scrollInfo,
                                  ) {
                                    if (!_loadingMore &&
                                        scrollInfo.metrics.pixels ==
                                            scrollInfo
                                                .metrics
                                                .maxScrollExtent) {
                                      _loadMore();
                                    }
                                    return false;
                                  },
                                  child: ListView.separated(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    itemCount:
                                        _items.length + (_loadingMore ? 1 : 0),
                                    separatorBuilder:
                                        (_, __) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      if (index == _items.length) {
                                        return const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }

                                      final item = _items[index];
                                      return _buildRequestCard(item);
                                    },
                                  ),
                                ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(RequestServiceModel item) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ảnh hoặc placeholder
          _buildImageSection(item),
          // Nội dung dưới ảnh
          Padding(
            padding: const EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row: Type xe + đời xe, mã đơn
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: MyText(
                              text:
                                  item.carInfo != null
                                      ? '${item.carInfo!.typeCar} ${item.carInfo!.yearModel}'
                                      : 'Thông tin xe',
                              textStyle: 'head',
                              textSize: '16',
                              textColor: 'primary',
                            ),
                          ),
                          Flexible(
                            child: MyText(
                              text:
                                  item.requestCode.isNotEmpty
                                      ? item.requestCode
                                      : 'Mã đơn #${item.id}',
                              textStyle: 'body',
                              textSize: '12',
                              textColor: 'tertiary',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isGarageUser) ...[
                      Row(
                        children: [
                          SvgIcon(
                            svgPath: 'assets/icons_final/clock.svg',
                            size: 16,
                            color: DesignTokens.textTertiary,
                          ),
                          const SizedBox(width: 6),
                          MyText(
                            text:
                                item.timeAgo ??
                                item.createdAt
                                    .replaceFirst('T', ' ')
                                    .split('.')
                                    .first,
                            textStyle: 'body',
                            textSize: '12',
                            textColor: 'tertiary',
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                // Mô tả
                if ((item.description ?? '').isNotEmpty) ...[
                  MyText(
                    text: item.description ?? '',
                    textStyle: 'body',
                    textSize: '14',
                    textColor: 'secondary',
                  ),
                ],
                const SizedBox(height: 12),
                // Row: Thời gian, nút Danh sách báo giá
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child:
                          isGarageUser
                              ? MyButton(
                                text: 'Nhắn tin',
                                height: 30,
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/chat',
                                    arguments: item,
                                  );
                                },
                                buttonType: ButtonType.secondary,
                                textStyle: 'label',
                                textSize: '12',
                                textColor: 'primary',
                                startIcon: 'assets/icons_final/message-text.svg',
                                sizeStartIcon: Size(16, 16),
                              )
                              : Row(
                                children: [
                                  SvgIcon(
                                    svgPath: 'assets/icons_final/clock.svg',
                                    size: 16,
                                    color: DesignTokens.textTertiary,
                                  ),
                                  const SizedBox(width: 6),
                                  MyText(
                                    text:
                                        item.timeAgo ??
                                        item.createdAt
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: MyButton(
                        text:
                            isGarageUser
                                ? 'Báo giá'
                                : 'Danh sách báo giá (${item.listQuotation?.length ?? 0})',
                        height: 30,
                        textStyle: 'label',
                        textSize: '12',
                        textColor: 'primary',
                        buttonType: ButtonType.primary,
                        startIcon: 'assets/icons_final/money-2.svg',
                        sizeStartIcon: Size(16, 16),
                        colorStartIcon: DesignTokens.surfaceTertiary,
                        onPressed: () => onQuotationPressed(item),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(RequestServiceModel item) {
    return Stack(
      children: [
        // Ảnh hoặc placeholder
        if (item.listImageAttachment.isNotEmpty)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Container(
              height: 159,
              width: double.infinity,
              decoration: BoxDecoration(color: DesignTokens.gray100),
              child: Image.network(
                resolveImageUrl(item.listImageAttachment.first.path)!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildImagePlaceholder();
                },
              ),
            ),
          )
        else
          _buildImagePlaceholder(),

        // Trạng thái ở góc trái trên
        if (!isGarageUser) ...[
          Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusBgColor(item.status),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _statusBorderColor(item.status),
                width: 1,
              ),
            ),
            child: MyText(
              text: _statusText(item.status),
              textStyle: 'title',
              textSize: '12',
              color: _statusTextColor(item.status),
            ),
          ),
        ),
        ],

        // Nút more ở góc phải trên
        if (!isGarageUser) ...[
          Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              onPressed: () {
                // TODO: Show more options
              },
              icon: SvgIcon(
                svgPath: 'assets/icons_final/more.svg',
                size: 16,
                color: DesignTokens.textPrimary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ),
        ],
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 159,
      width: double.infinity,
      decoration: BoxDecoration(
        color: DesignTokens.gray100,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Center(
        child: SvgIcon(
          svgPath: 'assets/icons_final/car.svg',
          size: 32,
          color: DesignTokens.gray400,
        ),
      ),
    );
  }
}

class _QuotationBottomSheet extends StatefulWidget {
  final RequestServiceModel item;
  final VoidCallback onSuccess;

  const _QuotationBottomSheet({
    required this.item,
    required this.onSuccess,
  });

  @override
  State<_QuotationBottomSheet> createState() => _QuotationBottomSheetState();
}

class _QuotationBottomSheetState extends State<_QuotationBottomSheet> {
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool isLoading = false;

  // Format price with thousand separators
  String formatPrice(String value) {
    // Remove all non-digit characters
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.isEmpty) return '';
    
    // Convert to number and format with thousand separators
    int number = int.tryParse(digitsOnly) ?? 0;
    String formatted = number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    
    return formatted;
  }

  // Get numeric value from formatted price
  int getNumericPrice(String formattedPrice) {
    String digitsOnly = formattedPrice.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(digitsOnly) ?? 0;
  }

  // Create quotation
  Future<void> createQuotation() async {
    if (isLoading) return;
    
    final price = getNumericPrice(priceController.text);
    final description = descriptionController.text.trim();
    
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập giá dự kiến hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mô tả'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await QuotationServiceApi.createQuotation(
        requestServiceId: widget.item.id,
        price: price,
        description: description,
      );

      if (response.success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo báo giá thành công'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tạo báo giá: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: 376,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: MyText(
                    text: 'Gửi báo giá',
                    textStyle: 'title',
                    textSize: '16',
                    textColor: 'primary',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price input field
                  MyTextField(
                    controller: priceController,
                    label: 'Giá dự kiến*',
                    hintText: 'Nhập giá dự kiến (VND)',
                    obscureText: false,
                    hasError: false,
                    keyboardType: TextInputType.number,
                    onChange: (value) {
                      String formatted = formatPrice(value);
                      if (formatted != value) {
                        priceController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // Description input field
                  MyTextField(
                    controller: descriptionController,
                    label: 'Mô tả',
                    hintText: 'Nhập mô tả',
                    height: 144,
                    obscureText: false,
                    hasError: false,
                    maxLines: 5,
                    minLines: 3,
                  ),
                  const SizedBox(height: 12),
                  // Action buttons - Always at bottom
                  Row(
                    children: [
                      Expanded(
                        child: MyButton(
                          text: 'Hủy',
                          height: 36,
                          onPressed: () => Navigator.pop(context),
                          buttonType: ButtonType.secondary,
                          textStyle: 'label',
                          textSize: '14',
                          textColor: 'primary',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MyButton(
                          text: isLoading ? 'Đang gửi...' : 'Gửi báo giá',
                          height: 36,
                          onPressed: isLoading ? null : createQuotation,
                          buttonType: isLoading ? ButtonType.disable : ButtonType.primary,
                          textStyle: 'label',
                          textSize: '14',
                          textColor: 'primary',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
