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
            "/": (context, param) => MyHomePage(),
            "/toastPage": (context, param) => ToastPage(),
            "/routerPage": (context, param) => PageMultilevelRouter(),
            "/routerPage/subRouter1": (context, param) => SubRouterPage1(),
            "/routerPage/subRouter2": (context, param) => SubRouterPage2(),
            "/routerPage/subRouter1/subRouter2": (context, param) => SubRouterPage2(),
          },
          pageBuilder: (context, child, path, params) {
            return MaterialPage(child: child, name: path, arguments: params);
          },
          builder: (context, appRouter) {
            return MaterialApp.router(
              routerDelegate: appRouter,
              routeInformationParser: appRouter,
              routeInformationProvider: PlatformRouteInformationProvider(initialRouteInformation: RouteInformation(location: "/")),
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

class MyHomePage extends StatefulWidget with RouterDataWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();

  @override
  initData() {
    return null;
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
              var _loadingController = showLoading(context, msg: "Loading");
              Timer(Duration(seconds: 5), () {
                _loadingController.close();
              });
            },
            child: Text("Loading"),
          ),
          TextButton(
            onPressed: () {
              LoadingCall.of(context).call((state) => Future.value());
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

class ToastPage extends StatefulWidget with RouterDataWidget {
  @override
  _ToastPageState createState() => _ToastPageState();

  @override
  initData() {}
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
