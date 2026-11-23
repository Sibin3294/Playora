import 'package:flutter/foundation.dart';
import 'package:guess_game/game/hunt_level.dart';

class PlayerProgress extends ChangeNotifier {
  PlayerProgress({
    this.totalPoints = 0,
    int selectedLevelId = 1,
    bool campaignCleared = false,
  })  : _selectedLevelId = selectedLevelId,
        _campaignCleared = campaignCleared;

  static final PlayerProgress instance = PlayerProgress();

  static const int campaignBonus = 250;

  int totalPoints;
  int _selectedLevelId;
  bool _campaignCleared;

  bool get campaignCleared => _campaignCleared;

  int get selectedLevelId => _selectedLevelId;

  HuntLevel get selectedLevel => HuntLevel.byId(_selectedLevelId);

  bool isUnlocked(HuntLevel level) => totalPoints >= level.pointsToUnlock;

  HuntLevel? get nextLevel => selectedLevel.next;

  bool get canAdvance {
    final upcoming = nextLevel;
    return upcoming != null && isUnlocked(upcoming);
  }

  HuntLevel? get nextLocked {
    for (final level in HuntLevel.all) {
      if (!isUnlocked(level)) return level;
    }
    return null;
  }

  int get pointsToNext {
    final locked = nextLocked;
    if (locked == null) return 0;
    return (locked.pointsToUnlock - totalPoints)
        .clamp(0, locked.pointsToUnlock);
  }

  double get nextLevelProgress {
    final locked = nextLocked;
    if (locked == null) return 1;
    final previous = HuntLevel.all.lastWhere(
      (level) => level.pointsToUnlock < locked.pointsToUnlock,
      orElse: () => HuntLevel.scout,
    );
    final span = locked.pointsToUnlock - previous.pointsToUnlock;
    if (span <= 0) return 1;
    return ((totalPoints - previous.pointsToUnlock) / span).clamp(0, 1);
  }

  void applyRemote({
    required int totalPoints,
    required int selectedLevelId,
    required bool campaignCleared,
  }) {
    this.totalPoints = totalPoints;
    _selectedLevelId = selectedLevelId;
    _campaignCleared = campaignCleared;
    notifyListeners();
  }

  bool select(HuntLevel level) {
    if (!isUnlocked(level)) return false;
    _selectedLevelId = level.id;
    notifyListeners();
    return true;
  }

  bool markCampaignCleared() {
    if (_campaignCleared) return false;
    _campaignCleared = true;
    notifyListeners();
    return true;
  }

  List<HuntLevel> award(int points) {
    if (points <= 0) return const [];
    final before = totalPoints;
    totalPoints += points;
    final unlocked = HuntLevel.all
        .where(
          (level) =>
              before < level.pointsToUnlock &&
              totalPoints >= level.pointsToUnlock,
        )
        .toList();
    notifyListeners();
    return unlocked;
  }

  void reset() {
    totalPoints = 0;
    _selectedLevelId = HuntLevel.scout.id;
    _campaignCleared = false;
    notifyListeners();
  }
}
