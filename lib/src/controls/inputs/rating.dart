import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';

class RatingBar extends StatefulWidget {
  const RatingBar({
    Key? key,
    required this.rating,
    this.onChanged,
    this.amount = 5,
    this.animationDuration,
    this.animationCurve,
    this.icon,
    this.iconSize,
    this.ratedIconColor,
    this.unratedIconColor,
    this.semanticsLabel,
    this.focusNode,
    // TODO: starSpacing
  })  : assert(rating <= amount && rating <= amount),
        super(key: key);

  final int amount;
  final double rating;

  final ValueChanged<double>? onChanged;

  final Duration? animationDuration;
  final Curve? animationCurve;

  final IconData? icon;
  final double? iconSize;
  final Color? ratedIconColor;
  final Color? unratedIconColor;

  final String? semanticsLabel;
  final FocusNode? focusNode;

  @override
  _RatingBarState createState() => _RatingBarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('amount', amount));
    properties.add(DoubleProperty('rating', rating));
    properties.add(
      DiagnosticsProperty<Duration>('animationDuration', animationDuration),
    );
    properties.add(
      DiagnosticsProperty<Curve>('animationCurve', animationCurve),
    );
    properties.add(DoubleProperty('iconSize', iconSize));
    properties.add(IconDataProperty('icon', icon));
    properties.add(ColorProperty('ratedIconColor', ratedIconColor));
    properties.add(ColorProperty('unratedIconColor', unratedIconColor));
    properties.add(ObjectFlagProperty<FocusNode>.has('focusNode', focusNode));
  }
}

class _RatingBarState extends State<RatingBar> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleUpdate(double x, double? size) {
    final iSize = (widget.iconSize ?? size ?? 24);
    final value = x / iSize;
    if (value <= widget.amount && !value.isNegative)
      widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    debugCheckHasFluentTheme(context);
    final size = context.theme.iconStyle!.size;
    return Semantics(
      label: widget.semanticsLabel,
      // It's only a slider if its value can be changed
      slider: widget.onChanged != null,
      maxValueLength: widget.amount,
      value: widget.rating.toStringAsFixed(2),
      focusable: true,
      focused: _focusNode.hasFocus,
      child: GestureDetector(
        onTapDown: (d) => _handleUpdate(d.localPosition.dx, size),
        onHorizontalDragStart: (d) => _handleUpdate(d.localPosition.dx, size),
        onHorizontalDragUpdate: (d) => _handleUpdate(d.localPosition.dx, size),
        child: TweenAnimationBuilder<double>(
          builder: (context, value, child) {
            double v = value + 1;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.amount, (index) {
                double r = v - 1;
                v -= 1;
                if (r > 1)
                  r = 1;
                else if (r < 0) r = 0;
                return RatingIcon(
                  rating: r,
                  icon: widget.icon,
                  ratedColor: widget.ratedIconColor,
                  unratedColor: widget.unratedIconColor,
                  size: widget.iconSize,
                );
              }),
            );
          },
          duration: widget.animationDuration ?? Duration.zero,
          curve: widget.animationCurve ?? standartCurve,
          tween: Tween<double>(begin: 0, end: widget.rating),
        ),
      ),
    );
  }
}

class RatingIcon extends StatelessWidget {
  const RatingIcon({
    Key? key,
    required this.rating,
    this.ratedColor,
    this.unratedColor,
    this.icon,
    this.size,
  })  : assert(rating >= 0.0 && rating <= 1.0),
        super(key: key);

  final double rating;
  final IconData? icon;
  final Color? ratedColor;
  final Color? unratedColor;
  final double? size;

  @override
  Widget build(BuildContext context) {
    debugCheckHasFluentTheme(context);
    final style = context.theme;
    final icon = this.icon ?? Icons.star;
    final size = this.size;
    if (rating == 1.0)
      return Icon(icon, color: ratedColor ?? style.accentColor, size: size);
    else if (rating == 0.0)
      return Icon(icon, color: unratedColor ?? style.disabledColor, size: size);
    return Stack(
      children: [
        Icon(icon, color: unratedColor ?? style.disabledColor, size: size),
        ClipRect(
          clipper: _StarClipper(rating),
          child: Icon(
            icon,
            color: ratedColor ?? style.accentColor,
            size: size,
          ),
        ),
      ],
    );
  }
}

class _StarClipper extends CustomClipper<Rect> {
  final double value;

  _StarClipper(this.value);

  @override
  Rect getClip(Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width * value, size.height);
    return rect;
  }

  @override
  bool shouldReclip(_StarClipper oldClipper) => oldClipper.value != value;
}
