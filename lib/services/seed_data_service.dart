import 'package:civicfix/services/complaint_service.dart';
import 'package:civicfix/services/location_service.dart';
import 'package:civicfix/services/auth_service.dart';
import 'package:civicfix/models/complaint_model.dart';
import 'package:civicfix/models/user_model.dart';
import 'package:uuid/uuid.dart';

class SeedDataService {
  static Future<void> seedSampleComplaints() async {
    final complaintService = ComplaintService();
    final authService = AuthService();
    
    if (complaintService.complaints.isNotEmpty) return;

    final johnUser = (await _getJohnUser(authService));
    if (johnUser == null) return;

    final sampleComplaints = [
      {
        'issueType': IssueType.pothole,
        'description': 'Large pothole on main road causing traffic issues. Multiple vehicles damaged.',
        'city': 'Downtown',
        'status': ComplaintStatus.inProgress,
        'priority': Priority.critical,
        'aiScore': 0.92,
        'duplicates': 5,
        'daysAgo': 7,
      },
      {
        'issueType': IssueType.brokenStreetlight,
        'description': 'Streetlight not working for past week. Safety concern for pedestrians.',
        'city': 'Midtown',
        'status': ComplaintStatus.verified,
        'priority': Priority.medium,
        'aiScore': 0.88,
        'duplicates': 2,
        'daysAgo': 3,
      },
      {
        'issueType': IssueType.waterlogging,
        'description': 'Severe waterlogging after rain. Area becomes completely flooded.',
        'city': 'Brooklyn',
        'status': ComplaintStatus.submitted,
        'priority': Priority.critical,
        'aiScore': 0.95,
        'duplicates': 8,
        'daysAgo': 1,
      },
      {
        'issueType': IssueType.openManhole,
        'description': 'Open manhole without cover. Immediate safety hazard.',
        'city': 'Queens',
        'status': ComplaintStatus.assigned,
        'priority': Priority.critical,
        'aiScore': 0.97,
        'duplicates': 3,
        'daysAgo': 2,
      },
      {
        'issueType': IssueType.garbageDump,
        'description': 'Illegal garbage dumping near residential area. Health hazard.',
        'city': 'Downtown',
        'status': ComplaintStatus.resolved,
        'priority': Priority.medium,
        'aiScore': 0.85,
        'duplicates': 1,
        'daysAgo': 14,
      },
      {
        'issueType': IssueType.pothole,
        'description': 'Small pothole forming on residential street. Needs early attention.',
        'city': 'Midtown',
        'status': ComplaintStatus.submitted,
        'priority': Priority.low,
        'aiScore': 0.78,
        'duplicates': 1,
        'daysAgo': 5,
      },
    ];

    for (final data in sampleComplaints) {
      final location = LocationService().getMockLocation(data['city'] as String);
      final createdAt = DateTime.now().subtract(Duration(days: data['daysAgo'] as int));
      
      final statusHistory = <StatusUpdate>[
        StatusUpdate(
          status: ComplaintStatus.submitted,
          timestamp: createdAt,
          note: 'Complaint submitted',
        ),
      ];

      if ((data['status'] as ComplaintStatus).index >= ComplaintStatus.verified.index) {
        statusHistory.add(StatusUpdate(
          status: ComplaintStatus.verified,
          timestamp: createdAt.add(const Duration(hours: 2)),
          note: 'Verified by municipal authority',
          updatedBy: 'Admin',
        ));
      }

      if ((data['status'] as ComplaintStatus).index >= ComplaintStatus.assigned.index) {
        statusHistory.add(StatusUpdate(
          status: ComplaintStatus.assigned,
          timestamp: createdAt.add(const Duration(hours: 6)),
          note: 'Assigned to maintenance team',
          updatedBy: 'Admin',
        ));
      }

      if ((data['status'] as ComplaintStatus).index >= ComplaintStatus.inProgress.index) {
        statusHistory.add(StatusUpdate(
          status: ComplaintStatus.inProgress,
          timestamp: createdAt.add(const Duration(days: 1)),
          note: 'Work started on site',
          updatedBy: 'Admin',
        ));
      }

      if (data['status'] == ComplaintStatus.resolved) {
        statusHistory.add(StatusUpdate(
          status: ComplaintStatus.resolved,
          timestamp: createdAt.add(const Duration(days: 7)),
          note: 'Issue successfully resolved',
          updatedBy: 'Admin',
        ));
      }

      final complaint = ComplaintModel(
        id: const Uuid().v4(),
        userId: johnUser.id,
        userName: johnUser.name,
        issueType: data['issueType'] as IssueType,
        description: data['description'] as String,
        location: location,
        status: data['status'] as ComplaintStatus,
        priority: data['priority'] as Priority,
        statusHistory: statusHistory,
        aiConfidenceScore: data['aiScore'] as double,
        isAiValidated: true,
        duplicateCount: data['duplicates'] as int,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

      complaintService.complaints.add(complaint);
    }

    await complaintService.loadComplaints();
  }

  static Future<UserModel?> _getJohnUser(AuthService authService) async {
    try {
      await authService.initialize();
      
      final users = authService;
      return authService.currentUser;
    } catch (e) {
      return null;
    }
  }
}
