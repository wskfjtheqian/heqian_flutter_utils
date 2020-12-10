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
          home: "/",
          routers: {
            "/": (context, param) => MyHomePage(),
            "/toastPage": (context, param) => ToastPage(),
            "/routerPage": (context, param) => RouterPage(),
            "/routerPage/subRouter1": (context, param) => SubRouterPage1(),
            "/routerPage/subRouter2": (context, param) => SubRouterPage2(),
          },
          openSubRouter: (context) {
            return 750 > MediaQuery.of(context).size.width;
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
              AutoRouter.of(context).pushNamed("/routerPage");
            },
            child: Text("AutoRouter"),
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

class RouterPage extends StatefulWidget with RouterDataWidget {
  @override
  _RouterPageState createState() => _RouterPageState();

  @override
  initData() {}
}

class _RouterPageState extends State<RouterPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 300,
            child: Column(
              children: [
                FlatButton(
                  child: Text("Route1"),
                  onPressed: () {
                    AutoRouter.of(context).pushNamedAndRemoveUntil("/routerPage/subRouter1", (route) => 0 == (route?.path?.indexOf("/routerPage/") ?? -1));
                  },
                ),
                FlatButton(
                  child: Text("Route2"),
                  onPressed: () {
                    AutoRouter.of(context).pushNamedAndRemoveUntil("/routerPage/subRouter2", (route) => 0 == (route?.path?.indexOf("/routerPage/") ?? -1));
                  },
                ),
                FlatButton(
                  child: Text("Exit"),
                  onPressed: () {
                    AutoRouter.of(context).popUntil((route) => 0 == (route?.path?.indexOf("/routerPage") ?? -1));
                  },
                ),
                FlatButton(
                  child: Text("Pop"),
                  onPressed: () {
                    Navigator.of(context).pop("");
                    AutoRouter.of(context).popUntil((route) => 0 == (route?.path?.indexOf("/routerPage") ?? -1));
                  },
                ),
              ],
            ),
          ),
          VerticalDivider(),
          Expanded(
            child: SubRouter(
              prefixPath: "/routerPage/",
            ),
          )
        ],
      ),
    );
  }
}

class SubRouterPage1 extends StatefulWidget with RouterDataWidget {
  @override
  _SubRouterPage1State createState() => _SubRouterPage1State();

  @override
  initData() {}
}

class _SubRouterPage1State extends State<SubRouterPage1> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
    );
  }
}

class SubRouterPage2 extends StatefulWidget with RouterDataWidget {
  @override
  _SubRouterPage2State createState() => _SubRouterPage2State();

  @override
  initData() {}
}

class _SubRouterPage2State extends State<SubRouterPage2> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amberAccent,
      child: FlatButton(
        child: Text("打开弹窗"),
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return AboutDialog(
                  applicationName: "AutoRouter",
                );
              });
        },
      ),
    );
  }
}
