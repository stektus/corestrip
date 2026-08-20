/* Column-per-sample history, the shape used by the "bars" panel style. */
import QtQuick

Canvas {
    id: bars

    property var values: []
    property int revision: 0
    property real maximum: 100
    property color barColor: "#0a84ff"
    property int barWidth: 3
    property int barSpacing: 1

    onRevisionChanged: requestPaint()
    onBarColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        if (!values || values.length === 0 || width <= 0 || height <= 0)
            return

        var slot = barWidth + barSpacing
        var count = Math.max(1, Math.floor(width / slot))
        var start = Math.max(0, values.length - count)
        var max = Math.max(maximum, 0.0001)

        /* Empty slots keep the gauge the same shape whether or not history
           has filled up yet. */
        ctx.fillStyle = Qt.rgba(barColor.r, barColor.g, barColor.b, 0.08)
        for (var s = 0; s < count; s++)
            ctx.fillRect(width - (s + 1) * slot + barSpacing, 0, barWidth, height)

        ctx.fillStyle = barColor
        for (var i = start; i < values.length; i++) {
            var ratio = Math.max(0, Math.min(1, values[i] / max))
            var h = Math.max(ratio > 0 ? 1 : 0, ratio * height)
            var x = width - (values.length - i) * slot + barSpacing
            if (x + barWidth < 0)
                continue
            ctx.fillRect(x, height - h, barWidth, h)
        }
    }
}
