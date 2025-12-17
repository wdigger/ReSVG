// The Swift Programming Language
// https://docs.swift.org/swift-book

import resvgWrapper
import Foundation
import UIKit

public class SVGImage {
    public struct Transform {
        public let sx: CGFloat  // scale x
        public let sy: CGFloat  // scale y
        public let kx: CGFloat  // skew x
        public let ky: CGFloat  // skew y
        public let tx: CGFloat  // translate x
        public let ty: CGFloat  // translate y
        
        public init(sx: CGFloat, sy: CGFloat,
                    kx: CGFloat, ky: CGFloat,
                    tx: CGFloat, ty: CGFloat) {
            self.sx = sx
            self.sy = sy
            self.kx = kx
            self.ky = ky
            self.tx = tx
            self.ty = ty
        }
        
        public static func scale(_ x: CGFloat, _ y: CGFloat) -> Transform {
            Transform(sx: x, sy: y, kx: 0, ky: 0, tx: 0, ty: 0)
        }
        
        public static func translate(_ x: CGFloat, _ y: CGFloat) -> Transform {
            Transform(sx: 1, sy: 1, kx: 0, ky: 0, tx: x, ty: y)
        }
    }
    
    let tree: UnsafeMutablePointer<OpaquePointer?>
    
    public init?(_ data: Data) {
        tree = .allocate(capacity: 1)
        let options = resvg_options_create()
        let result = data.withUnsafeBytes { unsafeBytes in
            let bytes = unsafeBytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
            return resvg_parse_tree_from_data(bytes, UInt(unsafeBytes.count), options, tree)
        }
        resvg_options_destroy(options)
        if result != RESVG_OK.rawValue {
            return nil
        }
    }
    
    deinit {
        if let tree = tree.pointee {
            resvg_tree_destroy(tree)
        }
        tree.deallocate()
    }
    
    public var size: CGSize {
        let size = resvg_get_image_size(tree.pointee)
        return CGSize(width: Double(size.width), height: Double(size.height))
    }
    
    public func render(size: CGSize? = nil) -> CGImage? {
        var trans = resvg_transform_identity()
        let svgSize = self.size
        
        var width: Int = 0
        var height: Int = 0
        if let size = size {
            width = Int(size.width)
            height = Int(size.height)
        } else {
            width = Int(svgSize.width)
            height = Int(svgSize.height)
        }
        
        trans.a = Float(CGFloat(width) / svgSize.width)
        trans.d = Float(CGFloat(height) / svgSize.height)
        
        var pixelData = Data(count: width * height * 4)
        pixelData.withUnsafeMutableBytes { (bytes: UnsafeMutableRawBufferPointer) in
            let pixels = bytes.assumingMemoryBound(to: CChar.self)
            resvg_render(tree.pointee, trans, UInt32(width), UInt32(height), pixels.baseAddress)
        }
        
        let bitsPerComponent = 8
        let bitsPerPixel = 32 // RGBA8888
        let bytesPerRow = width * (bitsPerPixel / bitsPerComponent)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue |
                                                CGBitmapInfo.byteOrder32Big.rawValue)
        
        guard let provider = CGDataProvider(data: pixelData as CFData) else { return nil }
        
        return CGImage(width: width,
                       height: height,
                       bitsPerComponent: bitsPerComponent,
                       bitsPerPixel: bitsPerPixel,
                       bytesPerRow: bytesPerRow,
                       space: colorSpace,
                       bitmapInfo: bitmapInfo,
                       provider: provider,
                       decode: nil,
                       shouldInterpolate: true,
                       intent: .defaultIntent)
    }
    
    func render(to context: CGContext) {
        guard let pixels = context.data else { return }
        
        let svgSize = self.size
        
        let width = context.width
        let height = context.height
        
        var transform = resvg_transform_identity()
        transform.a = Float(width) / Float(svgSize.width)
        transform.d = Float(height) / Float(svgSize.height)
        
        resvg_render(tree.pointee, transform, UInt32(width), UInt32(height), pixels)
    }
}
