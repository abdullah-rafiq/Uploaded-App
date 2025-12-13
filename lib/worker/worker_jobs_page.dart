// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/models/booking.dart';
import 'package:flutter_application_1/models/service.dart';
import 'package:flutter_application_1/services/booking_service.dart';
import 'package:flutter_application_1/services/service_catalog_service.dart';
import 'package:flutter_application_1/services/user_service.dart';
import 'package:flutter_application_1/localized_strings.dart';
import 'worker_job_detail_page.dart';

class WorkerJobsPage extends StatefulWidget {
  const WorkerJobsPage({super.key});

  @override
  State<WorkerJobsPage> createState() => _WorkerJobsPageState();
}

class _WorkerJobsPageState extends State<WorkerJobsPage> {
  String? _statusFilter; // null = All

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(L10n.workerJobsLoginRequiredMessage()),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(L10n.workerJobsAppBarTitle()),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<List<BookingModel>>(
        stream: BookingService.instance.watchProviderBookings(
          user.uid,
          status: _statusFilter,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                L10n.workerJobsLoadError(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            );
          }

          final bookings = snapshot.data ?? [];

          if (bookings.isEmpty) {
            return Center(
              child: Text(
                L10n.workerJobsEmptyMessage(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            );
          }

          Color statusColor(String status) {
            switch (status) {
              case BookingStatus.completed:
                return Colors.green;
              case BookingStatus.cancelled:
                return Colors.redAccent;
              case BookingStatus.inProgress:
              case BookingStatus.onTheWay:
                return Colors.orange;
              case BookingStatus.accepted:
                return Colors.blueAccent;
              default:
                return Colors.blueGrey;
            }
          }

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(L10n.bookingFilterAll(), null),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          L10n.bookingStatusRequested(), BookingStatus.requested),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          L10n.bookingStatusAccepted(), BookingStatus.accepted),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          L10n.bookingStatusInProgress(), BookingStatus.inProgress),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          L10n.bookingStatusCompleted(), BookingStatus.completed),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final b = bookings[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .shadowColor
                                .withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WorkerJobDetailPage(booking: b),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.assignment_outlined,
                              color: Colors.blueAccent,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FutureBuilder<ServiceModel?>(
                                future: ServiceCatalogService.instance
                                    .getService(b.serviceId),
                                builder: (context, serviceSnap) {
                                  final service = serviceSnap.data;
                                  final serviceName =
                                      service?.name ?? 'Service';

                                  return FutureBuilder<AppUser?>(
                                    future: UserService.instance
                                        .getById(b.customerId),
                                    builder: (context, userSnap) {
                                      final customer = userSnap.data;
                                      final customerName =
                                          (customer?.name
                                                      ?.trim()
                                                      .isNotEmpty ??
                                                  false)
                                              ? customer!.name!.trim()
                                              : 'Customer';

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            serviceName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${L10n.workerJobCustomerPrefix()} $customerName',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            b.scheduledTime == null
                                                ? 'Time: not set'
                                                : 'Time: ${_formatDateTime(b.scheduledTime)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (b.address != null &&
                                              b.address!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              b.address!,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor(b.status)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    b.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor(b.status),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'PKR ${b.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: bookings.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final selected = _statusFilter == status;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _statusFilter = status;
        });
      },
    );
  }
}

String _formatDateTime(DateTime? dt) {
  if (dt == null) return L10n.commonNotSet();
  final local = dt.toLocal();
  final date = '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
  final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$date • $time';
}
