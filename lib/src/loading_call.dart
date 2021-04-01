import 'package:flutter/material.dart';
import 'package:heqian_flutter_utils/heqian_flutter_utils.dart';

typedef OnLoadingCallError = Future<dynamic> Function(BuildContext context, dynamic error);

class LoadingCall extends StatefulWidget {
  final WidgetBuilder builder;
  final WidgetBuilder emptyBuilder;
  final WidgetBuilder initBuilder;
  final Future<bool> Function(BuildContext context) onInitLoading;
  final Widget Function(BuildContext context, dynamic error) errorBuilder;
  final OnLoadingCallError onError;

  const LoadingCall({
    Key key,
    this.builder,
    this.onInitLoading,
    this.onError,
    this.emptyBuilder,
    this.errorBuilder,
    this.initBuilder,
  })
      : assert(null != builder),
        super(key: key);

  @override
  LoadingStatusState createState() => LoadingStatusState();

  static _Call of(BuildContext context, {bool root = false, String text}) {
    if (!root) {
      LoadingStatusState state;
      if (context is StatefulElement && (context).state is LoadingStatusState) {
        state = context.state;
      } else {
        state = context.findAncestorStateOfType<LoadingStatusState>();
      }
      if (null != state) {
        state._context = context;
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
    if (null != widget.onInitLoading) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        try {
          _isEmpty = false == await widget.onInitLoading(context);
        } catch (e) {
          _error = e;
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
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (true == isEmpty) {
      child = (widget.emptyBuilder ?? _buildEmpty).call(context);
    } else if (null != error) {
      child = (widget.errorBuilder ?? _buildError).call(context, error);
    } else if (false == _isInit) {
      child = widget.initBuilder(context);
    } else {
      child = widget.builder(context);
    }
    return LoadingTheme(
      child: child,
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Material(
      child: Center(
        child: Text("暂无数据"),
      ),
    );
  }

  Widget _buildError(BuildContext context, dynamic error) {
    return Material(
      child: Center(
        child: Text("错误 :$error"),
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

typedef LoadingStateCall<T> = Future<T> Function(_Call state, LoadingController controller);

abstract class _Call {
  String _text;
  bool _isEmpty = false;

  dynamic _error;

  BuildContext _context;

  bool get isEmpty => _isEmpty;

  BuildContext getContext() => _context;

  set isEmpty(bool value) {
    _isEmpty = value;
  }

  dynamic get error => _error;

  OnLoadingCallError _onError;

  OnLoadingCallError get onError {
    return _onError ?? getContext()
        .findAncestorWidgetOfExactType<LoadingCall>()
        ?.onError;
  }

  showError(dynamic value, bool isShow) {
    showToast(_context, "$value");
  }

  Future<T> call<T>(LoadingStateCall call, {bool isShowError = true, Duration duration = const Duration(milliseconds: 500)}) async {
    var _loadingController = showLoading(_context, msg: _text);
    try {
      _error = null;
      if (null == duration) {
        return call(this, _loadingController);
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
      _loadingController.close();
    }
  }
}

class _LoadingCall extends _Call {
  _LoadingCall(BuildContext _context, String text) {
    _text = text;
    this._context = _context;
  }
}
