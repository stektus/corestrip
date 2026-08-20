/* Rounded progress ring; the arc grows clockwise from twelve o'clock. */
import QtQuick
import QtQuick.Shapes

Item {
    id: ring

    /* 0..1 */
    property real value: 0
    property color ringColor: "#0a84ff"
    property real thickness: Math.max(2, Math.min(width, height) * 0.12)
    property color trackColor: Qt.rgba(ringColor.r, ringColor.g, ringColor.b, 0.16)
    property bool animated: true

    readonly property real radius: (Math.min(width, height) - thickness) / 2

    default property alias content: contentArea.data

    Behavior on value {
        enabled: ring.animated
        NumberAnimation { duration: 450; easing.type: Easing.OutCubic }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        asynchronous: false

        ShapePath {
            strokeColor: ring.trackColor
            strokeWidth: ring.thickness
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap

            PathAngleArc {
                centerX: ring.width / 2
                centerY: ring.height / 2
                radiusX: ring.radius
                radiusY: ring.radius
                startAngle: -90
                sweepAngle: 360
            }
        }

        ShapePath {
            strokeColor: ring.ringColor
            strokeWidth: ring.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: ring.width / 2
                centerY: ring.height / 2
                radiusX: ring.radius
                radiusY: ring.radius
                startAngle: -90
                /* A hair below a full turn so the round cap never overlaps itself. */
                sweepAngle: Math.min(359.9, 360 * Math.max(0, Math.min(1, ring.value)))
            }
        }
    }

    Item {
        id: contentArea
        anchors.centerIn: parent
        width: parent.width - ring.thickness * 2.4
        height: parent.height - ring.thickness * 2.4
    }
}
