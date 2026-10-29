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

It presents a tactile, secure, and intuitive graphical interface that integrates seamlessly with the underlying [Core Module](https://github.com/evice-labs/e-wallet-core) (C++20 Universal Core Module) and the [SDK](https://github.com/evice-labs/lez-wallet-sdk) (pure Rust cryptographic engine).

### Core Design Philosophy: Modern Neo-Skeuomorphism
- **Tactile Materiality.** Deep charcoal canvas (`#171717`), physical card containers (`#262626`) with dual ambient/directional drop shadows, recessed OLED/LCD display bays (`#141414`), and 1px chiseled top specular highlights.
- **Unified Bento-Grid Layout.** A streamlined, non-fragmented single-screen architecture replacing legacy multi-tab navbars with high-density, responsive modular card workspaces and adaptive proportional scrolling.
- **Cascaded Profile & Multi-Account Switcher.** Interactive cascaded avatar component embedded directly in the Hero Balance Card header. Features real-time initial badges, sliding reveal micro-animations, 1-click account switching (`⇄`), and a contextual profile drawer with Activity-style subtle hover feedback (`#343434`) and card-contained vault settings.
- **Vault Security & Automated Idle Auto-Lock.** Keystore encryption protected by memory-hard key derivation (Argon2id) and authenticated cipher suites (AES-256-GCM). Window-level user inactivity detection automatically engages an idle timer that purges volatile secrets and locks the wallet.
- **Zero-Redundancy Automated Validation Architecture.** Systems and state controllers automatically resolve active identity credentials, privacy routes, cryptographic nonces, and balances, eliminating redundant user inputs and error-prone manual validations.

## Implemented Workspaces & Feature Domains

### 1. Hardware Keystore & Vault Lifecycle
- **BIP-39 Mnemonic Management.** Create fresh 12-word recovery phrases or restore existing vaults with interactive seed verification (`CreateWalletModal.qml`, `RestoreWalletModal.qml`).
- **Argon2id Vault Protection.** Authenticated encryption using AES-256-GCM. Features instant tactile lock and unlock flows (`UnlockModal.qml`).
- **Session Auto-Lock.** Automatic idle timeout clearing volatile cryptographic credentials and sessions from memory upon inactivity.

### 2. Multi-Account Portfolio (Public Unshielded vs Private Shielded)
- **Account Switcher.** Seamlessly toggle between transparent public accounts and shielded zero-knowledge accounts with distinct visual status badges (`BalanceView.qml`).
- **Streamlined Account Creation.** Create new accounts (`CreateAccountModal.qml`) with clear `Public Unshielded` vs `Private Shielded` model selection and sequential default naming without redundant copy.
- **Asset Balances.** Real-time balance queries across Native LEZ, Shielded Zero-Knowledge pools, and Logos Token Program holdings.
- **Account Detail Modal.** Inspect full 32-byte account IDs, customize labels, and safely inspect View/Spend keys protected by security disclosures (`AccountDetailModal.qml`).

### 3. 4-Way Asset Transfers & Instant LNS Domain Resolution
- **Inline Route Indicator.** Positioned directly beneath the Amount & Max button row, displaying a clean white `"Route:"` label with status-colored route paths (`Public ➝ Public`, `Public ➝ Shield`, `Shield ➝ Public`, `Shield ➝ Shield`).
- **Automated Privacy Route Detection.** `TransferController.qml` automatically inspects sender privacy and recipient identifier prefix (`Private/...` vs `Public/...` vs `.lez`) to detect and configure the route mode (`pub_to_pub`, `pub_to_priv`, `priv_to_pub`, `priv_to_priv`) without requiring manual route toggling from the user.
- **"Your Accounts" 1-Click Quick Selector.** `TransferView.qml` automatically displays 1-click chip buttons for user's other accounts in the wallet, eliminating manual address typing or copy-pasting for intra-wallet transfers and shielding operations.
- **Clean-Room LNS Resolver.** Resolves human-readable `.lez` names (e.g. `alice.lez`, `bob.lez`) asynchronously via debounced queries to the sequencer LNS registry, displaying real-time verification indicators.
- **Automatic Gas & Max Spend Calculation.** Gas fee (`0.00015 LEZ`) and spendable maximum balances are automatically computed by the controller.

### 4. Canonical Funding Path: EmPoWer PoW Mining & L1 → LEZ Bridge
*Directly integrated with Logos Blockchain node architecture and canonical EmPoWer bridging:*
- **EmPoWer Mining Station.** Direct REST integration with the Logos Blockchain node (`/pow/status`, `/pow/mining/start`, `/pow/mining/stop`, `/pow/claim`). Enables users to generate testnet tokens via local Proof-of-Work without relying on external centralized faucets (`FundingBridgeView.qml`, `FundingBridgeController.qml`).
- **Dual-Action Segmented Controls.** Tactile segmented switch (`Start Mining` vs `Bridge Tokens`) housed in an inset trough capsule with real-time hash rate and status indicators (`POW ACTIVE • 1920 H/S`).
- **L1 → LEZ Channel Deposit Bridge.** One-click bridging terminal that deposits mined L1 notes into the user's active LEZ account via on-chain `ChannelDeposit` transactions.
- **Zero-Redundancy Automation.** The recipient LEZ address is automatically locked to the user's active account (`accountStore.activeAccount`), the deposit amount is automatically calculated from the total unbridged L1 balance, and worker threads are preset to 4 threads.

### 5. On-Chain Testimonials Mini-App
- **Adoption Engine (LP-0021).** Built-in workspace enabling users to publish on-chain testimonials directly to the testnet zkVM `testimonial-program` (`TestimonialsView.qml`, `TestimonialController.qml`).
- **Auto-Bound Active Account Author.** The author identity is strictly and automatically derived from the active account currently open in the wallet (`accountStore.activeAccount`). The UI renders a clean read-only affordance: `Posting as: [alice.lez]`, with zero manual username or moniker input.
- **Standardized Physical Dimensions.** Submit button dimensions calibrated to match the tactile heights across adjacent card action rows.
- **Strict Client-Side UTF-8 Validation.** Multi-byte UTF-8 character calculator (`calculateUtf8Bytes`) enforcing the strict $\le 280$ byte contract limit with live byte telemetry.
- **Dynamic Idempotency Nonce.** Automatically generates UUIDv4 `submissionId` in the controller architecture for on-chain deduplication without cluttering the user interface.

### 6. Activity Feed & Transaction Ledger
- **Expanded 7-Item Activity Window.** Displays up to 7 rich transaction items per view with calibrated 40px row heights and pagination controls (`‹ Page 1 of N ›`) (`ActivityLedgerView.qml`).
- **Inline Refresh Action.** High-contrast tactile action button utilizing a white alpha-cutout refresh icon (`Refresh.png`) located directly alongside the filter tabs.
- **Segmented Filter Tabs.** Real-time chronological transaction history filterable by *All*, *Transfers*, *Shields*, and *Testimonials*.
- **Monospace Telemetry.** High-contrast transaction rows detailing direction, status tags, relative timestamps, transfer amounts, and page-by-page navigation.

### 7. Keystore & Vault Security Settings
- **Card-Contained Settings Actions.** `SettingsModal.qml` places all security actions (`Restore from Seed`, `Lock/Unlock Vault`) directly inside the Security Card, eliminating detached floating buttons.
- **Streamlined Scope.** Focused strictly on vault security, active account details, and keystore management without unnecessary network latency noise.

### 8. Informed Consent dApp Approvals & LP-0023 Verification
- **Permission Scope Assignment.** Manages dApp connection grant permissions (`GrantKind::Read`, `GrantKind::Propose`) via `ApprovalManager.qml` and `ApprovalModal.qml`.
- **Plain-Language Effect Simulation.** Invokes `simulatePromptEffect` to calculate net state diff (e.g. `+100 LOGO`, `-0.001 LEZ`) and estimated gas fees before user authorization.
- **LP-0023 Source Verification.** Evaluates caller origin and displays verified status badges (`LP-0023 VERIFIED`, `UNVERIFIED SOURCE`, `UNTRUSTED`).
- **Dual Consent Affordance.** Explicit, unambiguous action buttons: `Reject (0)` vs `Authorize & Sign (1)`.

### 9. Zero-Knowledge Identity Accountability
- **Master Identity Commitment.** Reads and displays the master zero-knowledge public root anchor via `getIdentityCommitment` (`IdentityModal.qml`).
- **Scoped Nullifier Generator.** Derives domain-isolated pseudonyms (`deriveScopedNullifier`) with 1-click dApp domain presets (`governance.logos.co`, `voting.lez.org`, `dex.swap.lez`).
- **BIP-340 Schnorr Attestation.** Generates a fresh cryptographic random nonce on modal opening (`generateFreshChallenge()`) and signs attestation challenges via secp256k1 without requiring manual hex input.

## Directory Structure

```
e-wallet-ui/
├── assets/
│   ├── eWalletLogo.png             # Official 256x256 application icon
│   └── icons/                      # Source asset repository
│       └── Refresh.png             # Refresh icon
├── metadata.json                   # Basecamp module manifest (type: ui_qml)
├── flake.nix                       # Nix flake packaging (mkLogosQmlModule)
├── flake.lock                      # Pinned Nix lockfile
├── .gitignore                      # Git ignore file (build, caches, local dev runner)
├── qml/
│   ├── Main.qml                    # Decoupled root shell orchestrator (Bento Grid + Adaptive Scrolling)
│   ├── assets/
│   │   └── icons/
│   │       └── Refresh.png         # White alpha-cutout icon for plugin sandbox compatibility
│   ├── theme/
│   │   ├── Theme.qml               # Design tokens (#171717 canvas, #262626 card, #141414 inset)
│   │   └── qmldir
│   ├── controls/                   # Reusable tactile components (Zero Icon)
│   │   ├── Button.qml              # Tactile pill button (Primary Blue, Charcoal, Destructive, Icons)
│   │   ├── Card.qml                # Beveled physical container with standardized 38px header & spacing
│   │   ├── InsetPanel.qml          # Sunken OLED/LCD display panel
│   │   ├── TextField.qml           # Recessed input field with focus glow
│   │   ├── ProgressBar.qml         # Recessed grooved progress track
│   │   ├── SegmentedBar.qml        # Inset capsule for tactile multi-tab selections
│   │   ├── TabButton.qml           # Segmented tactile tab switch button
│   │   ├── ModalOverlay.qml        # Tactile modal dialog backdrop & card
│   │   └── qmldir
│   ├── state/                      # State & IPC controllers (Logic Layer)
│   │   ├── WalletBridge.qml        # IPC bridge to e_wallet_core (+ Mock harness)
│   │   ├── AccountStore.qml        # Reactive multi-account portfolio controller
│   │   ├── TransferController.qml  # Automated 4-way transfer route & LNS lookup controller
│   │   ├── FundingBridgeController.qml # EmPoWer mining REST & L1 ChannelDeposit bridge controller
│   │   ├── TestimonialController.qml   # On-chain zkVM testimonial broadcast controller
│   │   ├── ApprovalManager.qml     # dApp permission & LP-0023 effect simulation manager
│   │   └── qmldir
│   ├── views/                      # Decoupled modular Bento-Grid card components
│   │   ├── BalanceView.qml         # Hero balance card, pool breakdown, cascaded avatar & menu
│   │   ├── TransferView.qml        # Quick transfer card (To, "Your Accounts" chips, Amount + Max)
│   │   ├── FundingBridgeView.qml   # EmPoWer mining station & L1 → LEZ Channel Deposit terminal
│   │   ├── TestimonialsView.qml    # LP-0021 on-chain testimonial broadcast card (Auto-bound author)
│   │   ├── ActivityLedgerView.qml  # Filterable transaction ledger & real-time telemetry (7 items)
│   │   ├── OnboardingView.qml      # Initial vault onboarding & seed phrase setup screen
│   │   ├── LockScreenView.qml      # Argon2id vault unlock & lock screen
│   │   └── qmldir
│   └── modals/                     # Interactive modal dialogs (Overlay Layer)
│       ├── UnlockModal.qml         # Argon2id master password prompt
│       ├── CreateWalletModal.qml   # 12-word BIP-39 mnemonic generator & backup
│       ├── RestoreWalletModal.qml  # Seed phrase import & recovery
│       ├── CreateAccountModal.qml  # Public Unshielded / Private Shielded account creator
│       ├── AccountDetailModal.qml  # 32-byte key inspector & label editor
│       ├── ApprovalModal.qml       # LP-0023 dApp permission & effect simulation consent modal
│       ├── IdentityModal.qml       # Zero-knowledge identity commitment, nullifiers & BIP-340 Schnorr
│       ├── SettingsModal.qml       # Keystore security info & vault lock controls
│       └── qmldir
└── .github/workflows/              # Continuous integration pipelines
    ├── ci-linux.yml                # Linux Nix build & QML architecture verification
    ├── ci-macos.yml                # macOS build compatibility verification
    └── testnet-smoke.yml           # Live testnet sequencer health & packaging smoke
```

## Building & Installation

### Prerequisites
- [Nix Package Manager](https://nixos.org/download.html) with Flakes enabled.
- Core Module dependency [`e-wallet-core`](https://github.com/evice-labs/e-wallet-core), automatically resolved from git (`github:evice-labs/e-wallet-core` as defined in `flake.nix`), or optionally overridden with a local checkout via `--override-input e_wallet_core path:../e-wallet-core`.

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
# 1. Deploy Core Module (built directly from git or local directory)
nix build github:evice-labs/e-wallet-core#install-portable --impure
cp -rL result/modules/e_wallet_core ~/.local/share/Logos/LogosBasecamp/modules/

# (Alternative if developing alongside a local checkout in ../e-wallet-core):
# cp -rL ../e-wallet-core/result/modules/e_wallet_core ~/.local/share/Logos/LogosBasecamp/modules/

# 2. Deploy UI Module
nix build .#install-portable --impure
cp -rL result/plugins/e_wallet_ui ~/.local/share/Logos/LogosBasecamp/plugins/
```

When you launch `LogosBasecamp`, **Evice Wallet** will automatically appear in the workspace dock with the `eWalletLogo.png` icon.

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