import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:heqian_flutter_utils/heqian_flutter_utils.dart';

typedef RouterWidgetBuilder = RouterDataWidget Function(BuildContext context, Map<String, dynamic>? params);
typedef CheckRouter = bool Function(String? path, Map<String, dynamic>? params);
typedef AutoRoutePredicate = bool Function(AppRouterData routerData);
typedef HashRoute = bool Function(AppRouterData routerData);
typedef OpenSubRouter = bool Function(BuildContext context);
typedef RouterBuilder = RouterDataWidget Function(BuildContext context);
typedef IsDialog = bool Function(BuildContext context, BaseRouterDelegate delegate);

abstract class RouterDataNotifier extends ValueNotifier<bool> {
  bool _dispose = false;

  RouterDataNotifier() : super(false);

  Future<void> init(BuildContext context);

  Future<void> initData(BuildContext context) async {
    try {
      await init(context);
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    if (!_dispose) {
      super.dispose();
      _dispose = true;
    }
  }

  @override
  void addListener(VoidCallback listener) {
    if (!_dispose) {
      super.addListener(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    if (!_dispose) {
      super.removeListener(listener);
    }
  }

  @override
  set value(bool newValue) {
    if (!_dispose) {
      super.value = newValue;
    }
  }

  @override
  void notifyListeners() {
    if (!_dispose) {
      super.notifyListeners();
    }
  }
}

abstract class RouterDataWidget<T extends RouterDataNotifier> extends StatefulWidget {
  T? _data;

  RouterDataWidget({Key? key}) : super(key: key);

  T? initData(BuildContext? context);

  T? get data => _data;

  set data(T? value) {
    _data = value;
  }
}

abstract class RouterDataWidgetState<T extends RouterDataWidget> extends State<T> {
  @override
  void initState() {
    super.initState();
    widget.data?.addListener(_valueChanged);
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    if (oldWidget.data != widget.data) {
      oldWidget.data?.removeListener(_valueChanged);
      widget.data?.addListener(_valueChanged);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.data?.removeListener(_valueChanged);
    super.dispose();
  }

  void _valueChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (null == widget.data || widget.data!.value) {
      return buildContent(context);
    }
    return buildInit(context);
  }

  Widget buildInit(BuildContext context) {
    return Container(
      color: Colors.white,
    );
  }

  Widget buildContent(BuildContext context);
}

class _DefaultWidget extends RouterDataWidget {
  @override
  __DefaultWidgetState createState() => __DefaultWidgetState();

  @override
  initData(BuildContext? context) {}
}

class __DefaultWidgetState extends State<_DefaultWidget> {
  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: Color(0xffffffff));
  }
}

class AppRouterData {
  final String path;
  final Map<String, dynamic>? params;

  AppRouterData({required this.path, this.params});

  @override
  String toString() {
    return 'AppRouterData{path: $path, params: $params}';
  }
}

class _HistoryRouter {
  RouterDataNotifier? _data;
  bool _isInit = false;
  AutoPath _path;
  AppRouterData _routerData;
  RouterWidgetBuilder _builder;
  Completer result = new Completer.sync();
  final List<WillPopCallback> _willPopCallbacks = <WillPopCallback>[];

  _HistoryRouter(this._routerData, this._path, this._builder);

  @override
  String toString() {
    return '_HistoryRouter{_routerData: $_routerData}';
  }
}

class SizePage {
  final double? width;
  final double? height;

  SizePage(this.width, this.height);
}

abstract class PageSize {
  SizePage get size;
}

class BaseRouterDelegate extends RouterDelegate<List<AppRouterData>> with ChangeNotifier {
  List<BaseRouterDelegate> _usbDelegateList = [];

  late CheckRouter _checkRouter;

  RouterBuilder? _backgroundBuilder;

  late BaseRouterDelegate _parent;

  String? prefixPath;

  Page<dynamic> pageBuilder(BuildContext context, RouterDataWidget dataWidget, _HistoryRouter router) {
    Widget child = AutoRoutePopModel(child: dataWidget, router: router);
    bool isDialog = router._path.isDialog?.call(context, this) ?? false;
    if (isDialog) {
      var size = SizePage(640, 768);
      if (dataWidget is PageSize) {
        size = (dataWidget as PageSize).size;
      }
      child = Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              boxShadow: [
                BoxShadow(color: Color(0x40888888), blurRadius: 8, spreadRadius: 4, offset: Offset(0, 3)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              child: SizedBox(
                child: child,
                width: size.width,
                height: size.height,
              ),
            ),
          ),
        ),
      );
    }
    return AutoRoutePage(
      key: ValueKey(isDialog.toString() + router._routerData.path + router._routerData.params.toString()),
      child: child,
      name: router._routerData.path,
      arguments: router._routerData.params,
    );
  }

  AutoPath getAutoPath(String path) {
    return _parent.getAutoPath(path);
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    for (var item in _usbDelegateList) {
      item.notifyListeners();
    }
  }

  List<_HistoryRouter> get historyList {
    var ret = <_HistoryRouter>[];
    for (var item in _parent.historyList) {
      if (_checkRouter(item._routerData.path, item._routerData.params)) {
        ret.add(item);
      }
    }
    return ret;
  }

  @override
  Widget build(BuildContext context) {
    var builders = getWidgetBuilders(context);

    var pages = <Page>[];
    for (var router in builders) {
      pages.add(pageBuilder(
        context,
        router._builder(context, router._routerData.params),
        router,
      ));
    }

    return Navigator(
      pages: pages,
      onPopPage: (route, result) {
        return Navigator.of(context).widget.onPopPage!(route, result);
      },
    );
  }

  List<_HistoryRouter> getWidgetBuilders(BuildContext context) {
    var builders = <_HistoryRouter>[];
    for (var item in historyList) {
      var ret = _isSubRouter(context, item._routerData);
      if (ret.sub || ret.dialog) {
        continue;
      }
      builders.add(item);
    }
    if (builders.isEmpty) {
      builders.add(_HistoryRouter(AppRouterData(path: "/"), AutoPath("/"), (context, params) => _backgroundBuilder?.call(context) ?? _DefaultWidget()));
    }

    return builders;
  }

  IsSub _isSubRouter(BuildContext context, AppRouterData? configuration) {
    var isDialogCall = getAutoPath(configuration!.path).isDialog;
    for (var item in _usbDelegateList) {
      var dialog = isDialogCall?.call(context, item) ?? false;
      if (!dialog && item._checkRouter(configuration.path, configuration.params)) {
        return IsSub(
          sub: true,
          dialog: dialog,
        );
      }
      var ret = item._isSubRouter(context, configuration);
      if (ret.sub) {
        return ret;
      }
    }
    return IsSub(sub: false, dialog: isDialogCall?.call(context, this) ?? false);
  }

  void _addSubRouterDelegate(BaseRouterDelegate delegate) {
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      _usbDelegateList.add(delegate);
      notifyListeners();
    });
  }

  void _removeSubRouterDelegate(BaseRouterDelegate delegate) {
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
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

class IsSub {
  final bool sub;
  final bool dialog;

  IsSub({required this.sub, required this.dialog});
}

class AppRouterDelegate extends BaseRouterDelegate
    with PopNavigatorRouterDelegateMixin<List<AppRouterData>>
    implements RouteInformationParser<List<AppRouterData>> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  RouteInformationProvider? _provider;

  RouteInformationProvider get provider => _provider!;

  AppRouterDelegate._();

  Map<AutoPath, RouterWidgetBuilder> _routers = {};

  List<_HistoryRouter> _historyList = [];

  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  @override
  List<_HistoryRouter> get historyList => _historyList;

  @override
  Widget build(BuildContext context) {
    var builders = getWidgetBuilders(context);

    var pages = <Page>[];
    for (var router in builders) {
      pages.add(pageBuilder(
        context,
        router._builder(context, router._routerData.params),
        router,
      ));
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
            if (!element.result.isCompleted) {
              element.result.complete(result);
            }
            element._data?.dispose();
            return true;
          }
          if (element._routerData.path.startsWith(route.settings.name ?? "")) {
            if (!element.result.isCompleted) {
              element.result.complete(null);
            }
            element._data?.dispose();
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
      if (item._routerData.path.startsWith(path)) {
        return true;
      }
    }
    return false;
  }

  @override
  List<_HistoryRouter> getWidgetBuilders(BuildContext context) {
    var builders = <_HistoryRouter>[];
    for (var item in historyList) {
      var ret = _isSubRouter(context, item._routerData);
      if (ret.sub) {
        continue;
      }

      builders.add(item);
    }
    if (builders.isEmpty) {
      builders.add(_HistoryRouter(AppRouterData(path: "/"), AutoPath("/"), (context, params) => _backgroundBuilder?.call(context) ?? _DefaultWidget()));
    }
    return builders;
  }

  @override
  Future<List<AppRouterData>> parseRouteInformation(RouteInformation routeInformation) async {
    var uri = Uri.parse(routeInformation.location!);
    return _paresPath(uri.path, uri.queryParameters);
  }

  @override
  RouteInformation restoreRouteInformation(List<AppRouterData> configuration) {
    var last = configuration.last;
    var uri = Uri(path: last.path, queryParameters: last.params);
    return RouteInformation(location: uri.toString());
  }

  @override
  List<AppRouterData>? get currentConfiguration => [this._historyList.isEmpty ? AppRouterData(path: "") : this._historyList.last._routerData];

  @override
  Future<void> setNewRoutePath(List<AppRouterData> configuration) async {
    if (configuration.isNotEmpty) {
      if (this._historyList.isNotEmpty) {
        if (Uri(path: configuration.last.path, queryParameters: configuration.last.params) ==
            Uri(path: this._historyList.last._routerData.path, queryParameters: this._historyList.last._routerData.params)) {
          return;
        }
      }
      await _addHistoryList(configuration);
    }
  }

  AutoPath? _findKey(String path) {
    for (var item in _routers.entries) {
      if (item.key.path == path) {
        return item.key;
      }
    }
    return null;
  }

  Future<_HistoryRouter?> _addHistoryList(List<AppRouterData> configuration) async {
    if (configuration.isNotEmpty) {
      for (var item in configuration) {
        var key = _findKey(item.path);
        if (null != key) {
          this._historyList.add(_HistoryRouter(item, key, _routers[key]!));
        }
      }
      notifyListeners();
      return this._historyList.last;
    }
    return null;
  }

  Future<T?> pushNamed<T>(String name, Map<String, dynamic>? params) async {
    if (!_routers.containsKey(AutoPath(name))) {
      throw "Not fond Router by $name";
    }

    var router = await _addHistoryList(_paresPath(name, params ?? {}));
    return await router!.result.future;
  }

  Future<T?> pushNamedAndRemoveUntil<T>(String name, AutoRoutePredicate? predicate, Map<String, dynamic>? params) async {
    _historyList.removeWhere((element) {
      if (predicate?.call(element._routerData) ?? false) {
        if (!element.result.isCompleted) {
          element.result.complete(null);
        }
        element._data?.dispose();
        return true;
      }
      return false;
    });

    if (!_routers.containsKey(AutoPath(name))) {
      throw "Not fond Router by $name";
    }

    var router = await _addHistoryList(_paresPath(name, params ?? {}));
    return await router!.result.future;
  }

  void popUntil(AutoRoutePredicate predicate) {
    _historyList.removeWhere((element) {
      if (predicate.call(element._routerData)) {
        if (!element.result.isCompleted) {
          element.result.complete(null);
        }
        element._data?.dispose();
        return true;
      }
      return false;
    });
    notifyListeners();
  }

  void pop<T extends Object>(T? result) {
    if (_historyList.isNotEmpty) {
      var last = _historyList.last;
      _historyList.removeLast();
      if (!last.result.isCompleted) {
        last.result.complete(result);
      }
      last._data?.dispose();
    }
    notifyListeners();
  }

  List<AppRouterData> _paresPath(String name, Map<String, dynamic> params) {
    var paths = name.split("/");
    var ret = <AppRouterData>[];
    var path = "";
    for (var i = 1; i < paths.length; i++) {
      path += "/" + paths[i];
      if (!_checkHistory(path) || path == name) {
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

  @override
  AutoPath getAutoPath(String path) {
    var temp = AutoPath(path);
    for (var item in _routers.entries) {
      if (item.key == temp) {
        return item.key;
      }
    }
    return null!;
  }

  bool hashRouter(HashRoute hashRoute) {
    for (var item in _historyList) {
      if (hashRoute(item._routerData)) {
        return true;
      }
    }
    return false;
  }

  Future<bool> didPopRoute() async {
    if (_historyList.isNotEmpty) {
      var last = _historyList.last;
      for (final WillPopCallback callback in List<WillPopCallback>.from(last._willPopCallbacks)) {
        if (await callback() != true) return true;
      }

      _historyList.removeLast();
      if (!last.result.isCompleted) {
        last.result.complete(null);
      }
      last._data?.dispose();
    }
    notifyListeners();

    if (_historyList.isEmpty) {
      return false;
    }
    return true;
  }
}

class SubRouter extends StatefulWidget {
  final CheckRouter? checkRouter;
  final String? prefixPath;
  final RouterBuilder? backgroundBuilder;

  const SubRouter({
    Key? key,
    this.checkRouter,
    this.prefixPath,
    this.backgroundBuilder,
  })  : assert(null != checkRouter || 0 != (prefixPath?.length ?? 0)),
        super(key: key);

  static _SubRouterState? of(BuildContext context) {
    return context.findAncestorStateOfType<_SubRouterState>();
  }

  @override
  _SubRouterState createState() => _SubRouterState<BaseRouterDelegate, SubRouter>(BaseRouterDelegate());
}

class _SubRouterState<E extends BaseRouterDelegate, T extends SubRouter> extends State<T> {
  final E _delegate;
  _SubRouterState? _routerState;

  _SubRouterState(this._delegate);

  @override
  void initState() {
    _routerState = context.findAncestorStateOfType<_SubRouterState>();
    if (null != _routerState) {
      _delegate._parent = _routerState!._delegate;
      _routerState!._addSubRouterDelegate(_delegate);
    }
    _delegate._checkRouter = widget.checkRouter ?? _checkRouter;
    _delegate._backgroundBuilder = widget.backgroundBuilder;
    _delegate.prefixPath = widget.prefixPath;

    super.initState();
  }

  @override
  void dispose() {
    _routerState?._removeSubRouterDelegate(_delegate);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    _delegate._checkRouter = oldWidget.checkRouter ?? _checkRouter;
    _delegate._backgroundBuilder = oldWidget.backgroundBuilder;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Router(routerDelegate: _delegate);
  }

  bool _checkRouter(String? path, Map<String, dynamic>? params) {
    return path?.startsWith(widget.prefixPath!) ?? false;
  }

  void _addSubRouterDelegate(BaseRouterDelegate delegate) {
    _delegate._addSubRouterDelegate(delegate);
  }

  void _removeSubRouterDelegate(BaseRouterDelegate delegate) {
    _delegate._removeSubRouterDelegate(delegate);
  }

  Future<T?> pushNamed<T extends Object>(
    String name, {
    Map<String, dynamic>? params,
  }) {
    return _routerState!.pushNamed(name, params: params);
  }

  Future<T?> pushNamedAndRemoveUntil<T extends Object>(
    String path, {
    AutoRoutePredicate? predicate,
    Map<String, dynamic>? params,
  }) {
    return _routerState!.pushNamedAndRemoveUntil(path, predicate: predicate, params: params);
  }

  void pop<T extends Object>([T? result]) {
    return _routerState!.popUntil((routerData) {
      return _delegate._checkRouter(routerData.path, routerData.params);
    });
  }

  void popUntil(AutoRoutePredicate predicate) {
    return _routerState!.popUntil(predicate);
  }

  Size? get size {
    return context.findRenderObject()?.paintBounds.size;
  }
}

class AutoPath {
  final String path;
  final IsDialog? isDialog;

  AutoPath(this.path, [this.isDialog]);

  @override
  bool operator ==(Object other) => identical(this, other) || other is AutoPath && runtimeType == other.runtimeType && path == other.path;

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() {
    return path;
  }
}

class AutoRouter extends SubRouter {
  final Widget Function(BuildContext context, AppRouterDelegate appRouter) builder;
  final Map<AutoPath, RouterWidgetBuilder> routers;
  final String? home;

  const AutoRouter({
    Key? key,
    required this.builder,
    required this.routers,
    this.home,
    RouterBuilder? backgroundBuilder,
  }) : super(
          key: key,
          prefixPath: home,
          backgroundBuilder: backgroundBuilder,
        );

  static AutoRouterState of(BuildContext context) {
    if (context is StatefulElement && context.state is _SubRouterState) {
      return context.state as AutoRouterState;
    }

    return context.findAncestorStateOfType<AutoRouterState>()!;
  }

  @override
  AutoRouterState createState() => AutoRouterState(AppRouterDelegate._());
}

class AutoRouterState extends _SubRouterState<AppRouterDelegate, AutoRouter> with WidgetsBindingObserver {
  AutoRouterState(AppRouterDelegate delegate) : super(delegate);
  String _home = WidgetsBinding.instance!.window.defaultRouteName;

  bool hashRouter(HashRoute hashRoute) {
    return _delegate.hashRouter(hashRoute);
  }

  void addListener(VoidCallback listener) {
    return _delegate.addListener(listener);
  }

  void removeListener(VoidCallback listener) {
    return _delegate.removeListener(listener);
  }

  @override
  Future<bool> didPopRoute() {
    return _delegate.didPopRoute();
  }

  @override
  void initState() {
    if (null != widget.home) {
      _home = widget.home!;
    }
    _delegate._provider = PlatformRouteInformationProvider(initialRouteInformation: RouteInformation(location: _home));
    _delegate._routers = widget.routers;
    _delegate._backgroundBuilder = widget.backgroundBuilder;
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AutoRouter oldWidget) {
    _delegate._routers = oldWidget.routers;
    _delegate._backgroundBuilder = oldWidget.backgroundBuilder;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder.call(context, _delegate);
  }

  @override
  Future<T?> pushNamed<T extends Object>(String name, {Map<String, dynamic>? params}) {
    return _delegate.pushNamed(name, params);
  }

  @override
  Future<T?> pushNamedAndRemoveUntil<T extends Object>(String path, {AutoRoutePredicate? predicate, Map<String, dynamic>? params}) {
    return _delegate.pushNamedAndRemoveUntil<T>(path, predicate, params);
  }

  @override
  void pop<T extends Object>([T? result]) {
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

class AutoRoutePopModel extends StatefulWidget {
  final RouterDataWidget child;

  final _HistoryRouter router;

  const AutoRoutePopModel({Key? key, required this.child, required this.router}) : super(key: key);

  @override
  _AutoRoutePopModelState createState() => _AutoRoutePopModelState();
}

class _AutoRoutePopModelState extends State<AutoRoutePopModel> {
  @override
  void initState() {
    if (!widget.router._isInit) {
      widget.router._data = widget.child.initData(context);
      WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
        widget.router._data?.init(context);
      });
      widget.router._isInit = true;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    widget.child._data = widget.router._data;
    return widget.child;
  }

  void removeScopedWillPopCallback(WillPopCallback param) {
    widget.router._willPopCallbacks.remove(param);
  }

  void addScopedWillPopCallback(WillPopCallback param) {
    widget.router._willPopCallbacks.add(param);
  }
}

class AutoRoutePopScope extends StatefulWidget {
  final Widget child;

  final WillPopCallback? onWillPop;

  AutoRoutePopScope({Key? key, required this.child, this.onWillPop}) : super(key: key);

  @override
  _AutoRoutePopScopeState createState() => _AutoRoutePopScopeState();
}

class _AutoRoutePopScopeState extends State<AutoRoutePopScope> {
  _AutoRoutePopModelState? _page;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.onWillPop != null) _page?.removeScopedWillPopCallback(widget.onWillPop!);
    _page = context.findAncestorStateOfType<_AutoRoutePopModelState>();
    if (widget.onWillPop != null) _page?.addScopedWillPopCallback(widget.onWillPop!);
  }

  @override
  void didUpdateWidget(AutoRoutePopScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onWillPop != oldWidget.onWillPop && _page != null) {
      if (oldWidget.onWillPop != null) _page!.removeScopedWillPopCallback(oldWidget.onWillPop!);
      if (widget.onWillPop != null) _page!.addScopedWillPopCallback(widget.onWillPop!);
    }
  }

  @override
  void dispose() {
    if (widget.onWillPop != null) _page?.removeScopedWillPopCallback(widget.onWillPop!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class AutoRoutePage<T> extends Page<T> {
  const AutoRoutePage({
    required this.child,
    this.dialog = false,
    LocalKey? key,
    String? name,
    Object? arguments,
    String? restorationId,
  }) : super(key: key, name: name, arguments: arguments, restorationId: restorationId);

  final Widget child;

  final bool dialog;

  @override
  Route<T> createRoute(BuildContext context) {
    return RawDialogRoute(
      settings: this,
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
        return child;
      },
    );
  }
}

class AutoRoutePageRoute<T> extends PopupRoute<T> {
  AutoRoutePageRoute({
    required RoutePageBuilder pageBuilder,
    bool barrierDismissible = true,
    Color? barrierColor = const Color(0x80000000),
    String? barrierLabel,
    Duration transitionDuration = const Duration(milliseconds: 200),
    RouteSettings? settings,
  })  : _pageBuilder = pageBuilder,
        _barrierDismissible = barrierDismissible,
        _barrierLabel = barrierLabel,
        _barrierColor = barrierColor,
        _transitionDuration = transitionDuration,
        super(settings: settings);

  final RoutePageBuilder _pageBuilder;

  @override
  bool get barrierDismissible => _barrierDismissible;
  final bool _barrierDismissible;

  @override
  String? get barrierLabel => _barrierLabel;
  final String? _barrierLabel;

  @override
  Color? get barrierColor => _barrierColor;
  final Color? _barrierColor;

  @override
  Duration get transitionDuration => _transitionDuration;
  final Duration _transitionDuration;

  @override
  bool get opaque => true;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: _pageBuilder(context, animation, secondaryAnimation),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.linear,
      ),
      child: child,
    );
  }
}
