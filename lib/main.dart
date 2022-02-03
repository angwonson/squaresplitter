import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as imglib;
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Image> myImageList = [];

  Future<List<Image>> splitImage(
      {required String inputImage,
      required int horizontalPieceCount,
      required int verticalPieceCount}) async {
    Uint8List rawImg = (await http.get(Uri.parse(inputImage))).bodyBytes;
    final baseSizeImage = imglib.decodeImage(rawImg);

    final int xLength = (baseSizeImage!.width / horizontalPieceCount).floor();
    final int yLength = (baseSizeImage.height / verticalPieceCount).floor();
    final int xRemainder = baseSizeImage.width.remainder(horizontalPieceCount);
    final int yRemainder = baseSizeImage.height.remainder(verticalPieceCount);
    debugPrint('X $xLength BY Y: $yLength REMAINDER X: $xRemainder Y: $yRemainder');
    List<imglib.Image> pieceList = [];

    int startX = 0;
    int startY = 0;
    for (int y = 0; y < verticalPieceCount; y++) {
      /// Add an extra pixel if there is a remainder from the division above
      int tweakedYLength = yLength;
      if (y < yRemainder) {
        tweakedYLength++;
      }
      for (int x = 0; x < horizontalPieceCount; x++) {
        int tweakedXLength = xLength;
        if (x < xRemainder) {
          tweakedXLength++;
        }
        debugPrint(
            'YCOUNT: $y XCOUNT: $x START X: $startX START Y: $startY END X: $tweakedXLength END Y: $tweakedYLength');
        pieceList.add(
          imglib.copyCrop(
              baseSizeImage, startX, startY, tweakedXLength, tweakedYLength),
        );
        startX = startX + tweakedXLength;
      }
      startX = 0;
      startY = startY + tweakedYLength;
    }

    /// Convert image from image package to Image Widget to display
    List<Image> outputImageList = [];
    for (imglib.Image img in pieceList) {
      outputImageList
          .add(Image.memory(Uint8List.fromList(imglib.encodeJpg(img))));
    }
    setState(() {
      myImageList = outputImageList;
    });

    return outputImageList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 516,
        ),
        child: GridView.count(
          // childAspectRatio: 3 / 2,
          padding: const EdgeInsets.all(4),
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          crossAxisCount: 4,
          children: myImageList,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          splitImage(
            // inputImage: 'https://blahblahblash.com/assets/515x515.png', // PNG with remainder
            inputImage: 'https://lh3.googleusercontent.com/CrSXeD3t60EdSZqBPSdzU82aA9zd5n5W5ap0Feg1efE7dB4NHjFU2sHTLAhem22Hezt9PSIPWFQUGoG_TJBzccwPGpzwyXoGbOHJtQ', // PNG
            // inputImage:
            //     'https://lh3.googleusercontent.com/Yd_G8wkjv1zm5m0aOocKVIJXFYAK_mukcLAwE1dF7bJWDXw_KQ-LqrKsoPXvpcGIZLl7-zfAZKr9cIJwiGuiPvB07ZOV85x-_vDk6w', // JPG
            horizontalPieceCount: 4,
            verticalPieceCount: 4,
          );
        },
        tooltip: 'Split It',
        child: const Icon(Icons.playlist_add_check_outlined),
      ),
    );
  }
}
