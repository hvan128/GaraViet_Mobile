import 'package:flutter/material.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text_field.dart';
import 'package:gara/services/request/request_service.dart';
import 'package:gara/services/quotation/quotation_service.dart';
import 'package:gara/services/messaging/messaging_event_bus.dart';
// Messaging handled inside ChatRoomScreen; no direct imports needed here
import 'package:gara/models/request/request_service_model.dart';
import 'package:gara/models/car/car_info_model.dart';
import 'package:gara/models/user/user_info_model.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/app_toast.dart';
import 'package:gara/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:gara/utils/status/status_library.dart';
import 'package:gara/widgets/image_carousel_widget.dart';
// import 'package:gara/utils/debug_logger.dart';
import 'package:gara/services/messaging/messaging_service.dart';
import 'package:gara/services/messaging/tab_focus_bus.dart';

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

  // Tab focus tracking
  bool _shouldRefreshOnFocus = false;


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

  // Handle message button press
  Future<void> onMessagePressed(RequestServiceModel item) async {
    try {
      final res = await MessagingServiceApi.createRoomFromRequest(
        requestServiceId: item.id,
      );
      if (res.success && res.data != null && res.data!.roomId.isNotEmpty) {
        if (!mounted) return;
        Navigator.pushNamed(
          context,
          '/chat-room',
          arguments: res.data!.roomId,
        );
      } else {
        if (!mounted) return;
        AppToastHelper.showError(context, message: 'Không thể mở phòng chat.');
      }
    } catch (e) {
      if (!mounted) return;
      AppToastHelper.showError(context, message: 'Không thể mở phòng chat.');
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
    _attachFocusListener();
  }

  void _attachFocusListener() {
    TabFocusBus.instance.currentIndex.addListener(_onFocusChange);
    TabFocusBus.instance.focusTick.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    final isFocused = TabFocusBus.instance.currentIndex.value == 1; // Request tab index
    if (isFocused && _shouldRefreshOnFocus) {
      _shouldRefreshOnFocus = false;
      _fetch(refresh: true);
    }
  }

  @override
  void dispose() {
    TabFocusBus.instance.currentIndex.removeListener(_onFocusChange);
    TabFocusBus.instance.focusTick.removeListener(_onFocusChange);
    super.dispose();
  }

  // Public method để gọi từ bên ngoài (MainNavigationScreen)
  void reloadFromExternal() {
    _fetch(refresh: true);
  }

  // Method để thêm request mới vào list (khi user đang ở tab Request)
  void addNewRequestToTop(RequestServiceModel newRequest) {
    if (mounted) {
      setState(() {
        // Kiểm tra xem request đã tồn tại chưa (tránh duplicate)
        final existingIndex = _items.indexWhere((item) => item.id == newRequest.id);
        if (existingIndex == -1) {
          // Thêm vào đầu list
          _items.insert(0, newRequest);
        }
      });
    }
  }

  // Method để parse Firebase notification data thành RequestServiceModel
  RequestServiceModel? parseRequestFromNotification(Map<String, dynamic> data) {
    try {
      final requestId = int.tryParse(data['requestId']?.toString() ?? '0') ?? 0;
      final requestCode = data['requestCode']?.toString() ?? '';
      final description = data['description']?.toString() ?? '';
      final address = data['address']?.toString() ?? '';
      final radiusSearch = data['radiusSearch']?.toString() ?? '';
      final createdAt = data['createdAt']?.toString() ?? '';
      final userName = data['userName']?.toString() ?? '';
      final userAvatar = data['userAvatar']?.toString() ?? '';
      
      // Parse carInfo JSON
      CarInfo? carInfo;
      try {
        final carInfoStr = data['carInfo']?.toString() ?? '';
        if (carInfoStr.isNotEmpty) {
          // Parse JSON string manually
          final carInfoMap = <String, dynamic>{};
          final regex = RegExp(r'"([^"]+)":\s*"([^"]*)"');
          final matches = regex.allMatches(carInfoStr);
          for (final match in matches) {
            carInfoMap[match.group(1)!] = match.group(2)!;
          }
          
          carInfo = CarInfo(
            id: int.tryParse(carInfoMap['id'] ?? '0') ?? 0,
            userId: int.tryParse(carInfoMap['user_id'] ?? '0') ?? 0,
            typeCar: carInfoMap['type_car'] ?? '',
            yearModel: carInfoMap['year_model'] ?? '',
            vehicleLicensePlate: carInfoMap['vehicle_license_plate'] ?? '',
            description: carInfoMap['description'] ?? '',
            status: int.tryParse(carInfoMap['status'] ?? '1') ?? 1,
          );
        }
      } catch (e) {
        print('[RequestScreen] Error parsing carInfo: $e');
      }

      // Parse createdBy - tạo UserInfoResponse với các giá trị mặc định
      final inforUser = UserInfoResponse(
        id: int.tryParse(data['userId']?.toString() ?? '0') ?? 0,
        userId: int.tryParse(data['userId']?.toString() ?? '0') ?? 0,
        name: userName,
        phone: '', // Không có trong notification
        avatarPath: userAvatar,
        roleId: 1, // Default role
        roleCode: 'USER',
        roleName: 'Người dùng',
        isActive: true,
        isPhoneVerified: false,
        deviceId: '',
        sessionId: '',
        createdAt: createdAt,
        updatedAt: createdAt,
      );

      return RequestServiceModel(
        id: requestId,
        requestCode: requestCode,
        inforUser: inforUser,
        carInfo: carInfo,
        status: 1, // Default status for new request
        address: address,
        description: description,
        radiusSearch: radiusSearch,
        listImageAttachment: [], // Empty for new requests
        listQuotation: [], // Empty for new requests
        createdAt: createdAt,
        updatedAt: createdAt,
        timeAgo: 'Vừa xong',
      );
    } catch (e) {
      print('[RequestScreen] Error parsing request from notification: $e');
      return null;
    }
  }

  Future<void> _fetch({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      // Khởi tạo danh sách mới để đảm bảo có thể mutable
      _items = <RequestServiceModel>[];
    }

    setState(() {
      _loading = refresh || _items.isEmpty;
      _loadingMore = !refresh && _items.isNotEmpty;
    });

    try {
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
          // Sao chép sang danh sách mới tránh giữ tham chiếu bất biến
          _items = List<RequestServiceModel>.of(response.requests);
        } else {
          _items.addAll(response.requests);
        }
        _pagination = response.pagination;
        _loading = false;
        _loadingMore = false;
      });

      // DebugLogger.largeJson('[RequestScreen] fetched', {
      //   'page': _currentPage,
      //   'itemsCount': _items.length,
      //   'total': _pagination?.total,
      //   'isGarage': isGarageUser,
      //   'userName': userProvider.userInfo?.name,
      // });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
      // DebugLogger.largeJson('[RequestScreen] error', {
      //   'error': e.toString(),
      // });
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
                     'Danh sách yêu cầu',
                  showLeftButton: false,
                  showRightButton: true,
                  rightIcon: SvgIcon(
                    svgPath: 'assets/icons_final/more.svg',
                    size: 24,
                    color: DesignTokens.textPrimary,
                  ),
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
                                  padding: EdgeInsets.only(
                                    top: 80,
                                    left: 12,
                                    right: 12,
                                    bottom: 50 + kBottomNavigationBarHeight,
                                  ),
                                  children: [
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
                                    final threshold = 200.0;
                                    if (!_loadingMore &&
                                        scrollInfo.metrics.pixels >=
                                            scrollInfo.metrics.maxScrollExtent -
                                                threshold) {
                                      _loadMore();
                                    }
                                    return false;
                                  },
                                  child: ListView.separated(
                                    padding: EdgeInsets.only(
                                      left: 20,
                                      right: 20,
                                      top: 0,
                                      bottom: 50 + kBottomNavigationBarHeight,
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
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        '/request-detail',
        arguments: item,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
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
                                onPressed: () => onMessagePressed(item),
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
      ),
    );
  }

  Widget _buildImageSection(RequestServiceModel item) {
    return ImageCarouselWidget(
      files: item.listImageAttachment,
      isGarageUser: isGarageUser,
      status: item.status,
      statusType: StatusType.request,
      onMorePressed: () {
        // TODO: Show more options
      },
      onImageTap: (index) {
        Navigator.pushNamed(
          context,
          '/image-viewer',
          arguments: {
            'files': item.listImageAttachment,
            'initialIndex': index,
          },
        );
      },
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
      AppToastHelper.showError(
        context,
        message: 'Vui lòng nhập giá dự kiến',
      );
      return;
    }
    
    if (description.isEmpty) {
      AppToastHelper.showWarning(
        context,
        message: 'Vui lòng nhập mô tả chi tiết',
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
        AppToastHelper.showSuccess(
          context,
          message: 'Gửi báo giá thành công!',
        );
        // Thông báo danh sách phòng chat có thể thay đổi để màn Tin nhắn cập nhật
        MessagingEventBus().emitRoomsDirty();
        widget.onSuccess();
      } else {
        AppToastHelper.showError(
          context,
          message: 'Không thể gửi báo giá. Vui lòng thử lại sau.',
        );
      }
    } catch (e) {
      AppToastHelper.showError(
        context,
        message: 'Không thể gửi báo giá. Vui lòng thử lại sau.',
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

