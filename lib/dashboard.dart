// import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:kanban_dashboard/task_status.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:overlay_support/overlay_support.dart';
import 'package:overlay_support/overlay_support.dart';

import 'bar_chart.dart';
import 'chart.dart';
import 'project_list.dart';
// import 'category_list.dart';
// import 'indicator.dart';
import 'login.dart';
import 'register.dart';
import 'splashscreen.dart';
// import 'task_list.dart';
import 'task_type_list.dart';
import 'line_chart.dart';
// import 'package:graphic/graphic.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OverlaySupport(
        child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardPage(),
        '/kanban': (context) => const ChartScreen(
            title: 'Thống kê Chung',
            categoryId: '',
            projectId: '61ab4b5084a5fa00241602dc'),
        '/list_project': (context) => const ProjectListScreen(),
        //'/list_category': (context) => const CategoryListScreen(),
        '/list_task_type': (context) => const TaskTypeListScreen(),
        '/task_status': (context) => const TaskStatusScreen(),
        '/line_chart': (context) =>
            const LineChartPage(projectId: '61ab4b5084a5fa00241602dc'),
        //'/list_task': (context) => const TaskListScreen(),
      },

      //home: DashboardPage(),
    ));
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  // _DashboardPageState2 createState() => _DashboardPageState2();
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  String userEmail = '';

  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  late SharedPreferences prefs;

  late int _totalNotifications;
  PushNotification? _notificationInfo;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    _totalNotifications = 0;
    registerNotification();
    onMessageOpen();
    getSharedPreference();
    buildTab();

    super.initState();
    //
  }

  void getSharedPreference() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('email')!;
    });
  }

  //check khi mở chương trình
  void onMessageOpen() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      PushNotification notification = PushNotification(
        title: message.notification?.title,
        body: message.notification?.body,
        dataTitle: message.data['title'],
        dataBody: message.data['body'],
      );
      setState(() {
        _notificationInfo = notification;
        _totalNotifications++;
      });
    });
  }

  // For handling notification when the app is in terminated state
  checkForInitialMessage() async {
    await Firebase.initializeApp();
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      PushNotification notification = PushNotification(
        title: initialMessage.notification?.title,
        body: initialMessage.notification?.body,
        dataTitle: initialMessage.data['title'],
        dataBody: initialMessage.data['body'],
      );
      setState(() {
        _notificationInfo = notification;
        _totalNotifications++;
      });
    }
  }

  Widget _buildMessageWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'App for capturing Firebase Push Notifications',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 16.0),
        NotificationBadge(totalNotifications: _totalNotifications),
        const SizedBox(height: 16.0),
        _notificationInfo != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TITLE: ${_notificationInfo!.title}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'BODY: ${_notificationInfo!.body}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ],
              )
            : Container(),
      ],
    );
  }

  final List<Widget> _widgetOptions = [];

  void buildTab() {
    // _widgetOptions.add(_buildMessageWidget());
    _widgetOptions.add(const ProjectList());
    _widgetOptions.add(const BarChartSample());

    // _widgetOptions.add(const Text(
    //   'Index 1: Business',
    //   style: optionStyle,
    // ));

    // _widgetOptions.add(const Text(
    //   'Index 2: School',
    //   style: optionStyle,
    // ));

    // _widgetOptions.add(const Text(
    //   'Index 3: Settings',
    //   style: optionStyle,
    // ));
  }

  @override
  Widget build(BuildContext context) {
    //await getUserInfo();

    final drawerHeader = UserAccountsDrawerHeader(
      accountName: const Text(
        'User Name',
      ),
      accountEmail: Text(
        userEmail,
      ),
      currentAccountPicture: const CircleAvatar(
        child: FlutterLogo(size: 42.0),
      ),
    );
    final drawerItems = ListView(
      children: [
        drawerHeader,
        // ListTile(
        //   title: const Text(
        //     'Charts',
        //   ),
        //   leading: const Icon(Icons.favorite),
        //   onTap: () {
        //     //Navigator.pop(context);
        //     Navigator.pushNamed(context, '/kanban');
        //   },
        // ),
        // ListTile(
        //   title: const Text(
        //     'Item Two',
        //   ),
        //   leading: const Icon(Icons.comment),
        //   onTap: () {
        //     Navigator.pop(context); //trả về như cũ nhé
        //   },
        // ),
        // ListTile(
        //   title: const Text(
        //     'Nâng cao chất lượng vận hành',
        //   ),
        //   leading: const Icon(Icons.manage_search),
        //   onTap: () {
        //     //Navigator.pop(context);
        //     Navigator.pushNamed(context, '/list_project');
        //   },
        // ),
        // ListTile(
        //   title: const Text(
        //     'Line Chart',
        //   ),
        //   leading: const Icon(Icons.pan_tool),
        //   onTap: () {
        //     //Navigator.pop(context);
        //     Navigator.pushNamed(context, '/line_chart');
        //   },
        // ),
        // ListTile(
        //   title: const Text(
        //     'Quản trị Danh Mục',
        //   ),
        //   leading: const Icon(Icons.pan_tool),
        //   onTap: () {
        //     //Navigator.pop(context);
        //     Navigator.pushNamed(context, '/list_category');
        //   },
        // ),
        // ListTile(
        //   title: const Text(
        //     'Quản trị Loại CV',
        //   ),
        //   leading: const Icon(Icons.air_sharp),
        //   onTap: () {
        //     //Navigator.pop(context);
        //     Navigator.pushNamed(context, '/list_task_type');
        //   },
        // ),
        // ListTile(
        //   title: const Text(
        //     'Quản trị Trạng Thái',
        //   ),
        //   leading: const Icon(Icons.pan_tool),
        //   onTap: () {
        //     //Navigator.pop(context);
        //     Navigator.pushNamed(context, '/task_status');
        //   },
        // ),
        // ListTile(
        //   title: const Text(
        //     'Quản trị công việc',
        //   ),
        //   leading: const Icon(Icons.work),
        //   onTap: () {
        //     //Navigator.pop(context);
        //     Navigator.pushNamed(context, '/list_task');
        //   },
        // ),
        ListTile(
          title: const Text(
            'Thoát',
          ),
          leading: const Icon(Icons.exit_to_app),
          onTap: () {
            //Navigator.pop(context);
            prefs.remove('email');
            Navigator.pushNamed(context, '/login');
          },
        ),
      ],
    );

    // const data = [
    //   {'category': 'Shirts', 'sales': 5},
    //   {'category': 'Cardigans', 'sales': 20},
    //   {'category': 'Chiffons', 'sales': 36},
    //   {'category': 'Pants', 'sales': 10},
    //   {'category': 'Heels', 'sales': 10},
    //   {'category': 'Socks', 'sales': 20},
    // ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Các chủ điểm trọng tâm ',
        ),
      ),
      // body: Center(
      //   child: _widgetOptions.elementAt(_selectedIndex),
      // ),
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Danh sách',
            backgroundColor: Colors.red,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Thống kê',
            backgroundColor: Colors.green,
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.school),
          //   label: 'School',
          //   backgroundColor: Colors.purple,
          // ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.settings),
          //   label: 'Settings',
          //   backgroundColor: Colors.pink,
          // ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),

      // so simple , drawers is
      drawer: Drawer(
        child: drawerItems,
      ),
    );
  }

  late final FirebaseMessaging _messaging;

  Future _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
  }

  void registerNotification() async {
    // 1. Initialize the Firebase app
    await Firebase.initializeApp();

    // 2. Instantiate Firebase Messaging
    _messaging = FirebaseMessaging.instance;
    try {
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
    } catch (err) {
      print('Chưa có message nào:' + err.toString());
    }
    // 3. On iOS, this helps to take the user permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // Parse the message received
        PushNotification notification = PushNotification(
          title: message.notification?.title,
          body: message.notification?.body,
          dataTitle: message.data['title'],
          dataBody: message.data['body'],
        );
        setState(() {
          _notificationInfo = notification;
          _totalNotifications++;
        });

        if (_notificationInfo != null) {
          showSimpleNotification(
            Text("Ăn không ?" + _notificationInfo!.title!),
            leading: NotificationBadge(totalNotifications: _totalNotifications),
            subtitle: Text(_notificationInfo!.body!),
            background: Colors.cyan.shade700,
            duration: const Duration(seconds: 5),
          );
        }
      });
    } else {
      print('User declined or has not accepted permission');
    }
  }
}

class PushNotification {
  PushNotification({
    this.title,
    this.body,
    this.dataTitle,
    this.dataBody,
  });
  String? title;
  String? body;
  String? dataTitle;
  String? dataBody;
}

class NotificationBadge extends StatelessWidget {
  final int totalNotifications;

  const NotificationBadge({Key? key, required this.totalNotifications})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.0,
      height: 40.0,
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '$totalNotifications',
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ),
    );
  }
}
