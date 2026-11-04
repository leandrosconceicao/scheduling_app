/// Navegação disparada pela lógica de negócio (controllers), sem depender do
/// roteador. Widgets devem navegar direto pelo `GoRouter.of(context)`.
abstract interface class INavigationService {
  void toSchedule(String companyId);

  /// Abre o login do cliente e retorna `true` quando ele foi concluído.
  Future<bool> requestLogin(String companyId);
}
