import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:civicfix/services/auth_service.dart';
import 'package:civicfix/services/complaint_service.dart';
import 'package:civicfix/services/location_service.dart';
import 'package:civicfix/services/ai_validation_service.dart';
import 'package:civicfix/services/gamification_service.dart';
import 'package:civicfix/models/complaint_model.dart';
import 'package:civicfix/models/location_model.dart';
import 'package:civicfix/theme.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _picker = ImagePicker();
  
  IssueType _selectedIssueType = IssueType.pothole;
  XFile? _selectedImage;
  LocationModel? _location;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  bool _useManualLocation = false;
  bool _useManualAddress = false;
  String _selectedCity = 'Downtown';

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source, maxWidth: 1920, maxHeight: 1080);
      if (image != null) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final location = await LocationService().getCurrentLocation();
      if (location != null) {
        setState(() {
          _location = location;
          _useManualLocation = false;
          _useManualAddress = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to get location. Using manual selection.')),
          );
          setState(() => _useManualLocation = true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _selectManualLocation(String city) {
    setState(() {
      _selectedCity = city;
      _location = LocationService().getMockLocation(city);
      _useManualLocation = true;
      _useManualAddress = false;
    });
  }

  void _setManualAddress() {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an address')),
      );
      return;
    }

    setState(() {
      _location = LocationModel(
        latitude: 40.7128,
        longitude: -74.0060,
        address: _addressController.text.trim(),
        landmark: null,
      );
      _useManualAddress = true;
      _useManualLocation = false;
    });
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image')),
      );
      return;
    }

    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final aiResult = await AIValidationService().validateImage(
        imagePath: _selectedImage!.path,
        reportedIssueType: _selectedIssueType,
      );

      if (!aiResult.isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(aiResult.message)),
          );
          setState(() => _isSubmitting = false);
          return;
        }
      }

      final authService = AuthService();
      final user = authService.currentUser;

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to report issues')),
          );
          setState(() => _isSubmitting = false);
        }
        return;
      }

      final complaintId = await ComplaintService().createComplaint(
        userId: user.id,
        userName: user.name,
        issueType: _selectedIssueType,
        description: _descriptionController.text.trim(),
        location: _location!,
        imagePath: _selectedImage!.path,
        aiConfidenceScore: aiResult.confidenceScore,
        isAiValidated: aiResult.isValid,
      );

      await GamificationService().awardPointsForComplaint(
        isValidated: aiResult.isValid,
        aiConfidenceScore: aiResult.confidenceScore,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              complaintId != null
                  ? 'Complaint submitted successfully!'
                  : 'This issue has already been reported by others.',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Issue'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '📸 Upload Photo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (_selectedImage != null)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(File(_selectedImage!.path)),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '📋 Issue Type',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<IssueType>(
                value: _selectedIssueType,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: IssueType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getIssueTypeDisplay(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedIssueType = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              Text(
                '📝 Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe the issue in detail...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                '📍 Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (_location != null)
                Card(
                  child: Padding(
                    padding: AppSpacing.paddingMd,
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _location!.address,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (_location!.landmark != null)
                                Text(
                                  _location!.landmark!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                icon: _isLoadingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(_isLoadingLocation ? 'Getting location...' : 'Use Current Location'),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                '✏️ Type Your Address',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'Type any address (e.g., 123 Main St, New York, NY)',
                  prefixIcon: const Icon(Icons.edit_location_outlined),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check_circle),
                    onPressed: _setManualAddress,
                    tooltip: 'Confirm address',
                  ),
                ),
                onFieldSubmitted: (_) => _setManualAddress(),
                textInputAction: TextInputAction.done,
              ),
              if (_useManualAddress && _location != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Address set: ${_location!.address}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Or select preset area:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: ['Downtown', 'Midtown', 'Brooklyn', 'Queens'].map((city) {
                  return ChoiceChip(
                    label: Text(city),
                    selected: _useManualLocation && _selectedCity == city,
                    onSelected: (_) => _selectManualLocation(city),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitComplaint,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Complaint'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _getIssueTypeDisplay(IssueType type) {
    switch (type) {
      case IssueType.pothole:
        return '🕳️ Pothole';
      case IssueType.brokenStreetlight:
        return '💡 Broken Streetlight';
      case IssueType.waterlogging:
        return '💧 Waterlogging';
      case IssueType.openManhole:
        return '⚠️ Open Manhole';
      case IssueType.garbageDump:
        return '🗑️ Garbage Dump';
      case IssueType.other:
        return '📌 Other';
    }
  }
}
