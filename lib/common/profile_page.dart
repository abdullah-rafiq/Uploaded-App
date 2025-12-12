// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/services/user_service.dart';
import 'package:flutter_application_1/worker/worker_verification_page.dart';

import '../user/wallet_page.dart';
import '../user/my_bookings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color accentBlue = Color(0xFF29B6F6);
    final current = FirebaseAuth.instance.currentUser;

    if (current == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view your profile.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FutureBuilder<AppUser?>(
          future: UserService.instance.getById(current.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final profile = snapshot.data;

            if (profile != null && !profile.verified) {
              final authUser = current;
              if (authUser.emailVerified) {
                UserService.instance
                    .updateUser(current.uid, {'verified': true});
              }
            }
            final displayName =
                profile?.name ?? current.displayName ?? 'User';
            final profileImageUrl = profile?.profileImageUrl;

            final avatarImage = (profileImageUrl != null && profileImageUrl.isNotEmpty)
                    ? NetworkImage(profileImageUrl)
                    : ResizeImage(
                     const AssetImage('assets/profile.png'),
                          width: 125,
                          height: 125,
                          ) as ImageProvider;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
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
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: avatarImage,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: IconButton(
                                iconSize: 18,
                                padding: const EdgeInsets.all(2),
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                icon: const Icon(Icons.add_a_photo, size: 16),
                                onPressed: () =>
                                    _changeProfileImage(context, current.uid),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (profile != null) ...[
                          Text(
                            'Role: ${profile.role.name}',
                            style: const TextStyle(
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (profile.role != UserRole.admin) ...[
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: profile.verified
                                  ? null
                                  : () {
                                      if (profile.role == UserRole.provider) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const WorkerVerificationPage(),
                                          ),
                                        );
                                      } else {
                                        _startPhoneVerification(
                                          context,
                                          profile,
                                        );
                                      }
                                    },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    profile.verified
                                        ? Icons.verified
                                        : Icons.error_outline,
                                    size: 16,
                                    color: profile.verified
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    profile.verified
                                        ? 'Verified account'
                                        : 'Not verified (tap to verify)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: profile.verified
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Wallet: PKR ${profile.walletBalance.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (profile == null || profile.role != UserRole.admin)
                    Container(
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          _QuickAction(
                            iconPath: 'assets/icons/wallet.png',
                            label: 'Wallet',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const WalletPage()),
                              );
                            },
                          ),
                          _QuickAction(
                            iconPath: 'assets/icons/booking.png',
                            label: 'Booking',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const MyBookingsPage()),
                              );
                            },
                          ),
                          _QuickAction(
                            iconPath: 'assets/icons/card.png',
                            label: 'Payment',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const MyBookingsPage()),
                              );
                            },
                          ),
                          _QuickAction(
                            iconPath: 'assets/icons/contact-us.png',
                            label: 'Support',
                            onTap: () {
                              context.push('/contact');
                            },
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (profile != null && profile.role != UserRole.admin) ...[
                    ListTile(
                      title: const Text('Edit profile'),
                      subtitle: Text(
                        profile.name == null || profile.name!.isEmpty
                            ? 'Add your name and phone number'
                            : 'Update your name or phone number',
                      ),
                      leading: const Icon(Icons.person_outline),
                      trailing:
                          const Icon(Icons.chevron_right, color: accentBlue),
                      onTap: () => _showEditProfileDialog(context, profile),
                    ),
                    const Divider(),
                  ],
                  ListTile(
                    title: const Text('Settings'),
                    subtitle: const Text('Privacy and logout'),
                    leading: Image.asset(
                      'assets/icons/setting.png',
                      width: 30,
                      height: 30,
                      cacheWidth: 125,  
                      cacheHeight: 125,
                      fit: BoxFit.scaleDown,
                    ),
                    trailing:
                        const Icon(Icons.chevron_right, color: accentBlue),
                    onTap: () {
                      context.push('/settings');
                    },
                  ),
                  const Divider(),
                  if (profile == null || profile.role != UserRole.admin) ...[
                    ListTile(
                      title: const Text('Help & Support'),
                      subtitle: const Text('Help center and legal support'),
                      leading: Image.asset('assets/icons/support.png',cacheWidth: 125,  
                        cacheHeight: 125,),
                      trailing:
                          const Icon(Icons.chevron_right, color: accentBlue),
                      onTap: () {
                        context.push('/contact');
                      },
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('FAQ'),
                      subtitle: const Text('Questions and Answers'),
                      leading: Image.asset('assets/icons/faq.png',cacheWidth: 125,  
                        cacheHeight: 125,),
                      trailing:
                          const Icon(Icons.chevron_right, color: accentBlue),
                      onTap: () {
                        context.push('/faq');
                      },
                    ),
                    const Divider(),
                  ],
                  ListTile(
                    title: const Text('Logout'),
                    subtitle: const Text('Sign out from this account'),
                    leading: const Icon(Icons.logout),
                    trailing:
                        const Icon(Icons.chevron_right, color: accentBlue),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        context.go('/auth');
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

Future<void> _showEditProfileDialog(BuildContext context, AppUser profile) async {
  final nameController = TextEditingController(text: profile.name ?? '');
  final phoneController = TextEditingController(text: profile.phone ?? '');
  final addressController =
      TextEditingController(text: profile.addressLine1 ?? '');
  final townController = TextEditingController(text: profile.town ?? '');
  String? selectedCity = profile.city;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: bottomInset + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Update your basic information so providers can recognize you easily.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      hintText: '+92 300 1234567',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCity,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Lahore', child: Text('Lahore')),
                      DropdownMenuItem(value: 'Islamabad', child: Text('Islamabad')),
                      DropdownMenuItem(value: 'Karachi', child: Text('Karachi')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedCity = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'House no. / Street (address line 1)',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: townController,
                    decoration: const InputDecoration(
                      labelText: 'Town / Area',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () async {
                      try {
                        final serviceEnabled =
                            await Geolocator.isLocationServiceEnabled();
                        if (!serviceEnabled) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Please enable location services to use this feature.'),
                            ),
                          );
                          return;
                        }

                        var permission = await Geolocator.checkPermission();
                        if (permission == LocationPermission.denied) {
                          permission = await Geolocator.requestPermission();
                        }

                        if (permission == LocationPermission.denied ||
                            permission == LocationPermission.deniedForever) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Location permission denied. Please enable it in settings.'),
                            ),
                          );
                          return;
                        }

                        final position = await Geolocator.getCurrentPosition(
                          desiredAccuracy: LocationAccuracy.high,
                        );

                        String? city;
                        String? town;
                        String? addressLine1;
                        try {
                          final placemarks = await placemarkFromCoordinates(
                            position.latitude,
                            position.longitude,
                          );

                          if (placemarks.isNotEmpty) {
                            final p = placemarks.first;

                            city = p.locality ??
                                p.subAdministrativeArea ??
                                p.administrativeArea;
                            town = p.subLocality ?? p.locality;

                            addressLine1 = p.street;
                            if (addressLine1 == null ||
                                addressLine1.trim().isEmpty) {
                              addressLine1 = p.name;
                            }

                            final lowerCity = city?.toLowerCase() ?? '';
                            if (lowerCity.contains('lahore')) {
                              city = 'Lahore';
                            } else if (lowerCity.contains('islamabad')) {
                              city = 'Islamabad';
                            } else if (lowerCity.contains('karachi')) {
                              city = 'Karachi';
                            }
                          }
                        } catch (_) {
                          // Ignore reverse geocoding failures; still save raw location.
                        }

                        final update = <String, dynamic>{
                          'locationLat': position.latitude,
                          'locationLng': position.longitude,
                        };

                        if (city != null && city.isNotEmpty) {
                          update['city'] = city;
                        }

                        if (town != null && town.isNotEmpty) {
                          update['town'] = town;
                        }

                        if (addressLine1 != null &&
                            addressLine1.trim().isNotEmpty) {
                          update['addressLine1'] = addressLine1;
                        }

                        await UserService.instance.updateUser(profile.id, update);

                        setState(() {
                          if (city != null && city.isNotEmpty) {
                            if (city == 'Lahore' ||
                                city == 'Islamabad' ||
                                city == 'Karachi') {
                              selectedCity = city;
                            }
                          }

                          if (town != null && town.isNotEmpty) {
                            townController.text = town;
                          }

                          if (addressLine1 != null &&
                              addressLine1.trim().isNotEmpty) {
                            addressController.text = addressLine1;
                          }
                        });

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Location and city/town updated from your current position.'),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not fetch location: $e'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use current location'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final name = nameController.text.trim();
                            final phone = phoneController.text.trim();

                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Name cannot be empty.')),
                              );
                              return;
                            }

                            try {
                              final address = addressController.text.trim();
                              final town = townController.text.trim();

                              await UserService.instance.updateUser(profile.id, {
                                'name': name,
                                'phone': phone.isEmpty ? null : phone,
                                'city': selectedCity,
                                'addressLine1':
                                    address.isEmpty ? null : address,
                                'town': town.isEmpty ? null : town,
                              });

                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Profile updated successfully.'),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Failed to update profile: $e'),
                                ),
                              );
                            }
                          },
                          child: const Text('Save changes'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.lock_reset),
                    title: const Text('Change password'),
                    subtitle:
                        const Text('Send a password reset link to your email.'),
                    onTap: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      final email = user?.email;

                      if (email == null || email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No email found for this account. You may be using a social login.',
                            ),
                          ),
                        );
                        return;
                      }

                      try {
                        await FirebaseAuth.instance
                            .sendPasswordResetEmail(email: email);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Password reset email sent. Please check your inbox.',
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Could not send reset email: $e',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    title: const Text('Delete account'),
                    subtitle: const Text(
                        'Permanently remove your account and data.'),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Delete account'),
                            content: const Text(
                              'This will permanently delete your account and data. This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirm != true) return;

                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'You must be logged in to delete account.',
                            ),
                          ),
                        );
                        return;
                      }

                      try {
                        final uid = user.uid;
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .delete();

                        await user.delete();

                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      } on FirebaseAuthException catch (e) {
                        if (!context.mounted) return;
                        if (e.code == 'requires-recent-login') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please log in again and then try deleting your account.',
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Could not delete account: ${e.code}'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not delete account: $e'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> _startPhoneVerification(
    BuildContext context, AppUser profile) async {
  final phone = profile.phone?.trim();

  if (phone == null || phone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please add your phone number in Edit profile first.'),
      ),
    );
    return;
  }

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You must be logged in to verify.')),
    );
    return;
  }

  try {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await user.linkWithCredential(credential);
        } catch (_) {
          // Ignore link errors; user might already be linked.
        }

        await UserService.instance
            .updateUser(profile.id, {'verified': true});

        if (context.mounted) {
          // Simple analytics/logging
          // ignore: avoid_print
          print('PHONE_VERIFIED_AUTO uid=${profile.id}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone verified successfully.')),
          );
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: ${e.message}')),
        );
      },
      codeSent: (String verificationId, int? resendToken) async {
        await _showOtpBottomSheet(
          context: context,
          verificationId: verificationId,
          profile: profile,
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Optional: you can inform the user that auto-retrieval timed out.
      },
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not start phone verification: $e')),
    );
  }
}

Future<void> _showOtpBottomSheet({
  required BuildContext context,
  required String verificationId,
  required AppUser profile,
}) async {
  final codeController = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: bottomInset + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Enter OTP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'We\'ve sent a 6-digit code to your phone. Enter it below to verify your account.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'OTP code',
                prefixIcon: Icon(Icons.sms_outlined),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final code = codeController.text.trim();
                  if (code.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter the 6-digit code.'),
                      ),
                    );
                    return;
                  }

                  try {
                    final credential = PhoneAuthProvider.credential(
                      verificationId: verificationId,
                      smsCode: code,
                    );

                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You must be logged in to verify.'),
                        ),
                      );
                      return;
                    }

                    try {
                      await user.linkWithCredential(credential);
                    } catch (_) {
                      // Ignore link errors; user might already be linked or signed in.
                    }

                    await UserService.instance
                        .updateUser(profile.id, {'verified': true});

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      // Simple analytics/logging
                      // ignore: avoid_print
                      print('PHONE_VERIFIED_OTP uid=${profile.id}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Phone verified successfully.'),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invalid code: $e')),
                    );
                  }
                },
                child: const Text('Verify'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _changeProfileImage(BuildContext context, String uid) async {
  try {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);

    // Show loading SnackBar
    final loadingSnack = SnackBar(
      content: Row(
        children: const [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Uploading profile picture...')
        ],
      ),
      duration: const Duration(minutes: 1), // will hide manually
    );
    ScaffoldMessenger.of(context).showSnackBar(loadingSnack);

    // Upload via UserService (Cloudinary under the hood) and update Firestore
    final uploadResult = await UserService.instance.uploadProfileImage(uid, file);
    await UserService.instance.updateProfileImageUrl(uid, uploadResult.secureUrl);
    // Optionally store Cloudinary public_id for future management
    await UserService.instance.updateUser(uid, {
      'profileImagePublicId': uploadResult.publicId,
    });

    // Hide loading SnackBar and show success
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile picture updated.')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not update profile picture: $e')),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String iconPath;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.iconPath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive sizes
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = (screenWidth * 0.10).clamp(40.0, 50.0); // 40-50 px
    final fontSize = (screenWidth * 0.03).clamp(12.0, 14.0); // 12-14 px
    final spacing = iconSize * 0.2; // spacing proportional to icon

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        GestureDetector(
          onTap: onTap,
          child: Image.asset(
            iconPath,
            width: iconSize,
            height: iconSize,
            cacheWidth: 125,
            cacheHeight: 125,
          ),
        ),
        SizedBox(height: spacing),
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
        ),
      ],
    );
  }
}
