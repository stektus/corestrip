/*
 * Everything the widget knows: the clock, the weather forecast and the events
 * read from iCalendar feeds.
 *
 * Network work is deliberately lazy — weather refreshes on its own schedule,
 * calendars on theirs, and both refresh immediately when the popup opens with
 * stale data rather than polling hard in the background.
 */
import QtQuick
import "../code/util.js" as Util
import "../code/ical.js" as ICal

QtObject {
    id: backend

    property bool detailed: false
    property bool showSeconds: false

    // ------------------------------------------------------------- clock ---
    property date now: new Date()

    readonly property Timer clock: Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var stamp = new Date()
            /* Without seconds on screen there is nothing to redraw until the
               minute rolls over. */
            if (backend.showSeconds
                    || stamp.getMinutes() !== backend.now.getMinutes()
                    || stamp.getHours() !== backend.now.getHours()
                    || stamp.getDate() !== backend.now.getDate())
                backend.now = stamp
        }
    }

    // ----------------------------------------------------------- weather ---
    property string locationName: ""
    property real latitude: 0
    property real longitude: 0
    property string temperatureUnit: "celsius"
    property string windUnit: "kmh"
    property int weatherIntervalMinutes: 15

    readonly property bool hasLocation: Math.abs(latitude) > 0.0001 || Math.abs(longitude) > 0.0001

    property var weather: null          /* { temperature, apparent, humidity, code, wind, isDay } */
    property var forecast: []           /* [{ date, code, high, low, precipitation }] */
    property var sunTimes: null         /* { sunrise, sunset } */
    property bool weatherLoading: false
    property string weatherError: ""
    property date weatherUpdated: new Date(0)

    function weatherUrl() {
        return "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + latitude.toFixed(4)
            + "&longitude=" + longitude.toFixed(4)
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,is_day"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset"
            + "&timezone=auto&forecast_days=7"
            + "&temperature_unit=" + (temperatureUnit === "fahrenheit" ? "fahrenheit" : "celsius")
            + "&wind_speed_unit=" + (windUnit === "ms" ? "ms" : (windUnit === "mph" ? "mph" : "kmh"))
    }

    function refreshWeather() {
        if (!hasLocation || weatherLoading)
            return

        weatherLoading = true
        var request = new XMLHttpRequest()
        request.open("GET", weatherUrl())
        request.onreadystatechange = function () {
            if (request.readyState !== XMLHttpRequest.DONE)
                return

            backend.weatherLoading = false
            if (request.status !== 200) {
                backend.weatherError = "Weather service unavailable (" + request.status + ")"
                return
            }

            try {
                var data = JSON.parse(request.responseText)
                backend.weather = {
                    temperature: data.current.temperature_2m,
                    apparent: data.current.apparent_temperature,
                    humidity: data.current.relative_humidity_2m,
                    code: data.current.weather_code,
                    wind: data.current.wind_speed_10m,
                    isDay: data.current.is_day === 1
                }

                var days = []
                for (var i = 0; i < data.daily.time.length; i++) {
                    var parts = data.daily.time[i].split("-")
                    days.push({
                        date: new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2])),
                        code: data.daily.weather_code[i],
                        high: data.daily.temperature_2m_max[i],
                        low: data.daily.temperature_2m_min[i],
                        precipitation: data.daily.precipitation_probability_max[i]
                    })
                }
                backend.forecast = days
                backend.sunTimes = {
                    sunrise: data.daily.sunrise[0].split("T")[1],
                    sunset: data.daily.sunset[0].split("T")[1]
                }
                backend.weatherError = ""
                backend.weatherUpdated = new Date()
            } catch (error) {
                backend.weatherError = "Could not read the forecast"
            }
        }
        request.send()
    }

    readonly property Timer weatherTimer: Timer {
        interval: Math.max(5, backend.weatherIntervalMinutes) * 60000
        running: backend.hasLocation
        repeat: true
        triggeredOnStart: true
        onTriggered: backend.refreshWeather()
    }

    // ---------------------------------------------------------- calendar ---
    /* Feed URLs are secrets: they are never logged, only handed to the request. */
    property var calendarSources: []    /* [{ name, url, color }] */
    property int calendarIntervalMinutes: 30

    property var rawEvents: []
    property var occurrences: []
    property bool calendarLoading: false
    property string calendarError: ""
    property date calendarUpdated: new Date(0)
    property int calendarRevision: 0

    property date rangeStart: new Date(now.getFullYear(), now.getMonth() - 1, 1)
    property date rangeEnd: new Date(now.getFullYear(), now.getMonth() + 2, 1)

    readonly property var eventColors: [
        "#ff375f", "#0a84ff", "#30d158", "#bf5af2", "#ff9f0a"
    ]

    function refreshCalendars() {
        if (calendarLoading || calendarSources.length === 0) {
            if (calendarSources.length === 0) {
                rawEvents = []
                occurrences = []
                calendarRevision++
            }
            return
        }

        calendarLoading = true
        var collected = []
        var pending = calendarSources.length
        var failures = 0

        var finish = function () {
            pending--
            if (pending > 0)
                return
            backend.calendarLoading = false
            backend.rawEvents = collected
            backend.expandRange()
            backend.calendarUpdated = new Date()
            backend.calendarError = failures > 0
                ? (failures === 1 ? "One calendar could not be read"
                                  : failures + " calendars could not be read")
                : ""
        }

        for (var i = 0; i < calendarSources.length; i++) {
            (function (source, index) {
                var request = new XMLHttpRequest()
                request.open("GET", source.url)
                request.onreadystatechange = function () {
                    if (request.readyState !== XMLHttpRequest.DONE)
                        return
                    if (request.status === 200) {
                        try {
                            var parsed = ICal.parseCalendar(
                                request.responseText,
                                source.name || ("Calendar " + (index + 1)),
                                source.color)
                            collected = collected.concat(parsed)
                        } catch (error) {
                            failures++
                        }
                    } else {
                        failures++
                    }
                    finish()
                }
                request.send()
            })(calendarSources[i], i)
        }
    }

    function expandRange() {
        occurrences = ICal.expand(rawEvents, rangeStart, rangeEnd)
        calendarRevision++
    }

    function eventsOn(date) {
        var out = []
        for (var i = 0; i < occurrences.length; i++) {
            var event = occurrences[i]
            if (Util.sameDay(event.start, date)
                    || (event.allDay && event.start <= date && event.end > date))
                out.push(event)
        }
        return out
    }

    function upcoming(limit) {
        var out = []
        var reference = new Date(now.getTime() - 30 * 60000)
        for (var i = 0; i < occurrences.length && out.length < limit; i++) {
            if (occurrences[i].end >= reference)
                out.push(occurrences[i])
        }
        return out
    }

    readonly property Timer calendarTimer: Timer {
        interval: Math.max(5, backend.calendarIntervalMinutes) * 60000
        running: backend.calendarSources.length > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: backend.refreshCalendars()
    }

    /* Opening the popup is a good moment to catch up if data went stale. */
    onDetailedChanged: {
        if (!detailed)
            return
        var age = new Date().getTime()
        if (hasLocation && age - weatherUpdated.getTime() > weatherIntervalMinutes * 60000)
            refreshWeather()
        if (calendarSources.length > 0 && age - calendarUpdated.getTime() > calendarIntervalMinutes * 60000)
            refreshCalendars()
    }

    onCalendarSourcesChanged: refreshCalendars()
    onRangeStartChanged: expandRange()
}
