import 'package:flutter/material.dart';
import 'package:gara/models/messaging/messaging_models.dart';
import 'package:gara/theme/index.dart';
import 'package:gara/utils/formatters.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/skeleton.dart';
import 'package:gara/widgets/text.dart';

class ServiceInfoCard extends StatelessWidget {
  final bool loading;
  final RoomData? room;
  final bool isGarageUser;
  final VoidCallback onEditQuotation;

  const ServiceInfoCard({
    super.key,
    required this.loading,
    required this.room,
    required this.isGarageUser,
    required this.onEditQuotation,
  });

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
                                onPressed: onEditQuotation,
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
