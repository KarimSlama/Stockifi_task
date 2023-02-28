import 'package:flutter/material.dart';

class StocklioBlinkingText extends StatefulWidget {
  final String text;
  const StocklioBlinkingText({Key? key, required this.text}) : super(key: key);

  @override
  State<StocklioBlinkingText> createState() => _StocklioBlinkingTextState();
}

class _StocklioBlinkingTextState extends State<StocklioBlinkingText>
    with SingleTickerProviderStateMixin {
  late Animation<Color?> _animation;
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);

    final curve = CurvedAnimation(parent: _controller, curve: Curves.linear);

    _animation =
        ColorTween(begin: Colors.white, end: Colors.transparent).animate(curve);

    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
      setState(() {});
    });

    _controller.forward();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Text(widget.text, style: TextStyle(color: _animation.value));
        });
  }
}
