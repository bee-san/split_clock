import QtQuick 2.15

Item {
    id: root

    property var bodyData: null
    property bool moon: false
    property color haloColor: Qt.rgba(1, 1, 1, 1)
    property color coreColor: Qt.rgba(1, 1, 1, 1)
    property color rimColor: Qt.rgba(1, 1, 1, 1)
    property color shadowColor: Qt.rgba(0, 0, 0, 1)
    property color atmosphereTintColor: Qt.rgba(1, 1, 1, 1)
    property real glowOpacity: 0.22
    property real rimOpacity: moon ? 0.34 : 0.26
    property real atmosphericVeilOpacity: 0
    property real surfaceFlattening: 0
    property real rimSoftening: 0
    property bool pulse: !moon

    function clampUnit(value) {
        return Math.max(0, Math.min(1, value));
    }

    function lerp(fromValue, toValue, amount) {
        return fromValue + ((toValue - fromValue) * clampUnit(amount));
    }

    function flattenColor(baseColor, targetColor, amount) {
        return Qt.rgba(
            lerp(baseColor.r, targetColor.r, amount),
            lerp(baseColor.g, targetColor.g, amount),
            lerp(baseColor.b, targetColor.b, amount),
            lerp(baseColor.a, targetColor.a, amount)
        );
    }

    readonly property bool hasBody: bodyData && bodyData.visible
    readonly property bool simplifiedMoon: moon && bodyData && bodyData.isSimplified === true
    readonly property real illuminationFraction: moon && bodyData && bodyData.illuminationFraction !== undefined ? clampUnit(bodyData.illuminationFraction) : 1
    readonly property bool litFromRight: !moon || !bodyData || bodyData.isWaxing !== false
    readonly property real surfaceDiameter: width * (moon ? 0.44 : 0.48)
    readonly property real phaseVectorZ: moon ? ((illuminationFraction * 2) - 1) : 1
    readonly property real phaseVectorX: moon
        ? ((litFromRight ? 1 : -1) * Math.sqrt(Math.max(0, 1 - (phaseVectorZ * phaseVectorZ))))
        : 0
    readonly property real phaseCurveScale: moon ? Math.abs(phaseVectorZ) : 1
    readonly property color moonLitCenterColor: Qt.rgba(
        (root.coreColor.r * 0.92) + 0.08,
        (root.coreColor.g * 0.92) + 0.08,
        (root.coreColor.b * 0.92) + 0.08,
        1
    )
    readonly property color moonLitRimColor: Qt.rgba(
        (root.coreColor.r * 0.78) + (root.rimColor.r * 0.22),
        (root.coreColor.g * 0.78) + (root.rimColor.g * 0.22),
        (root.coreColor.b * 0.78) + (root.rimColor.b * 0.22),
        1
    )
    readonly property color moonDarkCenterColor: Qt.rgba(
        lerp(root.shadowColor.r, root.coreColor.r, 0.16),
        lerp(root.shadowColor.g, root.coreColor.g, 0.16),
        lerp(root.shadowColor.b, root.coreColor.b, 0.16),
        1
    )
    readonly property color moonDarkRimColor: Qt.rgba(
        lerp(root.shadowColor.r, root.rimColor.r, 0.08),
        lerp(root.shadowColor.g, root.rimColor.g, 0.08),
        lerp(root.shadowColor.b, root.rimColor.b, 0.08),
        1
    )
    readonly property bool gibbousMoon: moon && illuminationFraction > 0.501
    readonly property bool crescentMoon: moon && illuminationFraction < 0.499
    readonly property real phaseEllipseScale: moon ? Math.max(0.001, phaseCurveScale) : 1
    readonly property real surfaceRotation: moon && bodyData ? bodyData.terminatorAngle || 0 : 0
    readonly property real flatteningAmount: clampUnit(surfaceFlattening)
    readonly property real softenedRimOpacity: rimOpacity * (1 - (clampUnit(rimSoftening) * 0.78))
    readonly property real softenedGlowOpacity: glowOpacity * (1 - (flatteningAmount * 0.32))
    readonly property color sunFlatCenterColor: root.flattenColor(
        Qt.rgba(
            (root.coreColor.r * 0.92) + 0.08,
            (root.coreColor.g * 0.92) + 0.08,
            (root.coreColor.b * 0.92) + 0.08,
            1
        ),
        root.atmosphereTintColor,
        root.flatteningAmount * 0.52
    )
    readonly property color sunFlatRimColor: root.flattenColor(
        Qt.rgba(
            (root.coreColor.r * 0.78) + (root.rimColor.r * 0.22),
            (root.coreColor.g * 0.78) + (root.rimColor.g * 0.22),
            (root.coreColor.b * 0.78) + (root.rimColor.b * 0.22),
            1
        ),
        root.atmosphereTintColor,
        root.flatteningAmount * 0.62
    )
    readonly property color flattenedMoonLitCenterColor: root.flattenColor(root.moonLitCenterColor, root.atmosphereTintColor, root.flatteningAmount * 0.48)
    readonly property color flattenedMoonLitRimColor: root.flattenColor(root.moonLitRimColor, root.atmosphereTintColor, root.flatteningAmount * 0.58)
    readonly property color flattenedMoonDarkCenterColor: root.flattenColor(root.moonDarkCenterColor, root.atmosphereTintColor, root.flatteningAmount * 0.32)
    readonly property color flattenedMoonDarkRimColor: root.flattenColor(root.moonDarkRimColor, root.atmosphereTintColor, root.flatteningAmount * 0.4)
    readonly property color softenedBorderColor: root.flattenColor(root.rimColor, root.atmosphereTintColor, root.flatteningAmount * 0.68)
    readonly property real moonPhaseSoftening: moon
        ? clampUnit((flatteningAmount * 0.56) + (atmosphericVeilOpacity * 0.78) + (clampUnit(rimSoftening) * 0.28))
        : 0
    readonly property real moonPhaseRendererOpacity: moon ? 1 - (moonPhaseSoftening * 0.26) : 1
    readonly property real phaseTerminatorVeilOpacity: moon ? moonPhaseSoftening * 0.24 : 0
    readonly property real phaseTerminatorCenter: moon
        ? clampUnit(
            litFromRight
                ? (gibbousMoon ? 0.42 + ((1 - phaseEllipseScale) * 0.16) : 0.54 - ((1 - phaseEllipseScale) * 0.18))
                : (gibbousMoon ? 0.58 - ((1 - phaseEllipseScale) * 0.16) : 0.46 + ((1 - phaseEllipseScale) * 0.18))
        )
        : 0.5
    readonly property color moonPhaseLitCenterColor: root.flattenColor(root.flattenedMoonLitCenterColor, root.atmosphereTintColor, root.moonPhaseSoftening * 0.16)
    readonly property color moonPhaseLitRimColor: root.flattenColor(root.flattenedMoonLitRimColor, root.atmosphereTintColor, root.moonPhaseSoftening * 0.2)
    readonly property color moonPhaseDarkCenterColor: root.flattenColor(root.flattenedMoonDarkCenterColor, root.flattenedMoonLitCenterColor, root.moonPhaseSoftening * 0.34)
    readonly property color moonPhaseDarkRimColor: root.flattenColor(root.flattenedMoonDarkRimColor, root.flattenedMoonLitRimColor, root.moonPhaseSoftening * 0.28)
    readonly property color moonPhaseVeilColor: root.flattenColor(root.atmosphereTintColor, root.flattenedMoonLitCenterColor, 0.18)

    visible: hasBody

    Rectangle {
        anchors.centerIn: parent
        width: parent.width
        height: width
        radius: width / 2
        color: Qt.rgba(root.haloColor.r, root.haloColor.g, root.haloColor.b, root.softenedGlowOpacity * (root.moon ? 0.36 : 0.44))

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: root.visible && root.pulse

            NumberAnimation {
                from: 0.9
                to: 1.04
                duration: 4200
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                from: 1.04
                to: 0.9
                duration: 4200
                easing.type: Easing.InOutSine
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: parent.width * (moon ? 0.52 : 0.58)
        height: width
        radius: width / 2
        color: Qt.rgba(root.haloColor.r, root.haloColor.g, root.haloColor.b, root.softenedGlowOpacity * (moon ? 0.22 : 0.28))
    }

    Rectangle {
        id: surface
        objectName: root.moon ? "moonSurfaceItem" : "surfaceItem"

        anchors.centerIn: parent
        width: root.surfaceDiameter
        height: width
        radius: width / 2
        clip: true
        border.width: Math.max(1, Math.round(width * (0.055 - (clampUnit(root.rimSoftening) * 0.025))))
        border.color: Qt.rgba(root.softenedBorderColor.r, root.softenedBorderColor.g, root.softenedBorderColor.b, root.softenedRimOpacity)
        rotation: root.surfaceRotation
        transformOrigin: Item.Center
        gradient: root.moon
            ? (root.gibbousMoon ? moonLitGradient : moonDarkGradient)
            : sunSurfaceGradient

        Gradient {
            id: sunSurfaceGradient

            GradientStop {
                position: 0
                color: root.sunFlatCenterColor
            }
            GradientStop {
                position: 1
                color: root.sunFlatRimColor
            }
        }

        Gradient {
            id: moonLitGradient

            GradientStop {
                position: 0
                color: root.moonPhaseLitCenterColor
            }

            GradientStop {
                position: 1
                color: root.moonPhaseLitRimColor
            }
        }

        Gradient {
            id: moonDarkGradient

            GradientStop {
                position: 0
                color: root.moonPhaseDarkCenterColor
            }

            GradientStop {
                position: 1
                color: root.moonPhaseDarkRimColor
            }
        }

        Item {
            id: moonPhaseRenderer
            objectName: "moonPhaseRenderer"
            visible: root.moon && root.illuminationFraction > 0.001 && root.illuminationFraction < 0.999
            anchors.fill: parent
            clip: true
            opacity: root.moonPhaseRendererOpacity

            Item {
                visible: !root.gibbousMoon
                clip: true
                width: parent.width / 2
                height: parent.height
                x: root.litFromRight ? parent.width / 2 : 0

                Item {
                    width: surface.width
                    height: surface.height
                    x: root.litFromRight ? -(surface.width / 2) : 0

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        gradient: moonLitGradient
                    }

                    Rectangle {
                        id: crescentShadowShape
                        visible: root.crescentMoon
                        anchors.centerIn: parent
                        width: parent.height
                        height: parent.height
                        radius: width / 2
                        gradient: moonDarkGradient

                        transform: Scale {
                            origin.x: crescentShadowShape.width / 2
                            origin.y: crescentShadowShape.height / 2
                            xScale: root.phaseEllipseScale
                            yScale: 1
                        }
                    }
                }
            }

            Item {
                visible: root.gibbousMoon
                clip: true
                width: parent.width / 2
                height: parent.height
                x: root.litFromRight ? 0 : parent.width / 2

                Item {
                    width: surface.width
                    height: surface.height
                    x: root.litFromRight ? 0 : -(surface.width / 2)

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        gradient: moonDarkGradient
                    }

                    Rectangle {
                        id: gibbousLightShape
                        anchors.centerIn: parent
                        width: parent.height
                        height: parent.height
                        radius: width / 2
                        gradient: moonLitGradient

                        transform: Scale {
                            origin.x: gibbousLightShape.width / 2
                            origin.y: gibbousLightShape.height / 2
                            xScale: root.phaseEllipseScale
                            yScale: 1
                        }
                    }
                }
            }

            Rectangle {
                id: moonTerminatorVeil

                objectName: "moonTerminatorVeilItem"
                visible: root.moonPhaseSoftening > 0.04
                width: parent.width * (0.12 + (root.moonPhaseSoftening * 0.12))
                height: parent.height * 1.02
                radius: width / 2
                x: (parent.width * root.phaseTerminatorCenter) - (width / 2)
                y: -parent.height * 0.01
                color: Qt.rgba(
                    root.moonPhaseVeilColor.r,
                    root.moonPhaseVeilColor.g,
                    root.moonPhaseVeilColor.b,
                    root.phaseTerminatorVeilOpacity
                )
            }
        }
    }

    Rectangle {
        anchors.centerIn: surface
        width: surface.width * (1.02 + (root.atmosphericVeilOpacity * 0.04))
        height: width
        radius: width / 2
        color: Qt.rgba(
            root.atmosphereTintColor.r,
            root.atmosphereTintColor.g,
            root.atmosphereTintColor.b,
            root.atmosphericVeilOpacity * (root.moon ? 0.18 : 0.14)
        )
    }

    Rectangle {
        anchors.fill: surface
        radius: width / 2
        color: Qt.rgba(
            root.atmosphereTintColor.r,
            root.atmosphereTintColor.g,
            root.atmosphereTintColor.b,
            root.atmosphericVeilOpacity * (root.moon ? 0.36 : 0.3)
        )
    }

    Rectangle {
        width: surface.width * (moon ? 0.16 : 0.2)
        height: width
        radius: width / 2
        x: surface.x + (surface.width * 0.18)
        y: surface.y + (surface.height * 0.12)
        color: Qt.rgba(1, 1, 1, moon ? 0.12 * (1 - (root.moonPhaseSoftening * 0.54)) : 0.2 * (1 - (root.flatteningAmount * 0.28)))
    }
}
