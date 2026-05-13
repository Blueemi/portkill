import Foundation

struct PortProcess: Identifiable, Hashable, Sendable {
    let port: Int
    let processName: String
    let pid: Int32
    let endpoint: String
    let protocolName: String

    var id: String {
        "\(pid)-\(port)-\(endpoint)"
    }

    var pidLabel: String {
        "PID \(pid)"
    }

    var portLabel: String {
        ":\(String(port))"
    }

    var displayName: String {
        processName.truncated(to: 14)
    }
}
