import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

// C function signatures
typedef _version_func = ffi.Pointer<Utf8> Function();
typedef _process_image_func = ffi.Void Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);
typedef _align_images_func = ffi.Void Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);
typedef _extract_roi_img_func = ffi.Void Function(ffi.Pointer<Utf8>, ffi.Int32,
    ffi.Int32, ffi.Int32, ffi.Int32, ffi.Pointer<Utf8>);
// Dart function signatures
typedef _VersionFunc = ffi.Pointer<Utf8> Function();
typedef _ProcessImageFunc = void Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);
typedef _AlignImageFunc = void Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);
typedef _ExtractROIImageFunc = void Function(
    ffi.Pointer<Utf8>, int, int, int, int, ffi.Pointer<Utf8>);
// Getting a library that holds needed symbols
ffi.DynamicLibrary _lib = Platform.isAndroid
    ? ffi.DynamicLibrary.open('libnative_opencv.so')
    : ffi.DynamicLibrary.process();

// Looking for the functions
final _VersionFunc _version =
    _lib.lookup<ffi.NativeFunction<_version_func>>('version').asFunction();
final _ProcessImageFunc _processImage = _lib
    .lookup<ffi.NativeFunction<_process_image_func>>('process_image')
    .asFunction();
final _AlignImageFunc _alignImages = _lib
    .lookup<ffi.NativeFunction<_align_images_func>>('align_images')
    .asFunction();
final _ExtractROIImageFunc _extractROIImg = _lib
    .lookup<ffi.NativeFunction<_extract_roi_img_func>>('extract_roi_img')
    .asFunction();

String opencvVersion() {
  return Utf8.fromUtf8(_version());
}

void processImage(ProcessImageArguments args) {
  _processImage(Utf8.toUtf8(args.inputPath), Utf8.toUtf8(args.outputPath));
}

void alignImages(ImageAlignmentArguments args) {
  _alignImages(Utf8.toUtf8(args.imagePath), Utf8.toUtf8(args.templatePath),
      Utf8.toUtf8(args.outputPath));
}

void extractROIImage(ROIArguments args) {
  _extractROIImg(Utf8.toUtf8(args.imagePath), args.x, args.y, args.width,
      args.height, Utf8.toUtf8(args.outputPath));
}

class ROIArguments {
  final String imagePath;
  final String outputPath;
  final int x;
  final int y;
  final int width;
  final int height;

  ROIArguments(
      {this.imagePath,
      this.outputPath,
      this.x,
      this.y,
      this.width,
      this.height});
}

class ProcessImageArguments {
  final String inputPath;
  final String outputPath;

  ProcessImageArguments(this.inputPath, this.outputPath);
}

class ImageAlignmentArguments {
  final String imagePath;
  final String templatePath;
  final String outputPath;
  ImageAlignmentArguments(this.imagePath, this.templatePath, this.outputPath);
}
