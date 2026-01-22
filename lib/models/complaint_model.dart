import 'package:civicfix/models/location_model.dart';
import 'package:civicfix/models/user_model.dart';

enum IssueType {
  pothole,
  brokenStreetlight,
  waterlogging,
  openManhole,
  garbageDump,
  other
}

enum ComplaintStatus {
  submitted,
  verified,
  assigned,
  inProgress,
  resolved,
  rejected
}

enum Priority { low, medium, critical }

class StatusUpdate {
  final ComplaintStatus status;
  final DateTime timestamp;
  final String? note;
  final String? updatedBy;

  StatusUpdate({
    required this.status,
    required this.timestamp,
    this.note,
    this.updatedBy,
  });

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'timestamp': timestamp.toIso8601String(),
        'note': note,
        'updatedBy': updatedBy,
      };

  factory StatusUpdate.fromJson(Map<String, dynamic> json) => StatusUpdate(
        status:
            ComplaintStatus.values.firstWhere((e) => e.name == json['status']),
        timestamp: DateTime.parse(json['timestamp']),
        note: json['note'],
        updatedBy: json['updatedBy'],
      );
}

class ComplaintModel {
  final String id;
  final String userId;
  final String userName;
  final IssueType issueType;
  final String description;
  final LocationModel location;
  final String? imagePath;
  final ComplaintStatus status;
  final Priority priority;
  final List<StatusUpdate> statusHistory;
  final double aiConfidenceScore;
  final bool isAiValidated;
  final int duplicateCount;
  final List<String> duplicateIds;
  final String? assignedTo;
  final String? resolutionNote;
  final String? resolutionImagePath;
  final DateTime? expectedResolutionDate;
  final DateTime? actualResolutionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  ComplaintModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.issueType,
    required this.description,
    required this.location,
    this.imagePath,
    required this.status,
    required this.priority,
    required this.statusHistory,
    this.aiConfidenceScore = 0.0,
    this.isAiValidated = false,
    this.duplicateCount = 1,
    this.duplicateIds = const [],
    this.assignedTo,
    this.resolutionNote,
    this.resolutionImagePath,
    this.expectedResolutionDate,
    this.actualResolutionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'issueType': issueType.name,
        'description': description,
        'location': location.toJson(),
        'imagePath': imagePath,
        'status': status.name,
        'priority': priority.name,
        'statusHistory': statusHistory.map((s) => s.toJson()).toList(),
        'aiConfidenceScore': aiConfidenceScore,
        'isAiValidated': isAiValidated,
        'duplicateCount': duplicateCount,
        'duplicateIds': duplicateIds,
        'assignedTo': assignedTo,
        'resolutionNote': resolutionNote,
        'resolutionImagePath': resolutionImagePath,
        'expectedResolutionDate': expectedResolutionDate?.toIso8601String(),
        'actualResolutionDate': actualResolutionDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ComplaintModel.fromJson(Map<String, dynamic> json) => ComplaintModel(
        id: json['id'],
        userId: json['userId'],
        userName: json['userName'],
        issueType:
            IssueType.values.firstWhere((e) => e.name == json['issueType']),
        description: json['description'],
        location: LocationModel.fromJson(json['location']),
        imagePath: json['imagePath'],
        status: ComplaintStatus.values
            .firstWhere((e) => e.name == json['status']),
        priority: Priority.values.firstWhere((e) => e.name == json['priority']),
        statusHistory: (json['statusHistory'] as List)
            .map((s) => StatusUpdate.fromJson(s))
            .toList(),
        aiConfidenceScore: json['aiConfidenceScore'] ?? 0.0,
        isAiValidated: json['isAiValidated'] ?? false,
        duplicateCount: json['duplicateCount'] ?? 1,
        duplicateIds: List<String>.from(json['duplicateIds'] ?? []),
        assignedTo: json['assignedTo'],
        resolutionNote: json['resolutionNote'],
        resolutionImagePath: json['resolutionImagePath'],
        expectedResolutionDate: json['expectedResolutionDate'] != null
            ? DateTime.parse(json['expectedResolutionDate'])
            : null,
        actualResolutionDate: json['actualResolutionDate'] != null
            ? DateTime.parse(json['actualResolutionDate'])
            : null,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );

  ComplaintModel copyWith({
    String? id,
    String? userId,
    String? userName,
    IssueType? issueType,
    String? description,
    LocationModel? location,
    String? imagePath,
    ComplaintStatus? status,
    Priority? priority,
    List<StatusUpdate>? statusHistory,
    double? aiConfidenceScore,
    bool? isAiValidated,
    int? duplicateCount,
    List<String>? duplicateIds,
    String? assignedTo,
    String? resolutionNote,
    String? resolutionImagePath,
    DateTime? expectedResolutionDate,
    DateTime? actualResolutionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      ComplaintModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        issueType: issueType ?? this.issueType,
        description: description ?? this.description,
        location: location ?? this.location,
        imagePath: imagePath ?? this.imagePath,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        statusHistory: statusHistory ?? this.statusHistory,
        aiConfidenceScore: aiConfidenceScore ?? this.aiConfidenceScore,
        isAiValidated: isAiValidated ?? this.isAiValidated,
        duplicateCount: duplicateCount ?? this.duplicateCount,
        duplicateIds: duplicateIds ?? this.duplicateIds,
        assignedTo: assignedTo ?? this.assignedTo,
        resolutionNote: resolutionNote ?? this.resolutionNote,
        resolutionImagePath: resolutionImagePath ?? this.resolutionImagePath,
        expectedResolutionDate:
            expectedResolutionDate ?? this.expectedResolutionDate,
        actualResolutionDate:
            actualResolutionDate ?? this.actualResolutionDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  String get issueTypeDisplay {
    switch (issueType) {
      case IssueType.pothole:
        return 'Pothole';
      case IssueType.brokenStreetlight:
        return 'Broken Streetlight';
      case IssueType.waterlogging:
        return 'Waterlogging';
      case IssueType.openManhole:
        return 'Open Manhole';
      case IssueType.garbageDump:
        return 'Garbage Dump';
      case IssueType.other:
        return 'Other';
    }
  }

  String get statusDisplay {
    switch (status) {
      case ComplaintStatus.submitted:
        return 'Submitted';
      case ComplaintStatus.verified:
        return 'Verified';
      case ComplaintStatus.assigned:
        return 'Assigned';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.rejected:
        return 'Rejected';
    }
  }
}
