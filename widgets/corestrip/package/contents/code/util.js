.pragma library

/* macOS-inspired accent palette, one hue per metric. */
var accent = {
    cpu: "#0a84ff",
    gpu: "#bf5af2",
    memory: "#30d158",
    network: "#ff9f0a",
    disk: "#64d2ff",
    battery: "#5e5ce6",
    thermal: "#ff453a"
}

/* Load colours shift towards red as a metric saturates, so a busy machine
   is readable at a glance without reading any number. */
function loadColor(base, ratio) {
    if (ratio === undefined || isNaN(ratio))
        return base
    if (ratio < 0.7)
        return base
    if (ratio < 0.9)
        return blend(base, accent.network, (ratio - 0.7) / 0.2)
    return blend(accent.network, accent.thermal, Math.min(1, (ratio - 0.9) / 0.1))
}

function blend(a, b, t) {
    var ca = Qt.color(a)
    var cb = Qt.color(b)
    return Qt.rgba(ca.r + (cb.r - ca.r) * t,
                   ca.g + (cb.g - ca.g) * t,
                   ca.b + (cb.b - ca.b) * t,
                   ca.a + (cb.a - ca.a) * t)
}

function alpha(color, a) {
    var c = Qt.color(color)
    return Qt.rgba(c.r, c.g, c.b, a)
}

function clamp01(v) {
    if (v === undefined || v === null || isNaN(v))
        return 0
    return Math.max(0, Math.min(1, v))
}

function percent(value) {
    if (value === undefined || value === null || isNaN(value))
        return "--"
    return Math.round(value) + "%"
}

/* Sensors report bytes; Plasma's own formatted values are locale aware but
   too long for tight rows, so short forms are built here. */
function bytes(value, decimals) {
    if (value === undefined || value === null || isNaN(value))
        return "--"
    var units = ["B", "KiB", "MiB", "GiB", "TiB", "PiB"]
    var i = 0
    var v = value
    while (v >= 1024 && i < units.length - 1) {
        v /= 1024
        i++
    }
    var d = decimals === undefined ? (v < 10 && i > 1 ? 1 : 0) : decimals
    return v.toFixed(d) + " " + units[i]
}

function rate(value) {
    if (value === undefined || value === null || isNaN(value))
        return "--"
    if (value < 1)
        return "0 B/s"
    return bytes(value, value >= 1024 * 1024 * 10 ? 0 : 1) + "/s"
}

/* "1.2M" — panel-sized rate, where a full "1.2 MiB/s" would not fit. */
function shortRate(value) {
    if (value === undefined || value === null || isNaN(value))
        return "--"
    if (value < 1024)
        return Math.round(value) + "B"
    var units = ["K", "M", "G", "T"]
    var v = value / 1024
    var i = 0
    while (v >= 1024 && i < units.length - 1) {
        v /= 1024
        i++
    }
    return (v >= 100 ? Math.round(v) : v.toFixed(1)) + units[i]
}

function hertz(value) {
    if (value === undefined || value === null || isNaN(value) || value <= 0)
        return "--"
    /* Sensors report MHz for CPU and GPU clocks. */
    if (value >= 1000)
        return (value / 1000).toFixed(2) + " GHz"
    return Math.round(value) + " MHz"
}

function celsius(value) {
    if (value === undefined || value === null || isNaN(value) || value <= 0)
        return "--"
    return Math.round(value) + "°"
}

function watts(value) {
    if (value === undefined || value === null || isNaN(value))
        return "--"
    return (value >= 100 ? Math.round(value) : value.toFixed(1)) + " W"
}

function uptime(seconds) {
    if (!seconds || isNaN(seconds))
        return "--"
    var d = Math.floor(seconds / 86400)
    var h = Math.floor((seconds % 86400) / 3600)
    var m = Math.floor((seconds % 3600) / 60)
    if (d > 0)
        return d + "d " + h + "h"
    if (h > 0)
        return h + "h " + m + "m"
    return m + "m"
}

/* "NVIDIA GeForce RTX 5070 Laptop GPU"   -> "GeForce RTX 5070"
   "GB206M [GeForce RTX 5070 Max-Q / Mobile]" -> "GeForce RTX 5070 Max-Q" */
function shortGpuName(name) {
    if (!name)
        return "GPU"
    var bracketed = String(name).match(/\[([^\]]+)\]/)
    var out = bracketed ? bracketed[1] : String(name)
    out = out.split("/")[0].trim()
    out = out.replace(/^(NVIDIA|AMD|ATI|Intel)\s+/i, "")
    out = out.replace(/\s+(Laptop|Mobile)?\s*GPU$/i, "")
    return out.trim()
}
