import 'package:flutter/material.dart';

class MyBarriers extends StatelessWidget {
  final double? size;
  final double width;
  final double? height;
  final bool isBottom;
  final Color? primaryColor;
  final Color? secondaryColor;
  final Color? borderColor;

  const MyBarriers({
    super.key,
    this.size,
    this.width = 68.0,
    this.height,
    this.isBottom = true,
    this.primaryColor,
    this.secondaryColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final double pipeHeight =
        (height ?? size ?? 200.0).clamp(0.0, double.infinity);
    if (pipeHeight <= 0) return const SizedBox.shrink();

    const double lipHeight = 24.0;
    const double lipExtraWidth = 10.0;
    final double shaftHeight =
        (pipeHeight - lipHeight).clamp(0.0, double.infinity);

    final Color primary = primaryColor ?? const Color(0xFF73BF2E);
    final Color secondary = secondaryColor ?? const Color(0xFF558022);
    final Color border = borderColor ?? const Color(0xFF284815);

    final pipeBorder = BorderSide(color: border, width: 2.5);
    final pipeGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color.lerp(primary, Colors.white, 0.25)!,
        primary,
        primary,
        secondary,
        Color.lerp(secondary, Colors.black, 0.2)!,
      ],
      stops: const [0.0, 0.25, 0.65, 0.88, 1.0],
    );

    final lipWidget = Container(
      width: width + lipExtraWidth,
      height: lipHeight.clamp(0.0, pipeHeight),
      decoration: BoxDecoration(
        gradient: pipeGradient,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );

    final shaftWidget = Container(
      width: width,
      height: shaftHeight,
      decoration: BoxDecoration(
        gradient: pipeGradient,
        border: Border(
          left: pipeBorder,
          right: pipeBorder,
        ),
      ),
    );

    return SizedBox(
      width: width + lipExtraWidth,
      height: pipeHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: isBottom
            ? [
                lipWidget,
                if (shaftHeight > 0) Expanded(child: shaftWidget),
              ]
            : [
                if (shaftHeight > 0) Expanded(child: shaftWidget),
                lipWidget,
              ],
      ),
    );
  }
}
