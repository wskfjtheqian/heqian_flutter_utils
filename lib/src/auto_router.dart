import 'package:flutter/widgets.dart';

class AutoRouter extends StatefulWidget {
  final Widget Function(BuildContext context, RouteFactory routeFactory) builder;
  final List routers;

  const AutoRouter({
    Key key,
    this.builder,
    this.routers,
  })  : assert(null != builder),
        super(key: key);

  @override
  _AutoRouterState createState() => _AutoRouterState();
}

class _AutoRouterState extends State<AutoRouter> {
  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _onGenerateRoute);
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {

  }
}
