//this renders blue square correctly
import 'dart:async';
//import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';

class ExampleCube extends StatefulWidget {
  _ExampleCubeState createState() => _ExampleCubeState();
}

class _ExampleCubeState extends State<ExampleCube> {
  late FlutterGlPlugin flutterGlPlugin;
  int? fboId;
  num dpr = 1.0;
  late double width;
  late double height;

  Size? screenSize;

  dynamic glProgram;
  dynamic _vao;

  dynamic sourceTexture;

  dynamic defaultFramebuffer;
  dynamic defaultFramebufferTexture;

  int n = 0;

  int t = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();

    print(" init state..... ");
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = width;

    flutterGlPlugin = FlutterGlPlugin();

    Map<String, dynamic> _options = {
      "antialias": true,
      "alpha": false,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": dpr
    };

    await flutterGlPlugin.initialize(options: _options);

    print(" flutterGlPlugin: textureid: ${flutterGlPlugin.textureId} ");

    setState(() {});

    // web need wait dom ok!!!
    Future.delayed(Duration(milliseconds: 100), () {
      setup();
    });
  }

  setup() async {
    // web no need use fbo
    if (!kIsWeb) {
      await flutterGlPlugin.prepareContext();

      setupDefaultFBO();
      sourceTexture = defaultFramebufferTexture;
    }

    setState(() {

    });

    prepare();

  
    // animate();
  }

  initSize(BuildContext context) {
    if (screenSize != null) {
      return;
    }

    final mq = MediaQuery.of(context);

    screenSize = mq.size;
    dpr = mq.devicePixelRatio;

    print(" screenSize: ${screenSize} dpr: ${dpr} ");

    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Example cube rotation'),
        ),
        body: Builder(
          builder: (BuildContext context) {
            initSize(context);
            return SingleChildScrollView(child: _build(context));
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            clickRender();
          },
          child: Text("Render"),
        ),
      ),
    );
  }

  Widget _build(BuildContext context) {
    return Column(
      children: [
        Container(
            width: width,
            height: width,
            color: Colors.black,
            child: Builder(builder: (BuildContext context) {
              if (kIsWeb) {
                return flutterGlPlugin.isInitialized
                    ? HtmlElementView(
                        viewType: flutterGlPlugin.textureId!.toString())
                    : Container();
              } else {
                return flutterGlPlugin.isInitialized
                    ? Texture(textureId: flutterGlPlugin.textureId!)
                    : Container();
              }
            })),
      ],
    );
  }

  animate() {
    render();

    Future.delayed(Duration(milliseconds: 40), () {
      animate();
    });
  }

  setupDefaultFBO() {
    final _gl = flutterGlPlugin.gl;
    int glWidth = (width * dpr).toInt();
    int glHeight = (height * dpr).toInt();

    print("glWidth: ${glWidth} glHeight: ${glHeight} ");

    defaultFramebuffer = _gl.createFramebuffer();
    defaultFramebufferTexture = _gl.createTexture();
    _gl.activeTexture(_gl.TEXTURE0);

    _gl.bindTexture(_gl.TEXTURE_2D, defaultFramebufferTexture);
    _gl.texImage2D(_gl.TEXTURE_2D, 0, _gl.RGBA, glWidth, glHeight, 0, _gl.RGBA,
        _gl.UNSIGNED_BYTE, null);
    _gl.texParameteri(_gl.TEXTURE_2D, _gl.TEXTURE_MIN_FILTER, _gl.LINEAR);
    _gl.texParameteri(_gl.TEXTURE_2D, _gl.TEXTURE_MAG_FILTER, _gl.LINEAR);

    _gl.bindFramebuffer(_gl.FRAMEBUFFER, defaultFramebuffer);
    _gl.framebufferTexture2D(_gl.FRAMEBUFFER, _gl.COLOR_ATTACHMENT0,
        _gl.TEXTURE_2D, defaultFramebufferTexture, 0);
  }

  clickRender() {
    print(" click render ... ");
    //render();
    animate();
  }

  Float32List getXRotationMatrix(double angleX) {
    final cosX = cos(angleX);
    final sinX = sin(angleX);

    return Float32List.fromList([
      1.0, 0.0, 0.0, 0.0,
      0.0, cosX, -sinX, 0.0,
      0.0, sinX, cosX, 0.0,
      0.0, 0.0, 0.0, 1.0,
    ]);
  }

  Float32List getZRotationMatrix(double angleZ) {
    final cosZ = cos(angleZ);
    final sinZ = sin(angleZ);

    return Float32List.fromList([
      cosZ, -sinZ, 0.0, 0.0,
      sinZ, cosZ, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 1.0,
    ]);
  }

  Float32List getYRotationMatrix(double angleY) {
    final cosY = cos(angleY);
    final sinY = sin(angleY);

    return Float32List.fromList([
      cosY, 0.0, sinY, 0.0,
      0.0, 1.0, 0.0, 0.0,
      -sinY, 0.0, cosY, 0.0,
      0.0, 0.0, 0.0, 1.0,
    ]);
  }
  Float32List multiplyMatrices(Float32List a, Float32List b) {
  Float32List result = Float32List(16);

  for (int row = 0; row < 4; row++) {
    for (int col = 0; col < 4; col++) {
      result[row * 4 + col] =
          a[row * 4 + 0] * b[0 * 4 + col] +
          a[row * 4 + 1] * b[1 * 4 + col] +
          a[row * 4 + 2] * b[2 * 4 + col] +
          a[row * 4 + 3] * b[3 * 4 + col];
    }
  }

  return result;
}

  render() {
    final _gl = flutterGlPlugin.gl;

  // Calculate rotation angles for X, Y, and Z axes
  double angleX = (DateTime.now().millisecondsSinceEpoch % 7000) / 7000.0 * 2 * pi;
  double angleY = 0.2;
  double angleZ = (DateTime.now().millisecondsSinceEpoch % 9000) / 9000.0 * 2 * pi;

  // Create rotation matrices for each axis
  Float32List rotationMatrixX = getXRotationMatrix(angleX);
  Float32List rotationMatrixY = getYRotationMatrix(angleY);
  Float32List rotationMatrixZ = getZRotationMatrix(angleZ);

  // Combine the rotation matrices
  Float32List rotationMatrixXY = multiplyMatrices(rotationMatrixX, rotationMatrixY);
  Float32List combinedRotationMatrix = multiplyMatrices(rotationMatrixXY, rotationMatrixZ);


    // Pass the rotation matrix to the shader
    var u_ModelMatrix = _gl.getUniformLocation(glProgram, 'model');

    _gl.uniformMatrix4fv(u_ModelMatrix, false, combinedRotationMatrix);

    _gl.viewport(0, 0, (width * dpr).toInt(), (height * dpr).toInt());
    _gl.clearColor(1.0, 1.0, 1.0, 1.0);
    _gl.clear(_gl.COLOR_BUFFER_BIT);
    
    _gl.bindVertexArray(_vao);
    _gl.useProgram(glProgram);
    _gl.drawElements(_gl.TRIANGLES, 36 , _gl.UNSIGNED_SHORT, 0);

    //print(" render n: ${n} ");
    _gl.finish();

    // if (!kIsWeb) {
    //   flutterGlPlugin.updateTexture(sourceTexture);
    // }
  }

  prepare() {
    final _gl = flutterGlPlugin.gl;

    String _version = "300 es";

    // if(!kIsWeb) {
    //   if (Platform.isMacOS || Platform.isWindows) {
    //     _version = "150";
    //   }
    // }
    

    var vs = """#version ${_version}
    in vec3 a_Position;
    in vec3 a_Color;

    out vec3 v_Color;

    uniform mat4 model;
    uniform mat4 view;
    uniform mat4 projection;

    void main() {
        gl_Position = model * vec4(a_Position, 1.0);
        v_Color = a_Color;
    }
    """;

    var fs = """#version ${_version}
    in highp vec3 v_Color;

    out highp vec4 pc_fragColor;
    #define gl_FragColor pc_fragColor

    void main() {
        gl_FragColor = vec4(v_Color, 1.0);
    }
    """;

    if (!initShaders(_gl, vs, fs)) {
      print('Failed to intialize shaders.');
      return;
    }

    // Write the positions of vertices to a vertex shader
    n = initVertexBuffers(_gl);
    if (n < 0) {
      print('Failed to set the positions of the vertices');
      return;
    }
  }

initVertexBuffers(gl) {
  var dim = 3;
  var vertices = Float32List.fromList([
      // Front Face
      -0.5, -0.5, -0.5,   // Bottom left
      0.5, -0.5, -0.5,    // Bottom right
      0.5,  0.5, -0.5,    // Top right
      -0.5,  0.5, -0.5,   // Top left
      // Back Face
      -0.5, -0.5,  0.5,   // Bottom left
      0.5, -0.5,  0.5,    // Bottom right
      0.5,  0.5,  0.5,    // Top right
      -0.5,  0.5,  0.5,   // Top left

      // Top face
      -0.5, 0.5, -0.5,  // Top left
      0.5, 0.5, -0.5,   // Top right
      0.5, 0.5, 0.5,    // Bottom right
      -0.5, 0.5, 0.5,   // Bottom left

      // Bottom face
      -0.5, -0.5, -0.5, // Top left
      0.5, -0.5, -0.5,  // Top right
      0.5, -0.5, 0.5,   // Bottom right
      -0.5, -0.5, 0.5,  // Bottom left

      // Right face
      0.5, -0.5, -0.5,  // Bottom left
      0.5, 0.5, -0.5,   // Top left
      0.5, 0.5, 0.5,    // Top right
      0.5, -0.5, 0.5,   // Bottom right

      // Left face
      -0.5, -0.5, -0.5, // Bottom left
      -0.5, 0.5, -0.5,  // Top left
      -0.5, 0.5, 0.5,   // Top right
      -0.5, -0.5, 0.5   // Bottom right
  ]);
  var indices = Uint16Array.fromList([
    //front face
    0, 1, 2, //bottom right
    2, 3, 0, //top left

    // Back face
    4, 5, 6,
    6, 7, 4,

    // Top face
    8, 9, 10,
    10, 11, 8,

    // Bottom face
    12, 13, 14,
    14, 15, 12,

    // Right face
    16, 17, 18,
    18, 19, 16,

    // Left face
    20, 21, 22,
    22, 23, 20
  ]);
 var colors = Float32List.fromList([
      // Colors for each vertex
      1.0, 0.0, 0.0, // Front face (Red)
      1.0, 0.0, 0.0,
      1.0, 0.0, 0.0,
      1.0, 0.0, 0.0,

      0.0, 1.0, 0.0, // Back face (Green)
      0.0, 1.0, 0.0,
      0.0, 1.0, 0.0,
      0.0, 1.0, 0.0,

      0.0, 0.0, 1.0, // Top face (Blue)
      0.0, 0.0, 1.0,
      0.0, 0.0, 1.0,
      0.0, 0.0, 1.0,

      1.0, 1.0, 0.0, // Bottom face (Yellow)
      1.0, 1.0, 0.0,
      1.0, 1.0, 0.0,
      1.0, 1.0, 0.0,

      1.0, 0.0, 1.0, // Right face (Magenta)
      1.0, 0.0, 1.0,
      1.0, 0.0, 1.0,
      1.0, 0.0, 1.0,

      0.0, 1.0, 1.0, // Left face (Cyan)
      0.0, 1.0, 1.0,
      0.0, 1.0, 1.0,
      0.0, 1.0, 1.0,
  ]);
  _vao = gl.createVertexArray();
  gl.bindVertexArray(_vao);

// Create a buffer object
    var vertexBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, vertices.lengthInBytes, vertices, gl.STATIC_DRAW);

    var indexBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, indices.lengthInBytes, indices, gl.STATIC_DRAW);

  // Color buffer
    var colorBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, colorBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, colors.lengthInBytes, colors, gl.STATIC_DRAW);

    // Assign the vertices in buffer object to a_Position variable
    var a_Position = gl.getAttribLocation(glProgram, 'a_Position');
    gl.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);

    gl.vertexAttribPointer(a_Position, dim, gl.FLOAT, false, 0, 0);
    gl.enableVertexAttribArray(a_Position);

    
  // Assign the colors in buffer object to a_Color variable
    var a_Color = gl.getAttribLocation(glProgram, 'a_Color');
    gl.bindBuffer(gl.ARRAY_BUFFER, colorBuffer);
    gl.vertexAttribPointer(a_Color, 3, gl.FLOAT, false, 0, 0);
    gl.enableVertexAttribArray(a_Color);
    // Return number of vertices
    return vertices.length;
  }
  
  initShaders(gl, vs_source, fs_source) {
    // Compile shaders
    var vertexShader = makeShader(gl, vs_source, gl.VERTEX_SHADER);
    var fragmentShader = makeShader(gl, fs_source, gl.FRAGMENT_SHADER);

    // Create program
    glProgram = gl.createProgram();

    // Attach and link shaders to the programR
    gl.attachShader(glProgram, vertexShader);
    gl.attachShader(glProgram, fragmentShader);
    gl.linkProgram(glProgram);
    var _res = gl.getProgramParameter(glProgram, gl.LINK_STATUS);
    print(" initShaders LINK_STATUS _res: ${_res} ");
    if (_res == false || _res == 0) {
      print("Unable to initialize the shader program");
      return false;
    }
    // Use program
    gl.useProgram(glProgram);

    return true;
  }

  makeShader(gl, src, type) {
    var shader = gl.createShader(type);
    gl.shaderSource(shader, src);
    gl.compileShader(shader);
    var _res = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
    if (_res == 0 || _res == false) {
      print("Error compiling shader: ${gl.getShaderInfoLog(shader)}");
      return;
    }
    return shader;
  }
}
