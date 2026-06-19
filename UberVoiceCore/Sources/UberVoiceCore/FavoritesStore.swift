import Foundation

/// Puerto de dominio para gestionar favoritos. Lo define el núcleo; lo orquesta
/// el `AppIntent` y lo consume la UI.
///
/// La *resolución de apodos* ("quiero ir al gimnasio" → `Favorite`) es el paso 3
/// del roadmap y se añadirá como `find(matching:)` (o un resolver aparte que use
/// ``all()``), manteniendo separadas persistencia y resolución.
public protocol FavoritesStore {
    /// Inserta el favorito; si ya existe uno con el mismo `nickname`, lo reemplaza.
    func save(_ favorite: Favorite) throws
    /// Todos los favoritos guardados (vacío si no hay ninguno).
    func all() throws -> [Favorite]
    /// Elimina el favorito con ese `nickname`. No falla si no existe.
    func delete(nickname: String) throws
}

/// Implementación con toda la lógica de favoritos (serialización Codable, upsert,
/// almacenamiento como un único blob JSON) sobre cualquier ``SecureStore``.
///
/// Es store-agnóstica a propósito: en device se inyecta ``KeychainSecureStore``;
/// en CI, un doble en memoria. Así esta lógica se prueba sin Keychain real.
public final class DefaultFavoritesStore: FavoritesStore {

    private let secureStore: SecureStore
    private let storageKey: String

    /// - Parameters:
    ///   - secureStore: backend seguro concreto (Keychain en device, fake en tests).
    ///   - storageKey: clave única bajo la que vive el blob de favoritos.
    public init(secureStore: SecureStore, storageKey: String = "favorites") {
        self.secureStore = secureStore
        self.storageKey = storageKey
    }

    public func all() throws -> [Favorite] {
        guard let data = try secureStore.data(forKey: storageKey) else { return [] }
        return try JSONDecoder().decode([Favorite].self, from: data)
    }

    public func save(_ favorite: Favorite) throws {
        var favorites = try all()
        if let index = favorites.firstIndex(where: { $0.nickname == favorite.nickname }) {
            favorites[index] = favorite
        } else {
            favorites.append(favorite)
        }
        try persist(favorites)
    }

    public func delete(nickname: String) throws {
        var favorites = try all()
        favorites.removeAll { $0.nickname == nickname }
        try persist(favorites)
    }

    private func persist(_ favorites: [Favorite]) throws {
        let data = try JSONEncoder().encode(favorites)
        try secureStore.setData(data, forKey: storageKey)
    }
}
