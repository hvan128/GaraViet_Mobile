import 'package:flutter/material.dart';
import 'package:gara/models/booking/booking_model.dart';
import 'package:gara/models/user/user_info_model.dart';
import 'package:gara/services/booking/booking_service.dart';
import 'package:gara/utils/debug_logger.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/utils/status/status_widget.dart';
import 'package:gara/utils/status/quotation_status.dart';
import 'package:gara/utils/status/booking_status.dart';
import 'package:gara/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/widgets/app_toast.dart';
import 'package:gara/widgets/month_picker.dart';
import 'package:gara/widgets/skeleton.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with TickerProviderStateMixin {
  final List<BookingModel> _items = [];
  BookingPagination? _pagination;
  int _page = 1;
  final int _perPage = 10;
  // Key để neo menu lọc ngay dưới nút "Lọc"
  final GlobalKey _filterKey = GlobalKey();
  // Lọc theo nhiều trạng thái: lưu set và build CSV khi gọi API
  final Set<int> _selectedStatuses = <int>{};
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  // Summary sticky bar (chỉ cho gara)
  DateTime _fromDate = DateTime(
  DateTime.now().year,
  DateTime.now().month,
  1,
  );
  DateTime _toDate = DateTime(
    DateTime.now().year,
    DateTime.now().month + 1,
    0,
    23,
    59,
    59,
  );
  bool _isCalculating = false;
  int? _totalRevenue; // total_revenue (G)
  int? _totalUnpaid; // total_unpaid (10%*G - V - C)
  int? _totalPaid; // total_paid (C + V)
  int? _totalPlatformFee; // total_platform_fee (10% * G)
  bool _summaryExpanded = true;
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  // Banner thông báo phí nền tảng
  DateTime? _dueDate; // Ngày hết hạn (sẽ được tính toán)

  // Animation cho summary bar
  late AnimationController _summaryAnimationController;
  late Animation<double> _summaryAnimation;

  @override
  void initState() {
    super.initState();
    _fetchPage(reset: true);
    _scrollController.addListener(_onScroll);

    // Khởi tạo animation controller
    _summaryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _summaryAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _summaryAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Thiết lập trạng thái ban đầu
    if (_summaryExpanded) {
      _summaryAnimationController.value = 1.0;
    }

    // Chỉ gọi tính toán cho tài khoản gara sau 1 frame để có context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isGarage = context.read<UserProvider>().isGarageUser;
      // DebugLogger.largeJson('isGarage in addPostFrameCallback', isGarage);
      if (isGarage) {
        // DebugLogger.largeJson('Calling _calculateDueDate', 'start');
        _calculateDueDate();
        _fetchSummary();
      } else {
        // DebugLogger.largeJson(
        //   'Not garage user, skipping _calculateDueDate',
        //   'skip',
        // );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _summaryAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchPage();
    }
  }

  void _toggleSummary() {
    setState(() {
      _summaryExpanded = !_summaryExpanded;
    });

    if (_summaryExpanded) {
      _summaryAnimationController.forward();
    } else {
      _summaryAnimationController.reverse();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // Chỉ xử lý khi kéo theo chiều dọc
    final deltaY = details.delta.dy;

    if (_summaryExpanded && deltaY > 0) {
      // Kéo xuống khi đang mở rộng
      final progress = _summaryAnimationController.value - (deltaY / 200);
      _summaryAnimationController.value = progress.clamp(0.0, 1.0);
    } else if (!_summaryExpanded && deltaY < 0) {
      // Kéo lên khi đang thu gọn
      final progress = _summaryAnimationController.value - (deltaY / 200);
      _summaryAnimationController.value = progress.clamp(0.0, 1.0);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    final currentValue = _summaryAnimationController.value;

    // Xác định hướng dựa trên velocity và vị trí hiện tại
    bool shouldExpand;

    if (velocity.abs() > 500) {
      // Velocity cao: dựa vào hướng velocity
      shouldExpand = velocity < 0; // Kéo lên = mở rộng
    } else {
      // Velocity thấp: dựa vào vị trí hiện tại
      shouldExpand = currentValue > 0.5;
    }

    if (shouldExpand != _summaryExpanded) {
      _toggleSummary();
    } else {
      // Quay về trạng thái ban đầu
      if (_summaryExpanded) {
        _summaryAnimationController.forward();
      } else {
        _summaryAnimationController.reverse();
      }
    }
  }

  void _calculateDueDate() {
    final now = DateTime.now();
    // DebugLogger.largeJson('now.day', now.day);
    // DebugLogger.largeJson('now.month', now.month);
    // DebugLogger.largeJson('now.year', now.year);

    if (now.day <= 15) {
      // Nếu ngày hiện tại <= 15, hết hạn ngày 15 tháng này
      _dueDate = DateTime(now.year, now.month, 15);
      // DebugLogger.largeJson(
      //   'dueDate calculated (this month)',
      //   _dueDate!.toIso8601String(),
      // );
    } else {
      // Nếu ngày hiện tại > 15, hết hạn ngày 15 tháng sau
      _dueDate = DateTime(now.year, now.month + 1, 15);
      // DebugLogger.largeJson(
      //   'dueDate calculated (next month)',
      //   _dueDate!.toIso8601String(),
      // );
    }
  }

  Future<void> _fetchPage({bool reset = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    if (reset) {
      _page = 1;
      _hasMore = true;
    }

    final isGarage = context.read<UserProvider>().isGarageUser;
    BookingListResponse res;
    if (isGarage) {
      res = await BookingServiceApi.getGarageBookedQuotations(
        page: _page,
        perPage: _perPage,
        statusCsv:
            _selectedStatuses.isEmpty ? null : _selectedStatuses.join(','),
        fromDate: _fromDate,
        toDate: _toDate,
      );
    } else {
      res = await BookingServiceApi.getUserBookedServices(
        page: _page,
        perPage: _perPage,
        statusCsv:
            _selectedStatuses.isEmpty ? null : _selectedStatuses.join(','),
        fromDate: _fromDate,
        toDate: _toDate,
      );
    }

    setState(() {
      _pagination = res.pagination;
      if (reset) _items.clear();
      _items.addAll(res.data);
      _hasMore = _items.length < (_pagination?.totalItems ?? _items.length);
      _isLoading = false;
      _page += 1;
    });
  }

  Future<void> _fetchSummary() async {
    if (_isCalculating) return;
    setState(() => _isCalculating = true);
    try {
      final res = await BookingServiceApi.calculateGarageOrdersPrice(
        fromDate: DateTime(
          _fromDate.year,
          _fromDate.month,
          _fromDate.day,
          0,
          0,
          0,
        ),
        toDate: DateTime(_toDate.year, _toDate.month, _toDate.day, 23, 59, 59),
      );
      // debugPrint(
      //   '[Schedule] calculateGarageOrdersPrice raw: ${res.toString()}',
      // );
      final data = (res['data'] ?? {}) as Map<String, dynamic>;
      // debugPrint('[Schedule] data keys: ${data.keys.toList()}');
      final summary = (data['summary'] ?? {}) as Map<String, dynamic>;
      // debugPrint('[Schedule] summary: ${summary.toString()}');
      setState(() {
        _totalRevenue = (summary['total_revenue'] ?? 0) as int;
        _totalPlatformFee = (summary['total_platform_fee'] ?? 0) as int;
        _totalPaid = (summary['total_paid'] ?? 0) as int;
        _totalUnpaid = (summary['total_unpaid'] ?? 0) as int;
      });
      // debugPrint(
      //   '[Schedule] parsed => total_revenue=${_totalRevenue}, total_platform_fee=${_totalPlatformFee}, total_paid=${_totalPaid}, total_unpaid=${_totalUnpaid}',
      // );
    } catch (e) {
      if (mounted) {
        AppToastHelper.showError(
          context,
          message: 'Lỗi tính giá: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) setState(() => _isCalculating = false);
    }
  }

  void _openStatusFilter() async {
    final bool isGarage = context.read<UserProvider>().isGarageUser;
    final Map<int, String> statusLabels = {
      if (isGarage)
        for (final s in QuotationStatus.values) s.value: s.displayName
      else
        for (final s in BookingStatus.values) s.value: s.displayName,
    };

    // Tính vị trí của nút lọc để neo menu ngay bên dưới
    final RenderBox? button =
        _filterKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final Offset buttonOffset =
        button?.localToGlobal(Offset.zero) ?? const Offset(0, 0);
    final Size buttonSize = button?.size ?? const Size(0, 0);

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromLTWH(
        buttonOffset.dx,
        buttonOffset.dy + buttonSize.height,
        buttonSize.width,
        0,
      ),
      Offset.zero & overlay.size,
    );

    final int? selected = await showMenu<int>(
      context: context,
      position: position,
      color: Colors.white,
      items: [
        for (final entry in statusLabels.entries)
          PopupMenuItem<int>(
            value: entry.key,
            height: 36,
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: SizedBox(
                height: 32,
                child: Center(
                  child: StatusWidget(
                    status: entry.key,
                    type: isGarage ? StatusType.quotation : StatusType.booking,
                    isSelected: _selectedStatuses.contains(entry.key),
                    height: 24,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    if (selected != null) {
      setState(() {
        if (_selectedStatuses.contains(selected)) {
          _selectedStatuses.remove(selected);
        } else {
          _selectedStatuses.add(selected);
        }
      });
      _fetchPage(reset: true);
      // Refetch summary khi lọc để cập nhật thông tin tài chính
      final isGarage = context.read<UserProvider>().isGarageUser;
      if (isGarage) {
        _fetchSummary();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGarage = context.watch<UserProvider>().isGarageUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            MyHeader(
              showLeftButton: false,
              customTitle: const MyText(
                text: 'Các đơn hàng',
                textStyle: 'head',
                textSize: '16',
                textColor: 'primary',
              ),
              showRightButton: true,
              rightIcon: MyMonthPicker(
                defaultValue: _selectedMonth,
                onMonthSelected: (dt) {
                  final firstDay = DateTime(dt.year, dt.month, 1);
                  final lastDay = DateTime(
                    dt.year,
                    dt.month + 1,
                    0,
                    23,
                    59,
                    59,
                  );
                  setState(() {
                    _selectedMonth = DateTime(dt.year, dt.month);
                    _fromDate = firstDay;
                    _toDate = lastDay;
                  });
                  _fetchSummary();
                  _fetchPage(reset: true);
                },
              ),
            ),
            // Nút lọc dưới header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: _openStatusFilter,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      key: _filterKey,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.surfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DesignTokens.borderSecondary),
                      ),
                      child: Row(
                        children: [
                          SvgIcon(
                            svgPath: 'assets/icons_final/filter.svg',
                            size: 16,
                            color: DesignTokens.textBrand,
                          ),
                          const SizedBox(width: 6),
                          const MyText(
                            text: 'Lọc',
                            textStyle: 'label',
                            textSize: '12',
                            textColor: 'brand',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: false,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final st in _selectedStatuses)
                              Padding(
                                padding:  EdgeInsets.only(left: st == _selectedStatuses.first ? 0 : 6),
                                child: StatusWidget(
                                  status: st,
                                  type:
                                      isGarage
                                          ? StatusType.quotation
                                          : StatusType.booking,
                                  isSelected: true,
                                  height: 24,
                                  onRemove: () {
                                    setState(() {
                                      _selectedStatuses.remove(st);
                                    });
                                    _fetchPage(reset: true);
                                    // Refetch summary khi xóa filter
                                    final isGarage = context.read<UserProvider>().isGarageUser;
                                    if (isGarage) {
                                      _fetchSummary();
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _fetchPage(reset: true);
                  // Refetch summary khi refresh
                  final isGarage = context.read<UserProvider>().isGarageUser;
                  if (isGarage) {
                    await _fetchSummary();
                  }
                },
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(12, 12, 12, 240),
                  itemCount:
                      _items.isEmpty
                          ? (_isLoading ? 1 : 1)
                          : _items.length +
                              (_hasMore ? 1 : 0) +
                              (isGarage && (_totalUnpaid ?? 0) > 0 ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Hiển thị banner unpaid ở đầu danh sách
                    if (isGarage && (_totalUnpaid ?? 0) > 0 && index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildUnpaidBanner(),
                      );
                    }

                    // Điều chỉnh index cho các item khác
                    final dataIndex =
                        isGarage && (_totalUnpaid ?? 0) > 0 ? index - 1 : index;

                    if (_items.isEmpty) {
                      if (_isLoading) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height,
                            child: SkeletonList(itemHeight: 150, itemCount: 3,),
                          ),
                        );
                      }
                      return _buildEmptyState();
                    }
                    if (dataIndex >= _items.length) {
                       return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height,
                            child: SkeletonList(itemHeight: 150, itemCount: 3,),
                          ),
                        );
                    }
                    final item = _items[dataIndex];
                    return _buildOrderCard(item, isGarage);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isGarage ? _buildStickySummaryBar() : null,
    );
  }

  Future<void> _onCompleteOrder(BookingModel item) async {
    final quotationId = item.quotation?.id;
    if (quotationId == null) {
      AppToastHelper.showError(context, message: 'Không tìm thấy mã báo giá');
      return;
    }
    try {
      final res = await BookingServiceApi.completeOrder(
        quotationId: quotationId,
      );
      final success = (res['success'] ?? true) == true;
      final message =
          res['message']?.toString() ?? 'Hoàn thành đơn hàng thành công';
      if (success) {
        if (mounted) AppToastHelper.showSuccess(context, message: message);
        await _fetchPage(reset: true);
        await _fetchSummary();
      } else {
        if (mounted) AppToastHelper.showError(context, message: message);
      }
    } catch (e) {
      if (mounted) {
        AppToastHelper.showError(context, message: 'Lỗi: ${e.toString()}');
      }
    }
  }

  Future<void> _onCancelOrder(BookingModel item) async {
    final quotationId = item.quotation?.id;
    if (quotationId == null) {
      AppToastHelper.showError(context, message: 'Không tìm thấy mã báo giá');
      return;
    }
    try {
      final res = await BookingServiceApi.cancelOrder(quotationId: quotationId);
      final success = (res['success'] ?? true) == true;
      final message = res['message']?.toString() ?? 'Hủy đặt lịch thành công';
      if (success) {
        if (mounted) AppToastHelper.showSuccess(context, message: message);
        await _fetchPage(reset: true);
        // Refetch summary khi hủy đơn hàng
        final isGarage = context.read<UserProvider>().isGarageUser;
        if (isGarage) {
          await _fetchSummary();
        }
      } else {
        if (mounted) AppToastHelper.showError(context, message: message);
      }
    } catch (e) {
      if (mounted) {
        AppToastHelper.showError(context, message: 'Lỗi: ${e.toString()}');
      }
    }
  }

  void _onChat(BookingModel item) {
    final quotation = item.quotation;
    final request = item.requestService;
    // Gọn: chỉ log kết quả cuối cùng và nguồn lấy

    // requestId: ưu tiên từ quotation, fallback sang request
    int requestId = quotation?.requestServiceId ?? 0;
    if (requestId == 0) {
      requestId = request?.id ?? 0;
    }

    // Gara id: ưu tiên userId; nếu = 0 thì fallback sang id
    int garaUserId = (quotation?.inforGarage?.userId ?? 0) != 0
        ? (quotation?.inforGarage?.userId ?? 0)
        : (quotation?.inforGarage?.id ?? 0);
    

    // User id: ưu tiên userId; nếu = 0 thì fallback sang id
    int userId = (request?.inforUser?.userId ?? 0) != 0
        ? (request?.inforUser?.userId ?? 0)
        : (request?.inforUser?.id ?? 0);
    

    // Bổ sung fallback theo vai trò đăng nhập
    final provider = context.read<UserProvider>();
    final int currentUserId = provider.userInfo?.userId ?? 0;
    final bool isGarageUser = provider.isGarageUser;
    if (isGarageUser && (garaUserId == 0) && currentUserId != 0) {
      garaUserId = currentUserId;
    }
    if (!isGarageUser && (userId == 0) && currentUserId != 0) {
      userId = currentUserId;
    }

    if (requestId == 0 || garaUserId == 0 || userId == 0) {
      AppToastHelper.showError(
        context,
        message: 'Lỗi mạng! Vui lòng thử lại sau!',
      );
      DebugLogger.log('[Schedule] _onChat missing | isGarageUser='
          '$isGarageUser currentUserId=$currentUserId requestId=$requestId '
          'garaUserId=$garaUserId userId=$userId');
      return;
    }

    final String roomId = 'room_req${requestId}_${garaUserId}_$userId';
    DebugLogger.log('[Schedule] _onChat room: $roomId');
    Navigator.pushNamed(
      context,
      '/chat-room',
      arguments: roomId,
    );
  }

  Widget _buildOrderCard(BookingModel item, bool isGarage) {
    final UserInfoResponse? user = item.requestService?.inforUser;
    final UserInfoResponse? garage = item.quotation?.inforGarage;
    final customerName = user?.name ?? '';
    final garageName = garage?.nameGarage ?? '';
    final code =
        isGarage
            ? item.quotation?.codeQuotation ?? ''
            : item.requestService?.requestCode ?? '';
    final address =
        isGarage ? item.requestService?.address ?? '' : garage?.address ?? '';
    final timeText = item.time != null ? _formatDateTime(item.time!) : '';
    final statusValue = item.status; // luôn dùng Booking.status
    final statusType = isGarage ? StatusType.quotation : StatusType.booking;
    final titleName = isGarage ? customerName : garageName;
    final description = item.requestService?.description ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.borderSecondary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        text: titleName,
                        textStyle: 'head',
                        textSize: '16',
                        textColor: 'brand',
                      ),
                      MyText(
                        text: code,
                        textStyle: 'body',
                        textSize: '12',
                        textColor: 'tertiary',
                      ),
                    ],
                  ),
                ),
                StatusWidget(status: statusValue, type: statusType),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                MyText(
                  text: 'Địa chỉ: ',
                  textStyle: 'body',
                  textSize: '14',
                  textColor: 'tertiary',
                ),
                MyText(
                  text: address,
                  textStyle: 'body',
                  textSize: '14',
                  textColor: 'primary',
                ),
                const SizedBox(width: 8),
                SvgIcon(
                  svgPath: 'assets/icons_final/map.svg',
                  size: 20,
                  color: DesignTokens.textBrand,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                MyText(
                  text: 'Thời gian: ',
                  textStyle: 'body',
                  textSize: '14',
                  textColor: 'tertiary',
                ),
                MyText(
                  text: timeText,
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
                  text: 'Dịch vụ: ',
                  textStyle: 'body',
                  textSize: '14',
                  textColor: 'tertiary',
                ),
                MyText(
                  text: description,
                  textStyle: 'body',
                  textSize: '14',
                  textColor: 'primary',
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: DesignTokens.borderBrandSecondary, height: 1),
            const SizedBox(height: 8),
            if (item.quotation != null) ...[
              Row(
                children: [
                  isGarage
                      ? const MyText(
                        text: 'Phí nền tảng: ',
                        textStyle: 'body',
                        textSize: '14',
                        textColor: 'tertiary',
                      )
                      : const SizedBox.shrink(),
                  isGarage
                      ? const MyText(
                        text: '10%',
                        textStyle: 'title',
                        textSize: '16',
                        textColor: 'brand',
                      )
                      : const SizedBox.shrink(),
                  const Spacer(),
                  MyText(
                    text: isGarage ? 'Còn phải thu: ' : 'Còn phải thanh toán: ',
                    textStyle: 'body',
                    textSize: '14',
                    textColor: 'tertiary',
                  ),
                  MyText(
                    text: _formatMoney(item.quotation!.remainPrice),
                    textStyle: 'title',
                    textSize: '16',
                    textColor: 'brand',
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            _buildActions(item, isGarage),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BookingModel item, bool isGarage) {
    final List<Widget> buttons = [];
    final int bookingStatus = item.status; // luôn dùng booking.status

    if (isGarage) {
      // USER VIEW
      final bool showComplete =
          isGarage &&
          (bookingStatus == 1 ||
              bookingStatus == 2 ||
              bookingStatus == 3 ||
              bookingStatus == 4);

      if (showComplete) {
        buttons.add(
          _buildBtn(
            'Hoàn thành',
            ButtonType.primary,
            () => _onCompleteOrder(item),
          ),
        );
      }
      buttons.addAll([
        _buildBtn('Nhắn tin', ButtonType.secondary, () => _onChat(item)),
        _buildBtn('Liên hệ', ButtonType.secondary, () {}),
      ]);
    } else {
      // GARAGE VIEW
      if (bookingStatus == 1) {
        // Chờ báo giá
        buttons.addAll([
          _buildBtn('Hủy đặt lịch', ButtonType.red, () => _onCancelOrder(item)),
          _buildBtn('Nhắn tin', ButtonType.secondary, () => _onChat(item)),
          _buildBtn('Liên hệ', ButtonType.secondary, () {}),
        ]);
      } else if (bookingStatus == 2) {
        // Chờ lên lịch
        buttons.addAll([
          _buildBtn('Báo cáo', ButtonType.red, () {}),
          _buildBtn('Đánh giá', ButtonType.secondary, () {}),
          _buildBtn('Bảo hành', ButtonType.secondary, () {}),
        ]);
      } else if (bookingStatus == 3) {
        // Chưa cọc
        buttons.add(_buildBtn('Báo cáo', ButtonType.red, () {}));
      } else {
        // Các trạng thái khác: mặc định hiển thị liên hệ/nhắn tin
        buttons.addAll([
          _buildBtn('Nhắn tin', ButtonType.primary, () => _onChat(item)),
          _buildBtn('Liên hệ', ButtonType.secondary, () {}),
        ]);
      }
    }

    return Row(
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          Expanded(child: buttons[i]),
          if (i != buttons.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildBtn(String text, ButtonType type, VoidCallback onPressed) {
    return MyButton(
      text: text,
      onPressed: onPressed,
      buttonType: type,
      height: 30,
      textStyle: 'label',
      textSize: '12',
    );
  }

  String _formatDateTime(DateTime dt) {
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)} ${two(dt.day)}/${two(dt.month)}/${dt.year}';
  }

  String _formatMoney(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$bufđ';
  }

  Widget _buildStickySummaryBar() {
    return SafeArea(
      top: false,
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              top: BorderSide(color: DesignTokens.borderSecondary, width: 1),
            ),

            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          padding: EdgeInsets.fromLTRB(12, 0, 12, 16 + 80),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nút toggle ở giữa với animation
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: _toggleSummary,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: AnimatedBuilder(
                        animation: _summaryAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _summaryAnimation.value * 3.14159, // 180 độ
                            child: SvgIcon(
                              svgPath: 'assets/icons_final/arrow-up.svg',
                              width: 20,
                              height: 20,
                              color: DesignTokens.textBrand,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              // Container chính với animation
              AnimatedBuilder(
                animation: _summaryAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      color: DesignTokens.surfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DesignTokens.borderSecondary),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child:
                        _isCalculating
                            ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                MyText(
                                  text: 'Đang tính toán...',
                                  textStyle: 'label',
                                  textSize: '14',
                                  textColor: 'tertiary',
                                ),
                              ],
                            )
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Dòng Tổng doanh thu (luôn hiển thị)
                                Row(
                                  children: [
                                    const MyText(
                                      text: 'Tổng doanh thu',
                                      textStyle: 'title',
                                      textSize: '16',
                                      textColor: 'primary',
                                    ),
                                    const Spacer(),
                                    MyText(
                                      text: _formatMoney((_totalRevenue ?? 0)),
                                      textStyle: 'title',
                                      textSize: '16',
                                      textColor: 'primary',
                                    ),
                                  ],
                                ),
                                // Phần chi tiết với animation
                                ClipRect(
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    heightFactor: _summaryAnimation.value,
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 8),
                                        const Divider(
                                          color:
                                              DesignTokens.borderBrandSecondary,
                                          height: 1,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const MyText(
                                              text: 'Phí nền tảng',
                                              textStyle: 'body',
                                              textSize: '14',
                                              textColor: 'tertiary',
                                            ),
                                            const Spacer(),
                                            MyText(
                                              text: _formatMoney(
                                                (_totalPlatformFee ?? 0),
                                              ),
                                              textStyle: 'body',
                                              textSize: '14',
                                              textColor: 'primary',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const MyText(
                                              text: 'Đã thanh toán',
                                              textStyle: 'body',
                                              textSize: '14',
                                              textColor: 'tertiary',
                                            ),
                                            const Spacer(),
                                            MyText(
                                              text: _formatMoney(
                                                (_totalPaid ?? 0),
                                              ),
                                              textStyle: 'body',
                                              textSize: '14',
                                              textColor: 'primary',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const MyText(
                                              text: 'Chưa thanh toán',
                                              textStyle: 'body',
                                              textSize: '14',
                                              textColor: 'error',
                                            ),
                                            const Spacer(),
                                            MyText(
                                              text: _formatMoney(
                                                (_totalUnpaid ?? 0),
                                              ),
                                              textStyle: 'body',
                                              textSize: '14',
                                              textColor: 'error',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnpaidBanner() {
    final unpaidAmount = _totalUnpaid ?? 0;
    // DebugLogger.largeJson('_dueDate is null?', _dueDate == null);
    if (_dueDate != null) {
      // DebugLogger.largeJson('_dueDate value', _dueDate!.toIso8601String());
    }
    final dueDate = _dueDate ?? DateTime.now();
    // DebugLogger.largeJson('unpaidAmount', unpaidAmount);
    // DebugLogger.largeJson('dueDate (final)', dueDate.toIso8601String());
    final now = DateTime.now();
    final isOverdue = now.isAfter(dueDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: DesignTokens.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.borderSecondary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MyText(
                  text: 'Bạn có ',
                  textStyle: 'body',
                  textSize: '12',
                  textColor: 'primary',
                ),
                MyText(
                  text: _formatMoney(unpaidAmount),
                  textStyle: 'title',
                  textSize: '12',
                  textColor: 'brand',
                ),
                MyText(
                  text: ' phí nền tảng chưa thanh toán.',
                  textStyle: 'body',
                  textSize: '12',
                  textColor: 'primary',
                ),
              ],
            ),
            const SizedBox(height: 4),
            MyText(
              text: 'Vui lòng thanh toán trước ${_formatDate(dueDate)}',
              textStyle: 'body',
              textSize: '12',
              textColor: 'primary',
            ),
            if (isOverdue) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DesignTokens.alerts['error']!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DesignTokens.alerts['error']!.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: MyText(
                  text:
                      'Tài khoản của bạn đã bị hạn chế. Vui lòng thanh toán ngay để tiếp tục sử dụng các dịch vụ.',
                  textStyle: 'body',
                  textSize: '12',
                  textColor: 'error',
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                MyButton(
                  text: 'Thanh toán',
                  buttonType: ButtonType.primary,
                  textStyle: 'label',
                  textSize: '12',
                  onPressed: () {
                    // TODO: Navigate to payment screen
                    AppToastHelper.showInfo(
                      context,
                      message: 'Chức năng thanh toán đang được phát triển',
                    );
                  },
                  height: 30,
                  width: 95,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          // Không dùng ảnh để đơn giản; có thể thêm icon sau
          MyText(
            text: 'Chưa có đơn hàng nào',
            textStyle: 'title',
            textSize: '16',
            textColor: 'tertiary',
          ),
          SizedBox(height: 8),
          MyText(
            text: 'Kéo xuống để làm mới',
            textStyle: 'body',
            textSize: '12',
            textColor: 'tertiary',
          ),
        ],
      ),
    );
  }
}
