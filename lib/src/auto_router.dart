import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

typedef RouterWidgetBuilder = RouterDataWidget Function(BuildContext context, Map<String, String> params);
typedef CheckRouter = bool Function(String path, Map<String, dynamic> params);
typedef PageBuilder = Page<dynamic> Function(BuildContext context, Widget child, String path, Map<String, dynamic> params);
typedef AutoRoutePredicate = bool Function(AppRouterData routerData);
typedef OpenSubRouter = bool Function(BuildContext context);

mixin RouterDataWidget<T> on Widget {
  T _data;

  T initData();

  T get data => _data;
}

class AppRouterData {
  final String path;
  final Map<String, dynamic> params;

  AppRouterData({this.path, this.params});
}

class _HistoryRouter {
  dynamic _data;
  bool _isInit = false;
  AppRouterData _routerData;
  RouterWidgetBuilder _builder;
  Completer result = new Completer.sync();

  _HistoryRouter(this._data, this._routerData, this._builder);
}

class _SubRouterDelegate extends RouterDelegate with ChangeNotifier {
  CheckRouter _checkRouter;
  Widget _widget;

  set page(Widget widget) {
    if (_widget != widget) {
      _widget = widget;
      notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: _widget,
    );
  }

  @override
  Future<bool> popRoute() {}

  @override
  Future<void> setNewRoutePath(configuration) {}
}

class SubRouter extends StatefulWidget {
  final CheckRouter checkRouter;
  final String prefixPath;

  const SubRouter({Key key, this.checkRouter, this.prefixPath})
      : assert(null != checkRouter || 0 != (prefixPath.length ?? 0)),
        super(key: key);

  @override
  _SubRouterState createState() => _SubRouterState();
}

class _SubRouterState extends State<SubRouter> {
  _SubRouterDelegate _delegate = _SubRouterDelegate();
  _AutoRouterState _routerState;

  @override
  void initState() {
    _delegate._checkRouter = widget.checkRouter ?? _checkRouter;
    super.initState();
    _routerState = AutoRouter.of(context);
    _routerState._addSubRouterDelegate(_delegate);
  }

  @override
  void dispose() {
    _routerState._removeSubRouterDelegate(_delegate);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SubRouter oldWidget) {
    _delegate._checkRouter = widget.checkRouter ?? _checkRouter;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Router(routerDelegate: _delegate);
  }

  bool _checkRouter(String path, Map<String, dynamic> param) {
    return 0 == (path?.indexOf(widget.prefixPath) ?? -1);
  }
}

class AppRouterDelegate extends RouterDelegate<AppRouterData>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRouterData>
    implements RouteInformationParser<AppRouterData> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  PageBuilder _pageBuilder;

  OpenSubRouter _openSubRouter;

  AppRouterDelegate._();

  Map<String, RouterWidgetBuilder> _routers = {};

  List<_SubRouterDelegate> _usbDelegateList = [];

  List<_HistoryRouter> _historyList = [];

  @override
  Widget build(BuildContext context) {
    var pages = <Page<dynamic>>[];
    for (var item in _historyList) {
      var wdiget = item._builder(context, item._routerData.params);
      if (!item._isInit) {
        item._data = wdiget.initData();
        item._isInit = true;
      }
      wdiget._data = item._data;

      var subRouter = _findSubDelegate(context, item._routerData);
      if (null == subRouter) {
        pages.add(_pageBuilder(context, wdiget, item._routerData.path, item._routerData.params));
      } else {
        subRouter._widget = wdiget;
      }
    }
    return Navigator(
      key: _navigatorKey,
      pages: pages,
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        notifyListeners();
        return true;
      },
    );
  }

  _SubRouterDelegate _findSubDelegate(BuildContext context, AppRouterData configuration) {
    if (_openSubRouter?.call(context) ?? false) {
      return null;
    }
    _SubRouterDelegate usbDelegate;
    for (var item in _usbDelegateList) {
      if (item._checkRouter(configuration.path, configuration.params)) {
        usbDelegate = item;
      }
    }
    return usbDelegate;
  }

  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  @override
  Future<void> setNewRoutePath(AppRouterData configuration) {
    if (_routers.containsKey(configuration.path)) {
      this._historyList.add(_HistoryRouter(null, configuration, _routers[configuration.path]));
      notifyListeners();
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

  @override
  AppRouterData get currentConfiguration => this._historyList.isEmpty ? null : this._historyList.last._routerData;

  Future<T> pushNamed<T>(String name, Map<String, dynamic> params) {
    if (!_routers.containsKey(name)) {
      throw "Not fond Router by $name";
    }

    var configuration = AppRouterData(
      path: name,
      params: params,
    );
    var router = _HistoryRouter(null, configuration, _routers[configuration.path]);
    this._historyList.add(router);
    notifyListeners();
    return router.result.future;
  }

  Future<T> pushNamedAndRemoveUntil<T>(String name, AutoRoutePredicate predicate, Map<String, dynamic> params) {
    _historyList.removeWhere((element) {
      if (predicate?.call(element._routerData) ?? false) {
        element.result.complete(null);
        return true;
      }
      return false;
    });

    if (!_routers.containsKey(name)) {
      throw "Not fond Router by $name";
    }

    var configuration = AppRouterData(
      path: name,
      params: params,
    );
    var router = _HistoryRouter(null, configuration, _routers[configuration.path]);
    this._historyList.add(router);
    notifyListeners();
    return router.result.future;
  }

  void popUntil(AutoRoutePredicate predicate) {
    _historyList.removeWhere((element) {
      if (predicate?.call(element._routerData) ?? false) {
        element.result.complete(null);
        return true;
      }
      return false;
    });
    notifyListeners();
  }

  void pop<T extends Object>(T result) {
    if (_historyList.isNotEmpty) {
      _historyList.last.result.complete(result);
      _historyList.removeLast();
    }
    notifyListeners();
  }
}

class AutoRouter extends StatefulWidget {
  final Widget Function(BuildContext context, AppRouterDelegate appRouter) builder;
  final Map<String, RouterWidgetBuilder> routers;
  final String home;
  final PageBuilder pageBuilder;
  final OpenSubRouter openSubRouter;

  const AutoRouter({
    Key key,
    this.builder,
    this.routers,
    this.home,
    this.pageBuilder,
    this.openSubRouter,
  })  : assert(null != builder),
        assert(null != routers),
        assert(null != pageBuilder),
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
  AppRouterDelegate _delegate = AppRouterDelegate._();

  @override
  void initState() {
    _delegate._routers = widget.routers;
    _delegate._openSubRouter = widget.openSubRouter;
    _delegate._pageBuilder = widget.pageBuilder;
    var uri = Uri.parse(widget.home ?? "/");

    _delegate._historyList.add(_HistoryRouter(
        null,
        AppRouterData(
          path: uri.path,
          params: uri.queryParameters,
        ),
        widget.routers[widget.home ?? "/"]));
    super.initState();
  }

  @override
  void didUpdateWidget(covariant AutoRouter oldWidget) {
    _delegate._pageBuilder = oldWidget.pageBuilder;
    _delegate._openSubRouter = widget.openSubRouter;
    super.didUpdateWidget(oldWidget);
  }

  void _addSubRouterDelegate(_SubRouterDelegate delegate) {
    _delegate._usbDelegateList.add(delegate);
  }

  void _removeSubRouterDelegate(_SubRouterDelegate delegate) {
    _delegate._usbDelegateList.remove(delegate);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _delegate);
  }

  Future<T> pushNamed<T extends Object>(String name, {Map<String, dynamic> params}) {
    return _delegate.pushNamed(name, params);
  }

  Future<T> pushNamedAndRemoveUntil<T extends Object>(
    String path,
    AutoRoutePredicate predicate, {
    Map<String, dynamic> arguments,
  }) {
    return _delegate.pushNamedAndRemoveUntil(path, predicate, arguments);
  }

  void pop<T extends Object>([T result]) {
    _delegate.pop(result);
  }

  void popUntil(AutoRoutePredicate predicate) {
    return _delegate.popUntil(predicate);
  }
}
