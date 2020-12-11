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

class _DefualtWidget extends StatelessWidget with RouterDataWidget {
  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: Color(0xffffffff));
  }

  @override
  initData() {}
}

class _HistoryRouter {
  dynamic _data;
  bool _isInit = false;
  AppRouterData _routerData;
  RouterWidgetBuilder _builder;
  Completer result = new Completer.sync();

  _HistoryRouter(this._routerData, this._builder);
}

class _BaseRouterDelegate extends RouterDelegate<AppRouterData> with ChangeNotifier {
  List<_BaseRouterDelegate> _usbDelegateList = [];

  CheckRouter _checkRouter;

  WidgetBuilder _backgroundBuilder;

  _BaseRouterDelegate _parent;

  List<_HistoryRouter> get historyList {
    return _parent.historyList.where((element) {
      return _checkRouter(element._routerData.path, element._routerData.params);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<_HistoryRouter> builders = getWidgetBuilders(context);

    var wdiget = builders.last._builder(context, builders.last._routerData.params);
    if (!builders.last._isInit) {
      builders.last._data = wdiget.initData();
      builders.last._isInit = true;
    }
    wdiget._data = builders.last._data;

    return SizedBox(
      height: double.infinity,
      child: wdiget,
    );
  }

  List<_HistoryRouter> getWidgetBuilders(BuildContext context) {
    var builders = <_HistoryRouter>[_HistoryRouter(AppRouterData(), (context, params) => _backgroundBuilder?.call(context) ?? _DefualtWidget())];
    for (var item in historyList) {
      if (!_isSubRouter(context, item._routerData)) {
        builders.add(item);
      }
    }
    return builders;
  }

  bool _isSubRouter(BuildContext context, AppRouterData configuration) {
    for (var item in _usbDelegateList) {
      if (item._checkRouter(configuration.path, configuration.params)) {
        return true;
      }
    }
    return false;
  }

  void _addSubRouterDelegate(_BaseRouterDelegate delegate) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _usbDelegateList.add(delegate);
      notifyListeners();
    });
  }

  void _removeSubRouterDelegate(_BaseRouterDelegate delegate) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _usbDelegateList.remove(delegate);
      notifyListeners();
    });
  }

  @override
  Future<bool> popRoute() {}

  @override
  Future<void> setNewRoutePath(AppRouterData configuration) {}
}

class SubRouter extends StatefulWidget {
  final CheckRouter checkRouter;
  final String prefixPath;
  final WidgetBuilder defualtBuilder;

  const SubRouter({
    Key key,
    this.checkRouter,
    this.prefixPath,
    this.defualtBuilder,
  })  : assert(null != checkRouter || 0 != (prefixPath.length ?? 0)),
        super(key: key);

  @override
  _SubRouterState createState() => _SubRouterState<_BaseRouterDelegate, SubRouter>(_BaseRouterDelegate());
}

class _SubRouterState<E extends _BaseRouterDelegate, T extends SubRouter> extends State<T> {
  final E _delegate;
  _SubRouterState _routerState;

  _SubRouterState(this._delegate);

  @override
  void initState() {
    super.initState();
    _routerState = context.findAncestorStateOfType<_SubRouterState>();
    if (null != _routerState) {
      _delegate._parent = _routerState._delegate;
      _routerState._addSubRouterDelegate(_delegate);
    }
    _delegate._checkRouter = widget.checkRouter ?? _checkRouter;
    _delegate._backgroundBuilder = widget.defualtBuilder;
  }

  @override
  void dispose() {
    _routerState?._removeSubRouterDelegate(_delegate);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SubRouter oldWidget) {
    _delegate._checkRouter = oldWidget.checkRouter ?? _checkRouter;
    _delegate._backgroundBuilder = oldWidget.defualtBuilder;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Router(routerDelegate: _delegate);
  }

  bool _checkRouter(String path, Map<String, dynamic> param) {
    return path?.startsWith(widget.prefixPath) ?? false;
  }

  void _addSubRouterDelegate(_BaseRouterDelegate delegate) {
    _delegate._addSubRouterDelegate(delegate);
  }

  void _removeSubRouterDelegate(_BaseRouterDelegate delegate) {
    _delegate._removeSubRouterDelegate(delegate);
  }
}

class AppRouterDelegate extends _BaseRouterDelegate with PopNavigatorRouterDelegateMixin<AppRouterData> implements RouteInformationParser<AppRouterData> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  AppRouterDelegate._();

  PageBuilder _pageBuilder;

  Map<String, RouterWidgetBuilder> _routers = {};

  List<_HistoryRouter> _historyList = [];

  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  @override
  List<_HistoryRouter> get historyList => _historyList;

  @override
  Widget build(BuildContext context) {
    var buildes = getWidgetBuilders(context);

    var pages = <Page>[];
    for (var item in buildes) {
      var widget = item._builder(context, item._routerData.params);
      if (!item._isInit) {
        item._data = widget.initData();
        item._isInit = true;
      }
      widget._data = item._data;
      pages.add(_pageBuilder(context, widget, item._routerData.path, item._routerData.params));
    }

    return Navigator(
      key: _navigatorKey,
      pages: pages,
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        _historyList.removeWhere((element) {
          if (route.settings.name == element._routerData.path) {
            element.result.complete(result);
            return true;
          }
          if (element._routerData.path.startsWith(route.settings.name) ?? false) {
            element.result.complete(null);
            return true;
          }
          return false;
        });

        notifyListeners();
        return true;
      },
    );
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

  @override
  Future<void> setNewRoutePath(AppRouterData configuration) {
    if (_routers.containsKey(configuration.path)) {
      _addHistoryList(_HistoryRouter(configuration, _routers[configuration.path]));
    }
  }

  _HistoryRouter _addHistoryList(_HistoryRouter historyRouter) {
    this._historyList.add(historyRouter);
    notifyListeners();
    return historyRouter;
  }

  Future<T> pushNamed<T>(String name, Map<String, dynamic> params) {
    if (!_routers.containsKey(name)) {
      throw "Not fond Router by $name";
    }

    var configuration = AppRouterData(
      path: name,
      params: params,
    );
    var router = _addHistoryList(_HistoryRouter(configuration, _routers[configuration.path]));
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
    var router = _addHistoryList(_HistoryRouter(configuration, _routers[configuration.path]));
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

class AutoRouter extends SubRouter {
  final Widget Function(BuildContext context, AppRouterDelegate appRouter) builder;
  final Map<String, RouterWidgetBuilder> routers;
  final String home;
  final PageBuilder pageBuilder;

  const AutoRouter({
    Key key,
    this.builder,
    this.routers,
    this.home,
    this.pageBuilder,
  })  : assert(null != builder),
        assert(null != routers),
        assert(null != pageBuilder),
        super(key: key, prefixPath: home);

  static _AutoRouterState of(BuildContext context) {
    if (context is StatefulElement && context.state is _AutoRouterState) {
      return context.state as _AutoRouterState;
    }

    return context.findRootAncestorStateOfType<_AutoRouterState>();
  }

  @override
  _AutoRouterState createState() => _AutoRouterState(AppRouterDelegate._());
}

class _AutoRouterState extends _SubRouterState<AppRouterDelegate, AutoRouter> {
  _AutoRouterState(AppRouterDelegate delegate) : super(delegate);

  @override
  void initState() {
    _delegate._routers = widget.routers;
    _delegate._pageBuilder = widget.pageBuilder;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant AutoRouter oldWidget) {
    _delegate._routers = oldWidget.routers;
    _delegate._pageBuilder = oldWidget.pageBuilder;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _delegate);
  }

  Future<T> pushNamed<T extends Object>(
    String name, {
    Map<String, dynamic> params,
  }) {
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

bool isSubRouter(BuildContext context) {
  return  context.findRootAncestorStateOfType<_SubRouterState>() != context.findAncestorStateOfType<_SubRouterState>();
}
