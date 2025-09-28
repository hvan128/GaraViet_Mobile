import 'package:flutter/material.dart';

class Navigate {
  final GlobalKey<NavigatorState> navigationKey;

  static final Navigate _instance = Navigate._();

  Navigate._() : navigationKey = GlobalKey<NavigatorState>();

  factory Navigate() => _instance;

  static dynamic pushReplacement(Route route, {Object? arguments}) {
    return _instance.navigationKey.currentState?.pushReplacement(route);
  }

  static dynamic pushReplacementNamed(String routeName, {Object? arguments}) {
    return _instance.navigationKey.currentState?.pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  static dynamic pushNamed(String routeName, {Object? arguments}) {
    return _instance.navigationKey.currentState?.pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  static dynamic push(Route route) {
    return _instance.navigationKey.currentState?.push(route);
  }

  static dynamic pop() {
    return _instance.navigationKey.currentState?.pop();
  }

  /// Push and remove all previous routes
  static dynamic pushNamedAndRemoveAll(String routeName, {Object? arguments}) {
    return _instance.navigationKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      arguments: arguments,
      (route) => false,
    );
  }

  /// Push and remove all previous routes using ```route```
  static dynamic pushAndRemoveAll(Route route) {
    return _instance.navigationKey.currentState?.pushAndRemoveUntil(
      route,
      (route) => false,
    );
  }

  /// Push and remove all the previous routes until the predicate using ```route```
  static dynamic pushAndRemoveUntil(
    Route route,
    String removeRouteName,
  ) {
    return _instance.navigationKey.currentState?.pushAndRemoveUntil(
      route,
      ModalRoute.withName(removeRouteName),
    );
  }

  /// Push and remove all the previous routes until the predicate using ```routeName```
  static dynamic pushNamedAndRemoveUntil(
    String routeName,
    String removeRouteName, {
    Object? arguments,
  }) {
    return _instance.navigationKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      arguments: arguments,
      ModalRoute.withName(removeRouteName),
    );
  }
}
