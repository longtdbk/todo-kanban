import 'package:flutter/material.dart';

// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/services.dart';

import 'helper/password_field.dart';
import 'helper/person_data.dart';
import 'login.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (BuildContext context) => const LoginScreen()))),
        automaticallyImplyLeading: false,
        //title: Text('Login'),
      ),
      body: const RegisterField(),
    );
  }
}

class RegisterField extends StatefulWidget {
  const RegisterField({Key? key}) : super(key: key);

  @override
  RegisterFieldState createState() => RegisterFieldState();
}

class RegisterFieldState extends State<RegisterField> with RestorationMixin {
  PersonData person = PersonData();

  FocusNode? _phoneNumber, _email, _lifeStory, _password, _retypePassword;

  @override
  void initState() {
    super.initState();
    _phoneNumber = FocusNode();
    _email = FocusNode();
    _lifeStory = FocusNode();
    _password = FocusNode();
    _retypePassword = FocusNode();
  }

  @override
  void dispose() {
    _phoneNumber!.dispose();
    _email!.dispose();
    _lifeStory!.dispose();
    _password!.dispose();
    _retypePassword!.dispose();
    super.dispose();
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
    ));
  }

  @override
  String get restorationId => 'text_field_demo';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_autoValidateModeIndex, 'autovalidate_mode');
  }

  final RestorableInt _autoValidateModeIndex =
      RestorableInt(AutovalidateMode.disabled.index);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormFieldState<String>> _passwordFieldKey =
      GlobalKey<FormFieldState<String>>();
  final _VNNumberTextInputFormatter _phoneNumberFormatter =
      _VNNumberTextInputFormatter();

  void _handleSubmitted() {
    final form = _formKey.currentState;
    if (!form!.validate()) {
      _autoValidateModeIndex.value =
          AutovalidateMode.always.index; // Start validating on every change.
      showInSnackBar(
        'Chưa nhấn nút submit',
      );
    } else {
      form.save();
      showInSnackBar("Tên:" + person.name + "SĐT:" + person.phoneNumber);
    }
  }

  String? _validateName(String? value) {
    if (value!.isEmpty) {
      return 'Bạn cần nhập tên';
    }
    final nameExp = RegExp(r'^[A-Za-z ]+$');
    if (!nameExp.hasMatch(value)) {
      return 'Chỉ chứa các ký tự Alphabeta';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    final phoneExp = RegExp(r'^\(\d\d\d\) \d\d\d\-\d\d\d\d$');
    if (!phoneExp.hasMatch(value!)) {
      return 'Chưa đúng định dạng số điện thoại';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final passwordField = _passwordFieldKey.currentState;
    if (passwordField!.value == null || passwordField.value!.isEmpty) {
      return 'Chưa nhập Mật khẩu ';
    }
    if (passwordField.value != value) {
      return 'Mật khẩu không trùng nhau';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const sizedBoxSpace = SizedBox(height: 24);

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.values[_autoValidateModeIndex.value],
      child: Scrollbar(
        child: SingleChildScrollView(
          restorationId: 'text_field_demo_scroll_view',
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              sizedBoxSpace,
              TextFormField(
                restorationId: 'name_field',
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  filled: true,
                  icon: Icon(Icons.person),
                  hintText: 'Tên của bạn',
                  labelText: 'Tên',
                ),
                onSaved: (value) {
                  person.name = value!;
                  _phoneNumber!.requestFocus();
                },
                validator: _validateName,
              ),
              sizedBoxSpace,
              TextFormField(
                restorationId: 'phone_number_field',
                textInputAction: TextInputAction.next,
                focusNode: _phoneNumber,
                decoration: const InputDecoration(
                  filled: true,
                  icon: Icon(Icons.phone),
                  hintText: 'Nhập số điện thoại liên lạc',
                  labelText: 'Số điện thoại',
                  prefixText: '+84 ',
                ),
                keyboardType: TextInputType.phone,
                onSaved: (value) {
                  person.phoneNumber = value!;
                  _email!.requestFocus();
                },
                maxLength: 14,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                validator: _validatePhoneNumber,
                // TextInputFormatters are applied in sequence.
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  // Fit the validating format.
                  _phoneNumberFormatter,
                ],
              ),
              sizedBoxSpace,
              TextFormField(
                restorationId: 'email_field',
                textInputAction: TextInputAction.next,
                focusNode: _email,
                decoration: const InputDecoration(
                  filled: true,
                  icon: Icon(Icons.email),
                  hintText: 'Địa chỉ email của bạn',
                  labelText: 'Email',
                ),
                keyboardType: TextInputType.emailAddress,
                onSaved: (value) {
                  person.email = value!;
                  _lifeStory!.requestFocus();
                },
              ),
              sizedBoxSpace,
              TextFormField(
                restorationId: 'life_story_field',
                focusNode: _lifeStory,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Kể cho chúng tôi nghe về bạn nhé',
                  helperText: 'Ngắn thôi, đây là demo',
                  labelText: 'Life story',
                ),
                maxLines: 3,
              ),
              sizedBoxSpace,
              TextFormField(
                restorationId: 'salary_field',
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Lương',
                  suffixText: 'VNĐ',
                ),
                maxLines: 1,
              ),
              sizedBoxSpace,
              PasswordField(
                restorationId: 'password_field',
                textInputAction: TextInputAction.next,
                focusNode: _password,
                fieldKey: _passwordFieldKey,
                helperText: 'Không hơn 8 ký tự',
                labelText: 'Mật khẩu',
                onSaved: (value) {
                  setState(() {
                    person.password = value!;
                    _retypePassword!.requestFocus();
                  });
                },
              ),
              sizedBoxSpace,
              TextFormField(
                restorationId: 'retype_password_field',
                focusNode: _retypePassword,
                decoration: const InputDecoration(
                  filled: true,
                  icon: Icon(Icons.password_rounded),
                  labelText: 'Gõ lại mật khẩu ',
                ),
                maxLength: 8,
                obscureText: true,
                validator: _validatePassword,
                onFieldSubmitted: (value) {
                  _handleSubmitted();
                },
              ),
              sizedBoxSpace,
              Center(
                child: ElevatedButton(
                  onPressed: _handleSubmitted,
                  child: const Text('Submit'),
                ),
              ),
              sizedBoxSpace,
              Text(
                '* Các trường bắt buộc',
                style: Theme.of(context).textTheme.caption,
              ),
              sizedBoxSpace,
            ],
          ),
        ),
      ),
    );
  }
}

/// Format incoming numeric text to fit the format of (###) ###-#### ##
class _VNNumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newTextLength = newValue.text.length;
    final newText = StringBuffer();
    var selectionIndex = newValue.selection.end;
    var usedSubstringIndex = 0;
    if (newTextLength >= 1) {
      newText.write('(');
      if (newValue.selection.end >= 1) selectionIndex++;
    }
    if (newTextLength >= 4) {
      newText.write(newValue.text.substring(0, usedSubstringIndex = 3) + ') ');
      if (newValue.selection.end >= 3) selectionIndex += 2;
    }
    if (newTextLength >= 7) {
      newText.write(newValue.text.substring(3, usedSubstringIndex = 6) + '-');
      if (newValue.selection.end >= 6) selectionIndex++;
    }
    if (newTextLength >= 11) {
      newText.write(newValue.text.substring(6, usedSubstringIndex = 10) + ' ');
      if (newValue.selection.end >= 10) selectionIndex++;
    }
    // Dump the rest.
    if (newTextLength >= usedSubstringIndex) {
      newText.write(newValue.text.substring(usedSubstringIndex));
    }
    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
