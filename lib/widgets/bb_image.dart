import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class BBImage extends StatefulWidget {
  final List<Map<String, dynamic>> detectionResults;
  final int imageWidth;
  final int imageHeight;
  final XFile? imageFile;
  Size? imageSize;

  BBImage({super.key, required this.detectionResults, required this.imageWidth, required this.imageHeight, required this.imageFile});

  @override
  _BBImageState createState() => _BBImageState();
}

class _BBImageState extends State<BBImage> {
  Size? imageSize;

  List<Widget> displayBoxesAroundRecognizedObjects(Size render) {
    // print(render);

    if (widget.detectionResults.isEmpty) return [];

    return widget.detectionResults.map((result) {
      return Positioned(
        left: (result["box"][0] / widget.imageWidth) * render.width,
        top: (result["box"][1] / widget.imageHeight) * render.height,
        width: ((result["box"][2] - result["box"][0]) / widget.imageHeight) * render.height,
        height: ((result["box"][3] - result["box"][1]) / widget.imageWidth) * render.width,
        child: Container(
            decoration: BoxDecoration(
              border: result["box"][4] > 0.4
                  ? Border.all(color: Colors.green, width: 3.0)
                  : Border.all(color: Colors.pink, width: 1.0),
            ),
          ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          // Check if imageSize is different before updating to avoid unnecessary rebuilds
          if (imageSize != renderBox.size) {
            setState(() {
              imageSize = renderBox.size;
            });
          }
        }
        // print("image after render : $imageSize, H: ${imageSize?.height}");
      });

      return Stack(
        children: <Widget>[
          widget.imageFile != null
              ? Image.file(
            File(widget.imageFile!.path),
            fit: BoxFit.contain,
          )
              : Image.asset(
            "assets/placeholder.png",
            fit: BoxFit.contain,
          ),
          if (imageSize != null) ...displayBoxesAroundRecognizedObjects(imageSize!),
        ],
      );
    });
  }
}