import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:task_manager/app/routes/app_routes.dart';
import 'package:task_manager/app/services/auth_service.dart';
import 'package:task_manager/app/utils/color.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _authService = Get.find<AuthService>();
  final _storage = GetStorage();

  final RxBool rememberMe = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() async {
    final savedEmail = _storage.read('email');
    final savedPassword = _storage.read('password');
    if (savedEmail != null && savedPassword != null) {
      emailController.text = savedEmail;
      passwordController.text = savedPassword;
      rememberMe.value = true;
    }
  }

  void login() async {
    if (!_validateInputs()) return;

    isLoading.value = true;
    try {
      await _authService.loginUser(
        emailController.text.trim(),
        passwordController.text.trim(),
        rememberMe.value,
      );

      if (rememberMe.value) {
        await _storage.write('email', emailController.text.trim());
        await _storage.write('password', passwordController.text.trim());
      } else {
        await _storage.remove('email');
        await _storage.remove('password');
      }

      Get.offAllNamed(AppRoutes.homeView);
    } catch (e) {
      _handleLoginError(e);
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateInputs() {
    if (emailController.text.trim().isEmpty ||
        !GetUtils.isEmail(emailController.text.trim())) {
      Get.snackbar(
        'Error',
        'Please enter a valid email address',
        backgroundColor: Appcolors.red,
        colorText: Appcolors.white,
      );
      return false;
    }

    if (passwordController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Password cannot be empty',
        backgroundColor: Appcolors.red,
        colorText: Appcolors.white,
      );
      return false;
    }

    return true;
  }

  void _handleLoginError(dynamic error) {
    String message = 'An unexpected error occurred';

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          message = 'No user found for this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password. Please try again';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later';
          break;
        default:
          message = error.message ?? message;
      }
    }

    Get.snackbar(
      'Error',
      message,
      backgroundColor: Appcolors.red,
      colorText: Appcolors.white,
    );
  }

  void forgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty || !GetUtils.isEmail(email)) {
      Get.snackbar(
        'Error',
        'Please enter a valid email address',
        backgroundColor: Appcolors.red,
        colorText: Appcolors.white,
      );
      return;
    }

    try {
      await _authService.resetPassword(email);
      Get.snackbar(
        'Success',
        'Password reset email sent. Please check your inbox.',
        backgroundColor: Appcolors.green,
        colorText: Appcolors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send reset email. Please try again.',
        backgroundColor: Appcolors.red,
        colorText: Appcolors.white,
      );
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
