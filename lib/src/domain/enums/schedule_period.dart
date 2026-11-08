/// Período da consulta dos agendamentos do cliente (`period` da API).
enum SchedulePeriod {
  /// A partir de agora, do mais próximo ao mais distante.
  upcoming("upcoming"),

  /// Já iniciados, do mais recente ao mais antigo.
  past("past"),
  all("all");

  final String code;

  const SchedulePeriod(this.code);
}
