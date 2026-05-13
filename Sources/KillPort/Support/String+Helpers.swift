import Foundation

extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }

    func truncated(to maxLength: Int) -> String {
        guard count > maxLength else {
            return self
        }

        guard maxLength > 3 else {
            return String(prefix(maxLength))
        }

        return String(prefix(maxLength - 3)) + "..."
    }
}
