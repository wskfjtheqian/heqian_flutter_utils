import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef IndicatorBuilder = Widget Function(BuildContext context, double value);

class Loading extends StatefulWidget {
  final LoadingThemeData? data;

  Widget? _child;

  WidgetBuilder? _builder;

  Loading({
    Key? key,
    this.data,
    required Widget child,
  })  : _child = child,
        super(key: key);

  Loading.builder({
    Key? key,
    this.data,
    required WidgetBuilder builder,
  })  : _builder = builder,
        super(key: key);

  @override
  _LoadingBodyState createState() => _LoadingBodyState();
}

class _LoadingBodyState extends State<Loading> {
  @override
  Widget build(BuildContext context) {
    Widget child = Overlay(
      initialEntries: [
        OverlayEntry(
          builder: widget._builder ?? (context) => widget._child!,
        )
      ],
    );


    if (null != widget.data) {
      child = LoadingTheme(
        child: child,
        data: widget.data!,
      );
    }
    return Directionality(
      textDirection: TextDirection.ltr,
      child: child,
    );
  }
}

class LoadingThemeData {
  final Duration? duration;
  final TextStyle? textStyle;
  final Alignment? alignment;
  final EdgeInsets? padding;
  final Color? color;
  final Color? colorMask;
  final Radius? radius;
  final IndicatorBuilder? indicatorBuilder;

  final List<BoxShadow>? boxShadow;

  LoadingThemeData({
    this.duration,
    this.textStyle,
    this.alignment,
    this.padding,
    this.color,
    this.colorMask = const Color(0x10000000),
    this.radius,
    this.indicatorBuilder,
    this.boxShadow,
  });

  LoadingThemeData copyWith({
    final Duration? duration,
    final TextStyle? textStyle,
    final Alignment? alignment,
    final EdgeInsets? padding,
    final Color? color,
    final Color? colorMask,
    final Radius? radius,
    final IndicatorBuilder? indicatorBuilder,
    final List<BoxShadow>? boxShadow,
  }) {
    return LoadingThemeData(
      duration: duration ?? this.duration,
      textStyle: textStyle ?? this.textStyle,
      alignment: alignment ?? this.alignment,
      padding: padding ?? this.padding,
      color: color ?? this.color,
      colorMask: colorMask ?? this.colorMask,
      radius: radius ?? this.radius,
      indicatorBuilder: indicatorBuilder ?? this.indicatorBuilder,
      boxShadow: boxShadow ?? this.boxShadow,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadingThemeData &&
          runtimeType == other.runtimeType &&
          duration == other.duration &&
          textStyle == other.textStyle &&
          alignment == other.alignment &&
          padding == other.padding &&
          color == other.color &&
          colorMask == other.colorMask &&
          radius == other.radius &&
          indicatorBuilder == other.indicatorBuilder &&
          boxShadow == other.boxShadow;

  @override
  int get hashCode =>
      duration.hashCode ^
      textStyle.hashCode ^
      alignment.hashCode ^
      padding.hashCode ^
      color.hashCode ^
      colorMask.hashCode ^
      radius.hashCode ^
      indicatorBuilder.hashCode ^
      boxShadow.hashCode;
}

class LoadingTheme extends InheritedTheme {
  final LoadingThemeData? data;

  const LoadingTheme({
    Key? key,
    this.data,
    required Widget child,
  }) : super(key: key, child: child);

  static LoadingThemeData? of(BuildContext context) {
    final LoadingTheme? inheritedButtonTheme = context.dependOnInheritedWidgetOfExactType<LoadingTheme>();
    return inheritedButtonTheme?.data;
  }

  @override
  bool updateShouldNotify(covariant LoadingTheme oldWidget) {
    return data != oldWidget.data;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    final LoadingTheme? ancestorTheme = context.findAncestorWidgetOfExactType<LoadingTheme>();
    return identical(this, ancestorTheme) ? child : LoadingTheme.fromLoadingThemeData(data: data, child: child);
  }

  const LoadingTheme.fromLoadingThemeData({
    Key? key,
    @required this.data,
    required Widget child,
  }) : super(key: key, child: child);
}

class LoadingController extends ValueNotifier<double> {
  OverlayEntry? _overlay;

  bool _isShow = false;

  Function()? _onAdd;

  LoadingController() : super(0);

  void open() {
    _onAdd?.call();
  }

  void close() {
    _isShow = false;
    notifyListeners();
  }

  void progress(int count, int total) {
    value = count / total;
  }
}

LoadingController showLoading(
  BuildContext context, {
  String Function(double value)? msg,
  TextStyle? textStyle,
  Alignment? alignment,
  EdgeInsets? padding,
  Color? color,
  Radius? radius,
  LoadingController? controller,
  Widget Function(BuildContext context)? indicatorBuilder,
  bool root = true,
  Color? colorMask,
}) {
  controller ??= LoadingController();
  var theme = LoadingTheme.of(context);
  OverlayState? overlayState;
  if (context is StatefulElement && context.state is OverlayState) {
    overlayState = context.state as OverlayState;
  } else if (root) {
    overlayState = context.findRootAncestorStateOfType<OverlayState>();
  } else {
    overlayState = context.findAncestorStateOfType<OverlayState>();
  }

  controller._onAdd = () {
    controller!._overlay = OverlayEntry(builder: (context) {
      Widget child = _LoadingBody(
        msg: msg,
        textStyle: textStyle,
        alignment: alignment,
        padding: padding,
        color: color,
        radius: radius,
        loadingController: controller!,
        indicatorBuilder: indicatorBuilder,
        colorMask: colorMask,
      );

      if (null != theme) {
        child = LoadingTheme(
          data: theme,
          child: child,
        );
      }
      return child;
    });
    controller._isShow = true;
    overlayState!.insert(controller._overlay!);
  };
  controller._onAdd!();
  return controller;
}

class _LoadingBody extends StatefulWidget {
  final String Function(double value)? msg;
  final TextStyle? textStyle;
  final Alignment? alignment;
  final EdgeInsets? padding;
  final Color? color;
  final Radius? radius;
  final LoadingController loadingController;
  final Widget Function(BuildContext context)? indicatorBuilder;
  final Color? colorMask;
  final List<BoxShadow>? boxShadow;

  const _LoadingBody({
    Key? key,
    this.msg,
    this.textStyle,
    this.alignment,
    this.padding,
    this.color,
    this.colorMask,
    this.radius,
    required this.loadingController,
    this.indicatorBuilder,
    this.boxShadow,
  }) : super(key: key);

  @override
  __LoadingState createState() => __LoadingState();
}

class __LoadingState extends State<_LoadingBody> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _controller.addStatusListener(_onStatusListener);
    _controller.addListener(_onListener);
    widget.loadingController.addListener(_onLoadingListener);

    if (widget.loadingController._isShow) {
      _controller.forward();
    } else {
      widget.loadingController._overlay?.remove();
      widget.loadingController._overlay = null;
    }
    super.initState();
  }

  @override
  void dispose() {
    widget.loadingController.removeListener(_onLoadingListener);
    _controller.removeListener(_onListener);
    _controller.removeStatusListener(_onStatusListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    LoadingThemeData? theme = LoadingTheme.of(context);
    TextStyle textStyle = TextStyle(
      color: Color(0xFFFFFFFF),
      decoration: TextDecoration.none,
      fontSize: 14,
      fontWeight: FontWeight.normal,
    );
    if (null != (widget.textStyle ?? theme?.textStyle)) {
      textStyle = (widget.textStyle ?? theme?.textStyle)!.merge(textStyle);
    }

    Widget child = Align(
      alignment: widget.alignment ?? (theme?.alignment ?? Alignment(0, 0.1)),
      child: Opacity(
        opacity: _controller.value,
        child: Container(
          decoration: BoxDecoration(
            color: widget.color ?? (theme?.color ?? Color(0x50000000)),
            borderRadius: BorderRadius.all(widget.radius ?? (theme?.radius ?? Radius.circular(8))),
            boxShadow: widget.boxShadow ?? theme?.boxShadow,
          ),
          padding: widget.padding ?? (theme?.padding ?? EdgeInsets.all(16)),
          child: ValueListenableBuilder<double>(
            valueListenable: widget.loadingController,
            builder: (context, value, child) {
              var msg = widget.msg?.call(value);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  (widget.indicatorBuilder ?? theme?.indicatorBuilder)?.call(context, value) ?? CircularProgressIndicator(value: value),
                  if (msg?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        msg!,
                        style: textStyle,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
    child = Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: child,
    );

    var colorMask = widget.colorMask ?? theme?.colorMask ?? const Color(0x30000000);
    if (null != colorMask) {
      child = ColoredBox(
        color: colorMask,
        child: child,
      );
    }
    return child;
  }

  void _onStatusListener(AnimationStatus status) {
    if (AnimationStatus.dismissed == status) {
      widget.loadingController._overlay?.remove();
      widget.loadingController._overlay = null;
    }
  }

  void _onListener() {
    setState(() {});
  }

  void _onLoadingListener() {
    if (!widget.loadingController._isShow) {
      _controller.reverse();
    }
  }
}
