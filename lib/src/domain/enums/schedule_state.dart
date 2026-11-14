enum ScheduleState {
  open("open"),
  closed("closed"),
  scheduled("scheduled"),
  lock("lock"),

  /// Atendimento realizado.
  completed("completed"),

  /// Agendamento cancelado (pelo cliente ou pela empresa).
  canceled("canceled");

  final String code;

  const ScheduleState(this.code);

  /// Estado desconhecido da API cai em [open], como antes.
  static ScheduleState parse(Object? code) {
    for (final state in values) {
      if (state.code == code) return state;
    }
    return open;
  }
}
