import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_manager/app/global/button.dart';
import 'package:task_manager/app/global/textfields.dart';
import 'package:task_manager/app/utils/color.dart';

import 'package:task_manager/app/views/register/controller/register_controller.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final RegisterController controller = Get.put(RegisterController());

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Register',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Appcolors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 16.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: controller.pickImage,
                  child: Stack(
                    children: [
                      Obx(() => Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Appcolors.background,
                              border: Border.all(
                                color: Appcolors.primary,
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: controller.selectedImage.value != null
                                  ? Image.file(
                                      controller.selectedImage.value!,
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Appcolors.primary,
                                    ),
                            ),
                          )),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 25,
                          width: 25,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Appcolors.primary,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.edit,
                              size: 16,
                              color: Appcolors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Get.height * 0.1),
                TextFields(
                  controller: controller.nameController,
                  hintText: 'Amit',
                  label: 'Enter the Name',
                ),
                TextFields(
                  controller: controller.emailController,
                  hintText: 'amit@gmail.com',
                  label: 'Enter the Email',
                ),
                TextFields(
                  controller: controller.passwordController,
                  hintText: '*******',
                  label: 'Enter the Password',
                  onTap: controller.togglePasswordVisibility,
                ),
                SizedBox(height: Get.height * 0.05),
                Obx(() => GestureDetector(
                      onTap: controller.isLoading.value
                          ? null
                          : controller.register,
                      child: Button(
                        text: controller.isLoading.value
                            ? 'Registering...'
                            : 'Register',
                        color: Appcolors.primary,
                        textColor: Appcolors.white,
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
