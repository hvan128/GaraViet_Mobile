import 'package:flutter/material.dart';
import 'package:gara/widgets/app_toast.dart';
import 'dart:math';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gara/components/auth/icon_field.dart';
import 'package:gara/theme/design_tokens.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';
import 'package:provider/provider.dart';
import 'package:gara/models/registration_data.dart';
import 'package:gara/widgets/keyboard_dismiss_wrapper.dart';
import 'package:gara/widgets/text_field.dart';
import 'package:gara/widgets/date_picker.dart';
import 'package:gara/widgets/button.dart';
// removed unused imports
import 'dart:typed_data';
import 'dart:convert';
import 'package:signature/signature.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:gara/services/auth/auth_service.dart';
import 'package:gara/navigation/navigation.dart';

class ElectronicContractPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final int currentStep;
  final int totalSteps;
  final String? initialContractMarkdown; // optional: md từ server

  const ElectronicContractPage({
    super.key,
    required this.onNext,
    this.onBack,
    required this.currentStep,
    required this.totalSteps,
    this.initialContractMarkdown,
  });

  @override
  State<ElectronicContractPage> createState() => _ElectronicContractPageState();
}

class _ElectronicContractPageState extends State<ElectronicContractPage> {
  final TextEditingController _cccdController = TextEditingController();
  final TextEditingController _issueDateController = TextEditingController();
  final TextEditingController _signatureController = TextEditingController();
  final ScrollController _contractScrollController = ScrollController();
  final SignatureController _signaturePadController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  Uint8List? _signatureBytes;

  bool _isLoading = false;
  bool _submitted = false;
  String? _cccdError;
  String? _issueDateError;
  String? _signatureError;
  String _contractMarkdown = '';

  @override
  void initState() {
    super.initState();
    // Load existing data from RegistrationData
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final registrationData = Provider.of<RegistrationData>(
        context,
        listen: false,
      );
      if (registrationData.cccd != null) {
        _cccdController.text = registrationData.cccd!;
      }
      if (registrationData.issueDate != null) {
        _issueDateController.text = _formatDate(registrationData.issueDate!);
      }
      if (registrationData.signature != null) {
        _signatureController.text = registrationData.signature!;
      }
    });
    // Ưu tiên md từ server nếu được truyền vào
    if (widget.initialContractMarkdown != null &&
        widget.initialContractMarkdown!.trim().isNotEmpty) {
      _contractMarkdown = _normalizeServerMarkdown(
        widget.initialContractMarkdown!,
      );
    } else {
      _contractMarkdown = _generateRandomContractMarkdown();
    }
  }

  @override
  void dispose() {
    _cccdController.dispose();
    _issueDateController.dispose();
    _signatureController.dispose();
    _contractScrollController.dispose();
    _signaturePadController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Chuẩn hóa chuỗi md từ server: đổi \r\n -> \n, trim khoảng trắng dư
  String _normalizeServerMarkdown(String raw) {
    return raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
  }

  String _generateRandomContractMarkdown() {
    final random = Random();
    final today = DateTime.now();
    final formattedDate = _formatDate(today);

    final titles = [
      '# Hợp đồng cung cấp dịch vụ',
      '# Hợp đồng hợp tác điện tử',
      '# Thỏa thuận sử dụng nền tảng',
    ];

    final parties = [
      '''- Bên A: Công ty TNHH Dịch vụ Gara Việt
- Bên B: Chủ gara/đối tác ("Khách hàng")''',
      '''- Bên A: Nền tảng Gara
- Bên B: Đối tác vận hành gara''',
      '''- Bên A: Công ty Cổ phần Công nghệ Ô tô
- Bên B: Người sử dụng dịch vụ''',
    ];

    final scope = [
      '1.1 Phạm vi: Cung cấp quyền truy cập, quản lý lịch hẹn, và xử lý thanh toán.',
      '1.1 Phạm vi: Cấp quyền sử dụng phần mềm và hỗ trợ kỹ thuật định kỳ.',
      '1.1 Phạm vi: Cung cấp hạ tầng quản lý gara và công cụ báo cáo.',
    ];

    final fees = [
      '2.1 Phí dịch vụ: 1% trên tổng doanh số giao dịch qua nền tảng.',
      '2.1 Phí dịch vụ: Gói cố định 499.000đ/tháng, thanh toán trước.',
      '2.1 Phí dịch vụ: Miễn phí 30 ngày đầu, sau đó 2% trên mỗi đơn.',
    ];

    final terms = [
      '- Thời hạn: 12 tháng, tự động gia hạn nếu không có thông báo bằng văn bản trước 15 ngày.\n- Bảo mật: Hai bên cam kết bảo mật dữ liệu khách hàng và giao dịch.',
      '- Thời hạn: 06 tháng, có thể chấm dứt sớm theo điều kiện vi phạm.\n- Bảo mật: Tuân thủ tiêu chuẩn mã hóa và sao lưu định kỳ.',
      '- Thời hạn: Không xác định, chấm dứt bất kỳ lúc nào với thông báo trước 07 ngày.\n- Bảo mật: Dữ liệu được xử lý theo chính sách quyền riêng tư.',
    ];

    final md = [
      titles[random.nextInt(titles.length)],
      '',
      '**Ngày hiệu lực:** $formattedDate',
      '',
      '## Các bên tham gia',
      parties[random.nextInt(parties.length)],
      '',
      '## Điều khoản',
      scope[random.nextInt(scope.length)],
      '',
      fees[random.nextInt(fees.length)],
      '',
      '## Cam kết và trách nhiệm',
      terms[random.nextInt(terms.length)],
      '',
      '> Lưu ý: Việc ký kết điện tử có giá trị pháp lý như ký trực tiếp.',
    ].join('\n');

    return md;
  }

  MarkdownStyleSheet _buildCompactMarkdownStyle(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    // Giảm cỡ chữ để phù hợp tổng thể app
    final baseSize = (theme.bodyMedium?.fontSize ?? 14);
    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      h1: theme.titleMedium?.copyWith(
        fontSize: baseSize + 1,
        fontWeight: FontWeight.w700,
        fontFamily: 'Manrope',
      ),
      h2: theme.titleSmall?.copyWith(
        fontSize: baseSize,
        fontWeight: FontWeight.w700,
        fontFamily: 'Manrope',
      ),
      h3: theme.titleSmall?.copyWith(
        fontSize: baseSize - 1,
        fontWeight: FontWeight.w600,
        fontFamily: 'Manrope',
      ),
      p: theme.bodySmall?.copyWith(
        fontSize: baseSize - 2,
        fontFamily: 'Manrope',
      ),
      listBullet: theme.bodySmall?.copyWith(
        fontSize: baseSize - 2,
        fontFamily: 'Manrope',
      ),
      blockquote: TextStyle(
        color: Colors.grey[700],
        fontSize: (baseSize - 2).clamp(10, 14).toDouble(),
        fontFamily: 'Manrope',
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey[300]!, width: 3)),
        color: Colors.grey[100],
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      code: theme.bodySmall?.copyWith(
        backgroundColor: DesignTokens.surfacePrimary,
        fontSize: baseSize - 2,
        fontFamily: 'Manrope',
      ),
    );
  }

  Future<void> _validateAndNext() async {
    setState(() {
      _isLoading = true;
      _submitted = true;
      _cccdError = null;
      _issueDateError = null;
      _signatureError = null;
    });

    // Validate CCCD
    if (_cccdController.text.trim().isEmpty) {
      setState(() {
        _cccdError = 'Vui lòng nhập số CCCD';
        _isLoading = false;
      });
      return;
    }

    if (_cccdController.text.trim().length != 12) {
      setState(() {
        _cccdError = 'Số CCCD phải có 12 chữ số';
        _isLoading = false;
      });
      return;
    }

    // Validate issue date
    if (_issueDateController.text.trim().isEmpty) {
      setState(() {
        _issueDateError = 'Vui lòng chọn ngày cấp';
        _isLoading = false;
      });
      return;
    }

    // Validate signature
    if (!_hasSignature) {
      setState(() {
        _signatureError = 'Vui lòng ký xác nhận';
        _isLoading = false;
      });
      return;
    }

    // Save to RegistrationData
    final registrationData = Provider.of<RegistrationData>(
      context,
      listen: false,
    );
    registrationData.setCccd(_cccdController.text.trim());

    // Parse date from dd/MM/yyyy format
    final dateParts = _issueDateController.text.trim().split('/');
    String issuedDateApi = '';
    if (dateParts.length == 3) {
      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);
      final picked = DateTime(year, month, day);
      registrationData.setIssueDate(picked);
      // Format yyyy-MM-dd for API
      issuedDateApi = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }

    if (_signatureBytes != null) {
      registrationData.setSignature(base64Encode(_signatureBytes!));
    }

    // Call API sign contract
    try {
      final resp = await AuthService.signContractForGarage(
        idCardNumber: _cccdController.text.trim(),
        idCardIssuedDate: issuedDateApi,
        signatureBytes: _signatureBytes!,
      );

      if (mounted) {
        if (resp['success'] == true) {
          AppToastHelper.showSuccess(
            context,
            message: resp['message'] ?? 'Ký hợp đồng thành công',
          );
          setState(() {
            _isLoading = false;
          });
          // Điều hướng về trang chủ và xóa toàn bộ lịch sử
          Navigate.pushNamedAndRemoveAll('/');
        } else {
          AppToastHelper.showError(
            context,
            message: resp['message'] ?? 'Ký hợp đồng thất bại',
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      AppToastHelper.showError(
        context,
        message: 'Có lỗi xảy ra khi ký hợp đồng',
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectIssueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _issueDateController.text = _formatDate(picked);
      });

      final registrationData = Provider.of<RegistrationData>(
        context,
        listen: false,
      );
      registrationData.setIssueDate(picked);
    }
  }

  void _autoSign() {
    setState(() {
      _signatureController.text = 'Ký tự động';
    });

    final registrationData = Provider.of<RegistrationData>(
      context,
      listen: false,
    );
    registrationData.setSignature('Ký tự động');
  }

  bool get _hasSignature =>
      _signatureBytes != null && _signatureBytes!.isNotEmpty;

  Future<void> _openSignaturePad() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Signature pad with dashed border
                  DottedBorder(
                    color: DesignTokens.borderBrandPrimary,
                    strokeWidth: 1,
                    dashPattern: const [6, 3],
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    child: Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: DesignTokens.surfacePrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          // Signature pad
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Signature(
                                controller: _signaturePadController,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                          // Refresh/Clear icon in top right
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                _signaturePadController.clear();
                              },
                              child: SvgIcon(
                                svgPath: 'assets/icons_final/refresh-square-2.svg',
                                width: 24,
                                height: 24,
                                color: DesignTokens.surfaceBrand,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Complete button
                  MyButton(
                    text: 'Hoàn thành',
                    onPressed: () async {
                      if (_signaturePadController.isEmpty) {
                        Navigator.pop(ctx);
                        return;
                      }
                      final bytes =
                          await _signaturePadController.toPngBytes();
                      if (bytes != null) {
                        setState(() {
                          _signatureBytes = bytes;
                          if (_submitted) {
                            _signatureError = null;
                          }
                        });
                        final registrationData =
                            Provider.of<RegistrationData>(
                              context,
                              listen: false,
                            );
                        registrationData.setSignature(
                          base64Encode(bytes),
                        );
                      }
                      Navigator.pop(ctx);
                    },
                    buttonType: ButtonType.primary,
                    height: 48,
                  ),
                  const SizedBox(height: 12),
                  // Cancel button
                  MyButton(
                    text: 'Hủy',
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                    buttonType: ButtonType.transparent,
                    height: 48,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header

            // Content
            Expanded(
              child: KeyboardDismissWrapper(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconField(
                        svgPath: "assets/icons_final/document-text.svg",
                      ),
                      const SizedBox(height: 12),

                      // Description
                      MyText(
                        text: 'Hợp đồng điện tử',
                        textStyle: 'head',
                        textSize: '24',
                        textColor: 'primary',
                      ),
                      const SizedBox(height: 4),
                      MyText(
                        text: 'Hãy đọc kỹ hợp đồng và cung cấp thông tin',
                        textStyle: 'body',
                        textSize: '14',
                        textColor: 'secondary',
                      ),
                      const SizedBox(height: 32),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: MyText(
                                  text: 'Nội dung hợp đồng',
                                  textStyle: 'body',
                                  textSize: '14',
                                  textColor: 'secondary',
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: DesignTokens.surfacePrimary,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: DesignTokens.borderSecondary,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: SizedBox(
                                  height: 175,
                                  child: Scrollbar(
                                    controller: _contractScrollController,
                                    thumbVisibility: true,
                                    thickness: 2,
                                    radius: const Radius.circular(6),
                                    child: SingleChildScrollView(
                                      controller: _contractScrollController,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      child: MarkdownBody(
                                        data: _contractMarkdown,
                                        styleSheet: _buildCompactMarkdownStyle(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // CCCD and Issue Date in one row
                          Row(
                            children: [
                              // CCCD input
                              Expanded(
                                child: MyTextField(
                                  controller: _cccdController,
                                  label: 'CCCD',
                                  obscureText: false,
                                  hasError: _submitted && _cccdError != null,
                                  errorText: _cccdError,
                                  hintText: 'CCCD..',
                                  onChange: (value) {
                                    setState(() {
                                      if (_submitted) {
                                        if (value.trim().isEmpty) {
                                          _cccdError = 'Vui lòng nhập số CCCD';
                                        } else if (value.trim().length != 12) {
                                          _cccdError =
                                              'Số CCCD phải có 12 chữ số';
                                        } else {
                                          _cccdError = null;
                                        }
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Issue Date input (DatePicker)
                              Expanded(
                                child: MyDatePicker(
                                  label: 'Ngày cấp',
                                  hasError:
                                      _submitted && _issueDateError != null,
                                  errorText: _issueDateError,
                                  onDateSelected: (picked) {
                                    setState(() {
                                      _issueDateController.text = _formatDate(
                                        picked,
                                      );
                                      if (_submitted) {
                                        _issueDateError = null;
                                      }
                                    });
                                    final registrationData =
                                        Provider.of<RegistrationData>(
                                          context,
                                          listen: false,
                                        );
                                    registrationData.setIssueDate(picked);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Signature input
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: MyText(
                                  text: 'Chữ ký điện tử',
                                  textStyle: 'body',
                                  textSize: '14',
                                  textColor: 'secondary',
                                ),
                              ),
                              GestureDetector(
                                onTap: _openSignaturePad,
                                child: Container(
                                  height: 120,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: DesignTokens.surfacePrimary,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          _submitted && _signatureError != null
                                              ? DesignTokens.alertError
                                              : DesignTokens.borderSecondary,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      if (_hasSignature)
                                        Positioned.fill(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Image.memory(
                                              _signatureBytes!,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        )
                                      else
                                        Center(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SvgIcon(
                                                svgPath:
                                                    'assets/icons_final/pen.svg',
                                                width: 20,
                                                height: 20,
                                                color:
                                                    DesignTokens.surfaceBrand,
                                              ),
                                              const SizedBox(width: 8),
                                              MyText(
                                                text: 'Ký tại đây',
                                                textStyle: 'body',
                                                textSize: '14',
                                                color:
                                                    DesignTokens.surfaceBrand,
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (_hasSignature)
                                        Align(
                                          alignment: Alignment.center,
                                          child: Center(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color:
                                                    DesignTokens
                                                        .surfaceSecondary,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color:
                                                      DesignTokens
                                                          .borderBrandSecondary,
                                                ),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SvgIcon(
                                                    svgPath:
                                                        'assets/icons_final/pen.svg',
                                                    width: 20,
                                                    height: 20,
                                                    color:
                                                        DesignTokens
                                                            .surfaceBrand,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  MyText(
                                                    text: 'Ký lại',
                                                    textStyle: 'body',
                                                    textSize: '14',
                                                    color:
                                                        DesignTokens
                                                            .surfaceBrand,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_submitted && _signatureError != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _signatureError!,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Continue button
                          MyButton(
                            text: _isLoading ? 'Đang xử lý...' : 'Tiếp tục',
                            onPressed:
                                _isLoading || !_hasSignature
                                    ? null
                                    : _validateAndNext,
                            buttonType:
                                !_hasSignature
                                    ? ButtonType.disable
                                    : ButtonType.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
