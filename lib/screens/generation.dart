import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three_dart.dart' as three;
import 'package:three_dart_jsm/three_dart_jsm.dart' as three_jsm;

class GenerateScreen extends StatefulWidget {
  const GenerateScreen(
      {super.key, required this.board, required this.whitePov});
  final List<String> board;
  final bool whitePov;
  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  late FlutterGlPlugin three3dRender;
  three.WebGLRenderer? renderer;

  int? fboId;
  late double width;
  late double height;

  Size? screenSize;

  late three.Scene scene;
  late three.Camera camera;
  late three.Mesh mesh;

  double dpr = 1.0;

  var amount = 4;

  bool verbose = true;
  bool disposed = false;

  late three.Object3D object,
      wking,
      wrook,
      wpawn,
      wknight,
      wbishop,
      wqueen,
      bking,
      brook,
      bpawn,
      bknight,
      bbishop,
      bqueen;

  late three.Texture texture;

  late three.WebGLMultisampleRenderTarget renderTarget;

  late three_jsm.OrbitControls controls;
  final GlobalKey<three_jsm.DomLikeListenableState> _globalKey =
      GlobalKey<three_jsm.DomLikeListenableState>();
  dynamic sourceTexture;

  @override
  void initState() {
    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = screenSize!.height;

    three3dRender = FlutterGlPlugin();

    Map<String, dynamic> options = {
      "antialias": true,
      "alpha": false,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": dpr
    };

    await three3dRender.initialize(options: options);

    setState(() {});

    // Wait for web
    Future.delayed(const Duration(milliseconds: 10), () async {
      await three3dRender.prepareContext();

      initScene();
    });
  }

  initSize(BuildContext context) {
    if (screenSize != null) {
      return;
    }

    final mqd = MediaQuery.of(context);

    screenSize = mqd.size;
    dpr = mqd.devicePixelRatio;

    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Generation"),
      ),
      body: Builder(
        builder: (BuildContext context) {
          initSize(context);
          return SingleChildScrollView(child: _build(context));
        },
      ),
    );
  }

  Widget _build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            three_jsm.DomLikeListenable(
                key: _globalKey,
                builder: (BuildContext context) {
                  return Container(
                      width: width,
                      height: height,
                      color: Colors.black,
                      child: Builder(builder: (BuildContext context) {
                        if (kIsWeb) {
                          return three3dRender.isInitialized
                              ? HtmlElementView(
                                  viewType: three3dRender.textureId!.toString())
                              : Container();
                        } else {
                          return three3dRender.isInitialized
                              ? Texture(textureId: three3dRender.textureId!)
                              : Container();
                        }
                      }));
                }),
          ],
        ),
      ],
    );
  }

  render() {
    final gl = three3dRender.gl;

    renderer!.render(scene, camera);

    if (verbose) {
      print(renderer!.info.memory);
      print(renderer!.info.render);
    }

    gl.flush();

    if (verbose) print(" render: sourceTexture: $sourceTexture ");

    if (!kIsWeb) {
      three3dRender.updateTexture(sourceTexture);
    }
  }

  initRenderer() {
    Map<String, dynamic> options = {
      "width": width,
      "height": height,
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element
    };
    renderer = three.WebGLRenderer(options);
    renderer!.setPixelRatio(dpr);
    renderer!.setSize(width, height, false);
    renderer!.shadowMap.enabled = false;

    if (!kIsWeb) {
      var pars = three.WebGLRenderTargetOptions({"format": three.RGBAFormat});
      renderTarget = three.WebGLMultisampleRenderTarget(
          (width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderTarget.samples = 4;
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget);
    }
  }

  initScene() {
    initRenderer();
    initPage();
  }

  initPage() {
    camera = three.PerspectiveCamera(45, width / height, 1, 2000);
    widget.whitePov
        ? camera.position.set(0, 25, 60)
        : camera.position.set(0, 25, -60);
    // scene
    scene = three.Scene();

    controls = three_jsm.OrbitControls(camera, _globalKey);

    controls.enableDamping =
        true; // an animation loop is required when either damping or auto-rotation are enabled
    controls.dampingFactor = 0.05;

    controls.screenSpacePanning = false;

    controls.minDistance = 25;
    controls.maxDistance = 100;

    controls.maxPolarAngle = three.Math.PI / 2;

    var ambientLight = three.AmbientLight(0xcccccc, 0.4);
    scene.add(ambientLight);

    var pointLight = three.PointLight(0xffffff, 0.8);
    camera.add(pointLight);
    scene.add(camera);
    scene.background = three.Color(0xd3d3d3);
    loadAll();

    animate();
  }

  animate() {
    if (!mounted || disposed) {
      return;
    }

    render();

    Future.delayed(const Duration(milliseconds: 50), () {
      animate();
    });
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      print(" disposed on not web");
      disposed = true;
      //renderer!.dispose();
      scene.dispose();
    } else {
      print("disposed on web");
      scene.dispose();
    }
    super.dispose();
  }

  loadAll() async {
    var manager = three.LoadingManager();

    var mtlLoader = three_jsm.MTLLoader(manager);

    var loader = three_jsm.OBJLoader(null);

    //Wooden board
    mtlLoader.setPath('assets/models/obj_models/chess/');
    var materials = await mtlLoader.loadAsync('chess.mtl');
    await materials.preload();
    loader.setMaterials(materials);
    object = await loader.loadAsync('assets/models/obj_models/chess/chess.obj');
    object.scale.set(0.5, 0.5, 0.5);
    object.position.set(0, -2);
    object.rotation.x = -three.Math.PI / 2;
    scene.add(object);

    //Stone board
    // mtlLoader.setPath('assets/models/obj_models/chess2/');
    // var materials = await mtlLoader.loadAsync('chess.mtl');
    // await materials.preload();
    // loader.setMaterials(materials);
    // object = await loader.loadAsync('assets/models/obj_models/chess2/chess.obj');
    // object.scale.set(0.42, 0.42, 0.42);
    // object.position.set(0, -1.2);
    // object.rotation.x = -three.Math.PI / 2;
    // scene.add(object);

    mtlLoader.setPath('assets/models/obj_models/set/');
    var whiteMaterial = await mtlLoader.loadAsync('white_material.mtl');
    await whiteMaterial.preload();

    loader.setMaterials(whiteMaterial);
    wking =
        await loader.loadAsync('assets/models/obj_models/set/white_king.obj');
    wqueen =
        await loader.loadAsync('assets/models/obj_models/set/white_queen.obj');
    wrook =
        await loader.loadAsync('assets/models/obj_models/set/white_rook.obj');
    wknight =
        await loader.loadAsync('assets/models/obj_models/set/white_knight.obj');
    wbishop =
        await loader.loadAsync('assets/models/obj_models/set/white_bishop.obj');
    wpawn =
        await loader.loadAsync('assets/models/obj_models/set/white_pawn.obj');

    var blackMaterial = await mtlLoader.loadAsync('black_material.mtl');
    await blackMaterial.preload();
    loader.setMaterials(blackMaterial);
    bking =
        await loader.loadAsync('assets/models/obj_models/set/black_king.obj');
    bqueen =
        await loader.loadAsync('assets/models/obj_models/set/black_queen.obj');
    brook =
        await loader.loadAsync('assets/models/obj_models/set/black_rook.obj');
    bknight =
        await loader.loadAsync('assets/models/obj_models/set/black_knight.obj');
    bbishop =
        await loader.loadAsync('assets/models/obj_models/set/black_bishop.obj');
    bpawn =
        await loader.loadAsync('assets/models/obj_models/set/black_pawn.obj');
    List<String> board = [];
    if (widget.board.isEmpty) {
      board = [
    'r', 'n', 'b', 'q', 'k', 'b', 'n', 'r',
    'p', 'p', 'p', 'p', 'p', 'p', 'p', 'p',
    '', '', '', '', '', '', '', '',
    '', '', '', '', '', '', '', '',
    '', '', '', '', '', '', '', '',
    '', '', '', '', '', '', '', '',
    'P', 'P', 'P', 'P', 'P', 'P', 'P', 'P',
    'R', 'N', 'B', 'Q', 'K', 'B', 'N', 'R',];
    } else {
      board = widget.board;
    }

    for (int i = 0; i < 64; i++) {
      if (board[i] == '') {
      } else {
        double x = (2.25 * (i % 8) - 8);

        double z = -8 + (i ~/ 8) * 2.25;

        if (board[i] == 'r') {
          three.Object3D newbrook = brook.clone();
          newbrook.name = "brook$i";
          newbrook.position.set(x, 0, z);
          scene.add(newbrook);
        } else if (board[i] == 'n') {
          three.Object3D newbknight = bknight.clone();
          newbknight.name = "bknight$i";
          newbknight.position.set(x, 0.25, z);
          newbknight.rotation.y = three.Math.PI;
          scene.add(newbknight);
        } else if (board[i] == 'b') {
          three.Object3D newbbishop = bbishop.clone();
          newbbishop.name = "bbishop$i";
          newbbishop.position.set(x, 0.5, z);
          scene.add(newbbishop);
        } else if (board[i] == 'q') {
          bqueen.position.set(x, 0.75, z);
          scene.add(bqueen);
        } else if (board[i] == 'k') {
          bking.position.set(x, 0.9, z);
          scene.add(bking);
        } else if (board[i] == 'p') {
          three.Object3D newbpawn = bpawn.clone();
          newbpawn.name = "bpawn$i";
          newbpawn.position.set(x, 0, z);
          scene.add(newbpawn);
        } else if (board[i] == 'P') {
          three.Object3D newwpawn = wpawn.clone();
          newwpawn.name = "wpawn$i";
          newwpawn.position.set(x, 0, z);
          scene.add(newwpawn);
        } else if (board[i] == 'R') {
          three.Object3D newwrook = wrook.clone();
          newwrook.name = "wrook$i";
          newwrook.position.set(x, 0, z);
          scene.add(newwrook);
        } else if (board[i] == 'N') {
          three.Object3D newwknight = wknight.clone();
          newwknight.name = "wknight$i";
          newwknight.position.set(x, 0.25, z);
          newwknight.rotation.y = three.Math.PI;
          scene.add(newwknight);
        } else if (board[i] == 'B') {
          three.Object3D newwbishop = wbishop.clone();
          newwbishop.name = "wbishop$i";
          newwbishop.position.set(x, 0.5, z);
          scene.add(newwbishop);
        } else if (board[i] == 'Q') {
          wqueen.position.set(x, 0.75, z);
          scene.add(wqueen);
        } else if (board[i] == 'K') {
          wking.position.set(x, 0.9, z);
          scene.add(wking);
        }
      }
    }
  }
}