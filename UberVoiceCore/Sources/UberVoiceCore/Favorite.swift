/// Favorito del usuario: asocia un apodo natural ("gimnasio") con una ubicación
/// ya geocodificada. Es un tipo de dominio puro (sin frameworks de Apple).
///
/// Se persiste cifrado en Keychain (ver ``FavoritesStore``) y, al pedir un viaje,
/// se proyecta a ``Destination`` (``destination``) para construir el deep link.
public struct Favorite: Codable, Equatable, Hashable, Sendable {
    /// Apodo natural con el que el usuario nombra el destino ("gimnasio").
    public let nickname: String
    /// Etiqueta legible/descriptiva ("Smart Fit Miraflores"). Para mostrar.
    public let label: String
    /// Latitud cacheada (se geocodifica una sola vez, al crear el favorito).
    public let latitude: Double
    /// Longitud cacheada.
    public let longitude: Double
    /// Dirección legible cacheada.
    public let formattedAddress: String

    public init(
        nickname: String,
        label: String,
        latitude: Double,
        longitude: Double,
        formattedAddress: String
    ) {
        self.nickname = nickname
        self.label = label
        self.latitude = latitude
        self.longitude = longitude
        self.formattedAddress = formattedAddress
    }

    /// Llaves snake_case para que el JSON persistido coincida con el esquema
    /// documentado del favorito (ver `UberVoice_Referencia_Siri.pdf`, §6).
    private enum CodingKeys: String, CodingKey {
        case nickname
        case label
        case latitude
        case longitude
        case formattedAddress = "formatted_address"
    }
}

public extension Favorite {
    /// Proyección al destino que alimenta a ``UberDeepLinkBuilder``.
    /// `label` no viaja al deep link (es solo para la UI); el apodo del viaje
    /// usa `nickname`.
    var destination: Destination {
        Destination(
            latitude: latitude,
            longitude: longitude,
            nickname: nickname,
            formattedAddress: formattedAddress
        )
    }
}
