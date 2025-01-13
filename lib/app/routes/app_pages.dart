import 'package:get/get.dart';
import 'package:task_manager/app/routes/app_routes.dart';
import 'package:task_manager/app/views/add_task/bindings/add_task_binding.dart';
import 'package:task_manager/app/views/add_task/ui/add_task_view.dart';
import 'package:task_manager/app/views/home/ui/home_view.dart';
import 'package:task_manager/app/views/login/bindings/login_binding.dart';
import 'package:task_manager/app/views/login/ui/login_view.dart';
import 'package:task_manager/app/views/register/ui/register_view.dart';

class AppPages {
  static final List<GetPage> pages = [
    GetPage(
        name: AppRoutes.loginView,
        page: () => LoginView(),
        binding: LoginBinding()),
    GetPage(
      name: AppRoutes.registerView,
      page: () => const RegisterView(),
    ),
    GetPage(
        name: AppRoutes.homeView,
        page: () => const HomeView(),
        binding: LoginBinding()),
    GetPage(
        name: AppRoutes.addtask,
        page: () => const AddTaskView(),
        binding: AddTaskBinding()),
  ];
}
