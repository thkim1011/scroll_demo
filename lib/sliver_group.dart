import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class TwoSideSliver extends MultiChildRenderObjectWidget {
  final double leftSize;
  final Widget left;
  final Widget right;

  TwoSideSliver({
    super.key,
    required this.leftSize,
    required this.left,
    required this.right,
  }) : super(children: [left, right]);

  @override
  _RenderTwoSideSliver createRenderObject(BuildContext context) {
    return _RenderTwoSideSliver(leftSize: leftSize);
  }

  @override
  void updateRenderObject(BuildContext _, _RenderTwoSideSliver renderObject) {
    renderObject.leftSize = leftSize;
  }
}

extension _TwoSideParentDataExt on RenderSliver {
  /// Shortcut for [parentData]
  _TwoSideParentData get twoSide => parentData! as _TwoSideParentData;
}

class _TwoSideParentData extends SliverPhysicalParentData
    with ContainerParentDataMixin<RenderSliver> {}

class _RenderTwoSideSliver extends RenderSliver
    with ContainerRenderObjectMixin<RenderSliver, _TwoSideParentData> {
  _RenderTwoSideSliver({required double leftSize}) : _leftSize = leftSize;

  double get leftSize => _leftSize;
  double _leftSize;

  set leftSize(double value) {
    if (_leftSize == value) return;
    _leftSize = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderSliver child) {
    if (child.parentData is! _TwoSideParentData) {
      child.parentData = _TwoSideParentData();
    }
  }

  RenderSliver get left => _children.elementAt(0);

  RenderSliver get right => _children.elementAt(1);

  Iterable<RenderSliver> get _children sync* {
    RenderSliver? child = firstChild;
    while (child != null) {
      yield child;
      child = childAfter(child);
    }
  }

  @override
  void performLayout() {
    if (firstChild == null) {
      geometry = SliverGeometry.zero;
      return;
    }

    left.layout(
      parentUsesSize: true,
      constraints.copyWith(crossAxisExtent: leftSize),
    );

    right.layout(
      parentUsesSize: true,
      constraints.copyWith(
        crossAxisExtent: constraints.crossAxisExtent - leftSize,
      ),
    );

    right.twoSide.paintOffset = Offset(leftSize, 0);

    if (left.geometry!.scrollExtent > right.geometry!.scrollExtent) {
      geometry = left.geometry;
    } else {
      geometry = right.geometry;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!geometry!.visible) return;
    context.paintChild(left, offset);
    context.paintChild(right, Offset(offset.dx + leftSize, offset.dy));
  }

  @override
  bool hitTestChildren(
      SliverHitTestResult result, {
        required double mainAxisPosition,
        required double crossAxisPosition,
      }) {
    for (final child in _childrenInHitTestOrder) {
      if (child.geometry!.visible) {
        final hit = child.hitTest(
          result,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition - child.twoSide.paintOffset.dx,
        );

        if (hit) return true;
      }
    }
    return false;
  }

  Iterable<RenderSliver> get _childrenInHitTestOrder sync* {
    RenderSliver? child = lastChild;
    while (child != null) {
      yield child;
      child = childBefore(child);
    }
  }

  /// Important!
  /// Otherwise Widgets like [Slider] or [PopupMenuButton] won't work even
  /// though the rest of Widget will work (like [ElevatedButton])
  @override
  void applyPaintTransform(RenderSliver child, Matrix4 transform) {
    child.twoSide.applyPaintTransform(transform);
  }
}

