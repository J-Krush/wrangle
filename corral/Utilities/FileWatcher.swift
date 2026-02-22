import Foundation

/// Watches a directory for file system changes using GCD dispatch sources.
/// Events are debounced so rapid changes (git checkout, npm install) coalesce into a single callback.
final class FileWatcher {
    private let url: URL
    private let onChange: () -> Void
    private let debounceInterval: TimeInterval
    private let queue = DispatchQueue(label: "dev.corral.FileWatcher", qos: .utility)
    private var fileDescriptor: Int32 = -1
    private var dispatchSource: DispatchSourceFileSystemObject?
    private var debounceWorkItem: DispatchWorkItem?

    init(url: URL, debounceInterval: TimeInterval = 0.3, onChange: @escaping () -> Void) {
        self.url = url
        self.debounceInterval = debounceInterval
        self.onChange = onChange
    }

    deinit {
        // deinit is single-threaded by definition — safe to access directly
        debounceWorkItem?.cancel()
        dispatchSource?.cancel()
        if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
    }

    /// Begins watching the directory for write events.
    func start() {
        queue.async { self._start() }
    }

    /// Stops watching and releases the file descriptor.
    func stop() {
        queue.sync { self._stop() }
    }

    // MARK: - Private (always called on self.queue)

    private func _start() {
        // Avoid double-starting
        guard dispatchSource == nil else { return }

        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: queue
        )

        source.setEventHandler { [weak self] in
            guard let self else { return }
            self.debounceWorkItem?.cancel()
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.onChange()
                }
            }
            self.debounceWorkItem = work
            self.queue.asyncAfter(
                deadline: .now() + self.debounceInterval,
                execute: work
            )
        }

        source.setCancelHandler { [weak self] in
            guard let self else { return }
            if self.fileDescriptor >= 0 {
                close(self.fileDescriptor)
                self.fileDescriptor = -1
            }
        }

        dispatchSource = source
        source.resume()
    }

    private func _stop() {
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
        dispatchSource?.cancel()
        dispatchSource = nil
    }
}
