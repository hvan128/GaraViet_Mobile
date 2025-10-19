import 'dart:async';

/// Sự kiện khi cần reload màn hình messages từ bên ngoài
class ReloadMessagesEvent {
  final String? reason; // Lý do reload (optional)
  
  ReloadMessagesEvent({this.reason});
}

/// Sự kiện khi cần reload màn hình Yêu cầu từ bên ngoài
class ReloadRequestsEvent {
  final String? reason; // Lý do reload (optional)
  final Map<String, dynamic>? notificationData; // Data từ Firebase notification

  ReloadRequestsEvent({this.reason, this.notificationData});
}

/// Sự kiện khi cần reload user info từ bên ngoài
class ReloadUserInfoEvent {
  final String? reason; // Lý do reload (optional)
  
  ReloadUserInfoEvent({this.reason});
}

/// Event bus cho navigation và reload màn hình
class NavigationEventBus {
  NavigationEventBus._();

  static final NavigationEventBus _instance = NavigationEventBus._();
  factory NavigationEventBus() => _instance;

  final StreamController<ReloadMessagesEvent> _reloadMessagesController =
      StreamController<ReloadMessagesEvent>.broadcast();
  final StreamController<ReloadRequestsEvent> _reloadRequestsController =
      StreamController<ReloadRequestsEvent>.broadcast();
  final StreamController<ReloadUserInfoEvent> _reloadUserInfoController =
      StreamController<ReloadUserInfoEvent>.broadcast();

  Stream<ReloadMessagesEvent> get onReloadMessages => _reloadMessagesController.stream;
  Stream<ReloadRequestsEvent> get onReloadRequests => _reloadRequestsController.stream;
  Stream<ReloadUserInfoEvent> get onReloadUserInfo => _reloadUserInfoController.stream;

  void emitReloadMessages({String? reason}) {
    if (!_reloadMessagesController.isClosed) {
      _reloadMessagesController.add(ReloadMessagesEvent(reason: reason));
    }
  }

  void emitReloadRequests({String? reason, Map<String, dynamic>? notificationData}) {
    if (!_reloadRequestsController.isClosed) {
      _reloadRequestsController.add(ReloadRequestsEvent(reason: reason, notificationData: notificationData));
    }
  }

  void emitReloadUserInfo({String? reason}) {
    if (!_reloadUserInfoController.isClosed) {
      _reloadUserInfoController.add(ReloadUserInfoEvent(reason: reason));
    }
  }

  void dispose() {
    _reloadMessagesController.close();
    _reloadRequestsController.close();
    _reloadUserInfoController.close();
  }
}
