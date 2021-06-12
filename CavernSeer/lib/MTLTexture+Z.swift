//
//    MTLTexture+Z.swift
//    CavernSeer
//
//    Combo of work by:
//      * [MIT] [Electricwoods LLC, Kaz Yoshikawa](https://gist.github.com/codelynx/4e56758fb89e94d0d1a58b40ddaade45)
//      * [CC BY-SA 4.0] [warrenm](https://stackoverflow.com/a/51866740)
//
// My combo doesn't quite seem to work...
//


import Foundation
import CoreGraphics
import MetalKit
import Accelerate



extension MTLTexture {

    #if os(iOS)
    typealias XImage = UIImage
    #elseif os(macOS)
    typealias XImage = NSImage
    #endif

    var cgImage: CGImage? {
        /// original code assumed `.bgra8Unorm`, but this is `.rgba16Float`

//        let fmt = self.pixelFormat
//        let width = self.width
//        let height = self.height
//
//        let depth = self.depth
//        let levels = self.mipmapLevelCount
//        let samples = self.sampleCount
//        let textureType = self.textureType
//        let usage = self.usage

        assert(self.pixelFormat == .rgba16Float)

        // read texture as byte array
        let componentsPerPixel = 4
        let totalPixels = width * height
        let rowBytes = width * componentsPerPixel * MemoryLayout<Float16>.size
        let region = MTLRegionMake2D(0, 0, width, height)
        let floatPtr = UnsafeMutablePointer<Float16>.allocate(
            capacity: totalPixels * componentsPerPixel
        )
        defer { floatPtr.deallocate() }

        self.getBytes(
            floatPtr,
            bytesPerRow: rowBytes,
            from: region,
            mipmapLevel: 0
        )
        var sourceBuffer = vImage_Buffer(
            data: floatPtr,
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: rowBytes
        )

        let destRowBytes = width * componentsPerPixel
        let byteValues = malloc(totalPixels * componentsPerPixel)!
        var destBuffer = vImage_Buffer(
            data: byteValues,
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: destRowBytes
        )

        vImageConvert_PlanarFtoPlanar8(
            &sourceBuffer,
            &destBuffer,
            1.0,
            0.0,
            vImage_Flags(kvImageNoFlags)
        )

        let bytesPtr = byteValues.assumingMemoryBound(to: UInt8.self)
        let provider = CGDataProvider(
            data:
            CFDataCreateWithBytesNoCopy(
                kCFAllocatorDefault,
                bytesPtr,
                totalPixels * componentsPerPixel,
                kCFAllocatorDefault
            )
        )!

        let colorScape = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        let cgImage = CGImage(
            width: self.width,
            height: self.height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: destRowBytes,
            space: colorScape,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent)
        return cgImage
    }

    var image: XImage? {
        guard let cgImage = self.cgImage else { return nil }
        #if os(iOS)
        return UIImage(cgImage: cgImage)
        #elseif os(macOS)
        return NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
        #endif
    }

}
