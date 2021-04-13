import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

typedef RouterWidgetBuilder = RouterDataWidget Function(BuildContext context, Map<String, dynamic> params);
typedef CheckRouter = bool Function(String path, Map<String, dynamic> params);
typedef PageBuilder = Page<dynamic> Function(BuildContext context, Widget child, String path, Map<String, dynamic> params);
typedef AutoRoutePredicate = bool Function(AppRouterData routerData);
typedef OpenSubRouter = bool Function(BuildContext context);

// ignore: must_be_immutable
abstract class RouterDataWidget<T extends ChangeNotifier> extends StatefulWidget {
  T _data;

  RouterDataWidget({Key key}) : super(key: key);

  T initData(BuildContext context);

  T get data => _data;

  set data(T value) {
    _data = value;
  }
}

abstract class RouterDataListener<T extends RouterDataWidget> extends State<T> {
  get data {
    return widget.data;
  }

  @override
  void initState() {
    data?.addListener(_onChangeNotifier);
    super.initState();
  }

  void _onChangeNotifier() {
    setState(() {});
  }

  @override
  void dispose() {
    data?.removeListener(_onChangeNotifier);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    data?.addListener(_onChangeNotifier);
    oldWidget.data?.removeListener(_onChangeNotifier);
    super.didUpdateWidget(oldWidget);
  }
}

class AppRouterData {
  final String path;
  final Map<String, dynamic> params;

  AppRouterData({this.path, this.params});
}

class _DefualtWidget extends RouterDataWidget {
  @override
  __DefualtWidgetState createState() => __DefualtWidgetState();

  @override
  ChangeNotifier initData(BuildContext context) {
    return null;
  }
}

class __DefualtWidgetState extends State<_DefualtWidget> {
  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: Color(0xffffffff));
  }
}

class _HistoryRouter {
  ChangeNotifier _data;
  bool _isInit = false;
  AppRouterData _routerData;
  RouterWidgetBuilder _builder;
  Completer result = new Completer.sync();

  _HistoryRouter(this._routerData, this._builder);
}

class _BaseRouterDelegate extends RouterDelegate<List<AppRouterData>> with ChangeNotifier {
  List<_BaseRouterDelegate> _usbDelegateList = [];

  CheckRouter _checkRouter;

  WidgetBuilder _backgroundBuilder;

  _BaseRouterDelegate _parent;

  PageBuilder _pageBuilder;

  Page<dynamic> pageBuilder(BuildContext context, Widget child, String path, Map<String, dynamic> params) {
    return (_pageBuilder ?? _parent.pageBuilder).call(context, child, path, params);
  }

  List<_HistoryRouter> get historyList {
    return _parent.historyList.where((element) {
      return _checkRouter(element._routerData?.path, element._routerData?.params);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    var buildes = getWidgetBuilders(context);

    var pages = <Page>[];
    for (var item in buildes) {
      var widget = item._builder(context, item._routerData.params);
      if (!item._isInit) {
        item._data = widget.initData(context);
        item._isInit = true;
      }
      widget._data = item._data;
      pages.add(pageBuilder(context, widget, item._routerData?.path, item._routerData.params));
    }

    return Navigator(
      pages: pages,
      onPopPage: (route, result) {
        return Navigator.of(context).widget.onPopPage(route, result);
      },
    );
  }

  List<_HistoryRouter> getWidgetBuilders(BuildContext context) {
    var builders = <_HistoryRouter>[];
    for (var item in historyList) {
      if (null != item._builder && !_isSubRouter(context, item._routerData)) {
        builders.add(item);
      }
    }
    if (builders.isEmpty) {
      builders.add(_HistoryRouter(AppRouterData(path: "/"), (context, params) => _backgroundBuilder?.call(context) ?? _DefualtWidget()));
    }
    return builders;
  }

  bool _isSubRouter(BuildContext context, AppRouterData configuration) {
    for (var item in _usbDelegateList) {
      if (item._checkRouter(configuration?.path, configuration?.params)) {
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
  Future<bool> popRoute() async {
    return true;
  }

  @override
  Future<void> setNewRoutePath(List<AppRouterData> configuration) async {}
}

class SubRouter extends StatefulWidget {
  final CheckRouter checkRouter;
  final String prefixPath;
  final WidgetBuilder backgroundBuilder;
  final PageBuilder pageBuilder;

  const SubRouter({
    Key key,
    this.checkRouter,
    this.prefixPath,
    this.backgroundBuilder,
    this.pageBuilder,
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
    _delegate._pageBuilder = widget.pageBuilder;
    _routerState = context.findAncestorStateOfType<_SubRouterState>();
    if (null != _routerState) {
      _delegate._parent = _routerState._delegate;
      _routerState._addSubRouterDelegate(_delegate);
    }
    _delegate._checkRouter = widget.checkRouter ?? _checkRouter;
    _delegate._backgroundBuilder = widget.backgroundBuilder;
    super.initState();
  }

  @override
  void dispose() {
    _routerState?._removeSubRouterDelegate(_delegate);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SubRouter oldWidget) {
    _delegate._checkRouter = oldWidget.checkRouter ?? _checkRouter;
    _delegate._backgroundBuilder = oldWidget.backgroundBuilder;
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

  Future<T> pushNamed<T extends Object>(
    String name, {
    Map<String, dynamic> params,
  }) {
    return _routerState.pushNamed(name, params: params);
  }

  Future<T> pushNamedAndRemoveUntil<T extends Object>(
    String path,
    AutoRoutePredicate predicate, {
    Map<String, dynamic> arguments,
  }) {
    return _routerState.pushNamedAndRemoveUntil(path, predicate, arguments: arguments);
  }

  void pop<T extends Object>([T result]) {
    return _routerState.popUntil((routerData) {
      return _delegate._checkRouter(routerData.path, routerData.params);
    });
  }

  void popUntil(AutoRoutePredicate predicate) {
    return _routerState.popUntil(predicate);
  }
}

class AppRouterDelegate extends _BaseRouterDelegate
    with PopNavigatorRouterDelegateMixin<List<AppRouterData>>
    implements RouteInformationParser<List<AppRouterData>> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  RouteInformationProvider _provider;

  RouteInformationProvider get provider => _provider;

  AppRouterDelegate._();

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
        item._data = widget.initData(navigatorKey.currentState?.overlay?.context);
        item._isInit = true;
      }
      widget._data = item._data;
      pages.add(_pageBuilder(context, widget, item._routerData?.path, item._routerData.params));
    }

    return Navigator(
      key: _navigatorKey,
      pages: pages,
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        _historyList.removeWhere((element) {
          if (route.settings.name == element._routerData?.path) {
            element.result.complete(result);
            return true;
          }
          if (element._routerData?.path?.startsWith(route.settings.name) ?? false) {
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

  bool _checkHistory(String path) {
    for (var item in historyList) {
      if (item._routerData?.path?.startsWith(path) ?? false) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<List<AppRouterData>> parseRouteInformation(RouteInformation routeInformation) async {
    var uri = Uri.parse(routeInformation.location);
    return _paresPath(uri.path, uri.queryParameters);
  }

  @override
  RouteInformation restoreRouteInformation(List<AppRouterData> configuration) {
    var last = configuration.last;
    var uri = Uri(path: last?.path ?? "", queryParameters: last?.params);
    return RouteInformation(location: uri.toString());
  }

  @override
  List<AppRouterData> get currentConfiguration => [this._historyList.isEmpty ? null : this._historyList.last._routerData];

  @override
  Future<void> setNewRoutePath(List<AppRouterData> configuration) async {
    if (configuration.isNotEmpty) {
      await _addHistoryList(configuration);
    }
  }

  Future<_HistoryRouter> _addHistoryList(List<AppRouterData> configuration) async {
    if (configuration.isNotEmpty) {
      for (var item in configuration) {
        this._historyList.add(_HistoryRouter(item, _routers[item.path]));
        notifyListeners();
        var completer = Completer();
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          completer.complete();
        });
        await completer.future.timeout(Duration(seconds: 2), onTimeout: () => null);
      }
      return this._historyList.last;
    }
    return null;
  }

  Future<T> pushNamed<T>(String name, Map<String, dynamic> params) async {
    if (!_routers.containsKey(name)) {
      throw "Not fond Router by $name";
    }

    var router = await _addHistoryList(_paresPath(name, params));
    return router?.result?.future;
  }

  Future<T> pushNamedAndRemoveUntil<T>(String name, AutoRoutePredicate predicate, Map<String, dynamic> params) async {
    _historyList.removeWhere((element) {
      if (predicate?.call(element._routerData) ?? false) {
        element.result.complete(null);
        element._data?.dispose();
        return true;
      }
      return false;
    });

    if (!_routers.containsKey(name)) {
      throw "Not fond Router by $name";
    }

    var router = await _addHistoryList(_paresPath(name, params));
    return router?.result?.future;
  }

  void popUntil(AutoRoutePredicate predicate) {
    _historyList.removeWhere((element) {
      if (predicate?.call(element._routerData) ?? false) {
        element.result.complete(null);
        element._data?.dispose();
        return true;
      }
      return false;
    });
    notifyListeners();
  }

  void pop<T extends Object>(T result) {
    if (_historyList.isNotEmpty) {
      _historyList.last.result.complete(result);
      _historyList.last._data?.dispose();
      _historyList.removeLast();
    }
    notifyListeners();
  }

  List<AppRouterData> _paresPath(String name, Map<String, dynamic> params) {
    var paths = name.split("/");
    var ret = <AppRouterData>[];
    var path = "";
    for (var i = 1; i < paths.length; i++) {
      path += "/" + paths[i];
      if (!_checkHistory(path)) {
        ret.add(
          AppRouterData(
            path: path,
            params: params,
          ),
        );
      }
    }
    return ret;
  }
}

class AutoRouter extends SubRouter {
  final Widget Function(BuildContext context, AppRouterDelegate appRouter) builder;
  final Map<String, RouterWidgetBuilder> routers;
  final String home;

  const AutoRouter({
    Key key,
    this.builder,
    this.routers,
    this.home,
    PageBuilder pageBuilder,
    WidgetBuilder backgroundBuilder,
  })  : assert(null != builder),
        assert(null != routers),
        assert(null != pageBuilder),
        super(
          key: key,
          prefixPath: home,
          backgroundBuilder: backgroundBuilder,
          pageBuilder: pageBuilder,
        );

  static _SubRouterState of(BuildContext context) {
    if (context is StatefulElement && context.state is _SubRouterState) {
      return context.state as _SubRouterState;
    }

    return context.findAncestorStateOfType<_SubRouterState>();
  }

  @override
  _AutoRouterState createState() => _AutoRouterState(AppRouterDelegate._());
}

class _AutoRouterState extends _SubRouterState<AppRouterDelegate, AutoRouter> {
  _AutoRouterState(AppRouterDelegate delegate) : super(delegate);
  String _home = WidgetsBinding.instance.window.defaultRouteName;

  @override
  void initState() {
    if (null != widget.home) {
      _home = widget.home;
    }
    _delegate._provider = PlatformRouteInformationProvider(initialRouteInformation: RouteInformation(location: _home));
    _delegate._routers = widget.routers;
    _delegate._backgroundBuilder = widget.backgroundBuilder;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant AutoRouter oldWidget) {
    _delegate._routers = oldWidget.routers;
    _delegate._pageBuilder = oldWidget.pageBuilder;
    _delegate._backgroundBuilder = oldWidget.backgroundBuilder;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder?.call(context, _delegate);
  }

  @override
  Future<T> pushNamed<T extends Object>(
    String name, {
    Map<String, dynamic> params,
  }) {
    return _delegate.pushNamed(name, params);
  }

  @override
  Future<T> pushNamedAndRemoveUntil<T extends Object>(
    String path,
    AutoRoutePredicate predicate, {
    Map<String, dynamic> arguments,
  }) {
    return _delegate.pushNamedAndRemoveUntil(path, predicate, arguments);
  }

  @override
  void pop<T extends Object>([T result]) {
    _delegate.pop(result);
  }

  @override
  void popUntil(AutoRoutePredicate predicate) {
    return _delegate.popUntil(predicate);
  }
}

bool isSubRouter(BuildContext context) {
  return context.findRootAncestorStateOfType<_SubRouterState>() != context.findAncestorStateOfType<_SubRouterState>();
}
