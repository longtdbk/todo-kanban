import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'helper/password_field.dart';
import 'helper/person_data.dart';
import 'login.dart';
import 'package:http/http.dart' as http;

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
  bool isLoading = false;

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
  // final _VNNumberTextInputFormatter _phoneNumberFormatter =
  //     _VNNumberTextInputFormatter();

  DateTime date = DateTime.now();
  String gender = "nam";

  Future<void> registerUser() async {
    setState(() {
      isLoading = true;
    });

    // final prefs = await SharedPreferences.getInstance();
    var outputFormat = DateFormat('dd/MM/yyyy');
    var birthDate = outputFormat.format(date);

    final response = await http.post(
        Uri.parse('http://www.vietinrace.com/srvTD/registerUser/'),
        headers: {
          //'Content-Type': 'application/json; charset=UTF-8',
          "Content-Type": "application/x-www-form-urlencoded",
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'user_gender': gender,
          'user_birthday': birthDate,
          'user_password': person.password,
          'user_name': person.name,
          'user_email': person.email,
        });
    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var status = json['data'][0]['status'];
      var msg = json['data'][0]['msg'];
      showInSnackBar(msg);
      if (status == "true") {
        Timer(
            const Duration(seconds: 2),
            () => Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (BuildContext context) => const LoginScreen())));
      }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
    // Navigator.pop(context);
  }

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
      registerUser();
      // showInSnackBar("Tên:" + person.name + "SĐT:" + person.phoneNumber);
    }
  }

  String? _validateName(String? value) {
    if (value!.isEmpty) {
      return 'Bạn cần nhập tên';
    }
    // final nameExp = RegExp(r'^[A-Za-z ]+$');
    // if (!nameExp.hasMatch(value)) {
    //   return 'Chỉ chứa các ký tự Alphabeta';
    // }
    return null;
  }

  // String? _validatePhoneNumber(String? value) {
  //   final phoneExp = RegExp(r'^\(\d\d\d\) \d\d\d\-\d\d\d\d$');
  //   if (!phoneExp.hasMatch(value!)) {
  //     return 'Chưa đúng định dạng số điện thoại';
  //   }
  //   return null;
  // }

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

  void _showPicker({
    @required BuildContext? context,
    @required Widget? child,
  }) {
    final themeData = CupertinoTheme.of(context!);
    final dialogBody = CupertinoTheme(
      data: themeData,
      child: child!,
    );

    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => dialogBody,
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showPicker(
          context: context,
          child: _BottomPicker(
            child: CupertinoDatePicker(
              backgroundColor:
                  CupertinoColors.systemBackground.resolveFrom(context),
              mode: CupertinoDatePickerMode.date,
              initialDateTime: date,
              onDateTimeChanged: (newDateTime) {
                setState(() => date = newDateTime);
              },
            ),
          ),
        );
      },
      child: _Menu(children: [
        //const Icon(Icons.access_time_outlined),
        const Text('Ngày sinh'),
        Text(
          DateFormat.yMMMMd().format(date),
          style: const TextStyle(color: CupertinoColors.inactiveGray),
        ),
      ]),
    );
  }

  Widget _buildGenderDropDownList() {
    // tao cac truong
    List<String> data = [];
    data.add("Nam");
    data.add("Nữ");

    List<DropdownMenuItem<String>> menu = [];
    // var dropdownValue = "";
    for (int j = 0; j < data.length; j++) {
      var menuItem = DropdownMenuItem<String>(
        value: data[j].toLowerCase(),
        child: Text(data[j]),
      );
      menu.add(menuItem);
    }

    return Row(children: [
      const Text('Giới tính'),
      const SizedBox(width: 50),
      //dropdownValues.add(data['1']);
      DropdownButton<String>(
          value: gender,
          icon: const Icon(Icons.arrow_downward),
          elevation: 16,
          style: const TextStyle(color: Colors.deepPurple),
          underline: Container(
            height: 2,
            color: Colors.deepPurpleAccent,
          ),
          onChanged: (String? newValue) {
            setState(() {
              gender = newValue!;
            });
          },
          items: menu)
    ]);

    // return dropDownItem;
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
                  _email!.requestFocus();
                },
                validator: _validateName,
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
                  _password!.requestFocus();
                },
              ),
              sizedBoxSpace,
              _buildDatePicker(context),
              sizedBoxSpace,
              _buildGenderDropDownList(),
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
// class _VNNumberTextInputFormatter extends TextInputFormatter {
//   @override
//   TextEditingValue formatEditUpdate(
//     TextEditingValue oldValue,
//     TextEditingValue newValue,
//   ) {
//     final newTextLength = newValue.text.length;
//     final newText = StringBuffer();
//     var selectionIndex = newValue.selection.end;
//     var usedSubstringIndex = 0;
//     if (newTextLength >= 1) {
//       newText.write('(');
//       if (newValue.selection.end >= 1) selectionIndex++;
//     }
//     if (newTextLength >= 4) {
//       newText.write(newValue.text.substring(0, usedSubstringIndex = 3) + ') ');
//       if (newValue.selection.end >= 3) selectionIndex += 2;
//     }
//     if (newTextLength >= 7) {
//       newText.write(newValue.text.substring(3, usedSubstringIndex = 6) + '-');
//       if (newValue.selection.end >= 6) selectionIndex++;
//     }
//     if (newTextLength >= 11) {
//       newText.write(newValue.text.substring(6, usedSubstringIndex = 10) + ' ');
//       if (newValue.selection.end >= 10) selectionIndex++;
//     }
//     // Dump the rest.
//     if (newTextLength >= usedSubstringIndex) {
//       newText.write(newValue.text.substring(usedSubstringIndex));
//     }
//     return TextEditingValue(
//       text: newText.toString(),
//       selection: TextSelection.collapsed(offset: selectionIndex),
//     );
//   }
// }

class _BottomPicker extends StatelessWidget {
  const _BottomPicker({
    Key? key,
    @required this.child,
  })  : assert(child != null),
        super(key: key);

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 216,
      padding: const EdgeInsets.only(top: 6),
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: DefaultTextStyle(
        style: TextStyle(
          color: CupertinoColors.label.resolveFrom(context),
          fontSize: 22,
        ),
        child: GestureDetector(
          // Blocks taps from propagating to the modal sheet and popping.
          onTap: () {},
          child: SafeArea(
            top: false,
            child: child!,
          ),
        ),
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({
    Key? key,
    @required this.children,
  })  : assert(children != null),
        super(key: key);

  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: CupertinoColors.inactiveGray, width: 0),
          bottom: BorderSide(color: CupertinoColors.inactiveGray, width: 0),
        ),
      ),
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children!,
        ),
      ),
    );
  }
}
