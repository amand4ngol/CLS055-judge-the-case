import 'package:flutter/foundation.dart';

import '../data/game_repository.dart';
import '../models.dart';

enum CaseScreenStatus { loading, warning, ready, error }

/// What the case screen hands back to the home screen when it closes.
class CaseExit {
  const CaseExit({this.result, this.hideSensitiveCases = false});

  /// Set when the player delivered a verdict.
  final RulingResult? result;

  /// The player ticked "Do not show me sensitive cases again". Saved by the
  /// home screen after leaving: saving it now would hide (and lock) the case
  /// the player is in.
  final bool hideSensitiveCases;
}

/// State of one case screen: the case, the player's ruling in progress and
/// the verdict they are building.
class CaseProvider extends ChangeNotifier {
  CaseProvider(this._repository, this.caseId);

  final GameRepository _repository;
  final String caseId;

  CaseScreenStatus _status = CaseScreenStatus.loading;
  Object? _error;
  CourtCase? _courtCase;
  PlayerRuling? _ruling;
  PlayerVerdict _verdict = PlayerVerdict.empty;
  bool _showLongSummary = false;
  bool _hideSensitiveCases = false;
  bool _isDelivering = false;
  RulingResult? _result;
  bool _disposed = false;

  CaseScreenStatus get status => _status;
  Object? get error => _error;

  /// Non-null once [status] is [CaseScreenStatus.warning] or [CaseScreenStatus.ready].
  CourtCase get courtCase => _courtCase!;
  PlayerVerdict get verdict => _verdict;
  bool get showLongSummary => _showLongSummary;
  bool get hideSensitiveCases => _hideSensitiveCases;
  bool get isDelivering => _isDelivering;

  int get argumentsRead => _ruling?.argumentsRead ?? 0;
  int get argumentsCount => courtCase.arguments.length;

  bool get canDeliver => _verdict.isComplete && !_isDelivering;

  CaseExit get exit =>
      CaseExit(result: _result, hideSensitiveCases: _hideSensitiveCases);

  /// Loads the case. Sensitive cases stop at the trigger warning; the
  /// ruling is only created once the player chooses to enter.
  Future<void> load() async {
    _status = CaseScreenStatus.loading;
    _error = null;
    _notify();

    try {
      final courtCase = await _repository.caseById(caseId);
      final player = await _repository.currentPlayer();
      _courtCase = courtCase;

      final preferences = player?.preferences ?? ContentPreferences.none;
      if (preferences.needsWarning(courtCase)) {
        _status = CaseScreenStatus.warning;
        _notify();
        return;
      }
      await _open();
    } catch (e) {
      _fail(e);
    }
  }

  /// "Enter anyways" on the trigger warning.
  Future<void> enterCase() async {
    _status = CaseScreenStatus.loading;
    _notify();
    try {
      await _open();
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _open() async {
    final ruling = await _repository.openCase(courtCase);
    _ruling = ruling;
    _verdict = ruling.verdict;
    _status = CaseScreenStatus.ready;
    _notify();
  }

  void setHideSensitiveCases(bool value) {
    _hideSensitiveCases = value;
    _notify();
  }

  void setShowLongSummary(bool value) {
    if (value == _showLongSummary) return;
    _showLongSummary = value;
    _notify();
  }

  /// Called when the argument carousel shows page [page]. Page 0 is the
  /// intro card, page n is argument n, so reaching it means n were read.
  void markArgumentsRead(int page) {
    final ruling = _ruling;
    if (ruling == null || page <= ruling.argumentsRead) return;
    _ruling = ruling.withProgress(argumentsRead: page);
    _notify();
    _saveProgress();
  }

  void toggleOption(VerdictOption option) {
    _verdict = _verdict.toggle(option);
    _notify();
    _saveProgress();
  }

  /// Slider moves: update the screen only, [saveDraft] runs when the drag
  /// ends so the repository is not written on every frame.
  void setFine(double eur) {
    _verdict = _verdict.withFine(eur);
    _notify();
  }

  void setPrison(double months) {
    _verdict = _verdict.withPrison(months);
    _notify();
  }

  void saveDraft() => _saveProgress();

  /// "Deliver Verdict". Returns the result, or null if it failed.
  Future<RulingResult?> deliver() async {
    if (!canDeliver) return null;
    _isDelivering = true;
    _notify();
    try {
      _result = await _repository.deliverVerdict(courtCase, _verdict);
      return _result;
    } catch (e) {
      _error = e;
      return null;
    } finally {
      _isDelivering = false;
      _notify();
    }
  }

  Future<void> _saveProgress() async {
    final ruling = _ruling;
    if (ruling == null) return;
    final updated = ruling.withProgress(verdict: _verdict);
    _ruling = updated;
    try {
      await _repository.saveProgress(updated);
    } catch (e) {
      // A lost draft only costs the player their place in the case, so it
      // must not break the screen.
      debugPrint('Could not save progress of $caseId: $e');
    }
  }

  void _fail(Object e) {
    _error = e;
    _status = CaseScreenStatus.error;
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
