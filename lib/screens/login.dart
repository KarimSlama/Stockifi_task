import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/auth.dart';
import 'package:stocklio_flutter/utils/constants.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/widgets/common/base_button.dart';
import 'package:stocklio_flutter/widgets/common/version_text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameTextController = TextEditingController();
  final _passwordTextController = TextEditingController();

  final double _formWidth = 220;
  final double _formSpacing = 16;

  bool _currentState = false;
  bool? _isPasswordVisible = false;

  String? errorMessage;

  void _updateState() {
    var username = _usernameTextController.text;
    var password = _passwordTextController.text;

    var newState = username.isNotEmpty && password.isNotEmpty;

    if (_currentState == newState) return;

    setState(() {
      _currentState = newState;
    });
  }

  void _toggleShowPassword(isPasswordVisible) {
    setState(() {
      _isPasswordVisible = isPasswordVisible;
    });
  }

  void _login() async {
    var username = _usernameTextController.text;
    var password = _passwordTextController.text;

    final response = await context
        .read<AuthProvider>()
        .signInWithEmailAndPassword(email: username, password: password);

    if (response.hasError) {
      setState(() {
        errorMessage = response.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          Center(
            child: SizedBox(
              width: _formWidth,
              child: Column(
                children: [
                  const Expanded(
                    child: Center(
                      child: Image(
                        image: AssetImage('assets/images/logo.png'),
                      ),
                    ),
                  ),
                  Form(
                    onChanged: _updateState,
                    child: Column(
                      children: [
                        if (errorMessage != null)
                          Text(
                            errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        TextFormField(
                          controller: _usernameTextController,
                          decoration: InputDecoration(
                            hintText:
                                StringUtil.localize(context).hint_text_username,
                          ),
                        ),
                        SizedBox(height: _formSpacing),
                        TextFormField(
                          controller: _passwordTextController,
                          decoration: InputDecoration(
                            hintText:
                                StringUtil.localize(context).hint_text_password,
                          ),
                          obscureText: !_isPasswordVisible!,
                        ),
                        SizedBox(height: _formSpacing),
                        CheckboxListTile(
                          title: Text(
                              StringUtil.localize(context).label_show_password),
                          value: _isPasswordVisible,
                          onChanged: _toggleShowPassword,
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(height: _formSpacing),
                        StockifiButton.async(
                          onPressed: _currentState ? _login : null,
                          child:
                              Text(StringUtil.localize(context).label_sign_in),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      alignment: Alignment.bottomCenter,
                      padding: EdgeInsets.all(_formSpacing),
                      child: Text(
                          StringUtil.localize(context).label_stockifi_2022),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: SafeArea(
              child: SizedBox(
                width: Constants.navRailWidth,
                child: VersionText(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
