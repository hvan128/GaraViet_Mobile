import 'dart:io';
import 'package:flutter/foundation.dart';

enum UserType {
  customer,
  garage,
}

class RegistrationData extends ChangeNotifier {
  // Common data
  String? phoneNumber;
  String? password;
  String? confirmPassword;
  UserType? selectedUserType;

  // User specific data
  String? fullName;
  String? vehicleType;
  String? vehicleYear;
  String? licensePlate;

  // Gara specific data
  String? garageName;
  int? numberOfWorkers;
  String? address;
  String? email;
  double? latitude;
  double? longitude;
  String? descriptionGarage;
  List<File>? garageImages;
  String? cccd;
  DateTime? issueDate;
  String? signature;

  // OTP verification
  String? otpCode;
  bool isOtpVerified = false;

  // Registration status
  bool isRegistrationComplete = false;

  // Clear all data
  void clear() {
    phoneNumber = null;
    password = null;
    confirmPassword = null;
    selectedUserType = null;
    fullName = null;
    vehicleType = null;
    vehicleYear = null;
    licensePlate = null;
    garageName = null;
    numberOfWorkers = null;
    address = null;
    email = null;
    latitude = null;
    longitude = null;
    descriptionGarage = null;
    garageImages = null;
    cccd = null;
    issueDate = null;
    signature = null;
    otpCode = null;
    isOtpVerified = false;
    isRegistrationComplete = false;
    notifyListeners();
  }

  // Validate common fields
  bool validateCommonFields() {
    return phoneNumber != null &&
        phoneNumber!.isNotEmpty &&
        password != null &&
        password!.isNotEmpty &&
        confirmPassword != null &&
        confirmPassword!.isNotEmpty &&
        password == confirmPassword;
  }

  // Validate user specific fields
  bool validateUserFields() {
    return fullName != null &&
        fullName!.isNotEmpty &&
        vehicleType != null &&
        vehicleType!.isNotEmpty &&
        vehicleYear != null &&
        vehicleYear!.isNotEmpty &&
        licensePlate != null &&
        licensePlate!.isNotEmpty;
  }

  // Validate garage specific fields
  bool validateGarageFields() {
    return garageName != null &&
        garageName!.isNotEmpty &&
        address != null &&
        address!.isNotEmpty &&
        email != null &&
        email!.isNotEmpty &&
        numberOfWorkers != null &&
        numberOfWorkers! > 0;
  }

  // Validate OTP
  bool validateOtp() {
    return otpCode != null && otpCode!.length == 4 && isOtpVerified;
  }

  // Get masked phone number
  String getMaskedPhoneNumber() {
    if (phoneNumber == null || phoneNumber!.length <= 4) {
      return phoneNumber ?? '';
    }
    String prefix = phoneNumber!.substring(0, 3);
    String suffix = phoneNumber!.substring(phoneNumber!.length - 2);
    String middle = '*' * (phoneNumber!.length - 5);
    return '+$prefix$middle$suffix';
  }

  // Setter methods with notifyListeners
  void setPhoneNumber(String? value) {
    phoneNumber = value;
    notifyListeners();
  }

  void setPassword(String? value) {
    password = value;
    notifyListeners();
  }

  void setConfirmPassword(String? value) {
    confirmPassword = value;
    notifyListeners();
  }

  void setSelectedUserType(UserType? value) {
    selectedUserType = value;
    notifyListeners();
  }

  void setFullName(String? value) {
    fullName = value;
    notifyListeners();
  }

  void setVehicleType(String? value) {
    vehicleType = value;
    notifyListeners();
  }

  void setVehicleYear(String? value) {
    vehicleYear = value;
    notifyListeners();
  }

  void setLicensePlate(String? value) {
    licensePlate = value;
    notifyListeners();
  }

  void setGarageName(String? value) {
    garageName = value;
    notifyListeners();
  }

  void setNumberOfWorkers(int? value) {
    numberOfWorkers = value;
    notifyListeners();
  }

  void setAddress(String? value) {
    address = value;
    notifyListeners();
  }

  void setLatitude(double? value) {
    latitude = value;
    notifyListeners();
  }

  void setLongitude(double? value) {
    longitude = value;
    notifyListeners();
  }

  void setEmail(String? value) {
    email = value;
    notifyListeners();
  }

  void setDescriptionGarage(String? value) {
    descriptionGarage = value;
    notifyListeners();
  }

  void setGarageImages(List<File>? value) {
    garageImages = value;
    notifyListeners();
  }

  void setCccd(String? value) {
    cccd = value;
    notifyListeners();
  }

  void setIssueDate(DateTime? value) {
    issueDate = value;
    notifyListeners();
  }

  void setSignature(String? value) {
    signature = value;
    notifyListeners();
  }

  void setOtpCode(String? value) {
    otpCode = value;
    notifyListeners();
  }

  void setOtpVerified(bool value) {
    isOtpVerified = value;
    notifyListeners();
  }

  void setRegistrationComplete(bool value) {
    isRegistrationComplete = value;
    notifyListeners();
  }
}
