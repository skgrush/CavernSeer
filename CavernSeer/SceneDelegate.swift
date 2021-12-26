//
//  SceneDelegate.swift
//  CavernSeer
//
//  Created by Samuel Grush on 6/27/20.
//  Copyright © 2020 Samuel K. Grush. All rights reserved.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    var contentView: ContentView?
    var fileOpener: FileOpener?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        let settingsStore = SettingsStore()

        let scanStore = ScanStore(settings: settingsStore)
        let projectStore = ProjectStore()
        let fileOpener = FileOpener(scanStore, projectStore)
        let objSerializer = ObjSerializer()
        let imageSharer = ShareSheetUtility()
        self.fileOpener = fileOpener

        // Create the SwiftUI view that provides the window contents.
        self.contentView = ContentView()
        let contentViewContext = self.contentView
            .environmentObject(scanStore)
            .environmentObject(projectStore)
            .environmentObject(fileOpener)
            .environmentObject(objSerializer)
            .environmentObject(settingsStore)
            .environmentObject(imageSharer)

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(
                rootView: contentViewContext
            )
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    /**
     Open file by URL
     */
    func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
        print("contexts: \(URLContexts.description)")

        let urls = URLContexts.map { $0.url }
        self.fileOpener?.openURLs(urls: urls)
    }

}

