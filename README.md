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
- **Tactile Materiality:** Deep charcoal canvas (`#171717`), physical card containers (`#262626`) with dual ambient/directional drop shadows, recessed OLED/LCD display bays (`#141414`), and 1px chiseled top specular highlights.
- **Unified Bento-Grid Layout:** A streamlined, non-fragmented single-screen architecture replacing legacy multi-tab navbars with high-density, responsive modular card workspaces.
- **Cascaded Profile & Multi-Account Switcher:** Interactive cascaded avatar component embedded directly in the Hero Balance Card header. Features real-time initial badges, sliding reveal micro-animations, 1-click account switching (`⇄`), and a contextual profile drawer for wallet settings and vault controls.
- **Vault Security & Automated Idle Auto-Lock:** Keystore encryption protected by memory-hard key derivation and authenticated cipher suites. Window-level user inactivity detection automatically engages a 15-minute idle timer that purges volatile secrets and locks the wallet.
- **Strict Zero-Icon Policy:** The user interface is completely free of decorative icons, glyph packs, or emoji clutter. All visual cues, statuses, and navigational elements rely on crisp, modern typography (*Inter* / *Roboto*) and semantic text pill badges (e.g., `[ PUBLIC TRANSPARENT ACCOUNT ]`, `[ SHIELDED ZK CIRCUIT ACCOUNT ]`, `[ VERIFIED ]`).

## Implemented Workspaces & Feature Domains

### 1. Hardware Keystore & Vault Lifecycle
- **BIP-39 Mnemonic Management:** Create fresh 12/24-word recovery phrases or restore existing vaults with interactive seed verification.
- **Argon2id Vault Protection:** Authenticated encryption using AES-256-GCM. Features instant tactile lock and unlock flows.
- **Session Auto-Lock:** Automatic 15-minute idle timeout clearing volatile cryptographic credentials and sessions from memory.

### 2. Multi-Account Portfolio (Transparent Public vs Shielded Private)
- **Account Switcher:** Seamlessly toggle between transparent accounts and shielded zero-knowledge accounts with distinct visual badges.
- **Asset Balances:** Real-time balance queries across Public Transparent, Shielded Zero-Knowledge, and Testnet Faucet pools.
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
- **Testnet Faucet:** One-click automated faucet request claiming 100 LEZ for active testnet accounts.

### 5. On-Chain Testimonials Mini-App
- **Adoption Engine (LP-0021):** Built-in workspace enabling users to publish on-chain testimonials directly to the testnet zkVM `testimonial-program`.
- **Submission Safeguards:** Strict client-side validation ensuring $\le 280$ UTF-8 bytes for testimonial text and $\le 64$ bytes for optional monikers with live character counters.

### 6. Activity Feed & Transaction Ledger
- **Segmented Filter Tabs:** Real-time chronological transaction history filterable by *All*, *Transfers*, *Shields*, and *Testimonials*.
- **Monospace Telemetry:** High-contrast transaction rows detailing direction, status tags, timestamps, and transfer amounts.

## Directory Structure

```
e-wallet-ui/
├── assets/
│   └── eWalletLogo.png             # Official 256x256 application icon
├── metadata.json                   # Basecamp module manifest (type: ui_qml)
├── flake.nix                       # Nix flake packaging (mkLogosQmlModule)
├── flake.lock                      # Pinned Nix lockfile
├── .gitignore                      # Git ignore file (build, caches, local dev runner)
├── qml/
│   ├── Main.qml                    # Decoupled root shell orchestrator (Bento Grid + Auto-Lock)
│   ├── theme/
│   │   ├── Theme.qml               # Design tokens (#171717 canvas, #262626 card, #141414 inset)
│   │   └── qmldir
│   ├── controls/                   # Reusable tactile components (Zero Icon)
│   │   ├── Button.qml              # Tactile pill button (Primary Blue & Charcoal)
│   │   ├── Card.qml                # Beveled physical container with headerRight slot & drop shadows
│   │   ├── InsetPanel.qml          # Sunken OLED/LCD display panel
│   │   ├── TextField.qml           # Recessed input field with focus glow
│   │   ├── ProgressBar.qml         # Recessed grooved progress track
│   │   ├── PillBadge.qml           # Semantic text status badge
│   │   ├── TabButton.qml           # Segmented tactile tab switch
│   │   ├── ModalOverlay.qml        # Tactile modal dialog backdrop & card
│   │   └── qmldir
│   ├── state/                      # State & IPC controllers
│   │   ├── WalletBridge.qml        # IPC bridge to e_wallet_core (+ Mock harness)
│   │   ├── AccountStore.qml        # Reactive multi-account portfolio controller
│   │   ├── TransferController.qml  # 4-way transfer state & LNS lookup controller
│   │   └── qmldir
│   ├── views/                      # Decoupled modular Bento-Grid card components
│   │   ├── BalanceView.qml         # Hero balance card, pool breakdown, cascaded avatar & menu
│   │   ├── TransferView.qml        # Quick transfer card (To, Amount + Max, Public/Shielded)
│   │   ├── FundingBridgeView.qml   # Testnet faucet claim & local PoW validator station
│   │   ├── TestimonialsView.qml    # LP-0021 on-chain testimonial broadcast card
│   │   ├── ActivityLedgerView.qml  # Filterable transaction ledger & real-time telemetry
│   │   └── qmldir
│   └── modals/                     # Interactive modal dialogs
│       ├── UnlockModal.qml         # Argon2id master password prompt
│       ├── CreateWalletModal.qml   # 12-word BIP-39 mnemonic generator & backup
│       ├── RestoreWalletModal.qml  # Seed phrase import & recovery
│       ├── CreateAccountModal.qml  # Public/Shielded account creator
│       ├── AccountDetailModal.qml  # 32-byte key inspector & label editor
│       ├── SettingsModal.qml       # Keystore security info, network sequencer, and vault locks
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
Run the standalone preview harness with live hot-reloading:
```bash
# Build standalone launcher (one-time setup)
nix build .#ui-dev

# Launch standalone UI with active real-time QML hot-reloading
./result/bin/run-logos-standalone-ui
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