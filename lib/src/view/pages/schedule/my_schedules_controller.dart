import 'package:get/get.dart';

import '../../../domain/domain.dart';
import '../../../shared/shared.dart';

/// Uma lista paginada de agendamentos (aba da tela).
final class ScheduleFeed {
  final SchedulePeriod period;
  final bool includeCanceled;

  final items = <Schedule>[].obs;
  final loading = false.obs;
  final loadingMore = false.obs;
  final loaded = false.obs;
  final hasMore = false.obs;
  final error = "".obs;

  int _page = 0;

  ScheduleFeed(this.period, {this.includeCanceled = false});

  bool get busy => loading.value || loadingMore.value;
}

/// "Meus agendamentos": próximos e histórico do cliente logado.
final class MySchedulesController extends GetxController {
  static const pageSize = 20;

  final String companyId;

  final _service = Get.find<ICompanyService>();
  final _auth = Get.find<IAuthService>();

  final upcoming = ScheduleFeed(SchedulePeriod.upcoming);

  /// O histórico inclui os cancelados, com o motivo.
  final history = ScheduleFeed(SchedulePeriod.past, includeCanceled: true);

  MySchedulesController(this.companyId);

  bool get isLogged => _auth.isLoggedIn && !_auth.isAnonymous;

  @override
  void onInit() {
    super.onInit();
    if (isLogged) load(upcoming);
  }

  /// O histórico só é buscado quando a aba é aberta.
  void ensureLoaded(ScheduleFeed feed) {
    if (isLogged && !feed.loaded.value && !feed.busy) load(feed);
  }

  /// Recarrega do início ([more] = `false`) ou traz a próxima página.
  Future<void> load(ScheduleFeed feed, {bool more = false}) async {
    if (feed.busy || (more && !feed.hasMore.value)) return;

    more ? feed.loadingMore.value = true : feed.loading.value = true;
    feed.error.value = "";

    final page = more ? feed._page + 1 : 1;
    final res = await _service.getClientSchedules(
      period: feed.period,
      includeCanceled: feed.includeCanceled,
      page: page,
      limit: pageSize,
    );

    if (res.result) {
      final received = res.data ?? const <Schedule>[];
      more ? feed.items.addAll(received) : feed.items.assignAll(received);
      feed._page = page;
      feed.hasMore.value = received.length >= pageSize;
      feed.loaded.value = true;
    } else {
      feed.error.value = res.description.hasContent
          ? res.description
          : "Não foi possível carregar seus agendamentos";
    }

    feed.loading.value = false;
    feed.loadingMore.value = false;
  }
}
