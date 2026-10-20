import 'package:flutter/foundation.dart';

import '../data/game_repository.dart';
import '../models.dart';
import 'case_provider.dart';

enum HomeStatus { loading, ready, error }

/// State of the home screen: the player, their country, the category chips
/// and the case column of the selected category.
class HomeProvider extends ChangeNotifier {
  HomeProvider(this._repository);

  final GameRepository _repository;

  HomeStatus _status = HomeStatus.loading;
  Object? _error;
  PlayerProfile? _player;
  List<Country> _countries = const [];
  List<CaseCategory> _categories = const [];
  int _selectedCategoryIndex = 0;
  List<CaseSlot> _cases = const [];
  bool _isLoadingCases = false;

  /// Increases on every case request, so a slow answer for a category the
  /// player already swiped away from is ignored.
  int _casesRequestId = 0;
  bool _disposed = false;

  HomeStatus get status => _status;
  Object? get error => _error;
  PlayerProfile? get player => _player;

  /// Every country of the picker.
  List<Country> get countries => _countries;

  /// The country the player rules in (Netherlands for a new player).
  Country? get country {
    final code = _player?.countryCode;
    return _countries.where((c) => c.code == code).firstOrNull;
  }

  List<CaseCategory> get categories => _categories;
  int get selectedCategoryIndex => _selectedCategoryIndex;
  List<CaseSlot> get cases => _cases;
  bool get isLoadingCases => _isLoadingCases;

  CaseCategory? get selectedCategory =>
      _categories.isEmpty ? null : _categories[_selectedCategoryIndex];

  /// The case the player should play next, so the column opens on it.
  int get focusedCaseIndex {
    final index = _cases.indexWhere(
      (slot) =>
          slot.state == CaseSlotState.next ||
          slot.state == CaseSlotState.inProgress,
    );
    return index == -1 ? 0 : index;
  }

  /// Loads everything the screen shows. Also used by the retry button.
  Future<void> load() async {
    _status = HomeStatus.loading;
    _error = null;
    _notify();

    try {
      final player = await _repository.currentPlayer();
      if (player == null) throw StateError('No player is signed in');

      _player = player;
      _countries = await _repository.countries();
      await _loadCategories();
      _status = HomeStatus.ready;
    } catch (e) {
      _error = e;
      _status = HomeStatus.error;
    }
    _notify();
  }

  /// Country picker: the player now rules in [code], so every column changes.
  Future<void> selectCountry(String code) async {
    if (code == _player?.countryCode) return;

    _status = HomeStatus.loading;
    _notify();
    try {
      _player = await _repository.setCountry(code);
      await _loadCategories();
      _status = HomeStatus.ready;
    } catch (e) {
      _error = e;
      _status = HomeStatus.error;
    }
    _notify();
  }

  /// Categories of the player's country and the column of the first one.
  Future<void> _loadCategories() async {
    final countryCode = _player!.countryCode;
    final categories = await _repository.categories(countryCode);
    _categories = categories;
    _selectedCategoryIndex = 0;
    _cases = categories.isEmpty
        ? const []
        : await _repository.caseColumn(countryCode, categories.first);
  }

  Future<void> selectCategory(int index) async {
    if (index == _selectedCategoryIndex ||
        index < 0 ||
        index >= _categories.length) {
      return;
    }
    _selectedCategoryIndex = index;
    await refreshCases();
  }

  /// Called when the player comes back from a case: saves the trigger
  /// warning choice, then reloads the column (the case may now be completed
  /// or hidden).
  Future<void> afterCase(CaseExit? exit) async {
    final preferences = _player?.preferences;
    if (preferences != null && (exit?.hideSensitiveCases ?? false)) {
      await _savePreferences(preferences.copyWith(hideSensitiveCases: true));
    }
    await refreshCases();
  }

  /// The case to play next in the selected category, if any is left.
  CaseSlot? get nextCase => _cases
      .where(
        (s) =>
            s.state == CaseSlotState.next ||
            s.state == CaseSlotState.inProgress,
      )
      .firstOrNull;

  /// The court's verdict next to the player's, for a completed case.
  Future<RulingResult?> pastResult(String caseId) async {
    try {
      return await _repository.reviseCase(caseId);
    } catch (e) {
      debugPrint('Could not load the result of $caseId: $e');
      return null;
    }
  }

  /// Every case of the selected category is hidden by the player's content
  /// preferences. (Categories are only listed when they have published
  /// cases, so an empty column can only mean that.)
  bool get isCategoryHidden =>
      !_isLoadingCases && _categories.isNotEmpty && _cases.isEmpty;

  /// "Do not show me sensitive cases again" is on.
  bool get hidesSensitiveCases =>
      _player?.preferences.hideSensitiveCases ?? false;

  /// Turns "Do not show me sensitive cases again" back off.
  Future<void> showSensitiveCases() async {
    final preferences = _player?.preferences;
    if (preferences == null) return;
    await _savePreferences(preferences.copyWith(hideSensitiveCases: false));
    await refreshCases();
  }

  Future<void> _savePreferences(ContentPreferences preferences) async {
    try {
      _player = await _repository.savePreferences(preferences);
    } catch (e) {
      debugPrint('Could not save content preferences: $e');
    }
  }

  /// Reloads the column of the selected category, e.g. after a verdict.
  Future<void> refreshCases() async {
    final player = _player;
    final category = selectedCategory;
    if (player == null || category == null) return;

    final requestId = ++_casesRequestId;
    _isLoadingCases = true;
    _notify();

    try {
      final cases = await _repository.caseColumn(player.countryCode, category);
      if (requestId != _casesRequestId) return;
      _cases = cases;
    } catch (e) {
      if (requestId != _casesRequestId) return;
      _error = e;
      _status = HomeStatus.error;
    }
    _isLoadingCases = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
