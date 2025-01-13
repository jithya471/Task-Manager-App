import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextStyle style(
  double fontSize,
  FontWeight weight,
  Color color, {
  double? height,
  TextDecoration? decoration,
  TextOverflow? overflow,
  Color? decorationColor,
}) {
  return TextStyle(
    fontFamily: GoogleFonts.roboto(fontWeight: weight).fontFamily,
    fontSize: fontSize,
    fontWeight: weight,
    color: color,
    height: height ?? 1.5,
    overflow: overflow ?? TextOverflow.ellipsis,
    decoration: decoration ?? TextDecoration.none,
    decorationColor: decorationColor,
    textBaseline: TextBaseline.alphabetic,
    leadingDistribution: TextLeadingDistribution.proportional,
  );
}
