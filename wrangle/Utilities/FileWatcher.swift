import Foundation

/// Watches a directory tree for file system changes using the FSEvents API.
/// Recursively monitors all subdirectories — the same mechanism Finder uses.
/// Events are debounced so rapid changes (git checkout, npm install) coalesce into a single callback.
final class FileWatcher {
    private let url: URL
    private let onChange: () -> Void
    private let debounceInterval: TimeInterval
    private let queue = DispatchQueue(label: "dev.Wrangle.FileWatcher", qos: .utility)
    private var eventStream: FSEventStreamRef?
    private var debounceWorkItem: DispatchWorkItem?

    init(url: URL, debounceInterval: TimeInterval = 0.3, onChange: @escaping () -> Void) {
        self.url = url
        self.debounceInterval = debounceInterval
        self.onChange = onChange
    }

    deinit {
        // deinit is single-threaded by definition — safe to call directly
        _stop()
    }

    /// Begins watching the directory tree for changes.
    func start() {
        queue.async { self._start() }
    }

    /// Stops watching and releases the event stream.
    func stop() {
        queue.sync { self._stop() }
    }

    // MARK: - Private (always called on self.queue)

    private func _start() {
        guard eventStream == nil else { return }

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let paths = [url.path as CFString] as CFArray

        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            FileWatcher.eventCallback,
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.1, // FSEvents-level latency — first coalescing layer
            UInt32(kFSEventStreamCreateFlagNoDefer | kFSEventStreamCreateFlagFileEvents)
        ) else { return }

        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
        eventStream = stream
    }

    private func _stop() {
        debounceWorkItem?.cancel()
        debounceWorkItem = nil

        if let stream = eventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            eventStream = nil
        }
    }

    // MARK: - FSEvents Callback

    private static let eventCallback: FSEventStreamCallback = {
        _, clientCallBackInfo, _, _, _, _ in
        guard let info = clientCallBackInfo else { return }
        let watcher = Unmanaged<FileWatcher>.fromOpaque(info).takeUnretainedValue()
        watcher.handleEvent()
    }

    /// Second debounce layer — coalesces bursts of FSEvents into a single callback.
    private func handleEvent() {
        debounceWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let callback = self.onChange
            Task { @MainActor in
                callback()
            }
        }
        debounceWorkItem = work
        queue.asyncAfter(deadline: .now() + debounceInterval, execute: work)
    }
}
