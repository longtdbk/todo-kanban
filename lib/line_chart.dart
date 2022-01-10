import 'dart:collection';
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'helper/chart_data.dart';
import 'helper/task_status_data.dart';
import 'indicator.dart';

class LineChartPage extends StatefulWidget {
  final String? projectId;
  final String? categoryId;
  final String? title;
  final String? year;
  const LineChartPage(
      {Key? key, this.projectId, this.categoryId, this.title, this.year})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => LineChartPageState();
}

class LineChartPageState extends State<LineChartPage> {
  late bool isShowingTotalTask;
  bool isLoading = false;
  List<ChartDataMonth> chartDataMonths = [];
  List<String> names = [];
  HashMap<String, List<FlSpot>> spotsMonthTotal = HashMap();
  HashMap<String, List<FlSpot>> spotsMonthProfit = HashMap();

  List<TaskStatusData> taskStatuses = [];
  String statuses = '';
  List<bool> checkStatuses = [];

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
    ));
  }

  SideTitles leftTitles({required GetTitleFunction getTitles}) => SideTitles(
        getTitles: getTitles,
        showTitles: true,
        margin: 8,
        interval: 1,
        reservedSize: 40,
        getTextStyles: (context, value) => const TextStyle(
          color: Color(0xff75729e),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );

  LineTouchData get lineTouchDataTask => LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
        ),
      );

  FlGridData get gridData => FlGridData(show: false);

  FlBorderData get borderData => FlBorderData(
        show: true,
        border: const Border(
          bottom: BorderSide(color: Color(0xff4e4965), width: 4),
          left: BorderSide(color: Colors.transparent),
          right: BorderSide(color: Colors.transparent),
          top: BorderSide(color: Colors.transparent),
        ),
      );

  FlTitlesData get titlesDataTotal => FlTitlesData(
        bottomTitles: bottomTitles,
        rightTitles: SideTitles(showTitles: false),
        topTitles: SideTitles(showTitles: false),
        leftTitles: leftTitles(
          getTitles: (value) {
            switch (value.toInt()) {
              case 1:
                return '2';
              case 2:
                return '4';
              case 3:
                return '6';
              case 4:
                return '8';
              case 5:
                return '10';
            }
            return '';
          },
        ),
      );

  FlTitlesData get titlesDataProfit => FlTitlesData(
        bottomTitles: bottomTitles,
        rightTitles: SideTitles(showTitles: false),
        topTitles: SideTitles(showTitles: false),
        leftTitles: leftTitles(
          getTitles: (value) {
            switch (value.toInt()) {
              case 1:
                return '10M';
              // case 2:
              //   return '20';
              case 3:
                return '30M';
              case 4:
                return '40M';
              // case 5:
              //   return '50';
              case 6:
                return '60M';
            }
            return '';
          },
        ),
      );

  SideTitles get bottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 22,
        margin: 10,
        interval: 1,
        getTextStyles: (context, value) => const TextStyle(
          color: Color(0xff72719b),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        getTitles: (value) {
          return value.toInt().toString();
          // switch (value.toInt()) {
          //   case 1:
          //     return 'T1';
          //   case 2:
          //     return 'T2';
          //   case 3:
          //     return 'T3';
          // }
          // return '';
        },
      );

  Future<void> getTaskStatus() async {
    taskStatuses = [];
    setState(() {
      isLoading = true;
    });

    // final prefs = await SharedPreferences.getInstance();

    var url =
        'http://www.vietinrace.com/srvTD/getTaskStatus/' + widget.projectId!;
    final response = await http.get(Uri.parse(url));

    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      for (var dat in data) {
        TaskStatusData taskStatus = TaskStatusData(
            id: dat['id'],
            name: dat['name'],
            shortName: dat['name'],
            code: dat['code']);
        taskStatuses.add(taskStatus);
        statuses += taskStatus.id + "-";
        checkStatuses.add(true);
      }
      statuses = statuses.substring(0, statuses.length - 1);
      getCalculateTasksMonth();
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  Future<void> getCalculateTasksMonth() async {
    chartDataMonths = [];
    setState(() {
      isLoading = true;
    });

    // final prefs = await SharedPreferences.getInstance();
    var url = '';
    if (widget.categoryId == '') {
      url =
          'http://www.vietinrace.com/srvTD/getCalculateTasksCategoriesMonths/' +
              widget.projectId! +
              '/0/' +
              widget.year! +
              '/' +
              statuses;
    } else {
      url =
          'http://www.vietinrace.com/srvTD/getCalculateTasksCategoriesChildMonths/' +
              widget.projectId! +
              '/' +
              widget.categoryId! +
              '/' +
              widget.year! +
              '/' +
              statuses;
    }

    final response = await http.get(Uri.parse(url));

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      var data = json['data'];
      for (int i = 0; i < 12; i++) {
        List<ChartData> chartDatas = [];
        int totalProfit = 0;
        int totalTasks = 0;
        for (var dat in data[i]) {
          ChartData chartData = ChartData();
          chartData.name = dat['name'];
          chartData.id = dat['id'];
          chartData.total = int.parse(dat['total']);
          chartData.profit = int.parse(dat['profit']);
          chartDatas.add(chartData);
          totalProfit += chartData.profit;
          totalTasks += chartData.total;
          if (i == 0) {
            names.add(chartData.name);
          }
        }

        String m = (i + 1).toString();
        ChartDataMonth chartMonth = ChartDataMonth();
        chartMonth.month = m;
        chartMonth.chartDatas = chartDatas;
        chartMonth.profit = totalProfit;
        chartMonth.total = totalTasks;
        chartDataMonths.add(chartMonth);
      }

      // 12 ; KVH, KTC
      if (names.isNotEmpty) {
        int len = names.length;
        for (int i = 0; i < len; i++) {
          List<FlSpot> spots = [];
          List<FlSpot> spotsProfit = [];
          for (int j = 0; j < chartDataMonths.length; j++) {
            // chia 10 ra cho dễ vẽ
            double totalDiv10 = chartDataMonths[j].chartDatas[i].total / 2;
            spots.add(FlSpot(j + 1, totalDiv10));

            double profitDiv10 = chartDataMonths[j].chartDatas[i].profit / 10;
            spotsProfit.add(FlSpot(j + 1, profitDiv10));
          }
          spotsMonthTotal[names[i]] = spots;
          spotsMonthProfit[names[i]] = spotsProfit;
        }
      }
    } else {
      showInSnackBar("Có lỗi xảy ra , có thể do kết nối mạng !");
    }
  }

  LineChartData get monthsDataTotal => LineChartData(
        lineTouchData: lineTouchDataTask,
        gridData: gridData,
        titlesData: titlesDataTotal,
        borderData: borderData,
        lineBarsData: getLineChartBarData(),
        minX: 1, //X là tháng
        maxX: 12,
        maxY: 6, // Y là total đó
        minY: 0,
      );

  LineChartData get monthsDataProfit => LineChartData(
        lineTouchData: lineTouchDataTask,
        gridData: gridData,
        titlesData: titlesDataProfit,
        borderData: borderData,
        lineBarsData: getLineChartBarData(),
        minX: 1, //X là tháng
        maxX: 12,
        maxY: 8, // Y là total đó
        minY: 0,
      );

  List<LineChartBarData> getLineChartBarData() {
    List<LineChartBarData> listLines = [];
    for (int i = 0; i < names.length; i++) {
      LineChartBarData lineChart = LineChartBarData(
        isCurved: true,
        colors: [getColor(i)],
        barWidth: isShowingTotalTask ? 8 : 4,
        isStrokeCapRound: true,
        dotData: FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
        spots: isShowingTotalTask
            ? spotsMonthTotal[names[i]]
            : spotsMonthProfit[names[i]],
      );
      listLines.add(lineChart);
    }
    return listLines;
  }

  Color getColor(int i) {
    Color colorChoose = const Color(0xff4af699);
    switch (i) {
      case 0:
        colorChoose = const Color(0xff4af699);
        break;
      case 1:
        colorChoose = const Color(0xffaa4cfc);
        break;
      case 2:
        colorChoose = const Color(0xff27b6fc);
        break;
      case 3:
        colorChoose = const Color(0xffF2F910);
        break;
      default:
        colorChoose = const Color(0xffF95A10);
        break;
    }
    return colorChoose;
  }

  List<Widget> showingIndicators() {
    List<Widget> indicators = [];
    for (int i = 0; i < names.length; i++) {
      indicators.add(Indicator(
        color: getColor(i),
        text: names[i],
        isSquare: true,
      ));
      indicators.add(const SizedBox(
        height: 4,
      ));
    }
    return indicators;
  }

  Widget _chooseStatus() {
    List<Widget> listStatuses = [];

    if (taskStatuses.length > 4) {
      int rows = taskStatuses.length ~/ 4 + 1;
      for (int i = 0; i < rows; i++) {
        List<Widget> listStatusesRow = [];
        for (int j = 4 * i; j < 4 + 4 * i; j++) {
          Checkbox checkBox = Checkbox(
              value: checkStatuses[j],
              onChanged: (value) {
                setState(() {
                  checkStatuses[j] = value!;
                  if (checkStatuses[j]) {
                    statuses = statuses + "-" + taskStatuses[j].id;
                  } else {
                    statuses = statuses.replaceAll(taskStatuses[j].id, "");
                  }
                  statuses = statuses.replaceAll("--", "-");
                  getCalculateTasksMonth();
                });
              });
          listStatusesRow.add(checkBox);
          listStatusesRow.add(Text(taskStatuses[i].name));
          listStatusesRow.add(const SizedBox(width: 10));
        }
        Row row = Row(children: listStatusesRow);
        listStatuses.add(row);
        //listStatuses.add(const SizedBox(height: 10));
      }
      return Column(children: listStatuses);
    } else {
      for (int i = 0; i < taskStatuses.length; i++) {
        Checkbox checkBox = Checkbox(
            value: checkStatuses[i],
            onChanged: (value) {
              setState(() {
                checkStatuses[i] = value!;
                if (checkStatuses[i]) {
                  statuses = statuses + "-" + taskStatuses[i].id;
                } else {
                  statuses = statuses.replaceAll(taskStatuses[i].id, "");
                }
                statuses = statuses.replaceAll("--", "-");
                getCalculateTasksMonth();
              });
            });
        listStatuses.add(checkBox);
        listStatuses.add(Text(taskStatuses[i].name));
        listStatuses.add(const SizedBox(width: 10));
      }
      Row row = Row(children: listStatuses);
      return row;
    }
  }

  @override
  void initState() {
    super.initState();
    isShowingTotalTask = true;
    getTaskStatus();
  }

  Widget _createLineChart() {
    // ổn đấy --> để làm luôn cái profit & tasks :)
    LineChart lineMonth = LineChart(
      //isShowingMainData ? sampleData1 : sampleData2,
      isShowingTotalTask ? monthsDataTotal : monthsDataProfit,
      swapAnimationDuration: const Duration(milliseconds: 250),
    );

    return AspectRatio(
      aspectRatio: 1.23,
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          gradient: LinearGradient(
            colors: [
              Color(0xff2c274c),
              Color(0xff46426c),
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(
                  height: 37,
                ),
                const Text(
                  'Dự án 2021',
                  style: TextStyle(
                    color: Color(0xff827daa),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 4,
                ),
                const Text(
                  'Thống kê tháng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 37,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0, left: 6.0),
                    // child: const Text("test")
                    child: lineMonth,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
              ],
            ),
            IconButton(
              icon: Icon(
                Icons.monetization_on,
                color: Colors.white.withOpacity(isShowingTotalTask ? 0.5 : 1.0),
              ),
              onPressed: () {
                setState(() {
                  isShowingTotalTask = !isShowingTotalTask;
                });
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Text(
          'Line chart',
        )),
        body: Container(
          color: const Color(0xffffffff),
          child: ListView(
            children: <Widget>[
              _chooseStatus(),
              const SizedBox(
                height: 8,
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 28,
                  right: 28,
                ),
                child: _createLineChart(),
              ),
              const SizedBox(
                height: 22,
              ),
              Padding(
                  padding: const EdgeInsets.only(
                    left: 28,
                    right: 28,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // cho vào vòng lặp được này
                    children: showingIndicators(),
                  )),
              const SizedBox(
                height: 22,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 28.0, right: 28),
                child: LineChartSample2(),
              ),
              const SizedBox(height: 22),
            ],
          ),
        ));
  }
}
// LineChart (gọi LineChartData --> chưa sample Data --> done)

class LineChartSample2 extends StatefulWidget {
  const LineChartSample2({Key? key}) : super(key: key);

  @override
  _LineChartSample2State createState() => _LineChartSample2State();
}

class _LineChartSample2State extends State<LineChartSample2> {
  List<Color> gradientColors = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];

  bool showAvg = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.70,
          child: Container(
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(18),
                ),
                color: Color(0xff232d37)),
            child: Padding(
              padding: const EdgeInsets.only(
                  right: 18.0, left: 12.0, top: 24, bottom: 12),
              child: LineChart(
                showAvg ? avgData() : mainData(),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 60,
          height: 34,
          child: TextButton(
            onPressed: () {
              setState(() {
                showAvg = !showAvg;
              });
            },
            child: Text(
              'avg',
              style: TextStyle(
                  fontSize: 12,
                  color:
                      showAvg ? Colors.white.withOpacity(0.5) : Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  LineChartData mainData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: SideTitles(showTitles: false),
        topTitles: SideTitles(showTitles: false),
        bottomTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          interval: 1,
          getTextStyles: (context, value) => const TextStyle(
              color: Color(0xff68737d),
              fontWeight: FontWeight.bold,
              fontSize: 16),
          getTitles: (value) {
            switch (value.toInt()) {
              case 2:
                return 'MAR';
              case 5:
                return 'JUN';
              case 8:
                return 'SEP';
            }
            return '';
          },
          margin: 8,
        ),
        leftTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTextStyles: (context, value) => const TextStyle(
            color: Color(0xff67727d),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          getTitles: (value) {
            switch (value.toInt()) {
              case 1:
                return '10k';
              case 3:
                return '30k';
              case 5:
                return '50k';
            }
            return '';
          },
          reservedSize: 32,
          margin: 12,
        ),
      ),
      borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1)),
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: 6,
      lineBarsData: [
        LineChartBarData(
          spots: const [
            FlSpot(0, 3),
            FlSpot(2.6, 2),
            FlSpot(4.9, 5),
            FlSpot(6.8, 3.1),
            FlSpot(8, 4),
            FlSpot(9.5, 3),
            FlSpot(11, 4),
          ],
          isCurved: true,
          colors: gradientColors,
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            colors:
                gradientColors.map((color) => color.withOpacity(0.3)).toList(),
          ),
        ),
      ],
    );
  }

  LineChartData avgData() {
    return LineChartData(
      lineTouchData: LineTouchData(enabled: false),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          getTextStyles: (context, value) => const TextStyle(
              color: Color(0xff68737d),
              fontWeight: FontWeight.bold,
              fontSize: 16),
          getTitles: (value) {
            switch (value.toInt()) {
              case 2:
                return 'MAR';
              case 5:
                return 'JUN';
              case 8:
                return 'SEP';
            }
            return '';
          },
          margin: 8,
          interval: 1,
        ),
        leftTitles: SideTitles(
          showTitles: true,
          getTextStyles: (context, value) => const TextStyle(
            color: Color(0xff67727d),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          getTitles: (value) {
            switch (value.toInt()) {
              case 1:
                return '10k';
              case 3:
                return '30k';
              case 5:
                return '50k';
            }
            return '';
          },
          reservedSize: 32,
          interval: 1,
          margin: 12,
        ),
        topTitles: SideTitles(showTitles: false),
        rightTitles: SideTitles(showTitles: false),
      ),
      borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1)),
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: 6,
      lineBarsData: [
        LineChartBarData(
          spots: const [
            FlSpot(0, 3.44),
            FlSpot(2.6, 3.44),
            FlSpot(4.9, 3.44),
            FlSpot(6.8, 3.44),
            FlSpot(8, 3.44),
            FlSpot(9.5, 3.44),
            FlSpot(11, 3.44),
          ],
          isCurved: true,
          colors: [
            ColorTween(begin: gradientColors[0], end: gradientColors[1])
                .lerp(0.2)!,
            ColorTween(begin: gradientColors[0], end: gradientColors[1])
                .lerp(0.2)!,
          ],
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(show: true, colors: [
            ColorTween(begin: gradientColors[0], end: gradientColors[1])
                .lerp(0.2)!
                .withOpacity(0.1),
            ColorTween(begin: gradientColors[0], end: gradientColors[1])
                .lerp(0.2)!
                .withOpacity(0.1),
          ]),
        ),
      ],
    );
  }
}
