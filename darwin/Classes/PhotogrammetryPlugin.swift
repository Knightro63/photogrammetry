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
        registrar.addMethodCallDelegate(instance, channel: method)
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
                    process(arguments,result)
                } else {
                    result(FlutterError(code: "INVALID OS", message: "requires version 17.0", details: nil))
                    return
                }
            #elseif os(macOS)
                process(arguments,result)
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
        let path:String = arguments["path"] as! String
        if #available(macOS 13.0, *) {
            guard PhotogrammetrySession.isSupported else {
                result(FlutterError(code: "ERROR", message: "Photogrammetry not supported.", details: nil))
                return
            }
        } else {
            // Fallback on earlier versions
        }

        let inputFolderUrl = URL(fileURLWithPath: path)//"/tmp/MyInputImages/"
        let fileName = path+"/"+(arguments["name"] as! String)+".usdz"
        let url = URL(fileURLWithPath: fileName)
        
        var quality:PhotogrammetrySession.Request.Detail = PhotogrammetrySession.Request.Detail.full
        switch arguments["quality"] as! String{
            case "reduced":
                quality = PhotogrammetrySession.Request.Detail.reduced
                break
            case "medium":
                quality = PhotogrammetrySession.Request.Detail.medium
                break
            case "preview":
                quality = PhotogrammetrySession.Request.Detail.preview
                break
            case "raw":
                quality = PhotogrammetrySession.Request.Detail.raw
                break
            default:
                quality = PhotogrammetrySession.Request.Detail.full
                break
        }
        
        let request = PhotogrammetrySession.Request.modelFile(url: url, detail: quality)

        var featureSensitivity:PhotogrammetrySession.Configuration.FeatureSensitivity = PhotogrammetrySession.Configuration.FeatureSensitivity.normal
        switch arguments["sensitivity"] as! String{
            case "high":
                featureSensitivity = PhotogrammetrySession.Configuration.FeatureSensitivity.high
                break
            default:
                featureSensitivity = PhotogrammetrySession.Configuration.FeatureSensitivity.normal
                break
        }
        var sampleOrdering:PhotogrammetrySession.Configuration.SampleOrdering = PhotogrammetrySession.Configuration.SampleOrdering.sequential
        switch arguments["ordering"] as! String{
            case "sequential":
                sampleOrdering = PhotogrammetrySession.Configuration.SampleOrdering.sequential
                break
            default:
            sampleOrdering = PhotogrammetrySession.Configuration.SampleOrdering.unordered
                break
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
                                "onError": error
                            ])
                            // Request encountered an error.
                            break
                    case .requestComplete(_, _):
                            self.sink([
                                "onProcessingCompleted": fileName
                            ])
                            // RealityKit has finished processing a request.
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
            try session!.process(requests: [ request ])
        } catch {
            result(FlutterError(code: "Error", message: "Error while processing moddle.", details: nil))
        }
    }
}
