import 'dart:developer';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_manager/app/routes/app_routes.dart';
import 'package:task_manager/app/services/auth_service.dart';
import 'package:task_manager/app/utils/color.dart';

class RegisterController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final Rx<File?> selectedImage = Rx<File?>(null);

  void togglePasswordVisibility() {
    isPasswordVisible.toggle();
  }

  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        selectedImage.value = File(image.path);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image',
        backgroundColor: Appcolors.red,
        colorText: Appcolors.red.withValues(alpha: 0.6),
      );
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      // Create unique file name
      final String fileName =
          'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Create storage reference
      final ref =
          FirebaseStorage.instance.ref().child('avatars').child(fileName);

      // Upload the file
      final uploadTask = ref.putFile(
        image,
        SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {'picked-file-path': image.path}),
      );

      // Wait for upload to complete and get download URL
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      log('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      log('Error uploading image: $e');
      Get.snackbar(
        'Error',
        'Failed to upload profile picture',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return null;
    }
  }

  bool _validateInputs() {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Name is required');
      return false;
    }

    if (!GetUtils.isEmail(emailController.text.trim())) {
      Get.snackbar('Error', 'Please enter a valid email');
      return false;
    }

    if (passwordController.text.length < 6) {
      Get.snackbar('Error', 'Password must be at least 6 characters');
      return false;
    }

    return true;
  }

  void register() async {
    if (!_validateInputs()) return;

    isLoading.value = true;
    String? avatarUrl;

    try {
      // First upload image if selected
      if (selectedImage.value != null) {
        avatarUrl = await _uploadImage(selectedImage.value!);
        if (avatarUrl == null) {
          // If image upload failed, notify user but continue with registration
          Get.snackbar(
            'Warning',
            'Failed to upload profile picture, but registration will continue',
            backgroundColor: Colors.yellow[100],
            colorText: Colors.orange[900],
          );
        }
      }

      // Then proceed with user registration
      await _authService.registerUser(
        emailController.text.trim(),
        passwordController.text.trim(),
        nameController.text.trim(),
        avatarUrl,
      );

      // If registration successful, navigate to home
      Get.offAllNamed(AppRoutes.homeView);
    } catch (e) {
      _handleRegisterError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void _handleRegisterError(dynamic error) {
    String message = 'Registration failed';

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          message = 'This email is already registered';
          break;
        case 'weak-password':
          message = 'The password provided is too weak';
          break;
        default:
          message = error.message ?? message;
      }
    }

    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red[100],
      colorText: Colors.red[900],
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
