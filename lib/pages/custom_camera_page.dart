import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math';
import 'package:http/http.dart' as http;

class CustomCameraPage extends StatefulWidget {
  const CustomCameraPage({super.key});

  @override
  State<CustomCameraPage> createState() => _CustomCameraPageState();
}

class _CustomCameraPageState extends State<CustomCameraPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIdx = 0;
  bool _isProcessing = false;
  FlashMode _flashMode = FlashMode.off;
  DeviceOrientation _deviceOrientation = DeviceOrientation.portraitUp;
  StreamSubscription? _orientationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _compassSubscription;
  StreamSubscription? _barometerSubscription;
  bool _isBarometerAvailable = false; // Penanda untuk fallback ke GPS
  Timer? _timer;

  final GlobalKey _previewContainerKey = GlobalKey();
  // final GlobalKey _watermarkKey = GlobalKey(); // <-- TAMBAHKAN KEY BARU INI

  final String _mapboxAccessToken = 'pk.eyJ1Ijoia2V2aW5uZG55IiwiYSI6ImNtY2U1Z2s4cDBxNzQya3EwemxteWszdTUifQ.TEa6hvVDjZhKWVya8-t_bA';
  // final String _googleMapsApiKey = 'AIzaSyBZCUJ_MEIuyJ4cBiXJOErt61_aKrnOYYI';

  String _address = "Mencari lokasi...";
  String _gpsCoordinates = "";
  String _timestamp = "";
  String? _mapImageUrl;
  String _shortAddress = "";
  String _altitudeInfo = "";
  String _attitudeInfo = "";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _getCurrentLocationForPreview();
    _listenToLocationAndCompass();
    _startListeningOrientation();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTimestamp());
  }

  @override
  void dispose() {
    _controller?.dispose();
    _orientationSubscription?.cancel();
    _positionSubscription?.cancel();
    _compassSubscription?.cancel();
    _barometerSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimestamp() {
    if (!mounted) return; // Pastikan widget masih ada di tree

    final timeZoneOffset = DateTime.now().timeZoneOffset;
    final timeZoneName = timeZoneOffset.isNegative
        ? "GMT${timeZoneOffset.toString().split(':')[0]}"
        : "GMT+${timeZoneOffset.toString().split(':')[0]}";

    setState(() {
      _timestamp = "${DateFormat('dd/MM/yyyy HH:mm:ss', 'id_ID').format(DateTime.now())} $timeZoneName";
    });
  }

  void _listenToLocationAndCompass() {
    // 1. Prioritas Utama: Stream untuk Ketinggian dari Barometer (Lebih Stabil)
    _barometerSubscription = barometerEventStream().listen((BarometerEvent event) {
      // Jika stream ini berjalan, berarti sensor tersedia
      print('Tekanan Barometer: ${event.pressure}');
      if (!_isBarometerAvailable) {
        setState(() {
          _isBarometerAvailable = true;
        });
      }

      // Formula untuk konversi tekanan (hPa) ke ketinggian (meter)
      // Menggunakan tekanan permukaan laut standar (1013.25 hPa) sebagai referensi.
      final seaLevelPressure = 1013.25;
      final pressure = event.pressure;
      // Rumus Barometrik
      final altitude = 44330 * (1 - pow(pressure / seaLevelPressure, 1 / 5.255));

      if (mounted) {
        setState(() {
          _altitudeInfo = "Ketinggian: ${altitude.toStringAsFixed(4)} m";
        });
      }
    }, onError: (error) {
      // Jika perangkat tidak punya barometer, stream akan error.
      // Kita set penanda ke false agar GPS mengambil alih.
      if (mounted) {
        setState(() {
          _isBarometerAvailable = false;
        });
      }
      print("Tidak ada sensor barometer, menggunakan GPS sebagai fallback.");
    });

    // 2. Stream untuk Koordinat (dari Geolocator) dan Ketinggian (sebagai fallback)
    _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
        )
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          // Selalu update koordinat
          _gpsCoordinates = "Lat: ${position.latitude.toStringAsFixed(6)}, Long: ${position.longitude.toStringAsFixed(6)}";

          // HANYA update ketinggian dari GPS JIKA barometer tidak tersedia
          if (!_isBarometerAvailable) {
            _altitudeInfo = "Ketinggian: ${position.altitude.toStringAsFixed(1)} m (GPS)";
          }
        });
      }
    });

    // 3. Stream untuk Arah (dari Kompas) - tidak berubah
    _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      if (mounted && event.heading != null) {
        setState(() {
          _attitudeInfo = "Arah: ${event.heading!.toStringAsFixed(1)}°";
        });
      }
    });
  }

  void _startListeningOrientation() {
    _orientationSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (!mounted) return;
      final double x = event.x;
      final double y = event.y;

      // Logika untuk menentukan orientasi perangkat
      DeviceOrientation newOrientation;
      if (x.abs() > y.abs()) { // Dominan orientasi landscape
        if (x > 5) {
          newOrientation = DeviceOrientation.landscapeLeft;
        } else if (x < -5){
          newOrientation = DeviceOrientation.landscapeRight;
        } else {
          return; // Zona mati, jangan update
        }
      } else { // Dominan orientasi portrait
        if (y < -5) {
          newOrientation = DeviceOrientation.portraitUp;
        } else if (y > 5){
          newOrientation = DeviceOrientation.portraitDown;
        } else {
          return; // Zona mati, jangan update
        }
      }

      if (newOrientation != _deviceOrientation) {
        setState(() {
          _deviceOrientation = newOrientation;
        });
      }
    });
  }

// LETAKKAN 3 FUNGSI INI DI DALAM class _CustomCameraPageState

// 1. Fungsi rotasi yang sudah benar
  int _getQuarterTurns() {
    switch (_deviceOrientation) {
      case DeviceOrientation.landscapeLeft:
        return 1; // 90 derajat searah jarum jam
      case DeviceOrientation.portraitDown:
        return 0; // 0 derajat (terbalik)
      case DeviceOrientation.landscapeRight:
        return 3; // 270 derajat searah jarum jam
      case DeviceOrientation.portraitUp:
      default:
        return 2; // 180 derajat (tegak normal)
    }
  }

// 2. Helper untuk menentukan posisi alignment watermark
  Alignment _getWatermarkAlignment() {
    switch (_deviceOrientation) {
      case DeviceOrientation.landscapeLeft: return Alignment.bottomLeft;
      case DeviceOrientation.landscapeRight: return Alignment.bottomRight;
      case DeviceOrientation.portraitDown: return Alignment.bottomCenter;
      case DeviceOrientation.portraitUp:
      default: return Alignment.topCenter;
    }
  }

// 3. Helper untuk mengecek jika orientasi adalah portrait
  bool _isPortrait() {
    return _deviceOrientation == DeviceOrientation.portraitUp ||
        _deviceOrientation == DeviceOrientation.portraitDown;
  }

  Future<void> _getCurrentLocationForPreview() async {
    // Implementasi tidak berubah
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);

      String address = "Lokasi tidak ditemukan";
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        String kelurahan = place.subLocality ?? '';
        String kabupaten = place.subAdministrativeArea ?? '';
        String kecamatan = place.locality ?? place.administrativeArea ?? '';

        _shortAddress = "$kelurahan, $kecamatan, $kabupaten".replaceAll(RegExp(r'^, |, $'),'');

        address = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country
        ].where((s) => s != null && s.isNotEmpty).join(', ');
      }

      String gpsCoordinates =
          "Lat: ${position.latitude.toStringAsFixed(6)}, Long: ${position.longitude.toStringAsFixed(6)}";

      final String mapboxStyle = 'mapbox/streets-v12';
      final String markerColor = 'ff0000';
      final int zoom = 16;
      final int width = 200;
      final int height = 120;

      final mapUrl =
          'https://api.mapbox.com/styles/v1/$mapboxStyle/static/pin-s+${markerColor}(${position.longitude},${position.latitude})/${position.longitude},${position.latitude},${zoom}/${width}x${height}@2x?access_token=$_mapboxAccessToken';
      debugPrint("Map URL: $mapUrl");

      // final mapUrl =
      //     'https://maps.googleapis.com/maps/api/staticmap?center=${position.latitude},${position.longitude}&zoom=$zoom&size=${width}x$height&maptype=roadmap&markers=color:red%7C${position.latitude},${position.longitude}&key=$_googleMapsApiKey';
      // debugPrint("Google Map URL: $mapUrl");

      if (mounted) {
        setState(() {
          _address = address;
          _gpsCoordinates = gpsCoordinates;
          // _timestamp = timestamp;
          _mapImageUrl = mapUrl;
          // _altitudeInfo = altitudeInfo;
          // _attitudeInfo = attitudeInfo;
        });
      }
    } catch (e) {
      debugPrint("Gagal mendapatkan data lokasi untuk preview: $e");
      if (mounted) {
        setState(() {
          _address = "Gagal mendapatkan lokasi.";
        });
      }
    }
  }

  Future<void> _initializeCamera() async {
    // Implementasi tidak berubah
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      debugPrint("Tidak ada kamera yang ditemukan");
      return;
    }
    _selectedCameraIdx = _cameras!
        .indexWhere((c) => c.lensDirection == CameraLensDirection.back);
    if (_selectedCameraIdx == -1) _selectedCameraIdx = 0;
    _onNewCameraSelected(_cameras![_selectedCameraIdx]);
  }

  void _onNewCameraSelected(CameraDescription cameraDescription) async {
    // Implementasi tidak berubah
    await _controller?.dispose();
    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller!.setFlashMode(FlashMode.off);
    _flashMode = FlashMode.off;
    try {
      await _controller!.initialize();
      if (mounted) setState(() {});
    } on CameraException catch (e) {
      debugPrint("Terjadi eror pada kamera: $e");
    }
  }

  void _switchCamera() { /* Tidak berubah */
    if (_cameras == null || _cameras!.length < 2) return;
    _selectedCameraIdx = (_selectedCameraIdx + 1) % _cameras!.length;
    _onNewCameraSelected(_cameras![_selectedCameraIdx]);
  }

  void _toggleFlash() { /* Tidak berubah */
    if (_controller == null) return;
    setState(() {
      if (_flashMode == FlashMode.off) {
        _flashMode = FlashMode.auto;
        _controller!.setFlashMode(FlashMode.auto);
      } else if (_flashMode == FlashMode.auto) {
        _flashMode = FlashMode.torch;
        _controller!.setFlashMode(FlashMode.torch);
      } else {
        _flashMode = FlashMode.off;
        _controller!.setFlashMode(FlashMode.off);
      }
    });
  }

  IconData _getFlashIcon() { /* Tidak berubah */
    switch (_flashMode) {
      case FlashMode.torch: return Icons.flash_on;
      case FlashMode.auto: return Icons.flash_auto;
      default: return Icons.flash_off;
    }
  }

  int _getRotationAngleFromOrientation(DeviceOrientation orientation) {
    if (orientation == DeviceOrientation.landscapeLeft) {
      // Saat HP miring ke kiri, gambar potret sumber harus diputar 90° searah jarum jam.
      return -90;
    }
    if (orientation == DeviceOrientation.landscapeRight) {
// Saat HP miring ke kiri, gambar potret sumber harus diputar 90° searah jarum jam.
      return 90;
    }
    if (orientation == DeviceOrientation.portraitUp) {
// Saat HP miring ke kiri, gambar potret sumber harus diputar 90° searah jarum jam.
      return 180;
    }
    return 0;
  }

  Future<void> _takeAndProcessPicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) {
      return;
    }
    setState(() => _isProcessing = true);

    try {
      // Menambahkan print untuk memastikan orientasi terdeteksi dengan benar
      debugPrint("Mengambil gambar dengan orientasi: $_deviceOrientation");

      final results = await Future.wait([
        _controller!.takePicture(),
        (_previewContainerKey.currentContext!.findRenderObject() as RenderRepaintBoundary)
            .toImage(pixelRatio: 3.0),
      ]);

      final XFile cameraImageFile = results[0] as XFile;
      final ui.Image screenshotUiImage = results[1] as ui.Image;

      final Uint8List cameraImageBytes = await cameraImageFile.readAsBytes();
      final ByteData? screenshotBytes = await screenshotUiImage.toByteData(format: ui.ImageByteFormat.png);

      final img.Image originalPhotoForExif = img.decodeImage(cameraImageBytes)!;
      img.Image finalVisualImage = img.decodeImage(screenshotBytes!.buffer.asUint8List())!;

      int angle = _getRotationAngleFromOrientation(_deviceOrientation);
      if (angle != 0) {
        finalVisualImage = img.copyRotate(finalVisualImage, angle: angle);
      }

      // Salin data EXIF dari kamera
      finalVisualImage.exif = originalPhotoForExif.exif;

      final List<int> finalImageBytes = img.encodeJpg(finalVisualImage, quality: 95);

      final dir = await getTemporaryDirectory();
      final tempPath = '${dir.path}/final_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = await File(tempPath).create();
      await file.writeAsBytes(finalImageBytes);

      if (mounted) Navigator.pop(context, file);

    } catch (e) {
      debugPrint("Gagal capture dengan metode hybrid: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memproses gambar: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }


// Pastikan fungsi helper ini juga ada di dalam class Anda
  img.Image _centerCrop(img.Image image, int targetWidth, int targetHeight) {
    final imageWidth = image.width;
    final imageHeight = image.height;
    final double imageRatio = imageWidth / imageHeight;
    final double targetRatio = targetWidth / targetHeight;

    int cropWidth, cropHeight, x, y;

    if (imageRatio > targetRatio) {
      cropHeight = imageHeight;
      cropWidth = (imageHeight * targetRatio).round();
      x = (imageWidth - cropWidth) ~/ 2;
      y = 0;
    } else {
      cropWidth = imageWidth;
      cropHeight = (imageWidth / targetRatio).round();
      x = 0;
      y = (imageHeight - cropHeight) ~/ 2;
    }
    return img.copyCrop(image, x: x, y: y, width: cropWidth, height: cropHeight);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return buildCameraUI();
          },
        ),
      ),
    );
  }

  Widget _buildGeolocationOverlay() {
    // Definisikan blok teks agar bisa digunakan kembali

    final combinedSensorInfo = [_altitudeInfo, _attitudeInfo]
        .where((s) => s.isNotEmpty) // Hanya ambil string yang tidak kosong
        .join(', ');

    final bool isPortrait = _isPortrait();
    final double containerOpacity = 0.2;
    final double mapSize = isPortrait ? 92.0 : 80.0; // Peta sedikit lebih kecil di potret & lanskap
    final double mapTextPadding = isPortrait ? 10.0 : 18.0; // Padding lebih besar di lanskap

    final Widget textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Penting!
      children: [
        Text(_shortAddress, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(_address, style: const TextStyle(color: Colors.white, fontSize: 8), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(_gpsCoordinates, style: const TextStyle(color: Colors.white, fontSize: 8)),
        if (combinedSensorInfo.isNotEmpty)
          Text(combinedSensorInfo, style: const TextStyle(color: Colors.white, fontSize: 8)),
        const SizedBox(height: 2),
        Text(_timestamp, style: const TextStyle(color: Colors.white, fontSize: 8)),
        // --- TAMBAHKAN DUA TEXT WIDGET DI SINI ---
      ],
    );

    // Layout ini (Row) akan digunakan untuk semua orientasi untuk memastikan kekompakan
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: mapSize, // Gunakan ukuran peta dinamis
          height: mapSize,
          child: _mapImageUrl != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(_mapImageUrl!, fit: BoxFit.cover),
          )
              : Container(
            decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8.0)),
          ),
        ),
        SizedBox(width: mapTextPadding), // Gunakan padding dinamis
        Flexible(child: textBlock),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(containerOpacity), // Gunakan opacity dinamis
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: content,
    );
  }

  // --- DIMODIFIKASI: Menerapkan RotatedBox ---
// GANTI FUNGSI LAMA ANDA DENGAN YANG INI
  Widget buildCameraUI() {
    final int quarterTurns = _getQuarterTurns();
    final bool isPortrait = _isPortrait();

    return Stack(
      children: [
        // Layer 1: Preview Kamera (dengan rasio 2:3 yang benar)
        Center(
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: ClipRRect(
              child: RepaintBoundary(
                key: _previewContainerKey,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Kamera Preview dengan BoxFit.cover
                    if (_controller != null && _controller!.value.isInitialized)
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller!.value.previewSize!.height,
                          height: _controller!.value.previewSize!.width,
                          child: CameraPreview(_controller!),
                        ),
                      ),

                    // Watermark yang diputar dan diposisikan secara dinamis di dalam area foto
                    Align(
                      alignment: _getWatermarkAlignment(),
                      child: RotatedBox(
                        quarterTurns: quarterTurns,
                        child: Transform.translate(
                          offset: isPortrait ? const Offset(0, 16) : const Offset(0, 17),
                          child: Container(
                            width: isPortrait ? null : MediaQuery.of(context).size.height * 0.6,
                            margin: EdgeInsets.all(isPortrait ? 22.0 : 22.0),
                            // KEMBALIKAN SEPERTI SEMULA, TANPA REPAINTBOUNDARY TAMBAHAN
                            child: _buildGeolocationOverlay(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Layer 2: Tombol Kontrol (yang juga ikut berputar)
        Positioned(
          top: 16, left: 16, right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RotatedBox(
                  quarterTurns: quarterTurns,
                  child: _buildControlButton(icon: _getFlashIcon(), onPressed: _toggleFlash)
              ),
              RotatedBox(
                quarterTurns: quarterTurns,
                child: _buildControlButton(icon: Icons.flip_camera_ios_outlined, onPressed: _switchCamera),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 20, left: 0, right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _takeAndProcessPicture,
              child: Container(
                height: 80, width: 80,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                padding: const EdgeInsets.all(4.0),
                child: Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
              ),
            ),
          ),
        ),

        if (_isProcessing)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
      ],
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 30),
        onPressed: onPressed,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}