// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/service.dart';
import 'package:flutter_application_1/user/service_detail_page.dart';

const Color primaryLightBlue = Color(0xFF4FC3F7);
const Color primaryBlue = Color(0xFF29B6F6);
const Color primaryDarkBlue = Color(0xFF0288D1);

class ProviderModel {
  final String id;
  final String name;
  final String avatar;
  final double rating;
  final double pricePerHour;
  final String service;

  ProviderModel({
    required this.id,
    required this.name,
    this.avatar = 'assets/profile.png',
    this.rating = 4.5,
    this.pricePerHour = 250.0,
    required this.service,
  });
}

final List<ProviderModel> featuredProviders = [
  ProviderModel(
    id: 'p1',
    name: 'Raza Khan',
    avatar: 'assets/profile.png',
    rating: 4.8,
    pricePerHour: 300,
    service: 'Plumbing',
  ),
  ProviderModel(
    id: 'p2',
    name: 'Sadia Ali',
    avatar: 'assets/profile.png',
    rating: 4.6,
    pricePerHour: 250,
    service: 'Cleaning',
  ),
  ProviderModel(
    id: 'p3',
    name: 'Bilal Ahmed',
    avatar: 'assets/profile.png',
    rating: 4.7,
    pricePerHour: 280,
    service: 'Electrician',
  ),
];

class FeaturedProvidersSection extends StatelessWidget {
  const FeaturedProvidersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final p = featuredProviders[index];
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final subtleTextColor = isDark
              ? Colors.white70
              : theme.colorScheme.onSurface.withOpacity(0.7);
          return Container(
            width: 270,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: AssetImage(p.avatar),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: isDark
                                  ? Colors.white
                                  : theme.textTheme.titleMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.service,
                            style: TextStyle(color: subtleTextColor),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${p.rating}',
                                style: TextStyle(color: subtleTextColor),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryLightBlue.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Top Rated',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white
                                        : primaryDarkBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PKR ${p.pricePerHour.toInt()}/hr',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : primaryDarkBlue,
                        fontSize: 15,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final service = ServiceModel(
                          id: p.service.toLowerCase(),
                          name: p.service,
                          basePrice: p.pricePerHour,
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ServiceDetailPage(service: service),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: primaryBlue,
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                      ),
                      child: const Text('Book Now'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemCount: featuredProviders.length,
      ),
    );
  }
}
