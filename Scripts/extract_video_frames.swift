import AVFoundation
import AppKit
import Foundation

struct VideoInfo {
    let durationSeconds: Double
    let width: Int
    let height: Int
    let nominalFPS: Float
}

enum ExtractorError: Error {
    case usage
    case missingTrack
    case failedToCreateCGImage
}

func loadVideoInfo(asset: AVAsset) async throws -> VideoInfo {
    let duration = try await asset.load(.duration)
    guard let track = try await asset.loadTracks(withMediaType: .video).first else {
        throw ExtractorError.missingTrack
    }

    let size = try await track.load(.naturalSize)
    let transform = try await track.load(.preferredTransform)
    let transformed = CGRect(origin: .zero, size: size).applying(transform)
    let fps = try await track.load(.nominalFrameRate)

    return VideoInfo(
        durationSeconds: duration.seconds,
        width: Int(abs(transformed.width).rounded()),
        height: Int(abs(transformed.height).rounded()),
        nominalFPS: fps
    )
}

func pngData(from image: CGImage) -> Data? {
    let bitmap = NSBitmapImageRep(cgImage: image)
    return bitmap.representation(using: .png, properties: [:])
}

@main
struct Main {
    static func main() async throws {
        let arguments = CommandLine.arguments
        guard arguments.count >= 3 else {
            throw ExtractorError.usage
        }

        let videoURL = URL(fileURLWithPath: arguments[1])
        let outputURL = URL(fileURLWithPath: arguments[2], isDirectory: true)
        let frameCount = arguments.count >= 4 ? max(1, Int(arguments[3]) ?? 6) : 6

        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        let asset = AVURLAsset(url: videoURL)
        let info = try await loadVideoInfo(asset: asset)

        print("duration=\(String(format: "%.3f", info.durationSeconds))")
        print("width=\(info.width)")
        print("height=\(info.height)")
        print("fps=\(String(format: "%.3f", info.nominalFPS))")

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 960, height: 960)
        generator.requestedTimeToleranceAfter = .zero
        generator.requestedTimeToleranceBefore = .zero

        let safeDuration = max(info.durationSeconds, 0.1)
        let times: [CMTime] = (0..<frameCount).map { index in
            let progress = frameCount == 1 ? 0.5 : Double(index + 1) / Double(frameCount + 1)
            return CMTime(seconds: safeDuration * progress, preferredTimescale: 600)
        }

        for (index, time) in times.enumerated() {
            let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
            guard let data = pngData(from: cgImage) else {
                throw ExtractorError.failedToCreateCGImage
            }
            let frameURL = outputURL.appendingPathComponent(String(format: "frame-%03d.png", index + 1))
            try data.write(to: frameURL, options: .atomic)
            print("frame=\(frameURL.path)")
        }
    }
}
