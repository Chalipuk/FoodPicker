import CoreML
import UIKit
import Vision

struct FoodGuess {
    var labels: [SeenLabel] = []
    var candidates: [Food] = []
}

// ตอนนี้ใช้ Vision ในเครื่อง (ฟรี ไม่ต้องใช้เน็ต) — ถ้าจะเปลี่ยนไปใช้ AI ที่บอกชื่อเมนูได้ ให้แทนที่ guess(_:among:) หน้าจอไม่ต้องแก้
enum FoodRecognizer {
    static func guess(_ image: UIImage, among foods: [Food]) async throws -> FoodGuess {
        let labels = try await labels(in: image)
        return FoodGuess(labels: labels, candidates: FoodMatcher.rank(labels, among: foods))
    }

    private static func labels(in image: UIImage) async throws -> [SeenLabel] {
        guard let cgImage = image.cgImage else { return [] }
        var request = ClassifyImageRequest()
        #if targetEnvironment(simulator)
        // Simulator ไม่มี GPU/Neural Engine ให้ Vision ("Failed to create espresso context") — บังคับใช้ CPU
        if let cpu = MLComputeDevice.allComputeDevices.first(where: { if case .cpu = $0 { true } else { false } }) {
            request.setComputeDevice(cpu, for: .main)
        }
        #endif
        let observations = try await request
            .perform(on: cgImage, orientation: CGImagePropertyOrientation(image.imageOrientation))
        return observations
            .filter { $0.confidence >= 0.05 }
            .sorted { $0.confidence > $1.confidence }
            .prefix(10)
            .map { SeenLabel(name: $0.identifier, confidence: $0.confidence) }
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
