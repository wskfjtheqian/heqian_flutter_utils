import 'package:flutter/material.dart';
import 'package:heqian_flutter_utils/heqian_flutter_utils.dart';

bool checkRouter(AppRouterData route, [String path = "/routerPage/"]) => route?.path?.startsWith(path) ?? false;

class PageMultilevelRouter extends RouterDataWidget {
  @override
  _PageMultilevelRouterState createState() => _PageMultilevelRouterState();

  @override
  initData(BuildContext context) {}
}

class _PageMultilevelRouterState extends State<PageMultilevelRouter> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("多级路由")),
      body: Row(
        children: [
          SizedBox(
            width: 300,
            child: Column(
              children: [
                FlatButton(
                  child: Text("Route1"),
                  onPressed: () {
                    // AutoRouter.of(context).pushNamedAndRemoveUntil("/routerPage/subRouter1", (route) => checkRouter(route), arguments: {"id": "12"});
                  },
                ),
                FlatButton(
                  child: Text("Route2"),
                  onPressed: () {
                    // AutoRouter.of(context).pushNamedAndRemoveUntil("/routerPage/subRouter2", (route) => checkRouter(route));
                  },
                ),
                FlatButton(
                  child: Text("Route1/Route1"),
                  onPressed: () {
                    AutoRouter.of(context).pushNamed("/routerPage/subRouter1/subRouter3");
                  },
                ),
                FlatButton(
                  child: Text("Exit"),
                  onPressed: () {
                    AutoRouter.of(context).popUntil((route) => checkRouter(route, "/routerPage"));
                  },
                ),
              ],
            ),
          ),
          if (750 < MediaQuery.of(context).size.width) ...[
            VerticalDivider(),
            Expanded(
              child: SubRouter(
                prefixPath: "/routerPage/",
              ),
            )
          ]
        ],
      ),
    );
  }
}

class SubRouterPage1 extends RouterDataWidget {
  @override
  _SubRouterPage1State createState() => _SubRouterPage1State();

  @override
  initData(BuildContext context) {}
}

class _SubRouterPage1State extends State<SubRouterPage1> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isSubRouter(context)
          ? null
          : AppBar(
              title: Text("这是二级路由"),
            ),
      body: Container(
        color: Colors.blue,
        width: double.infinity,
        child: Column(
          children: [
            GestureDetector(
              child: Text("这是二级路由"),
              onTap: () {
                AutoRouter.of(context).pop();
              },
            ),
            if (750 < MediaQuery.of(context).size.width)
              Expanded(
                child: SubRouter(
                  prefixPath: "/routerPage/subRouter1/",
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SubRouterPage2Data extends RouterDataNotifier {
  String name = "Init Text";

  @override
  Future<void> init(BuildContext context) {
    value = true;
  }
}

class SubRouterPage2 extends RouterDataWidget<SubRouterPage2Data> {
  @override
  _SubRouterPage2State createState() => _SubRouterPage2State();

  @override
  SubRouterPage2Data initData(BuildContext context) {
    return SubRouterPage2Data();
  }
}

class _SubRouterPage2State extends State<SubRouterPage2> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isSubRouter(context)
          ? null
          : AppBar(
              title: Text("二级页面"),
            ),
      body: Container(
        width: double.infinity,
        color: Colors.amberAccent,
        child: Column(
          children: [
            Text(widget.data?.name ?? ""),
            FlatButton(
              child: Text("set net text"),
              onPressed: () {
                setState(() {
                  widget.data?.name = "new Text";
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SubRouterPage3 extends RouterDataWidget {
  @override
  _SubRouterPage3State createState() => _SubRouterPage3State();

  @override
  initData(BuildContext context) {}
}

class _SubRouterPage3State extends State<SubRouterPage3> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isSubRouter(context)
          ? null
          : AppBar(
              title: Text("三级页面"),
            ),
      body: Container(
        width: double.infinity,
        color: Colors.grey,
        child: Column(
          children: [
            GestureDetector(
              child: Text("三级页面"),
              onTap: () {
                AutoRouter.of(context).pop();
              },
            )
          ],
        ),
      ),
    );
  }
}
