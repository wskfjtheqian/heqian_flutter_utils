import 'dart:async';

import 'package:flutter/material.dart';
import 'package:heqian_flutter_utils/heqian_flutter_utils.dart';

void main() {
  runApp(MyApp());
}

class YttxHttpClinet {}

class YttxHttp extends NetwordInterface<YttxHttpClinet> {
  YttxHttp(
    List<YttxHttpClinet> interfaces,
  ) : super(interfaces);
}

class NetUser extends YttxHttpClinet {
  void login() {}
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Network(
      create: (context) {
        return [
          YttxHttp([
            NetUser(),
          ]),
        ];
      },
      builder: (context) {
        return AutoRouter(
          routers: null,
          builder: (context, routeFactory) {
            return MaterialApp(
              title: 'Flutter Demo',
              theme: ThemeData(
                fontFamily: "SourceHanSansCN",
                primarySwatch: Colors.blue,
                visualDensity: VisualDensity.adaptivePlatformDensity,
              ),
              home: MyHomePage(),
              onGenerateRoute: routeFactory,
            );
          },
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("常用工具示例"),
      ),
      body: Column(
        children: [
          TextButton(
            onPressed: () {
              showToast(context, "Toast");
            },
            child: Text("Toast"),
          ),
          TextButton(
            onPressed: () {
              Network.of<NetUser>(context).login();
            },
            child: Text("Network"),
          ),
          TextButton(
            onPressed: () {
              var _loadingController = showLoading(context, msg: "Loading");
              Timer(Duration(seconds: 5), () {
                _loadingController.close();
              });
            },
            child: Text("Loading"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, "routeName");
            },
            child: Text("AutoRouter"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) {
                    return ToastPage();
                  },
                ),
              );
            },
            child: Text("New Page"),
          ),
        ],
      ),
    );
  }
}

class ToastPage extends StatefulWidget {
  @override
  _ToastPageState createState() => _ToastPageState();
}

class _ToastPageState extends State<ToastPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: TextButton(
          onPressed: () {
            showToast(context, "Close");
            Navigator.pop(context);
          },
          child: Text("Toast"),
        ),
      ),
    );
  }
}
