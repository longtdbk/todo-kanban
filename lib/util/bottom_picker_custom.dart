import 'package:flutter/cupertino.dart';

class BottomPickerCustom extends StatelessWidget {
  const BottomPickerCustom({
    Key? key,
    @required this.child,
  })  : assert(child != null),
        super(key: key);

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 216,
      padding: const EdgeInsets.only(top: 6),
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: DefaultTextStyle(
        style: TextStyle(
          color: CupertinoColors.label.resolveFrom(context),
          fontSize: 22,
        ),
        child: GestureDetector(
          // Blocks taps from propagating to the modal sheet and popping.
          onTap: () {},
          child: SafeArea(
            top: false,
            child: child!,
          ),
        ),
      ),
    );
  }
}

class MenuPickerCustom extends StatelessWidget {
  const MenuPickerCustom({
    Key? key,
    @required this.children,
  })  : assert(children != null),
        super(key: key);

  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: CupertinoColors.inactiveGray, width: 0),
          bottom: BorderSide(color: CupertinoColors.inactiveGray, width: 0),
        ),
      ),
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children!,
        ),
      ),
    );
  }
}
