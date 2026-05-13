import Foundation

@MainActor
final class PortMonitorStore: ObservableObject {
    @Published private(set) var ports: [PortProcess] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var isShowingKillAllConfirmation = false

    private let scanner: any PortScanning
    private let killer: any ProcessKilling

    init(scanner: any PortScanning = PortScanner(), killer: any ProcessKilling = ProcessKiller()) {
        self.scanner = scanner
        self.killer = killer
    }

    var uniqueProcessCount: Int {
        Set(ports.map(\.pid)).count
    }

    var statusText: String {
        if isLoading && ports.isEmpty {
            return "Scanning..."
        }

        if ports.isEmpty {
            return "No listeners"
        }

        let processWord = uniqueProcessCount == 1 ? "process" : "processes"
        return "\(ports.count) ports, \(uniqueProcessCount) \(processWord)"
    }

    func refresh() {
        Task {
            await refreshNow()
        }
    }

    func refreshNow() async {
        guard !isLoading else {
            return
        }

        isLoading = true
        defer {
            isLoading = false
        }

        do {
            ports = try await scanner.scan()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func kill(_ entry: PortProcess) {
        kill(pid: entry.pid)
    }

    func killAll() {
        let targets = Set(ports.map(\.pid))
        guard !targets.isEmpty else {
            return
        }

        Task {
            do {
                try await killer.kill(pids: targets)
                await refreshNow()
            } catch {
                errorMessage = error.localizedDescription
                await refreshNow()
            }
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func kill(pid: Int32) {
        Task {
            do {
                try await killer.kill(pid: pid)
                await refreshNow()
            } catch {
                errorMessage = error.localizedDescription
                await refreshNow()
            }
        }
    }
}
