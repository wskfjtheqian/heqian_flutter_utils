import 'package:flutter/material.dart';
import 'package:heqian_flutter_utils/heqian_flutter_utils.dart';

bool checkRouter(AppRouterData route, [String path = "/routerPage/"]) => route?.path?.startsWith(path) ?? false;

class PageMultilevelRouter extends StatefulWidget with RouterDataWidget {
  @override
  _PageMultilevelRouterState createState() => _PageMultilevelRouterState();

  @override
  initData() {}
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
                    AutoRouter.of(context).pushNamedAndRemoveUntil("/routerPage/subRouter1", (route) => checkRouter(route));
                  },
                ),
                FlatButton(
                  child: Text("Route2"),
                  onPressed: () {
                    AutoRouter.of(context).pushNamedAndRemoveUntil("/routerPage/subRouter2", (route) => checkRouter(route));
                  },
                ),
                FlatButton(
                  child: Text("Route1/Route1"),
                  onPressed: () {
                    AutoRouter.of(context).pushNamed("/routerPage/subRouter1/subRouter2");
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
      child: Column(
        children: [
          Text("这是三级路由"),
          Expanded(
            child: SubRouter(
              prefixPath: "/routerPage/subRouter1/",
            ),
          ),
        ],
      ),
    );
  }
}

class SubRouterPage2Data {
  String name = "Init Text";
}

class SubRouterPage2 extends StatefulWidget with RouterDataWidget<SubRouterPage2Data> {
  @override
  _SubRouterPage2State createState() => _SubRouterPage2State();

  @override
  SubRouterPage2Data initData() {
    return SubRouterPage2Data();
  }
}

class _SubRouterPage2State extends State<SubRouterPage2> {
  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
