import 'package:flutter/foundation.dart';
import '../models/filters.dart';

class FiltersProvider extends ChangeNotifier {
  Filters _filters = const Filters();
  Filters get filters => _filters;

  void setFilters(Filters f) {
    _filters = f;
    notifyListeners();
  }

  void updateSearch(String q) {
    _filters = _filters.copyWith(search: q);
    notifyListeners();
  }
}
