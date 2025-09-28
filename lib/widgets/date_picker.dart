import 'package:flutter/material.dart';
import 'package:gara/theme/index.dart';
import 'package:gara/widgets/svg_icon.dart';
import 'package:gara/widgets/text.dart';

class MyDatePicker extends StatefulWidget {
  final ValueChanged<DateTime> onDateSelected;
  final String? label;
  final DateTime? defaultValue; // Add defaultValue prop
  final bool hasError;
  final String? errorText;
  final bool enabled;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? height;

  const MyDatePicker({
    super.key,
    required this.onDateSelected,
    this.label,
    this.defaultValue, // Initialize defaultValue in constructor
    this.hasError = false,
    this.errorText,
    this.enabled = true,
    this.borderRadius = 12.0,
    this.padding,
    this.height,
  });

  @override
  State<MyDatePicker> createState() => _MyDatePickerState(); // Pass defaultValue to state
}

class _MyDatePickerState extends State<MyDatePicker> {
  DateTime? selectedDate;
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  @override
  void initState() {
    super.initState();
    selectedDate = widget.defaultValue;
  }

  Future<void> _selectDate(BuildContext context) async {
    if (!widget.enabled) return;

    DateTime firstDate = DateTime(2000);
    DateTime lastDate = DateTime(2101);
    DateTime initial = selectedDate ?? DateTime.now();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        DateTime displayedMonth = DateTime(initial.year, initial.month);
        final ColorScheme scheme = ColorScheme.light(
          primary: DesignTokens.primaryBlue,
          onPrimary: DesignTokens.textInvert,
          surface: DesignTokens.surfacePrimary,
          onSurface: DesignTokens.textPrimary,
          secondary: DesignTokens.primaryBlue2,
          onSecondary: DesignTokens.textInvert,
        );

        return StatefulBuilder(
          builder: (context, setLocalState) {
            ThemeData themed = Theme.of(context).copyWith(
            colorScheme: scheme,
              dialogTheme: DialogThemeData(
              surfaceTintColor: Colors.transparent,
                shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                elevation: 8,
              ),
              iconButtonTheme: IconButtonThemeData(
                style: ButtonStyle(
                  // Ẩn icon header mặc định của CalendarDatePicker
                  iconColor: const MaterialStatePropertyAll(Colors.transparent),
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: DesignTokens.surfacePrimary,
                // Ẩn toàn bộ header mặc định để dùng header custom
              headerBackgroundColor: DesignTokens.surfacePrimary,
                headerForegroundColor: Colors.transparent,
                headerHelpStyle: MyTypography.getStyle(
                  'label',
                  '12',
                )?.copyWith(color: Colors.transparent, fontSize: 0),
                headerHeadlineStyle: MyTypography.getStyle(
                  'head',
                  '16',
                )?.copyWith(color: Colors.transparent, fontSize: 0),
              dividerColor: DesignTokens.borderSecondary,
              dayForegroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.disabled))
                    return DesignTokens.textSecondary.withOpacity(0.4);
                if (states.contains(MaterialState.selected))
                  return DesignTokens.textInvert;
                return DesignTokens.textPrimary;
              }),
              dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected))
                    return DesignTokens.surfaceBrand;
                return Colors.transparent;
              }),
              dayOverlayColor: const MaterialStatePropertyAll(
                Colors.transparent,
              ),
                todayForegroundColor: MaterialStateProperty.resolveWith((
                  states,
                ) {
                if (states.contains(MaterialState.selected))
                  return DesignTokens.textInvert;
                  return DesignTokens.textBrand;
              }),
                todayBackgroundColor: MaterialStateProperty.resolveWith((
                  states,
                ) {
                if (states.contains(MaterialState.selected))
                return Colors.transparent;
                  return DesignTokens.primaryBlue4;
                }),
                weekdayStyle: MyTypography.getStyle('label', '14')?.copyWith(
                  color: DesignTokens.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
                dayStyle: MyTypography.getStyle(
                  'label',
                  '14',
                )?.copyWith(fontWeight: FontWeight.w500),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              ),
            );

            List<String> monthNames = const [
              'January',
              'February',
              'March',
              'April',
              'May',
              'June',
              'July',
              'August',
              'September',
              'October',
              'November',
              'December',
            ];

            // Đặt chiều rộng dialog theo đúng chiều rộng lưới (7 ô x 44)
            const double _gridWidth = 44 * 7;
            const EdgeInsets _contentPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

            return Theme(
              data: themed,
              child: Dialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                backgroundColor: DesignTokens.surfacePrimary,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const double _gridWidth = 44 * 7;
                    const EdgeInsets _contentPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
                    final double desired = _gridWidth + 32; // content + padding hai bên
                    final double safeMax = constraints.maxWidth - 2; // trừ epsilon tránh overflow
                    final double width = desired <= safeMax ? desired : safeMax;
                    return SizedBox(
                      width: width,
                      child: Padding(
                        padding: _contentPadding,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header custom: Left group (Month Year + chevron), Right group (prev/next)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Left group: Month Year + chevron to open YearPicker
                                  GestureDetector(
                                    onTap: () async {
                                      final pickedYear = await _showCustomYearPicker(
                                        parentContext: dialogContext,
                                        firstDate: firstDate,
                                        lastDate: lastDate,
                                        initialYear: displayedMonth.year,
                                      );
                                      if (pickedYear != null) {
                                        setLocalState(() {
                                          displayedMonth = DateTime(
                                            pickedYear,
                                            displayedMonth.month,
                                          );
                                        }
                                        );
                                      }
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        MyText(
                                          text: '${monthNames[displayedMonth.month - 1]} ${displayedMonth.year}',
                                          textStyle: 'title',
                                          textSize: '16',
                                          textColor: 'brand',
                                        ),
                                        const SizedBox(width: 8),
                                        SvgIcon(
                                          svgPath: 'assets/icons_final/arrow-right.svg',
                                          width: 20,
                                          height: 20,
                                          color: DesignTokens.surfaceBrand,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Right group: prev/next month arrows
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          final DateTime prev = DateTime(
                                            displayedMonth.year,
                                            displayedMonth.month - 1,
                                          );
                                          if (prev.isBefore(
                                            DateTime(
                                              firstDate.year,
                                              firstDate.month,
                                            ),
                                          )) return;
                                          setLocalState(() {
                                            displayedMonth = prev;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(20),
                                        child: Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: SvgIcon(
                                            svgPath: 'assets/icons_final/arrow-left.svg',
                                            width: 20,
                                            height: 20,
                                            color: DesignTokens.textBrand,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () {
                                          final DateTime next = DateTime(
                                            displayedMonth.year,
                                            displayedMonth.month + 1,
                                          );
                                          if (next.isAfter(DateTime(lastDate.year, lastDate.month))) return;
                                          setLocalState(() {
                                            displayedMonth = next;
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: SvgIcon(
                                            svgPath: 'assets/icons_final/arrow-right.svg',
                                            width: 20,
                                            height: 20,
                                            color: DesignTokens.textBrand,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Custom calendar grid để ẩn hoàn toàn header gốc
                            _buildCustomCalendar(
                              displayedMonth: displayedMonth,
                              selectedDate: selectedDate,
                              firstDate: firstDate,
                              lastDate: lastDate,
                              onDateSelected: (date) {
                                Navigator.of(dialogContext).pop();
                                setState(() {
                                  selectedDate = date;
                                });
                                widget.onDateSelected(date);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),  
            );
          },
        );
      },
    );  
  }

  Widget _buildCustomCalendar({
    required DateTime displayedMonth,
    required DateTime? selectedDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required Function(DateTime) onDateSelected,
  }) {
    const double tileSize = 44;
    const double rowGap = 8;
    const double gridWidth =
        tileSize * 7; // không đặt khoảng cách cột để khít 7 ô
    final firstDayOfMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month + 1,
      0,
    );
    final firstDayOfWeek = firstDayOfMonth.weekday % 7; // 0 = Sunday
    final daysInMonth = lastDayOfMonth.day;

    // Tạo danh sách ngày trong tháng
    final List<DateTime> days = [];

    // Thêm ngày từ tháng trước (nếu cần)
    final prevMonth = DateTime(displayedMonth.year, displayedMonth.month - 1);
    final lastDayOfPrevMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month,
      0,
    );
    for (int i = firstDayOfWeek - 1; i >= 0; i--) {
      days.add(
        DateTime(prevMonth.year, prevMonth.month, lastDayOfPrevMonth.day - i),
      );
    }

    // Thêm ngày trong tháng hiện tại
    for (int day = 1; day <= daysInMonth; day++) {
      days.add(DateTime(displayedMonth.year, displayedMonth.month, day));
    }

    // Thêm ngày từ tháng sau (nếu cần)
    final nextMonth = DateTime(displayedMonth.year, displayedMonth.month + 1);
    // Giới hạn tối đa 5 hàng (5 x 7 = 35)
    int remainingDays = 35 - days.length;
    for (int day = 1; day <= remainingDays; day++) {
      days.add(DateTime(nextMonth.year, nextMonth.month, day));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Center(
        child: SizedBox(
          width: gridWidth,
          child: Column(
            children: [
              // Days of week header (cố định bề rộng từng ô 44)
              Row(
                children:
                    ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                        .map(
                          (day) => SizedBox(
                            width: tileSize,
                            child: Center(
                              child: MyText(
                                text: day,
                                textStyle: 'label',
                                textSize: '14',
                                textColor: 'tertiary',
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
              SizedBox(height: rowGap),
              // Calendar grid (tối đa 5 hàng)
              ...List.generate(5, (weekIndex) {
                return Padding(
                  padding: EdgeInsets.only(bottom: weekIndex == 4 ? 0 : rowGap),
                  child: Row(
                    children: List.generate(7, (dayColIndex) {
                      final dayIndex = weekIndex * 7 + dayColIndex;
                      if (dayIndex >= days.length) {
                        return const SizedBox(
                          width: tileSize,
                          height: tileSize,
                        );
                      }

                      final date = days[dayIndex];
                      final isCurrentMonth = date.month == displayedMonth.month;
                      final isSelected =
                          selectedDate != null &&
                          date.year == selectedDate.year &&
                          date.month == selectedDate.month &&
                          date.day == selectedDate.day;
                      final isToday =
                          date.year == DateTime.now().year &&
                          date.month == DateTime.now().month &&
                          date.day == DateTime.now().day;
                      final isEnabled =
                          date.isAfter(
                            firstDate.subtract(const Duration(days: 1)),
                          ) &&
                          date.isBefore(lastDate.add(const Duration(days: 1)));

                      return SizedBox(
                        width: tileSize,
                        height: tileSize,
                        child: GestureDetector(
                          onTap:
                              isEnabled && isCurrentMonth
                                  ? () => onDateSelected(date)
                                  : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? DesignTokens.surfaceBrand
                                      : isToday && !isSelected
                                      ? DesignTokens.primaryBlue4
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(tileSize),
                            ),
                            child: Center(
                              child: MyText(
                                text: date.day.toString(),
                                textStyle: 'label',
                                textSize: '14',
                                textColor:
                                    isSelected
                                        ? 'invert'
                                        : isCurrentMonth
                                        ? isToday
                                            ? 'brand'
                                            : 'primary'
                                        : 'secondary',
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<int?> _showCustomYearPicker({
    required BuildContext parentContext,
    required DateTime firstDate,
    required DateTime lastDate,
    required int initialYear,
  }) async {
    final int startYear = firstDate.year;
    final int endYear = lastDate.year;
    final List<int> years = [for (int y = startYear; y <= endYear; y++) y];

    return showDialog<int>(
      context: parentContext,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: DesignTokens.surfacePrimary,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: 44 * 4 + 8 * 3, // 4 cột, gap 8
              height: 44 * 5 + 8 * 4, // 5 hàng, 4 khoảng cách
              child: Scrollbar(
                thumbVisibility: true,
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  physics: const ClampingScrollPhysics(),
                  shrinkWrap: false,
                  itemCount: years.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final y = years[index];
                    final bool isSelected = y == initialYear;
                    final bool isCurrentYear = y == DateTime.now().year;
                    return GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(y),
                      child: Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? DesignTokens.surfaceBrand
                              : isCurrentYear
                                  ? DesignTokens.primaryBlue4
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Center(
                          child: MyText(
                            text: y.toString(),
                            textStyle: 'label',
                            textSize: '14',
                            textColor: isSelected
                                ? 'invert'
                                : isCurrentYear
                                    ? 'brand'
                                    : 'primary',
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final containerHeight = widget.height ?? 44.0;
    final containerPadding =
        widget.padding ??
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12);

    Widget suffixIcon;
    // Fallback dùng icon hệ thống vì asset có thể không tồn tại
    suffixIcon = SvgIcon(
      svgPath: 'assets/icons_final/calendar.svg',
      width: 18,
      height: 18,
      color: widget.enabled ? DesignTokens.textBrand : DesignTokens.textDisable,
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
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Container(
            height: containerHeight,
            padding: containerPadding,
            decoration: BoxDecoration(
              color: DesignTokens.surfacePrimary,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color:
                    widget.hasError
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
                    text:
                        selectedDate != null
                            ? _formatDate(selectedDate!)
                            : 'DD/MM/YYYY',
                    textStyle: 'label',
                    textSize: '14',
                    color:
                        widget.enabled
                            ? selectedDate != null
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
