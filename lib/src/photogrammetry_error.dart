/// Error codes from 
enum PhotogrammetryErrorCode {
  controllerUninitialized,
  genericError,
}

class PhotogrammetryException implements Exception {
  const PhotogrammetryException({
    required this.errorCode,
    this.errorDetails,
  });

  /// The error code of the exception.
  final PhotogrammetryErrorCode errorCode;

  /// The additional error details that came with the [errorCode].
  final PhotogrammetryErrorDetails? errorDetails;

  @override
  String toString() {
    if (errorDetails != null && errorDetails?.message != null) {
      return "AppleVisionException: code ${errorCode.name}, message: ${errorDetails?.message}";
    }
    return "AppleVisionException: ${errorCode.name}";
  }
}

/// The raw error details for a [AppleVisionException].
/// 
/// [code] The error code thrown
/// [details] The details of the message
/// [message] The error message
class PhotogrammetryErrorDetails {
  const PhotogrammetryErrorDetails({
    this.code,
    this.details,
    this.message,
  });

  /// The error code from the [PlatformException].
  final String? code;

  /// The details from the [PlatformException].
  final Object? details;

  /// The error message from the [PlatformException].
  final String? message;
}