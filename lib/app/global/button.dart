import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:task_manager/app/utils/color.dart';
import 'package:task_manager/app/utils/styles.dart';

class Button extends StatelessWidget {
  final String text;
  final IconData? icon;
  final IconData? lefticon;
  final BorderRadiusGeometry? borderRadius;
  final double? textsize;
  final Color? color;
  final Color? textColor;
  final FontWeight? fontWeight;
  const Button(
      {super.key,
      required this.text,
      this.icon,
      this.color,
      this.textColor,
      this.lefticon,
      this.borderRadius,
      this.textsize,
      this.fontWeight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width,
      height: Get.height * .06,
      decoration: BoxDecoration(
          color: color ?? Appcolors.primary,
          borderRadius: const BorderRadius.all(Radius.circular(10))),
      child: Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: Get.height * 0.005),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              icon != null
                  ? Padding(
                      padding: EdgeInsets.only(
                          top: Get.height * 0.005, right: Get.width * 0.02),
                      child: Icon(
                        icon,
                        color: Appcolors.white,
                        size: 20,
                      ),
                    )
                  : const SizedBox.shrink(),
              Text(
                text,
                style: style(textsize ?? 16, fontWeight ?? FontWeight.w700,
                    textColor ?? Appcolors.white),
              ),
              lefticon != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                      ),
                      child: Icon(
                        lefticon,
                        color: Appcolors.white,
                        size: 20,
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}