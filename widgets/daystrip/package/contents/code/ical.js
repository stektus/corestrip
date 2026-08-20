.pragma library

/*
 * Minimal iCalendar (RFC 5545) reader: enough for the feeds Google, Nextcloud
 * and Outlook publish as "secret address in iCal format".
 *
 * Deliberately not supported: VTIMEZONE definitions (a TZID is read as local
 * time, which is right whenever the calendar and the machine share a zone),
 * and the more exotic recurrence rules (BYSETPOS, BYWEEKNO, BYYEARDAY).
 */

function unfold(text) {
    /* Continuation lines start with a space or tab and belong to the line above. */
    return String(text).replace(/\r\n/g, "\n").replace(/\r/g, "\n").replace(/\n[ \t]/g, "")
}

function unescapeText(value) {
    return String(value)
        .replace(/\\n/gi, " ")
        .replace(/\\,/g, ",")
        .replace(/\;/g, ";")
        .replace(/\\\\/g, "\\")
        .trim()
}

function parseProperty(line) {
    var colon = line.indexOf(":")
    if (colon < 0)
        return null

    var head = line.substring(0, colon)
    var value = line.substring(colon + 1)
    var pieces = head.split(";")
    var params = {}

    for (var i = 1; i < pieces.length; i++) {
        var eq = pieces[i].indexOf("=")
        if (eq > 0)
            params[pieces[i].substring(0, eq).toUpperCase()] = pieces[i].substring(eq + 1)
    }

    return { name: pieces[0].toUpperCase(), params: params, value: value }
}

/* "20260820", "20260820T103000Z" or "20260820T103000" (+TZID). */
function parseDate(value, params) {
    var raw = String(value).trim()
    var match = raw.match(/^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z)?)?$/)
    if (!match)
        return null

    var year = parseInt(match[1], 10)
    var month = parseInt(match[2], 10) - 1
    var day = parseInt(match[3], 10)

    if (match[4] === undefined)
        return { date: new Date(year, month, day), allDay: true }

    var hour = parseInt(match[4], 10)
    var minute = parseInt(match[5], 10)
    var second = parseInt(match[6], 10)

    if (match[7] === "Z")
        return { date: new Date(Date.UTC(year, month, day, hour, minute, second)), allDay: false }

    return { date: new Date(year, month, day, hour, minute, second), allDay: false }
}

function parseRule(value) {
    var rule = { freq: "", interval: 1, count: 0, until: null, byDay: [], byMonthDay: [] }
    var parts = String(value).split(";")

    for (var i = 0; i < parts.length; i++) {
        var eq = parts[i].indexOf("=")
        if (eq < 0)
            continue
        var key = parts[i].substring(0, eq).toUpperCase()
        var val = parts[i].substring(eq + 1)

        switch (key) {
        case "FREQ":
            rule.freq = val.toUpperCase()
            break
        case "INTERVAL":
            rule.interval = Math.max(1, parseInt(val, 10) || 1)
            break
        case "COUNT":
            rule.count = parseInt(val, 10) || 0
            break
        case "UNTIL":
            var until = parseDate(val, {})
            rule.until = until ? until.date : null
            break
        case "BYDAY":
            rule.byDay = val.toUpperCase().split(",").map(function (day) {
                return day.replace(/^[+-]?\d+/, "")
            })
            break
        case "BYMONTHDAY":
            rule.byMonthDay = val.split(",").map(function (day) { return parseInt(day, 10) })
            break
        }
    }

    return rule.freq ? rule : null
}

/* Returns raw events; recurrences are expanded later, per visible range. */
function parseCalendar(text, calendarName, color) {
    var lines = unfold(text).split("\n")
    var events = []
    var current = null

    for (var i = 0; i < lines.length; i++) {
        var line = lines[i]
        if (line === "BEGIN:VEVENT") {
            current = { summary: "", location: "", start: null, end: null,
                        allDay: false, rule: null, exceptions: [],
                        calendar: calendarName, color: color }
            continue
        }
        if (line === "END:VEVENT") {
            if (current && current.start) {
                if (!current.end)
                    current.end = new Date(current.start.getTime() + (current.allDay ? 86400000 : 3600000))
                events.push(current)
            }
            current = null
            continue
        }
        if (!current)
            continue

        var property = parseProperty(line)
        if (!property)
            continue

        switch (property.name) {
        case "SUMMARY":
            current.summary = unescapeText(property.value)
            break
        case "LOCATION":
            current.location = unescapeText(property.value)
            break
        case "DTSTART":
            var start = parseDate(property.value, property.params)
            if (start) {
                current.start = start.date
                current.allDay = start.allDay || property.params["VALUE"] === "DATE"
            }
            break
        case "DTEND":
            var end = parseDate(property.value, property.params)
            if (end)
                current.end = end.date
            break
        case "RRULE":
            current.rule = parseRule(property.value)
            break
        case "EXDATE":
            var dates = property.value.split(",")
            for (var d = 0; d < dates.length; d++) {
                var exception = parseDate(dates[d], property.params)
                if (exception)
                    current.exceptions.push(exception.date.getTime())
            }
            break
        }
    }

    return events
}

var weekdayCodes = ["SU", "MO", "TU", "WE", "TH", "FR", "SA"]

function shiftByFreq(date, rule, steps) {
    var out = new Date(date.getTime())
    switch (rule.freq) {
    case "DAILY":
        out.setDate(out.getDate() + rule.interval * steps)
        break
    case "WEEKLY":
        out.setDate(out.getDate() + 7 * rule.interval * steps)
        break
    case "MONTHLY":
        out.setMonth(out.getMonth() + rule.interval * steps)
        break
    case "YEARLY":
        out.setFullYear(out.getFullYear() + rule.interval * steps)
        break
    default:
        return null
    }
    return out
}

function occurrence(event, start) {
    var length = event.end.getTime() - event.start.getTime()
    return {
        summary: event.summary,
        location: event.location,
        allDay: event.allDay,
        calendar: event.calendar,
        color: event.color,
        start: start,
        end: new Date(start.getTime() + length)
    }
}

/* Expands events into concrete occurrences inside [rangeStart, rangeEnd). */
function expand(events, rangeStart, rangeEnd) {
    var out = []
    var guard = 0

    for (var i = 0; i < events.length; i++) {
        var event = events[i]

        if (!event.rule) {
            if (event.end > rangeStart && event.start < rangeEnd)
                out.push(occurrence(event, new Date(event.start.getTime())))
            continue
        }

        var rule = event.rule
        var emitted = 0

        /* Yearly birthdays often start decades ago; skip straight to the
           visible range instead of walking every period. COUNT rules have to
           be counted from the beginning, so those start at zero. */
        var firstStep = 0
        if (!rule.count && event.start < rangeStart) {
            var elapsed = rangeStart - event.start
            switch (rule.freq) {
            case "DAILY":
                firstStep = Math.floor(elapsed / (86400000 * rule.interval))
                break
            case "WEEKLY":
                firstStep = Math.floor(elapsed / (604800000 * rule.interval))
                break
            case "MONTHLY":
                firstStep = Math.floor(((rangeStart.getFullYear() - event.start.getFullYear()) * 12
                                        + rangeStart.getMonth() - event.start.getMonth()) / rule.interval)
                break
            case "YEARLY":
                firstStep = Math.floor((rangeStart.getFullYear() - event.start.getFullYear()) / rule.interval)
                break
            }
            firstStep = Math.max(0, firstStep - 1)
        }

        for (var step = firstStep; step < firstStep + 800; step++) {
            var base = shiftByFreq(event.start, rule, step)
            if (!base)
                break
            if (base >= rangeEnd && !(rule.freq === "WEEKLY" && rule.byDay.length > 0))
                break
            if (rule.until && base > rule.until)
                break
            if (rule.count && emitted >= rule.count)
                break

            var candidates = [base]
            if (rule.freq === "WEEKLY" && rule.byDay.length > 0) {
                candidates = []
                var weekStart = new Date(base.getTime())
                weekStart.setDate(weekStart.getDate() - weekStart.getDay())
                for (var d = 0; d < 7; d++) {
                    if (rule.byDay.indexOf(weekdayCodes[d]) < 0)
                        continue
                    var day = new Date(weekStart.getTime())
                    day.setDate(day.getDate() + d)
                    day.setHours(base.getHours(), base.getMinutes(), base.getSeconds(), 0)
                    if (day >= event.start)
                        candidates.push(day)
                }
            }

            for (var c = 0; c < candidates.length; c++) {
                var candidate = candidates[c]
                if (rule.until && candidate > rule.until)
                    continue
                if (rule.count && emitted >= rule.count)
                    break
                if (event.exceptions.indexOf(candidate.getTime()) >= 0)
                    continue

                emitted++
                guard++
                if (candidate < rangeEnd && candidate >= new Date(rangeStart.getTime() - 86400000))
                    out.push(occurrence(event, candidate))
            }

            if (guard > 5000)
                break
        }
    }

    out.sort(function (a, b) { return a.start - b.start })
    return out
}
