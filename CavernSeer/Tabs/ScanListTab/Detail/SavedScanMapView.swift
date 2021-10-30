//
//  SavedScanMapView.swift
//  CavernSeer
//
//  Created by Samuel Grush on 7/18/21.
//  Copyright © 2021 Samuel K. Grush. All rights reserved.
//

import SwiftUI
import MapKit
import SceneKit


final class MapProjectedMiniWorldController :
    UIViewController, BaseProjectedMiniWorldRenderController {

    static let height: Float = 200

    let showUI = false

    let selectedStation: SurveyStation? = nil
    var prevSelected: SurveyStation? = nil

    let scaleBarModel = ScaleBarModel()
    unowned let renderModel: GeneralRenderModel

    init(renderModel: GeneralRenderModel) {
        self.renderModel = renderModel

        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func postSceneAttachment(sceneView: SCNView) {
        sceneView.allowsCameraControl = false
    }

    func viewUpdater(uiView: SCNView) {
        //uiView.pointOfView?.camera?.fieldOfView = uiView.frame.size.width

    }

    func makeaCamera() -> SCNNode {
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 1
        camera.projectionDirection = .horizontal
        camera.zNear = 0.1
        camera.zFar = 1000

        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: Self.height, z: 0)
        cameraNode.eulerAngles = SCNVector3Make(.pi / -2, 0, 0)

        return cameraNode
    }
}


fileprivate let usaLocation = MKCoordinateRegion(
    center: .init(latitude: 37.9559293, longitude: -91.7742682),
    latitudinalMeters: .init(2600),
    longitudinalMeters: .init(2600)
)
fileprivate extension MKCoordinateRegion {
    func boundingMapRect() -> MKMapRect {
        .init(
            origin: .init(self.center),
            size: .init(
                width: self.span.latitudeDelta,
                height: self.span.longitudeDelta
            )
        )
    }
}

class ScanMapOverlay : NSObject, MKOverlay {

    static let PxPerMeter: Float = 100

    /// root coordinate of a scan-map on the greater map
    var coordinate: CLLocationCoordinate2D
    /// rectangle within which the overlay is visible
    var boundingMapRect: MKMapRect

    let snapshotPngData: Data

    init(scan: ScanFile, renderModel: GeneralRenderModel) {
        let extentMeters = scan.extent
        let centerMeters = scan.center

        if let loc = scan.location {
            self.coordinate = loc.toCoordinates()
            self.boundingMapRect = MKMapRect(
                origin: .init(self.coordinate),
                size: .init(width: 100, height: 100)
            )
        } else {
            self.coordinate = usaLocation.center
            self.boundingMapRect = usaLocation.boundingMapRect()
        }


        self.snapshotPngData = Self.generateSnapshotData(
            extent: extentMeters,
            renderModel: renderModel
        )
    }



    func moveTo(coord: CLLocationCoordinate2D) {
        self.boundingMapRect = self.boundingMapRect.offsetBy(
            dx: coord.latitude - self.coordinate.latitude,
            dy: coord.longitude - self.coordinate.longitude
        )
        self.coordinate = coord

    }

    private static func generateSnapshotData(
        extent: simd_float3,
        renderModel: GeneralRenderModel
    ) -> Data {
        guard
            let device = MTLCreateSystemDefaultDevice()
        else {
            fatalError("generateSnapshot failed on device retrieval")
        }

        let controller = MapProjectedMiniWorldController(
            renderModel: renderModel
        )
        let scnView = controller.makeUIView()

        let newSize = CGSize(
            // x axis (east)
            width: CGFloat(Self.PxPerMeter * extent.x),
            // z axis (south)
            height: CGFloat(Self.PxPerMeter * extent.y)
        )

        let renderer = SCNRenderer(device: device)
        renderer.scene = scnView.scene
        renderer.pointOfView = scnView.pointOfView

        let img = renderer.snapshot(
            atTime: TimeInterval(0),
            with: newSize,
            antialiasingMode: .multisampling4X
        )

        return img.pngData()!
    }

    private static func processLocation(
        location: CSLocation?,
        extent: simd_float3
    ) -> MKCoordinateRegion {
        if let loc = location {
            return .init(
                center: .init(latitude: loc.latitude, longitude: loc.longitude),
                latitudinalMeters: .init(extent.x),
                longitudinalMeters: .init(extent.y)
            )
        } else {
            return usaLocation
        }
    }
}

class SavedScanMapViewModel: ObservableObject {
    @Published
    var visible = false
    @Published
    var coordinateRegion: MKCoordinateRegion = usaLocation
    @ObservedObject
    var renderModel = GeneralRenderModel()

    func onAppear(_ scan: ScanFile, _ settings: SettingsStore) {

        self.renderModel.updateScanAndSettings(scan: scan, settings: settings)

        let overlay = ScanMapOverlay(scan: scan, renderModel: self.renderModel)

        

        self.visible = true
    }

    func onDisappear() {
        self.visible = false

        self.renderModel.dismantle()
    }




}


struct SavedScanMapView: View {
    var scan: ScanFile

    @EnvironmentObject
    var settings: SettingsStore

    @ObservedObject
    private var model = SavedScanMapViewModel()

    var body: some View {
        VStack {
            if model.visible {
                Map(coordinateRegion: $model.coordinateRegion)
                    .ignoresSafeArea()
            }
        }
        .onAppear(perform: { model.onAppear(scan, settings) })
        .onDisappear(perform: { model.onDisappear() })
    }
}

//struct SavedScanMapView_Previews: PreviewProvider {
//    static var previews: some View {
//        SavedScanMapView()
//    }
//}
