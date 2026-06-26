/// The order of the image samples.
/// 
/// [sequential] Images are in sequential order.
/// 
/// [unordered] Images aren’t in sequential order.
enum SampleOrdering{
  sequential,
  unordered
}

/// The precision of landmark detection.
/// 
/// [high] The session uses the detail algorithm to detect landmarks.
/// 
/// [normal] The session uses the default algorithm to detect landmarks.
enum FeatureSensitivity{normal,high}

/// Quality of the model created.
/// 
///  [full] A high-quality object with significant resource requirements.
/// 
/// [preview] A fast, low-quality object for previewing the final result.
/// 
/// [medium] A medium-quality object with moderate resource requirements.
/// 
/// [raw] The raw-created object at the highest possible resolution.
/// 
/// [reduced] A mobile-quality object with low resource requirements.
enum PhotogrammetryQuality{
  full, //<250k triangles
  preview, //<25k triangles
  medium, //<100k triangles
  raw, //<30M triangles
  reduced //<50k triangles
}

enum PhotogrammetryFormat{
  obj,
  usda,
  usdz
}

/// The data need to create the 3D model.
/// 
/// [enableMask] A Boolean value that indicates whether the session uses object masks.
/// 
/// [quality]  The quality of the model created.
/// 
/// [sensitivity] The precision of landmark detection.
/// 
/// [path] The path of the image samples.
/// 
/// [name] The name of the output file.
/// 
/// [ordering] The order of the image samples.
class PhotogrammetryData{
  PhotogrammetryData({
    this.enableMask = true,
    this.quality = PhotogrammetryQuality.full,
    this.sensitivity = FeatureSensitivity.normal,
    required this.path,
    this.name = 'MyObject',
    this.ordering = SampleOrdering.unordered,
    this.format = PhotogrammetryFormat.usdz
  });

  String path;
  String name;
  PhotogrammetryQuality quality;
  FeatureSensitivity sensitivity;
  SampleOrdering ordering;
  bool enableMask;
  PhotogrammetryFormat format;

  @override
  String toString(){
    return map.toString();
  }

  Map<String,dynamic> get map => {
    'sensitivity': sensitivity.name,
    'quality': quality.name,
    'enableMask': enableMask,
    'ordering': ordering.name,
    'name': name,
    'path': path,
    'format': format.name
  };
}

/// The data for the where the images were caputred in 3d space.
/// 
/// [photoId] A string of the photos name.
/// 
/// [transformMatrix]  The 4x4 matrix of the position, and rotation
class CameraPoseData {
  final String photoId; // Key name mapping to the source photo
  final List<double> transformMatrix; // Flat array of 16 entries (4x4 matrix)

  CameraPoseData({required this.photoId, required this.transformMatrix});

  /// Helper getter to extract the raw X, Y, Z spatial translation coordinates 
  /// directly from the final column of the 4x4 transformation matrix.
  List<double> get translation3D => [
    transformMatrix[12], // X-axis coordinate
    transformMatrix[13], // Y-axis coordinate
    transformMatrix[14], // Z-axis coordinate
  ];

  Map<String,dynamic> get map => {
    'id': photoId,
    'transform': transformMatrix,
  };
}