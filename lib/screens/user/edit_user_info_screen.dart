import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gara/models/file/file_info_model.dart';
import 'package:gara/models/user/user_info_model.dart';
import 'package:gara/widgets/header.dart';
import 'package:gara/widgets/keyboard_dismiss_wrapper.dart';
import 'package:gara/widgets/smart_image_picker.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/widgets/text_field.dart';
import 'package:flutter/services.dart';
import 'package:gara/services/user/user_service.dart';
import 'package:gara/utils/url.dart';
import 'package:gara/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:gara/widgets/app_toast.dart';

class EditUserInfoScreen extends StatefulWidget {
  final UserInfoResponse userInfo;
  const EditUserInfoScreen({super.key, required this.userInfo});

  @override
  State<EditUserInfoScreen> createState() => _EditUserInfoScreenState();
}

class _EditUserInfoScreenState extends State<EditUserInfoScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _fromCtrl = TextEditingController();
  
  // Garage-specific fields
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _workerCtrl = TextEditingController();
  final TextEditingController _servicesCtrl = TextEditingController();
  File? _avatarFile;
  final List<File> _serviceImages = [];
  final List<File> _certificateImages = [];
  late List<FileInfo> _currentServiceFiles; // Files hiện tại từ server
  late List<FileInfo> _currentCertificateFiles; // Files hiện tại từ server
  static const int _maxServiceImages = 3;
  static const int _maxCertificateImages = 3;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    
    // Kiểm tra nếu là gara thì sử dụng nameGarage, không thì dùng name
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.isGarageUser) {
      _nameCtrl.text = widget.userInfo.nameGarage ?? widget.userInfo.name;
    } else {
    _nameCtrl.text = widget.userInfo.name;
    }
    
    _phoneCtrl.text = widget.userInfo.phone;
    _addressCtrl.text = widget.userInfo.address ?? '';
    _descCtrl.text = widget.userInfo.descriptionGarage ?? '';
    _fromCtrl.text = _extractYear(widget.userInfo.createdAt);
   
    // Initialize garage-specific fields
    _emailCtrl.text = widget.userInfo.emailGarage ?? '';
    _workerCtrl.text = widget.userInfo.numberOfWorker ?? '';
    _servicesCtrl.text = widget.userInfo.servicesProvided ?? '';
    
    // Initialize current files from user info
    _currentServiceFiles = widget.userInfo.listFileAvatar ?? [];
    _currentCertificateFiles = widget.userInfo.listFileCertificate ?? [];
    
    // debugPrint('[EditUserInfoScreen] Current service files: ${_currentServiceFiles.length}');
    // debugPrint('[EditUserInfoScreen] Current certificate files: ${_currentCertificateFiles.length}');
    // debugPrint('[EditUserInfoScreen] listFileAvatar: ${widget.userInfo.listFileAvatar}');
    // debugPrint('[EditUserInfoScreen] listFileCertificate: ${widget.userInfo.listFileCertificate}');
    
    // Debug chi tiết từng file
    for (int i = 0; i < _currentServiceFiles.length; i++) {
      final file = _currentServiceFiles[i];
      // debugPrint('[EditUserInfoScreen] Service file $i: id=${file.id}, name=${file.name}, path=${file.path}');
    }
    
    for (int i = 0; i < _currentCertificateFiles.length; i++) {
      final file = _currentCertificateFiles[i];
      // debugPrint('[EditUserInfoScreen] Certificate file $i: id=${file.id}, name=${file.name}, path=${file.path}');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _descCtrl.dispose();
    _fromCtrl.dispose();
    _emailCtrl.dispose();
    _workerCtrl.dispose();
    _servicesCtrl.dispose();
    super.dispose();
  }

  String _extractYear(String? date) {
    if (date == null || date.isEmpty) return '';
    try {
      final dt = DateTime.parse(date);
      return dt.year.toString();
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.surfaceSecondary,
      body: SafeArea(
        child: KeyboardDismissWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyHeader(
                height: 56,
                backgroundColor: DesignTokens.surfaceBrand,
                customTitle: const MyText(
                  text: 'Chỉnh sửa hồ sơ',
                  textStyle: 'head',
                  textSize: '16',
                  textColor: 'invert',
                ),
                showRightButton: true,
                rightIcon: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
                onRightPressed: _onSubmit,
                leftIconColor: DesignTokens.textInvert,
                rightIconColor: DesignTokens.textInvert,
                onLeftPressed: () {
                  Navigator.of(context).pop(_hasChanges);
                },
              ),
              Container(height: 12, color: DesignTokens.surfaceBrand,),
              _buildHeroEdit(),
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  // Nếu không phải garage user thì chỉ hiển thị trường tên
                  if (!userProvider.isGarageUser) {
                    return const SizedBox.shrink();
                  }
                  
                  // Nếu là garage user thì hiển thị tất cả các trường
                  return Container(
                    decoration: const BoxDecoration(
                      color: DesignTokens.surfaceSecondary,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: MyTextField(
                                  label: 'Hoạt động từ',
                                  controller: _fromCtrl,
                                  obscureText: false,
                                  hasError: false,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: MyTextField(
                                  label: 'Địa chỉ',
                                  controller: _addressCtrl,
                                  obscureText: false,
                                  hasError: false,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          MyTextField(
                            obscureText: false,
                            hasError: false,
                            label: 'Mô tả',
                            controller: _descCtrl,
                            height: 144,
                            maxLines: 6,
                          ),
                          const SizedBox(height: 12),
                          MyTextField(
                            label: 'Dịch vụ cung cấp và chuyên môn',
                            controller: _servicesCtrl,
                            obscureText: false,
                            hasError: false,
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
                                    if (_serviceImages.length >= _maxServiceImages) {
                                      AppToastHelper.showWarning(
                                        context,
                                        message: 'Chỉ được thêm tối đa 3 ảnh dịch vụ',
                                      );
                                      return;
                                    }
                                    setState(() => _serviceImages.add(file));
                                  },
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildServiceImagesDisplay(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          MyText(text: 'Chứng chỉ', textStyle: 'label', textSize: '16', textColor: 'primary',),
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              children: [
                                 SmartImagePicker(label: 'Thêm chứng chỉ', showPreview: false, onImageSelected: (file) {
                                   if (file == null) return;
                                   if (_certificateImages.length >= _maxCertificateImages) {
                                     AppToastHelper.showWarning(
                                       context,
                                       message: 'Chỉ được thêm tối đa 1 ảnh chứng chỉ',
                                     );
                                     return;
                                   }
                                   setState(() => _certificateImages.add(file));
                                 }),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildCertificateImagesDisplay(),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
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

  Widget _buildHeroEdit() {
    return Container(
      color: DesignTokens.surfaceSecondary,
      height: 160,
      width: double.infinity,
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                height: 70,
                decoration: const BoxDecoration(
                  color: DesignTokens.surfaceBrand,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
          Positioned(
            top: 0,
            left: 16,
            right: 16,
            child: Container(
              height: 152,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DesignTokens.surfacePrimary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _showAvatarPickerSheet,
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Viền tròn trắng
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                          // Ảnh hiện tại (ưu tiên ảnh mới chọn), sau đó tới ảnh cũ từ server
                          ClipOval(
                            child:
                                _avatarFile != null
                                    ? Image.file(
                                      _avatarFile!,
                                      fit: BoxFit.cover,
                                    )
                                    : (widget.userInfo.avatarPath != null && widget.userInfo.avatarPath!.isNotEmpty)
                                    ? (resolveImageUrl(widget.userInfo.avatarPath!) != null
                                        ? Image.network(resolveImageUrl(widget.userInfo.avatarPath!)!, fit: BoxFit.cover)
                                        : Container(color: DesignTokens.surfaceBrand))
                                    : Container(
                                      color: DesignTokens.surfaceBrand,
                                    ),
                          ),
                          // Lớp phủ đen + icon camera
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const SvgIcon(
                              svgPath: 'assets/icons_final/camera.svg',
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  MyTextField(
                    controller: _nameCtrl,
                    obscureText: false,
                    hasError: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAvatarPickerSheet() async {
    File? result;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const MyText(text: 'Chọn từ thư viện'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  result = await _pickFromGallery();
                  if (!mounted || result == null) return;
                  setState(() => _avatarFile = result);
                  final ok = await UserService.uploadAvatar(result!);
                  if (!mounted) return;
                  AppToastHelper.showInfo(
                    context,
                    message: ok ? 'Tải ảnh đại diện thành công' : 'Tải ảnh đại diện thất bại',
                  );
                  if (ok) _hasChanges = true;
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const MyText(text: 'Chụp ảnh mới'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  result = await _pickFromCamera();
                  if (!mounted || result == null) return;
                  setState(() => _avatarFile = result);
                  final ok = await UserService.uploadAvatar(result!);
                  if (!mounted) return;
                  AppToastHelper.showInfo(
                    context,
                    message: ok ? 'Tải ảnh đại diện thành công' : 'Tải ảnh đại diện thất bại',
                  );
                  if (ok) _hasChanges = true;
                },
              ),
              if (_avatarFile != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const MyText(text: 'Xóa ảnh'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() => _avatarFile = null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<File?> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? img = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      return img != null ? File(img.path) : null;
    } catch (_) {
      return null;
    }
  }

  Future<File?> _pickFromCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? img = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      return img != null ? File(img.path) : null;
    } catch (_) {
      return null;
    }
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

  Future<void> _onSubmit() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final isGarageUser = userProvider.isGarageUser;
      
      // Kiểm tra có thay đổi không
      bool hasChanges = false;
      if (isGarageUser) {
        hasChanges = _hasGarageChanges();
      } else {
        hasChanges = _hasUserChanges();
      }
      
      // Nếu không có thay đổi gì thì không cần gọi API
      if (!hasChanges) {
        if (mounted) {
          AppToastHelper.showInfo(
            context,
            message: 'Không có thay đổi nào để cập nhật',
          );
          Navigator.of(context).pop(false);
        }
        return;
      }

      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // debugPrint('[EditUserInfoScreen] Updating user info, isGarage: $isGarageUser');
      
      if (isGarageUser) {
        // Gara: Gọi 3 API
        await _updateGarageInfo();
      } else {
        // User thường: Gọi 1 API
        await _updateUserInfo();
      }

      // Đóng loading dialog
      if (mounted) Navigator.of(context).pop();

      // Cập nhật UserProvider với thông tin mới
      await userProvider.refreshUserInfo();
      
      // Hiển thị thông báo thành công
      if (mounted) {
        AppToastHelper.showSuccess(
          context,
          message: 'Cập nhật thông tin thành công!',
        );
      }

      // Quay về màn hình trước
      if (mounted) Navigator.of(context).pop(true);
      
    } catch (e) {
      // Đóng loading dialog nếu đang hiển thị
      if (mounted) Navigator.of(context).pop();
      
      // Hiển thị thông báo lỗi
      if (mounted) {
        AppToastHelper.showError(
          context,
          message: 'Lỗi khi cập nhật: $e',
        );
      }
      
      // debugPrint('[EditUserInfoScreen] Error updating user info: $e');
    }
  }

  // Kiểm tra có thay đổi cho user thường không
  bool _hasUserChanges() {
    // So sánh tên hiện tại với tên ban đầu
    final originalName = widget.userInfo.name;
    final currentName = _nameCtrl.text.trim();
    
    return currentName != originalName;
  }

  // Kiểm tra có thay đổi cho garage không
  bool _hasGarageChanges() {
    // Kiểm tra thông tin cơ bản
    final originalNameGarage = widget.userInfo.nameGarage ?? widget.userInfo.name;
    final currentNameGarage = _nameCtrl.text.trim();
    
    final originalEmailGarage = widget.userInfo.emailGarage ?? '';
    final currentEmailGarage = _emailCtrl.text.trim();
    
    final originalAddress = widget.userInfo.address ?? '';
    final currentAddress = _addressCtrl.text.trim();
    
    final originalWorker = widget.userInfo.numberOfWorker ?? '';
    final currentWorker = _workerCtrl.text.trim();
    
    final originalDesc = widget.userInfo.descriptionGarage ?? '';
    final currentDesc = _descCtrl.text.trim();
    
    final originalServices = widget.userInfo.servicesProvided ?? '';
    final currentServices = _servicesCtrl.text.trim();
    
    final originalFrom = _extractYear(widget.userInfo.createdAt);
    final currentFrom = _fromCtrl.text.trim();
    
    // Kiểm tra thay đổi thông tin cơ bản
    bool hasBasicChanges = 
        currentNameGarage != originalNameGarage ||
        currentEmailGarage != originalEmailGarage ||
        currentAddress != originalAddress ||
        currentWorker != originalWorker ||
        currentDesc != originalDesc ||
        currentServices != originalServices ||
        currentFrom != originalFrom;
    
    // Kiểm tra thay đổi ảnh
    bool hasImageChanges = _avatarFile != null || 
                          _serviceImages.isNotEmpty || 
                          _certificateImages.isNotEmpty ||
                          _hasServiceChanges() ||
                          _hasCertificateChanges();
    
    return hasBasicChanges || hasImageChanges;
  }

  // Cập nhật thông tin user thường
  Future<void> _updateUserInfo() async {
    // Chỉ gọi API khi có thay đổi tên
    if (_hasUserChanges()) {
      final updateData = {
        'name': _nameCtrl.text,
      };
      await UserService.updateUserInfo(updateData);
      // debugPrint('[EditUserInfoScreen] User info updated');
    }
  }

  // Cập nhật thông tin gara (3 API)
  Future<void> _updateGarageInfo() async {
    // Kiểm tra thay đổi thông tin cơ bản
    final originalNameGarage = widget.userInfo.nameGarage ?? widget.userInfo.name;
    final currentNameGarage = _nameCtrl.text.trim();
    
    final originalEmailGarage = widget.userInfo.emailGarage ?? '';
    final currentEmailGarage = _emailCtrl.text.trim();
    
    final originalAddress = widget.userInfo.address ?? '';
    final currentAddress = _addressCtrl.text.trim();
    
    final originalWorker = widget.userInfo.numberOfWorker ?? '';
    final currentWorker = _workerCtrl.text.trim();
    
    final originalDesc = widget.userInfo.descriptionGarage ?? '';
    final currentDesc = _descCtrl.text.trim();
    
    final originalServices = widget.userInfo.servicesProvided ?? '';
    final currentServices = _servicesCtrl.text.trim();
    
    final originalFrom = _extractYear(widget.userInfo.createdAt);
    final currentFrom = _fromCtrl.text.trim();
    
    bool hasBasicChanges = 
        currentNameGarage != originalNameGarage ||
        currentEmailGarage != originalEmailGarage ||
        currentAddress != originalAddress ||
        currentWorker != originalWorker ||
        currentDesc != originalDesc ||
        currentServices != originalServices ||
        currentFrom != originalFrom;

    // 1. Cập nhật thông tin gara (chỉ khi có thay đổi)
    if (hasBasicChanges) {
      final garageData = {
        'name_garage': _nameCtrl.text,
        'email_garage': _emailCtrl.text,
        'address': _addressCtrl.text,
        'number_of_worker': _workerCtrl.text,
        'description_garage': _descCtrl.text,
        'services_provided': _servicesCtrl.text,
        'active_from': _fromCtrl.text,
      };
      await UserService.updateGarageInfo(garageData);
      // debugPrint('[EditUserInfoScreen] Garage info updated');
    }

    // 2. Cập nhật chứng chỉ (chỉ khi có thay đổi)
    if (_certificateImages.isNotEmpty || _hasCertificateChanges()) {
      final currentFiles = _getCurrentCertificateFiles();
      await UserService.updateGarageCertificate(
        currentFiles: currentFiles,
        newFiles: _certificateImages.isNotEmpty ? _certificateImages : null,
      );
      // debugPrint('[EditUserInfoScreen] Garage certificates updated');
    }

    // 3. Cập nhật file đăng ký (chỉ khi có thay đổi)
    if (_serviceImages.isNotEmpty || _hasServiceChanges()) {
      final currentFiles = _getCurrentServiceFiles();
      await UserService.updateGarageRegisterAttachment(
        currentFiles: currentFiles,
        newFiles: _serviceImages.isNotEmpty ? _serviceImages : null,
      );
      // debugPrint('[EditUserInfoScreen] Garage register files updated');
    }
  }

  // Kiểm tra có thay đổi chứng chỉ không
  bool _hasCertificateChanges() {
    // TODO: Implement logic to check if certificate files changed
    return false;
  }

  // Kiểm tra có thay đổi file đăng ký không
  bool _hasServiceChanges() {
    // TODO: Implement logic to check if service files changed
    return false;
  }

  // Lấy danh sách file chứng chỉ hiện tại
  List<Map<String, dynamic>> _getCurrentCertificateFiles() {
    return _currentCertificateFiles.map((file) => {
      'id': file.id,
      'path': file.path,
    }).toList();
  }

  // Lấy danh sách file đăng ký hiện tại
  List<Map<String, dynamic>> _getCurrentServiceFiles() {
    return _currentServiceFiles.map((file) => {
      'id': file.id,
      'path': file.path,
    }).toList();
  }

  // Hiển thị ảnh dịch vụ (cũ + mới)
  Widget _buildServiceImagesDisplay() {
    final allImages = <Widget>[];
    
    // Thêm ảnh cũ từ server
    for (int i = 0; i < _currentServiceFiles.length; i++) {
      final fileInfo = _currentServiceFiles[i];
      allImages.add(
        _buildExistingFileThumb(
          fileInfo,
          () {
            setState(() {
              _currentServiceFiles.removeAt(i);
            });
          },
        ),
      );
    }
    
    // Thêm ảnh mới từ picker
    for (int i = 0; i < _serviceImages.length; i++) {  
      allImages.add(
        _fileThumb(
          _serviceImages[i],
          () {
            setState(() => _serviceImages.removeAt(i));
          },
        ),
      );
    }
    
    if (allImages.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (ctx, i) => allImages[i],
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: allImages.length,
      ),
    );
  }

  // Hiển thị ảnh chứng chỉ (cũ + mới)
  Widget _buildCertificateImagesDisplay() {
    // debugPrint('[EditUserInfoScreen] _buildCertificateImagesDisplay called');
    // debugPrint('[EditUserInfoScreen] _currentCertificateFiles.length: ${_currentCertificateFiles.length}');
    // debugPrint('[EditUserInfoScreen] _certificateImages.length: ${_certificateImages.length}');
    
    final allImages = <Widget>[];
    
    // Thêm ảnh cũ từ server
    for (int i = 0; i < _currentCertificateFiles.length; i++) {
      final fileInfo = _currentCertificateFiles[i];
      // debugPrint('[EditUserInfoScreen] Adding existing certificate file $i: ${fileInfo.path}');
      allImages.add(
        _buildExistingFileThumb(
          fileInfo,
          () {
            setState(() {
              _currentCertificateFiles.removeAt(i);
            });
          },
        ),
      );
    }
    
    // Thêm ảnh mới từ picker
    for (int i = 0; i < _certificateImages.length; i++) {
      // debugPrint('[EditUserInfoScreen] Adding new certificate file $i: ${_certificateImages[i].path}');
      allImages.add(
        _fileThumb(
          _certificateImages[i],
          () {
            setState(() => _certificateImages.removeAt(i));
          },
        ),
      );
    }
    
    // debugPrint('[EditUserInfoScreen] Total certificate images to display: ${allImages.length}');
    
    if (allImages.isEmpty) {
      // debugPrint('[EditUserInfoScreen] No certificate images to display, returning SizedBox.shrink()');
      return const SizedBox.shrink();
    }
    
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (ctx, i) => allImages[i],
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: allImages.length,
      ),
    );
  }

  // Hiển thị ảnh cũ từ server
  Widget _buildExistingFileThumb(FileInfo fileInfo, VoidCallback onRemove) {
    final imageUrl = resolveImageUrl(fileInfo.path) ?? '';
    // debugPrint('[EditUserInfoScreen] _buildExistingFileThumb: path=${fileInfo.path}, resolvedUrl=$imageUrl');
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                // debugPrint('[EditUserInfoScreen] Image loaded successfully: $imageUrl');
                return child;
              }
              // debugPrint('[EditUserInfoScreen] Image loading: $imageUrl, progress: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: DesignTokens.gray100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              // debugPrint('[EditUserInfoScreen] Image load error: $imageUrl, error: $error');
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: DesignTokens.gray100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.image, color: DesignTokens.gray400),
              );
            },
          ),
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
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
        // Label để phân biệt ảnh cũ
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Cũ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
