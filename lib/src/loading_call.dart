import 'package:flutter/material.dart';
import 'package:heqian_flutter_utils/heqian_flutter_utils.dart';

class LoadingCall extends StatefulWidget {
  final WidgetBuilder builder;
  final WidgetBuilder emptyBuilder;
  final WidgetBuilder initBuilder;
  final Future<bool> Function(BuildContext context) onInitLoading;
  final Widget Function(BuildContext context, dynamic error) errorBuilder;

  const LoadingCall({
    Key key,
    this.builder,
    this.onInitLoading,
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
    _context = context;
    _isInit = widget.initBuilder == null;
    if (null != widget.onInitLoading) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        try {
          _isEmpty = false == await widget.onInitLoading(context);
        } catch (e) {} finally {
          setState(() {
            _isInit = true;
          });
        }
      });
    }
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
  set error(dynamic value) {
    setState(() {
      _error = value;
    });
  }

}

typedef LoadingStateCall<T> = Future<T> Function(_Call state);

abstract class _Call {
  String _text;
  bool _isEmpty = false;

  dynamic _error;

  BuildContext _context;

  bool get isEmpty => _isEmpty;

  set isEmpty(bool value) {
    _isEmpty = value;
  }

  dynamic get error => _error;

  set error(dynamic value) {
    _error = value;
    showToast(_context, "$value");
  }

  Future<T> call<T>(LoadingStateCall call, {bool isShowError = true}) async {
    var _loadingController = showLoading(_context, msg: _text);
    try {
      _error = null;
      return await Future.wait([call(this), Future.delayed(Duration(seconds: 1))]).then((value) => value[0]);
    } catch (e) {
      if (isShowError) {
        error = e;
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
