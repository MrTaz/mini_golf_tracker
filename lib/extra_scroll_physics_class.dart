import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/always_scrollable_overscroll_physics_class.dart';

class OverscrollList extends StatelessWidget {
  final ScrollController _scrollCtrl = ScrollController();
  final double _topOverscroll = 200;
  final double _bottomOverscroll = 200;

  OverscrollList({super.key});

  void _scrollList(Offset offset) {
    _scrollCtrl.jumpTo(
      _scrollCtrl.offset + offset.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(border: Border.all(width: 1)),
      child: Listener(
        onPointerSignal: (PointerSignalEvent event) {
          if (kIsWeb) {
            GestureBinding.instance.pointerSignalResolver.register(event, (event) {
              _scrollList((event as PointerScrollEvent).scrollDelta);
            });
          }
        },
        child: ScrollConfiguration(
          behavior: const MaterialScrollBehavior(),
          // behavior: OffsetOverscrollBehavior(
          //   leadingPaintOffset: -_topOverscroll,
          //   trailingPaintOffset: -_bottomOverscroll,
          // ),
          child: CustomScrollView(
            controller: _scrollCtrl,
            physics: kIsWeb
                ? NeverScrollableOverscrollPhysics(
                    overscrollStart: _topOverscroll,
                    overscrollEnd: _bottomOverscroll,
                  )
                : AlwaysScrollableOverscrollPhysics(
                    overscrollStart: _topOverscroll,
                    overscrollEnd: _bottomOverscroll,
                  ),
            slivers: [
              SliverToBoxAdapter(
                child: Container(width: 400, height: 100, color: Colors.blue),
              ),
              SliverToBoxAdapter(
                child: Container(width: 400, height: 100, color: Colors.yellow),
              ),
              SliverToBoxAdapter(
                child: Container(width: 400, height: 100, color: Colors.red),
              ),
              SliverToBoxAdapter(
                child: Container(width: 400, height: 100, color: Colors.orange),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
