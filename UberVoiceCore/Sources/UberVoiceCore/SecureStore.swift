import Foundation

/// Puerto de almacenamiento seguro de bajo nivel: guardar/leer/borrar `Data`
/// por clave. Lo define el núcleo; lo implementa la infraestructura.
///
/// Deliberadamente NO expone tipos de Keychain (OSStatus, kSec…): así el núcleo
/// no conoce la infraestructura y la lógica de favoritos (``DefaultFavoritesStore``)
/// queda 100% testeable en CI con un doble en memoria.
public protocol SecureStore {
    /// Inserta o reemplaza el dato bajo `key`.
    func setData(_ data: Data, forKey key: String) throws
    /// Devuelve el dato de `key`, o `nil` si no existe.
    func data(forKey key: String) throws -> Data?
    /// Borra el dato de `key`. No falla si la clave no existía.
    func removeData(forKey key: String) throws
}
