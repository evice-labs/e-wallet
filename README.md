<p align="center">
  <img src="assets/eWalletLogo.png" alt="eWallet Logo" width="160" />
</p>

<p align="center">
  <strong>Evice LEZ Wallet QML UI Plugin for Logos Basecamp</strong>
  <br />
</p>

<p align="center">
  <a href="LICENSE-APACHE"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" alt="License Apache" /></a>
  <a href="LICENSE-MIT"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License MIT" /></a>
  <img src="https://img.shields.io/badge/Platform-Logos%20Basecamp-orange.svg" alt="Logos Basecamp" />
  <img src="https://img.shields.io/badge/Network-LEZ%20Testnet%200.4-emerald.svg" alt="LEZ Testnet 0.4" />
  <img src="https://img.shields.io/badge/Design-Neo--Skeuomorphism-black.svg" alt="Neo-Skeuomorphism" />
</p>

## Overview

**Evice LEZ Wallet UI** is the official user-facing desktop application module for the Logos Execution Zone (LEZ), designed and packaged natively for **Logos Basecamp**.

It presents a tactile, secure, and intuitive graphical interface that integrates seamlessly with the underlying [Core Module](https://github.com/evice-labs/e-wallet-core) (C++20 Universal Core Module) and the [SDK](https://github.com/evice-labs/e-wallet-sdk) (pure Rust cryptographic engine).

### Core Design Philosophy: Modern Neo-Skeuomorphism
- **Tactile Materiality:** Deep black canvases (`#050508`), recessed OLED/LCD bays with inner shadows, and multi-layered specular edge highlights.
- **Pill-Beveled Action Controls:** Elevated push-buttons with realistic top lighting rims (`rgba(255, 255, 255, 0.4)`), vibrant cerulean primary action fills, dark charcoal secondary containers, and mechanical click depression.
- **Strict Zero-Icon Policy:** The user interface is completely free of decorative icons, glyph packs, or emoji clutter. All visual cues, statuses, and navigational elements rely on crisp, modern typography (*Inter* / *Roboto*) and semantic text pill badges (e.g., `[ PUBLIC TRANSPARENT ACCOUNT ]`, `[ SHIELDED ZK CIRCUIT ACCOUNT ]`, `[ VERIFIED ]`).

## System Architecture

### Decoupled Component Hierarchy
To ensure long-term maintainability and modular scalability, `e-wallet-ui` strictly adheres to a decoupled, unidirectional data-flow architecture:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        LOGOS BASECAMP HOST                             │
│                                                                        │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │               qml/Main.qml (Clean Root Shell Router)           │   │
│   │   • Top Navigation Bar       • Global Modal Presenter          │   │
│   │   • Telemetry Readouts       • Theme Provider Context          │   │
│   └───────┬────────────────────────────────────────────────┬───────┘   │
│           │                                                │           │
│           ▼                                                ▼           │
│   ┌───────────────────────────┐                    ┌───────────────┐   │
│   │   qml/views/ (UI Panels)  │                    │ qml/modals/   │   │
│   │   • DashboardView         │                    │ • Approval    │   │
│   │   • TransferView          │◄──── Reactive ─────┤ • AccountPick │   │
│   │   • FundingBridgeView     │      Bindings      │ • KeyExport   │   │
│   │   • TestimonialsView      │                    └───────────────┘   │
│   │   • IdentityView          │                            ▲           │
│   └─────────────┬─────────────┘                            │           │
│                 │                                          │           │
│                 ▼                                          │           │
│   ┌────────────────────────────────────────────────────────┴───────┐   │
│   │               qml/state/ (Decoupled Controllers)               │   │
│   │   • WalletBridge (IPC)       • AccountStore (Balances/State)   │   │
│   │   • TransferController       • FundingBridgeController (PoW)   │   │
│   │   • ApprovalManager          • TestimonialController           │   │
│   └──────────────────────────────┬─────────────────────────────────┘   │
└──────────────────────────────────┼─────────────────────────────────────┘
                                   │
                                   ▼ `logos.callModule("e_wallet_core", ...)`
┌────────────────────────────────────────────────────────────────────────┐
│               e-wallet-core (Universal C++ Basecamp Module)            │
│   • wallet_engine   • wallet_accounts   • wallet_transfers             │
│   • wallet_sessions • wallet_approval   • wallet_identity              │
│   • wallet_names    • wallet_contracts  • wallet_helpers               │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼ C-ABI FFI (`lez_wallet_sdk.h`)
┌────────────────────────────────────────────────────────────────────────┐
│               lez-wallet-sdk (Rust Core Engine & Tools)                │
│   • sdk-engine      • Argon2id/AES-GCM  • Intent Hashing (SHA-256)     │
│   • LNS Resolver    • EffectSimulator   • Verifier (LP-0023)           │
└────────────────────────────────────────────────────────────────────────┘
```

## Implemented Workspaces & Feature Domains

### 1. Hardware Keystore & Vault Lifecycle
- **BIP-39 Mnemonic Management:** Create fresh 12/24-word recovery phrases or restore existing vaults with interactive seed verification.
- **Argon2id Vault Protection:** Authenticated encryption using AES-256-GCM. Features instant tactile lock and unlock flows.
- **Session Auto-Lock:** Automatic timeout clearing volatile cryptographic credentials from memory.

### 2. Multi-Account Portfolio (Transparent Public vs Shielded Private)
- **Account Switcher:** Seamlessly toggle between transparent accounts and shielded zero-knowledge accounts with distinct visual badges.
- **Asset Balances:** Real-time balance queries for both native LEZ coin and custom Fungible Token Program definitions.
- **Account Detail Modal:** Inspect full 32-byte account IDs, generate QR representations, and export View/Spend keys protected by password re-entry.

### 3. 4-Way Asset Transfers & Instant LNS Domain Resolution
- **Multi-Privacy Transfer Matrix:**
  1. `Public -> Public`: Transparent on-chain ledger transfers.
  2. `Public -> Private (Shield)`: Converts transparent balances into private shielded notes.
  3. `Private -> Public (Unshield)`: Proves notes in ZK circuit and credits transparent recipients.
  4. `Private -> Private`: Complete end-to-end sender and receiver privacy.
- **Clean-Room LNS Resolver:** Resolves human-readable `.lez` names (e.g. `alice.lez`) directly on-chain using Argon2id master key derivation and sequencer PDA queries, displaying real-time ownership badges.

### 4. Canonical Funding Path: EmPoWer PoW Mining & L1 &rarr; LEZ Bridge
*Aligned with the Logos network architecture and EmPoWer L1-to-LEZ bridging specification:*
- **EmPoWer Mining Station:** Direct REST integration with the Logos Blockchain node (`/pow/status`, `/pow/mining/start`, `/pow/mining/stop`, `/pow/claim`). Enables users to generate testnet tokens via local Proof-of-Work without relying on external centralized faucets.
- **L1 &rarr; LEZ Channel Deposit:** One-click bridging terminal moving mined L1 notes into the user's active LEZ account via on-chain `ChannelDeposit` transactions.

### 5. On-Chain Testimonials Mini-App
- **Adoption Engine (LP-0021):** Built-in workspace enabling users to publish on-chain testimonials directly to the testnet zkVM `testimonial-program`.
- **Submission Safeguards:** Strict client-side validation ensuring $\le 280$ UTF-8 bytes for testimonial text and $\le 64$ bytes for optional monikers.
- **Attribution Invariant:** Automatically embeds the unique `SUBMISSION_ID` into the transaction payload, linking directly to the live testnet block explorer (`https://explorer.testnet.lez.logos.co/`).

### 6. Informed Consent Approval UX & Program Verification (LP-0023)
- **Granular Session Security:** Interactive account picker allowing users to grant scoped permissions (`GrantKind::Read` vs `GrantKind::Propose`) to connecting dApps.
- **Plain-Language Effect Simulation:** Decodes raw calldata into human-readable balance deltas (`simulatePromptEffect`), preventing blind signing.
- **Program Source Verification Badge:** Inspects smart contract bytecode against the LP-0023 registry, rendering `[ VERIFIED ]`, `[ UNVERIFIED ]`, or `[ UNTRUSTED ]` alert banners.

### 7. Identity Accountability Hub
- **Master Identity Commitment:** Derives deterministic public commitments from the root seed for on-chain identity registry verification.
- **Cross-dApp Scoped Nullifiers:** Computes unlinkable pseudonymous nullifiers per dApp domain.
- **BIP-340 Schnorr Attestations:** Cryptographically signs arbitrary message payloads with scoped identity credentials.

## Directory Structure

```
e-wallet-ui/
├── assets/
│   └── eWalletLogo.png             # Official 256x256 application icon
├── metadata.json                   # Basecamp module manifest (type: ui_qml)
├── flake.nix                       # Nix flake packaging (mkLogosQmlModule)
├── flake.lock                      # Pinned Nix lockfile
├── .gitignore
├── qml/
│   ├── Main.qml                    # Decoupled root shell & router (< 120 lines)
│   ├── theme/
│   │   ├── Theme.qml               # Design tokens (colors, bevels, lighting, typography)
│   │   └── qmldir
│   ├── controls/                   # Reusable tactile components (Zero Icon)
│   │   ├── Button.qml              # Tactile pill button (Primary Blue & Charcoal)
│   │   ├── Card.qml                # Beveled physical container with drop shadow
│   │   ├── InsetPanel.qml          # Sunken OLED/LCD display panel
│   │   ├── TextField.qml           # Recessed input field with focus glow
│   │   ├── ProgressBar.qml         # Recessed grooved progress track
│   │   ├── PillBadge.qml           # Semantic text status badge
│   │   ├── TabButton.qml           # Segmented tactile tab switch
│   │   └── qmldir
│   └── state/
│       ├── WalletBridge.qml        # IPC bridge to e_wallet_core (+ Mock harness)
│       └── qmldir
└── .github/workflows/              # Continuous integration pipelines
    ├── ci-linux.yml                # Linux Nix build & QML architecture verification
    ├── ci-macos.yml                # macOS build compatibility verification
    └── testnet-smoke.yml           # Live testnet sequencer health & packaging smoke
```

## Building & Installation

### Prerequisites
- [Nix Package Manager](https://nixos.org/download.html) with Flakes enabled.
- Pinned `e-wallet-core` module located in the parent directory (`../e-wallet-core`).

### 1. Local Development Preview
Run the standalone preview harness without launching Basecamp:
```bash
# Using standard QML runner
qml6 -I qml qml/Main.qml

# Or using Nix application runner
nix run . --impure
```

### 2. Building the Production Nix Package
```bash
# Build the standard module package
nix build .# --impure -L

# Build the portable variant for Logos Basecamp deployment
nix build .#install-portable --impure -L
```

### 3. Deploying to Logos Basecamp
Logos Basecamp loads installed portable modules from `~/.local/share/Logos/LogosBasecamp`:

```bash
# Deploy Core Module
cp -rL ../e-wallet-core/result/modules/e_wallet_core ~/.local/share/Logos/LogosBasecamp/modules/

# Deploy UI Module
cp -rL result/plugins/e_wallet_ui ~/.local/share/Logos/LogosBasecamp/plugins/
```

When you launch `LogosBasecamp`, **Evice Wallet** will automatically appear in the sidebar with the `eWalletLogo.png` icon!

## Continuous Integration & Quality Assurance

Automated GitHub Actions workflows are configured in `.github/workflows/`:
- **`ci-linux.yml`:** Validates `metadata.json` integrity, verifies `eWalletLogo.png` icon presence, enforces the decoupled architecture line-count threshold on `qml/Main.qml`, and builds the module and portable bundles.
- **`ci-macos.yml`:** Validates Nix package compilation on `macos-latest`.
- **`testnet-smoke.yml`:** Periodic weekly workflow that tests live JSON-RPC connectivity with the LEZ testnet sequencer (`https://testnet.lez.logos.co`), checking `checkHealth`, `getLastBlockId`, and `getFeeState` before validating bundle construction.

## License

Dual-licensed under either:
- **Apache License, Version 2.0** ([LICENSE-APACHE](LICENSE-APACHE))
- **MIT License** ([LICENSE-MIT](LICENSE-MIT))

at your option.