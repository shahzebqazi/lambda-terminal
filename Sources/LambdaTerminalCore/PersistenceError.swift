import Foundation

public enum PersistenceError: Error, Equatable, LocalizedError {
    case readFailed(path: String, underlying: String)
    case writeFailed(path: String, underlying: String)
    case decodeFailed(path: String, underlying: String)

    public var errorDescription: String? {
        switch self {
        case .readFailed(let path, let underlying):
            return "Failed to read \(path): \(underlying)"
        case .writeFailed(let path, let underlying):
            return "Failed to write \(path): \(underlying)"
        case .decodeFailed(let path, let underlying):
            return "Failed to decode \(path): \(underlying)"
        }
    }
}
