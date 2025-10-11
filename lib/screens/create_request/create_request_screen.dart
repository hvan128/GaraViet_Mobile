import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gara/theme/color.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/dropdown.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/widgets/smart_image_picker.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/text_field.dart';
import 'package:gara/services/user/user_service.dart';
import 'package:gara/utils/format.dart';
import 'package:gara/widgets/app_toast.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  double _searchRadius = 7;
  final List<File> _attachedImages = [];
  final TextEditingController _addressController = TextEditingController();
  List<DropdownItem> _carItems = [];
  String? _selectedCar;
  final int _maxImages = 3;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    final cars = await UserService.getAllCars();
    if (!mounted) return;
    setState(() {
      _carItems = cars.map((c) {
        final id = c.id.toString();
        final plate = formatLicensePlate(c.vehicleLicensePlate);
        String label = [c.typeCar, c.yearModel].where((s) => s.isNotEmpty).join(' ');
        if (plate.isNotEmpty) label = '$label • $plate';
        return DropdownItem(value: id, label: label.isEmpty ? 'Xe $id' : label);
      }).toList();
      if (_carItems.isEmpty) {
        _carItems = [DropdownItem(value: 'none', label: 'Chưa có xe')];
      }
      _selectedCar = _carItems.first.value;
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.white['c900'],

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyHeader(
                title: 'Tạo yêu cầu',
                showLeftButton: true,
                showRightButton: true,
                rightIcon: SvgIcon(
                  svgPath: 'assets/icons_final/more.svg',
                  size: 24,
                  color: DesignTokens.textPrimary,
                ),
                onRightPressed: () {},
                onLeftPressed: () => Navigator.pop(context),
              ),
              Container(
                decoration: BoxDecoration(color: DesignTokens.surfaceSecondary),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildCarSection(),
                    const SizedBox(height: 16),
                    _buildLocationSection(),
                    const SizedBox(height: 16),
                    _buildDescriptionSection(),
                    const SizedBox(height: 16),
                    _buildAttachmentsSection(),
                    const SizedBox(height: 16),
                    _buildSearchRadiusSection(),
                    const SizedBox(height: 16),
                    _buildSubmitButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarSection() {
    return MyDropdown(
      items: _carItems,
      label: 'Xe của bạn',
      selectedValue: _selectedCar,
      onChanged: (value) {
        setState(() {
          _selectedCar = value;
        });
      },
    );
  }

  Widget _buildLocationSection() {
    return MyTextField(
      controller: _addressController,
      hintText: 'Vị trí của bạn',
      obscureText: false,
      hasError: false,
      label: 'Vị trí của bạn',
      suffixIcon: SvgIcon(svgPath: 'assets/icons_final/map.svg', size: 20),
     );
  }

  Widget _buildDescriptionSection() {
    return MyTextField(
      hintText: 'Mô tả yêu cầu',
      obscureText: false,
      hasError: false,
      maxLines: 5,
      height: 144,
      label: 'Mô tả yêu cầu',
      onChange: (value) {
        setState(() {
          _descriptionController.text = value;
        });
      },
    );
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          text: 'Hình ảnh',
          textStyle: 'title',
          textSize: '16',
          textColor: 'primary',
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              SmartImagePicker(
                label: 'Thêm ảnh dịch vụ',
                showPreview: false,
                onImageSelected: (file) {
                  if (file == null) return;
                  if (_attachedImages.length >= _maxImages) {
                    AppToastHelper.showWarning(
                      context,
                      message: 'Chỉ được thêm tối đa 3 ảnh dịch vụ',
                    );
                    return;
                  }
                  setState(() => _attachedImages.add(file));
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child:
                    _attachedImages.isNotEmpty
                        ? SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder:
                                (ctx, i) => _fileThumb(_attachedImages[i], () {
                                  setState(() => _attachedImages.removeAt(i));
                                }),
                            separatorBuilder:
                                (_, __) => const SizedBox(width: 12),
                            itemCount: _attachedImages.length,
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }

   Widget _fileThumb(File file, VoidCallback onRemove) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildSearchRadiusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MyText(
              text: 'Bán kính tìm kiếm',
              textStyle: 'title',
              textSize: '16',
              textColor: 'primary',
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                MyText(
                  text: '${_searchRadius}km ',
                  textStyle: 'title',
                  textSize: '16',
                  textColor: 'brand',
                ),
                MyText(
                  text: ' ( có ',
                  textStyle: 'body',
                  textSize: '14',
                  textColor: 'tertiary',
                ),
                MyText(
                  text: '8',
                  textStyle: 'title',
                  textSize: '16',
                  textColor: 'brand',
                ),
                MyText(
                  text: ' garage )',
                  textStyle: 'body',
                  textSize: '14',
                  textColor: 'tertiary',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Labels above the slider
       
        // Slider theo mẫu, không padding hai bên và track bo tròn
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackShape: const RoundedRectSliderTrackShape(),
            activeTrackColor: DesignTokens.surfaceBrand,
            inactiveTrackColor: DesignTokens.borderBrandSecondary,
            thumbColor: DesignTokens.surfaceBrand,
            overlayColor: Colors.transparent,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            trackHeight: 6,
          ),
          child: Slider(
            padding: EdgeInsets.zero,
            value: _searchRadius,
            min: 5.0,
            max: 50.0,
            divisions: 45,
            onChanged: (value) => setState(() => _searchRadius = value),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            MyText(text: '5km', textStyle: 'label', textSize: '14', textColor: 'tertiary'),
            MyText(text: '50km', textStyle: 'label', textSize: '14', textColor: 'tertiary'),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return MyButton(
      text: 'Gửi yêu cầu và nhận báo giá',
      onPressed: () async {
        final ok = await UserService.createRequest(
          carId: _selectedCar ?? '',
          address: _addressController.text,
          description: _descriptionController.text,
          radiusSearch: '${_searchRadius.round()}km',
          files: _attachedImages,
        );
        if (!mounted) return;
        
        if (ok) {
          // Gửi thành công - navigate về main tại tab yêu cầu
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (route) => false,
            arguments: {'selectedTab': 1}, // Tab yêu cầu
          );
          AppToastHelper.showSuccess(context, message: 'Gửi yêu cầu thành công');
        } else {
          AppToastHelper.showError(context, message: 'Gửi yêu cầu thất bại');
        }
      },
      buttonType: ButtonType.primary,
    );
  }
}
