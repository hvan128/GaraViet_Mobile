import 'package:flutter/material.dart';
import 'package:gara/theme/index.dart';
import 'package:gara/widgets/app_dialog.dart';
import 'package:gara/widgets/app_toast.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/widgets/dropdown.dart';
import 'package:gara/utils/format.dart';
import 'package:gara/services/user/user_service.dart';
import 'package:gara/models/car/car_info_model.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/services/booking/booking_service.dart';
import 'package:gara/models/booking/booking_model.dart';
import 'package:gara/utils/status/status_widget.dart';
import 'package:gara/widgets/image_carousel_widget.dart';
import 'package:gara/models/file/file_info_model.dart';
import 'package:gara/widgets/fullscreen_image_viewer.dart';
import 'package:url_launcher/url_launcher.dart';

class MyCarScreen extends StatefulWidget {
  const MyCarScreen({super.key});

  @override
  State<MyCarScreen> createState() => _MyCarScreenState();
}

class _MyCarScreenState extends State<MyCarScreen> {
  bool _loading = true;
  bool _loadingDetail = false;
  List<DropdownItem> _carItems = [];
  String? _selectedCarId;
  CarInfo? _carDetail;
  // Lịch sử đặt lịch theo xe
  final List<BookingModel> _historyItems = [];
  BookingPagination? _historyPagination;
  int _historyPage = 1;
  final int _historyPerPage = 10;
  bool _historyLoading = false;
  bool _historyHasMore = true;

  Future<void> _openInMaps({double? latitude, double? longitude, String? queryLabel}) async {
    try {
      Uri? uri;
      if (latitude != null && longitude != null) {
        final geoUri = Uri.parse(
            'geo:$latitude,$longitude?q=$latitude,$longitude(${Uri.encodeComponent(queryLabel ?? 'Vị trí')})');
        if (await canLaunchUrl(geoUri)) {
          uri = geoUri;
        } else {
          uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
        }
      } else if ((queryLabel ?? '').isNotEmpty) {
        final encoded = Uri.encodeComponent(queryLabel!);
        uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
      }
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _onRefresh() async {
    await _loadCars();
  }

  Future<void> _loadCars() async {
    setState(() {
      _loading = true;
    });
    final cars = await UserService.getAllCars();
    if (!mounted) return;
    if (cars.isEmpty) {
      setState(() {
        _carItems = [DropdownItem(value: 'none', label: 'Chưa có xe')];
        _selectedCarId = 'none';
        _carDetail = null;
        _loading = false;
      });
      return;
    }

    final items = cars.map((c) {
      final id = c.id.toString();
      final plate = formatLicensePlate(c.vehicleLicensePlate);
      String label = [c.typeCar, c.yearModel].where((s) => s.isNotEmpty).join(' ');
      if (label.isEmpty) label = 'Xe $id';
      if (plate.isNotEmpty) label = '$label • $plate';
      return DropdownItem(value: id, label: label);
    }).toList();

    setState(() {
      _carItems = items;
      _selectedCarId = items.first.value; // mặc định xe đầu tiên
      _loading = false;
    });

    await _loadCarDetail(items.first.value);
  }

  Future<void> _loadCarsAndSelectNewest() async {
    setState(() {
      _loading = true;
    });
    final cars = await UserService.getAllCars();
    if (!mounted) return;
    if (cars.isEmpty) {
      setState(() {
        _carItems = [DropdownItem(value: 'none', label: 'Chưa có xe')];
        _selectedCarId = 'none';
        _carDetail = null;
        _loading = false;
      });
      return;
    }

    final items = cars.map((c) {
      final id = c.id.toString();
      final plate = formatLicensePlate(c.vehicleLicensePlate);
      String label = [c.typeCar, c.yearModel].where((s) => s.isNotEmpty).join(' ');
      if (label.isEmpty) label = 'Xe $id';
      if (plate.isNotEmpty) label = '$label • $plate';
      return DropdownItem(value: id, label: label);
    }).toList();

    setState(() {
      _carItems = items;
      _selectedCarId = items.first.value; // Chọn xe đầu tiên (mới nhất)
      _loading = false;
    });

    // Tải chi tiết xe mới nhất
    await _loadCarDetail(items.first.value);

    // Hiển thị toast thành công
    AppToastHelper.showSuccess(context, message: 'Thêm xe thành công!');
  }

  Future<void> _loadCarDetail(String carId) async {
    setState(() {
      _loadingDetail = true;
    });
    final detail = await UserService.getCarById(carId);
    if (!mounted) return;
    setState(() {
      _carDetail = detail;
      _loadingDetail = false;
    });
    // Sau khi có chi tiết xe, tải lịch sử theo xe
    await _fetchHistory(reset: true);
  }

  Future<void> _fetchHistory({bool reset = false}) async {
    if (_selectedCarId == null || _selectedCarId == 'none') return;
    if (_historyLoading) return;
    setState(() {
      _historyLoading = true;
    });
    if (reset) {
      _historyPage = 1;
      _historyHasMore = true;
    }

    try {
      final res = await BookingServiceApi.getUserBookedServices(
        page: _historyPage,
        perPage: _historyPerPage,
        carId: _selectedCarId,
      );
      setState(() {
        _historyPagination = res.pagination;
        if (reset) _historyItems.clear();
        _historyItems.addAll(res.data);
        _historyHasMore = _historyItems.length < (_historyPagination?.totalItems ?? _historyItems.length);
        _historyPage += 1;
      });
    } catch (e) {
      // DebugLogger.largeJson('[MyCar] fetch history error', e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _historyLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Guard for hot-reload: nếu state cũ còn giữ Map thì reset
    if (_carDetail != null && _carDetail is! CarInfo) {
      _carDetail = null;
    }
    return Scaffold(
      backgroundColor: DesignTokens.surfacePrimary,
      body: SafeArea(
        child: Column(
          children: [
            MyHeader(
              title: 'Xe của bạn',
              rightIcon: SvgIcon(svgPath: 'assets/icons_final/more.svg', size: 24, color: DesignTokens.textPrimary),
              showRightButton: true,
              showLeftButton: false,
              onRightPressed: _openMoreMenu,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyDropdown(
                          items: _carItems,
                          selectedValue: _selectedCarId,
                          showIcon: true,
                          title: 'Chọn xe',
                          hintText: 'Chọn xe của bạn',
                          onChanged: (val) {
                            print('[MyCarScreen] Dropdown changed: $val');
                            if (val == null || val == _selectedCarId) return;

                            // Delay một chút để đảm bảo dropdown đã đóng hoàn toàn
                            Future.delayed(const Duration(milliseconds: 100), () {
                              if (!mounted) return;
                              setState(() {
                                _selectedCarId = val;
                              });
                              if (val != 'none') {
                                _loadCarDetail(val);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        if (_loading || _loadingDetail) ...[
                          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                        ] else if (_carDetail == null) ...[
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: MyText(
                              text: 'Không có dữ liệu xe',
                              textStyle: 'body',
                              textSize: '16',
                              textColor: 'primary',
                              textAlign: TextAlign.start,
                            ),
                          ),
                        ] else ...[
                          _buildCarSummary(),
                          const SizedBox(height: 16),
                          _buildHistorySection(),
                          const SizedBox(height: 120), // chừa chỗ cho sticky button
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: DesignTokens.surfacePrimary,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32 + 64),
          child: MyButton(
            text: 'Tạo yêu cầu',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/create-request',
                arguments: {'selectedCarId': _selectedCarId, 'carInfo': _carDetail},
              );
            },
          ),
        ),
      ),
    );
  }

  void _openMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildListTile('Thêm xe mới', 'assets/icons_final/add.svg', _onAddCar),
                const SizedBox(height: 8),
                _buildListTile('Sửa thông tin', 'assets/icons_final/edit-2.svg', _onEditCar),
                const SizedBox(height: 8),
                _buildListTile('Xóa xe', 'assets/icons_final/trash.svg', _onDeleteCar, isLast: true),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onAddCar() {
    Navigator.pushNamed(context, '/add-car').then((value) {
      if (value is Map && value['created'] == true) {
        // Đóng modal bottom sheet nếu đang mở
        Navigator.of(context).pop();

        // Tải lại danh sách xe và chọn xe mới nhất
        _loadCarsAndSelectNewest();
      }
    });
  }

  void _onEditCar() {
    if (_selectedCarId == null || _selectedCarId == 'none' || _carDetail == null) {
      AppToastHelper.showWarning(context, message: 'Vui lòng chọn xe để sửa');
      return;
    }

    Navigator.pushNamed(context, '/edit-car', arguments: {'carInfo': _carDetail}).then((value) {
      if (value is Map && value['updated'] == true) {
        // Đóng modal bottom sheet nếu đang mở
        Navigator.of(context).pop();

        // Tải lại thông tin xe
        _loadCarDetail(_selectedCarId!);

        // Hiển thị toast thành công
        AppToastHelper.showSuccess(context, message: 'Cập nhật xe thành công!');
      }
    });
  }

  void _onDeleteCar() {
    if (_selectedCarId == null || _selectedCarId == 'none') return;
    final carId = _selectedCarId!;
    AppDialogHelper.confirm(
      context,
      title: 'Xóa xe',
      message: 'Nếu xóa xe sẽ mất toàn bộ thông tin đi kèm và các đơn hàng của xe. Bạn vẫn muốn xóa chứ?',
      confirmText: 'Xóa',
      confirmButtonType: ButtonType.delete,
      type: AppDialogType.warning,
    ).then((confirmed) async {
      if (confirmed != true) return;
      // Gọi API xóa
      final ok = await UserService.deleteCar(carId);
      if (!mounted) return;
      if (ok) {
        // Đóng modal bottom sheet
        Navigator.of(context).pop();

        AppToastHelper.showSuccess(context, message: 'Xóa xe thành công');
        await _loadCars();
      } else {
        AppToastHelper.showError(context, message: 'Không thể xóa xe. Vui lòng thử lại sau.');
      }
    });
  }

  Widget _buildListTile(String title, String iconPath, VoidCallback onTap, {bool isLast = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: isLast ? 0 : 4),
        child: SizedBox(
          height: 36,
          child: Row(
            children: [
              SvgIcon(svgPath: iconPath, color: isLast ? DesignTokens.alertError : DesignTokens.primaryBlue, size: 20),
              const SizedBox(width: 12),
              MyText(text: title, textStyle: 'label', textSize: '16', textColor: isLast ? 'error' : 'primary'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarSummary() {
    final plate = formatLicensePlate(_carDetail!.vehicleLicensePlate);
    final typeCar = _carDetail!.typeCar;
    final yearModel = _carDetail!.yearModel;

    // Tạo danh sách files để hiển thị
    List<FileInfo> filesToShow = [];
    if (_carDetail!.listFiles != null && _carDetail!.listFiles!.isNotEmpty) {
      filesToShow = _carDetail!.listFiles!;
    } else if (_carDetail!.files != null) {
      filesToShow = [_carDetail!.files!];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(color: DesignTokens.surfaceSecondary),
                child: filesToShow.isNotEmpty
                    ? ImageCarouselWidget(
                        files: filesToShow,
                        height: 160,
                        showPageIndicators: true,
                        autoPlay: true,
                        onImageTap: (index) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullscreenImageViewer(files: filesToShow, initialIndex: index),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: SvgIcon(
                          svgPath: 'assets/icons_final/car.svg',
                          size: 56,
                          color: DesignTokens.textSecondary,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: typeCar,
                  textStyle: 'title',
                  textSize: '16',
                  textColor: 'primary',
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    MyText(text: 'Đời xe: ', textStyle: 'body', textSize: '14', textColor: 'tertiary'),
                    MyText(text: yearModel, textStyle: 'body', textSize: '14', textColor: 'primary'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    MyText(text: 'Biển số: ', textStyle: 'body', textSize: '14', textColor: 'tertiary'),
                    MyText(text: plate, textStyle: 'body', textSize: '14', textColor: 'primary'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MyText(
          text: 'Lịch sử thực hiện',
          textStyle: 'title',
          textSize: '16',
          textColor: 'primary',
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 12),
        if (_historyLoading && _historyItems.isEmpty) ...[
          const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: CircularProgressIndicator())),
        ] else if (_historyItems.isEmpty) ...[
          const MyText(
            text: 'Không có lịch sử thực hiện',
            textStyle: 'body',
            textSize: '14',
            textColor: 'tertiary',
            textAlign: TextAlign.start,
          ),
        ] else ...[
          for (int i = 0; i < _historyItems.length; i++) ...[
            _buildHistoryCard(_historyItems[i]),
            if (i != _historyItems.length - 1) const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          if (_historyHasMore)
            SizedBox(
              height: 40,
              width: double.infinity,
              child: MyButton(
                text: _historyLoading ? 'Đang tải...' : 'Tải thêm',
                buttonType: ButtonType.secondary,
                onPressed: _historyLoading ? null : () => _fetchHistory(),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildHistoryCard(BookingModel item) {
    final garageName = item.quotation?.inforGarage?.nameGarage ?? '';
    final address = item.quotation?.inforGarage?.address ?? '';
    double? _toDouble(String? v) => v == null ? null : double.tryParse(v);
    final double? latitude = _toDouble(item.quotation?.inforGarage?.latitude);
    final double? longitude = _toDouble(item.quotation?.inforGarage?.longitude);
    final timeText = item.time != null ? _formatDateTime(item.time!) : '';
    final description = item.requestService?.description ?? '';
    final remain = item.quotation?.remainPrice ?? 0;

    return Container(
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
                      MyText(text: garageName, textStyle: 'head', textSize: '16', textColor: 'brand'),
                      MyText(
                        text: item.requestService?.requestCode ?? '',
                        textStyle: 'body',
                        textSize: '12',
                        textColor: 'tertiary',
                      ),
                    ],
                  ),
                ),
                StatusWidget(status: item.status, type: StatusType.booking),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MyText(text: 'Địa chỉ: ', textStyle: 'body', textSize: '14', textColor: 'tertiary'),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openInMaps(
                      latitude: latitude,
                      longitude: longitude,
                      queryLabel: address,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: MyText(
                            text: address,
                            textStyle: 'body',
                            textSize: '14',
                            textColor: 'primary',
                            maxLines: null,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SvgIcon(
                          svgPath: 'assets/icons_final/map.svg',
                          size: 20,
                          color: DesignTokens.textBrand,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MyText(text: 'Thời gian: ', textStyle: 'body', textSize: '14', textColor: 'tertiary'),
                MyText(text: timeText, textStyle: 'body', textSize: '14', textColor: 'primary'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MyText(text: 'Dịch vụ: ', textStyle: 'body', textSize: '14', textColor: 'tertiary'),
                Expanded(child: MyText(text: description, textStyle: 'body', textSize: '14', textColor: 'primary')),
              ],
            ),
            if (item.status != 3) ...[
              const SizedBox(height: 8),
              const Divider(color: DesignTokens.borderBrandSecondary, height: 1),
              const SizedBox(height: 8),
            ],
            if (item.quotation != null) ...[
              if (item.status != 3)
                Row(
                  children: [
                    MyText(
                      text: item.status == 2 ? 'Đã thanh toán: ' : 'Còn phải thanh toán: ',
                      textStyle: 'body',
                      textSize: '14',
                      textColor: 'tertiary',
                    ),
                    MyText(text: _formatMoney(remain), textStyle: 'title', textSize: '16', textColor: 'brand'),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
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

  String _formatDateTime(DateTime dt) {
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)} ${two(dt.day)}/${two(dt.month)}/${dt.year}';
  }
}
