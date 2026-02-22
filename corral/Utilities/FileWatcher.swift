import Foundation

/// Watches a directory for file system changes using GCD dispatch sources.
/// Events are debounced so rapid changes (git checkout, npm install) coalesce into a single callback.
final class FileWatcher {
    private let url: URL
    private let onChange: () -> Void
    private var fileDescriptor: Int32 = -1
    private nonisolated(unsafe) var dispatchSource: DispatchSourceFileSystemObject?
    private nonisolated(unsafe) var debounceWorkItem: DispatchWorkItem?
    private let debounceInterval: TimeInterval

    init(url: URL, debounceInterval: TimeInterval = 0.3, onChange: @escaping () -> Void) {
        self.url = url
        self.debounceInterval = debounceInterval
        self.onChange = onChange
    }

    deinit {
        debounceWorkItem?.cancel()
        dispatchSource?.cancel()
        if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
    }

    /// Begins watching the directory for write events.
    func start() {
        // Avoid double-starting
        guard dispatchSource == nil else { return }

        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: DispatchQueue.global(qos: .utility)
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
            DispatchQueue.global(qos: .utility).asyncAfter(
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

    /// Stops watching and releases the file descriptor.
    func stop() {
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
        dispatchSource?.cancel()
        dispatchSource = nil
    }
}
