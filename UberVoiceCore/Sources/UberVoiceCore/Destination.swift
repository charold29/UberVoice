/// Destino resuelto de un viaje, listo para construir el deep link de Uber.
///
/// Es un tipo de dominio puro (sin frameworks de Apple): se arma a partir de un
/// favorito ya geocodificado y alimenta a ``UberDeepLinkBuilder``. Las coordenadas
/// se guardan como `Double` y SIEMPRE se serializan con punto decimal, nunca coma
/// (ver ``UberDeepLinkBuilder/coordinateString(_:)``).
public struct Destination: Equatable, Sendable {
    /// Latitud del destino (`dropoff[latitude]`).
    public let latitude: Double
    /// Longitud del destino (`dropoff[longitude]`).
    public let longitude: Double
    /// Apodo natural del destino que se muestra en Uber (`dropoff[nickname]`).
    public let nickname: String
    /// Dirección legible del destino (`dropoff[formatted_address]`).
    public let formattedAddress: String

    public init(
        latitude: Double,
        longitude: Double,
        nickname: String,
        formattedAddress: String
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.nickname = nickname
        self.formattedAddress = formattedAddress
    }
}
