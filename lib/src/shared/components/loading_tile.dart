import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingTile extends StatelessWidget {
  const LoadingTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      enabled: true,
      child: Container(
        height: 200,
        color: Colors.white,
      ),
    );
  }
}
