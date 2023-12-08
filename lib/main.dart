import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FraDet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
        useMaterial3: true,
      ),
      home: const MainPage(title: 'FraDet'),
      navigatorKey: navigatorKey,
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.title});

  final String title;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Uint8List imageBytes = Uint8List(0);
  Uint8List processedImageBytes = Uint8List(0);

  // Future<void> getLostData() async {
  //   final ImagePicker picker = ImagePicker();
  //   final LostDataResponse response = await picker.retrieveLostData();
  //   if (response.isEmpty) {
  //     return;
  //   }
  //   final List<XFile>? files = response.files;
  //   if (files != null) {
  //     _handleLostFiles(files);
  //   } else {
  //     _handleError(response.exception);
  //   }
  // }
  //
  // void _handleLostFiles(List<XFile> files) {
  //   XFile file = files[0];
  //
  //   if (file == null) {
  //     return;
  //   }
  //
  //   if (!file.mimeType!.startsWith("image/")) {
  //     PlatformException error = PlatformException(
  //       code: "ASD_WRONG_MEDIA_TYPE_RECOVERED",
  //       message: "how the hell did you even get here",
  //     );
  //     _handleError(error);
  //   }
  //
  //   setState(() async {
  //     hasImage = true;
  //     imageBytes = await file.readAsBytes();
  //   });
  // }
  //
  // void _handleError(PlatformException? error) {
  //   if (error == null) {
  //     return;
  //   }
  //
  //   showDialog(
  //     context: navigatorKey.currentContext!,
  //     builder: (BuildContext context) {
  //       return Wrap(
  //         children: [
  //           Text("Error occurred",
  //               style: Theme.of(context).textTheme.headlineLarge),
  //           Text("${error.code}: ${error.message}"),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.info),
            tooltip: "À propos",
            onPressed: () {
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                builder: (BuildContext context) {
                  return Wrap(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(
                          "À propos",
                          style: Theme
                              .of(context)
                              .textTheme
                              .headlineMedium,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: RichText(
                          text: TextSpan(
                            style: Theme
                                .of(context)
                                .textTheme
                                .bodyLarge,
                            children: const <TextSpan>[
                              TextSpan(
                                text: "Conception et programmation par ",
                              ),
                              TextSpan(
                                text: "Adnan Taha ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: "sous la supervision de François Goulet.",
                              ),
                            ],
                          ),
                          maxLines: null,
                          softWrap: true,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GestureDetector(
              onTap: () async {
                final ImagePicker picker = ImagePicker();

                final XFile? image =
                await picker.pickImage(source: ImageSource.gallery);
                if (image == null) {
                  return;
                }

                setState(() async {
                  imageBytes = await image.readAsBytes();
                });
              },
              child: processedImageBytes.isNotEmpty
                  ? Image.memory(
                processedImageBytes,
                fit: BoxFit.cover,
                width: 110.0,
                height: 110.0,
              )
                  : imageBytes.isNotEmpty
                  ? Image.memory(
                imageBytes,
                fit: BoxFit.cover,
                width: 110.0,
                height: 110.0,
              )
                  : Image.asset(
                'placeholder.png',
                fit: BoxFit.cover,
                width: 220.0,
                height: 220.0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
              child: TextButton(
                onPressed: () {
                  if (processedImageBytes.isNotEmpty) {
                    bool wantsToProceed = false;
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          child: Column(
                            children: [
                              const Text(
                                "Êtes-vous certain de vouloir resoumettre l'image?",
                              ),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      wantsToProceed = true;
                                      Navigator.pop(context);
                                    },
                                    child: const Text("Oui"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      wantsToProceed = false;
                                      Navigator.pop(context);
                                    },
                                    child: const Text("Non, annuler"),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      }
                    );

                    if (!wantsToProceed) {
                      return;
                    }
                  }

                  if (imageBytes.isNotEmpty) {
                    Uint8List? processedStuff;

                    // todo: do the processing

                    setState(() {
                      processedImageBytes = processedStuff;
                    });
                  }
                },
                child: const Text("Traiter"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
