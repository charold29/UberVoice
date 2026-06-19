import Foundation

/// Construye el **deep link universal** de Uber (`https://m.uber.com/ul/`) con la
/// acción `setPickup`: origen = ubicación actual del usuario, destino prellenado.
///
/// El núcleo produce **solo la cadena byte-exacta** del enlace (``urlString(for:)``).
/// Construir el objeto `URL` y abrirlo es responsabilidad del adaptador
/// `RideLauncher` (infraestructura), porque el parser de `URL` de Foundation trata
/// los corchetes literales distinto según la versión del SO: el parser estricto
/// (macOS de CI) los rechaza, el legacy (iOS 16 en device) los conserva. Mantener
/// esa conversión fuera del núcleo lo deja 100% determinista y testeable en CI.
///
/// Reglas que respeta (ver `CLAUDE.md`):
/// - Llaves con corchetes **literales**: `dropoff[latitude]`, nunca `dropoff%5Blatitude%5D`.
/// - Valores **percent-encodeados** (juego "unreserved" de RFC 3986).
/// - Coordenadas **locale-safe**: siempre punto decimal, jamás coma (device puede ser es-PE).
/// - `pickup=my_location` fijo; no se pasan coordenadas de origen.
public struct UberDeepLinkBuilder {

    /// Base del enlace universal. Funciona con o sin la app de Uber instalada.
    public static let baseURL = "https://m.uber.com/ul/"

    /// `client_id` de la app registrada en el dashboard de Uber. Opcional:
    /// mientras no exista registro (cuenta Personal Team), se omite del enlace.
    public let clientID: String?

    public init(clientID: String? = nil) {
        self.clientID = clientID
    }

    /// Cadena byte-exacta del deep link para un destino dado.
    ///
    /// Este es el producto canónico del builder y lo que verifican los tests.
    public func urlString(for destination: Destination) -> String {
        Self.baseURL + "?" + percentEncodedQuery(for: destination)
    }

    // MARK: - Query

    /// Pares (clave, valor sin codificar) en orden fijo y determinista.
    private func queryPairs(for destination: Destination) -> [(key: String, value: String)] {
        var pairs: [(key: String, value: String)] = []
        if let clientID, !clientID.isEmpty {
            pairs.append((key: "client_id", value: clientID))
        }
        pairs.append((key: "action", value: "setPickup"))
        pairs.append((key: "pickup", value: "my_location"))
        pairs.append((key: "dropoff[latitude]", value: Self.coordinateString(destination.latitude)))
        pairs.append((key: "dropoff[longitude]", value: Self.coordinateString(destination.longitude)))
        pairs.append((key: "dropoff[nickname]", value: destination.nickname))
        pairs.append((key: "dropoff[formatted_address]", value: destination.formattedAddress))
        return pairs
    }

    /// Query ya ensamblada: claves literales (con corchetes) y valores codificados.
    func percentEncodedQuery(for destination: Destination) -> String {
        queryPairs(for: destination)
            .map { "\($0.key)=\(Self.percentEncoded($0.value))" }
            .joined(separator: "&")
    }

    // MARK: - Formato locale-safe de coordenadas

    /// Serializa una coordenada con punto decimal independientemente del locale.
    ///
    /// `Double.description` (Swift puro, no Foundation) siempre usa `.` como
    /// separador, así que un device en es-PE jamás producirá `-12,0931`.
    static func coordinateString(_ value: Double) -> String {
        String(describing: value)
    }

    // MARK: - Percent encoding

    /// Juego "unreserved" de RFC 3986: `ALPHA / DIGIT / "-" / "." / "_" / "~"`.
    /// Todo lo demás (espacios, comas, acentos…) se percent-encodea.
    private static let unreservedCharacters: CharacterSet = {
        var set = CharacterSet()
        set.insert(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        set.insert(charactersIn: "abcdefghijklmnopqrstuvwxyz")
        set.insert(charactersIn: "0123456789")
        set.insert(charactersIn: "-._~")
        return set
    }()

    /// Percent-encoding estricto de un valor (espacio → `%20`, coma → `%2C`, …).
    static func percentEncoded(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: unreservedCharacters) ?? value
    }
}
