import 'dart:math';
import 'package:civicfix/models/complaint_model.dart';

class AIValidationResult {
  final bool isValid;
  final double confidenceScore;
  final IssueType? detectedIssueType;
  final String message;

  AIValidationResult({
    required this.isValid,
    required this.confidenceScore,
    this.detectedIssueType,
    required this.message,
  });
}

class AIValidationService {
  static final AIValidationService _instance = AIValidationService._internal();
  factory AIValidationService() => _instance;
  AIValidationService._internal();

  final _random = Random();

  Future<AIValidationResult> validateImage({
    required String imagePath,
    required IssueType reportedIssueType,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    final isValid = _random.nextDouble() > 0.15;
    
    if (!isValid) {
      return AIValidationResult(
        isValid: false,
        confidenceScore: _random.nextDouble() * 0.4,
        message: 'Image quality too low or issue not clearly visible. Please upload a clearer image.',
      );
    }

    final detectedType = _mockDetectIssueType(reportedIssueType);
    final matchesReported = detectedType == reportedIssueType;
    final confidenceScore = matchesReported 
        ? 0.75 + (_random.nextDouble() * 0.2)
        : 0.5 + (_random.nextDouble() * 0.25);

    return AIValidationResult(
      isValid: true,
      confidenceScore: confidenceScore,
      detectedIssueType: detectedType,
      message: matchesReported
          ? 'Image validated successfully. ${_getIssueTypeConfidenceMessage(detectedType, confidenceScore)}'
          : 'Detected issue type (${_issueTypeToString(detectedType)}) differs from reported type. Please verify.',
    );
  }

  IssueType _mockDetectIssueType(IssueType reportedType) {
    final shouldMatch = _random.nextDouble() > 0.2;
    if (shouldMatch) {
      return reportedType;
    }
    
    final allTypes = IssueType.values.toList()..remove(reportedType);
    return allTypes[_random.nextInt(allTypes.length)];
  }

  String _getIssueTypeConfidenceMessage(IssueType type, double confidence) {
    final percentage = (confidence * 100).toStringAsFixed(0);
    return '$percentage% confidence in detecting ${_issueTypeToString(type)}.';
  }

  String _issueTypeToString(IssueType type) {
    switch (type) {
      case IssueType.pothole:
        return 'pothole';
      case IssueType.brokenStreetlight:
        return 'broken streetlight';
      case IssueType.waterlogging:
        return 'waterlogging';
      case IssueType.openManhole:
        return 'open manhole';
      case IssueType.garbageDump:
        return 'garbage dump';
      case IssueType.other:
        return 'other issue';
    }
  }

  Future<bool> validateImageQuality(String imagePath) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _random.nextDouble() > 0.1;
  }
}
