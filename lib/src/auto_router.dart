import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

typedef RouterWidgetBuilder = Widget Function(BuildContext context, Map<String, String> params);

class AppRouterData {
  final String path;
  final Map<String, dynamic> params;

  AppRouterData({this.path, this.params});
}

class AppRouter extends RouterDelegate<AppRouterData> implements RouteInformationParser<AppRouterData> {
  AppRouterData _configuration;

  AppRouter._();

  Map<String, RouterWidgetBuilder> _routers = {};

  List<void Function()> _listener = [];

  @override
  void addListener(void Function() listener) {
    _listener.add(listener);
  }

  @override
  void removeListener(void Function() listener) {
    _listener.remove(listener);
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateInitialRoutes: (navigator, initialRoute) {
        return [
          MaterialPageRoute(builder: (context) {
            return _routers[_configuration.path]?.call(context, _configuration.params);
          }),
        ];
      },
    );
  }

  @override
  Future<bool> popRoute() async {
    return true;
  }

  @override
  Future<void> setNewRoutePath(AppRouterData configuration) {
    if (_routers.containsKey(_configuration.path)) {
      this._configuration = configuration;
      for (var item in _listener) {
        item?.call();
      }
    }
  }

  @override
  Future<AppRouterData> parseRouteInformation(RouteInformation routeInformation) async {
    var uri = Uri.parse(routeInformation.location);
    return AppRouterData(
      path: uri.path,
      params: uri.queryParameters,
    );
  }

  @override
  RouteInformation restoreRouteInformation(AppRouterData configuration) {
    var uri = Uri(path: configuration.path, queryParameters: configuration.params);
    return RouteInformation(location: uri.toString());
  }
}

class AutoRouter extends StatefulWidget {
  final Widget Function(BuildContext context, AppRouter appRouter) builder;
  final Map<String, RouterWidgetBuilder> routers;
  final String home;

  const AutoRouter({
    Key key,
    this.builder,
    this.routers,
    this.home,
  })  : assert(null != builder),
        assert(null != routers),
        super(key: key);

  static _AutoRouterState of(BuildContext context) {
    if (context is StatefulElement && context.state is _AutoRouterState) {
      return context.state as _AutoRouterState;
    }

    return context.findRootAncestorStateOfType<_AutoRouterState>();
  }

  @override
  _AutoRouterState createState() => _AutoRouterState();
}

class _AutoRouterState extends State<AutoRouter> {
  var appRouter = AppRouter._();

  @override
  void initState() {
    appRouter._routers = widget.routers;
    var uri = Uri.parse(widget.home ?? "/");
    appRouter._configuration = AppRouterData(
      path: uri.path,
      params: uri.queryParameters,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, appRouter);
  }

  void pushNamed(String name, {Map<String, dynamic> params}) {
    appRouter.setNewRoutePath(
      AppRouterData(
        path: name,
        params: params,
      ),
    );
  }
}
