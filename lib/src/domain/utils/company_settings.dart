import '../entities/company.dart';

/// Seções da tela de configurações da empresa.
enum ConfigSection {
  dados("Dados da empresa"),
  funcionamento("Funcionamento"),
  endereco("Endereço"),
  contato("Contato e redes");

  final String title;

  const ConfigSection(this.title);

  /// Campos de texto editados na seção.
  List<String> get keys => switch (this) {
    dados => const [CompanySettings.name],
    funcionamento => const [
      CompanySettings.open,
      CompanySettings.close,
      CompanySettings.lunchStart,
      CompanySettings.lunchEnd,
      CompanySettings.period,
      CompanySettings.lock,
    ],
    endereco => const [
      CompanySettings.zip,
      CompanySettings.street,
      CompanySettings.number,
      CompanySettings.complement,
      CompanySettings.neighborhood,
      CompanySettings.city,
      CompanySettings.state,
    ],
    contato => const [
      CompanySettings.phone,
      CompanySettings.whatsapp,
      CompanySettings.email,
      CompanySettings.instagram,
      CompanySettings.facebook,
    ],
  };
}

/// Regras de rascunho, máscara e validação da edição da empresa.
///
/// O rascunho é um mapa `campo -> texto`, como digitado; o envio à API
/// converte (telefones só com dígitos, por exemplo).
abstract final class CompanySettings {
  static const name = "name";
  static const open = "open";
  static const close = "close";
  static const lunchStart = "lunchStart";
  static const lunchEnd = "lunchEnd";
  static const period = "period";
  static const lock = "lock";
  static const zip = "zip";
  static const street = "street";
  static const number = "number";
  static const complement = "complement";
  static const neighborhood = "neighborhood";
  static const city = "city";
  static const state = "state";
  static const phone = "phone";
  static const whatsapp = "whatsapp";
  static const email = "email";
  static const instagram = "instagram";
  static const facebook = "facebook";

  /// Chave dos erros que não pertencem a um campo de texto.
  static const days = "days";

  static const _periods = [15, 30, 45, 60];

  /// Durações oferecidas, incluindo a atual mesmo que fora do padrão.
  static List<int> periodOptions(int current) =>
      {..._periods, if (current > 0) current}.toList()..sort();

  /// Rascunho da [section] a partir dos dados salvos da empresa.
  static Map<String, String> draftOf(Company company, ConfigSection section) {
    final config = company.configuration;
    final address = company.address;
    final social = company.social;

    final all = <String, String>{
      name: company.name,
      open: _hhmm(config.openingHours),
      close: _hhmm(config.closingTime),
      lunchStart: _hhmm(config.lunchBreak.start),
      lunchEnd: _hhmm(config.lunchBreak.end),
      period: "${config.defaultPeriodInMinutes}",
      lock: config.lockSchedulePeriodInMinutes > 0
          ? "${config.lockSchedulePeriodInMinutes}"
          : "",
      zip: maskZip(address.zipCode),
      street: address.street,
      number: address.number,
      complement: address.complement,
      neighborhood: address.neighborhood,
      city: address.city,
      state: address.state,
      phone: maskPhone(social.phone),
      whatsapp: maskPhone(social.whatsapp),
      email: social.email,
      instagram: social.instagram.replaceFirst(RegExp(r"^@"), ""),
      facebook: social.facebook,
    };

    return {for (final key in section.keys) key: all[key] ?? ""};
  }

  /// Erros por campo (vazio = válido). [workingDays] só vale em Funcionamento.
  static Map<String, String> errors(
    ConfigSection section,
    Map<String, String> d, {
    Set<int> workingDays = const {},
  }) {
    final out = <String, String>{};
    String value(String key) => (d[key] ?? "").trim();
    void required(String key, String message) {
      if (value(key).isEmpty) out[key] = message;
    }

    switch (section) {
      case ConfigSection.dados:
        required(name, "Informe o nome da empresa");
      case ConfigSection.funcionamento:
        for (final key in [open, close, lunchStart, lunchEnd]) {
          required(key, "Informe o horário");
        }
        final o = value(open), c = value(close);
        final ls = value(lunchStart), le = value(lunchEnd);
        if (!out.containsKey(close) &&
            !out.containsKey(open) &&
            c.compareTo(o) <= 0) {
          out[close] = "O fechamento deve ser depois da abertura";
        }
        if (!out.containsKey(lunchStart) &&
            !out.containsKey(open) &&
            ls.compareTo(o) < 0) {
          out[lunchStart] = "Deve começar depois da abertura";
        }
        if (!out.containsKey(lunchEnd) &&
            !out.containsKey(lunchStart) &&
            le.compareTo(ls) <= 0) {
          out[lunchEnd] = "Deve terminar depois do início";
        }
        if (!out.containsKey(lunchEnd) &&
            !out.containsKey(close) &&
            le.compareTo(c) > 0) {
          out[lunchEnd] = "Deve terminar antes do fechamento";
        }
        if (!((int.tryParse(value(lock)) ?? 0) > 0)) {
          out[lock] = "Informe um valor maior que zero";
        }
        if (workingDays.isEmpty) {
          out[days] = "Selecione ao menos um dia de funcionamento";
        }
      case ConfigSection.endereco:
        if (digits(value(zip), 8).length != 8) {
          out[zip] = "Informe os 8 dígitos do CEP";
        }
        required(street, "Informe a rua");
        required(number, "Informe o número");
        required(neighborhood, "Informe o bairro");
        required(city, "Informe a cidade");
        if (value(state).length != 2) out[state] = "Use a sigla";
      case ConfigSection.contato:
        for (final key in [phone, whatsapp]) {
          final size = digits(value(key), 11).length;
          if (size > 0 && size < 10) out[key] = "Número incompleto";
        }
        if (value(email).isNotEmpty &&
            !RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$").hasMatch(value(email))) {
          out[email] = "E-mail inválido";
        }
        if (RegExp(r"\s").hasMatch(value(instagram))) {
          out[instagram] = "Não use espaços";
        }
    }
    return out;
  }

  /// "Com essa configuração, são até N horários por dia." ou `null` enquanto
  /// os horários estiverem incompletos ou inconsistentes.
  static String? slotsLabel(Map<String, String> d) {
    final errs = errors(ConfigSection.funcionamento, d, workingDays: const {0});
    if ([open, close, lunchStart, lunchEnd].any(errs.containsKey)) return null;

    final p = int.tryParse(d[period] ?? "") ?? 0;
    if (p <= 0) return null;

    final before = _minutes(d[lunchStart]!) - _minutes(d[open]!);
    final after = _minutes(d[close]!) - _minutes(d[lunchEnd]!);
    return "Com essa configuração, são até ${before ~/ p + after ~/ p} "
        "horários por dia.";
  }

  static int _minutes(String time) {
    final parts = time.split(":");
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// "08:00:00" -> "08:00".
  static String _hhmm(String value) =>
      value.length >= 5 ? value.substring(0, 5) : value;

  static String digits(String text, int max) {
    final only = text.replaceAll(RegExp(r"\D"), "");
    return only.length > max ? only.substring(0, max) : only;
  }

  static String maskZip(String text) {
    final d = digits(text, 8);
    return d.length > 5 ? "${d.substring(0, 5)}-${d.substring(5)}" : d;
  }

  static String maskPhone(String text) {
    final d = digits(text, 11);
    if (d.length <= 2) return d;
    final tail = d.substring(2);
    final split = d.length == 11 ? 5 : 4;
    if (tail.length <= split) return "(${d.substring(0, 2)}) $tail";
    return "(${d.substring(0, 2)}) ${tail.substring(0, split)}-"
        "${tail.substring(split)}";
  }
}
