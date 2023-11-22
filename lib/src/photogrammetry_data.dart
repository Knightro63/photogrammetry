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
    this.ordering = SampleOrdering.unordered
  });

  String path;
  String name;
  PhotogrammetryQuality quality;
  FeatureSensitivity sensitivity;
  SampleOrdering ordering;
  bool enableMask;

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
    'path': path
  };
}