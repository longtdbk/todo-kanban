import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/services.dart';
import 'package:kanban_dashboard/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helper/categories_data.dart';
import 'category_list.dart';
import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart' as http;

class CategoryAddScreen extends StatelessWidget {
  const CategoryAddScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thêm dự án',
        ),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (BuildContext context) => const DashboardPage()))),
        automaticallyImplyLeading: false,
      ),
      body: const CategoryAdd(),
    );
  }
}

class CategoryAdd extends StatefulWidget {
  const CategoryAdd({Key? key}) : super(key: key);

  @override
  CategoryAddState createState() => CategoryAddState();
}

// cái này mục tiêu là hiện hay ẩn --> tạo thành 1 file mới thôi (helper)

class CategoryAddState extends State<CategoryAdd> with RestorationMixin {
  CategoryData Category = CategoryData();

  FocusNode? _name;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _name = FocusNode();
  }

  @override
  void dispose() {
    _name!.dispose();
    super.dispose();
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
    ));
  }

  @override
  String get restorationId => 'category_field';

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
      checkCreateCategory();
      //showInSnackBar("Tên:" + person.email + " Đăng nhập thành công ");
    }
  }

  Future<void> checkCreateCategory() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    final response = await http.post(
        Uri.parse('http://www.vietinrace.com/srvTD/addCategoryPost/'),
        headers: {
          //'Content-Type': 'application/json; charset=UTF-8',
          "Content-Type": "application/x-www-form-urlencoded",
        },
        encoding: Encoding.getByName('utf-8'),
        body: {'name': Category.name, 'email': prefs.getString("email")!});

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      // return {
      var json = jsonDecode(response.body);
      var status = json['data'][0]['status'];
      var msg = json['data'][0]['msg'];
      showInSnackBar(msg);
      if (status == "true") {
        Timer(Duration(seconds: 2), () => _routeToCategoryList());
      }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  void _routeToCategoryList() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (BuildContext context) => const CategoryListScreen()));
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
          restorationId: 'category_name_field_scroll_view',
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              sizedBoxSpace,
              TextFormField(
                restorationId: 'category_name_field',
                textInputAction: TextInputAction.next,
                focusNode: _name,
                decoration: const InputDecoration(
                  filled: true,
                  icon: Icon(Icons.new_label),
                  hintText: 'Tên Danh Mục',
                  labelText: 'Danh Mục',
                ),
                keyboardType: TextInputType.name,
                onSaved: (value) {
                  Category.name = value!;
                  //_password!.requestFocus();
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
                            child: const Text('Tạo'),
                          ),
                          sizedBoxWidth,
                          ElevatedButton(
                            onPressed: _routeToCategoryList,
                            child: const Text('Bỏ qua'),
                          ),
                        ]))
                  : const Center(child: CircularProgressIndicator()),
              sizedBoxSpace,
              Text(
                '* Là các trường bắt buộc',
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
