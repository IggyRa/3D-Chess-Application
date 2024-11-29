import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three_dart.dart' as three;
import 'package:three_dart_jsm/three_dart_jsm.dart' as three_jsm;

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});
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
    Future.delayed(const Duration(milliseconds: 100), () async {
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
      floatingActionButton: FloatingActionButton(
        child: const Text("render"),
        onPressed: () {
          render();
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
    //int t = DateTime.now().millisecondsSinceEpoch;

    final gl = three3dRender.gl;

    renderer!.render(scene, camera);

    //int t1 = DateTime.now().millisecondsSinceEpoch;

    // if (verbose) {
    //   print("render cost: ${t1 - t} ");
    //   print(renderer!.info.memory);
    //   print(renderer!.info.render);
    // }

    gl.flush();

    //if (verbose) print(" render: sourceTexture: $sourceTexture ");

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

  initPage() async {
    camera = three.PerspectiveCamera(45, width / height, 1, 2000);
    camera.position.set(0, 100, 150); // Adjust camera position
    // scene

    scene = three.Scene();

    controls = three_jsm.OrbitControls(camera, _globalKey);
    // controls.listenToKeyEvents( window );

    //controls.addEventListener( 'change', render ); // call this only in static scenes (i.e., if there is no animation loop)

    controls.enableDamping =
        true; // an animation loop is required when either damping or auto-rotation are enabled
    controls.dampingFactor = 0.05;

    controls.screenSpacePanning = false;

    controls.minDistance = 10;
    controls.maxDistance = 1000;

    controls.maxPolarAngle = three.Math.pi / 2;

    var ambientLight = three.AmbientLight(0xcccccc, 0.4);
    scene.add(ambientLight);

    var pointLight = three.PointLight(0xffffff, 0.8);
    camera.add(pointLight);
    scene.add(camera);
    scene.background = three.Color(0xd3d3d3);
    // texture
    var manager = three.LoadingManager();

    var mtlLoader = three_jsm.MTLLoader(manager);

    var loader = three_jsm.OBJLoader(null);

    mtlLoader.setPath('assets/models/obj_models/chess/');
    var materials = await mtlLoader.loadAsync('chess.mtl');
    await materials.preload();

    loader.setMaterials(materials);
    object = await loader.loadAsync('assets/models/obj_models/chess/chess.obj');
    object.scale.set(0.5, 0.5, 0.5);
    object.position.set(0, -2);
    object.rotation.x = -three.Math.pi / 2;
    scene.add(object);

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
        //await loader.loadAsync('assets/models/obj_models/set/white_bishop.obj');
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
    // bbishop =
    //     await loader.loadAsync('assets/models/obj_models/set/black_bishop.obj');
    bpawn =
        await loader.loadAsync('assets/models/obj_models/set/black_pawn.obj');

//set white positions
    wrook.position.set(-8, 0, 8);
    three.Object3D wrook2 = wrook.clone();
    wrook2.position.set(8, 0, 8);

    // wbishop.position.set(-5.75, 0, 8);
    // three.Object3D wbishop2 = wbishop.clone();
    // wbishop2.position.set(5.75, 0, 8);

    wknight.position.set(-3.5, 0, 8);
    three.Object3D wknight2 = wknight.clone();
    wknight2.position.set(3.5, 0, 8);
    wknight.rotation.y = three.Math.pi;
    wknight2.rotation.y = three.Math.pi;

    wking.position.set(1.25, 1, 8);
    wqueen.position.set(-1.25, 1, 8);
//set black positions

    brook.position.set(8, 0, -8);
    three.Object3D brook2 = brook.clone();
    brook2.position.set(-8, 0, -8);

    // bbishop.position.set(-5.75, 0, 8);
    // three.Object3D bbishop2 = bbishop.clone();
    // bbishop2.position.set(5.75, 0, 8);

    bknight.position.set(-3.5, 0, -8);
    three.Object3D bknight2 = bknight.clone();
    bknight2.position.set(3.5, 0, -8);
        bknight.rotation.y = three.Math.pi;
    bknight2.rotation.y = three.Math.pi;

    bking.position.set(-1.25, 1, -8);
    bqueen.position.set(-1.25, 1, -8);
    //adding white pieces
    scene.add(wrook);
    scene.add(wrook2);
    scene.add(wknight);
    scene.add(wknight2);
    scene.add(wking);
    scene.add(wqueen);

    //adding white pieces
    scene.add(brook);
    scene.add(brook2);
    scene.add(bknight);
    scene.add(bknight2);
    scene.add(bking);
    scene.add(bqueen);
    for (double i = 0; i < 8; i++) {
      three.Object3D newwpawn = wpawn.clone();
      newwpawn.name = "wpawn$i";
      //initial offset is 8, each separated by 2.25
      newwpawn.position.set(-2.25 * i + 8, 0, 5.5);
      scene.add(newwpawn);
    }
    //adding black pieces
    scene.add(brook);

    for (double i = 0; i < 8; i++) {
      three.Object3D newbpawn = bpawn.clone();
      newbpawn.name = "bpawn$i";
      //initial offset is 8, each separated by 2.25
      newbpawn.position.set(-2.25 * i + 8, 0, -5.5);
      scene.add(newbpawn);
    }

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
    print(" dispose ............. ");
    disposed = true;
    three3dRender.dispose();

    super.dispose();
  }
}
