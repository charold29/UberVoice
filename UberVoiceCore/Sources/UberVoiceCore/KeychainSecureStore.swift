import Foundation
import Security

/// Adaptador de ``SecureStore`` sobre Keychain Services (cifrado, ligado al
/// dispositivo). Es infraestructura: compila en CI, pero su comportamiento real
/// SOLO se prueba en dispositivo físico (el Keychain headless del runner no es
/// representativo).
///
/// Guarda cada clave como un `kSecClassGenericPassword` (service + account).
public final class KeychainSecureStore: SecureStore {

    /// Identificador del servicio bajo el que se agrupan los ítems.
    private let service: String

    public init(service: String = "com.ubervoice.favorites") {
        self.service = service
    }

    public enum KeychainError: Error, Equatable {
        /// El Keychain devolvió un estado inesperado (ver `Security.SecCopyErrorMessageString`).
        case unexpectedStatus(OSStatus)
    }

    public func setData(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        // Intentamos actualizar; si no existe, lo creamos.
        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )

        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var addQuery = query
            addQuery[kSecValueData as String] = data
            // Disponible tras el primer desbloqueo y nunca sale del dispositivo.
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(addStatus)
            }
        default:
            throw KeychainError.unexpectedStatus(updateStatus)
        }
    }

    public func data(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            return item as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    public func removeData(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
