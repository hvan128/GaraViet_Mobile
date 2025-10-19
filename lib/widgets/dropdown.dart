import 'package:flutter/material.dart';
import 'package:gara/theme/index.dart';
import 'package:gara/widgets/text.dart';
import 'package:gara/widgets/svg_icon.dart';
// import 'package:flutter_svg/flutter_svg.dart';

class MyDropdown extends StatefulWidget {
  final List<DropdownItem> items;
  final String? selectedValue;
  final Function(String?)? onChanged;
  final String? hintText;
  final bool enabled;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;
  final Color? textColor;
  final double borderRadius;
  final bool showIcon;
  final dynamic
  icon; // Hỗ trợ cả IconData và Widget; null thì không có prefix icon
  final IconData? dropdownIcon;
  final String? title;
  final bool showTitle;
  final String? label;
  final bool showLabel;
  final TextStyle? labelStyle;
  final bool hasError;
  final String? errorText;

  const MyDropdown({
    super.key,
    required this.items,
    this.selectedValue,
    this.onChanged,
    this.hintText,
    this.enabled = true,
    this.padding,
    this.height,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
    this.textColor,
    this.borderRadius = 12.0,
    this.showIcon = false,
    this.icon,
    this.dropdownIcon = Icons.keyboard_arrow_down,
    this.title,
    this.showTitle = true,
    this.label,
    this.showLabel = true,
    this.labelStyle,
    this.hasError = false,
    this.errorText,
  });

  @override
  State<MyDropdown> createState() => _MyDropdownState();
}

class DropdownItem {
  final String value;
  final String label;
  final String? description;
  final dynamic icon; // Hỗ trợ cả IconData và Widget

  const DropdownItem({
    required this.value,
    required this.label,
    this.description,
    this.icon,
  });
}

class _MyDropdownState extends State<MyDropdown> {
  String? _selectedValue;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.selectedValue;
  }

  @override
  void didUpdateWidget(MyDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValue != oldWidget.selectedValue) {
      _selectedValue = widget.selectedValue;
    }
  }

  bool _isShowingHint() {
    if (_selectedValue == null || _selectedValue!.isEmpty) {
      return true;
    }
    final exists = widget.items.any((item) => item.value == _selectedValue);
    return !exists;
  }

  String _getDisplayText() {
    if (_selectedValue != null && _selectedValue!.isNotEmpty) {
      try {
        final selectedItem = widget.items.firstWhere(
          (item) => item.value == _selectedValue,
        );
        return selectedItem.label;
      } catch (e) {
        // Nếu không tìm thấy item, trả về hint text
        return widget.hintText ?? 'Chọn';
      }
    }
    return widget.hintText ?? 'Chọn';
  }

  Widget _buildSelectedItemIcon() {
    if (!(widget.showIcon)) {
      return const SizedBox();
    }

    if (_selectedValue != null) {
      final selectedItem = widget.items.firstWhere(
        (item) => item.value == _selectedValue,
        orElse: () => DropdownItem(value: '', label: widget.hintText ?? 'Chọn'),
      );

      if (selectedItem.icon != null) {
        if (selectedItem.icon is IconData) {
          return Icon(
            selectedItem.icon as IconData,
            color: widget.iconColor ?? Colors.blue[600],
            size: 20,
          );
        } else {
          return selectedItem.icon as Widget;
        }
      }
    }

    // Fallback to provided icon
    if (widget.icon is IconData) {
      return Icon(
        widget.icon as IconData,
        color: widget.iconColor ?? Colors.blue[600],
        size: 20,
      );
    } else if (widget.icon is Widget) {
      return widget.icon as Widget;
    }

    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel && widget.label != null) ...[
          MyText(
            text: widget.label!,
            textStyle: 'body',
            textSize: '14',
            textColor: 'secondary',
          ),
          const SizedBox(height: 6),
        ],
        GestureDetector(
          onTap: widget.enabled ? _showDropdown : null,
          child: Container(
            height: widget.height ?? 44,
            padding:
                widget.padding ??
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? DesignTokens.surfacePrimary,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color:
                    widget.hasError
                        ? DesignTokens.alerts['error']!
                        : widget.borderColor ?? DesignTokens.borderPrimary,
                width: widget.hasError ? 2 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.showIcon &&
                    (widget.icon != null || _selectedValue != null)) ...[
                  _buildSelectedItemIcon(),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: MyText(
                    text: _getDisplayText(),
                    textStyle: 'label',
                    textSize: '14',
                    textColor: _isShowingHint() ? 'placeholder' : 'primary',
                  ),
                ),
                _isOpen
                    ? SvgIcon(
                      svgPath: 'assets/icons_final/arrow-up.svg',
                      width: 16,
                      height: 16,
                    )
                    : SvgIcon(
                      svgPath: 'assets/icons_final/arrow-down.svg',
                      width: 16,
                      height: 16,
                    ),
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

  void _showDropdown() {
    setState(() {
      _isOpen = true;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    if (widget.showIcon && widget.icon != null) ...[
                      widget.icon is IconData
                          ? Icon(
                            widget.icon as IconData,
                            color: Colors.blue[600],
                            size: 20,
                          )
                          : widget.icon as Widget,
                      const SizedBox(width: 12),
                    ],
                    MyText(
                      text: widget.title ?? 'Chọn',
                      textStyle: 'body',
                      textSize: '14',
                      textColor: 'secondary',
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _isOpen = false;
                        });
                      },
                      child: SvgIcon(
                        svgPath: 'assets/icons_final/close.svg',
                        width: 16,
                        height: 16,
                      ),
                    ),
                  ],
                ),
              ),

              // Items list
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    final isSelected = item.value == _selectedValue;

                    return ListTile(
                      leading:
                          widget.showIcon &&
                                  (item.icon != null || widget.icon != null)
                              ? (item.icon != null
                                  ? (item.icon is IconData
                                      ? Icon(
                                        item.icon as IconData,
                                        color:
                                            isSelected
                                                ? Colors.blue[600]
                                                : Colors.grey[400],
                                        size: 20,
                                      )
                                      : item.icon as Widget)
                                  : (widget.icon is IconData
                                      ? Icon(
                                        widget.icon as IconData,
                                        color:
                                            isSelected
                                                ? Colors.blue[600]
                                                : Colors.grey[400],
                                        size: 20,
                                      )
                                      : widget.icon as Widget))
                              : null,
                      title: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? Colors.blue[600] : Colors.black87,
                        ),
                      ),
                      subtitle:
                          item.description != null
                              ? Text(
                                item.description!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              )
                              : null,
                      trailing:
                          isSelected
                              ? Icon(
                                Icons.check_circle,
                                color: Colors.blue[600],
                                size: 20,
                              )
                              : null,
                      onTap: () {
                        setState(() {
                          _selectedValue = item.value;
                          _isOpen = false;
                        });
                        widget.onChanged?.call(item.value);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      setState(() {
        _isOpen = false;
      });
    });
  }
}
