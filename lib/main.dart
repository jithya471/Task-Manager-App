import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:task_manager/app/routes/app_pages.dart';
import 'package:task_manager/app/services/connectivity_service.dart';
import 'package:task_manager/app/services/local_storage_service.dart';
import 'package:task_manager/app/services/task_service.dart';
import 'package:task_manager/app/utils/color.dart';
import 'package:task_manager/app/views/home/controller/home_controller.dart';
import 'package:task_manager/app_binding.dart';
import 'package:task_manager/error_app.dart';
import 'package:task_manager/theme_controller.dart';
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
    Get.put(ThemeController());
    runApp(const MyApp());
  } catch (e) {
    log('Error during initialization: $e');
    runApp(const ErrorApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure the ThemeController is initialized once
    Get.put(ThemeController());

    return Obx(() {
      // Use `isDarkMode.value` directly to set the themeMode
      final themeController = Get.put(ThemeController());

      return GetMaterialApp(
        title: 'Task Manager',
        debugShowCheckedModeBanner: false,
        initialRoute: Get.find<AuthService>().initialRoute,
        getPages: AppPages.pages,
        initialBinding: AppBinding(),
        theme: ThemeData(
          primaryColor: Appcolors.primary,
          scaffoldBackgroundColor: Appcolors.background,
          appBarTheme: AppBarTheme(
            backgroundColor: Appcolors.primary,
          ),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: Appcolors.textColor),
            bodyMedium: TextStyle(color: Appcolors.textColor),
            headlineLarge: TextStyle(color: Appcolors.primary),
            headlineMedium: TextStyle(color: Appcolors.primary),
          ),
          iconTheme: IconThemeData(color: Appcolors.black),
          buttonTheme: ButtonThemeData(buttonColor: Appcolors.lightBlue),
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          primaryColor: Appcolors.primary,
          scaffoldBackgroundColor: Appcolors.black,
          appBarTheme: AppBarTheme(
            backgroundColor: Appcolors.primary,
          ),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: Appcolors.white),
            bodyMedium: TextStyle(color: Appcolors.white),
            headlineLarge: TextStyle(color: Appcolors.white),
            headlineMedium: TextStyle(color: Appcolors.white),
          ),
          iconTheme: IconThemeData(color: Appcolors.white),
          buttonTheme: ButtonThemeData(buttonColor: Appcolors.lightBlue),
          brightness: Brightness.dark,
        ),
        themeMode:
            themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
        builder: (context, child) {
          return Obx(() {
            final connectivityService = Get.put(ConnectivityService());
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
    });
  }
}
