// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/services/user_service.dart';
import 'package:flutter_application_1/services/cloudinary_service.dart';

class WorkerVerificationPage extends StatefulWidget {
  const WorkerVerificationPage({super.key});

  @override
  State<WorkerVerificationPage> createState() => _WorkerVerificationPageState();
}

class _WorkerVerificationPageState extends State<WorkerVerificationPage> {
  // ignore: unused_field
  bool _submitting = false;
  String? _cnicFrontUrl;
  String? _cnicBackUrl;
  String? _selfieUrl;
  String? _shopUrl;

  final ImagePicker _picker = ImagePicker();

  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload(String field) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to verify.')),
      );
      return;
    }

    try {
      final picked = await _picker.pickImage(source: ImageSource.camera);
      if (picked == null) return;

      final file = File(picked.path);

      // Upload via Cloudinary and store URL/publicId in the corresponding user fields.
      final result = await CloudinaryService.instance.uploadImage(
        file: file,
        folder: 'worker_verification/${user.uid}',
        publicId: field,
      );
      final url = result.secureUrl;

      await UserService.instance.updateUser(user.uid, {
        field: url,
        '${field}PublicId': result.publicId,
      });

      setState(() {
        if (field == 'cnicFrontImageUrl') {
          _cnicFrontUrl = url;
        } else if (field == 'cnicBackImageUrl') {
          _cnicBackUrl = url;
        } else if (field == 'selfieImageUrl') {
          _selfieUrl = url;
        } else if (field == 'shopImageUrl') {
          _shopUrl = url;
        }
      });

      if (mounted) {
        if (field == 'cnicFrontImageUrl') {
          _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } else if (field == 'cnicBackImageUrl') {
          _pageController.animateToPage(
            2,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } else if (field == 'selfieImageUrl') {
          _pageController.animateToPage(
            3,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } else if (field == 'shopImageUrl') {
          // Last step completed: auto-submit verification
          _submitVerification();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload image: $e')),
        );
      }
    }
  }

  Future<void> _submitVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to verify.')),
      );
      return;
    }

    if (_cnicFrontUrl == null ||
        _cnicBackUrl == null ||
        _selfieUrl == null ||
        _shopUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please upload CNIC front & back pictures, live picture, and shop/tools pictures first.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await UserService.instance.updateUser(user.uid, {
        'verificationStatus': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification details submitted. Your account is under review.'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit verification: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    // ignore: unused_local_variable
    final Color titleColor =
        isDark ? Colors.white : theme.colorScheme.onSurface;
    // ignore: unused_local_variable
    final Color descColor = isDark
        ? Colors.white70
        : theme.colorScheme.onSurface.withOpacity(0.7);
    const totalSteps = 4;
    final completedSteps =
        (_cnicFrontUrl != null ? 1 : 0) +
        (_cnicBackUrl != null ? 1 : 0) +
        (_selfieUrl != null ? 1 : 0) +
        (_shopUrl != null ? 1 : 0);
    final progress = completedSteps / totalSteps;
    final currentStep =
        completedSteps < totalSteps ? completedSteps + 1 : totalSteps;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker verification'),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'To start taking jobs, please upload the following live photos:',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step $currentStep of $totalSteps',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 210,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  // Prevent swiping ahead of the current completed step.
                  int maxStep = 0;
                  if (_cnicFrontUrl != null) maxStep = 1;
                  if (_cnicBackUrl != null) maxStep = 2;
                  if (_selfieUrl != null) maxStep = 3;

                  if (index > maxStep) {
                    _pageController.animateToPage(
                      maxStep,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                  }
                },
                children: [
                  _VerificationTile(
                    title: 'CNIC front picture',
                    description: 'Take a clear picture of the front of your CNIC.',
                    uploaded: _cnicFrontUrl != null,
                    onTap: () => _pickAndUpload('cnicFrontImageUrl'),
                  ),
                  _VerificationTile(
                    title: 'CNIC back picture',
                    description:
                        'Take a clear picture of the back side of your CNIC.',
                    uploaded: _cnicBackUrl != null,
                    enabled: _cnicFrontUrl != null,
                    onTap: () => _pickAndUpload('cnicBackImageUrl'),
                  ),
                  _VerificationTile(
                    title: 'Live picture',
                    description: 'Take a live picture of yourself matching your CNIC.',
                    uploaded: _selfieUrl != null,
                    enabled:
                        _cnicFrontUrl != null && _cnicBackUrl != null,
                    onTap: () => _pickAndUpload('selfieImageUrl'),
                  ),
                  _VerificationTile(
                    title: 'Shop / tools picture',
                    description: 'Take a picture of your shop or tools.',
                    uploaded: _shopUrl != null,
                    enabled: _selfieUrl != null,
                    onTap: () => _pickAndUpload('shopImageUrl'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationTile extends StatelessWidget {
  final String title;
  final String description;
  final bool uploaded;
  final bool enabled;
  final VoidCallback onTap;

  const _VerificationTile({
    required this.title,
    required this.description,
    required this.uploaded,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color titleColor =
        isDark ? Colors.white : theme.colorScheme.onSurface;
    final Color descColor = isDark
        ? Colors.white70
        : theme.colorScheme.onSurface.withOpacity(0.7);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            uploaded ? Icons.check_circle : Icons.photo_camera_outlined,
            color: uploaded ? Colors.green : Colors.blueAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: descColor,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: enabled ? onTap : null,
                    child: Text(uploaded ? 'Retake photo' : 'Take photo'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
