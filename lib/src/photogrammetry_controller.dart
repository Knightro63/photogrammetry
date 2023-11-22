
import 'dart:async';
import 'package:flutter/services.dart';
import 'photogrammetry_data.dart';
import 'photogrammetry_error.dart';

class Photogrammetry {
  static const MethodChannel _methodChannel = MethodChannel('photogrammetry/channel');
  static const EventChannel _eventChannel = EventChannel('photogrammetry/stream');
  StreamSubscription? events;

  /// Process the image using apple vision and return the requested information or null value
  /// 
  /// [pgData] The data need to create the 3D model.
  /// 
  /// [onSkipped] returns the id of the skipped image
  /// 
  /// [onDownsampling] Indicates a sample image has reduced landmarks
  /// 
  /// [onCanceled] The process has been aborted
  /// 
  /// [onInvalidSample] The sample image has no landmarks in common
  /// return the id of the sample image
  /// 
  /// [onStartedProcessing] All the landmarks in the image samples have been found
  /// 
  /// [onProcessingCompleted] The process of creating the model has completed
  /// returns the path of the created model
  ///  
  /// [onProgressChanged] Periodic progress update.
  /// 
  /// [onComplete] All process fror this program have completed
  Future<String?> process({
    required PhotogrammetryData pgData,
    Function(int sample)? onSkipped,
    void Function()? onDownsampling,
    void Function()? onCanceled,
    Function(int sample, String reason)? onInvalidSample,
    void Function()? onStartedProcessing,
    Function(String path)? onProcessingCompleted,
    Function(double progress)? onProgressChanged,
    Function()? onComplete,
    Function(String path,int,int,String)? onError
  }) async{
    events = _eventChannel.receiveBroadcastStream().listen((data) {
      data as Map;
      for (final key in data.keys) {
        switch (key) {
          case 'onSkipped':
            onSkipped?.call(data[key] as int);
            break;
          case 'onDownsampling':
            onDownsampling?.call();
            break;
          case 'onCanceled':
            onCanceled?.call();
            break;
          case 'onInvalidSample':
            final Map<String, dynamic> result = Map<String, dynamic>.from(data[key] as Map);
            onInvalidSample?.call(result['id'] as int, result['reason'] as String);
            break;
          case 'onStartedProcessing':
            onStartedProcessing?.call();
            break;
          case 'onProcessingCompleted':
            onProcessingCompleted?.call(data[key] as String);
            break;
          case 'onProgressChanged':
            onProgressChanged?.call(data[key] as double);
            break;
          case 'onComplete':
            onComplete?.call();
            events?.cancel();
            break;
          case 'onError':
            final Map<String, dynamic> result = Map<String, dynamic>.from(data[key] as Map);
            onError?.call(
              result['deviceAddress'] as String,
              result['error'] as int,
              result['errorType'] as int,
              result['message'] as String,
            );
            events?.cancel();
            break;
        }
      }
    });

    return _convertData(
      await _methodChannel.invokeMapMethod<String, dynamic>(  
        'process',
        pgData.map,
      )
    );
  }

  /// Abort making the model
  Future<String?> abort() async {
    String temp = await _methodChannel.invokeMethod('abort');
    events?.cancel();
    return temp;
  }

  /// Dispose of the stream event
  void dispose(){
    events?.cancel();
  }

  /// Handles a returning event from the platform side
  String? _convertData(Map? event) {
    if(event == null) return null;
    final name = event['name'];
    
    switch (name) {
      case 'path':
        return event['pathToFile'];
      case 'noData':
        break;
      case 'done':
        break;
      case 'error':
        throw PhotogrammetryException(
          errorCode: PhotogrammetryErrorCode.genericError,
          errorDetails: PhotogrammetryErrorDetails(message: event['message'] as String?),
        );
      default:
        throw UnimplementedError(name as String?);
    }

    return null;
  }
}