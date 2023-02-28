import 'package:flutter/material.dart';

class PaddedText extends StatelessWidget {
  final String text;
  final double? padding;
  final TextStyle? style;
  final TextAlign? textAlign;
  final double? width;
  final TextOverflow? overflow;
  final int? maxLines;

  const PaddedText(
    this.text, {
    Key? key,
    this.textAlign,
    this.style,
    this.padding,
    this.width,
    this.overflow,
    this.maxLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: EdgeInsets.all(padding ?? 8.0),
      child: Text(
        text,
        style: style,
        overflow: overflow,
        maxLines: maxLines,
        textAlign: textAlign,
      ),
    );
  }
}
