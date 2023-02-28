import 'package:flutter/material.dart';
import 'dart:math';

enum SlideDirection { right, left }

enum ButtonState { notConfirmed, confirmed }

class SlideButton extends StatefulWidget {
  /// A child, allowing for any widget to
  /// be put inside the background bar
  final Widget? backgroundChild;

  /// A child, allowing for any widget to
  /// be put inside the sliding bar
  final Widget? slidingChild;

  /// The height of this widget
  final double? height;

  /// Background color of this widget
  final Color? backgroundColor;

  /// BorderRadius for the sliding bar, default is 50
  final double borderRadius;

  /// Sliding bar color of this widget
  final Color slidingBarColor;

  /// The percentage the bar must be to the button be confirmed.
  /// defaults to 0.9
  final double confirmPercentage;

  /// This updates the borders when the button reaches 0.9
  /// percent dragged, and set the borderRadius to zero,
  /// giving the impression of a "closed" button
  final bool shouldCloseBorders;

  /// The percentage the bar is set to snap when the user is not dragging
  /// Doubles as the initial value for the bar
  final double initialSliderPercentage;

  /// Allows toggling of the draggability of the Button.
  /// Set this to false to prevent the user from being able to drag
  /// the panel up and down. Defaults to true.
  final bool isDraggable;

  /// If non-null, this callback
  /// is called as the button slides around with the
  /// current position of the panel. The position is a double
  /// between initialSliderPercentage and 1.0
  final void Function(double position)? onButtonSlide;

  /// If non-null, this callback is called when the
  /// button is CONFIRMED
  final VoidCallback? onButtonOpened;

  /// If non-null, this callback is called when the button
  /// is NOT CONFIRMED
  final VoidCallback? onButtonClosed;

  /// Either SlideDirection.LEFT or SlideDirection.RIGHT. Indicates which way
  /// the button need to be slided. Defaults to RIGHT. If set to LEFT, the panel attaches
  /// itself to the right of the screen and is confirmed .
  final SlideDirection slideDirection;

  final VoidCallback action;

  const SlideButton({
    Key? key,
    this.slidingChild,
    this.backgroundChild,
    this.height,
    this.confirmPercentage = 0.9,
    this.initialSliderPercentage = 0.2,
    this.slideDirection = SlideDirection.right,
    this.isDraggable = true,
    this.onButtonSlide,
    this.onButtonOpened,
    this.onButtonClosed,
    required this.backgroundColor,
    required this.slidingBarColor,
    this.shouldCloseBorders = true,
    this.borderRadius = 50.0,
    required this.action,
  }) : super(key: key);

  @override
  State<SlideButton> createState() => _SlideButtonState();
}

class _SlideButtonState extends State<SlideButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideAnimationController;

  var _borderRadius = 0.0;
  var _maxWidth = 0.0;

  @override
  void initState() {
    super.initState();

    _borderRadius = widget.borderRadius;

    _slideAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300))
      ..addListener(() {
        setState(() {});

        if (widget.shouldCloseBorders) {
          _borderRadius = widget.borderRadius -
              (sigmoid(_slideAnimationController.value) * widget.borderRadius);
        }

        widget.onButtonSlide?.call(_slideAnimationController.value);

        if (_slideAnimationController.value == 1.0) {
          widget.onButtonOpened?.call();
        }

        if (_slideAnimationController.value == widget.initialSliderPercentage) {
          widget.onButtonClosed?.call();
        }
      });

    _slideAnimationController.value = widget.initialSliderPercentage;
  }

  @override
  void dispose() {
    _slideAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _maxWidth = constraints.maxWidth;

        return Stack(
          children: <Widget>[
            Align(
              alignment: const Alignment(-1.0, 0.0),
              child: Container(
                height: widget.height,
                color: widget.backgroundColor,
                child: widget.backgroundChild,
              ),
            ),
            Align(
              alignment: const Alignment(-1.0, 0.0),
              child: GestureDetector(
                onVerticalDragUpdate: widget.isDraggable ? _onDrag : null,
                onVerticalDragEnd: widget.isDraggable ? _onDragEnd : null,
                child: SizedBox(
                  height: widget.height,
                  child: Align(
                    alignment: widget.slideDirection == SlideDirection.right
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 170),
                      width: _slideAnimationController.value * _maxWidth,
                      decoration: BoxDecoration(
                          color: widget.slidingBarColor,
                          borderRadius: widget.slideDirection ==
                                  SlideDirection.right
                              ? BorderRadius.only(
                                  bottomRight: Radius.circular(_borderRadius),
                                  topRight: Radius.circular(_borderRadius))
                              : BorderRadius.only(
                                  bottomLeft: Radius.circular(_borderRadius),
                                  topLeft: Radius.circular(_borderRadius))),
                      child: widget.slidingChild,
                    ),
                  ),
                ),
              ),
            )
          ],
        );
      },
    );
  }

  // Temporary sigmoid function to remove borders from the sliding bar
  double sigmoid(double x) {
    return 1 / (1 + exp(-61 * x + 54));
  }

  void _onDrag(DragUpdateDetails details) {
    if (widget.slideDirection == SlideDirection.right) {
      _slideAnimationController.value = (details.localPosition.dx) / _maxWidth;
    } else {
      _slideAnimationController.value =
          1.0 - (details.globalPosition.dx) / _maxWidth;
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (_slideAnimationController.isAnimating) return;

    if (_slideAnimationController.value > widget.confirmPercentage) {
      _slideAnimationController.fling(velocity: 1.0);
    } else {
      if (_slideAnimationController.value == widget.confirmPercentage) {
        widget.action();
      }

      _slideAnimationController.animateTo(widget.initialSliderPercentage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn);
    }
  }
}
