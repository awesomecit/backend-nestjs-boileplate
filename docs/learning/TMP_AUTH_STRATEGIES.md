# 🔐 Autenticazione nelle App Moderne (Enterprise e Consumer)

## Introduzione

In un'app moderna, **l'autenticazione** non è solo "inserire username e password".  
Le aziende e i prodotti consumer devono garantire:

- **Sicurezza** dei dati e degli accessi
- **User Experience (UX)** fluida
- **Scalabilità** (integrazione con servizi esterni)
- **Compliance** con standard (GDPR, ISO, NIST, ecc.)

Per questo si usano diverse **strategie di autenticazione** (authentication strategies), spesso combinate.

---

## 📌 Tipologie di autenticazione principali

### 1. Username + Password

- Metodo più tradizionale.
- Da solo è insicuro (phishing, brute-force).
- Da usare **solo con MFA**.

### 2. MFA (Multi-Factor Authentication)

- Combina più fattori:
  - Qualcosa che **sai** (password, PIN)
  - Qualcosa che **hai** (OTP, token, push notification)
  - Qualcosa che **sei** (biometria: impronta, volto)
- Standard in contesti enterprise.

### 3. Passwordless

- Nessuna password da ricordare.
- Modalità:
  - **Magic link** via email
  - **OTP** via SMS/app
  - **Passkey / WebAuthn (FIDO2)**
  - **Biometria** (Face ID, Touch ID, Windows Hello)

### 4. Federated Authentication / SSO

- L’utente accede tramite un **Identity Provider (IdP)**.
- Tecnologie:
  - **SAML 2.0** (enterprise tradizionale, AD/ADFS)
  - **OIDC + OAuth 2.0** (più moderno, app web/mobile)
- Vantaggi: **Single Sign-On (SSO)**, gestione centralizzata.

### 5. Social Login

- Accesso con **Google, Apple, Facebook, GitHub, LinkedIn**.
- Utile lato consumer (riduce attrito in registrazione).

### 6. API & Machine-to-Machine

- Per autenticare **servizi e microservizi**:
  - OAuth 2.0 (Client Credentials)
  - mTLS (mutual TLS)
  - API Keys (con scadenza e scope limitati)

### 7. Adaptive / Risk-Based Authentication

- Analizza il contesto (IP, device, posizione, comportamenti).
- Richiede più fattori solo se rileva rischio.

### 8. Biometria

- Sul device (Face ID, Touch ID).
- Può essere usata come **fattore aggiuntivo** o **passwordless**.

### 9. Hardware Tokens (YubiKey, Smart Card)

- Molto sicuri.
- Diffusi in settori regolamentati (bancario, PA, difesa).

---

## 🔍 Tabella comparativa: Enterprise vs Consumer

| Tipologia                                        | Enterprise (B2E / B2B)                      | Consumer (B2C)                              |
| ------------------------------------------------ | ------------------------------------------- | ------------------------------------------- |
| **Username + Password**                          | Supportata ma mai da sola, sempre con MFA.  | Ancora usata, ma meglio passwordless.       |
| **MFA**                                          | Obbligatoria (compliance).                  | Raccomandata, spesso opzionale.             |
| **Passwordless**                                 | In adozione progressiva (Passkey/WebAuthn). | Altamente consigliata (UX migliore).        |
| **SSO / Federated (SAML, OIDC, Azure AD, Okta)** | Standard di fatto.                          | Non prioritario, ma utile con Google/Apple. |
| **Social Login**                                 | Poco usato.                                 | Molto diffuso.                              |
| **API / Machine-to-Machine**                     | Fondamentale.                               | Solo se l’app espone API.                   |
| **Adaptive / Risk-Based**                        | Sempre più adottata.                        | Utile per ridurre frizioni.                 |
| **Biometria**                                    | Secondo fattore o passwordless locale.      | Molto apprezzata, spesso primaria.          |
| **Hardware tokens**                              | Comune in settori regolamentati.            | Raro.                                       |

---

## 🗂️ Flussi di autenticazione (Mermaid)

### Flusso base con Username + Password + MFA

```mermaid
sequenceDiagram
  participant U as Utente
  participant A as App
  participant IdP as Identity Provider

  U->>A: Inserisce username + password
  A->>IdP: Invia credenziali
  IdP-->>A: Risposta positiva
  A-->>U: Richiesta secondo fattore (OTP/Push/Biometria)
  U->>IdP: Inserisce secondo fattore
  IdP-->>A: Conferma autenticazione
  A-->>U: Accesso consentito

Flusso Federated Authentication (OIDC / OAuth2)
sequenceDiagram
  participant U as Utente
  participant A as App
  participant IdP as Identity Provider

  U->>A: Richiede login
  A-->>U: Redirect a Identity Provider
  U->>IdP: Inserisce credenziali (SSO)
  IdP-->>U: Redirect con Authorization Code
  U->>A: Invia Authorization Code
  A->>IdP: Scambia Authorization Code con Access Token
  IdP-->>A: Restituisce Access Token + ID Token
  A-->>U: Accesso consentito

Flusso Passwordless con Magic Link
sequenceDiagram
  participant U as Utente
  participant A as App
  participant E as Email Service

  U->>A: Inserisce email
  A->>E: Invia magic link all'utente
  E-->>U: Riceve email con link
  U->>A: Clicca magic link
  A-->>U: Accesso consentito (sessione attiva)

🚀 Conclusioni

Enterprise → sicurezza + compliance → SSO, MFA, OAuth2/mTLS, Adaptive.

Consumer → esperienza utente → social login, passwordless, biometria, MFA opzionale.

Il futuro è passwordless (Passkey/WebAuthn), supportato ormai da Google, Apple e Microsoft.
```
