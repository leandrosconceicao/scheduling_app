import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/core.dart';

/// Foto do barbeiro. Sem foto (ou se ela falhar), mostra as iniciais do nome.
class EmployeeAvatar extends StatelessWidget {
  final String name;
  final String photoUrl;

  /// Foto ainda não enviada (prévia); tem prioridade sobre [photoUrl].
  final Uint8List? previewBytes;
  final double radius;

  const EmployeeAvatar({
    super.key,
    required this.name,
    this.photoUrl = "",
    this.previewBytes,
    this.radius = 24.0,
  });

  /// Primeira letra das duas primeiras palavras do nome.
  static String initialsOf(String name) {
    return name
        .split(RegExp(r"\s+"))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final initials = initialsOf(name);
    final fallback = Center(
      child: initials.isEmpty
          ? Icon(Icons.person_outline, color: golden, size: radius)
          : Text(
              initials,
              style: TextStyle(
                color: golden,
                fontWeight: FontWeight.bold,
                fontSize: radius * .7,
              ),
            ),
    );

    final uri = Uri.tryParse(photoUrl);
    final hasPhoto = uri != null && uri.isAbsolute && uri.host.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: golden.withValues(alpha: .2),
      child: ClipOval(
        child: SizedBox.square(
          dimension: radius * 2,
          child: previewBytes != null
              ? Image.memory(
                  previewBytes!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback,
                )
              : hasPhoto
              ? CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => fallback,
                  placeholder: (_, _) => fallback,
                )
              : fallback,
        ),
      ),
    );
  }
}
