import 'package:flutter_test/flutter_test.dart';
import 'package:ranger/providers/filters_provider.dart';
import 'package:ranger/models/enums.dart';

void main() {
  test('filters update', () {
    final p = FiltersProvider();
    expect(p.filters.search, '');
    p.updateSearch('run');
    expect(p.filters.search, 'run');
    final f = p.filters.copyWith(category: RoutineCategory.work);
    p.setFilters(f);
    expect(p.filters.category, RoutineCategory.work);
  });
}
