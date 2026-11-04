abstract interface class ILocalRepository {
  Future<void> write(String key, String value);

  Future<void> remove(String key);

  T? read<T>(String key);

  Future<void> erase();

  bool hasData(String key);
}