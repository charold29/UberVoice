# CLAUDE.md — UberVoice

Reglas del proyecto para Claude Code. **Respétalas siempre.** Si una instrucción puntual choca con
algo de aquí, gana este archivo: avísalo y pide confirmación antes de desviarte.

---

## Qué es UberVoice

App iOS en Swift que pide un Uber por voz con Siri. Al oír frases como "quiero ir al gimnasio", resuelve
el destino entre los **favoritos cifrados** del usuario, arma un **deep link** de Uber con el destino
prellenado y **abre Uber para que el usuario confirme manualmente**. Cada favorito tiene un apodo natural
("el gimnasio", "mi escuela").

**Responsable:** creador del proyecto y desarrollador en jefe.

---

## Restricción que define todo: Windows-first

- El desarrollo es en **Windows, sin Mac por ahora**. Xcode y la firma (`codesign`, Keychain de macOS)
  son exclusivos de macOS.
- **Toda la lógica se escribe y se testea desde Windows + CI.** El app target, la firma y las pruebas en
  iPhone **esperan a una sesión de Mac**.
- Objetivo: dejar el proyecto "listo para ejecutar" para que la sesión de Mac sea solo *ensamblar el
  shell + firmar + probar*.

---

## Arquitectura fija — NO negociable, NO proponer alternativas

| Decisión | Elección | Prohibido |
|---|---|---|
| Disparo por voz | **App Intents + App Shortcuts** | ❌ SiriKit Ride Booking (deprecado desde iOS 15) |
| Acción sobre Uber | **Universal Deep Link** `https://m.uber.com/ul/` (`action=setPickup`) | ❌ API REST de Uber (requiere aprobación empresarial) |
| Favoritos | **Keychain Services**, cifrado | ❌ UserDefaults / texto plano |
| Geocodificación | **CLGeocoder**, una sola vez al crear el favorito (cachear coords) | ❌ geocodificar en cada viaje |
| Confirmación del viaje | **Manual dentro de Uber** (por diseño) | ❌ pedido 100% automático |

---

## Patrón de arquitectura: Ports & Adapters (Hexagonal) + MVVM en UI

La regla de dependencia **apunta siempre hacia adentro**. La infraestructura conoce al núcleo; el núcleo
**nunca** conoce la infraestructura.

**Núcleo / dominio** — Swift puro, cero frameworks, 100% testeable en CI:
- Modelo `Favorite` (nickname, label, latitude, longitude, formatted_address).
- Resolución de destino ("gimnasio" → `Favorite`).
- Constructor del **deep link** (`m.uber.com/ul/`, encoding, llaves literales).
- Parsing y validaciones.

**Puertos** — protocolos que define el núcleo:
- `FavoritesStore` — guardar / listar / resolver favoritos.
- `Geocoder` — dirección → coordenadas (se usa **una sola vez**, al crear el favorito).
- `RideLauncher` — abrir una URL (lanzar Uber).

**Adaptadores** — lo que toca frameworks (lo "no-CI"):
- `KeychainFavoritesStore: FavoritesStore` → Keychain Services.
- `CLGeocoderAdapter: Geocoder` → CoreLocation.
- `UIApplicationRideLauncher: RideLauncher` → `UIApplication.open`.

**Adaptadores de entrada:**
- `AppIntent` (Siri vía App Shortcuts): **orquesta**, no construye URLs ni habla con Keychain. Delega en
  los puertos.
- Vistas SwiftUI para gestionar favoritos (MVVM).

**Prohibido:** VIPER, Clean por 5 capas, TCA (es dependencia externa). Aplicar puertos **solo** en las
fronteras que compran testabilidad real (storage, geocoding, launch). En el resto, MVVM directo.

---

## Estructura del repo

```
repo/
├── UberVoiceCore/                ← Swift Package (LÓGICA testeable, se hace en Windows)
│   ├── Package.swift
│   ├── Sources/UberVoiceCore/
│   └── Tests/UberVoiceCoreTests/
├── UberVoiceApp/                 ← App target Xcode (SHELL, espera la Mac)
└── .github/workflows/ci.yml      ← compila y testea SOLO el package
```

El app target **solo consume** `UberVoiceCore`; no mete lógica.

---

## Estándares de código

1. **Swift idiomático, iOS 16+** (App Intents requiere iOS 16+), **sin dependencias externas** salvo que
   sea estrictamente necesario.
2. **Lógica como Swift Package** (`UberVoiceCore`); el app target va aparte.
3. **Coordenadas locale-safe:** siempre punto decimal, **jamás coma** (el device puede estar en es-PE).
4. **Deep link:** valores percent-encodeados; llaves con corchetes (`dropoff[latitude]`) **literales**;
   `pickup=my_location`.
5. **Favoritos solo en Keychain**, cifrados. Geocodificar **una sola vez** al crear el favorito y cachear.
6. **Tests para toda la lógica.**

---

## CI/CD (GitHub Actions)

- Runner **`macos-latest`** (los tests importan frameworks de Apple; no corren en Linux).
- Pasos: `swift build` + `swift test`. Nada más.
- En CI **solo** se testea: lógica de favoritos, parsing, geocodificación **mockeada** y construcción de
  la URL del deep link.
- **Siri y deep link real:** SOLO en dispositivo físico, **nunca** en simulador ni CI.
- Los minutos de macOS cuentan 10×: cancelar runs viejos del mismo branch.

---

## Cuenta Apple — Personal Team

- Sin capacidades de cuenta de pago (no push remoto, no distribución fuera del device de prueba).
- Firma automática con Personal Team. El certificado **caduca a los 7 días**.
- Probar siempre en **dispositivo físico** (los universal links no funcionan en simulador).

---

## Orden de construcción

| # | Pieza | Estado | CI |
|---|---|---|---|
| 1 | `UberDeepLinkBuilder` + `Destination` | ✅ hecho | ✅ |
| 2 | `KeychainStore` (con abstracción para testear sin Keychain real) | pendiente | ✅ |
| 3 | `Favorite` + resolución de apodos | pendiente | ✅ |
| 4 | `GeocoderService` (wrapper CLGeocoder tras protocolo, mock en tests) | pendiente | ✅ |
| 5 | Parsing del destino | pendiente | ✅ |
| 6 | App Intent + App Shortcut (shell) | pendiente | ❌ (sesión Mac) |
| 7 | Integración end-to-end en iPhone | pendiente | ❌ (dispositivo) |

---

## Fuera de alcance (no diseñar para esto todavía)

- Alexa (se evalúa después; **sin capas de portabilidad**).
- Android.
- API REST privilegiada de Uber.
