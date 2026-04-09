import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

/// Renders a BlurHash string as a placeholder image.
class BlurHashPlaceholder extends StatelessWidget {
  final String hash;

  const BlurHashPlaceholder({super.key, required this.hash});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: BlurHash(
        hash: hash,
        imageFit: BoxFit.cover,
        decodingWidth: 32,
        decodingHeight: 32,
      ),
    );
  }
}
