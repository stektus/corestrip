/*
 * Weather symbols drawn in the widget's own style.
 *
 * Icon themes disagree wildly about weather names — several popular ones ship
 * only a handful — so the widget draws its own instead of hoping the theme has
 * "weather-many-clouds".
 */
import QtQuick
import "../code/util.js" as Util

Canvas {
    id: glyph

    /* WMO weather code as reported by Open-Meteo. */
    property int code: 0
    property bool day: true

    property color sunColor: "#ffd60a"
    property color moonColor: "#e6e6ea"
    property color cloudColor: "#c9ccd6"
    property color cloudShade: "#9aa0ad"
    property color rainColor: "#5ac8fa"
    property color snowColor: "#eaf4ff"
    property color boltColor: "#ffb340"

    implicitWidth: 32
    implicitHeight: 32

    onCodeChanged: requestPaint()
    onDayChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    readonly property int family: {
        switch (code) {
        case 0: return 0                                    // clear
        case 1: return 1                                    // mainly clear
        case 2: return 2                                    // partly cloudy
        case 3: return 3                                    // overcast
        case 45: case 48: return 4                          // fog
        case 51: case 53: case 55: case 56: case 57: return 5   // drizzle
        case 61: case 63: case 65: case 66: case 67: return 6   // rain
        case 80: case 81: case 82: return 6
        case 71: case 73: case 75: case 77: return 7        // snow
        case 85: case 86: return 7
        case 95: case 96: case 99: return 8                 // thunderstorm
        }
        return 3
    }

    function drawSun(ctx, cx, cy, radius, rays) {
        if (rays) {
            ctx.strokeStyle = glyph.sunColor
            ctx.lineWidth = Math.max(1, radius * 0.22)
            ctx.lineCap = "round"
            for (var i = 0; i < 8; i++) {
                var angle = i * Math.PI / 4
                var inner = radius * 1.45
                var outer = radius * 1.95
                ctx.beginPath()
                ctx.moveTo(cx + Math.cos(angle) * inner, cy + Math.sin(angle) * inner)
                ctx.lineTo(cx + Math.cos(angle) * outer, cy + Math.sin(angle) * outer)
                ctx.stroke()
            }
        }
        ctx.beginPath()
        ctx.arc(cx, cy, radius, 0, Math.PI * 2)
        ctx.fillStyle = glyph.sunColor
        ctx.fill()
    }

    function drawMoon(ctx, cx, cy, radius) {
        /* Crescent: a filled disc with a second disc punched out of it. */
        ctx.save()
        ctx.beginPath()
        ctx.arc(cx, cy, radius, 0, Math.PI * 2)
        ctx.fillStyle = glyph.moonColor
        ctx.fill()
        ctx.globalCompositeOperation = "destination-out"
        ctx.beginPath()
        ctx.arc(cx + radius * 0.55, cy - radius * 0.45, radius * 0.92, 0, Math.PI * 2)
        ctx.fill()
        ctx.restore()
    }

    function drawCloud(ctx, x, y, width, color) {
        var height = width * 0.62
        ctx.fillStyle = color
        ctx.beginPath()
        ctx.arc(x + width * 0.32, y + height * 0.55, height * 0.45, 0, Math.PI * 2)
        ctx.arc(x + width * 0.58, y + height * 0.36, height * 0.55, 0, Math.PI * 2)
        ctx.arc(x + width * 0.78, y + height * 0.6, height * 0.4, 0, Math.PI * 2)
        ctx.fill()
        ctx.beginPath()
        ctx.roundedRect(x + width * 0.16, y + height * 0.62, width * 0.7, height * 0.42,
                        height * 0.21, height * 0.21)
        ctx.fill()
    }

    function drawDrops(ctx, x, y, width, count, color, dash) {
        ctx.strokeStyle = color
        ctx.lineWidth = Math.max(1, width * 0.06)
        ctx.lineCap = "round"
        for (var i = 0; i < count; i++) {
            var dx = x + width * (0.28 + i * 0.22)
            ctx.beginPath()
            ctx.moveTo(dx, y)
            ctx.lineTo(dx - width * 0.06, y + width * (dash ? 0.14 : 0.22))
            ctx.stroke()
        }
    }

    function drawFlakes(ctx, x, y, width, count, color) {
        ctx.fillStyle = color
        for (var i = 0; i < count; i++) {
            var dx = x + width * (0.3 + i * 0.22)
            ctx.beginPath()
            ctx.arc(dx, y + width * 0.1, Math.max(1, width * 0.055), 0, Math.PI * 2)
            ctx.fill()
        }
    }

    function drawBolt(ctx, x, y, size, color) {
        ctx.fillStyle = color
        ctx.beginPath()
        ctx.moveTo(x + size * 0.55, y)
        ctx.lineTo(x + size * 0.2, y + size * 0.55)
        ctx.lineTo(x + size * 0.45, y + size * 0.55)
        ctx.lineTo(x + size * 0.3, y + size)
        ctx.lineTo(x + size * 0.8, y + size * 0.42)
        ctx.lineTo(x + size * 0.52, y + size * 0.42)
        ctx.closePath()
        ctx.fill()
    }

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()

        var size = Math.min(width, height)
        if (size <= 0)
            return

        var unit = size / 32

        switch (family) {
        case 0:     // clear sky
            if (day)
                drawSun(ctx, size * 0.5, size * 0.5, unit * 7, true)
            else
                drawMoon(ctx, size * 0.5, size * 0.5, unit * 9)
            break

        case 1:     // mainly clear: bright sky with a small cloud
        case 2:     // partly cloudy
            if (day)
                drawSun(ctx, size * 0.36, size * 0.34, unit * (family === 1 ? 6 : 5.5), true)
            else
                drawMoon(ctx, size * 0.36, size * 0.34, unit * (family === 1 ? 7.5 : 7))
            drawCloud(ctx, size * 0.24, size * 0.42, size * 0.72, cloudColor)
            break

        case 3:     // overcast: two stacked cloud layers
            drawCloud(ctx, size * 0.06, size * 0.22, size * 0.66, cloudShade)
            drawCloud(ctx, size * 0.2, size * 0.38, size * 0.74, cloudColor)
            break

        case 4:     // fog
            drawCloud(ctx, size * 0.14, size * 0.2, size * 0.72, cloudColor)
            ctx.strokeStyle = cloudShade
            ctx.lineWidth = Math.max(1, unit * 1.6)
            ctx.lineCap = "round"
            for (var f = 0; f < 3; f++) {
                var fy = size * (0.68 + f * 0.11)
                ctx.beginPath()
                ctx.moveTo(size * (f % 2 === 0 ? 0.18 : 0.28), fy)
                ctx.lineTo(size * (f % 2 === 0 ? 0.82 : 0.72), fy)
                ctx.stroke()
            }
            break

        case 5:     // drizzle
            drawCloud(ctx, size * 0.14, size * 0.16, size * 0.72, cloudColor)
            drawDrops(ctx, size * 0.14, size * 0.72, size * 0.72, 3, rainColor, true)
            break

        case 6:     // rain
            drawCloud(ctx, size * 0.14, size * 0.12, size * 0.72, cloudColor)
            drawDrops(ctx, size * 0.14, size * 0.66, size * 0.72, 3, rainColor, false)
            break

        case 7:     // snow
            drawCloud(ctx, size * 0.14, size * 0.12, size * 0.72, cloudColor)
            drawFlakes(ctx, size * 0.14, size * 0.68, size * 0.72, 3, snowColor)
            break

        case 8:     // thunderstorm
            drawCloud(ctx, size * 0.12, size * 0.1, size * 0.76, cloudShade)
            drawBolt(ctx, size * 0.3, size * 0.6, size * 0.38, boltColor)
            break
        }
    }
}
