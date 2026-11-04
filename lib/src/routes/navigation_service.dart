import 'package:go_router/go_router.dart';

import '../domain/domain.dart';
import 'app_routes.dart';

final class GoRouterNavigationService implements INavigationService {
  final GoRouter _router;

  GoRouterNavigationService(this._router);

  @override
  void toSchedule(String companyId) => _router.goSchedule(companyId);

  @override
  Future<bool> requestLogin(String companyId) async {
    return await _router.pushLogin(companyId) ?? false;
  }
}
