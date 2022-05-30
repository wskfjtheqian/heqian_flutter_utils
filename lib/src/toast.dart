import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

typedef ToastControllerRemove = void Function();

class ToastController extends ChangeNotifier {
  ToastControllerRemove? _onRemove;

  void remove() {
    _onRemove?.call();
  }
}

showToast(
  BuildContext context,
  String msg, {
  Duration? duration,
  TextStyle? textStyle,
  Alignment? alignment,
  EdgeInsets? padding,
  Color? color,
  Radius? radius,
  ToastController? controller,
  bool rootOverlay = true,
}) {
  assert(msg.isNotEmpty);
  controller ??= ToastController();
  late OverlayEntry overlay;
  var theme = ToastTheme.of(context);
  overlay = OverlayEntry(builder: (_) {
    return ToastTheme(
      data: theme,
      child: _Toast(
        msg: msg,
        onRemove: overlay.remove,
        duration: duration,
        textStyle: textStyle,
        alignment: alignment,
        padding: padding,
        color: color,
        radius: radius,
        toastController: controller,
      ),
    );
  });
  OverlayState? overlayState;
  if (context is StatefulElement && context.state is OverlayState) {
    overlayState = context.state as OverlayState;
  } else {
    overlayState = context.findRootAncestorStateOfType<OverlayState>();
  }
  overlayState!.insert(overlay);
  return controller;
}

class ToastThemeData {
  final Duration? duration;
  final TextStyle? textStyle;
  final Alignment? alignment;
  final EdgeInsets? padding;
  final Color? color;
  final Radius? radius;

  const ToastThemeData({
    this.duration,
    this.textStyle,
    this.alignment,
    this.padding,
    this.color,
    this.radius,
  });

  ToastThemeData copyWith({
    final Duration? duration,
    final TextStyle? textStyle,
    final Alignment? alignment,
    final EdgeInsets? padding,
    final Color? color,
    final Radius? radius,
  }) {
    return ToastThemeData(
      duration: duration ?? this.duration,
      textStyle: textStyle ?? this.textStyle,
      alignment: alignment ?? this.alignment,
      padding: padding ?? this.padding,
      color: color ?? this.color,
      radius: radius ?? this.radius,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToastThemeData &&
          runtimeType == other.runtimeType &&
          duration == other.duration &&
          textStyle == other.textStyle &&
          alignment == other.alignment &&
          padding == other.padding &&
          color == other.color &&
          radius == other.radius;

  @override
  int get hashCode => duration.hashCode ^ textStyle.hashCode ^ alignment.hashCode ^ padding.hashCode ^ color.hashCode ^ radius.hashCode;
}

class ToastTheme extends InheritedTheme {
  final ToastThemeData? data;

  const ToastTheme({
    Key? key,
    required this.data,
    required Widget child,
  }) : super(key: key, child: child);

  static ToastThemeData? of(BuildContext context) {
    final ToastTheme? inheritedButtonTheme = context.dependOnInheritedWidgetOfExactType<ToastTheme>();
    return inheritedButtonTheme?.data;
  }

  @override
  bool updateShouldNotify(covariant ToastTheme oldWidget) {
    return data != oldWidget.data;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    final ToastTheme? ancestorTheme = context.findAncestorWidgetOfExactType<ToastTheme>();
    return identical(this, ancestorTheme) ? child : ToastTheme.fromToastThemeData(data: data, child: child);
  }

  const ToastTheme.fromToastThemeData({
    Key? key,
    required this.data,
    required Widget child,
  }) : super(key: key, child: child);
}

class _Toast extends StatefulWidget {
  final String msg;
  final VoidCallback? onRemove;
  final Duration? duration;
  final TextStyle? textStyle;
  final Alignment? alignment;
  final EdgeInsets? padding;
  final Color? color;
  final Radius? radius;
  final ToastController? toastController;

  const _Toast({
    Key? key,
    required this.msg,
    this.onRemove,
    this.duration,
    this.textStyle,
    this.alignment,
    this.padding,
    this.color,
    this.radius,
    this.toastController,
  }) : super(key: key);

  @override
  _ToastState createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _controller.addStatusListener(_onStatusListener);
    _controller.addListener(_onListener);
    _controller.forward();
    super.initState();
    widget.toastController?._onRemove = _onRemove;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _timer = Timer(widget.duration ?? (ToastTheme.of(context)?.duration ?? Duration(seconds: 2)), () {
        _controller.reverse();
        _timer = null;
      });
    });
  }

  _onRemove() {
    _controller.reverse();
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    widget.toastController?._onRemove = null;
    _controller.removeListener(_onListener);
    _controller.removeStatusListener(_onStatusListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ToastThemeData? theme = ToastTheme.of(context);
    TextStyle textStyle = TextStyle(
      color: Color(0xFFFFFFFF),
      decoration: TextDecoration.none,
      fontSize: 14,
      fontWeight: FontWeight.normal,
    );
    if (null != (widget.textStyle ?? theme?.textStyle)) {
      textStyle = (widget.textStyle ?? theme?.textStyle)!.merge(textStyle);
    }

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Align(
        alignment: widget.alignment ?? (theme?.alignment ?? Alignment(0, 0.2)),
        child: Opacity(
          opacity: _controller.value,
          child: Container(
            decoration: BoxDecoration(
              color: widget.color ?? (theme?.color ?? Color(0xCC808080)),
              borderRadius: BorderRadius.all(widget.radius ?? (theme?.radius ?? Radius.circular(8))),
            ),
            padding: widget.padding ?? (theme?.padding ?? EdgeInsets.symmetric(vertical: 8, horizontal: 12)),
            child: Text(
              widget.msg,
              style: textStyle,
            ),
          ),
        ),
      ),
    );
  }

  void _onStatusListener(AnimationStatus status) {
    if (AnimationStatus.dismissed == status) {
      widget.onRemove?.call();
    }
  }

  void _onListener() {
    setState(() {});
  }
}
