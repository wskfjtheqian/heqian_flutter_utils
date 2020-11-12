import 'package:flutter/material.dart';


class LoadingCall extends StatefulWidget {
  final WidgetBuilder builder;
  final bool isEmpty;

  const LoadingCall({Key key, this.builder, this.isEmpty = false})
      : assert(null != builder),
        super(key: key);

  @override
  LoadingStatusState createState() => LoadingStatusState();

  static _Call of(BuildContext context, {bool root = false, String text}) {
    if (!root) {
      var state = context.findAncestorStateOfType<LoadingStatusState>();
      if (null != state) {
        return state;
      }
    }
    return _LoadingCall(
      Overlay.of(context, rootOverlay: root),
      context,
      text,
    );
  }
}

class LoadingStatusState extends State<LoadingCall> with _Call {
  OverlayEntry _entry;
  var overlayKey = GlobalKey<OverlayState>();

  @override
  void initState() {
    super.initState();
    _isEmpty = widget.isEmpty;
    _entry = OverlayEntry(
      builder: (context) {
        return isEmpty ? _buildEmpty(context) : widget.builder(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(
      key: overlayKey,
      initialEntries: [_entry],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Material(
      child: Center(
        child: Text("Not data"),
      ),
    );
  }

  @override
  Future<T> call<T>(LoadingStateCall call) async {
    var entry = OverlayEntry(builder: builderProgress);
    try {
      overlayKey.currentState.insert(entry);
      return await Future.wait([call(this), Future.delayed(Duration(seconds: 1))]).then((value) => value[0]);
    } catch (e) {
      rethrow;
    } finally {
      entry?.remove();
    }
  }

  @override
  void set isEmpty(bool value) {
    if (isEmpty != value) {
      super.isEmpty = value;
      _entry.markNeedsBuild();
    }
  }
}

typedef LoadingStateCall<T> = Future<T> Function(_Call state);

abstract class _Call {
  String _text;
  bool _isEmpty = true;

  bool get isEmpty => _isEmpty;

  set isEmpty(bool value) {
    _isEmpty = value;
  }

  Future<T> call<T>(LoadingStateCall call);

  Widget builderProgress(BuildContext context) {
    return Material(
      color: Color(0x50000000),
      child: Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(color: Color(0x90000000), borderRadius: BorderRadius.all(Radius.circular(12))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CircularProgressIndicator(),
              if (_text?.isNotEmpty ?? false)
                Text(
                  _text,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingCall extends _Call {
  final OverlayState _overlay;
  final BuildContext _context;

  _LoadingCall(this._overlay, this._context, String text) {
    _text = text;
  }

  Future<T> call<T>(LoadingStateCall call) async {
    var entry = OverlayEntry(builder: builderProgress);
    _overlay.insert(entry);
    try {
      return await Future.wait([call(this), Future.delayed(Duration(seconds: 1))]).then((value) => value[0]);
    } catch (e) {} finally {
      entry?.remove();
    }
  }
}
