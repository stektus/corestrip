.pragma library

/* macOS-inspired accent palette, one hue per domain. */
var accent = {
    time: "#0a84ff",
    weather: "#ff9f0a",
    calendar: "#ff375f",
    event: "#30d158",
    night: "#5e5ce6"
}

function alpha(color, a) {
    var c = Qt.color(color)
    return Qt.rgba(c.r, c.g, c.b, a)
}

// ----------------------------------------------------------------- clock ---

function pad(value) {
    return value < 10 ? "0" + value : String(value)
}

function formatTime(date, use24Hour, withSeconds) {
    if (!date)
        return "--:--"
    var hours = date.getHours()
    var suffix = ""
    if (!use24Hour) {
        suffix = hours < 12 ? " AM" : " PM"
        hours = hours % 12
        if (hours === 0)
            hours = 12
    }
    var out = (use24Hour ? pad(hours) : String(hours)) + ":" + pad(date.getMinutes())
    if (withSeconds)
        out += ":" + pad(date.getSeconds())
    return out + suffix
}

var monthNames = ["January", "February", "March", "April", "May", "June",
                  "July", "August", "September", "October", "November", "December"]
var monthShort = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
var dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
var dayShort = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

function formatDate(date, style) {
    if (!date)
        return ""
    switch (style) {
    case "full":
        return dayNames[date.getDay()] + ", " + date.getDate() + " " + monthNames[date.getMonth()]
    case "iso":
        return date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate())
    default:
        return date.getDate() + " " + monthShort[date.getMonth()]
    }
}

function weekday(date, short) {
    if (!date)
        return ""
    return short ? dayShort[date.getDay()] : dayNames[date.getDay()]
}

function sameDay(a, b) {
    return a && b
        && a.getFullYear() === b.getFullYear()
        && a.getMonth() === b.getMonth()
        && a.getDate() === b.getDate()
}

function startOfDay(date) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate())
}

function addDays(date, days) {
    var out = new Date(date.getTime())
    out.setDate(out.getDate() + days)
    return out
}

/* "in 20 min", "in 3 h", "now", "yesterday" — relative wording for the agenda. */
function relativeDay(date, today) {
    var diff = Math.round((startOfDay(date) - startOfDay(today)) / 86400000)
    if (diff === 0)
        return "Today"
    if (diff === 1)
        return "Tomorrow"
    if (diff === -1)
        return "Yesterday"
    if (diff > 1 && diff < 7)
        return dayNames[date.getDay()]
    return formatDate(date, "compact")
}

// --------------------------------------------------------------- weather ---

/* WMO weather codes as used by Open-Meteo. */
function weatherLabel(code) {
    switch (code) {
    case 0: return "Clear"
    case 1: return "Mainly clear"
    case 2: return "Partly cloudy"
    case 3: return "Overcast"
    case 45: case 48: return "Fog"
    case 51: case 53: case 55: return "Drizzle"
    case 56: case 57: return "Freezing drizzle"
    case 61: return "Light rain"
    case 63: return "Rain"
    case 65: return "Heavy rain"
    case 66: case 67: return "Freezing rain"
    case 71: return "Light snow"
    case 73: return "Snow"
    case 75: return "Heavy snow"
    case 77: return "Snow grains"
    case 80: case 81: return "Rain showers"
    case 82: return "Heavy showers"
    case 85: case 86: return "Snow showers"
    case 95: return "Thunderstorm"
    case 96: case 99: return "Thunderstorm with hail"
    }
    return "—"
}

function temperature(value, unit) {
    if (value === undefined || value === null || isNaN(value))
        return "--"
    return Math.round(value) + "°" + (unit === "fahrenheit" ? "F" : "")
}

function wind(value, unit) {
    if (value === undefined || value === null || isNaN(value))
        return "--"
    switch (unit) {
    case "ms": return (value / 3.6).toFixed(1) + " m/s"
    case "mph": return Math.round(value) + " mph"
    default: return Math.round(value) + " km/h"
    }
}

function percent(value) {
    if (value === undefined || value === null || isNaN(value))
        return "--"
    return Math.round(value) + "%"
}
