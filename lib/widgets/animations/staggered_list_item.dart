import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

// Usage in parent State:
//   late final AnimationController _listCtrl;
//   void initState() {
//     _listCtrl = AnimationController(
//       vsync: this, duration: Duration(milliseconds: 500));
//     _listCtrl.forward();
//   }
//   itemBuilder: (ctx, i) => StaggeredListItem(
//     index: i, controller: _listCtrl, child: MyCard(...)),

class StaggeredListItem extends StatelessWidget {
  final int index;
  final AnimationController controller;
  final Widget child;
  static const _maxAnimated = 8;
  static const _itemDuration = 0.12; // fraction of total

  const StaggeredListItem({super.key,
    required this.index,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (index >= _maxAnimated) return child;
    final start = index * _itemDuration;
    final end = (start + _itemDuration).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05), end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }
}