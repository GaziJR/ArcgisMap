// [WriteFile Name=Animate3DSymbols, Category=Scenes]
// [Legal]
// Copyright 2016 Esri.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// [Legal]

import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Esri.ArcGISRuntime 100.13
import Esri.ArcGISExtras 1.1
import QtWebEngine 1.0

Rectangle {
    id: rootRectangle
    objectName: "hudBarCompenets"

    width: 800
    height: 600

    property string headingAtt: "heading";
    property string pitchAtt: "pitch";
    property string rollAtt: "roll";
    property real lon2;
    property real lat2;
    property real yaw2;
    property real roll2;
    property real pitch2;
    property real elevation2;
    property string attrFormat: "[%1]"

    property Graphic routeGraphic

    /**
     * Create SceneView that contains a Scene with the Imagery Basemap
     */

    // Create a scene view
    SceneView {
        id: sceneView
        anchors.fill: parent

        Component.onCompleted: {
            // Set the focus on SceneView to initially enable keyboard navigation
            forceActiveFocus();
        }

        attributionTextVisible: (sceneView.width - mapView.width) > mapView.width // only show attribution text on the widest view

        cameraController: followButton.checked ? followController : globeController

        // create a scene...scene is a default property of sceneview
        // and thus will get added to the sceneview
        Scene {
            // add a basemap
            BasemapImageryWithLabels {}

            // add a surface...surface is a default property of scene
            Surface {
                // add an arcgis tiled elevation source...elevation source is a default property of surface
                ArcGISTiledElevationSource {
                    url: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer"
                }
            }
        }

        GraphicsOverlay {
            id: sceneOverlay

            LayerSceneProperties {
                surfacePlacement: Enums.SurfacePlacementAbsolute
            }

            SimpleRenderer {
                id: sceneRenderer
                RendererSceneProperties {
                    id: renderProps
                    headingExpression: attrFormat.arg(headingAtt)
                    pitchExpression:  attrFormat.arg(pitchAtt)
                    rollExpression: attrFormat.arg(rollAtt)
                }
            }

            ModelSceneSymbol {
                id: mms
                url: "Bristol.dae"
                scale: 1.0
                heading: 0.0
            }

            Graphic {
                id: graphic3d
                symbol: mms

                geometry: Point {
                    x: 0.
                    y: 0.
                    z: 100.
                    spatialReference: sceneView.spatialReference
                }

                Component.onCompleted: {
                    graphic3d.attributes.insertAttribute(headingAtt, 0.);
                    graphic3d.attributes.insertAttribute(rollAtt, 0.);
                    graphic3d.attributes.insertAttribute(pitchAtt, 0.);
                }
            }
        }

        GridLayout {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                bottom: sceneView.attributionTop
                margins: 10
            }

            columns: 2

            RowLayout {
                Button {
                    id: followButton
                    Layout.alignment: Qt.AlignRight | Qt.AlignTop
                    text: checked? "fixed" : "follow "
                    checked: true
                    checkable: true
                }

            }

            Rectangle {
                id: mapFrame
                Layout.columnSpan: 2
                Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                Layout.minimumHeight: parent.height * 0.25
                Layout.minimumWidth: parent.width * 0.3
                color: "black"

                MapView {
                    id: mapView
                    objectName: "mapView"
                    anchors {
                        fill: parent
                        margins: 2
                    }

                    Map {
                        BasemapImageryWithLabels {}
                    }

                    GraphicsOverlay {
                        id: graphicsOverlay
                        Graphic {
                            id: graphic2d
                            symbol: plane2DSymbol
                        }
                    }

                    // MouseArea {
                    //     anchors.fill: parent
                    //     onPressed: mouse.accepted
                    //     onWheel: wheel.accepted
                    // }
                }

                RowLayout {
                    anchors {
                        left: parent.left
                        top: parent.top
                    }
                    spacing: 10

                }
            }
        }
    }

    GlobeCameraController {
        id: globeController
    }

    OrbitGeoElementCameraController {
        id: followController
        targetGeoElement: graphic3d
        cameraDistance: 500.0
        cameraPitchOffset: 45.0
    }


    ListModel {
        id: currentMissionModel
    }

    SimpleMarkerSymbol {
        id: plane2DSymbol
        style: Enums.SimpleMarkerSymbolStyleTriangle
        color: "blue"
        size: 10
    }

    Timer {
        id: timer
        interval: 64;
        running: true;
        repeat: true
        onTriggered: animate();
    }

    function animate() {
        const newPos = createPoint();


        graphic3d.geometry = newPos;
        graphic3d.attributes.replaceAttribute(headingAtt, yaw2);
        graphic3d.attributes.replaceAttribute(pitchAtt, pitch2);
        graphic3d.attributes.replaceAttribute(rollAtt, roll2);

        // update the 2d graphic
        graphic2d.geometry = newPos;
        plane2DSymbol.angle = yaw2;

        //nextFrameRequested();
    }

    function createPoint() {
        return ArcGISRuntimeEnvironment.createObject(
                    "Point", {
                        x: lon2,
                        y: lat2,
                        z: elevation2,
                        spatialReference: Factory.SpatialReference.createWgs84()
                    });
    }

}
