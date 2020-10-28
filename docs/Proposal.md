# _UnnamedCavernSeer_ Proposal Draft

_Samuel K. Grush_

## (Draft) Requirements

- ~~**Phase0 (proof of concept)**~~
  - ~~Can view a live scan of surroundings as a mesh~~
- **Phase1**
  - ~~User can start a scan to begin capturing an AR mesh of their surroundings~~
  - ~~Ending a scan will store off all (useful) information to a named file~~
  - User can mark `survey anchor`s (raycasting?) on the mesh.
    - ~~survey anchors _should probably_ be visible~~
    - Nameable?
    - ~~click~~ and hold??
  - User can indicate a point to see the distance to (single click?)
  - ~~Meshes _should probably_ occlude one another.~~ (~~Completely?~~ Transparently? Configurably?)
  - ~~Previously-generated~~ project ~~meshes can be viewed and survey anchor distances can be measured~~
  - Ability to halt a session and restore (precise restore sounds tough, phase2?)
- **Phase2**
  - ~~Project meshes can be rendered into flat map projections,~~ and plane slices
  - ~~Project messhes can be exported to _some_ file format that retains all information~~
  - ~~Project meshes can be exported to an open and well-supported format~~
  - View meshes in VR/AR
- **Phase3? (Tough/longshot goals)**
  - Tweak mesh based on precise external measurements of survey anchors (e.g. feed long-range disto-measurements into world map to improve accuracy)
  - Collaboration

## Relevant Caveats

- “Design AR experiences for predictable lighting conditions. World tracking involves image analysis, which requires a clear image. Tracking quality is reduced when the camera can’t see details, such as when the camera is pointed at a blank wall or the scene is too dark.“
- Depth accuracy limits
- Thermal issues may require stopping world tracking **(confirmed)**, but smooth downgrading is possible

## Technical points

- With Scene reconstruction (MUST check if it supportsSceneReconstruction aka LiDAR, >= iOS 13.4)
- Without plane detection
- showSceneUnderstanding shows meshes

## Sources:

- ARKit World Tracking, _Apple Developer Documentation_
  https://developer.apple.com/documentation/arkit/world_tracking
  - Visualizing and Interacting with a Reconstructed Scene
    https://developer.apple.com/documentation/arkit/world_tracking/visualizing_and_interacting_with_a_reconstructed_scene
