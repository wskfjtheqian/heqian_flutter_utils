import 'dart:async';
import 'package:example/pages/page_multilevel_router.dart';
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
          home: "/",
          routers: {
            AutoPath("/"): (context, param) => MyHomePage(),
            AutoPath("/toastPage"): (context, param) => ToastPage(),
            AutoPath("/routerPage"): (context, param) => PageMultilevelRouter(),
            AutoPath("/routerPage/subRouter1"): (context, param) => SubRouterPage1(),
            AutoPath("/routerPage/subRouter2"): (context, param) => SubRouterPage2(),
            AutoPath("/routerPage/subRouter1/subRouter3"): (context, param) => SubRouterPage3(),
          },
          builder: (context, appRouter) {
            return MaterialApp.router(
              routerDelegate: appRouter,
              routeInformationParser: appRouter,
              routeInformationProvider: appRouter.provider,
              title: 'Flutter Demo',
              theme: ThemeData(
                fontFamily: "SourceHanSansCN",
                primarySwatch: Colors.blue,
                visualDensity: VisualDensity.adaptivePlatformDensity,
              ),
            );
          },
        );
      },
    );
  }
}

class MyHomePage extends RouterDataWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();

  @override
  initData(BuildContext context) {

  }
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
              var _loadingController = showLoading(context, msg: (value) => "Loading");
              Timer(Duration(seconds: 5), () {
                _loadingController.close();
              });
            },
            child: Text("Loading"),
          ),
          TextButton(
            onPressed: () {
              LoadingCall.of(context).call((state, loadingController) => Future.value());
            },
            child: Text("LoadingCall"),
          ),
          TextButton(
            onPressed: () {
              AutoRouter.of(context).pushNamed("/routerPage");
            },
            child: Text("multilevel"),
          ),
          TextButton(
            onPressed: () {
              AutoRouter.of(context).pushNamed("/toastPage");
            },
            child: Text("New Page"),
          ),
        ],
      ),
    );
  }
}

class ToastPage extends RouterDataWidget {
  @override
  _ToastPageState createState() => _ToastPageState();

  @override
  initData(BuildContext context) {
    throw UnimplementedError();
  }
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
