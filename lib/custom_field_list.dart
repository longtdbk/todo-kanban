import 'dart:async';
import 'dart:collection';
import 'dart:convert';
// import 'dart:html';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'package:flutter/gestures.dart' show DragStartBehavior;

import 'helper/categories_data.dart';
import 'helper/custom_field_data.dart';
import 'helper/project_data.dart';
import 'helper/task_data.dart';

import 'package:http/http.dart' as http;

// class TaskListScreen extends StatelessWidget {
//   final ProjectData? project;
//   final CategoryData? category;

//   const TaskListScreen({Key? key, this.project, this.category})
//       : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Quản trị công việc',
//         ),
//         leading: IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.black),
//             onPressed: () => Navigator.of(context).pushReplacement(
//                 MaterialPageRoute(
//                     builder: (BuildContext context) => const DashboardPage()))),
//         automaticallyImplyLeading: false,
//         //title: Text('Login'),
//       ),
//       body: TaskList(project: project, category: category),
//     );
//   }
// }

class CustomFieldList extends StatefulWidget {
  final ProjectData? project;
  final CategoryData? category;
  const CustomFieldList({Key? key, this.project, this.category})
      : super(key: key);

  @override
  CustomFieldListState createState() => CustomFieldListState();
}

class CustomFieldListState extends State<CustomFieldList> {
  // with SingleTickerProviderStateMixin, RestorationMixin {
  var projects = [];
  var fields = [];
  CustomFieldData fieldData = CustomFieldData();
  //var tasksMap = [];
  HashMap fieldsMap = HashMap<String, List<TaskData>>();

  var taskStatuses = [];
  bool isLoading = false;
  String project = '';
  String typeCustomField = 'list';
  @override
  void initState() {
    super.initState();
    project = widget.project!.id;
    getCustomFieldsProject(project);
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
    ));
  }

  // sau phải theo user nữa chứ ko phải chỉ thế này đâu ??
  Future<void> getCustomFieldsProject(String project) async {
    fields = [];
    setState(() {
      isLoading = true;
    });

    // final prefs = await SharedPreferences.getInstance();

    var url = 'http://www.vietinrace.com/srvTD/getCustomField/' + project;
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      for (var dat in data) {
        CustomFieldData field = CustomFieldData();
        field.name = dat['name'];
        field.code = dat['name'];
        field.id = dat['id'];
        field.type = dat['type'];
        field.desc = dat['description'];
        field.value = dat['value'];
        fields.add(field);
      }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  //edit customfield includes (edit Value, add Value )
  Future<void> editCustomFieldValue(
      int index, String value, String option) async {
    setState(() {
      isLoading = true;
    });
    // final prefs = await SharedPreferences.getInstance();

    final response = await http.post(
        Uri.parse('http://www.vietinrace.com/srvTD/editCustomField/'),
        headers: {
          //'Content-Type': 'application/json; charset=UTF-8',
          "Content-Type": "application/x-www-form-urlencoded",
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'project': widget.project!.id,
          'option': option,
          'value': value,
          'field': fields[index].id
        });

    getCustomFieldsProject(widget.project!.id);
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      // var status = json['data'][0]['status'];
      var msg = json['data'][0]['msg'];
      showInSnackBar(msg);
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  //edit customfield includes (edit Value, add Value )
  Future<void> addCustomFieldValue(
      String fieldName, String desc, String type) async {
    setState(() {
      isLoading = true;
    });

    // final prefs = await SharedPreferences.getInstance();

    final response = await http.post(
        Uri.parse('http://www.vietinrace.com/srvTD/addCustomFieldPost/'),
        headers: {
          //'Content-Type': 'application/json; charset=UTF-8',
          "Content-Type": "application/x-www-form-urlencoded",
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'project': widget.project!.id,
          'field_name': fieldName,
          'field_desc': desc,
          'field_type': type,
          'field_value': "{}",
        });

    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      // var status = json['data'][0]['status'];
      var msg = json['data'][0]['msg'];
      showInSnackBar(msg);
      getCustomFieldsProject(widget.project!.id);
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  void editFieldName(int index) {
    TextEditingController editingController =
        TextEditingController(text: fields[index].name);
    showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
              title: const Text('Sửa tên trường'),
              content: Container(
                height: 80,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                child: CupertinoTextField(
                  controller: editingController,
                  autofocus: true,
                ),
              ),
              actions: <Widget>[
                CupertinoDialogAction(
                  child: const Text('Cancel'),
                  isDestructiveAction: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoDialogAction(
                    child: const Text('Update'),
                    isDefaultAction: true,
                    onPressed: () {
                      if (editingController.text.isNotEmpty) {
                        //setState(() {});
                        editCustomFieldValue(
                            index, editingController.text, "0");
                      }
                      Navigator.of(context).pop();
                    }),
              ]);
        });
  }

  void addFieldValue(int index) {
    TextEditingController editingController = TextEditingController(text: '');
    showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
              title: const Text('Thêm giá trị'),
              content: Container(
                height: 80,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                child: CupertinoTextField(
                  controller: editingController,
                  autofocus: true,
                ),
              ),
              actions: <Widget>[
                CupertinoDialogAction(
                  child: const Text('Cancel'),
                  isDestructiveAction: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoDialogAction(
                    child: const Text('Update'),
                    isDefaultAction: true,
                    onPressed: () {
                      if (editingController.text.isNotEmpty) {
                        // setState(() {});
                        processAddFieldValue(index, editingController.text);
                      }
                      Navigator.of(context).pop();
                    }),
              ]);
        });
  }

  void editFieldValue(int index, int indexChild, String value) {
    TextEditingController editingController =
        TextEditingController(text: value);
    showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
              title: const Text('Sửa giá trị'),
              content: Container(
                height: 80,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                child: CupertinoTextField(
                  controller: editingController,
                  autofocus: true,
                ),
              ),
              actions: <Widget>[
                CupertinoDialogAction(
                  child: const Text('Cancel'),
                  isDestructiveAction: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoDialogAction(
                    child: const Text('Update'),
                    isDefaultAction: true,
                    onPressed: () {
                      if (editingController.text.isNotEmpty) {
                        // setState(() {});
                        processEditFieldValue(
                            index, indexChild, editingController.text);
                      }
                      Navigator.of(context).pop();
                    }),
              ]);
        });
  }

  Future<void> showBottomModalAddField() async {
    List<DropdownMenuItem<String>> menuType = [];
    var menuItem = const DropdownMenuItem<String>(
      value: 'list',
      child: Text('Danh sách - List'),
    );
    menuType.add(menuItem);

    var menuItem2 = const DropdownMenuItem<String>(
      value: 'number',
      child: Text('Số - Có vẽ biểu đồ'),
    );
    menuType.add(menuItem2);

    var menuItem3 = const DropdownMenuItem<String>(
      value: 'text',
      child: Text('Văn bản - Text'),
    );
    menuType.add(menuItem3);

    // da hieu roi day --> phai cho vao trong builder ???
    String? message = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return CustomBottomSheet(projectId: widget.project!.id);
          // return StatefulBuilder(builder: (context, StateSetter setState) {
          //   String name = "";
          //   String desc = "";
          //   String type = "list";
          //   return Padding(
          //       padding: MediaQuery.of(context).viewInsets,
          //       child: SizedBox(
          //           height: 400,
          //           child: Column(children: <Widget>[
          //             Padding(
          //                 padding: const EdgeInsets.all(15),
          //                 child: TextField(
          //                   onChanged: (value) => {name = value},
          //                   //controller: editingController,
          //                   decoration: const InputDecoration(
          //                     border: OutlineInputBorder(),
          //                     labelText: 'Tên trường',
          //                   ),
          //                 )),
          //             Row(children: [
          //               const SizedBox(width: 20),
          //               const Text('Thể loại'),
          //               const SizedBox(width: 20),
          //               DropdownButton<String>(
          //                   value: type,
          //                   icon: const Icon(Icons.arrow_downward),
          //                   elevation: 16,
          //                   style: const TextStyle(color: Colors.deepPurple),
          //                   underline: Container(
          //                     height: 2,
          //                     color: Colors.deepPurpleAccent,
          //                   ),
          //                   onChanged: (String? newValue) {
          //                     setState(() {
          //                       type = newValue!;
          //                     });
          //                   },
          //                   items: menuType)
          //             ]),
          //             Padding(
          //               padding: const EdgeInsets.all(15),
          //               child: TextField(
          //                 onChanged: (value) => {desc = value},
          //                 decoration: const InputDecoration(
          //                   border: OutlineInputBorder(),
          //                   labelText: 'Mô tả',
          //                 ),
          //               ),
          //             ),
          //             ElevatedButton(
          //               child: const Text('Tạo'),
          //               onPressed: () {
          //                 if (name != "") {
          //                   addCustomFieldValue(name, desc, type);
          //                   Navigator.of(context).pop();
          //                 }
          //               },
          //             )
          //           ])));
          // });
        });
    showInSnackBar(message!);
    //.whenComplete(() {
    // });
    //print("test:" + test!);
    getCustomFieldsProject(widget.project!.id);
  }

  void processAddFieldValue(int fieldIndex, String value) {
    String oldValue = fields[fieldIndex].value;
    var data = jsonDecode(oldValue.replaceAll("'", "\""));

    String newValue = oldValue.substring(0, oldValue.length - 1);
    if (data.length > 0) {
      newValue += ",";
    }
    newValue += "'" + (data.length + 1).toString() + "':'" + value + "'}";
    editCustomFieldValue(fieldIndex, newValue, "1");
  }

  void processEditFieldValue(
      int fieldIndex, int fieldValueIndex, String value) {
    String oldValue = fields[fieldIndex].value;
    var data = jsonDecode(oldValue.replaceAll("'", "\""));
    data[fieldValueIndex.toString()] = value;
    String newValue = "{";
    for (int i = 1; i <= data.length; i++) {
      newValue += "'" + i.toString() + "':'" + data[i.toString()] + "',";
    }
    newValue = newValue.substring(0, newValue.length - 1) + "}";

    editCustomFieldValue(fieldIndex, newValue, "1");
  }

  Widget _itemTraling(int index) {
    List<PopupMenuEntry<String>> menu = [];

    if (fields[index].type == 'list') {
      var menuItem = const PopupMenuItem<String>(
          value: "add",
          child: ListTile(
              // leading: const Icon(Icons.visibility),
              title: Text(
            'Thêm giá trị mới',
          )));
      menu.add(menuItem);
    }

    var menuItem2 = const PopupMenuItem<String>(
        value: "edit",
        child: ListTile(
            // leading: const Icon(Icons.visibility),
            title: Text(
          'Sửa tên',
        )));
    menu.add(menuItem2);

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      onSelected: (value) => {
        // showInSnackBar("Bạn chọn là: ${value}")
        value == "edit" ? editFieldName(index) : addFieldValue(index)
      },
      itemBuilder: (context) => menu,
    );
  }

  Widget _itemChildTraling(int index, int indexChild, String fieldValue) {
    List<PopupMenuEntry<String>> menu = [];

    var menuItem = const PopupMenuItem<String>(
        value: "edit",
        child: ListTile(
            // leading: const Icon(Icons.visibility),
            title: Text(
          'Sửa',
        )));
    menu.add(menuItem);

    var menuItem2 = const PopupMenuItem<String>(
        value: "delete",
        child: ListTile(
            // leading: const Icon(Icons.visibility),
            title: Text(
          'Xóa',
        )));
    menu.add(menuItem2);

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      onSelected: (value) => {
        // showInSnackBar("Bạn chọn là: ${value}")
        editFieldValue(index, indexChild, fieldValue)
      },
      itemBuilder: (context) => menu,
    );
  }

  // int _current = 0;

  // List<Widget> lists = [];

  List<Widget> buildList() {
    List<Widget> list = [];
    if (isLoading) {
      list.add(const Center(child: LinearProgressIndicator()));
    } else {
      for (int index = 0; index < fields.length; index++) {
        //ProjectData project = (ProjectData)projects[i];
        ListTile item = ListTile(
            leading: ExcludeSemantics(
              child: CircleAvatar(child: Text('${index + 1}')),
            ),
            title: Text(
              fields[index].name,
            ),
            subtitle: Text('Loại: ' + fields[index].type),
            trailing: _itemTraling(index),
            onTap: () {});
        list.add(item);
        list.add(const Divider()); //
        var data = jsonDecode(fields[index].value.replaceAll("'", "\""));

        for (int i = 1; i <= data.length; i++) {
          ListTile itemChild = ListTile(
              leading: ExcludeSemantics(
                  // child: CircleAvatar(child: Text('${i + 1}')),
                  child: Container(
                      padding: const EdgeInsets.only(left: 20),
                      child: const Icon(Icons.circle_outlined))),
              //contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text(
                data[i.toString()],
              ),
              trailing: _itemChildTraling(index, i, data[i.toString()]),
              onTap: () {});
          list.add(itemChild);
          list.add(const Divider()); //
        }
      }
      list.add(FloatingActionButton(
        onPressed: () {
          showBottomModalAddField();
        },
        tooltip: 'Tạo trường mới',
        child: const Icon(Icons.add),
      ));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    //const sizedBoxSpace = SizedBox(height: 24);
    //const sizedBoxWidth = SizedBox(width: 18);
    // cái này là từng Item đây này :)

    return RefreshIndicator(
        onRefresh: () async {
          //Do whatever you want on refresh.Usually update the data of the listview
          getCustomFieldsProject(project);
        },
        child: Scrollbar(
          child: ListView(
            restorationId: 'project_list_view',
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: buildList(),
          ),
        ),
        color: Colors.white,
        backgroundColor: Colors.red);
  }
}

class CustomBottomSheet extends StatefulWidget {
  final String? projectId;
  const CustomBottomSheet({Key? key, this.projectId}) : super(key: key);
  @override
  _CustomBottomSheetState createState() => _CustomBottomSheetState();
}

class _CustomBottomSheetState extends State<CustomBottomSheet> {
  List<DropdownMenuItem<String>> menuType = [];

  String name = "";
  String desc = "";
  String type = "list";
  bool isLoading = false;

  // void showInSnackBar(String value) {
  //   ScaffoldMessenger.of(context).hideCurrentSnackBar();
  //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //     content: Text(value),
  //   ));
  // }

  Future<void> addCustomFieldValue(
      String fieldName, String desc, String type) async {
    setState(() {
      isLoading = true;
    });

    // final prefs = await SharedPreferences.getInstance();

    final response = await http.post(
        Uri.parse('http://www.vietinrace.com/srvTD/addCustomFieldPost/'),
        headers: {
          //'Content-Type': 'application/json; charset=UTF-8',
          "Content-Type": "application/x-www-form-urlencoded",
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'project': widget.projectId,
          'field_name': fieldName,
          'field_desc': desc,
          'field_type': type,
          'field_value': "{}",
        });

    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      // var status = json['data'][0]['status'];
      var msg = json['data'][0]['msg'];
      // showInSnackBar(msg);
      //getCustomFieldsProject(widget.project!.id);
      Navigator.of(context).pop(msg);
    } else {
      // showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  @override
  Widget build(BuildContext context) {
    menuType = [];
    var menuItem = const DropdownMenuItem<String>(
      value: 'list',
      child: Text('Danh sách - List'),
    );
    menuType.add(menuItem);

    var menuItem2 = const DropdownMenuItem<String>(
      value: 'number',
      child: Text('Số - Có vẽ biểu đồ'),
    );
    menuType.add(menuItem2);

    var menuItem3 = const DropdownMenuItem<String>(
      value: 'text',
      child: Text('Văn bản - Text'),
    );
    menuType.add(menuItem3);

    return Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: SizedBox(
            height: 400,
            child: Column(children: <Widget>[
              Padding(
                  padding: const EdgeInsets.all(15),
                  child: TextField(
                    onChanged: (value) => {name = value},
                    //controller: editingController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Tên trường',
                    ),
                  )),
              Row(children: [
                const SizedBox(width: 20),
                const Text('Thể loại'),
                const SizedBox(width: 20),
                DropdownButton<String>(
                    value: type,
                    icon: const Icon(Icons.arrow_downward),
                    elevation: 16,
                    style: const TextStyle(color: Colors.deepPurple),
                    underline: Container(
                      height: 2,
                      color: Colors.deepPurpleAccent,
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        type = newValue!;
                      });
                    },
                    items: menuType)
              ]),
              Padding(
                padding: const EdgeInsets.all(15),
                child: TextField(
                  onChanged: (value) => {desc = value},
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Mô tả',
                  ),
                ),
              ),
              ElevatedButton(
                child: const Text('Tạo'),
                onPressed: () {
                  if (name != "") {
                    addCustomFieldValue(name, desc, type);
                  }
                },
              )
            ])));
  }
}
