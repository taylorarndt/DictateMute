import CoreAudio
import Darwin
import Foundation

/// Finds out which processes are recording from a microphone, using Core Audio's
/// per-process objects (macOS 14.2 and later). No microphone access is needed for this,
/// and no audio is ever read.
enum MicMonitor {
    /// True when Claude Code, or a helper it started, is recording.
    static func claudeCodeIsListening() -> Bool {
        pidsUsingMicrophone().contains(where: isClaudeCode)
    }

    static func pidsUsingMicrophone() -> [pid_t] {
        var result: [pid_t] = []
        for object in processObjects() {
            guard let running: UInt32 = property(object, kAudioProcessPropertyIsRunningInput, UInt32(0)),
                  running != 0,
                  let pid: pid_t = property(object, kAudioProcessPropertyPID, pid_t(0)) else { continue }
            result.append(pid)
        }
        return result
    }

    /// Claude Code runs as a binary named "claude", or as a versioned binary inside
    /// ~/.local/share/claude/versions/. We also walk up a few parents in case it records
    /// through a helper such as SoX.
    static func isClaudeCode(_ pid: pid_t) -> Bool {
        var current = pid
        for _ in 0..<6 {
            guard current > 1 else { return false }
            if name(of: current).lowercased() == "claude" || path(of: current).contains("/claude/versions/") {
                return true
            }
            current = parent(of: current)
        }
        return false
    }

    // MARK: Helpers

    private static func processObjects() -> [AudioObjectID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyProcessObjectList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        let system = AudioObjectID(kAudioObjectSystemObject)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr else { return [] }
        var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(system, &address, 0, nil, &size, &ids) == noErr else { return [] }
        return ids
    }

    private static func property<T: FixedWidthInteger>(_ object: AudioObjectID, _ selector: AudioObjectPropertySelector, _ initial: T) -> T? {
        var address = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var value = initial
        var size = UInt32(MemoryLayout<T>.size)
        return AudioObjectGetPropertyData(object, &address, 0, nil, &size, &value) == noErr ? value : nil
    }

    private static func name(of pid: pid_t) -> String {
        var buffer = [CChar](repeating: 0, count: 1024)
        proc_name(pid, &buffer, UInt32(buffer.count))
        return String(cString: buffer)
    }

    private static func path(of pid: pid_t) -> String {
        var buffer = [CChar](repeating: 0, count: 4096)
        return proc_pidpath(pid, &buffer, UInt32(buffer.count)) > 0 ? String(cString: buffer) : ""
    }

    private static func parent(of pid: pid_t) -> pid_t {
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        return proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size ? pid_t(info.pbi_ppid) : 0
    }
}
