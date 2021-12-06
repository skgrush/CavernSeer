/*
Copyright © 2020 Apple Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Abstract:
A custom anchor for saving a snapshot image in an ARWorldMap.
*/

import RealityKit
import ARKit

/// - Tag: SnapshotAnchor
class SnapshotAnchor: ARAnchor {

    let imageData: Data

    convenience init?(capturing session: ARSession, suffix: String) {

        #if !targetEnvironment(simulator)
        guard let frame = session.currentFrame
        else {
            debugPrint("Cannot capture snapshot; no `session.currentFrame`")
            return nil
        }

        let image = CIImage(cvPixelBuffer: frame.capturedImage)
        let orientation = CGImagePropertyOrientation(
            cameraOrientation: UIDevice.current.orientation
        )

        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let data = context.jpegRepresentation(
            of: image.oriented(orientation),
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.7])
        else {
            debugPrint("Cannot capture snapshot; jpeg conversion failed")
            return nil
        }

        self.init(
            imageData: data,
            transform: frame.camera.transform,
            suffix: suffix
        )
        #else
        return nil
        #endif
    }

    init(imageData: Data, transform: float4x4, suffix: String) {
        self.imageData = imageData
        super.init(name: "snapshot-\(suffix)", transform: transform)
    }

    required init(anchor: ARAnchor) {
        self.imageData = (anchor as! SnapshotAnchor).imageData
        super.init(anchor: anchor)
    }

    override class var supportsSecureCoding: Bool {
        return true
    }

    required init?(coder aDecoder: NSCoder) {
        if let snapshot = aDecoder.decodeObject(
            of: NSData.self,
            forKey: "snapshot"
        ) as Data? {
            self.imageData = snapshot
        } else {
            return nil
        }

        super.init(coder: aDecoder)
    }

    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(imageData, forKey: "snapshot")
    }

}



extension CGImagePropertyOrientation {
    /// Preferred image presentation orientation respecting the native sensor orientation of iOS device camera.
    init(cameraOrientation: UIDeviceOrientation) {
        switch cameraOrientation {
        case .portrait:
            self = .right
        case .portraitUpsideDown:
            self = .left
        case .landscapeLeft:
            self = .up
        case .landscapeRight:
            self = .down
        default:
            self = .right
        }
    }
}
