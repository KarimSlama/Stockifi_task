import 'package:flutter/material.dart';

enum _ButtonType { sync, async }

class StockifiButton extends StatefulWidget {
  final Function()? onPressed;
  final Future<bool> Function()? confirmationCallback;
  final Widget child;
  final ButtonStyle? style;

  const StockifiButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.confirmationCallback,
    this.style,
  })  : _buttonType = _ButtonType.sync,
        super(key: key);

  const StockifiButton.async({
    Key? key,
    required this.child,
    this.onPressed,
    this.confirmationCallback,
    this.style,
  })  : _buttonType = _ButtonType.async,
        super(key: key);

  final _ButtonType _buttonType;

  @override
  State<StockifiButton> createState() => _StockifiButtonState();
}

class _StockifiButtonState extends State<StockifiButton> {
  late bool _isLoading;

  @override
  void initState() {
    _isLoading = false;
    super.initState();
  }

  void _onPressed() async {
    if (widget.confirmationCallback != null) {
      final isConfirmed = await widget.confirmationCallback?.call();
      if (!(isConfirmed ?? false)) return;
    }

    if (widget._buttonType == _ButtonType.sync) {
      widget.onPressed?.call();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await widget.onPressed?.call();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: widget.style,
      onPressed: !_isLoading ? _onPressed : null,
      child: Center(
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 3.0,
                ),
              )
            : widget.child,
      ),
    );
  }
}
