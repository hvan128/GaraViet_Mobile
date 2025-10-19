import 'package:flutter/material.dart';
import 'package:gara/theme/index.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';

class MyMonthPicker extends StatefulWidget {
  final ValueChanged<DateTime> onMonthSelected;
  final String? label;
  final DateTime? defaultValue;
  final bool hasError;
  final String? errorText;
  final bool enabled;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? height;

  const MyMonthPicker({
    super.key,
    required this.onMonthSelected,
    this.label,
    this.defaultValue,
    this.hasError = false,
    this.errorText,
    this.enabled = true,
    this.borderRadius = 12.0,
    this.padding,
    this.height,
  });

  @override
  State<MyMonthPicker> createState() => _MyMonthPickerState();
}

class _MyMonthPickerState extends State<MyMonthPicker> {
  DateTime? selectedMonth;

  String _formatMonthYear(DateTime dt) {
    return 'Tháng ${dt.month}/${dt.year}';
  }

  @override
  void initState() {
    super.initState();
    selectedMonth = widget.defaultValue;
  }

  Future<void> _selectMonth(BuildContext context) async {
    if (!widget.enabled) return;

    final now = DateTime.now();
    int tempYear = (selectedMonth ?? now).year;
    int tempMonth = (selectedMonth ?? now).month;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Dialog(
              backgroundColor: DesignTokens.surfacePrimary,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 40,
                        child: Center(
                          child: MyText(
                            text: 'Chọn tháng',
                            textStyle: 'title',
                            textSize: '16',
                            textColor: 'primary',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            IgnorePointer(
                              ignoring: true,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  height: 28,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        DesignTokens.surfacePrimary,
                                        DesignTokens.surfacePrimary.withOpacity(0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            IgnorePointer(
                              ignoring: true,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  height: 28,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        DesignTokens.surfacePrimary,
                                        DesignTokens.surfacePrimary.withOpacity(0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            IgnorePointer(
                              ignoring: true,
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: DesignTokens.surfaceTertiary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 90,
                                  child: _buildPickerColumn(
                                    items: List.generate(12, (index) => 'Tháng ${index + 1}'),
                                    selectedIndex: tempMonth - 1,
                                    onSelected: (index) {
                                      setLocalState(() {
                                        tempMonth = index + 1;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 90,
                                  child: _buildPickerColumn(
                                    items: List.generate(7, (i) => (now.year - 3 + i).toString()),
                                    selectedIndex: tempYear - (now.year - 3),
                                    onSelected: (index) {
                                      setLocalState(() {
                                        tempYear = now.year - 3 + index;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                          Expanded(
                            child: MyButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              text: 'Cancel',
                              buttonType: ButtonType.secondary,
                              height: 36,
                              textStyle: 'label',
                              textSize: '14',
                              textColor: 'secondary',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MyButton(
                              onPressed: () {
                                final newMonth = DateTime(tempYear, tempMonth, 1);
                                Navigator.of(dialogContext).pop();
                                setState(() {
                                  selectedMonth = newMonth;
                                });
                                widget.onMonthSelected(newMonth);
                              },
                              buttonType: ButtonType.primary,
                              height: 36,
                              text: 'OK',
                              textStyle: 'label',
                              textSize: '14',
                              textColor: 'invert',
                            ),
                          ),
                        ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPickerColumn({
    required List<String> items,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
  }) {
    final FixedExtentScrollController scrollController = FixedExtentScrollController(
      initialItem: selectedIndex,
    );

    return ListWheelScrollView.useDelegate(
      controller: scrollController,
      itemExtent: 56,
      perspective: 0.005,
      diameterRatio: 1.2,
      physics: const FixedExtentScrollPhysics(),
      overAndUnderCenterOpacity: 1.0,
      useMagnifier: false,
      onSelectedItemChanged: onSelected,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: items.length,
        builder: (context, index) {
          return Container(
            height: 56,
            alignment: Alignment.center,
            child: MyText(
              text: items[index],
              textStyle: 'label',
              textSize: '18',
              textColor: 'primary',
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final containerHeight = widget.height ?? 32.0;
    final containerPadding = widget.padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 6);

    Widget suffixIcon = SvgIcon(
      svgPath: 'assets/icons_final/calendar.svg',
      width: 16,
      height: 16,
      color: widget.enabled ? DesignTokens.surfaceBrand : DesignTokens.textDisable,
    );

    final display = selectedMonth ?? widget.defaultValue ?? DateTime.now();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          MyText(
            text: widget.label!,
            textStyle: 'body',
            textSize: '14',
            textColor: 'secondary',
          ),
          const SizedBox(height: 6),
        ],
        Align(
          alignment: Alignment.center,
          child: InkWell(
            onTap: () => _selectMonth(context),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Container(
              height: containerHeight,
              padding: containerPadding,
              decoration: BoxDecoration(
                color: widget.enabled 
                    ? DesignTokens.surfaceSecondary 
                    : DesignTokens.surfaceTertiary,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: widget.hasError
                      ? DesignTokens.borderBrandPrimary
                      : DesignTokens.borderSecondary,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  suffixIcon,
                  const SizedBox(width: 6),
                  MyText(
                    text: _formatMonthYear(display),
                    textStyle: 'label',
                    textSize: '12',
                    textColor: widget.enabled ? 'brand' : 'disable',
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.hasError && widget.errorText != null) ...[
          const SizedBox(height: 6),
          MyText(
            text: widget.errorText!,
            textStyle: 'label',
            textSize: '12',
            textColor: 'error',
            lineHeight: 1.38,
          ),
        ],
      ],
    );
  }
}