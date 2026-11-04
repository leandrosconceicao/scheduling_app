import 'package:flutter/foundation.dart';

import '../../domain/domain.dart';

final class OwnerSessionService extends ChangeNotifier
    implements IOwnerSessionService {
  static const _tokenKey = "owner_token";

  final ILocalRepository _repository;

  OwnerSessionService(this._repository);

  @override
  String get token => _repository.read<String>(_tokenKey) ?? "";

  @override
  bool get isAuthenticated => token.isNotEmpty;

  @override
  Future<void> start(String token) async {
    await _repository.write(_tokenKey, token);
    notifyListeners();
  }

  @override
  Future<void> end() async {
    await _repository.remove(_tokenKey);
    notifyListeners();
  }
}
