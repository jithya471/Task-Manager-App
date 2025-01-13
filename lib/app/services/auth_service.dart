import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:task_manager/app/routes/app_routes.dart';
import 'package:task_manager/app/utils/color.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Rx<User?> user = Rx<User?>(null);
  final RxBool rememberMe = false.obs;
  late String initialRoute;

  @override
  void onInit() {
    super.onInit();
    user.bindStream(_auth.authStateChanges());
    _handleMultiSessions();
  }

  Future<void> checkInitialAuthState() async {
    try {
      // Check if user is logged in
      final currentUser = _auth.currentUser;

      // Check remember me status
      final storage = GetStorage();
      final bool remembered = storage.read('rememberMe') ?? false;

      if (currentUser != null && remembered) {
        // Verify if the user's session is valid in Firestore
        final sessionDoc = await _firestore
            .collection('user_sessions')
            .doc(currentUser.uid)
            .get();

        if (sessionDoc.exists && sessionDoc.data()?['forcedLogout'] != true) {
          initialRoute = AppRoutes.homeView;
        } else {
          // If session is invalid, logout user
          await logoutUser();
          initialRoute = AppRoutes.loginView;
        }
      } else {
        // If not logged in or not remembered, go to login
        initialRoute = AppRoutes.loginView;
      }
    } catch (e) {
      log('Error checking auth state: $e');
      initialRoute = AppRoutes.loginView;
    }
  }

  Future<void> _handleMultiSessions() async {
    user.listen((User? user) async {
      if (user != null) {
        try {
          final tokenResult = await user.getIdTokenResult();
          final lastSignInTime = tokenResult.authTime;

          // Store session info in Firestore
          await _firestore.collection('user_sessions').doc(user.uid).set({
            'lastSignInTime': lastSignInTime?.toIso8601String(),
            'deviceId': await _getDeviceId(),
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // Listen for forced logout
          _firestore
              .collection('user_sessions')
              .doc(user.uid)
              .snapshots()
              .listen(
            (snapshot) {
              if (snapshot.exists && snapshot.data()?['forcedLogout'] == true) {
                logoutUser();
              }
            },
            onError: (error) {
              log('Error listening to session changes: $error');
            },
          );
        } catch (e) {
          log('Error handling multi-sessions: $e');
          // Optionally show a snackbar or handle the error
          Get.snackbar(
            'Warning',
            'Unable to sync session data. Some features might be limited.',
            backgroundColor: Appcolors.red,
            colorText: Appcolors.white,
            duration: const Duration(seconds: 3),
          );
        }
      }
    });
  }

  Future<String> _getDeviceId() async {
    // Implement device ID generation logic
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<UserCredential?> registerUser(
      String email, String password, String name, String? avatarUrl) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create user profile with proper null handling for avatarUrl
        final userData = {
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Only add avatarUrl to userData if it's not null
        if (avatarUrl != null) {
          userData['avatarUrl'] = avatarUrl;
        }

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userData);
      }

      return userCredential;
    } catch (e) {
      log('Error in registerUser: $e'); 
      rethrow;
    }
  }

  Future<void> loginUser(String email, String password, bool rememberMe) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (rememberMe) {
        final storage = GetStorage();
        await storage.write('rememberMe', true);
        await storage.write('email', email);
        await storage.write('password', password);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logoutUser() async {
    try {
      final storage = GetStorage();
      await storage.remove('rememberMe');
      await storage.remove('email');
      await storage.remove('password');

      if (user.value != null) {
        await _firestore
            .collection('user_sessions')
            .doc(user.value!.uid)
            .delete();
      }

      await _auth.signOut();
      Get.offAllNamed(AppRoutes.loginView);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to logout. Please try again.',
        backgroundColor: Appcolors.red,
        colorText: Appcolors.white,
      );
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar(
        'Success',
        'Password reset email sent',
        backgroundColor: Appcolors.green,
        colorText: Appcolors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send reset email',
        backgroundColor: Appcolors.red,
        colorText: Appcolors.white,
      );
      rethrow;
    }
  }
}
