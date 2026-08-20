/*
 * Formatting and the colour palette, shared by every view.
 */
.pragma library

/* macOS-ish accents, the same family the other widgets in this collection use. */
var accent = {
    media: "#ff375f",
    wave: "#5ac8fa",
    glow: "#bf5af2",
    play: "#30d158",
    quiet: "#8e8e93"
}

function clamp01(value) {
    if (isNaN(value))
        return 0
    return Math.max(0, Math.min(1, value))
}

/* MPRIS reports microseconds. */
function duration(microseconds) {
    if (!microseconds || microseconds <= 0)
        return "0:00"
    var total = Math.floor(microseconds / 1000000)
    var hours = Math.floor(total / 3600)
    var minutes = Math.floor((total % 3600) / 60)
    var seconds = total % 60
    var pad = seconds < 10 ? "0" : ""
    if (hours > 0)
        return hours + ":" + (minutes < 10 ? "0" : "") + minutes + ":" + pad + seconds
    return minutes + ":" + pad + seconds
}

function remaining(position, length) {
    if (!length || length <= 0)
        return ""
    return "-" + duration(Math.max(0, length - position))
}

/* One line for tooltips and the panel when only a single line fits. */
function oneLine(track, artist) {
    if (track && artist)
        return artist + " — " + track
    return track || artist || ""
}

/* Stable per-track seed, so the equalizer does not restart identically for
   every song while still being deterministic within one. */
function seedOf(text) {
    var seed = 2166136261
    for (var i = 0; i < text.length; i++) {
        seed ^= text.charCodeAt(i)
        seed = (seed * 16777619) >>> 0
    }
    return seed
}

/* Deterministic pseudo-random in [0, 1) — no Math.random, so a repaint never
   changes what an already drawn frame looked like. */
function noise(seed, a, b) {
    var value = (seed ^ (a * 374761393) ^ (b * 668265263)) >>> 0
    value = (value ^ (value >>> 13)) >>> 0
    value = (value * 1274126177) >>> 0
    return ((value ^ (value >>> 16)) >>> 0) / 4294967296
}

/* Colours picked out of a cover can be muddy or nearly black; the equalizer
   needs something that reads against a panel. Keeps the hue, insists on a
   usable saturation and lightness. */
function lively(source, fallback) {
    if (!source || source.a === 0)
        return fallback
    var saturation = Math.max(source.hslSaturation, 0.45)
    var lightness = Math.min(Math.max(source.hslLightness, 0.5), 0.72)
    return Qt.hsla(source.hslHue, saturation, lightness, 1)
}
