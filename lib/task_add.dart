import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'helper/categories_data.dart';
import 'helper/project_data.dart';
import 'helper/task_data.dart';
import 'helper/task_type_data.dart';

class TaskAdd extends StatefulWidget {
  final String? taskStatusId;
  final ProjectData? project;
  final CategoryData? category;

  const TaskAdd({Key? key, this.project, this.taskStatusId, this.category})
      : super(key: key);

  @override
  TaskAddState createState() => TaskAddState();
}

class TaskAddState extends State<TaskAdd> with RestorationMixin {
//StateLess --> chả có gì luôn hay thật --> cố định, nhưng nhanh
// StateFull có thay đổi
// class TaskAdd extends StatelessWidget {
  FocusNode? _title, _description;
  bool isLoading = false;
  final RestorableInt _autoValidateModeIndex =
      RestorableInt(AutovalidateMode.disabled.index);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TaskData taskData = TaskData();
  var taskTypes = [];
  List<PopupMenuEntry<String>> menu = [];
  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
    ));
  }

  @override
  void initState() {
    super.initState();
    _title = FocusNode();
    _description = FocusNode();
    getTaskTypes(widget.project!.id);
  }

  @override
  void dispose() {
    _title!.dispose();
    _description!.dispose();
    super.dispose();
  }

  @override
  String get restorationId => 'task_add_screen';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_autoValidateModeIndex, 'autovalidate_mode');
  }

  void _handleSubmitted() {
    final form = _formKey.currentState;
    if (!form!.validate()) {
      _autoValidateModeIndex.value =
          AutovalidateMode.always.index; // Start validating on every change.
      // showInSnackBar(
      //   'Chưa nhấn nút submit',
      // );
    } else {
      form.save();
      String taskStatus = widget.taskStatusId!;

      createTask(taskStatus);
      //showInSnackBar("Tên:" + person.name + "SĐT:" + person.phoneNumber);
    }
  }

  Future<void> createTask(String taskStatus) async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    final response = await http.post(
        Uri.parse('http://www.vietinrace.com/srvTD/addTaskPost/'),
        headers: {
          //'Content-Type': 'application/json; charset=UTF-8',
          "Content-Type": "application/x-www-form-urlencoded",
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'name': taskData.name,
          'description': taskData.description,
          'status': taskStatus,
          'profit': taskData.profit.toString(),
          'project': '',
          'email': prefs.getString('email'),
          'category': '',
          'type': ''
        });

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var status = json['data'][0]['status'];
      var msg = json['data'][0]['msg'];
      showInSnackBar(msg);
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
    Navigator.pop(context);
  }

  Future<void> getTaskTypes(String project) async {
    taskTypes = [];
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    var url = 'http://www.vietinrace.com/srvTD/getTaskTypesProject/' + project;
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      for (var dat in data) {
        TaskTypeData taskType = TaskTypeData();
        taskType.name = dat['name'];
        taskType.id = dat['id'];
        taskType.code = dat['code'];
        taskTypes.add(taskType);
      }
      for (int i = 0; i < taskTypes.length; i++) {
        var menuItem = PopupMenuItem<String>(
            value: taskTypes[i].id,
            child: ListTile(
                // leading: const Icon(Icons.visibility),
                title: Text(
              taskTypes[i].name,
            )));
        menu.add(menuItem);
      }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  String? _validateTitle(String? value) {
    if (value!.isEmpty) {
      return 'Bạn cần nhập tên công việc';
    }
    //final nameExp = RegExp(r'^[A-Za-z ]+$');
    // if (!nameExp.hasMatch(value)) {
    //   return 'Chỉ chứa các ký tự Alphabeta';
    // }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const sizedBoxSpace = SizedBox(height: 24);

    return Scaffold(
        body: SizedBox(
      height: 600,
      child: Column(
        children: [
          const SizedBox(
            height: 50,
            child: Center(
              child: Text(
                'Thêm công việc mới',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const Divider(thickness: 1),
          Form(
            key: _formKey,
            autovalidateMode:
                AutovalidateMode.values[_autoValidateModeIndex.value],
            child: Scrollbar(
              child: SingleChildScrollView(
                restorationId: 'task_add_scroll_view',
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    TextFormField(
                      restorationId: 'title_field',
                      textInputAction: TextInputAction.next,
                      focusNode: _title,
                      decoration: const InputDecoration(
                        filled: true,
                        // icon: Icon(Icons.email),
                        hintText: 'Nhập tiêu đề ',
                        labelText: 'Tiêu đề',
                      ),
                      // keyboardType: TextInputType.emailAddress,
                      onSaved: (value) {
                        taskData.name = value!;
                        _description!.requestFocus();
                      },
                      validator: _validateTitle,
                    ),
                    sizedBoxSpace,
                    TextFormField(
                      restorationId: 'description_field',
                      focusNode: _description,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Nhập mô tả ngắn về công việc',
                        helperText: 'Ngắn thôi ',
                        labelText: 'Mô tả công việc',
                      ),
                      maxLines: 3,
                      onSaved: (value) {
                        taskData.description = value!;
                        // _description!.requestFocus();
                      },
                      // onFieldSubmitted: (value) {
                      //   _handleSubmitted();
                      // },
                    ),
                    sizedBoxSpace,
                    TextFormField(
                      restorationId: 'profit_field',
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Lợi nhuận',
                        suffixText: 'VNĐ',
                      ),
                      maxLines: 1,
                      onSaved: (value) {
                        taskData.profit = double.parse(value!);
                        // _description!.requestFocus();
                      },
                    ),
                    sizedBoxSpace,
                    IconButton(
                        icon: Icon(Icons.directions_bus),
                        onPressed: () {
                          print("Pressed");
                        }),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      onSelected: (value) =>
                          showInSnackBar("Bạn chọn là: ${value}"),
                      itemBuilder: (context) => menu,
                    ),
                    sizedBoxSpace,
                    !isLoading
                        ? Center(
                            child: ElevatedButton(
                              onPressed: _handleSubmitted,
                              child: const Text('Tạo'),
                            ),
                          )
                        : const Center(child: CircularProgressIndicator()),
                    sizedBoxSpace,
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    ));
  }
}
