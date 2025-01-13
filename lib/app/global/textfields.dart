import 'package:flutter/material.dart';
import 'package:task_manager/app/utils/color.dart';
import 'package:task_manager/app/utils/styles.dart';

class TextFields extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final Function()? onTap;
  final String label;
  final int? length;

  const TextFields({
    super.key,
    required this.hintText,
    this.controller,
    this.validator,
    this.keyboardType,
    this.onTap,
    required this.label,
    this.length,
  });

  @override
  State<TextFields> createState() => _TextFieldsState();
}

class _TextFieldsState extends State<TextFields> {
  String? errorText;

  void _validateInput(String value) {
    final result = widget.validator?.call(value);
    setState(() {
      errorText = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: style(13, FontWeight.w500, Appcolors.textColor),
        ),
        TextFormField(
          maxLines: widget.length,
          style: style(14, FontWeight.w400, Appcolors.black),
          keyboardType: widget.keyboardType,
          controller: widget.controller,
          validator: widget.validator,
          enabled: true,
          readOnly: false,
          decoration: InputDecoration(
            fillColor: Appcolors.white,
            filled: true,
            isDense: true,
            contentPadding:
                const EdgeInsets.only(top: 18.0, right: 10.0, left: 10.0),
            suffixIconColor: Appcolors.black,
            helperText: '',
            hintText: widget.hintText,
            hintStyle: style(16.0, FontWeight.w400, Appcolors.lightGrey),
            border: const OutlineInputBorder(
              borderSide: BorderSide(color: Appcolors.borderColor, width: 1.0),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: errorText == null ? Appcolors.borderColor : Colors.red,
                width: 1.0,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: errorText == null ? Appcolors.borderColor : Colors.red,
                width: 1.0,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            errorText: errorText,
            errorStyle: style(12, FontWeight.w400, Colors.red),
            counterText: "",
          ),
          onChanged: (value) {
            _validateInput(value);
          },
          onTap: () {
            if (widget.onTap != null) {
              widget.onTap!();
            }
          },
        ),
      ],
    );
  }
}
