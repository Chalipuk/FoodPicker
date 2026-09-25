import UIKit
import CoreImage.CIFilterBuiltins

enum ProfileLink {
    static let scheme = "foodpicker"

    static func url(for diner: Diner) -> URL? {
        guard let data = try? JSONEncoder().encode(diner) else { return nil }
        var components = URLComponents()
        components.scheme = scheme
        components.host = "profile"
        components.queryItems = [URLQueryItem(name: "d", value: base64URL(data))]
        return components.url
    }

    static func diner(from url: URL) -> Diner? {
        guard url.scheme == scheme, url.host == "profile",
              let value = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "d" })?.value,
              let data = data(fromBase64URL: value) else { return nil }
        return try? JSONDecoder().decode(Diner.self, from: data)
    }

    static func diner(fromText text: String) -> Diner? {
        guard let range = text.range(of: "\(scheme)://profile?d=[A-Za-z0-9_-]+", options: .regularExpression),
              let url = URL(string: String(text[range])) else { return nil }
        return diner(from: url)
    }

    static func qrImage(for url: URL) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(url.absoluteString.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 12, y: 12)),
              let cgImage = CIContext().createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private static func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func data(fromBase64URL value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        return Data(base64Encoded: base64)
    }
}
