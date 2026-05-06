# Datenschutzrichtlinie für SE Monitor for Homeassistant

*Stand: 6.5.2026*

Diese Datenschutzrichtlinie beschreibt, welche Daten die App **SE Monitor for HA** (im
Folgenden „die App") verarbeitet, wie sie verarbeitet werden und welche Rechte Sie als
Nutzer:in haben.

## 1. Verantwortlicher im Sinne der DSGVO

Verantwortlich für die Verarbeitung personenbezogener Daten im Zusammenhang mit der App ist:

> **Stephan Schindewolf**
> HJasensprung 1
> 76228 Karlsruhe
> Deutschland
>
> E-Mail: schiwo1@gmail.com

## 2. Grundsatz: Keine Datenerhebung durch den Anbieter

SE Monitor for HA ist eine reine Client-App, die ausschließlich auf Ihrem iPhone, Ihrer
Apple Watch und in der zugehörigen Widget-Erweiterung läuft. **Es gibt keine vom
Anbieter betriebenen Server, keine Analytics, kein Tracking und keine Werbung.** Es
werden weder personenbezogene Daten noch Nutzungsdaten an den Anbieter oder an Dritte
übermittelt.

## 3. Datenverarbeitung auf dem Gerät

Damit die App ihre Funktion erfüllen kann (Anzeige von Sensorwerten Ihrer eigenen Home
Assistant-Installation), werden folgende Daten **lokal auf Ihren Apple-Geräten**
gespeichert:

| Datum | Zweck | Speicherort | Übermittlung |
|-------|-------|-------------|--------------|
| Home Assistant URL (z. B. Ihre Nabu-Casa-Adresse) | Verbindung zu Ihrer HA-Instanz | App-Group `UserDefaults` | iPhone → Apple Watch via WatchConnectivity |
| Long-Lived Access Token (HA-Zugangstoken) | Authentifizierung gegenüber Ihrer HA-Instanz | iOS-/watchOS-Schlüsselbund (Keychain Access Group) | iPhone → Apple Watch via WatchConnectivity |
| Liste der konfigurierten HA-Entitäts-IDs (Solar, Netz, Verbrauch, Batterie 1–4) | Auswahl der anzuzeigenden Sensoren | App-Group `UserDefaults` | iPhone → Apple Watch via WatchConnectivity |
| Zwischengespeicherte Sensor-Momentaufnahme und 24-Stunden-Verlauf | Anzeige der Charts und Komplikation auch ohne Netzverbindung | App-Group `UserDefaults` der Apple Watch | nein |

Die Übertragung von iPhone zu Apple Watch erfolgt ausschließlich über das
verschlüsselte WatchConnectivity-Framework von Apple und verlässt das Apple-Ökosystem
nicht.

## 4. Direkte Kommunikation mit Ihrer Home Assistant-Instanz

Zum Abruf der Sensorwerte stellt die App **ausschließlich verschlüsselte HTTPS-
Verbindungen** zu der von Ihnen eingegebenen Home Assistant-URL her (typischerweise
Ihre Nabu-Casa-Cloud-Adresse). Dabei werden HTTP-Anfragen an die folgenden Endpunkte
gerichtet:

- `GET /api/states/<entity_id>` — aktueller Sensorwert
- `GET /api/history/period/<startzeit>?filter_entity_id=...` — 24-Stunden-Verlauf

Diese Anfragen tragen den Long-Lived Access Token im `Authorization`-Header. Die
Antworten enthalten ausschließlich die Sensorwerte aus Ihrer eigenen Home
Assistant-Installation. Der Anbieter der App erhält von dieser Kommunikation nichts;
sie findet direkt zwischen Ihrem Gerät und Ihrer eigenen HA-Instanz statt.

## 5. Drittanbieter

Die App nutzt **keine** Drittanbieter-SDKs, keine Werbe- oder Tracking-Dienste, keine
Crash-Reporting-Dienste und keine externen Analyse-Tools.

Die App kommuniziert ausschließlich mit:

1. **Ihrer eigenen Home Assistant-Instanz** über die von Ihnen eingegebene URL.
2. **Apple-Diensten**, die für den Betrieb von iOS- und watchOS-Apps systembedingt
   erforderlich sind (z. B. WatchConnectivity, WidgetKit, Keychain). Für die
   Datenverarbeitung durch Apple gelten die Datenschutzbestimmungen von Apple Inc.

## 6. Rechtsgrundlage der Verarbeitung (Art. 6 DSGVO)

Soweit auf dem Gerät personenbezogene Daten (insb. Ihr Zugangstoken) verarbeitet werden,
geschieht dies auf Grundlage von Art. 6 Abs. 1 lit. b DSGVO (Erfüllung der Funktion, die
Sie mit der Installation der App nachgefragt haben) sowie Art. 6 Abs. 1 lit. f DSGVO
(berechtigtes Interesse an einem funktionierenden Produkt).

## 7. Speicherdauer

- Zugangstoken, URL und Entitätsliste werden gespeichert, bis Sie sie in der App ändern
  oder die App von Ihrem Gerät deinstallieren.
- Zwischengespeicherte Sensorwerte werden bei jedem erfolgreichen Abruf überschrieben
  und beim Deinstallieren der App vollständig entfernt.

## 8. Ihre Rechte

Da der Anbieter der App **keine Daten von Ihnen erhebt oder speichert**, gibt es seitens
des Anbieters auch keine personenbezogenen Daten, auf die sich die folgenden Rechte
beziehen könnten. Vollständigkeitshalber: Nach DSGVO stehen Ihnen grundsätzlich die
folgenden Rechte zu — Auskunft (Art. 15), Berichtigung (Art. 16), Löschung (Art. 17),
Einschränkung der Verarbeitung (Art. 18), Datenübertragbarkeit (Art. 20), Widerspruch
(Art. 21) sowie Beschwerde bei einer Aufsichtsbehörde (Art. 77).

Alle lokal auf Ihrem Gerät gespeicherten Daten können Sie jederzeit löschen, indem Sie
die App deinstallieren oder die Konfigurationsfelder leeren.

## 9. Sicherheit

- Der Long-Lived Access Token wird im Apple-Schlüsselbund (Keychain) gespeichert, der
  mit der Geräte-Sperre und der Secure Enclave abgesichert ist.
- Die Übertragung zwischen iPhone und Apple Watch erfolgt über das von Apple
  bereitgestellte, verschlüsselte WatchConnectivity-Protokoll.
- Verbindungen zu Ihrer Home Assistant-Instanz erfolgen ausschließlich über HTTPS
  (TLS).

## 10. Hinweis zu Markenrechten

SE Monitor for HA ist ein unabhängiges Drittprodukt. Es steht in keiner geschäftlichen
oder personellen Verbindung zu **SolarEdge Technologies, Inc.** oder zum
**Home Assistant**-Projekt und wird von diesen weder unterstützt noch gesponsert.
„SolarEdge" ist eine eingetragene Marke von SolarEdge Technologies, Inc.; der Name wird
hier nur zur Beschreibung der Drittanbieter-Home-Assistant-Integrationen verwendet,
deren Sensorwerte die App auslesen kann.

## 11. Änderungen dieser Datenschutzrichtlinie

Diese Datenschutzrichtlinie kann angepasst werden, wenn dies durch geänderte Funktionen
der App oder durch geänderte Rechtslage erforderlich wird. Die jeweils aktuelle Fassung
wird unter der URL veröffentlicht, die Sie im App Store als Datenschutzrichtlinie der
App finden.

## 12. Kontakt

Bei Fragen zu dieser Datenschutzrichtlinie wenden Sie sich bitte an die unter Ziffer 1
genannte Kontaktadresse.
