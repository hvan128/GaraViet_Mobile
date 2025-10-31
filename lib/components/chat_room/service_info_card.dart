import 'package:flutter/material.dart';
import 'package:gara/models/messaging/messaging_models.dart';
import 'package:gara/theme/index.dart';
import 'package:gara/utils/formatters.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/skeleton.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/models/quotation/quotation_model.dart';
import 'package:gara/services/quotation/quotation_service.dart';
import 'package:gara/widgets/text_field.dart';
import 'package:gara/widgets/app_toast.dart';

class ServiceInfoCard extends StatelessWidget {
  final bool loading;
  final RoomData? room;
  final bool isGarageUser;
  final VoidCallback? onQuotationUpdated;

  const ServiceInfoCard({
    Key? key,
    required this.loading,
    required this.room,
    required this.isGarageUser,
    this.onQuotationUpdated,
  }) : super(key: key);

  static Future<void> showEditQuotationBottomSheet(BuildContext context, QuotationModel quotation,
      {VoidCallback? onUpdateDone}) async {
    final TextEditingController priceController = TextEditingController(text: formatCurrency(quotation.price));
    final TextEditingController descriptionController = TextEditingController(text: quotation.description);
    bool isSubmitting = false;

    String formatPrice(String value) {
      final onlyDigits = value.replaceAll(RegExp(r'[^\d]'), '');
      if (onlyDigits.isEmpty) return '';
      final number = int.tryParse(onlyDigits) ?? 0;
      return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    }

    int parsePrice(String formatted) {
      final onlyDigits = formatted.replaceAll(RegExp(r'[^\d]'), '');
      return int.tryParse(onlyDigits) ?? 0;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submit() async {
              if (isSubmitting) return;
              final price = parsePrice(priceController.text);
              final desc = descriptionController.text.trim();
              if (price <= 0) {
                AppToastHelper.show(context, message: 'Vui lòng nhập giá hợp lệ', type: AppToastType.error);
                return;
              }
              if (desc.isEmpty) {
                AppToastHelper.show(context, message: 'Vui lòng nhập mô tả', type: AppToastType.error);
                return;
              }
              setModalState(() {
                isSubmitting = true;
              });
              try {
                final res = await QuotationServiceApi.updateQuotation(
                  quotationId: quotation.id,
                  price: price,
                  description: desc,
                  status: quotation.status,
                );
                if (res.success) {
                  Navigator.pop(context);
                  if (onUpdateDone != null) onUpdateDone();
                  AppToastHelper.show(context, message: 'Cập nhật báo giá thành công', type: AppToastType.success);
                  return;
                } else {
                  AppToastHelper.show(context, message: res.message, type: AppToastType.error);
                }
              } catch (_) {
                AppToastHelper.show(context, message: 'Không thể cập nhật báo giá', type: AppToastType.error);
              } finally {
                setModalState(() {
                  isSubmitting = false;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child:
                                MyText(text: 'Sửa báo giá', textStyle: 'title', textSize: '16', textColor: 'primary')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    MyTextField(
                      controller: priceController,
                      label: 'Giá*',
                      hintText: 'Nhập giá (VND)',
                      keyboardType: TextInputType.number,
                      hasError: false,
                      obscureText: false,
                      onChange: (value) {
                        final formatted = formatPrice(value);
                        if (formatted != value) {
                          priceController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    MyTextField(
                      controller: descriptionController,
                      label: 'Mô tả',
                      hintText: 'Nhập mô tả',
                      height: 120,
                      hasError: false,
                      obscureText: false,
                      minLines: 3,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: MyButton(
                            text: 'Hủy',
                            height: 40,
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
                            text: isSubmitting ? 'Đang lưu...' : 'Lưu',
                            height: 40,
                            onPressed: isSubmitting ? null : submit,
                            buttonType: isSubmitting ? ButtonType.disable : ButtonType.primary,
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to request detail screen
        if (room?.requestServiceInfo != null) {
          Navigator.pushNamed(context, '/request-detail', arguments: room!.requestServiceInfo);
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: DesignTokens.surfacePrimary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: DesignEffects.medCardShadow,
        ),
        child: loading
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton.line(height: 20, margin: const EdgeInsets.only(bottom: 4)),
                  Skeleton.line(height: 20, width: 180),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: title + description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: MyText(
                                text: (room?.carInfo != null && room!.carInfo!.isNotEmpty)
                                    ? room!.carInfo!
                                    : ((room?.requestCode != null && room!.requestCode!.isNotEmpty)
                                        ? room!.requestCode!
                                        : '—'),
                                textStyle: 'head',
                                textSize: '16',
                                textColor: 'primary',
                              ),
                            ),
                            if (isGarageUser && room?.quotationInfo != null) ...[
                              MyButton(
                                text: 'Sửa báo giá',
                                onPressed: () {
                                  if (room?.quotationInfo == null) return;
                                  ServiceInfoCard.showEditQuotationBottomSheet(
                                    context,
                                    room!.quotationInfo!,
                                    onUpdateDone: onQuotationUpdated,
                                  );
                                },
                                buttonType: ButtonType.primary,
                                width: 93,
                                height: 30,
                                textStyle: 'label',
                                textSize: '12',
                                textColor: 'invert',
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: MyText(
                                text: (room?.serviceDescription != null && room!.serviceDescription!.isNotEmpty)
                                    ? room!.serviceDescription!
                                    : ((room?.statusText != null && room!.statusText!.isNotEmpty)
                                        ? room!.statusText!
                                        : '—'),
                                textStyle: 'body',
                                textSize: '14',
                                textColor: 'secondary',
                              ),
                            ),
                            if (isGarageUser && room?.quotationInfo != null) ...[
                              const SizedBox(width: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  MyText(text: 'Giá:', textStyle: 'body', textSize: '14', textColor: 'tertiary'),
                                  const SizedBox(width: 6),
                                  MyText(
                                    text: '${formatCurrency(room!.quotationInfo!.price)} đ',
                                    textStyle: 'head',
                                    textSize: '16',
                                    textColor: 'brand',
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right: edit button + price (when has quotation)
                ],
              ),
      ),
    );
  }
}
