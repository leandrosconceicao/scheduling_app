import 'package:firebase_auth/firebase_auth.dart';
import 'package:ltech_core/ltech_core.dart';

import '../../application/application.dart';

abstract interface class IAuthService {

  bool get isLoggedIn;
  bool get isAnonymous;

  String get userEmail;
  String get userName;
  String get phoneNumber;
  String get profilePhotoImage;
  String get uid;

  Future<ApiResponse<UserCredential?>> loginWithEmail(String email, String password);
  Future<ApiResponse> signUpWithEmail(String email, String password, String name);
  Future<ApiResponse> logout();
  Future<ApiResponse<OwnerAuthorizationDto?>> authorizeOwner(OwnerAuthorizationDto request);
}