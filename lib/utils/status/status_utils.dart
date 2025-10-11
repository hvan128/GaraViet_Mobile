import 'package:flutter/material.dart';
import 'quotation_status.dart';
import 'request_status.dart';
import 'status_widget.dart';
import 'booking_status.dart';

class StatusUtils {
  // Quotation Status Utilities
  static List<QuotationStatus> getAllQuotationStatuses() {
    return QuotationStatus.values;
  }

  static QuotationStatus getQuotationStatusByValue(int value) {
    return QuotationStatus.fromValue(value);
  }

  static List<QuotationStatus> getQuotationStatusesByColor({Color? bg, Color? text, Color? border}) {
    return QuotationStatus.values.where((status) {
      final c = status.color;
      final bgOk = bg == null || c.background == bg;
      final textOk = text == null || c.text == text;
      final borderOk = border == null || c.border == border;
      return bgOk && textOk && borderOk;
    }).toList();
  }

  static bool canTransitionQuotationStatus(int fromValue, int toValue) {
    final fromStatus = QuotationStatus.fromValue(fromValue);
    final toStatus = QuotationStatus.fromValue(toValue);
    return fromStatus.canTransitionTo(toStatus);
  }

  static List<QuotationStatus> getNextPossibleQuotationStatuses(int currentValue) {
    final currentStatus = QuotationStatus.fromValue(currentValue);
    return QuotationStatus.values
        .where((status) => currentStatus.canTransitionTo(status))
        .toList();
  }

  // Request Status Utilities
  static List<RequestStatus> getAllRequestStatuses() {
    return RequestStatus.values;
  }

  static RequestStatus getRequestStatusByValue(int value) {
    return RequestStatus.fromValue(value);
  }

  static List<RequestStatus> getRequestStatusesByColor({Color? bg, Color? text, Color? border}) {
    return RequestStatus.values.where((status) {
      final c = status.color;
      final bgOk = bg == null || c.background == bg;
      final textOk = text == null || c.text == text;
      final borderOk = border == null || c.border == border;
      return bgOk && textOk && borderOk;
    }).toList();
  }

  static bool canTransitionRequestStatus(int fromValue, int toValue) {
    final fromStatus = RequestStatus.fromValue(fromValue);
    final toStatus = RequestStatus.fromValue(toValue);
    return fromStatus.canTransitionTo(toStatus);
  }

  static List<RequestStatus> getNextPossibleRequestStatuses(int currentValue) {
    final currentStatus = RequestStatus.fromValue(currentValue);
    return RequestStatus.values
        .where((status) => currentStatus.canTransitionTo(status))
        .toList();
  }

  // Common Utilities
  static String getStatusDisplayName(dynamic status, StatusType type) {
    if (type == StatusType.quotation) {
      final quotationStatus = status is int 
          ? QuotationStatus.fromValue(status)
          : status as QuotationStatus;
      return quotationStatus.displayName;
    } else if (type == StatusType.request) {
      final requestStatus = status is int 
          ? RequestStatus.fromValue(status)
          : status as RequestStatus;
      return requestStatus.displayName;
    } else {
      final bookingStatus = status is int
          ? BookingStatus.fromValue(status)
          : status as BookingStatus;
      return bookingStatus.displayName;
    }
  }

  static Map<String, Color> getStatusColors(dynamic status, StatusType type) {
    if (type == StatusType.quotation) {
      final quotationStatus = status is int 
          ? QuotationStatus.fromValue(status)
          : status as QuotationStatus;
      return {
        'bg': quotationStatus.color.background,
        'text': quotationStatus.color.text,
        'border': quotationStatus.color.border,
      };
    } else if (type == StatusType.request) {
      final requestStatus = status is int 
          ? RequestStatus.fromValue(status)
          : status as RequestStatus;
      return {
        'bg': requestStatus.color.background,
        'text': requestStatus.color.text,
        'border': requestStatus.color.border,
      };
    } else {
      final bookingStatus = status is int
          ? BookingStatus.fromValue(status)
          : status as BookingStatus;
      return {
        'bg': bookingStatus.color.background,
        'text': bookingStatus.color.text,
        'border': bookingStatus.color.border,
      };
    }
  }

  // Validation
  static bool isValidQuotationStatus(int value) {
    return QuotationStatus.values.any((status) => status.value == value);
  }

  static bool isValidRequestStatus(int value) {
    return RequestStatus.values.any((status) => status.value == value);
  }

  // Status mapping for API
  static Map<String, dynamic> quotationStatusToJson(QuotationStatus status) {
    return {
      'value': status.value,
      'display_name': status.displayName,
      'colors': {
        'bg': status.color.background.value,
        'text': status.color.text.value,
        'border': status.color.border.value,
      },
    };
  }

  static Map<String, dynamic> requestStatusToJson(RequestStatus status) {
    return {
      'value': status.value,
      'display_name': status.displayName,
      'colors': {
        'bg': status.color.background.value,
        'text': status.color.text.value,
        'border': status.color.border.value,
      },
    };
  }

  // Get status by display name
  static QuotationStatus? getQuotationStatusByDisplayName(String displayName) {
    try {
      return QuotationStatus.values.firstWhere(
        (status) => status.displayName == displayName,
      );
    } catch (e) {
      return null;
    }
  }

  static RequestStatus? getRequestStatusByDisplayName(String displayName) {
    try {
      return RequestStatus.values.firstWhere(
        (status) => status.displayName == displayName,
      );
    } catch (e) {
      return null;
    }
  }
}

