import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:task_manager/app/routes/app_pages.dart';
import 'package:task_manager/app/services/connectivity_service.dart';
import 'package:task_manager/app/services/local_storage_service.dart';
import 'package:task_manager/app/services/task_service.dart';
import 'package:task_manager/app_binding.dart';
import 'package:task_manager/error_app.dart';
import 'app/services/auth_service.dart';

Future<void> main() async {
  try {
    // Ensure Flutter is initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp();

    // Initialize local storage
    await GetStorage.init();

    // Initialize services
    final localStorageService =
        Get.put<LocalStorageService>(LocalStorageService());
    await localStorageService.onInit();

    // Initialize auth service
    final authService = Get.put(AuthService());
    await authService.checkInitialAuthState();

    // Initialize task service after auth
    final taskService = Get.put(TaskService());

    // Initialize connectivity service last since it depends on other services
    final connectivityService = Get.put(ConnectivityService());

    runApp(const MyApp());
  } catch (e) {
    log('Error during initialization: $e');
    runApp(
        const ErrorApp()); 
  }
}

// Application widget
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
      theme: ThemeData(
        // Add your theme configuration
        primarySwatch: Colors.blue,
      ),
      builder: (context, child) {
        return Obx(() {
          final connectivityService = Get.find<ConnectivityService>();
          final hasConnection = connectivityService.hasConnection;

          return Stack(
            children: [
              child!,
              if (!hasConnection)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Material(
                    child: Container(
                      color: Colors.red,
                      padding: const EdgeInsets.all(8),
                      child: const Text(
                        'You are offline. Changes will sync when connection is restored.',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          );
        });
      },
    );
  }
}
