import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gara/theme/color.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/utils/formatters.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/dropdown.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/widgets/smart_image_picker.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/text_field.dart';
import 'package:gara/services/user/user_service.dart';
import 'package:gara/widgets/app_toast.dart';
import 'package:gara/services/location/goong_place_service.dart';
import 'package:uuid/uuid.dart';
import 'package:gara/services/request/request_service.dart';
import 'package:gara/widgets/keyboard_dismiss_wrapper.dart';

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
  final ScrollController _suggestionScrollController = ScrollController();
  List<DropdownItem> _carItems = [];
  String? _selectedCar;
  final int _maxImages = 3;
  bool _isLoading = false;

  String? _preSelectedCarId;

  // Autocomplete state
  Timer? _debounce;
  List<GoongAutocompletePrediction> _addressSuggestions = [];
  bool _isSearchingAddress = false;
  String _goongSessionToken = const Uuid().v4();
  double? _selectedLat;
  double? _selectedLng;
  int? _nearbyGarageCount;
  bool _isRadiusSearching = false;
  Timer? _radiusDebounce;

  @override
  void initState() {
    super.initState();
    // Nhận arguments từ màn hình trước
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        final selectedCarId = args['selectedCarId'] as String?;
        if (selectedCarId != null && selectedCarId != 'none') {
          _preSelectedCarId = selectedCarId;
        }
      }
    });
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

      // Ưu tiên chọn xe từ arguments, nếu không có thì chọn xe đầu tiên
      if (_preSelectedCarId != null && _carItems.any((item) => item.value == _preSelectedCarId)) {
        _selectedCar = _preSelectedCarId;
      } else {
        _selectedCar = _carItems.first.value;
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _suggestionScrollController.dispose();
    _debounce?.cancel();
    _radiusDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.white['c900'],
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          color: DesignTokens.surfaceSecondary,
          child: SizedBox(
            width: double.infinity,
            child: _buildSubmitButton(),
          ),
        ),
      ),
      body: KeyboardDismissWrapper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyHeader(
              title: 'Tạo yêu cầu',
              showLeftButton: true,
              showRightButton: true,
              rightIcon: SvgIcon(svgPath: 'assets/icons_final/more.svg', size: 24, color: DesignTokens.textPrimary),
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
                  if (_selectedLat != null && _selectedLng != null && _addressController.text.trim().isNotEmpty) ...[
                    _buildSearchRadiusSection(),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyTextField(
          controller: _addressController,
          hintText: 'Vị trí của bạn',
          obscureText: false,
          hasError: false,
          label: 'Vị trí của bạn',
          suffixIcon: _isSearchingAddress
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : SvgIcon(svgPath: 'assets/icons_final/map.svg', size: 20),
          onChange: _onAddressChanged,
        ),
        if (_addressSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: DesignTokens.surfacePrimary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DesignTokens.getBorderColor('secondary')),
            ),
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView.separated(
              controller: _suggestionScrollController,
              shrinkWrap: true,
              itemCount: _addressSuggestions.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: DesignTokens.getBorderColor('secondary')),
              itemBuilder: (ctx, i) {
                final s = _addressSuggestions[i];
                final title = s.mainText?.isNotEmpty == true ? s.mainText! : s.description;
                final subtitle = s.secondaryText;
                return ListTile(
                  title: MyText(text: title, textStyle: 'title', textSize: '14', textColor: 'primary'),
                  subtitle: subtitle != null
                      ? MyText(text: subtitle, textStyle: 'body', textSize: '14', textColor: 'tertiary')
                      : null,
                  onTap: () => _onSelectSuggestion(s),
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading:
                      SvgIcon(svgPath: 'assets/icons_final/location.svg', size: 18, color: DesignTokens.textTertiary),
                );
              },
            ),
          ),
      ],
    );
  }

  void _onAddressChanged(String value) {
    // ignore: avoid_print
    print('[UI] Address changed: "$value"');
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _addressSuggestions = [];
        _isSearchingAddress = false;
      });
      // ignore: avoid_print
      print('[UI] Skip autocomplete (too short)');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isSearchingAddress = true);
      try {
        // ignore: avoid_print
        print('[UI] Trigger autocomplete for "$value"');
        final results = await GoongPlaceService.autocomplete(
          input: value.trim(),
          sessionToken: _goongSessionToken,
          limit: 10,
          moreCompound: true,
        );
        if (!mounted) return;
        setState(() => _addressSuggestions = results);
        // ignore: avoid_print
        print('[UI] Suggestions count: ${results.length}');
      } finally {
        if (mounted) setState(() => _isSearchingAddress = false);
      }
    });
  }

  Future<void> _onSelectSuggestion(GoongAutocompletePrediction s) async {
    setState(() {
      _addressController.text = s.description;
      _addressSuggestions = [];
    });
    // ignore: avoid_print
    print('[UI] Select suggestion: placeId=${s.placeId}');
    final detail = await GoongPlaceService.getPlaceDetail(placeId: s.placeId, sessionToken: _goongSessionToken);
    if (detail != null) {
      setState(() {
        _selectedLat = detail.lat;
        _selectedLng = detail.lng;
      });
      _fetchGaragesInRadius();
      // ignore: avoid_print
      print('[UI] Detail: lat=${detail.lat}, lng=${detail.lng}, addr=${detail.formattedAddress}');
    } else {
      // ignore: avoid_print
      print('[UI] Detail: null');
    }
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
        MyText(text: 'Hình ảnh', textStyle: 'title', textSize: '16', textColor: 'primary'),
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
                    AppToastHelper.showWarning(context, message: 'Chỉ được thêm tối đa 3 ảnh dịch vụ');
                    return;
                  }
                  setState(() => _attachedImages.add(file));
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _attachedImages.isNotEmpty
                    ? SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (ctx, i) => _fileThumb(_attachedImages[i], () {
                            setState(() => _attachedImages.removeAt(i));
                          }),
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
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
              decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
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
            MyText(text: 'Bán kính tìm kiếm', textStyle: 'title', textSize: '16', textColor: 'primary'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                MyText(
                  text: '${_searchRadius.toStringAsFixed(0)}km ',
                  textStyle: 'title',
                  textSize: '16',
                  textColor: 'brand',
                ),
                MyText(text: ' ( có ', textStyle: 'body', textSize: '14', textColor: 'tertiary'),
                // if (_isRadiusSearching)
                //   Baseline(
                //     baseline: 12,
                //     baselineType: TextBaseline.alphabetic,
                //     child: SizedBox(
                //       width: 12,
                //       height: 12,
                //       child: CircularProgressIndicator(
                //         strokeWidth: 2,
                //         valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.surfaceBrand),
                //       ),
                //     ),
                //   )
                // else
                MyText(
                  text: (_nearbyGarageCount ?? 0).toString(),
                  textStyle: 'title',
                  textSize: '16',
                  textColor: 'brand',
                ),
                MyText(text: ' garage )', textStyle: 'body', textSize: '14', textColor: 'tertiary'),
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
            onChanged: (_selectedLat != null && _selectedLng != null && _addressController.text.trim().isNotEmpty)
                ? (value) {
                    setState(() => _searchRadius = value.roundToDouble());
                    _radiusDebounce?.cancel();
                    _radiusDebounce = Timer(const Duration(milliseconds: 400), _fetchGaragesInRadius);
                  }
                : null,
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

  Future<void> _fetchGaragesInRadius() async {
    if (!mounted) return;
    final lat = _selectedLat;
    final lng = _selectedLng;
    final addr = _addressController.text.trim();
    if (lat == null || lng == null || addr.isEmpty) return;

    setState(() {
      _isRadiusSearching = true;
    });
    try {
      final res = await RequestServiceApi.getGaragesInRadius(
        latitude: lat,
        longitude: lng,
        radiusKm: _searchRadius,
      );
      if (!mounted) return;
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>?;
        final total = data != null ? (data['total'] as num?) : null;
        setState(() {
          _nearbyGarageCount = total?.toInt() ?? 0;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRadiusSearching = false;
        });
      }
    }
  }

  Widget _buildSubmitButton() {
    return MyButton(
      text: _isLoading ? 'Đang gửi yêu cầu...' : 'Gửi yêu cầu và nhận báo giá',
      onPressed: _isLoading
          ? null
          : () async {
              if (_isLoading) return; // Ngăn ấn nhiều lần khi đang loading

              setState(() {
                _isLoading = true;
              });

              try {
                // Gửi theo yêu cầu backend: address (label), latitude, longitude (riêng)
                final ok = await UserService.createRequest(
                  carId: _selectedCar ?? '',
                  address: _addressController.text,
                  description: _descriptionController.text,
                  radiusSearch: '${_searchRadius.round()}km',
                  latitude: _selectedLat?.toString(),
                  longitude: _selectedLng?.toString(),
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
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
      buttonType: _isLoading ? ButtonType.disable : ButtonType.primary,
    );
  }

  // Không cần build JSON cho address khi gửi; backend yêu cầu 3 trường riêng lẻ
}
