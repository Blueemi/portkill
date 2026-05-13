import Darwin
import Foundation

protocol ProcessKilling {
    func kill(pid: Int32) async throws
    func kill(pids: Set<Int32>) async throws
}

struct ProcessKiller: ProcessKilling {
    func kill(pid: Int32) async throws {
        try await Task.detached(priority: .userInitiated) {
            try Self.killSynchronously(pid: pid)
        }.value
    }

    func kill(pids: Set<Int32>) async throws {
        for pid in pids.sorted() {
            try await kill(pid: pid)
        }
    }

    private static func killSynchronously(pid: Int32) throws {
        guard pid > 0 else {
            return
        }

        if Darwin.kill(pid, SIGTERM) == -1 {
            try handleKillError(pid: pid)
        }

        Thread.sleep(forTimeInterval: 0.45)

        if Darwin.kill(pid, 0) == 0 {
            if Darwin.kill(pid, SIGKILL) == -1 {
                try handleKillError(pid: pid)
            }
        } else if errno != ESRCH {
            try handleKillError(pid: pid)
        }
    }

    private static func handleKillError(pid: Int32) throws {
        let errorNumber = errno
        if errorNumber == ESRCH {
            return
        }

        let message = String(cString: strerror(errorNumber))
        throw ProcessKillerError.killFailed(pid: pid, message: message)
    }
}

enum ProcessKillerError: LocalizedError {
    case killFailed(pid: Int32, message: String)

    var errorDescription: String? {
        switch self {
        case .killFailed(let pid, let message):
            return "Could not kill PID \(pid): \(message)"
        }
    }
}
