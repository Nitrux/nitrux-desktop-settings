pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

Singleton {
  id: root

  Component.onCompleted: {
    Logger.i("SoundService", "Service started");
  }

  /**
  * Play a sound file
  * @param soundPath - Path to the sound file (absolute, relative to shellDir, or just filename for Assets/Sounds/)
  * @param options - Optional object with:
  *   - volume: Volume level (0.0 to 1.0, default: 1.0)
  *   - fallback: Whether to fallback to default notification sound if file not found (default: false)
  *   - repeat: Whether to repeat/loop the sound continuously (default: false)
  */
  function playSound(soundPath, options) {
    if (!soundPath || soundPath === "") {
      Logger.w("SoundService", "No sound path provided");
      return;
    }

    const opts = options || {};
    const volume = opts.volume !== undefined ? opts.volume : 1.0;
    const fallback = opts.fallback !== undefined ? opts.fallback : false;
    const repeat = opts.repeat !== undefined ? opts.repeat : false;

    // Resolve path
    let resolvedPath = soundPath;

    // If it's just a filename (no path separators), assume it's in Assets/Sounds/
    if (!soundPath.includes("/") && !soundPath.startsWith("file://")) {
      resolvedPath = Quickshell.shellDir + "/Assets/Sounds/" + soundPath;
    } else if (!soundPath.startsWith("/") && !soundPath.startsWith("file://")) {
      // Relative path - assume it's relative to shellDir
      resolvedPath = Quickshell.shellDir + "/" + soundPath;
    } else if (soundPath.startsWith("file://")) {
      resolvedPath = soundPath.substring(7); // Remove "file://" prefix
    }
    // Absolute paths are used as-is

    // Build command with volume if supported
    const volumeArg = volume < 1.0 ? Math.round(volume * 100) : "";

    // Try different audio players in order of preference
    let command = "";

    if (repeat) {
      // Repeat mode - use mpv or ffplay with loop, or paplay in a while loop
      if (volumeArg && volumeArg > 0) {
        command = `mpv --no-video --really-quiet --loop=inf --volume=${volumeArg} "${resolvedPath}" 2>/dev/null || ffplay -nodisp -loop -1 -loglevel quiet -volume ${volumeArg} "${resolvedPath}" 2>/dev/null || (while true; do paplay --volume=${volumeArg} "${resolvedPath}" 2>/dev/null || break; done)`;
      } else {
        command = `mpv --no-video --really-quiet --loop=inf "${resolvedPath}" 2>/dev/null || ffplay -nodisp -loop -1 -loglevel quiet "${resolvedPath}" 2>/dev/null || (while true; do paplay "${resolvedPath}" 2>/dev/null || break; done)`;
      }
    } else {
      // Normal play once mode
      if (volumeArg && volumeArg > 0) {
        command = `paplay --volume=${volumeArg} "${resolvedPath}" 2>/dev/null || mpv --no-video --really-quiet --volume=${volumeArg} "${resolvedPath}" 2>/dev/null || ffplay -nodisp -autoexit -loglevel quiet -volume ${volumeArg} "${resolvedPath}" 2>/dev/null`;
      } else {
        command = `paplay "${resolvedPath}" 2>/dev/null || mpv --no-video --really-quiet "${resolvedPath}" 2>/dev/null || ffplay -nodisp -autoexit -loglevel quiet "${resolvedPath}" 2>/dev/null`;
      }
    }

    // Add fallback to default notification sound if requested (only in non-repeat mode)
    if (fallback && !repeat) {
      const defaultSound = Quickshell.shellDir + "/Assets/Sounds/notification.mp3";
      if (volumeArg && volumeArg > 0) {
        command += ` || paplay --volume=${volumeArg} "${defaultSound}" 2>/dev/null || mpv --no-video --really-quiet --volume=${volumeArg} "${defaultSound}" 2>/dev/null || ffplay -nodisp -autoexit -loglevel quiet -volume ${volumeArg} "${defaultSound}" 2>/dev/null`;
      } else {
        command += ` || paplay "${defaultSound}" 2>/dev/null || mpv --no-video --really-quiet "${defaultSound}" 2>/dev/null || ffplay -nodisp -autoexit -loglevel quiet "${defaultSound}" 2>/dev/null`;
      }
    }

    command += " || true"; // Always succeed

    Logger.d("SoundService", "Playing sound:", resolvedPath, volumeArg ? `(volume: ${volumeArg}%)` : "", repeat ? "(repeat)" : "");
    Quickshell.execDetached(["sh", "-c", command]);
  }

  /**
  * Stop a playing sound by killing the audio player processes
  * @param soundPath - Path to the sound file to stop (optional, if not provided stops all notification sounds)
  */
  function stopSound(soundPath) {
    let resolvedPath = soundPath;

    if (soundPath) {
      // Resolve path the same way as playSound
      if (!soundPath.includes("/") && !soundPath.startsWith("file://")) {
        resolvedPath = Quickshell.shellDir + "/Assets/Sounds/" + soundPath;
      } else if (!soundPath.startsWith("/") && !soundPath.startsWith("file://")) {
        resolvedPath = Quickshell.shellDir + "/" + soundPath;
      } else if (soundPath.startsWith("file://")) {
        resolvedPath = soundPath.substring(7);
      }

      // Kill processes playing this specific sound file
      const command = `pkill -f "mpv.*${resolvedPath}" 2>/dev/null; pkill -f "ffplay.*${resolvedPath}" 2>/dev/null; pkill -f "paplay.*${resolvedPath}" 2>/dev/null; true`;
      Logger.d("SoundService", "Stopping sound:", resolvedPath);
      Quickshell.execDetached(["sh", "-c", command]);
    } else {
      // Kill all mpv/ffplay/paplay processes (be careful with this)
      const command = `pkill -f "mpv.*--loop=inf" 2>/dev/null; pkill -f "ffplay.*-loop" 2>/dev/null; pkill -f "while true.*paplay" 2>/dev/null; true`;
      Logger.d("SoundService", "Stopping all repeating sounds");
      Quickshell.execDetached(["sh", "-c", command]);
    }
  }
}
