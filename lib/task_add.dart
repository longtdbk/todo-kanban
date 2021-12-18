import 'dart:collection';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kanban_dashboard/helper/custom_field_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'helper/task_data.dart';
import 'util/bottom_picker_custom.dart';

// Cả add cả edit luôn nhé ???
class TaskAdd extends StatefulWidget {
  final String? taskStatusId;
  final String? projectId;
  final String? categoryId;
  final TaskData? taskData;
  // final List<CustomFieldData>? fields;

  const TaskAdd({
    Key? key,
    this.projectId,
    this.taskStatusId,
    this.categoryId,
    this.taskData,
    // this.fields
  }) : super(key: key);

  @override
  TaskAddState createState() => TaskAddState();
}

class TaskAddState extends State<TaskAdd> {
//StateLess --> chả có gì luôn hay thật --> cố định, nhưng nhanh
// StateFull có thay đổi
// class TaskAdd extends StatelessWidget {

  var tasks = [];
  List<CustomFieldData> fields = [];

  var taskStatuses = [];

  bool isLoading = false;

  TaskData taskData = TaskData();
  var taskTypes = [];
  List<PopupMenuEntry<String>> menu = [];

  DateTime dateStart = DateTime.now();
  DateTime dateEstimate = DateTime.now();
  DateTime dateFinish = DateTime.now();

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
    ));
  }

  @override
  void initState() {
    if (widget.taskData != null) {
      //getTaskID(widget.taskId!);

    }
    getCustomFieldsProject();
    // getTaskTypes(widget.projectId!);
    super.initState();
  }

  Future<void> createTask(TaskData taskData) async {
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
          'status': taskData.status,
          'profit': taskData.profit.toString(),
          'project': widget.projectId!,
          'email': prefs.getString('email'),
          'category': widget.categoryId!,
          'custom_fields': taskData.customFields,
          'start_date': taskData.dateStart,
          'finish_date': '',
          'finish_estimate_date': taskData.dateFinishEstimate,
          'type': ''
        });
    //getTaskStatuses();
    // getProject();
    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      // var status = json['data'][0]['status'];
      var msg = json['data'][0]['msg'];
      showInSnackBar(msg);
      // Navigator.pop(context);
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
    //Navigator.pop(context);
  }

  // Future<void> getTaskTypes(String project) async {
  //   taskTypes = [];
  //   setState(() {
  //     isLoading = true;
  //   });

  //   // final prefs = await SharedPreferences.getInstance();

  //   var url = 'http://www.vietinrace.com/srvTD/getTaskTypesProject/' + project;
  //   final response = await http.get(Uri.parse(url));

  //   setState(() {
  //     isLoading = false;
  //   });
  //   if (response.statusCode == 200) {
  //     var json = jsonDecode(response.body);
  //     var data = json['data'];
  //     for (var dat in data) {
  //       TaskTypeData taskType = TaskTypeData();
  //       taskType.name = dat['name'];
  //       taskType.id = dat['id'];
  //       taskType.code = dat['code'];
  //       taskTypes.add(taskType);
  //     }
  //     for (int i = 0; i < taskTypes.length; i++) {
  //       var menuItem = PopupMenuItem<String>(
  //           value: taskTypes[i].id,
  //           child: ListTile(
  //               // leading: const Icon(Icons.visibility),
  //               title: Text(
  //             taskTypes[i].name,
  //           )));
  //       menu.add(menuItem);
  //     }
  //   } else {
  //     showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
  //   }
  // }

  Future<void> getCustomFieldsProject() async {
    fields = [];
    setState(() {
      isLoading = true;
    });

    // final prefs = await SharedPreferences.getInstance();

    var url =
        'http://www.vietinrace.com/srvTD/getCustomField/' + widget.projectId!;
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
        field.value = dat['value'];
        field.isUse = dat['isUse'];

        var data = jsonDecode(field.value.replaceAll("'", "\""));
        HashMap<String, String> values = HashMap<String, String>();
        for (int i = 1; i <= data.length; i++) {
          values[i.toString()] = data[i.toString()];
        }
        field.valueFields = values;
        // dropdownValues.add("");
        fields.add(field);
      }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Future<void> getTaskID(String taskId) async {
    setState(() {
      isLoading = true;
    });

    // final prefs = await SharedPreferences.getInstance();

    var url = 'http://www.vietinrace.com/srvTD/getTaskID/' + taskId;
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      for (var dat in data) {
        TaskData taskData = TaskData();
        taskData.name = dat['name'];
        taskData.description = dat['description'];
        taskData.customFields = dat['custom_fields'];
        taskData.status = dat['status'];
        taskData.category = dat['category'];
        //taskData.project = dat['project'];
        taskData.dateStart = dat['start_date'];
        taskData.dateFinishEstimate = dat['finish_estimate_date'];

        //{'dddd':'1','ddd':'2'}
        var dataFields =
            jsonDecode(taskData.customFields.replaceAll("'", "\""));
        // HashMap<String, String> values = HashMap<String, String>();
        // for (int i = 1; i <= dataFields.length; i++) {
        //   values[i.toString()] = data[i.toString()];
        // }
        //field.valueFields = values;
        // dropdownValues.add("");
      }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Future<void> updateTaskID(TaskData taskData) async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    final response = await http.post(
        Uri.parse('http://www.vietinrace.com/srvTD/editTaskPost/'),
        headers: {
          //'Content-Type': 'application/json; charset=UTF-8',
          "Content-Type": "application/x-www-form-urlencoded",
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'name': taskData.name,
          'description': taskData.description,
          'task_id': taskData.id,
          'status': taskData.status,
          'profit': taskData.profit.toString(),
          'project': widget.projectId!,
          'email': prefs.getString('email'),
          'category': widget.categoryId!,
          'custom_fields': taskData.customFields,
          'start_date': taskData.dateStart,
          'finish_date': '',
          'finish_estimate_date': taskData.dateFinishEstimate,
          'type': ''
        });

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      // var status = json['data'][0]['status'];
      var msg = json['data'][0]['msg'];
      showInSnackBar(msg);
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  List<PopupMenuEntry<String>> createMenuSample(int i) {
    List<PopupMenuEntry<String>> menu = [];
    var data = jsonDecode(fields[i].value.replaceAll("'", "\""));
    for (int j = 1; j <= data.length; j++) {
      var menuItem = PopupMenuItem<String>(
          value: j.toString(),
          child: ListTile(
              // leading: const Icon(Icons.visibility),
              title: Text(
            data[j.toString()],
          )));
      menu.add(menuItem);
    }
    return menu;
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

  Widget _buildDatePicker(BuildContext context, String title, int option,
      StateSetter setStateDate) {
    DateTime date = DateTime.now();

    // var outputFormat = DateFormat('dd/MM/yyyy');
    //taskData.dateStart = outputFormat.format(dateStart);

    if (option == 1) {
      date = dateStart;
    } else if (option == 2) {
      date = dateEstimate;
    }
    // if (dateText != "") {
    //   date = DateTime.parse(dateText);
    // }

    return GestureDetector(
      onTap: () {
        _showPicker(
          context: context,
          child: BottomPickerCustom(
            child: CupertinoDatePicker(
              backgroundColor:
                  CupertinoColors.systemBackground.resolveFrom(context),
              mode: CupertinoDatePickerMode.date,
              initialDateTime: date,
              onDateTimeChanged: (newDateTime) {
                setStateDate(() => {
                      if (option == 1)
                        {dateStart = newDateTime}
                      else if (option == 2)
                        {dateEstimate = newDateTime}
                    });
              },
            ),
          ),
        );
      },
      child: MenuPickerCustom(children: [
        //const Icon(Icons.access_time_outlined),
        Text(title),
        Text(
          DateFormat.yMMMMd().format(date),
          style: const TextStyle(color: CupertinoColors.inactiveGray),
        ),
      ]),
    );
  }

  void _handleSubmitted(String name, String description, String profit,
      List<String> fieldValues) {
    //String taskStatus = widget.taskStatusId!;
    TaskData taskData = TaskData();
    taskData.status = widget.taskStatusId!;
    taskData.description = description;
    taskData.name = name;
    taskData.profit = double.parse(profit);
    var outputFormat = DateFormat('dd/MM/yyyy');
    // var birthDate = outputFormat.format(date);
    taskData.dateStart = outputFormat.format(dateStart);
    taskData.dateFinishEstimate = outputFormat.format(dateEstimate);

    // String value = "{";
    // for (int i = 0; i < fieldValues.length; i++) {
    //   if (fieldValues[i] != "") {
    //     value += "'" + fields[i].id + "':'" + fieldValues[i] + "',";
    //   }
    // }
    // value = value != "{" ? value.substring(0, value.length - 1) + "}" : "{}";
    // taskData.customFields = value;

    String value = "[";
    String type = "list"; // sau them list, number ???
    for (int i = 0; i < fieldValues.length; i++) {
      if (fieldValues[i] != "") {
        value += "{'id':'" +
            fields[i].id +
            "','value':'" +
            fieldValues[i] +
            "','type':'" +
            type +
            "'},";
      }
    }
    value = value != "[" ? value.substring(0, value.length - 1) + "]" : "[{}]";
    taskData.customFields = value;
    createTask(taskData);
    //showInSnackBar("Tên:" + person.name + "SĐT:" + person.phoneNumber);
  }

  void _handleEditSubmitted(String name, String description, String profit,
      List<String> fieldValues) {
    //String taskStatus = widget.taskStatusId!;
    TaskData taskData = TaskData();
    taskData.id = widget.taskData!.id;
    taskData.category = widget.taskData!.category;
    taskData.status = widget.taskData!.status;
    taskData.description = description;
    taskData.name = name;
    taskData.profit = double.parse(profit);
    var outputFormat = DateFormat('dd/MM/yyyy');
    // var birthDate = outputFormat.format(date);
    taskData.dateStart = outputFormat.format(dateStart);
    taskData.dateFinishEstimate = outputFormat.format(dateEstimate);

    // String value = "{";
    // for (int i = 0; i < fieldValues.length; i++) {
    //   if (fieldValues[i] != "") {
    //     value += "'" + fields[i].id + "':'" + fieldValues[i] + "',";
    //   }
    // }
    // value = value != "{" ? value.substring(0, value.length - 1) + "}" : "{}";

    String value = "[";
    String type = "list"; // sau them list, number ???
    for (int i = 0; i < fieldValues.length; i++) {
      if (fieldValues[i] != "") {
        value += "{'id':'" +
            fields[i].id +
            "','value':'" +
            fieldValues[i] +
            "','type':'" +
            type +
            "'},";
      }
    }
    value = value != "[" ? value.substring(0, value.length - 1) + "]" : "[{}]";
    taskData.customFields = value;

    updateTaskID(taskData);
    //showInSnackBar("Tên:" + person.name + "SĐT:" + person.phoneNumber);
  }

  Widget _buildTask() {
    return widget.taskData != null ? _buildEditTask() : _buildAddTask();
  }

  Widget _buildAddTask() {
    String name = "";
    String desc = "";
    String profit = "";
    List<String> dropdownTexts = [];
    List<String> dropdownValues = [];
    for (int i = 0; i < fields.length; i++) {
      dropdownValues.add("");
      dropdownTexts.add("");
    }

    return SingleChildScrollView(child:
        StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
      return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Column(children: <Widget>[
            Padding(
                padding: const EdgeInsets.all(15),
                child: TextField(
                  onChanged: (value) => {name = value},
                  //controller: editingController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Tên công việc',
                  ),
                )),
            Padding(
              padding: const EdgeInsets.all(15),
              child: TextField(
                onChanged: (value) => {desc = value},
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Mô tả',
                ),
                maxLines: 3,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: TextField(
                onChanged: (value) => {
                  //try{
                  profit = value
                  //}catch(){}
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Lợi ích',
                  suffixText: 'VNĐ',
                ),
              ),
            ),
            // Column(
            //   children: createCustomFields(),
            // ),
            _buildDatePicker(context, 'Ngày bắt đầu', 1, setState),
            _buildDatePicker(context, 'Ngày dự kiến hoàn thành', 2, setState),
            for (int i = 0; i < fields.length; i++)
              Row(children: [
                const SizedBox(width: 20),
                Text(fields[i].name),
                const SizedBox(width: 20),
                Text(dropdownTexts[i]),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  onSelected: (value) => {
                    setState(() {
                      dropdownTexts[i] = fields[i].valueFields[value];
                      dropdownValues[i] = value;
                      // valueSelected = data[value];
                    }),
                    //dropdownValues[i] == data[value]
                  },
                  itemBuilder: (context) => createMenuSample(i),
                )
              ]),
            ElevatedButton(
              child: const Text('Tạo'),
              onPressed: () {
                if (name != "") {
                  _handleSubmitted(name, desc, profit, dropdownValues);
                  // Navigator.of(context).pop();
                }
              },
            )
          ]));
    }));
  }

  Widget _buildEditTask() {
    String name = widget.taskData!.name;
    String desc = widget.taskData!.description;
    String profit = widget.taskData!.profit.toString();
    List<String> dropdownTexts = [];
    List<String> dropdownValues = [];
    dateStart = DateTime.parse(widget.taskData!.dateStart);
    dateEstimate = DateTime.parse(widget.taskData!.dateFinishEstimate);
    for (int i = 0; i < fields.length; i++) {
      dropdownValues.add("");
      dropdownTexts.add("");
    }

    var data = jsonDecode(widget.taskData!.customFields.replaceAll("'", "\""));
    for (int i = 0; i < data.length; i++) {
      for (int j = 0; j < fields.length; j++) {
        if (fields[j].id == data[i]['id']) {
          dropdownValues[j] = data[i]['value'];
          dropdownTexts[j] = fields[j].valueFields[data[i]['value']];
        }
      }
    }

    return SingleChildScrollView(child:
        StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
      return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Column(children: <Widget>[
            Padding(
                padding: const EdgeInsets.all(15),
                child: TextField(
                  controller: TextEditingController()..text = name,
                  onChanged: (value) => {name = value},
                  //controller: editingController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Tên công việc',
                  ),
                )),
            Padding(
              padding: const EdgeInsets.all(15),
              child: TextField(
                controller: TextEditingController()..text = desc,
                onChanged: (value) => {desc = value},
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Mô tả',
                ),
                maxLines: 3,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: TextField(
                controller: TextEditingController()..text = profit,
                onChanged: (value) => {profit = value},
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Lợi ích',
                  suffixText: 'VNĐ',
                ),
              ),
            ),
            // Column(
            //   children: createCustomFields(),
            // ),
            _buildDatePicker(context, 'Ngày bắt đầu', 1, setState),
            _buildDatePicker(context, 'Ngày dự kiến hoàn thành', 2, setState),
            for (int i = 0; i < fields.length; i++)
              Row(children: [
                const SizedBox(width: 20),
                Text(fields[i].name),
                const SizedBox(width: 20),
                Text(dropdownTexts[i]),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  onSelected: (value) => {
                    setState(() {
                      dropdownTexts[i] = fields[i].valueFields[value];
                      dropdownValues[i] = value;
                      // valueSelected = data[value];
                    }),
                    //dropdownValues[i] == data[value]
                  },
                  itemBuilder: (context) => createMenuSample(i),
                )
              ]),
            ElevatedButton(
              child: const Text('Cập nhật'),
              onPressed: () {
                if (name != "") {
                  _handleEditSubmitted(name, desc, profit, dropdownValues);
                  // Navigator.of(context).pop();
                }
              },
            )
          ]));
    }));
  }

  @override
  Widget build(BuildContext context) {
    const sizedBoxSpace = SizedBox(height: 24);

    return Scaffold(
      appBar: AppBar(
          title: const Text(
        'Tạo công việc',
      )),
      body: _buildTask(),
    );
  }
}
