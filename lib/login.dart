import 'dart:convert';

import 'package:flutter/material.dart';

// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/services.dart';
import 'package:kanban_dashboard/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helper/password_field.dart';
import 'helper/person_data.dart';
import 'register.dart';
import 'package:http/http.dart' as http;

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        //title: Text('Login'),
      ),
      body: const LoginField(),
    );
  }
}

class LoginField extends StatefulWidget {
  const LoginField({Key? key}) : super(key: key);

  @override
  LoginFieldState createState() => LoginFieldState();
}

// cái này mục tiêu là hiện hay ẩn --> tạo thành 1 file mới thôi (helper)

class LoginFieldState extends State<LoginField> with RestorationMixin {
  PersonData person = PersonData();

  FocusNode? _email, _password;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _email = FocusNode();
    _password = FocusNode();
  }

  @override
  void dispose() {
    _email!.dispose();
    _password!.dispose();
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

  void _handleSubmitted() {
    final form = _formKey.currentState;
    if (!form!.validate()) {
      _autoValidateModeIndex.value =
          AutovalidateMode.always.index; // Start validating on every change.
      showInSnackBar(
        'Chưa nhấn nút submit',
      );
    } else {
      form.save(); //lưu giữ liệu --> gọi thử service check user xem nào ?? :)
      checkUserPassword();
      //showInSnackBar("Tên:" + person.email + " Đăng nhập thành công ");
    }
  }

  Future<void> checkUserPassword() async {
    setState(() {
      isLoading = true;
    });

    final response =
        await http.post(Uri.parse('http://www.vietinrace.com/srvTD/checkUser/'),
            headers: {
              //'Content-Type': 'application/json; charset=UTF-8',
              "Content-Type": "application/x-www-form-urlencoded",
            },
            encoding: Encoding.getByName('utf-8'),
            body: {
              'email': person.email,
              'password': person.password,
            });

    // var url = 'http://www.vietinrace.com/srvTD/checkUser/' +
    //     person.email +
    //     '/' +
    //     person.password;

    // final response = await http
    //     //.get(Uri.parse('https://jsonplaceholder.typicode.com/albums/1'));
    //     .get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      //return {
      var json = jsonDecode(response.body);
      var msg = json['data']['msg'];
      if (msg == "OK") {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('email', person.email);

        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (BuildContext context) => const DashboardPage()));
      } else {
        showInSnackBar(msg);
      }
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
      //throw Exception('Failed to load album');
    }
  }

  void _routeToRegister() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (BuildContext context) => const RegisterScreen()));
  }

  String? _validatePassword(String? value) {
    final passwordField = _passwordFieldKey.currentState;
    if (passwordField!.value == null || passwordField.value!.isEmpty) {
      return 'Chưa nhập Mật khẩu ';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const sizedBoxSpace = SizedBox(height: 24);
    const sizedBoxWidth = SizedBox(width: 18);

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
              PasswordField(
                restorationId: 'password_field',
                textInputAction: TextInputAction.next,
                focusNode: _password,
                fieldKey: _passwordFieldKey,
                helperText: 'Nhấn ẩn/hiện mật khẩu',
                labelText: 'Mật khẩu',
                validator: _validatePassword,
                onSaved: (value) {
                  setState(() {
                    person.password = value!;
                  }
                      //  _handleSubmitted();
                      );
                },
              ),
              sizedBoxSpace,
              !isLoading
                  ? Center(
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          ElevatedButton(
                            onPressed: _handleSubmitted,
                            child: const Text('Đăng nhập'),
                          ),
                          sizedBoxWidth,
                          ElevatedButton(
                            onPressed: _routeToRegister,
                            child: const Text('Đăng ký'),
                          ),
                        ]))
                  : const Center(child: CircularProgressIndicator()),
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
