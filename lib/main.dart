import 'dart:ui' as ui;
import 'package:flutter/material.dart';

Future<ui.Image> generateBabeInfoTexture() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // Ukuran standar Equirectangular Map (2:1)
  const double width = 1024;
  const double height = 512;

  // Latar belakang transparan
  final paint = Paint()..color = Colors.transparent;
  canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), paint);

  // Konfigurasi Teks BABE.INFO
  const textStyle = TextStyle(
    color: Color(0xFF111111), // Warna hitam pekat seperti di gambar
    fontSize: 52,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.0,
  );

  const text = 'BABE.INFO';
  final textPainter = TextPainter(
    text: const TextSpan(text: text, style: textStyle),
    textDirection: TextDirection.ltr,
  )..layout();

  // Draw susunan teks berulang melingkar
  const double rowSpacing = 80;
  const double colSpacing = 320;

  for (double y = 20; y < height; y += rowSpacing) {
    // Geser setiap baris agar pola selang-seling
    double xOffset = ((y / rowSpacing).floor() % 2 == 0) ? 0 : 120;
    for (double x = -100 + xOffset; x < width + 100; x += colSpacing) {
      textPainter.paint(canvas, Offset(x, y));
    }
  }

  final picture = recorder.endRecording();
  return await picture.toImage(width.toInt(), height.toInt());
}
