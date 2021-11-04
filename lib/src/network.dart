import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class Network extends StatefulWidget {
  final WidgetBuilder builder;

  final List<NetwordInterface> Function(BuildContext context) create;

  const Network({Key? key, required this.builder, required this.create}) : super(key: key);

  @override
  _NetworkState createState() => _NetworkState();

  static T of<T>(BuildContext context) {
    _NetworkState formState = context.findAncestorStateOfType<_NetworkState>()!;
    return formState.getInterfaces<T>();
  }
}

class _NetworkState extends State<Network> {
  late List<NetwordInterface> _interfaces;

  @override
  void initState() {
    super.initState();
    _interfaces = widget.create(context);
    _interfaces.forEach((element) {
      element.__networkState = this;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      return widget.builder(context);
    });
  }

  T getInterfaces<T>() {
    for (var item in _interfaces) {
      if (item is T) {
        return item as T;
      } else {
        var temp = item.getInterfaces<T>();
        if (null != temp) {
          return temp;
        }
      }
    }
    assert(false, "Not find interfaces");
    return null!;
  }
}

abstract class NetwordInterface<E> {
  final List<E> interfaces;

  _NetworkState? __networkState;

  _NetworkState get networkState => __networkState!;

  NetwordInterface(this.interfaces);

  T? getInterfaces<T>() {
    for (var item in interfaces) {
      if (item is T) {
        return item;
      }
    }
    return null;
  }
}
