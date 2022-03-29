import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'helper/categories_data.dart';
import 'helper/chart_data.dart';

class BarChartSample extends StatefulWidget {
  const BarChartSample({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => BarChartSampleState();
}

class BarChartSampleState extends State<BarChartSample> {
  final Color leftBarColor = const Color(0xff53fdd7);
  final Color rightBarColor = const Color(0xffff5182);
  final double width = 7;

  late List<BarChartGroupData> rawBarGroups;
  late List<BarChartGroupData> showingBarGroups;

  int touchedGroupIndex = -1;

  var prefs;
  UserProjectsInfoData userProjectsInfoData = UserProjectsInfoData();
  bool isLoading = false;

  var countProjects = '';
  var countUsers = '';
  var countTasks = '';

  @override
  void initState() {
    super.initState();
    final barGroup1 = makeGroupData(0, 5, 12);
    final barGroup2 = makeGroupData(1, 16, 12);
    final barGroup3 = makeGroupData(2, 18, 5);
    final barGroup4 = makeGroupData(3, 20, 16);
    final barGroup5 = makeGroupData(4, 17, 6);
    final barGroup6 = makeGroupData(5, 19, 1.5);
    final barGroup7 = makeGroupData(6, 10, 1.5);

    final items = [
      barGroup1,
      barGroup2,
      barGroup3,
      barGroup4,
      barGroup5,
      barGroup6,
      barGroup7,
    ];

    rawBarGroups = items;

    showingBarGroups = rawBarGroups;
    getProjectInfo();
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
    ));
  }

  Future<void> getProjectInfo() async {
    setState(() {
      isLoading = true;
    });
    prefs = await SharedPreferences.getInstance();
    // final prefs = await SharedPreferences.getInstance();

    var url = 'http://www.vietinrace.com/srvTD/getProjectInfo/' +
        prefs.getString('email')!;
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      for (var dat in data) {
        userProjectsInfoData = UserProjectsInfoData();
        userProjectsInfoData.tasks = int.parse(dat['tasks']);
        userProjectsInfoData.projects = int.parse(dat['projects']);
        userProjectsInfoData.users = int.parse(dat['users']);
        userProjectsInfoData.projectsShare = int.parse(dat['projects_share']);
        userProjectsInfoData.tasksShare = int.parse(dat['tasks_share']);
        //userProjectsInfoDatas.add(userProjectsInfoData);
      }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Widget _buildCardInfo() {
    countProjects = '';
    countUsers = '';
    countTasks = '';

    if (userProjectsInfoData.projects == 0) {
      countProjects += userProjectsInfoData.projectsShare.toString() + ' Dự án';
      countUsers += userProjectsInfoData.users.toString() + ' Người dùng';
      countTasks += userProjectsInfoData.tasksShare.toString() + ' Công việc';
    } else {
      countProjects += userProjectsInfoData.projects.toString() + ' Dự án';
      countUsers += userProjectsInfoData.users.toString() + ' Người dùng';
      countTasks += userProjectsInfoData.tasks.toString() + ' Công việc';
    }

    return Container(
      height: 200, width: 150,
      child: isLoading
          ? const LinearProgressIndicator()
          : Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              color: Colors.lightBlue,
              child: Column(
                children: [
                  const SizedBox(height: 25),
                  Text(countProjects,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 30)),
                  const SizedBox(height: 25),
                  Text(countUsers,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 20)),
                  const SizedBox(height: 25),
                  Text(countTasks,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 20)),
                ],
              )),
      // Transform.rotate(
      //     angle: 15 * pi / 180, child: Text("flutter is awesome"))),
    );
  }

  Widget _buildCardColorRotate(double angleRotate, Color color) {
    return Transform.rotate(
        angle: angleRotate * pi / 180,
        origin: Offset(-60, 80),
        child: Container(
          height: 200, width: 150,
          child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              color: color //Colors.redAccent,
              ),
          // Transform.rotate(
          //     angle: 15 * pi / 180, child: Text("flutter is awesome"))),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //Color.fromRGBO(70, 49, 179,0) Color.fromARGB(179, 70, 49, 255)

        backgroundColor: const Color(
            0xff4631b3), //Color.fromRGBO(70, 49, 179, 300), //(a, r, g, b)#4631b3
        body: RefreshIndicator(
            onRefresh: () async {
              getProjectInfo();
            },
            child: Scrollbar(
                child: Center(
                    child: Stack(
              children: [
                _buildCardColorRotate(25, Colors.lightGreen),
                _buildCardColorRotate(10, Colors.redAccent),
                _buildCardInfo()
              ],
            )))));
  }

  BarChartGroupData makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(barsSpace: 4, x: x, barRods: [
      BarChartRodData(
        y: y1,
        colors: [leftBarColor],
        width: width,
      ),
      BarChartRodData(
        y: y2,
        colors: [rightBarColor],
        width: width,
      ),
    ]);
  }

  Widget makeTransactionsIcon() {
    const width = 4.5;
    const space = 3.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: width,
          height: 10,
          color: Colors.white.withOpacity(0.4),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 28,
          color: Colors.white.withOpacity(0.8),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 42,
          color: Colors.white.withOpacity(1),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 28,
          color: Colors.white.withOpacity(0.8),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 10,
          color: Colors.white.withOpacity(0.4),
        ),
      ],
    );
  }
}
