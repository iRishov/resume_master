import 'package:flutter/material.dart';

PageRouteBuilder<dynamic> slidePageRouteBuilder(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.2, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeOut;
      var slideTween = Tween(
        begin: begin,
        end: end,
      ).chain(CurveTween(curve: curve));
      var slideAnimation = animation.drive(slideTween);

      const fadeBegin = 0.0;
      const fadeEnd = 1.0;
      var fadeTween = Tween(
        begin: fadeBegin,
        end: fadeEnd,
      ).chain(CurveTween(curve: curve));
      var fadeAnimation = animation.drive(fadeTween);

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(position: slideAnimation, child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 250),
  );
}
