import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ValueTextField extends StatefulWidget {
  final InputDecoration? decoration;
  final TextAlign? textAlign;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final String? value;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;

  const ValueTextField({
    Key? key,
    this.decoration,
    this.textAlign,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.value,
    this.enabled = true,
    this.focusNode,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: false),
  }) : super(key: key);

  @override
  State<ValueTextField> createState() => _IngredientTextFieldState();
}

class _IngredientTextFieldState extends State<ValueTextField> {
  final _controller = TextEditingController();

  @override
  void initState() {
    _controller.text = widget.value ?? '';
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: null,
      focusNode: widget.focusNode,
      // autofocus: true,
      enabled: widget.enabled,
      controller: _controller,
      decoration: widget.decoration,
      textAlign: widget.textAlign ?? TextAlign.start,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      onSubmitted: widget.onSubmitted,
    );
  }
}
