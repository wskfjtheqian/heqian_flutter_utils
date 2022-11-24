import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:heqian_flutter_utils/heqian_flutter_utils.dart';

typedef OnLoadingCallError = Future<dynamic> Function(BuildContext context, dynamic error);
typedef OnShowError = void Function(dynamic message);

class LoadingCall extends StatefulWidget {
  final WidgetBuilder builder;
  final WidgetBuilder? emptyBuilder;
  final WidgetBuilder? initBuilder;
  final Future<bool> Function(BuildContext context)? onInitLoading;
  final Widget Function(BuildContext context, dynamic error)? errorBuilder;
  final OnLoadingCallError? onError;
  final LoadingThemeData? data;
  final bool? isEmpty;
  final OnShowError? onShowError;

  const LoadingCall({
    Key? key,
    required this.builder,
    this.onInitLoading,
    this.onError,
    this.emptyBuilder,
    this.errorBuilder,
    this.initBuilder,
    this.data,
    this.isEmpty,
    this.onShowError,
  }) : super(key: key);

  @override
  LoadingStatusState createState() => LoadingStatusState();

  static _Call of(BuildContext context, {bool root = false, String Function(double value)? text}) {
    if (!root) {
      LoadingStatusState? state;
      if (context is StatefulElement && context.state is LoadingStatusState) {
        state = context.state as LoadingStatusState?;
      } else {
        state = context.findAncestorStateOfType<LoadingStatusState>();
      }
      if (null != state) {
        state._context = context;
        state._root = root;
        return state;
      }
    }
    return _LoadingCall(
      context,
      text,
    );
  }
}

class LoadingStatusState extends State<LoadingCall> with _Call {
  var overlayKey = GlobalKey<OverlayState>();
  var _isInit = true;

  @override
  void initState() {
    super.initState();
    _isInit = widget.initBuilder == null;
    _onError = widget.onError;
    _onShowError = widget.onShowError;
    if (null != widget.onInitLoading) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        try {
          _isEmpty = false == await widget.onInitLoading!(context);
        } catch (e) {
          rethrow;
        } finally {
          if (mounted) {
            setState(() {
              _isInit = true;
            });
          }
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant LoadingCall oldWidget) {
    _onError = oldWidget.onError;
    _onShowError = oldWidget.onShowError;
    super.didUpdateWidget(oldWidget);
  }

  @override
  bool get isEmpty {
    return widget.isEmpty ?? super.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (true == isEmpty) {
      child = (widget.emptyBuilder ?? _buildEmpty).call(context);
    } else if (null != error) {
      child = (widget.errorBuilder ?? _buildError).call(context, error);
    } else if (false == _isInit) {
      child = widget.initBuilder!(context);
    } else {
      child = widget.builder(context);
    }
    if (null == widget.data) {
      return child;
    }
    return LoadingTheme(
      data: widget.data,
      child: child,
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Material(
      child: Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text("暂无数据"),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, dynamic error) {
    return Material(
      child: Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text("错误 :$error"),
        ),
      ),
    );
  }

  @override
  void set isEmpty(bool value) {
    setState(() {
      super._isEmpty = value;
    });
  }

  @override
  showError(dynamic value, bool isShow) {
    if (!isShow) {
      setState(() {
        _error = value;
      });
    } else {
      super.showError(value, isShow);
    }
  }

  @override
  BuildContext getContext() {
    return context;
  }
}

typedef LoadingStateCall<T> = Future<T> Function(_Call state, LoadingController? controller);

abstract class _Call {
  String Function(double value)? _text;
  bool _isEmpty = false;

  bool _root = false;

  dynamic _error;

  late BuildContext _context;

  bool get isEmpty => _isEmpty;

  BuildContext getContext() => _context;

  set isEmpty(bool value) {
    _isEmpty = value;
  }

  dynamic get error => _error;

  OnLoadingCallError? _onError;

  OnShowError? _onShowError;

  OnLoadingCallError? get onError {
    if (null != _onError) {
      return _onError;
    }

    var loading = getContext().findAncestorStateOfType<LoadingStatusState>();
    if (null == loading) {
      return null;
    }

    if (null != loading.widget.onError) {
      return loading.widget.onError;
    }

    return loading.onError;
  }

  OnShowError? get onShowError {
    if (null != _onShowError) {
      return _onShowError;
    }

    var loading = getContext().findAncestorStateOfType<LoadingStatusState>();
    if (null == loading) {
      return null;
    }

    if (null != loading.widget.onShowError) {
      return loading.widget.onShowError;
    }

    return loading.onShowError;
  }

  showError(dynamic value, bool isShow) {
    if (null != onShowError) {
      onShowError!.call(value);
    } else {
      showToast(_context, "$value");
    }
  }

  Future<T> call<T>(LoadingStateCall<T> call, {bool isShowError = true, bool isShowLoading = true, Duration? duration}) async {
    var _loadingController = true == isShowLoading ? showLoading(_context, msg: _text, root: _root) : null;
    try {
      _error = null;
      if (null == duration) {
        return await call(this, _loadingController);
      }
      return await Future.wait([call(this, _loadingController), Future.delayed(duration)]).then((value) => value[0]);
    } catch (e) {
      var error = null != onError ? (await onError?.call(_context, e)) : e;
      if (null != error) {
        if (null != isShowError) {
          showError(error, isShowError);
        }
      }
      rethrow;
    } finally {
      _loadingController?.close();
    }
  }
}

class _LoadingCall extends _Call {
  _LoadingCall(BuildContext _context, String Function(double value)? text) {
    _text = text;
    this._context = _context;
  }
}
