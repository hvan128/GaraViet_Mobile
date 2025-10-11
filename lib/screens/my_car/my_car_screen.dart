import 'package:flutter/material.dart';
import 'package:gara/theme/index.dart';
import 'package:gara/utils/debug_logger.dart';
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

    final items =
        cars.map((c) {
          final id = c.id.toString();
          final plate = formatLicensePlate(c.vehicleLicensePlate);
          String label = [
            c.typeCar,
            c.yearModel,
          ].where((s) => s.isNotEmpty).join(' ');
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

  Future<void> _loadCarDetail(String carId) async {
    setState(() {
      _loadingDetail = true;
    });
    final detail = await UserService.getCarById(carId);
    DebugLogger.largeJson('[MyCarScreen] detail', detail);
    if (!mounted) return;
    setState(() {
      _carDetail = detail;
      _loadingDetail = false;
    });
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
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyHeader(
                  title: 'Xe của bạn',
                  rightIcon: SvgIcon(
                    svgPath: 'assets/icons_final/more.svg',
                    size: 24,
                    color: DesignTokens.textPrimary,
                  ),
                  showRightButton: true,
                  showLeftButton: false,
                  onRightPressed: _openMoreMenu,
                ),
                Padding(
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
                          if (val == null || val == _selectedCarId) return;
                          setState(() {
                            _selectedCarId = val;
                          });
                          if (val != 'none') {
                            _loadCarDetail(val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_loading || _loadingDetail) ...[
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        ),
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
                        const SizedBox(height: 24),
                        MyButton(
                          text: 'Tạo yêu cầu',
                          onPressed: () {
                            Navigator.pushNamed(context, '/create-request');
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ],
            ),
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
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildListTile(
                  'Thêm xe mới',
                  'assets/icons_final/add.svg',
                  _onAddCar,
                ),
                const SizedBox(height: 8),
                _buildListTile(
                  'Sửa thông tin',
                  'assets/icons_final/edit-2.svg',
                  _onEditCar,
                ),
                const SizedBox(height: 8),
                _buildListTile(
                  'Xóa xe',
                  'assets/icons_final/trash.svg',
                  _onDeleteCar,
                  isLast: true,
                ),
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
        _onRefresh();
      }
    });
  }
  void _onEditCar() {
    // TODO: implement _onEditCar
  }
  void _onDeleteCar() {
    if (_selectedCarId == null || _selectedCarId == 'none') return;
    final carId = _selectedCarId!;
    AppDialogHelper.confirm(
      context,
      title: 'Xóa xe',
      message:
          'Nếu xóa xe sẽ mất toàn bộ thông tin đi kèm và các đơn hàng của xe. Bạn vẫn muốn xóa chứ?',
      confirmText: 'Xóa',
      confirmButtonType: ButtonType.delete,
      type: AppDialogType.warning,
    ).then((confirmed) async {
      if (confirmed != true) return;
      // Gọi API xóa
      final ok = await UserService.deleteCar(carId);
      if (!mounted) return;
      if (ok) {
        AppToastHelper.showSuccess(
          context,
          message: 'Xóa xe thành công',
        );
        await _loadCars();
      } else {
        AppToastHelper.showError(
          context,
          message: 'Không thể xóa xe. Vui lòng thử lại sau.',
        );
      }
    });
  }

  Widget _buildListTile(
    String title,
    String iconPath,
    VoidCallback onTap, {
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: isLast ? 0 : 4),
        child: SizedBox(
          height: 36,
          child: Row(
            children: [
              SvgIcon(
                svgPath: iconPath,
                color:
                    isLast ? DesignTokens.alertError : DesignTokens.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 12),
              MyText(
                text: title,
                textStyle: 'label',
                textSize: '16',
                textColor: isLast ? 'error' : 'primary',
              ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: DesignTokens.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SvgIcon(
                  svgPath: 'assets/icons_final/car.svg',
                  size: 56,
                  color: DesignTokens.textSecondary,
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
                    MyText(
                      text: 'Đời xe: ',
                      textStyle: 'body',
                      textSize: '14',
                      textColor: 'tertiary',
                    ),
                    MyText(
                      text: yearModel,
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
                      text: 'Biển số: ',
                      textStyle: 'body',
                      textSize: '14',
                      textColor: 'tertiary',
                    ),
                    MyText(
                      text: plate,
                      textStyle: 'body',
                      textSize: '14',
                      textColor: 'primary',
                    ),
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
      children: const [
        MyText(
          text: 'Lịch sử thực hiện',
          textStyle: 'title',
          textSize: '16',
          textColor: 'primary',
          textAlign: TextAlign.start,
        ),
        SizedBox(height: 12),
        MyText(
          text: 'Không có lịch sử thực hiện',
          textStyle: 'body',
          textSize: '14',
          textColor: 'tertiary',
          textAlign: TextAlign.start,
        ),
        // TODO: bind real history list when API available
      ],
    );
  }
}
