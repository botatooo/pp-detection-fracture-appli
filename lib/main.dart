import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:pp_detection_fracture/widgets/bb_image.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Détection de fractures",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MainPage(title: "Détection de fractures"),
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
  int currentPage = 0;

  late FlutterVision vision;
  bool isLoaded = false;

  late List<Map<String, dynamic>> detectionResults;
  bool ranDetection = false;
  XFile? imageFile;
  int imageHeight = 1;
  int imageWidth = 1;

  @override
  void initState() {
    vision = FlutterVision();
    loadYoloModel().then((value) {
      setState(() {
        detectionResults = [];
        isLoaded = true;
      });
    });
    super.initState();
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage == null) {
      return;
    }

    setState(() {
      imageFile = pickedImage;
      detectionResults = [];
      ranDetection = false;
    });
  }

  Future<void> loadYoloModel() async {
    await vision.loadYoloModel(
        labels: 'assets/labels.txt',
        modelPath: 'assets/yolov8n_fracatlas_float32.tflite',
        modelVersion: "yolov8",
        quantization: false,
        numThreads: 2,
        useGpu: true
    );
  }

  Future<void> runInference() async {
    detectionResults.clear();

    Uint8List imageBytes = await imageFile!.readAsBytes();
    final image = await decodeImageFromList(imageBytes);

    imageHeight = image.height;
    imageWidth = image.width;

    // print("height ${image.height}");
    // print("width ${image.width}");

    final result = await vision.yoloOnImage(
        bytesList: imageBytes,
        imageHeight: image.height,
        imageWidth: image.width,
        iouThreshold: 0.8,
        confThreshold: 0.4,
        classThreshold: 0.1 // 0.3
    );

    // highest score first
    result.sort((a, b) => a["box"][4].compareTo(b["box"][4]));

    // print(result);
    setState(() {
      detectionResults = result;
      ranDetection = true;
    });
  }


  @override
  Widget build(BuildContext context) {
    if (!isLoaded) {
      return const Scaffold(
        body: Center(
          child: Text("Loading model..."),
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: IndexedStack(
          index: currentPage,
          children: [
            // accueil
            Center(
              child: Flex(
                direction: Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Expanded(
                    flex: 7,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GestureDetector(
                        onTap: pickImage,
                        child: BBImage(
                          detectionResults: detectionResults,
                          imageFile: imageFile,
                          imageHeight: imageHeight,
                          imageWidth: imageWidth,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ranDetection
                        ? detectionResults.isEmpty
                          ? const Text("Aucune fracture trouvée")
                          : detectionResults.length == 1
                            ? const Text("1 fracture trouvée")
                            : Text("${detectionResults.length} fractures trouvées")
                        : const Text("Les résultats seront affichés ici")
                  ),
                  Expanded(
                    flex: 3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 32.0, bottom: 32.0),
                          child: FilledButton(
                            onPressed: () {
                              if (detectionResults.isNotEmpty) {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text("Êtes-vous certain de vouloir resoumettre l'image?"),
                                        actions: [
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              textStyle: Theme.of(context).textTheme.labelLarge,
                                            ),
                                            onPressed: () {
                                              if (imageFile != null) {
                                                runInference();
                                              }
                                              Navigator.pop(context);
                                            },
                                            child: const Text("Oui"),
                                          ),
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              textStyle: Theme.of(context).textTheme.labelLarge,
                                            ),
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text("Non, annuler"),
                                          ),
                                        ],
                                      );
                                    });
                                return;
                              }

                              if (imageFile != null) {
                                runInference();
                              }
                            },
                            child: const Text("Traiter"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // à propos
            Wrap(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 16.0),
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
                          text:
                          "sous la supervision de François Goulet de l'École internationale de Montréal.",
                        ),
                      ],
                    ),
                    maxLines: null,
                    softWrap: true,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: RichText(
                    text: TextSpan(
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodyLarge,
                      children: [
                        TextSpan(
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.blue,
                          ),
                          text: "Code source pour l'application",
                          recognizer: TapGestureRecognizer()
                            ..onTap = () =>
                                launchUrl(
                                  Uri.parse(
                                    "https://github.com/botatooo/pp-detection-fracture-appli",
                                  ),
                                  mode: LaunchMode.externalApplication,
                                ),
                        ),
                        const TextSpan(text: "\n"),
                        TextSpan(
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.blue,
                          ),
                          text: "Code source pour le modèle IA",
                          recognizer: TapGestureRecognizer()
                            ..onTap = () =>
                                launchUrl(
                                  Uri.parse(
                                    "https://github.com/botatooo/pp-detection-fracture-recherche",
                                  ),
                                  mode: LaunchMode.externalApplication,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              // icon: Icon(Icons.camera_alt_outlined),
              icon: Icon(Icons.camera_enhance_rounded),
              label: "Accueil",
            ),
            NavigationDestination(
              // icon: Icon(Icons.info_outline_rounded),
              icon: Icon(Icons.info_rounded),
              label: "À propos",
            ),
          ],
          selectedIndex: currentPage,
          onDestinationSelected: (newPage) {
            setState(() {
              currentPage = newPage;
            });
          },
        ),
      );
    });
  }
}
