import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoadingController extends ChangeNotifier {
  Function() _onRemove;

  void close() {
    _onRemove?.call();
  }
}

class Loading extends StatefulWidget {
  final LoadingThemeData data;

  final Widget child;

  const Loading({
    Key key,
    this.data,
    this.child,
  }) : super(key: key);

  @override
  _LoadingBodyState createState() => _LoadingBodyState();
}

class _LoadingBodyState extends State<Loading> {
  @override
  Widget build(BuildContext context) {
    Widget child = Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) {
            return widget.child;
          },
        )
      ],
    );
    if (null != widget.data) {
      child = LoadingTheme(
        child: widget.child,
        data: widget.data,
      );
    }
    return Directionality(
      textDirection: TextDirection.ltr,
      child: child,
    );
  }
}

LoadingController showLoading(
  BuildContext context, {
  String msg,
  TextStyle textStyle,
  Alignment alignment,
  EdgeInsets padding,
  Color color,
  Radius radius,
  LoadingController controller,
  Widget Function(BuildContext context) indicatorBuilder,
  bool rootOverlay = true,
}) {
  controller ??= LoadingController();
  OverlayEntry overlay;

  LoadingThemeData theme = LoadingTheme.of(context);
  overlay = OverlayEntry(builder: (context) {
    return _LoadingBody(
      msg: msg,
      onRemove: overlay.remove,
      textStyle: textStyle,
      alignment: alignment,
      padding: padding,
      color: color,
      radius: radius,
      toastController: controller,
      indicatorBuilder: indicatorBuilder,
      theme: theme,
    );
  });

  Overlay.of(context, rootOverlay: rootOverlay).insert(overlay);
  return controller;
}

class LoadingThemeData {
  final Duration duration;
  final TextStyle textStyle;
  final Alignment alignment;
  final EdgeInsets padding;
  final Color color;
  final Color colorMask;
  final Radius radius;
  final Widget Function(BuildContext context) indicatorBuilder;

  LoadingThemeData({
    this.duration,
    this.textStyle,
    this.alignment,
    this.padding,
    this.color,
    this.colorMask = const Color(0x10000000),
    this.radius,
    this.indicatorBuilder,
  });

  LoadingThemeData copyWith({
    final Duration duration,
    final TextStyle textStyle,
    final Alignment alignment,
    final EdgeInsets padding,
    final Color color,
    final Color colorMask,
    final Radius radius,
    final Widget Function(BuildContext context) indicatorBuilder,
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
          indicatorBuilder == other.indicatorBuilder;

  @override
  int get hashCode =>
      duration.hashCode ^
      textStyle.hashCode ^
      alignment.hashCode ^
      padding.hashCode ^
      color.hashCode ^
      colorMask.hashCode ^
      radius.hashCode ^
      indicatorBuilder.hashCode;
}

class LoadingTheme extends InheritedTheme {
  final LoadingThemeData data;

  const LoadingTheme({
    Key key,
    this.data,
    @required Widget child,
  }) : super(key: key, child: child);

  static LoadingThemeData of(BuildContext context) {
    final LoadingTheme inheritedButtonTheme =
        context.dependOnInheritedWidgetOfExactType<LoadingTheme>();
    return inheritedButtonTheme?.data;
  }

  @override
  bool updateShouldNotify(covariant LoadingTheme oldWidget) {
    return data != oldWidget.data;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    final LoadingTheme ancestorTheme =
        context.findAncestorWidgetOfExactType<LoadingTheme>();
    return identical(this, ancestorTheme)
        ? child
        : LoadingTheme.fromLoadingThemeData(data: data, child: child);
  }

  const LoadingTheme.fromLoadingThemeData({
    Key key,
    @required this.data,
    Widget child,
  })  : assert(data != null),
        super(key: key, child: child);
}

class _LoadingBody extends StatefulWidget {
  final String msg;
  final VoidCallback onRemove;
  final TextStyle textStyle;
  final Alignment alignment;
  final EdgeInsets padding;
  final Color color;
  final Radius radius;
  final LoadingController toastController;
  final Widget Function(BuildContext context) indicatorBuilder;
  final Color colorMask;
  final LoadingThemeData theme;

  const _LoadingBody({
    Key key,
    this.msg,
    this.onRemove,
    this.textStyle,
    this.alignment,
    this.padding,
    this.color,
    this.colorMask = const Color(0x30000000),
    this.radius,
    this.toastController,
    this.indicatorBuilder,
    this.theme,
  }) : super(key: key);

  @override
  __LoadingState createState() => __LoadingState();
}

class __LoadingState extends State<_LoadingBody>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _controller.addStatusListener(_onStatusListener);
    _controller.addListener(_onListener);
    _controller.forward();
    super.initState();
    widget.toastController?._onRemove = _onRemove;
  }

  _onRemove() {
    _controller?.reverse();
    widget?.onRemove();
  }

  @override
  void dispose() {
    widget.toastController?._onRemove = null;
    _controller.removeListener(_onListener);
    _controller.removeStatusListener(_onStatusListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = TextStyle(
      color: Color(0xFFFFFFFF),
      decoration: TextDecoration.none,
      fontSize: 14,
      fontWeight: FontWeight.normal,
    );
    if (null != (widget.textStyle ?? widget.theme?.textStyle)) {
      textStyle =
          (widget.textStyle ?? widget.theme?.textStyle).merge(textStyle);
    }
    Widget indicator =
        (widget.indicatorBuilder ?? widget.theme?.indicatorBuilder)
            ?.call(context);

    Widget child = Align(
      alignment:
          widget.alignment ?? (widget.theme?.alignment ?? Alignment(0, 0.2)),
      child: Opacity(
        opacity: _controller.value,
        child: Container(
          decoration: BoxDecoration(
            color: widget.color ?? (widget.theme?.color ?? Color(0x50000000)),
            borderRadius: BorderRadius.all(
                widget.radius ?? (widget.theme?.radius ?? Radius.circular(8))),
          ),
          padding:
              widget.padding ?? (widget.theme?.padding ?? EdgeInsets.all(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              indicator ?? CircularProgressIndicator(),
              if (widget.msg?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    widget.msg,
                    style: textStyle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    var colorMask = widget.colorMask ?? widget.theme?.colorMask;
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
      widget.onRemove?.call();
    }
  }

  void _onListener() {
    setState(() {});
  }
}
