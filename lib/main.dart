import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:task_manager/app/routes/app_pages.dart';
import 'package:task_manager/app/services/local_storage_service.dart';
import 'package:task_manager/app_binding.dart';

import 'app/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize GetStorage
  await GetStorage.init();

  // Register dependencies
  Get.put(AuthService()); // Register AuthService
  Get.put(LocalStorageService()); // Register LocalStorageService

  // Wait for the initial auth state to be determined
  final authService = Get.find<AuthService>();
  await authService.checkInitialAuthState();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      initialRoute: Get.find<AuthService>().initialRoute,
      getPages: AppPages.pages,
      initialBinding: AppBinding(),
    );
  }
}
