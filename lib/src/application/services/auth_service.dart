import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:ltech_core/ltech_core.dart';
import '../../domain/domain.dart';
import '../application.dart';

final class AuthService extends GetxController implements IAuthService {

  String get _ownerEndpoint => "/owner";

  @override
  String get uid => user.value?.uid ?? "";

  @override
  void onInit() {
    _firebaseAuth.authStateChanges().listen((currentUser) async {
      user.trigger(currentUser);
      if (currentUser == null) {
        await signInAnonymously();
      }
      await saveJwtToken();
      if (!_ready.isCompleted) _ready.complete();
    });
    super.onInit();
  }

  final _firebaseAuth = FirebaseAuth.instance;

  final repository = Get.find<ILocalRepository>();

  final user = Rxn<User>();

  final _ready = Completer<void>();

  /// Completa quando o primeiro token (anônimo ou não) já foi salvo.
  @override
  Future<void> get tokenReady => _ready.future;

  Future<void> saveJwtToken() async {
    try {
      final idToken = await user.value?.getIdTokenResult();

      if (!(idToken?.token?.hasContent ?? false)) {
        repository.remove("access_token");
        return;
      }

      repository.write("access_token", idToken!.token!);
    } catch (_) {
      repository.remove("access_token");
    }
  }

  Future<void> signInAnonymously() async {
    try {
      await _firebaseAuth.signInAnonymously();
    } catch (_) {
    }
  }

  @override
  bool get isLoggedIn => user.value != null;

  @override
  Future<ApiResponse<UserCredential?>> loginWithEmail(
    String email,
    String password,
  ) async {
    try {
      final userCredencial = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return ApiResponse.result(data: userCredencial);
    } catch (e) {
      return ApiResponse.unknow(errorDescription: "Credenciais inválidas");
    }
  }

  @override
  Future<ApiResponse<dynamic>> logout() async {
    try {
      await _firebaseAuth.signOut();

      return ApiResponse.success();
    } catch (e) {
      return ApiResponse.unknow();
    }
  }

  @override
  Future<ApiResponse<dynamic>> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name);

      return ApiResponse.success();
    } catch (e) {
      return ApiResponse.badRequest(errorDescription: "Não foi possível cadastrar o usuário");
    }
  }

  @override
  Future<ApiResponse<OwnerAuthorizationDto?>> authorizeOwner(OwnerAuthorizationDto request) {
    final client = Get.find<IHttpClient>();
    return client.post(
      endpoint: "$_ownerEndpoint/auth",
      requestBody: request.toJson(),
      parser: (json) => OwnerAuthorizationDto.fromJson(json),
    );
  }

  @override
  String get userEmail => user.value?.email ?? "";

  @override
  String get userName => (user.value?.displayName?.hasContent ?? false)
      ? (user.value?.displayName ?? "")
      : "Nome do usuário";

  @override
  String get profilePhotoImage => user.value?.photoURL ?? "";

  @override
  String get phoneNumber => user.value?.phoneNumber ?? "";

  @override
  bool get isAnonymous => user.value?.isAnonymous ?? true;
}
