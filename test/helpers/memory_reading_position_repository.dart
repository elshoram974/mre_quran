import 'package:mre_quran/features/mushaf/data/reading_position_repository.dart';

class MemoryReadingPositionRepository implements ReadingPositionRepository {
  int? page;

  @override
  Future<int?> loadPage() async => page;

  @override
  Future<void> savePage(int value) async {
    page = value;
  }
}
