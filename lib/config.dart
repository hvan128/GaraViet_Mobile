class Config {
  // static const String baseUrl = 'https://14.224.137.80:5009/api/v1';
  static const String baseUrl = 'http://157.66.219.148:5006/api/v1';

  //* Auth API *//
  static const String createRoleUrl = '$baseUrl/auth/create-role';
  static const String refreshTokenUrl = '$baseUrl/auth/refresh-token';
  static const String resendOtpUrl = '$baseUrl/auth/resend-otp';
  static const String sendOtpUrl = '$baseUrl/auth/send-otp';
  static const String signContractGarageUrl =
      '$baseUrl/auth/sign-contract-for-garage';
  static const String userLoginUrl = '$baseUrl/auth/user-login';
  static const String logoutUrl = '$baseUrl/auth/user-logout';
  static const String userRegisterGarageUrl =
      '$baseUrl/auth/user-register-for-garage';
  static const String userRegisterUrl = '$baseUrl/auth/user-register-for-user';
  static const String verifyOtpUrl = '$baseUrl/auth/verify-otp';

  //* Manager-User API *//
  static const String userGetInfoUrl = '$baseUrl/manager-user/get-infor-user';
  static const String userUpdateInfoUrl =
      '$baseUrl/manager-user/update-infor-user';
  static const String userUpdateGarageUrl =
      '$baseUrl/manager-user/update-infor-garage';
  static const String userUpdateCertificateUrl =
      '$baseUrl/manager-user/update-certificate';
  static const String userUpdateGarageRegisterAttachmentUrl =
      '$baseUrl/manager-user/update-garage-register-attachment';
  static const String userChangePasswordUrl =
      '$baseUrl/manager-user/change-password';
  static const String userDeactivateUrl =
      '$baseUrl/manager-user/deactivate-account';
  static const String userUploadAvatarUrl =
      '$baseUrl/manager-user/upload-avatar';
  static const String userDeleteAvatarUrl =
      '$baseUrl/manager-user/delete-avatar';
  static const String userVerifyGarageUrl =
      '$baseUrl/manager-user/verify-garage';

  //* Manager-Car API *//
  static const String carCreateUrl = '$baseUrl/manager-car/create-car';
  static const String carDeleteUrl = '$baseUrl/manager-car/delete-car';
  static const String carGetAllUrl = '$baseUrl/manager-car/get-all-car';
  static const String carGetByIdUrl = '$baseUrl/manager-car/get-car-by-id';
  static const String carUpdateUrl = '$baseUrl/manager-car/update-car';

  //* Manager-Request API *//
  static const String requestCreateUrl =
      '$baseUrl/manager-request/create-request';
  static const String requestDeleteUrl =
      '$baseUrl/manager-request/delete-request';
  static const String requestGetAllUrl =
      '$baseUrl/manager-request/get-all-requests';
  static const String requestGetByIdUrl =
      '$baseUrl/manager-request/get-request-by-id';
  static const String requestUpdateUrl =
      '$baseUrl/manager-request/update-request';
  static const String requestGetAllForGarageUrl =
      '$baseUrl/manager-request/get-all-requests-garage';

  //* Manager-Quotation API *//
  static const String quotationCreateUrl =
      '$baseUrl/manager-quotation/create-quotation';
  static const String quotationDeleteUrl =
      '$baseUrl/manager-quotation/delete-quotation';
  static const String quotationGetAllByGarageUrl =
      '$baseUrl/manager-quotation/get-all-quotations-by-garage-id';
  static const String quotationGetAllByRequestUrl =
      '$baseUrl/manager-quotation/get-all-quotations-by-request-service-id';
  static const String quotationGetByCarUrl =
      '$baseUrl/manager-quotation/get-quotation-by-car-id';
  static const String quotationGetByIdUrl =
      '$baseUrl/manager-quotation/get-quotation-by-id';
  static const String quotationGetByUserUrl =
      '$baseUrl/manager-quotation/get-quotation-by-user-id';
  static const String quotationUpdateUrl =
      '$baseUrl/manager-quotation/update-quotation';

  //* Location API *//
  static const String locationDeleteUrl = '$baseUrl/location/delete-location';
  static const String locationDirectionsUrl = '$baseUrl/location/directions';
  static const String locationPlaceDetailsUrl =
      '$baseUrl/location/place-details';
  static const String locationReverseGeoUrl =
      '$baseUrl/location/reverse-geocode';
  static const String locationSaveUrl = '$baseUrl/location/save-location';
  static const String locationSavedUrl = '$baseUrl/location/saved-locations';
  static const String locationSearchUrl = '$baseUrl/location/search-places';
  static const String locationUpdateUrl = '$baseUrl/location/update-location';

  //* Admin API *//
  static const String adminCacheStatsUrl = '$baseUrl/admin/cache-stats';
  static const String adminChangeStarRatingStandardNoJwtUrl =
      '$baseUrl/admin/change-star-rating-standard-no-jwt';
  static const String adminChangeWarrantyNoJwtUrl =
      '$baseUrl/admin/change-warranty-no-jwt';
  static const String adminClearPhoneCacheUrl =
      '$baseUrl/admin/clear-phone-cache';

  // Vouchers
  static const String adminCreateVoucherUrl = '$baseUrl/admin/vouchers';
  static const String adminGetActiveVouchersUrl =
      '$baseUrl/admin/vouchers/active';
  static const String adminGetVoucherDetailUrl =
      '$baseUrl/admin/vouchers/detail';
  static const String adminToggleVoucherStatusUrl =
      '$baseUrl/admin/vouchers/toggle-status';
  // For DELETE: append '/{voucher_id}' when calling
  static const String adminDeleteVoucherUrl = '$baseUrl/admin/vouchers';

  // Data Contract
  static const String adminCreateDataContractUrl =
      '$baseUrl/admin/data-contract/create-data-contract';
  static const String adminDeleteDataContractUrl =
      '$baseUrl/admin/data-contract/delete-data-contract';
  static const String adminGetAllDataContractsUrl =
      '$baseUrl/admin/data-contract/get-all-data-contracts';
  static const String adminGetDataContractByIdUrl =
      '$baseUrl/admin/data-contract/get-data-contract-by-id';
  static const String adminGetDataContractByVersionUrl =
      '$baseUrl/admin/data-contract/get-data-contract-by-version';
  static const String adminUpdateDataContractUrl =
      '$baseUrl/admin/data-contract/update-data-contract';

  //* Payment API *//
  static const String paymentCheckVietqrConnectionUrl =
      '$baseUrl/payment/check-vietqr-connection';
  static const String paymentCreateQrUrl = '$baseUrl/payment/create-qr';
  static const String paymentCheckStatusUrl = '$baseUrl/payment/check-status';
  static const String paymentManualUpdateStatusUrl =
      '$baseUrl/payment/manual-update-status';
  static const String paymentPollingUrl = '$baseUrl/payment/polling';
  static const String paymentWebhookUrl = '$baseUrl/payment/webhook';

  //* Booking API *//
  static const String bookingCreateUrl = '$baseUrl/booking/create-booking';
  static const String bookingDetailUrl = '$baseUrl/booking/detail';
  static const String bookingGarageBookedQuotationsUrl =
      '$baseUrl/booking/garage-booked-quotations';
  static const String bookingUserBookedServicesUrl =
      '$baseUrl/booking/user-booked-services';
  static const String bookingCompleteOrderUrl =
      '$baseUrl/booking/complete-order';
  static const String bookingCancelOrderUrl =
      '$baseUrl/booking/cancel-order';
  static const String bookingCalculateGarageOrdersPriceUrl =
      '$baseUrl/booking/calculate-garage-orders-price';

  //* Messaging API *//
  static const String messagingCreateRoomFromRequestUrl =
      '$baseUrl/messaging/create-room-from-request';
  static const String messagingGetAllRoomUrl = '$baseUrl/messaging/get-all-room';
  static const String messagingDeleteRoomUrl = '$baseUrl/messaging/room';
  static const String messagingDeleteMessageUrl = '$baseUrl/messaging/room';
  static const String messagingMarkMessageReadUrl = '$baseUrl/messaging/room';
  static const String messagingGetRoomMessagesUrl = '$baseUrl/messaging/room';
  static const String messagingSendMessageUrl = '$baseUrl/messaging/room';
  static const String messagingGetRoomsUrl = '$baseUrl/messaging/rooms';
  static const String messagingGetUnreadCountUrl = '$baseUrl/messaging/unread-count';
  
  //* Notification API *//
  static const String notificationListUrl = '$baseUrl/notification/list';
  
  //* Firebase API *//
  static const String firebaseRegisterTokenUrl = '$baseUrl/firebase/register-token';
}
