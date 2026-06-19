import Foundation
@testable import UberVoiceCore

/// Doble de ``SecureStore`` en memoria para los tests de CI: reemplaza al
/// Keychain real sin tocar frameworks de Apple ni el dispositivo.
final class InMemorySecureStore: SecureStore {
    private(set) var storage: [String: Data] = [:]

    /// Permite simular fallos del backend (p. ej. para futuros tests de error).
    var setDataError: Error?

    func setData(_ data: Data, forKey key: String) throws {
        if let setDataError { throw setDataError }
        storage[key] = data
    }

    func data(forKey key: String) throws -> Data? {
        storage[key]
    }

    func removeData(forKey key: String) throws {
        storage[key] = nil
    }
}
