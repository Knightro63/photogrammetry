#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif
import RealityKit

public class PhotogrammetryPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

  let registry: FlutterTextureRegistry
  var sink: FlutterEventSink!
  var session:PhotogrammetrySession?
  
  init(_ registry: FlutterTextureRegistry) {
    self.registry = registry
    super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(iOS)
    let method = FlutterMethodChannel(name:"photogrammetry/channel", binaryMessenger: registrar.messenger())
    let instance = PhotogrammetryPlugin(registrar.textures())

    let event = FlutterEventChannel(name:"photogrammetry/stream", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: method)
    event.setStreamHandler(instance)
    #elseif os(macOS)
    let method = FlutterMethodChannel(name:"photogrammetry/channel", binaryMessenger: registrar.messenger)
    let instance = PhotogrammetryPlugin(registrar.textures)
    
    let event = FlutterEventChannel(name:"photogrammetry/stream", binaryMessenger: registrar.messenger)
    registrar.addMethodCallDelegate(instance, channel: method)
    event.setStreamHandler(instance)
    #endif
  }
  
  // FlutterStreamHandler
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    return nil
  }
    
  // FlutterStreamHandler
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }
    
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "process":
        guard let arguments = call.arguments as? Dictionary<String, Any>
        else {
          result(FlutterError(code: "INVALID_ARGS", message: "", details: nil))
          return
        }
        #if os(iOS)
          if #available(iOS 17.0, *) {
            guard PhotogrammetrySession.isSupported else {
              result(FlutterError(code: "UNSUPPORTED_HARDWARE", message: "Device lacks Photogrammetry support.", details: nil))
              return
            }
            process(arguments, result)
          } else {
            result(FlutterError(code: "INVALID OS", message: "requires version 17.0", details: nil))
            return
          }
        #elseif os(macOS)
          process(arguments,result)
        #endif
        return
    case "isSupported":
      #if os(iOS)
      if #available(iOS 17.0, *) {
        result(PhotogrammetrySession.isSupported)
      } else {
        result(false) // API does not exist prior to iOS 17
      }
      #elseif os(macOS)
      if #available(macOS 13.0, *) {
        result(PhotogrammetrySession.isSupported)
      } else {
        result(false) // API does not exist prior to macOS 12
      }
      #endif
      return
    case "abort":
      session?.cancel()
      return
    default:
      return result(FlutterMethodNotImplemented)
    }
  }
    
  // Gets called when a new image is added to the buffer
  #if os(iOS)
  @available(iOS 17.0, *)
  #endif
  func process(_ arguments: Dictionary<String, Any>, _ result: @escaping FlutterResult){
    if let activeSession = self.session {
      print("Stopping old background allocations before continuing...")
      activeSession.cancel()
      self.session = nil
    }

    let path:String = arguments["path"] as! String
    if #available(macOS 13.0, *) {
      guard PhotogrammetrySession.isSupported else {
        result(FlutterError(code: "ERROR", message: "Photogrammetry not supported.", details: nil))
        return
      }
    }

    let inputFolderUrl = URL(fileURLWithPath: path)//"/tmp/MyInputImages/"
    let formatStr = (arguments["format"] as? String ?? "usdz").lowercased()
    let nameStr = arguments["name"] as! String
    let outputUrl: URL
    let completedPathMarker: String
    let fileManager = FileManager.default
    
    if formatStr == "obj" {
      // OBJ output requires a directory path instead of a file file path. 
      // RealityKit will generate 'mesh.obj', 'mesh.mtl', and image files inside this directory.
      let objDirectoryPath = path + "/" + nameStr + "_obj"
      outputUrl = URL(fileURLWithPath: objDirectoryPath, isDirectory: true)
      completedPathMarker = objDirectoryPath
      
      if fileManager.fileExists(atPath: objDirectoryPath) {
        try? fileManager.removeItem(atPath: objDirectoryPath)
      }
      
      // Safely recreate the empty structure directory
      try? fileManager.createDirectory(at: outputUrl, withIntermediateDirectories: true, attributes: nil)
    }else {
      let extensionStr = (formatStr == "usda") ? ".usda" : ".usdz"
      let fileAssetPath = path + "/" + nameStr + extensionStr
      outputUrl = URL(fileURLWithPath: fileAssetPath)
      completedPathMarker = fileAssetPath
      
      // 🛠️ FIX: If the output 3D asset file already exists, erase it first
      if fileManager.fileExists(atPath: fileAssetPath) {
        try? fileManager.removeItem(atPath: fileAssetPath)
      }
    }

    // let fileName = path+"/"+(arguments["name"] as! String)+".usdz"
    // let url = URL(fileURLWithPath: fileName)
    
    var quality: PhotogrammetrySession.Request.Detail = .reduced
    
    #if os(macOS)
    quality = .full
    switch arguments["quality"] as! String {
      case "reduced": quality = .reduced
      case "medium": quality = .medium
      case "preview": quality = .preview
      case "raw": quality = .raw
      default: quality = .full
    }
    #endif
      
    let modelRequest = PhotogrammetrySession.Request.modelFile(url: outputUrl, detail: quality)
    var posesRequest: PhotogrammetrySession.Request? = nil
    if #available(macOS 14.0, *) {
      posesRequest = PhotogrammetrySession.Request.poses
    }

    var featureSensitivity: PhotogrammetrySession.Configuration.FeatureSensitivity = .normal
    switch arguments["sensitivity"] as! String {
      case "high": featureSensitivity = .high
      default: featureSensitivity = .normal
    }

    var sampleOrdering: PhotogrammetrySession.Configuration.SampleOrdering = .sequential
      switch arguments["ordering"] as! String {
      case "sequential": sampleOrdering = .sequential
      default: sampleOrdering = .unordered
    }
    
    let enableMask:Bool = arguments["enableMask"] as? Bool ?? true
    var config = PhotogrammetrySession.Configuration()
    // Use slower, more sensitive landmark detection.
    config.featureSensitivity = featureSensitivity
    // Adjacent images are next to each other.
    config.sampleOrdering = sampleOrdering
    // Object masking is enabled.
    config.isObjectMaskingEnabled = enableMask

    // Try to create the session, or else exit.
    var maybeSession: PhotogrammetrySession? = nil
    do {
      maybeSession = try PhotogrammetrySession(input: inputFolderUrl,configuration: config)
    } catch {
      result(FlutterError(code: "Error", message: "Error while creating session.", details: nil))
    }
    self.session = maybeSession
    
    if self.session ==  nil{
      result(FlutterError(code: "Error", message: "Unable to create session.", details: nil))
      return
    }
    
    let _ = Task.init {
      do {
        for try await output in session!.outputs {
          switch output {
            case .processingComplete:
              // RealityKit has processed all requests.
              self.sink([
                  "onComplete": ""
              ])
              return
            case .requestError(_, let error):
              self.sink([
                "onError": [
                  "deviceAddress": "Photogrammetry",
                  "error": 0,
                  "errorType": 0,
                  "message": error.localizedDescription
                ]
              ])
              // Request encountered an error.
              break
          case .requestComplete(let request, let result):
            if case .poses = request {
              // 2. Safely unpack the calculated camera poses array
              if case .poses(let posesContainer) = result {
                var serializedPoses: [[String: Any]] = []
                
                for (sampleId, pose) in posesContainer.posesBySample {
                    let transformMatrix = pose.transform // simd_float4x4 matrix
                    let matrixList = matrixToArray(transformMatrix)
                    
                    // 3. (Optional) Check if Apple mapped the source file URL to match the sample index
                    let fileUrlString = posesContainer.urlsBySample[sampleId]?.lastPathComponent ?? "sample_\(sampleId)"
                    
                    serializedPoses.append([
                        "id": fileUrlString, // Descriptive string identification (e.g., "IMG_0123.HEIC")
                        "sampleIndex": sampleId, // Integer index
                        "transform": matrixList // 16 float elements mapping the 4x4 coordinate space
                    ])
                }
                
                // Send the position tracking matrix array to Dart
                self.sink([ "onCameraPosesCalculated": serializedPoses ])
              }
            } 
            else {
              // Handle your existing model file request completion
              self.sink([ "onProcessingCompleted": completedPathMarker ])
            }
            break
          case .requestProgress(_, let fractionComplete):
            self.sink([
                "onProgressChanged": fractionComplete
            ])
            // Periodic progress update. Update UI here.
            break
          case .inputComplete:
            self.sink([
                "onStartedProcessing": ""
            ])
            // Ingestion of images is complete and processing begins.
            break
          case .invalidSample(let id, let reason):
            self.sink([
                "onInvalidSample": [
                    "id": id,
                    "reason":reason
                ] as [String : Any]
            ])
            // RealityKit deemed a sample invalid and didn't use it.
            break
          case .skippedSample(let id):
            self.sink([
                "onSkipped": id
            ])
            // RealityKit was unable to use a provided sample.
            break
          case .automaticDownsampling:
            self.sink([
                "onDownsampling": ""
            ])
            // RealityKit downsampled the input images because of
            // resource constraints.
            break
          case .processingCancelled:
            self.sink([
                "onCanceled": ""
            ])
            // Processing was canceled.
            break
          case .requestProgressInfo(_, _):
              break
          case .stitchingIncomplete:
              break
          @unknown default:
            // Unrecognized output.
            break
          }
        }
      }
      catch {
        result(FlutterError(code: "Error", message: "Unable to create model.", details: nil))
      }
    }
      
    do {
      if #available(macOS 14.0, *) {
        try session!.process(requests: [ modelRequest, posesRequest! ])
      }
      else{
        try session!.process(requests: [ modelRequest ])
      }
    } catch {
      result(FlutterError(code: "Error", message: "Error while processing moddle.", details: nil))
    }
  }

  private func matrixToArray(_ rawMatrix: Transform) -> [Float] {
    let matrix = rawMatrix.matrix
      
    return [
      matrix.columns.0.x, matrix.columns.0.y, matrix.columns.0.z, matrix.columns.0.w,
      matrix.columns.1.x, matrix.columns.1.y, matrix.columns.1.z, matrix.columns.1.w,
      matrix.columns.2.x, matrix.columns.2.y, matrix.columns.2.z, matrix.columns.2.w,
      matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z, matrix.columns.3.w
    ]
  }
}
