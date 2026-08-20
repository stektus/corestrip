/*
 * Everything the widget knows about what is playing.
 *
 * The source is MPRIS2 — the same bus interface Plasma's own media controls
 * read, so anything that announces itself there is understood: browsers
 * through plasma-browser-integration, VLC, Elisa, Spotify, mpv with an MPRIS
 * plugin, and the rest.
 *
 * Position is the only value nobody pushes: MPRIS players report it on demand.
 * It is therefore polled, but only while something plays and only while a view
 * actually shows it.
 */
import QtQuick
import org.kde.plasma.private.mpris as Mpris

QtObject {
    id: backend

    /* Set by the popup; enables the expensive parts. */
    property bool detailed: false
    /* Set by the panel when it draws a progress line. */
    property bool tracksPosition: false

    readonly property Mpris.Mpris2Model sources: Mpris.Mpris2Model {}

    readonly property var player: sources.currentPlayer
    readonly property bool hasPlayer: player !== null && player !== undefined

    readonly property int status: hasPlayer ? player.playbackStatus : Mpris.PlaybackStatus.Stopped
    readonly property bool playing: status === Mpris.PlaybackStatus.Playing
    readonly property bool paused: status === Mpris.PlaybackStatus.Paused
    /* "Something is loaded", as opposed to a player that sits there stopped. */
    readonly property bool active: hasPlayer && (playing || paused)

    readonly property string track: hasPlayer && player.track ? player.track : ""
    readonly property string artist: hasPlayer && player.artist ? player.artist : ""
    readonly property string album: hasPlayer && player.album ? player.album : ""
    readonly property string artUrl: hasPlayer && player.artUrl ? player.artUrl : ""
    readonly property string identity: hasPlayer && player.identity ? player.identity : ""
    readonly property string playerIcon: hasPlayer && player.iconName ? player.iconName : "media-playback-start"

    readonly property real length: hasPlayer && player.length > 0 ? player.length : 0
    property real position: 0
    readonly property real progress: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0

    readonly property bool canControl: hasPlayer && player.canControl
    readonly property bool canGoNext: hasPlayer && player.canGoNext
    readonly property bool canGoPrevious: hasPlayer && player.canGoPrevious
    readonly property bool canSeek: hasPlayer && player.canSeek && length > 0
    readonly property bool canRaise: hasPlayer && player.canRaise

    readonly property real volume: hasPlayer ? player.volume : 0
    readonly property bool shuffled: hasPlayer && player.shuffle === Mpris.ShuffleStatus.On
    readonly property int loop: hasPlayer ? player.loopStatus : Mpris.LoopStatus.None

    readonly property string loopLabel: {
        switch (loop) {
        case Mpris.LoopStatus.Track: return "Repeat track"
        case Mpris.LoopStatus.Playlist: return "Repeat playlist"
        default: return "No repeat"
        }
    }
    readonly property string loopIcon: {
        switch (loop) {
        case Mpris.LoopStatus.Track: return "media-playlist-repeat-song"
        case Mpris.LoopStatus.Playlist: return "media-playlist-repeat"
        default: return "media-playlist-repeat"
        }
    }

    // ---------------------------------------------------------- position ---
    /* Asking a player where it is costs a D-Bus round trip, so it happens only
       while playing and only while something on screen shows the number. */
    readonly property Timer positionTimer: Timer {
        interval: backend.detailed ? 1000 : 2000
        repeat: true
        running: backend.playing && (backend.detailed || backend.tracksPosition)
        triggeredOnStart: true
        onTriggered: {
            if (!backend.hasPlayer)
                return
            backend.player.updatePosition()
            backend.position = backend.player.position
        }
    }

    /* A seek or a track change reports itself; catch those without polling. */
    readonly property Connections playerWatch: Connections {
        target: backend.player
        ignoreUnknownSignals: true

        function onPositionChanged() {
            backend.position = backend.player.position
        }
        function onTrackChanged() {
            backend.position = 0
            if (backend.hasPlayer)
                backend.player.updatePosition()
        }
        function onPlaybackStatusChanged() {
            if (backend.hasPlayer) {
                backend.player.updatePosition()
                backend.position = backend.player.position
            }
        }
    }

    onDetailedChanged: {
        if (detailed && hasPlayer) {
            player.updatePosition()
            position = player.position
        }
    }

    // ----------------------------------------------------------- actions ---
    function playPause() {
        if (hasPlayer && canControl)
            player.PlayPause()
    }

    function next() {
        if (canGoNext)
            player.Next()
    }

    function previous() {
        if (canGoPrevious)
            player.Previous()
    }

    function stop() {
        if (hasPlayer && canControl)
            player.Stop()
    }

    function seekFraction(fraction) {
        if (!canSeek)
            return
        player.position = Math.round(Math.max(0, Math.min(1, fraction)) * length)
        position = player.position
    }

    function setVolume(value) {
        if (hasPlayer)
            player.volume = Math.max(0, Math.min(1, value))
    }

    function nudgeVolume(delta) {
        if (hasPlayer)
            player.volume = Math.max(0, Math.min(1, player.volume + delta))
    }

    function toggleShuffle() {
        if (hasPlayer)
            player.shuffle = shuffled ? Mpris.ShuffleStatus.Off : Mpris.ShuffleStatus.On
    }

    function cycleLoop() {
        if (!hasPlayer)
            return
        switch (loop) {
        case Mpris.LoopStatus.Playlist:
            player.loopStatus = Mpris.LoopStatus.Track
            break
        case Mpris.LoopStatus.Track:
            player.loopStatus = Mpris.LoopStatus.None
            break
        default:
            player.loopStatus = Mpris.LoopStatus.Playlist
        }
    }

    function raisePlayer() {
        if (canRaise)
            player.Raise()
    }

    function selectPlayer(index) {
        sources.currentIndex = index
    }
}
