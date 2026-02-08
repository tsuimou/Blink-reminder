import AVFoundation

enum CameraUsageMonitor {
    static func isCameraInUse() -> Bool {
        guard let device = AVCaptureDevice.default(for: .video) else {
            return false
        }
        return device.isInUseByAnotherApplication
    }
}
