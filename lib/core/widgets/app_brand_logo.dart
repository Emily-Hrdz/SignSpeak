import 'package:flutter/material.dart';

class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({this.size = 64, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/signspeak_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Logo de SignSpeak',
    );
  }
}
