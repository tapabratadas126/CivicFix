import 'package:civicfix/models/user_model.dart';
import 'package:civicfix/services/auth_service.dart';

class GamificationBadge {
  final String name;
  final String description;
  final String emoji;
  final int requiredPoints;

  GamificationBadge({
    required this.name,
    required this.description,
    required this.emoji,
    required this.requiredPoints,
  });
}

class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  final List<GamificationBadge> _availableBadges = [
    GamificationBadge(
      name: 'Active Citizen',
      description: 'Report your first issue',
      emoji: '🌟',
      requiredPoints: 10,
    ),
    GamificationBadge(
      name: 'City Guardian',
      description: 'Report 5 valid issues',
      emoji: '🛡️',
      requiredPoints: 50,
    ),
    GamificationBadge(
      name: 'Civic Hero',
      description: 'Report 10+ valid issues',
      emoji: '🏆',
      requiredPoints: 100,
    ),
    GamificationBadge(
      name: 'Eagle Eye',
      description: 'Report issues with high AI confidence',
      emoji: '👁️',
      requiredPoints: 75,
    ),
    GamificationBadge(
      name: 'Neighborhood Champion',
      description: 'Actively improve your area',
      emoji: '🏘️',
      requiredPoints: 150,
    ),
  ];

  List<GamificationBadge> get availableBadges => _availableBadges;

  Future<void> awardPointsForComplaint({
    required bool isValidated,
    required double aiConfidenceScore,
  }) async {
    final authService = AuthService();
    final currentUser = authService.currentUser;
    
    if (currentUser == null || currentUser.role != UserRole.citizen) return;

    int points = 10;
    
    if (isValidated) {
      points += 5;
    }
    
    if (aiConfidenceScore >= 0.9) {
      points += 10;
    } else if (aiConfidenceScore >= 0.75) {
      points += 5;
    }

    final newPoints = currentUser.gamificationPoints + points;
    final newBadges = _checkForNewBadges(currentUser.badges, newPoints);

    final updatedUser = currentUser.copyWith(
      gamificationPoints: newPoints,
      badges: newBadges,
      updatedAt: DateTime.now(),
    );

    await authService.updateUser(updatedUser);
  }

  List<String> _checkForNewBadges(List<String> currentBadges, int points) {
    final earnedBadges = currentBadges.toList();
    
    for (final badge in _availableBadges) {
      if (points >= badge.requiredPoints && !earnedBadges.contains(badge.name)) {
        earnedBadges.add(badge.name);
      }
    }
    
    return earnedBadges;
  }

  List<GamificationBadge> getUserBadges(List<String> badgeNames) =>
      _availableBadges.where((b) => badgeNames.contains(b.name)).toList();

  int getRankPosition(int userPoints, List<UserModel> allUsers) {
    final sortedUsers = allUsers
        .where((u) => u.role == UserRole.citizen)
        .toList()
      ..sort((a, b) => b.gamificationPoints.compareTo(a.gamificationPoints));
    
    return sortedUsers.indexWhere((u) => u.gamificationPoints == userPoints) + 1;
  }
}
