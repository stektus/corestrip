/*
 * The equalizer.
 *
 * Honest about what it is: an animated indicator, not a spectrum analyser.
 * A Plasma applet has no access to the audio stream — reading it would mean a
 * capture client and a native plugin — so the motion is generated here. It is
 * deterministic (seeded from the track) rather than random, so a repaint never
 * jumps and two widgets side by side stay in step.
 */
import QtQuick
import "../code/util.js" as Util

Canvas {
    id: visualizer

    /* bars | blocks | wave | dots | pulse */
    property string style: "bars"
    property int bars: 7
    property color color: "#5ac8fa"
    property bool active: false
    property int speed: 100
    property int seed: 0
    /* Height the bars rest at when nothing plays. */
    property real floorLevel: 0.14

    readonly property int columns: Math.max(3, Math.min(24, bars))
    readonly property int tickInterval: Math.round(Math.max(20, Math.min(200, 4500 / Math.max(20, speed))))

    property var levels: []
    property var targets: []
    /* Where each column last peaked. The cap that hangs above a falling bar is
       what makes a row of rectangles read as an equalizer. */
    property var peaks: []
    property int frame: 0

    implicitWidth: Math.round(columns * 4)
    implicitHeight: 20

    onColumnsChanged: reset()
    onStyleChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Component.onCompleted: reset()

    function reset() {
        var next = []
        for (var i = 0; i < columns; i++)
            next.push(floorLevel)
        levels = next
        targets = next.slice()
        peaks = next.slice()
        requestPaint()
    }

    /* Low columns swing wider than high ones, the way a spectrum looks. */
    function targetFor(index, step) {
        var tilt = 1 - 0.45 * (index / Math.max(1, columns - 1))
        var slow = Util.noise(seed, index, Math.floor(step / 3))
        var fast = Util.noise(seed + 7, index, step)
        return floorLevel + (0.25 + 0.75 * (0.6 * slow + 0.4 * fast)) * tilt * (1 - floorLevel)
    }

    Timer {
        id: motion
        interval: visualizer.tickInterval
        repeat: true
        running: visualizer.active && visualizer.visible
        onTriggered: {
            visualizer.frame++
            var levels = visualizer.levels
            var targets = visualizer.targets
            var peaks = visualizer.peaks
            for (var i = 0; i < visualizer.columns; i++) {
                if (visualizer.frame % 3 === 0)
                    targets[i] = visualizer.targetFor(i, visualizer.frame)
                /* Rising is quicker than falling — that is what makes it read
                   as sound rather than as a wobble. */
                var rate = targets[i] > levels[i] ? 0.6 : 0.18
                levels[i] += (targets[i] - levels[i]) * rate
                peaks[i] = levels[i] > peaks[i] ? levels[i]
                                                : Math.max(levels[i], peaks[i] - 0.03)
            }
            visualizer.requestPaint()
        }
    }

    /* When the music stops the columns sink instead of freezing mid-air, and
       the timer stops itself once they have — the array is mutated in place,
       so a binding could not tell when to give up. */
    Timer {
        id: settle
        interval: 40
        repeat: true
        onTriggered: {
            var levels = visualizer.levels
            var peaks = visualizer.peaks
            var atRest = true
            for (var i = 0; i < visualizer.columns; i++) {
                levels[i] += (visualizer.floorLevel - levels[i]) * 0.25
                peaks[i] = Math.max(levels[i], peaks[i] - 0.05)
                if (Math.abs(levels[i] - visualizer.floorLevel) > 0.005
                        || peaks[i] - levels[i] > 0.01)
                    atRest = false
            }
            visualizer.requestPaint()
            if (atRest)
                stop()
        }
    }

    onActiveChanged: {
        if (active)
            settle.stop()
        else
            settle.restart()
    }

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        ctx.clearRect(0, 0, width, height)
        if (width <= 0 || height <= 0 || levels.length === 0)
            return

        switch (style) {
        case "blocks": paintBlocks(ctx); break
        case "wave": paintWave(ctx); break
        case "dots": paintDots(ctx); break
        case "pulse": paintPulse(ctx); break
        default: paintBars(ctx)
        }
    }

    /* Bars stay slim when the strip is wide and short: a column wider than
       half its height stops reading as an equalizer and starts reading as a
       row of tiles. */
    function columnGeometry() {
        var slot = width / columns
        var barWidth = Math.max(1, Math.min(slot * 0.58, height * 0.5))
        return { slot: slot, barWidth: barWidth, offset: (slot - barWidth) / 2 }
    }

    function paintBars(ctx) {
        var g = columnGeometry()
        var radius = Math.min(g.barWidth / 2, height * 0.14)
        var capHeight = Math.max(1.5, height * 0.07)
        for (var i = 0; i < columns; i++) {
            var level = Util.clamp01(levels[i])
            var barHeight = Math.max(radius * 2, height * level)
            var x = i * g.slot + g.offset
            var y = height - barHeight

            var gradient = ctx.createLinearGradient(0, y, 0, height)
            gradient.addColorStop(0, Qt.rgba(color.r, color.g, color.b, 1))
            gradient.addColorStop(1, Qt.rgba(color.r, color.g, color.b, 0.4))
            ctx.fillStyle = gradient
            ctx.beginPath()
            ctx.roundedRect(x, y, g.barWidth, barHeight, radius, radius)
            ctx.fill()

            var peak = Util.clamp01(peaks[i])
            var peakY = height - Math.max(capHeight, height * peak)
            if (peakY < y - capHeight * 0.6) {
                ctx.fillStyle = Qt.rgba(color.r, color.g, color.b, 0.75)
                ctx.beginPath()
                ctx.roundedRect(x, peakY, g.barWidth, capHeight,
                                capHeight / 2, capHeight / 2)
                ctx.fill()
            }
        }
    }

    function paintBlocks(ctx) {
        var g = columnGeometry()
        var segments = Math.max(3, Math.min(8, Math.round(height / 6)))
        var gap = Math.max(1, height * 0.06)
        var segmentHeight = (height - gap * (segments - 1)) / segments
        for (var i = 0; i < columns; i++) {
            var lit = Math.round(Util.clamp01(levels[i]) * segments)
            for (var s = 0; s < segments; s++) {
                var on = s < Math.max(1, lit)
                ctx.fillStyle = Qt.rgba(color.r, color.g, color.b, on ? 0.95 - 0.4 * (s / segments) : 0.13)
                var y = height - (s + 1) * segmentHeight - s * gap
                ctx.beginPath()
                ctx.roundedRect(i * g.slot + g.offset, y, g.barWidth, segmentHeight,
                                segmentHeight * 0.35, segmentHeight * 0.35)
                ctx.fill()
            }
        }
    }

    function paintWave(ctx) {
        var middle = height / 2
        var amplitude = 0
        for (var i = 0; i < columns; i++)
            amplitude += levels[i]
        amplitude = (amplitude / columns) * height * 0.42

        ctx.lineWidth = Math.max(1.4, height * 0.09)
        ctx.lineCap = "round"
        ctx.lineJoin = "round"
        ctx.strokeStyle = Qt.rgba(color.r, color.g, color.b, 0.95)
        ctx.beginPath()
        var steps = Math.max(16, Math.round(width))
        for (var s = 0; s <= steps; s++) {
            var t = s / steps
            var phase = frame * 0.22
            var value = Math.sin(t * Math.PI * 3 + phase) * Math.sin(t * Math.PI)
            var y = middle - value * amplitude
            if (s === 0)
                ctx.moveTo(0, y)
            else
                ctx.lineTo(t * width, y)
        }
        ctx.stroke()
    }

    function paintDots(ctx) {
        var g = columnGeometry()
        var radius = Math.max(1.2, Math.min(g.barWidth, height * 0.16) / 2)
        for (var i = 0; i < columns; i++) {
            var level = Util.clamp01(levels[i])
            var y = height - radius - (height - radius * 2) * level
            ctx.fillStyle = Qt.rgba(color.r, color.g, color.b, 0.35)
            ctx.beginPath()
            ctx.ellipse(i * g.slot + g.slot / 2 - radius, height - radius * 2, radius * 2, radius * 2)
            ctx.fill()
            ctx.fillStyle = Qt.rgba(color.r, color.g, color.b, 0.95)
            ctx.beginPath()
            ctx.ellipse(i * g.slot + g.slot / 2 - radius, y - radius, radius * 2, radius * 2)
            ctx.fill()
        }
    }

    function paintPulse(ctx) {
        var mean = 0
        for (var i = 0; i < columns; i++)
            mean += levels[i]
        mean /= columns

        var maxRadius = Math.min(width, height) / 2
        var radius = maxRadius * (0.45 + 0.55 * mean)
        var centreX = width / 2
        var centreY = height / 2

        ctx.fillStyle = Qt.rgba(color.r, color.g, color.b, 0.18)
        ctx.beginPath()
        ctx.ellipse(centreX - radius, centreY - radius, radius * 2, radius * 2)
        ctx.fill()

        ctx.strokeStyle = Qt.rgba(color.r, color.g, color.b, 0.7)
        ctx.lineWidth = Math.max(1, maxRadius * 0.12)
        ctx.beginPath()
        ctx.ellipse(centreX - radius, centreY - radius, radius * 2, radius * 2)
        ctx.stroke()

        var core = maxRadius * 0.36
        ctx.fillStyle = Qt.rgba(color.r, color.g, color.b, 0.95)
        ctx.beginPath()
        ctx.ellipse(centreX - core, centreY - core, core * 2, core * 2)
        ctx.fill()
    }
}
