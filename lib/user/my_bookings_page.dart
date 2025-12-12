// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/booking.dart';
import 'package:flutter_application_1/models/service.dart';
import 'package:flutter_application_1/services/booking_service.dart';
import 'package:flutter_application_1/services/service_catalog_service.dart';
import 'package:flutter_application_1/user/payment_page.dart';
import 'package:flutter_application_1/user/booking_detail_page.dart';

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view your bookings.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        title: const Text('My Bookings'),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: BookingService.instance.watchCustomerBookings(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load bookings.'),
            );
          }

          final bookings = snapshot.data ?? [];

          Color statusColor(String status) {
            switch (status) {
              case BookingStatus.completed:
                return Colors.green;
              case BookingStatus.cancelled:
                return Colors.redAccent;
              case BookingStatus.inProgress:
              case BookingStatus.onTheWay:
              case BookingStatus.accepted:
                return Colors.orange;
              case BookingStatus.requested:
              default:
                return Colors.blueGrey;
            }
          }

          String statusLabel(String status) {
            switch (status) {
              case BookingStatus.completed:
                return 'Completed';
              case BookingStatus.cancelled:
                return 'Cancelled';
              case BookingStatus.inProgress:
                return 'In progress';
              case BookingStatus.onTheWay:
                return 'On the way';
              case BookingStatus.accepted:
                return 'Scheduled';
              case BookingStatus.requested:
              default:
                return 'Requested';
            }
          }

          Widget buildBookingTile(BookingModel b) {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.08),
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
                      builder: (_) => BookingDetailPage(booking: b),
                    ),
                  );
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.cleaning_services_rounded,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FutureBuilder<ServiceModel?>(
                        future: ServiceCatalogService.instance
                            .getService(b.serviceId),
                        builder: (context, serviceSnap) {
                          final service = serviceSnap.data;
                          final serviceName = service?.name ?? 'Service';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                serviceName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
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
                            ],
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
                            color: statusColor(b.status).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusLabel(b.status),
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
                        const SizedBox(height: 4),
                        if (b.paymentStatus == PaymentStatus.pending)
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PaymentPage(booking: b),
                                ),
                              );
                            },
                            child: const Text('Pay now'),
                          )
                        else
                          const Text(
                            'Paid',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          final statusOrder = [
            BookingStatus.requested,
            BookingStatus.accepted,
            BookingStatus.onTheWay,
            BookingStatus.inProgress,
            BookingStatus.completed,
            BookingStatus.cancelled,
          ];

          final statusLabels = [
            'Requested',
            'Scheduled',
            'On the way',
            'In progress',
            'Completed',
            'Cancelled',
          ];

          return DefaultTabController(
            length: statusOrder.length,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  tabs: [
                    for (int i = 0; i < statusOrder.length; i++)
                      Tab(
                        child: Text(
                          statusLabels[i],
                          style: TextStyle(
                            color: statusColor(statusOrder[i]),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      for (final status in statusOrder)
                        Builder(
                          builder: (context) {
                            final filtered = bookings
                                .where((b) => b.status == status)
                                .toList();
                            if (filtered.isEmpty) {
                              return Center(
                                child: Text(
                                  'No ${statusLabel(status).toLowerCase()} bookings yet.',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) =>
                                  buildBookingTile(filtered[index]),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }
}

String _formatDateTime(DateTime? dt) {
  if (dt == null) return 'Not set';
  final local = dt.toLocal();
  final date = '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
  final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$date • $time';
}

