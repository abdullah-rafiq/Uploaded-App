// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/services/auth_service.dart';

import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        if (email.isEmpty) _emailError = 'Email is required';
        if (password.isEmpty) _passwordError = 'Password is required';
      });
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _emailError = 'Please enter a valid email address';
      });
      return;
    }

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Simple analytics/logging
      // ignore: avoid_print
      print('LOGIN_EMAIL_SUCCESS user=${cred.user?.uid}');

      if (cred.user != null && email.toLowerCase() == 'firebase@fire.com') {
        await AuthService.instance.ensureAdminUser(cred.user!);
      }

      final profile = await AuthService.instance.getCurrentUserProfile();

      if (!mounted) return;

      // Hide keyboard before navigation to reduce transition jank
      FocusScope.of(context).unfocus();

      if (profile == null) {
        context.go('/role');
        return;
      }

      switch (profile.role) {
        case UserRole.customer:
          context.go('/home');
          break;
        case UserRole.provider:
          context.go('/worker');
          break;
        case UserRole.admin:
          context.go('/admin');
          break;
        // ignore: unreachable_switch_default
        default:
          context.go('/home');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';

      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Something went wrong, please try again later')),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // user cancelled

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = userCred.user;

      if (firebaseUser != null) {
        // Ensure there is a Firestore user document if missing (e.g. first Google sign-in)
        await AuthService.instance.ensureUserDocument(
          firebaseUser: firebaseUser,
          role: UserRole.customer,
        );
      }

      // Simple analytics/logging
      // ignore: avoid_print
      print('LOGIN_GOOGLE_SUCCESS user=${firebaseUser?.uid}');

      final profile = await AuthService.instance.getCurrentUserProfile();

      if (!mounted) return;

      if (profile == null) {
        context.go('/role');
        return;
      }

      switch (profile.role) {
        case UserRole.customer:
          context.go('/home');
          break;
        case UserRole.provider:
          context.go('/worker');
          break;
        case UserRole.admin:
          context.go('/admin');
          break;
        // ignore: unreachable_switch_default
        default:
          context.go('/home');
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Google sign-in failed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong with Google sign-in: $e'),
        ),
      );
    }
  }

  Future<void> _forgotPassword() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ForgotPasswordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      // Avoid full layout jump when keyboard opens; we handle insets manually
      resizeToAvoidBottomInset: false,

      /// 🔥 FIXED BACKGROUND
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/login_main.jpg'),
            fit: BoxFit.cover,
          ),
        ),

        /// Overlay
        child: Container(
          color: const Color.fromARGB(115, 0, 213, 255),

          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 28,
                right: 16,
                top: 24,
                bottom: bottomInset > 0 ? bottomInset + 24 : 40,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,

                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 80),

                  const Text(
                    'Welcome Back,',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.15),
                          offset: Offset(0, 5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Login to your account using\nEmail and password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.80),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),

                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            labelText: "Email",
                            labelStyle:
                                const TextStyle(color: Colors.black54),
                            errorText: _emailError,
                          ),
                          onChanged: (value) {
                            setState(() {
                              if (value.isEmpty) {
                                _emailError = "Email is required";
                              } else if (!_isValidEmail(value.trim())) {
                                _emailError = "Enter a valid email";
                              } else {
                                _emailError = null;
                              }
                            });
                          },
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            labelText: "Password",
                            labelStyle:
                                const TextStyle(color: Colors.black54),
                            errorText: _passwordError,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _passwordError =
                                  value.isEmpty ? "Password is required" : null;
                            });
                          },
                          onSubmitted: (_) => _login(),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF29B6F6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _login,
                            child: const Text(
                              "Log In",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Forgot your password? ",
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                      GestureDetector(
                        onTap: _forgotPassword,
                        child: const Text(
                          "Reset password",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: SizedBox(
                      width: size.width * 0.7,
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                        onPressed: _signInWithGoogle,
                        icon: Image.asset(
                          "assets/icons/google.png",
                          width: 24,
                        ),
                        label: const Text(
                          "Continue with Google",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignUpScreen()),
                        );
                      },
                      child: const Text(
                        "Create an account",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}