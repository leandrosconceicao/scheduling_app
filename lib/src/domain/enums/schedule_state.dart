enum ScheduleState {
  open("open"),
  closed("closed"),
  scheduled("scheduled"),
  lock("lock");

  final String code;

  const ScheduleState(this.code);
}