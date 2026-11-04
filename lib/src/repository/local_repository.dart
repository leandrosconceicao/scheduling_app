import 'package:get_storage/get_storage.dart';
import 'package:scheduling_app/src/domain/domain.dart';

final class LocalRepository implements ILocalRepository {

  final GetStorage _storage = GetStorage();
  
  @override
  Future<void> write(String key, String value) async => await _storage.write(key, value);

  @override
  T? read<T>(String key) => _storage.read(key);

  @override
  Future<void> remove(String key) => _storage.remove(key);

  @override
  Future<void> erase() => _storage.erase();

  @override
  bool hasData(String key) => _storage.hasData(key);
}