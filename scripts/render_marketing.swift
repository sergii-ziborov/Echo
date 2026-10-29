import AppKit
import Foundation
import ImageIO

let args = CommandLine.arguments
let input = URL(fileURLWithPath: args[1])
let pages = try JSONSerialization.jsonObject(with: Data(contentsOf: input)) as! [[String: Any]]
for p in pages {
    let width = p["width"] as! Int, height = p["height"] as! Int
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let cg = NSGraphicsContext.current!.cgContext
    cg.translateBy(x: 0, y: CGFloat(height)); cg.scaleBy(x: 1, y: -1)
    func color(_ hex: String) -> NSColor {
        let v = UInt32(hex, radix: 16) ?? 0
        return NSColor(red: CGFloat((v >> 16) & 255)/255, green: CGFloat((v >> 8)&255)/255, blue: CGFloat(v&255)/255, alpha: 1)
    }
    color(p["background"] as? String ?? "061020").setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height)).fill()
    for item in p["items"] as! [[String: Any]] {
        let x = item["x"] as! Double, y = item["y"] as! Double, w = item["w"] as! Double, h = item["h"] as! Double
        let rect = NSRect(x: x, y: y, width: w, height: h)
        if let path = item["image"] as? String, let image = NSImage(contentsOfFile: path) {
            NSGraphicsContext.saveGraphicsState()
            if let radius = item["radius"] as? Double { NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).addClip() }
            cg.translateBy(x: rect.minX, y: rect.maxY); cg.scaleBy(x: 1, y: -1)
            image.draw(in: NSRect(x: 0, y: 0, width: w, height: h), from: .zero, operation: .sourceOver, fraction: 1)
            NSGraphicsContext.restoreGraphicsState()
        } else if let text = item["text"] as? String {
            let size = item["size"] as! Double
            let bold = item["bold"] as? Bool ?? false
            let font = NSFont(name: bold ? "AvenirNext-DemiBold" : "AvenirNext-Regular", size: size) ?? NSFont.systemFont(ofSize: size, weight: bold ? .semibold : .regular)
            let para = NSMutableParagraphStyle(); para.lineSpacing = size * 0.15
            if item["align"] as? String == "center" { para.alignment = .center }
            let attr: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color(item["color"] as? String ?? "F1F5FA"), .paragraphStyle: para]
            NSGraphicsContext.saveGraphicsState(); cg.translateBy(x: 0,y: CGFloat(height));cg.scaleBy(x: 1,y: -1)
            NSAttributedString(string: text, attributes: attr).draw(with: NSRect(x: x, y: Double(height)-y-h, width: w, height: h), options: [.usesLineFragmentOrigin,.usesFontLeading])
            NSGraphicsContext.restoreGraphicsState()
        } else {
            color(item["fill"] as? String ?? "12213B").setFill()
            NSBezierPath(roundedRect: rect, xRadius: item["radius"] as? Double ?? 0, yRadius: item["radius"] as? Double ?? 0).fill()
        }
    }
    NSGraphicsContext.restoreGraphicsState()
    let output = URL(fileURLWithPath: p["output"] as! String)
    try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
    let flat = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    flat.draw(rep.cgImage!, in: CGRect(x: 0, y: 0, width: width, height: height))
    let destination = CGImageDestinationCreateWithURL(output as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, flat.makeImage()!, nil)
    guard CGImageDestinationFinalize(destination) else { fatalError("PNG export failed") }
    print(output.path)
}
