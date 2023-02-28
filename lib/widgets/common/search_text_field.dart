// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class SearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String)? onChanged;
  final String? hintText;
  final VoidCallback clearCallback;
  const SearchTextField({
    Key? key,
    required this.controller,
    this.onChanged,
    this.hintText,
    required this.clearCallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                onPressed: clearCallback,
              ),
      ),
    );
  }
}
