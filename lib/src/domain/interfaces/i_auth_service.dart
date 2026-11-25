import 'package:firebase_auth/firebase_auth.dart';
import 'package:ltech_core/ltech_core.dart';

import '../../application/application.dart';

const googleLoginCancelled = "google-login-cancelled";

abstract interface class IAuthService {

  bool get isLoggedIn;
  bool get isAnonymous;

  String get userEmail;
  String get userName;
  String get phoneNumber;
  String get profilePhotoImage;
  String get uid;

  /// Completa quando o token inicial já está disponível no repositório local.
  Future<void> get tokenReady;

  Future<ApiResponse<UserCredential?>> loginWithEmail(String email, String password);
  /// Login via popup do Google (web). Cancelamento pelo usuário retorna
  /// [googleLoginCancelled] como descrição do erro.
  Future<ApiResponse<UserCredential?>> loginWithGoogle();
  Future<ApiResponse> signUpWithEmail(String email, String password, String name);
  Future<ApiResponse> logout();
  Future<ApiResponse<OwnerAuthorizationDto?>> authorizeOwner(OwnerAuthorizationDto request);
}