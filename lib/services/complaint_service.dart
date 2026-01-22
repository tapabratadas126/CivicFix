import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:civicfix/models/complaint_model.dart';
import 'package:civicfix/models/location_model.dart';

class ComplaintService extends ChangeNotifier {
  static final ComplaintService _instance = ComplaintService._internal();
  factory ComplaintService() => _instance;
  ComplaintService._internal();

  List<ComplaintModel> _complaints = [];
  bool _isLoading = false;

  List<ComplaintModel> get complaints => _complaints;
  bool get isLoading => _isLoading;

  Future<void> loadComplaints() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final complaintsJson = prefs.getString('complaints') ?? '[]';
      final List<dynamic> complaintsList = jsonDecode(complaintsJson);
      _complaints = complaintsList.map((c) => ComplaintModel.fromJson(c)).toList();
      _complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('Failed to load complaints: $e');
      _complaints = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveComplaints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'complaints',
        jsonEncode(_complaints.map((c) => c.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Failed to save complaints: $e');
    }
  }

  Future<String?> createComplaint({
    required String userId,
    required String userName,
    required IssueType issueType,
    required String description,
    required LocationModel location,
    String? imagePath,
    required double aiConfidenceScore,
    required bool isAiValidated,
  }) async {
    try {
      final duplicateInfo = await _checkForDuplicates(location, issueType);
      
      if (duplicateInfo.isDuplicate) {
        await _mergeDuplicate(duplicateInfo.existingComplaintId!, userId);
        return duplicateInfo.existingComplaintId;
      }

      final priority = _calculatePriority(
        issueType: issueType,
        aiConfidenceScore: aiConfidenceScore,
        duplicateCount: 1,
      );

      final now = DateTime.now();
      final newComplaint = ComplaintModel(
        id: const Uuid().v4(),
        userId: userId,
        userName: userName,
        issueType: issueType,
        description: description,
        location: location,
        imagePath: imagePath,
        status: ComplaintStatus.submitted,
        priority: priority,
        statusHistory: [
          StatusUpdate(
            status: ComplaintStatus.submitted,
            timestamp: now,
            note: 'Complaint submitted',
          ),
        ],
        aiConfidenceScore: aiConfidenceScore,
        isAiValidated: isAiValidated,
        createdAt: now,
        updatedAt: now,
      );

      _complaints.insert(0, newComplaint);
      await _saveComplaints();
      notifyListeners();
      return newComplaint.id;
    } catch (e) {
      debugPrint('Failed to create complaint: $e');
      return null;
    }
  }

  Future<({bool isDuplicate, String? existingComplaintId})> _checkForDuplicates(
    LocationModel location,
    IssueType issueType,
  ) async {
    const double proximityThresholdKm = 0.05;

    for (final complaint in _complaints) {
      if (complaint.issueType == issueType &&
          complaint.status != ComplaintStatus.resolved &&
          complaint.status != ComplaintStatus.rejected) {
        final distance = location.distanceTo(complaint.location);
        if (distance < proximityThresholdKm) {
          return (isDuplicate: true, existingComplaintId: complaint.id);
        }
      }
    }
    return (isDuplicate: false, existingComplaintId: null);
  }

  Future<void> _mergeDuplicate(String complaintId, String reporterId) async {
    final index = _complaints.indexWhere((c) => c.id == complaintId);
    if (index != -1) {
      final existing = _complaints[index];
      final updatedComplaint = existing.copyWith(
        duplicateCount: existing.duplicateCount + 1,
        duplicateIds: [...existing.duplicateIds, reporterId],
        priority: _calculatePriority(
          issueType: existing.issueType,
          aiConfidenceScore: existing.aiConfidenceScore,
          duplicateCount: existing.duplicateCount + 1,
        ),
        updatedAt: DateTime.now(),
      );
      _complaints[index] = updatedComplaint;
      await _saveComplaints();
      notifyListeners();
    }
  }

  Priority _calculatePriority({
    required IssueType issueType,
    required double aiConfidenceScore,
    required int duplicateCount,
  }) {
    int score = 0;

    if (issueType == IssueType.openManhole || issueType == IssueType.waterlogging) {
      score += 3;
    } else if (issueType == IssueType.pothole) {
      score += 2;
    } else {
      score += 1;
    }

    if (aiConfidenceScore >= 0.8) score += 2;
    else if (aiConfidenceScore >= 0.6) score += 1;

    if (duplicateCount >= 5) score += 3;
    else if (duplicateCount >= 3) score += 2;
    else if (duplicateCount >= 2) score += 1;

    if (score >= 6) return Priority.critical;
    if (score >= 3) return Priority.medium;
    return Priority.low;
  }

  Future<void> updateComplaintStatus({
    required String complaintId,
    required ComplaintStatus newStatus,
    String? note,
    String? updatedBy,
    String? assignedTo,
    DateTime? expectedResolutionDate,
  }) async {
    final index = _complaints.indexWhere((c) => c.id == complaintId);
    if (index != -1) {
      final complaint = _complaints[index];
      final statusUpdate = StatusUpdate(
        status: newStatus,
        timestamp: DateTime.now(),
        note: note,
        updatedBy: updatedBy,
      );

      _complaints[index] = complaint.copyWith(
        status: newStatus,
        statusHistory: [...complaint.statusHistory, statusUpdate],
        assignedTo: assignedTo ?? complaint.assignedTo,
        expectedResolutionDate: expectedResolutionDate ?? complaint.expectedResolutionDate,
        updatedAt: DateTime.now(),
      );

      await _saveComplaints();
      notifyListeners();
    }
  }

  Future<void> resolveComplaint({
    required String complaintId,
    required String resolutionNote,
    String? resolutionImagePath,
    required String resolvedBy,
  }) async {
    final index = _complaints.indexWhere((c) => c.id == complaintId);
    if (index != -1) {
      final complaint = _complaints[index];
      final now = DateTime.now();
      
      _complaints[index] = complaint.copyWith(
        status: ComplaintStatus.resolved,
        resolutionNote: resolutionNote,
        resolutionImagePath: resolutionImagePath,
        actualResolutionDate: now,
        statusHistory: [
          ...complaint.statusHistory,
          StatusUpdate(
            status: ComplaintStatus.resolved,
            timestamp: now,
            note: resolutionNote,
            updatedBy: resolvedBy,
          ),
        ],
        updatedAt: now,
      );

      await _saveComplaints();
      notifyListeners();
    }
  }

  List<ComplaintModel> getComplaintsByUserId(String userId) =>
      _complaints.where((c) => c.userId == userId).toList();

  List<ComplaintModel> getComplaintsByStatus(ComplaintStatus status) =>
      _complaints.where((c) => c.status == status).toList();

  List<ComplaintModel> getComplaintsByPriority(Priority priority) =>
      _complaints.where((c) => c.priority == priority).toList();

  Map<String, int> getStatusCounts() {
    final counts = <String, int>{};
    for (final status in ComplaintStatus.values) {
      counts[status.name] = _complaints.where((c) => c.status == status).length;
    }
    return counts;
  }

  Map<String, int> getIssueTypeCounts() {
    final counts = <String, int>{};
    for (final type in IssueType.values) {
      counts[type.name] = _complaints.where((c) => c.issueType == type).length;
    }
    return counts;
  }

  double getAverageResolutionTime() {
    final resolved = _complaints.where(
      (c) => c.status == ComplaintStatus.resolved && c.actualResolutionDate != null,
    );
    
    if (resolved.isEmpty) return 0;
    
    final totalHours = resolved.fold<double>(
      0,
      (sum, c) => sum + c.actualResolutionDate!.difference(c.createdAt).inHours,
    );
    
    return totalHours / resolved.length;
  }
}
