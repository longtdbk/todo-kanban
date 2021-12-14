import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'helper/chart_data.dart';
import 'indicator.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({Key? key}) : super(key: key);

  @override
  // _DashboardPageState2 createState() => _DashboardPageState2();
  _ChartScreenState createState() => _ChartScreenState();
}

class _ChartScreenState extends State {
  int touchedIndex = -1;

  var chartDatas = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getAllCategoriesProject('61ab4b5084a5fa00241602dc', 2);
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
    ));
  }

  Future<void> getAllCategoriesProject(String project, int level) async {
    chartDatas = [];
    setState(() {
      isLoading = true;
    });

    // final prefs = await SharedPreferences.getInstance();

    var url = 'http://www.vietinrace.com/srvTD/getTasksCategories/' +
        project +
        "/" +
        level.toString();
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      int totalProfit = 0;
      int totalTasks = 0;
      for (var dat in data) {
        ChartData chartData = ChartData();
        chartData.name = dat['name'];
        chartData.total = int.parse(dat['total']);
        chartData.profit = int.parse(dat['profit']);
        totalProfit += chartData.profit;
        totalTasks += chartData.total;
        chartDatas.add(chartData);
      }
      for (int i = 0; i < chartDatas.length; i++) {
        chartDatas[i].percentTotal = chartDatas[i].total / totalTasks;
        chartDatas[i].percentProfit = chartDatas[i].profit / totalProfit;
      }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kanban',
        ),
      ),
      body: AspectRatio(
        aspectRatio: 1.3,
        child: Card(
          color: Colors.white,
          child: Row(
            children: <Widget>[
              const SizedBox(
                height: 18,
              ),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: PieChart(
                    PieChartData(
                        pieTouchData: PieTouchData(touchCallback:
                            (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        }),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        sectionsSpace: 0,
                        centerSpaceRadius: 40,
                        sections: showingSectionsChart()),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                // cho vào vòng lặp được này
                children: showingIndicators(),
              ),
              const SizedBox(
                width: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> showingIndicators() {
    List<Widget> indicators = [];
    for (int i = 0; i < chartDatas.length; i++) {
      indicators.add(Indicator(
        color: chooseColor(i),
        text: chartDatas[i].name,
        isSquare: true,
      ));

      indicators.add(const SizedBox(
        height: 4,
      ));
    }
    return indicators;
  }

  Color chooseColor(int i) {
    Color color = const Color(0xff0293ee);
    switch (i) {
      case 0:
        color = const Color(0xff0293ee);
        break;
      case 1:
        color = const Color(0xfff8b250);
        break;
      case 2:
        color = const Color(0xff845bef);
        break;
      case 3:
        color = const Color(0xff13d38e);
        break;
      default:
        color = const Color(0xff0293ee);
    }
    return color;
  }

  List<PieChartSectionData> showingSectionsChart() {
    List<PieChartSectionData> listPies = [];

    for (int i = 0; i < chartDatas.length; i++) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;
      Color color = chooseColor(i);
      PieChartSectionData sectionData = PieChartSectionData(
        color: color,
        value: chartDatas[i].percentProfit,
        title: chartDatas[i].profit.toString(),
        radius: radius,
        titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xffffffff)),
      );
      listPies.add(sectionData);
    }
    return listPies;
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(4, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;
      switch (i) {
        case 0:
          return PieChartSectionData(
            color: const Color(0xff0293ee),
            value: 40,
            title: '40%',
            radius: radius,
            titleStyle: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xffffffff)),
          );
        case 1:
          return PieChartSectionData(
            color: const Color(0xfff8b250),
            value: 30,
            title: '30%',
            radius: radius,
            titleStyle: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xffffffff)),
          );
        case 2:
          return PieChartSectionData(
            color: const Color(0xff845bef),
            value: 15,
            title: '15%',
            radius: radius,
            titleStyle: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xffffffff)),
          );
        case 3:
          return PieChartSectionData(
            color: const Color(0xff13d38e),
            value: 15,
            title: '15%',
            radius: radius,
            titleStyle: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xffffffff)),
          );
        default:
          throw Error();
      }
    });
  }
}
