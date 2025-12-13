// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/models/booking.dart';
import 'package:flutter_application_1/models/review.dart';

class AdminWorkerDetailPage extends StatelessWidget {
  final AppUser worker;

  const AdminWorkerDetailPage({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(worker.name?.isNotEmpty == true ? worker.name! : 'Worker details'),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderCard(context),
            const SizedBox(height: 16),
            _buildVerificationSection(context),
            const SizedBox(height: 16),
            _buildEarningsSection(context),
            const SizedBox(height: 16),
            _buildReviewsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            worker.name?.isNotEmpty == true ? worker.name! : 'Worker',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ID: ${worker.id}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          if (worker.phone != null)
            Text(
              'Phone: ${worker.phone}',
              style: const TextStyle(fontSize: 13),
            ),
          if (worker.email != null)
            Text(
              'Email: ${worker.email}',
              style: const TextStyle(fontSize: 13),
            ),
          const SizedBox(height: 4),
          Text(
            'Status: ${worker.status}',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationSection(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(worker.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _sectionCard(
            context,
            title: 'Verification documents',
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _sectionCard(
            context,
            title: 'Verification documents',
            child: Text('Error loading verification: ${snapshot.error}'),
          );
        }

        final doc = snapshot.data;
        final data = doc?.data();
        if (doc == null || !doc.exists || data == null) {
          return _sectionCard(
            context,
            title: 'Verification documents',
            child: const Text('No verification data found for this worker.'),
          );
        }

        final String? cnicFrontUrl = data['cnicFrontImageUrl'] as String?;
        final String? cnicBackUrl = data['cnicBackImageUrl'] as String?;
        final String? selfieUrl = data['selfieImageUrl'] as String?;
        final String? shopUrl = data['shopImageUrl'] as String?;

        final String cnicFrontStatus =
            (data['cnicFrontStatus'] as String?) ?? 'pending';
        final String cnicBackStatus =
            (data['cnicBackStatus'] as String?) ?? 'pending';
        final String selfieStatus =
            (data['selfieStatus'] as String?) ?? 'pending';
        final String shopStatus =
            (data['shopStatus'] as String?) ?? 'pending';

        final bool hasAnyImage =
            cnicFrontUrl != null ||
            cnicBackUrl != null ||
            selfieUrl != null ||
            shopUrl != null;

        if (!hasAnyImage) {
          return _sectionCard(
            context,
            title: 'Verification documents',
            child: const Text(
              'Worker has not submitted verification photos yet.',
            ),
          );
        }

        Color statusColor(String status) {
          switch (status) {
            case 'approved':
              return Colors.green;
            case 'rejected':
              return Colors.redAccent;
            case 'pending':
            default:
              return Colors.orange;
          }
        }

        String statusLabel(String status) {
          switch (status) {
            case 'approved':
              return 'Approved';
            case 'rejected':
              return 'Needs resubmit';
            case 'pending':
            default:
              return 'Pending';
          }
        }

        Widget buildDocRow({
          required String title,
          required String fieldStatusKey,
          required String status,
          required String? url,
        }) {
          if (url == null) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('$title: Not uploaded'),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor(status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel(status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Pass'),
                      onPressed: () async {
                        await _updateDocStatus(
                          context,
                          data,
                          fieldStatusKey,
                          'approved',
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.redAccent,
                      ),
                      label: const Text('Resubmit'),
                      onPressed: () async {
                        await _updateDocStatus(
                          context,
                          data,
                          fieldStatusKey,
                          'rejected',
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          );
        }

        return _sectionCard(
          context,
          title: 'Verification documents',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDocRow(
                title: 'CNIC front picture',
                fieldStatusKey: 'cnicFrontStatus',
                status: cnicFrontStatus,
                url: cnicFrontUrl,
              ),
              buildDocRow(
                title: 'CNIC back picture',
                fieldStatusKey: 'cnicBackStatus',
                status: cnicBackStatus,
                url: cnicBackUrl,
              ),
              buildDocRow(
                title: 'Live picture',
                fieldStatusKey: 'selfieStatus',
                status: selfieStatus,
                url: selfieUrl,
              ),
              buildDocRow(
                title: 'Shop / tools picture',
                fieldStatusKey: 'shopStatus',
                status: shopStatus,
                url: shopUrl,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEarningsSection(BuildContext context) {
    final bookingsQuery = FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: worker.id)
        .where('status', isEqualTo: BookingStatus.completed);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: bookingsQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _sectionCard(
            context,
            title: 'Earnings',
            child: Text('Error loading earnings: ${snapshot.error}'),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final bookings = docs
            .map((d) => BookingModel.fromMap(d.id, d.data()))
            .toList();

        final total = bookings.fold<num>(
          0,
          (sum, b) => sum + (b.price),
        );

        return _sectionCard(
          context,
          title: 'Earnings',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total: PKR ${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                bookings.isEmpty
                    ? 'No completed jobs yet.'
                    : 'Based on ${bookings.length} completed job(s).',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    final reviewsQuery = FirebaseFirestore.instance
        .collection('reviews')
        .where('providerId', isEqualTo: worker.id)
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: reviewsQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _sectionCard(
            context,
            title: 'Customer reviews',
            child: Text('Error loading reviews: ${snapshot.error}'),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _sectionCard(
            context,
            title: 'Customer reviews',
            child: const Text('No reviews yet.'),
          );
        }

        final reviews = docs
            .map((d) => ReviewModel.fromMap(d.id, d.data()))
            .toList();

        final avgRating = reviews.isEmpty
            ? 0.0
            : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                reviews.length;

        return _sectionCard(
          context,
          title: 'Customer reviews',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${reviews.length} review(s))',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final r = reviews[index];
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .shadowColor
                              .withOpacity(0.07),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              i < r.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            );
                          }),
                        ),
                        if (r.comment != null && r.comment!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              r.comment!,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          'Booking: ${r.bookingId}',
                          style: const TextStyle(
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateDocStatus(
    BuildContext context,
    Map<String, dynamic> currentData,
    String statusField,
    String newStatus,
  ) async {
    try {
      final Map<String, String> statuses = {
        'cnicFrontStatus': statusField == 'cnicFrontStatus'
            ? newStatus
            : (currentData['cnicFrontStatus'] as String? ?? 'pending'),
        'cnicBackStatus': statusField == 'cnicBackStatus'
            ? newStatus
            : (currentData['cnicBackStatus'] as String? ?? 'pending'),
        'selfieStatus': statusField == 'selfieStatus'
            ? newStatus
            : (currentData['selfieStatus'] as String? ?? 'pending'),
        'shopStatus': statusField == 'shopStatus'
            ? newStatus
            : (currentData['shopStatus'] as String? ?? 'pending'),
      };

      String overall;
      if (statuses.values.every((s) => s == 'approved')) {
        overall = 'approved';
      } else if (statuses.values.any((s) => s == 'rejected')) {
        overall = 'rejected';
      } else {
        overall = 'pending';
      }

      final updates = <String, dynamic>{
        statusField: newStatus,
        'verificationStatus': overall,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(worker.id)
          .update(updates);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'approved'
                  ? 'Document marked as passed.'
                  : 'Document marked for resubmission.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update status: $e')),
        );
      }
    }
  }

  Widget _sectionCard(BuildContext context,
      {required String title, required Widget child}) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
