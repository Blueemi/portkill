import Foundation

protocol PortScanning {
    func scan() async throws -> [PortProcess]
}

struct PortScanner: PortScanning {
    func scan() async throws -> [PortProcess] {
        try await Task.detached(priority: .userInitiated) {
            try Self.scanSynchronously()
        }.value
    }

    private static func scanSynchronously() throws -> [PortProcess] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-nP", "-iTCP", "-sTCP:LISTEN", "-F", "pcPn"]

        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error

        try process.run()
        process.waitUntilExit()

        let outputData = output.fileHandleForReading.readDataToEndOfFile()
        let errorData = error.fileHandleForReading.readDataToEndOfFile()
        let outputText = String(data: outputData, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 && outputText.isEmpty {
            let message = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw PortScannerError.lsofFailed(message?.nilIfEmpty ?? "lsof exited with status \(process.terminationStatus).")
        }

        return parse(outputText)
    }

    private static func parse(_ output: String) -> [PortProcess] {
        var currentPID: Int32?
        var currentCommand = "Unknown"
        var currentProtocol = "TCP"
        var rows: [PortProcess] = []
        var seen = Set<String>()

        for rawLine in output.split(whereSeparator: \.isNewline) {
            guard let marker = rawLine.first else {
                continue
            }

            let value = String(rawLine.dropFirst())

            switch marker {
            case "p":
                currentPID = Int32(value)
                currentCommand = "Unknown"
                currentProtocol = "TCP"
            case "c":
                currentCommand = value.nilIfEmpty ?? "Unknown"
            case "P":
                currentProtocol = value.nilIfEmpty ?? "TCP"
            case "n":
                guard let pid = currentPID, let port = extractPort(from: value) else {
                    continue
                }

                let uniqueKey = "\(pid)-\(port)-\(value)"
                guard seen.insert(uniqueKey).inserted else {
                    continue
                }

                rows.append(
                    PortProcess(
                        port: port,
                        processName: currentCommand,
                        pid: pid,
                        endpoint: value,
                        protocolName: currentProtocol
                    )
                )
            default:
                continue
            }
        }

        return rows.sorted { lhs, rhs in
            if lhs.port != rhs.port {
                return lhs.port < rhs.port
            }

            if lhs.processName.localizedCaseInsensitiveCompare(rhs.processName) != .orderedSame {
                return lhs.processName.localizedCaseInsensitiveCompare(rhs.processName) == .orderedAscending
            }

            return lhs.pid < rhs.pid
        }
    }

    private static func extractPort(from endpoint: String) -> Int? {
        let localEndpoint = endpoint.components(separatedBy: "->").first ?? endpoint
        guard let colonIndex = localEndpoint.lastIndex(of: ":") else {
            return nil
        }

        let afterColon = localEndpoint[localEndpoint.index(after: colonIndex)...]
        let portText = afterColon.prefix { character in
            character.isNumber
        }

        return Int(portText)
    }
}

enum PortScannerError: LocalizedError {
    case lsofFailed(String)

    var errorDescription: String? {
        switch self {
        case .lsofFailed(let message):
            return message
        }
    }
}
