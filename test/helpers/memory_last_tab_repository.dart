import 'package:mre_quran/features/startup/data/last_tab_repository.dart';

class MemoryLastTabRepository implements LastTabRepository {
  String? path;

  @override
  Future<String?> load() async => path;

  @override
  Future<void> save(String value) async {
    path = value;
  }
}
