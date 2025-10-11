import 'package:flutter/material.dart';
import 'package:gara/theme/index.dart';
import 'package:gara/widgets/button.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';

class MyTimePicker extends StatefulWidget {
  final ValueChanged<TimeOfDay> onTimeSelected;
  final String? label;
  final TimeOfDay? defaultValue;
  final bool hasError;
  final String? errorText;
  final bool enabled;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? height;

  const MyTimePicker({
    super.key,
    required this.onTimeSelected,
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
  State<MyTimePicker> createState() => _MyTimePickerState();
}

class _MyTimePickerState extends State<MyTimePicker> {
  TimeOfDay? selectedTime;

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  @override
  void initState() {
    super.initState();
    selectedTime = widget.defaultValue;
  }

  Future<void> _selectTime(BuildContext context) async {
    if (!widget.enabled) return;

    TimeOfDay currentTime = selectedTime ?? TimeOfDay.now();
    int selectedHour = currentTime.hourOfPeriod == 0 ? 12 : currentTime.hourOfPeriod;
    int selectedMinute = currentTime.minute;
    bool isAM = currentTime.period == DayPeriod.am;

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
                    // Header
                    SizedBox(
                      height: 56,
                      child: Center(
                        child: MyText(
                          text: 'Time',
                          textStyle: 'title',
                          textSize: '16',
                          textColor: 'primary',
                        ),
                      ),
                    ),
                    // Time picker with 3 columns
                    SizedBox(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Top fade overlay across the entire row
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
                          // Bottom fade overlay across the entire row
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
                          // Center highlight bar across all columns
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
                          // The 3 pickers
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 55,
                                child: _buildPickerColumn(
                                  items: List.generate(12, (index) => '${index + 1}'.padLeft(2, '0')),
                                  selectedIndex: selectedHour - 1,
                                  onSelected: (index) {
                                    setLocalState(() {
                                      selectedHour = index + 1;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 55,
                                child: _buildPickerColumn(
                                  items: List.generate(60, (index) => index.toString().padLeft(2, '0')),
                                  selectedIndex: selectedMinute,
                                  onSelected: (index) {
                                    setLocalState(() {
                                      selectedMinute = index;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 55,
                                child: _buildPickerColumn(
                                  items: ['AM', 'PM'],
                                  selectedIndex: isAM ? 0 : 1,
                                  onSelected: (index) {
                                    setLocalState(() {
                                      isAM = index == 0;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Action buttons
                    Row(
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
                              // Convert 12-hour format to 24-hour format
                              int hour24 = selectedHour;
                              if (isAM && selectedHour == 12) {
                                hour24 = 0;
                              } else if (!isAM && selectedHour != 12) {
                                hour24 = selectedHour + 12;
                              }
                              
                              final newTime = TimeOfDay(hour: hour24, minute: selectedMinute);
                              Navigator.of(dialogContext).pop();
                              setState(() {
                                selectedTime = newTime;
                              });
                              widget.onTimeSelected(newTime);
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
    final containerHeight = widget.height ?? 44.0;
    final containerPadding = widget.padding ?? 
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12);

    Widget suffixIcon = SvgIcon(
      svgPath: 'assets/icons_final/clock.svg',
      width: 16,
      height: 16,
      color: widget.enabled ? DesignTokens.surfaceBrand : DesignTokens.textDisable,
    );

    return Column(
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
        InkWell(
          onTap: () => _selectTime(context),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Container(
            height: containerHeight,
            padding: containerPadding,
            decoration: BoxDecoration(
              color: DesignTokens.surfacePrimary,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: widget.hasError
                    ? DesignTokens.alerts['error']!
                    : DesignTokens.borderPrimary,
                width: widget.hasError ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: MyText(
                    text: selectedTime != null
                        ? _formatTime(selectedTime!)
                        : '12:00 AM',
                    textStyle: 'label',
                    textSize: '14',
                    color: widget.enabled
                        ? selectedTime != null
                            ? DesignTokens.textPrimary
                            : DesignTokens.textPlaceholder
                        : DesignTokens.textDisable,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                suffixIcon,
              ],
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