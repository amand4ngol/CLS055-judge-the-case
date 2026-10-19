import '../models.dart';
import 'fake_data.dart';
import 'game_repository.dart';

/// In-memory [GameRepository] on [FakeData], for building the screens before
/// the backend is ready. Data goes through the same `fromFirestore` /
/// `toMap` code as the real app, and through the same game rules
/// ([RulingResult.evaluate]). Nothing is persisted between launches.
class FakeGameRepository implements GameRepository {
  FakeGameRepository({PlayerProfile? player, this.latency = const Duration(milliseconds: 150)})
      : _player = player {
    _cases.addAll(FakeData.cases);
    _verdicts.addAll(FakeData.verdicts);
    _countries.addAll(FakeData.countries);
  }

  /// A player who already completed two cases (one right, one wrong) and has
  /// one in progress, to fill the profile and the CONTINUE state.
  static Future<FakeGameRepository> withHistory({Duration latency = Duration.zero}) async {
    final repo = FakeGameRepository(player: FakeData.newPlayer, latency: latency);
    await repo.deliverVerdict(
      await repo.caseById(FakeData.redLightId),
      const PlayerVerdict(options: {VerdictOption.prison}, prisonMonths: 12),
    );
    await repo.deliverVerdict(
      await repo.caseById(FakeData.shoplifterId),
      const PlayerVerdict(options: {VerdictOption.caseDismissed}),
    );
    final opened = await repo.openCase(await repo.caseById(FakeData.healingWeekendId));
    await repo.saveProgress(opened.withProgress(argumentsRead: 3));
    return repo;
  }

  /// Simulated network delay, so loading states show up.
  final Duration latency;

  final _cases = <String, Map<String, dynamic>>{};
  final _verdicts = <String, Map<String, dynamic>>{};
  final _countries = <String, Map<String, dynamic>>{};
  final _rulings = <String, Map<String, dynamic>>{};
  PlayerProfile? _player;

  Future<void> _wait() => latency == Duration.zero ? Future.value() : Future.delayed(latency);

  PlayerProfile get _requirePlayer => _player ?? (throw StateError('No player: call createPlayer first'));

  Iterable<CourtCase> _published(String country) => _cases.entries
      .map((e) => CourtCase.fromFirestore(e.key, e.value))
      .where((c) => c.status == CaseStatus.published && c.country == country);

  Map<String, PlayerRuling> get _rulingMap =>
      {for (final e in _rulings.entries) e.key: PlayerRuling.fromFirestore(e.key, e.value)};

  @override
  Future<PlayerProfile?> currentPlayer() async {
    await _wait();
    return _player;
  }

  @override
  Future<PlayerProfile> createPlayer({
    required String name,
    required String username,
    required String countryCode,
  }) async {
    await _wait();
    return _player = PlayerProfile(
      uid: 'fake-${username.toLowerCase()}',
      name: name,
      username: username,
      countryCode: countryCode,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<Country>> countries() async {
    await _wait();
    return [for (final e in _countries.entries) Country.fromFirestore(e.key, e.value)];
  }

  @override
  Future<PlayerProfile> setCountry(String countryCode) async {
    await _wait();
    return _player = _requirePlayer.copyWith(countryCode: countryCode);
  }

  @override
  Future<PlayerProfile> savePreferences(ContentPreferences preferences) async {
    await _wait();
    return _player = _requirePlayer.copyWith(preferences: preferences);
  }

  @override
  Future<List<CaseCategory>> categories(String countryCode) async {
    await _wait();
    final used = _published(countryCode).map((c) => c.category).toSet();
    return CaseCategory.values.where(used.contains).toList();
  }

  @override
  Future<List<CaseSlot>> caseColumn(String countryCode, CaseCategory category) async {
    await _wait();
    return CaseSlot.column(
      _published(countryCode).where((c) => c.category == category),
      _rulingMap,
      _requirePlayer.preferences,
    );
  }

  @override
  Future<CourtCase> caseById(String caseId) async {
    await _wait();
    final map = _cases[caseId];
    if (map == null) throw StateError('Unknown case $caseId');
    return CourtCase.fromFirestore(caseId, map);
  }

  @override
  Future<PlayerRuling> openCase(CourtCase courtCase) async {
    await _wait();
    final existing = _rulings[courtCase.id];
    if (existing != null) return PlayerRuling.fromFirestore(courtCase.id, existing);
    final ruling = PlayerRuling.start(courtCase);
    _rulings[courtCase.id] = ruling.toMap();
    return ruling;
  }

  @override
  Future<PlayerRuling> saveProgress(PlayerRuling ruling) async {
    await _wait();
    if (ruling.isCompleted) return ruling;
    _rulings[ruling.caseId] = ruling.toMap();
    return ruling;
  }

  @override
  Future<RulingResult> deliverVerdict(CourtCase courtCase, PlayerVerdict verdict) async {
    if (!verdict.isComplete) throw ArgumentError('Verdict is incomplete');
    await _wait();
    final ruling = _rulings.containsKey(courtCase.id)
        ? PlayerRuling.fromFirestore(courtCase.id, _rulings[courtCase.id]!)
        : PlayerRuling.start(courtCase);
    final result = RulingResult.evaluate(
      profile: _requirePlayer,
      courtCase: courtCase,
      ruling: ruling,
      verdict: verdict,
      courtVerdict: CaseVerdict.fromFirestore(courtCase.id, _verdicts[courtCase.id]!),
    );
    _rulings[courtCase.id] = result.ruling.toMap();
    _player = result.profile;
    return result;
  }

  @override
  Future<List<PlayerRuling>> completedRulings({int? limit}) async {
    await _wait();
    final done = _rulingMap.values.where((r) => r.isCompleted).toList()
      ..sort((a, b) => (b.submittedAt ?? DateTime(0)).compareTo(a.submittedAt ?? DateTime(0)));
    return limit == null ? done : done.take(limit).toList();
  }

  @override
  Future<RulingResult> reviseCase(String caseId) async {
    final ruling = _rulingMap[caseId];
    if (ruling == null || !ruling.isCompleted) {
      throw StateError('Case $caseId is not completed: its verdict stays hidden');
    }
    final courtCase = await caseById(caseId);
    return RulingResult.evaluate(
      profile: _requirePlayer,
      courtCase: courtCase,
      ruling: ruling,
      verdict: ruling.verdict,
      courtVerdict: CaseVerdict.fromFirestore(caseId, _verdicts[caseId]!),
    );
  }
}
