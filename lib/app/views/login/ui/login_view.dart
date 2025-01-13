import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_manager/app/global/button.dart';
import 'package:task_manager/app/global/textfields.dart';
import 'package:task_manager/app/routes/app_routes.dart';
import 'package:task_manager/app/utils/color.dart';
import 'package:task_manager/app/utils/constants.dart';
import 'package:task_manager/app/utils/styles.dart';

import 'package:task_manager/app/views/login/controller/login-controller.dart';

class LoginView extends StatelessWidget {
  final LoginController _controller = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        backgroundColor: Appcolors.primary,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Login',
          style: style(18, FontWeight.w500, Appcolors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: verticalPadding, horizontal: horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                TextFields(
                  hintText: 'amit@gmail.com',
                  label: 'Enter the Email Address',
                  controller: _controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                TextFields(
                  hintText: '*******',
                  label: 'Enter the Password',
                  controller: _controller.passwordController,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Obx(() => Checkbox(
                            value: _controller.rememberMe.value,
                            onChanged: (value) =>
                                _controller.rememberMe.value = value ?? false,
                            activeColor: Appcolors.primary,
                          )),
                      Text(
                        'Remember Me',
                        style: style(14, FontWeight.w400, Appcolors.black),
                      ),
                    ],
                  ),
                ),
                Obx(() => _controller.isLoading.value
                    ? const CircularProgressIndicator()
                    : GestureDetector(
                        onTap: _controller.login,
                        child: Button(text: 'Login'),
                      )),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: verticalPadding),
                  child: GestureDetector(
                    onTap: _controller.forgotPassword,
                    child: Text(
                      'Forgot Password?',
                      style: style(14, FontWeight.w400, Appcolors.primary),
                    ),
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Don\'t have an account?',
                        style: style(14, FontWeight.w400, Appcolors.black),
                      ),
                      TextSpan(
                        text: '  Sign up',
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Get.toNamed(AppRoutes.registerView),
                        style: style(14, FontWeight.w500, Appcolors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
