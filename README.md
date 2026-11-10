<p align="center">
  <img src="assets/wallez.png" alt="WALLEZ Logo" width="160" />
</p>

<p align="center">
  <span style="font-size: 32px; font-weight: 700; letter-spacing: -0.5px;">Wallez</span>
  <br />
  <span style="font-size: 15px; color: #888888;">Sovereign Desktop Wallet for Logos Basecamp &amp; LEZ</span>
</p>

<p align="center">
  <a href="LICENSE-APACHE"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" alt="License Apache" /></a>
  <a href="LICENSE-MIT"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License MIT" /></a>
  <img src="https://img.shields.io/badge/Platform-Logos%20Basecamp-orange.svg" alt="Logos Basecamp" />
  <img src="https://img.shields.io/badge/Network-LEZ%20Testnet%200.4-emerald.svg" alt="LEZ Testnet 0.4" />
  <img src="https://img.shields.io/badge/Design-Neo--Skeuomorphism-black.svg" alt="Neo-Skeuomorphism" />
</p>

## Overview

**WALLEZ** is the official user-facing desktop application module for the Logos Execution Zone (LEZ), designed and packaged natively for **Logos Basecamp**.

It presents a tactile, secure, and intuitive graphical interface that integrates seamlessly with the underlying [Core Module](https://github.com/evice-labs/e-wallet-core) (C++20 Universal Core Module) and the [SDK](https://github.com/evice-labs/lez-wallet-sdk) (pure Rust cryptographic engine).

### Core Design Philosophy: Modern Neo-Skeuomorphism
- **Tactile Materiality.** Deep charcoal canvas (`#171717`), physical card containers (`#262626`) with dual ambient/directional drop shadows, recessed OLED/LCD display bays (`#141414`), and 1px chiseled top specular highlights.
- **Unified Bento-Grid Layout & Responsive Mobile Breakpoint.** A streamlined, non-fragmented single-screen architecture replacing legacy multi-tab navbars with high-density modular card workspaces. On wide viewports, renders a 2x2 Bento grid with proportional row heights (40% / 60%). When crossing the responsive breakpoint (`< 880px`), dynamically collapses into an intuitive single-column vertical feed backed by an interactive synchronized scrollbar track and thumb with drag-and-tap navigation.
- **Cascaded Profile & Multi-Account Switcher with State Persistence.** Interactive cascaded avatar component embedded directly in the Hero Balance Card header. Features real-time initial badges, sliding reveal micro-animations, 1-click account switching (`⇄`), and a contextual profile drawer with subtle hover feedback (`#343434`). The active account is persistently tracked across session locks and unlocks via `lastActiveAccountId`, ensuring the user's selected account is always preserved upon reentry.
- **Vault Security & Automated Idle Auto-Lock.** Keystore encryption protected by memory-hard key derivation (Argon2id) and authenticated cipher suites (AES-256-GCM). Window-level user inactivity detection automatically engages an idle timer that purges volatile secrets and locks the wallet.
- **Zero-Redundancy Automated Validation Architecture.** Systems and state controllers automatically resolve active identity credentials, privacy routes, cryptographic nonces, and balances, eliminating redundant user inputs and error-prone manual validations.

## Implemented Workspaces & Feature Domains

### 1. Hardware Keystore & Vault Lifecycle
- **BIP-39 Mnemonic Management.** Create fresh 12-word recovery phrases or restore existing vaults with interactive seed verification (`CreateWalletModal.qml`, `RestoreWalletModal.qml`).
- **Argon2id Vault Protection.** Authenticated encryption using AES-256-GCM. Features instant tactile lock and unlock flows (`UnlockModal.qml`).
- **Session Auto-Lock.** Automatic idle timeout clearing volatile cryptographic credentials and sessions from memory upon inactivity.

### 2. Multi-Account Portfolio (Public Unshielded vs Private Shielded)
- **Account Switcher & Active Persistence.** Seamlessly toggle between transparent public accounts (`Public/...`) and shielded zero-knowledge accounts (`Private/...`) with distinct visual status badges (`BalanceView.qml`). Active account selections are persisted across wallet lock/unlock cycles in `AccountStore.qml`.
- **Unified Canonical Telemetry & Address Copy.** Clear visual presentation tailored to each account type. Displays the account's authentic balance, cryptographic privacy model (`PUBLIC ACCOUNT` vs `SHIELDED ZERO-KNOWLEDGE ACCOUNT`), and canonical address (`Public/<id>` or `Private/<id>`) with a 1-click clipboard copy affordance.
- **Streamlined Account Creation with Privacy Context.** Create new accounts (`CreateAccountModal.qml`) with clear `Public Unshielded` vs `Private Shielded` selectors and dynamic context cards explaining transparent on-chain addresses vs zero-knowledge commitments and nullifiers.
- **Asset Balances & Token Program Holdings.** Real-time balance queries across Native LEZ, Shielded Zero-Knowledge pools, and Logos Token Program holdings. `AccountStore.qml` dynamically queries `listTokenHoldings` and `listAllTokenHoldings` from the Core Module, mapping active tokens without hardcoded mock fallbacks.
- **Account Deletion & Safety Safeguards.** Safely delete non-primary accounts via the danger zone in `SettingsModal.qml`. Built-in safeguards enforce a minimum of 1 active account, automatically re-route to an adjacent account, persist deletion state (`deletedAccountsJson`), and immediately redirect the user back to the dashboard.

### 3. 4-Way Asset Transfers & Instant LNS Domain Resolution
- **Inline Route Indicator.** Positioned directly beneath the Amount & Max button row, displaying a clean white `"Route:"` label with status-colored route paths (`Public ➝ Public`, `Public ➝ Shield`, `Shield ➝ Public`, `Shield ➝ Shield`).
- **Automated Privacy Route Detection.** `TransferController.qml` automatically inspects the sender's account privacy and recipient identifier prefix (`Private/...` vs `Public/...` vs `.lez`) to configure the route mode (`pub_to_pub`, `pub_to_priv`, `priv_to_pub`, `priv_to_priv`) with zero manual toggle overhead.
- **Fresh Shielded Recipient Safety Notice.** Built-in validation checks inform the user when shielding (`Public ➝ Private`) to a freshly created private account with 0 balance, ensuring the amount exceeds the required private fee reserve (`> 5,070,616 raw units`) to prevent execution errors.
- **"Your Accounts" 1-Click Quick Selector.** `TransferView.qml` automatically displays 1-click chip buttons for user's other accounts in the wallet, eliminating manual address typing or copy-pasting for intra-wallet transfers and shielding operations.
- **Clean-Room LNS Resolver.** Resolves human-readable `.lez` names (e.g. `alice.lez`, `bob.lez`) asynchronously via debounced queries to the sequencer LNS registry, displaying real-time verification indicators.
- **Automatic Gas & Max Spend Calculation.** Dynamically queries gas limit seeds (`getGasLimit`, default: `34,000 units`) from the Core Module and calculates spendable maximum balances accordingly.

### 4. Canonical Funding Path: EmPoWer PoW Mining & L1 → LEZ Bridge
*Directly integrated with Logos Blockchain node architecture and canonical EmPoWer bridging via `e-wallet-core` & `lez-wallet-sdk`:*
- **EmPoWer Mining Station.** Native IPC integration through `e-wallet-core` (`getPowStatus`, `startPowMining`, `stopPowMining`, `channelDeposit`) backed by `lez-wallet-sdk` (`PUT /pow/mining/start`, `PUT /pow/auto-claim/start`, `PUT /pow/mining/stop`, `GET /pow/status`, `POST /pow/claim`, `POST /channel/deposit`), completely compliant with Logos Basecamp's `ui_qml` zero-network sandbox (`FundingBridgeView.qml`, `FundingBridgeController.qml`).
- **Dual-Action Segmented Controls.** Tactile segmented switch (`Start Mining` vs `Bridge Tokens`) housed in an inset trough capsule with real-time hash rate and status indicators (`POW ACTIVE • 1920 H/S`).
- **L1 → LEZ Channel Deposit Bridge.** One-click bridging terminal that deposits mined L1 notes into the user's active LEZ Public account via on-chain `ChannelDeposit` transactions while enforcing the Asymmetric Deposit Trap guardrail.
- **Zero-Redundancy Automation.** The recipient LEZ address is automatically locked to the user's active account (`accountStore.activeAccount`), the deposit amount is automatically calculated from the total unbridged L1 balance, and worker threads are preset to 4 threads.
- **Asynchronous Settlement & Status Taxonomy.** Bridged deposits initialize in a dedicated `CHANNEL BRIDGE` state with dark yellow branding (`#D4A017`) and `Block: Pending`, avoiding premature success indications until on-chain sequencer block inclusion is confirmed via native transaction reconciliation.

### 5. On-Chain Testimonials Mini-App
- **On-Chain Testimonial Engine.** Built-in workspace enabling users to publish on-chain testimonials directly to the testnet zkVM `testimonial-program` (`TestimonialsView.qml`, `TestimonialController.qml`).
- **Auto-Bound Active Account Author.** The author identity is strictly and automatically derived from the active account currently open in the wallet (`accountStore.activeAccount`). The UI renders a clean read-only affordance: `Posting as: [alice.lez]`, with zero manual username or moniker input.
- **Standardized Physical Dimensions.** Submit button dimensions calibrated to match the tactile heights across adjacent card action rows.
- **Strict Client-Side UTF-8 Validation.** Multi-byte UTF-8 character calculator (`calculateUtf8Bytes`) enforcing the strict $\le 280$ byte contract limit with live byte telemetry.
- **Dynamic Idempotency Nonce.** Automatically generates UUIDv4 `submissionId` in the controller architecture for on-chain deduplication without cluttering the user interface.

### 6. Activity Feed & Transaction Ledger
- **Expanded 7-Item Activity Window.** Displays up to 7 rich transaction items per view with calibrated 40px row heights and pagination controls (`‹ Page 1 of N ›`) (`ActivityLedgerView.qml`).
- **Deterministic zkVM Gas Telemetry & Reserve Normalization.** Evaluates and normalizes gas execution cycles in `TxDetailModal.qml` and `ActivityLedgerView.qml` via `GasCalculator.qml` (`gasCalc.normalizeDisplay(...)`), accurately reflecting execution gas baselines (`275,456` raw units for smart contract/transfer reserves, `2,968` for standard public transfers, `3,778` for zkVM contract calls, `12,400` for note shielding, and `409,764` for private ZK verifications).
- **Protocol-Adaptive Sequencer Reconciliation Engine.** All transactions requiring sequencer inclusion (Transfers, Channel Bridge Deposits, Contract Invocations) share a unified, event-driven reconciliation pipeline (`reconciliationTimer`). The poller queries `getTransactionStatus` directly via `e-wallet-core` (adhering to Basecamp's zero-network sandbox), dynamically tracking `Pending` status until confirmed with height (`Block #<height>`), or marking as dropped if missing from mempool after retry cycles. The timer runs strictly on-demand when pending transactions exist, auto-stopping upon settlement.
- **Strict Status Taxonomy & Theme Palette.** Enforces consistent, non-redundant visual status cues: dark yellow (`theme.accentDarkYellow`, `#D4A017`) for `CHANNEL BRIDGE` in-flight deposits, amber/muted gray for pending sequencer states, status-success green (`theme.statusSuccess`) exclusively for confirmed transfers, and destructive red (`theme.statusDanger`) for reverted/failed operations.
- **Inline Refresh Action.** High-contrast tactile action button utilizing a white alpha-cutout refresh icon (`Refresh.png`) located directly alongside the filter tabs.
- **Segmented Filter Tabs.** Real-time chronological transaction history filterable by *All*, *Transfers*, *Shields*, and *Testimonials*.
- **Monospace Telemetry.** High-contrast transaction rows detailing direction, status tags, relative timestamps, transfer amounts, and page-by-page navigation.

### 7. Keystore & Comprehensive Vault Settings
- **Unified Account & Keystore Management.** Consolidated `SettingsModal.qml` serves as the centralized hub for account and keystore configuration, eliminating fragmented dialogs:
  - **Account Customization & Labeling:** Copy full account ID, inline label renaming with instantaneous UI feedback and disk persistence (`labelsJson`).
  - **Danger Zone (Account Deletion):** Secure inline confirmation with automatic fallback account selection and dashboard redirection.
  - **Master Vault Password Change:** Re-encrypt the Argon2id keystore with new passphrase credentials directly from the settings interface.
  - **Secret Key Inspector & Export:** Protected 32-byte private key inspection with explicit security disclosure and auto-clearing clipboard feedback.
  - **Connected dApp Session Management:** Real-time list of active dApp authorizations with 1-click permission revocation.
  - **Storage Telemetry & Keystore Actions:** Instant copy for on-disk vault storage locations, seed phrase restore triggers, and quick access to ZK identity accountability.
  - **Synchronized Scrollbar Navigation:** Integrated scroll track and thumb providing effortless navigation across all settings categories.

### 8. Informed Consent dApp Approvals & Program Source Verification
- **Permission Scope Assignment.** Manages dApp connection grant permissions (`GrantKind::Read`, `GrantKind::Propose`) via `ApprovalManager.qml` and `ApprovalModal.qml`.
- **Plain-Language Effect Simulation.** Invokes `simulatePromptEffect` to calculate net state diff (e.g. `+100 LOGO`, `-0.001 LEZ`) and estimated gas fees before user authorization.
- **Program Source Verification.** Evaluates caller origin and displays verified status badges (`VERIFIED`, `UNVERIFIED SOURCE`, `UNTRUSTED`).
- **Dual Consent Affordance.** Explicit, unambiguous action buttons: `Reject (0)` vs `Authorize & Sign (1)`.

### 9. Zero-Knowledge Identity Accountability (Domain 6)
- **Direct Cryptographic Wiring (Zero Mock Fallbacks).** Purged all hardcoded mock strings. All identity operations interact directly with the Rust SDK engine via C-ABI FFI and `e-wallet-core`.
- **Automatic Internal Session Grants.** `WalletBridge.qml` automatically requests `IdentityRead` and `IdentityPropose` grants during internal Basecamp session handshakes, enabling seamless ZK operations without manual friction.
- **Master Identity Commitment.** Reads and displays the master zero-knowledge public root anchor via `getIdentityCommitment` (`IdentityModal.qml`).
- **Scoped Nullifier Generator.** Derives domain-isolated pseudonyms (`deriveScopedNullifier`) with 1-click dApp domain presets (`governance.logos.co`, `voting.lez.org`, `dex.swap.lez`).
- **BIP-340 Schnorr Attestation.** Generates a fresh cryptographic random nonce on modal opening (`generateFreshChallenge()`) and signs attestation challenges via secp256k1 without requiring manual hex input.

### 10. Canonical Demonstration dApp: Logos DAO Governance Mini-App
- Built as an independent standalone Basecamp module (`/home/namauser/logos-ecosystem/dao-miniapp`) serving as the canonical reference dApp demonstration.
- Demonstrates decentralized anonymous voting: citizen verification via Master Commitment, proposal-scoped nullifiers for Sybil-resistance (1 citizen = 1 vote per proposal, unlinkable across proposals), and BIP-340 Schnorr signed ballot submission via `proposeContractCall`.

## Directory Structure

```
e-wallet-ui/
├── assets/
│   ├── wallez.png                  # Official WALLEZ 256x256 application icon
│   ├── icon.png                    # Basecamp module icon
│   └── icons/                      # Source asset repository
│       └── Refresh.png             # Refresh icon
├── metadata.json                   # Basecamp module manifest (type: ui_qml)
├── flake.nix                       # Nix flake packaging (mkLogosQmlModule)
├── flake.lock                      # Pinned Nix lockfile
├── .gitignore                      # Git ignore file (build, caches, local dev runner)
├── qml/
│   ├── Main.qml                    # Bento Grid + Responsive Breakpoint + Adaptive Scrollbar
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
│   │   ├── AccountStore.qml        # Reactive multi-account controller (Persistence across locks, label map & deletion)
│   │   ├── TransferController.qml  # Automated 4-way transfer route & LNS lookup controller
│   │   ├── FundingBridgeController.qml # EmPoWer mining & L1 ChannelDeposit bridge IPC controller
│   │   ├── TestimonialController.qml   # On-chain zkVM testimonial broadcast controller
│   │   ├── ApprovalManager.qml     # dApp permission & effect simulation manager
│   │   ├── GasCalculator.qml       # Deterministic zkVM gas cycles & fee calculation engine
│   │   └── qmldir
│   ├── views/                      # Decoupled modular Bento-Grid card components
│   │   ├── BalanceView.qml         # Hero balance card, pool breakdown, cascaded avatar & menu
│   │   ├── TransferView.qml        # Quick transfer card (To, "Your Accounts" chips, Amount + Max)
│   │   ├── FundingBridgeView.qml   # EmPoWer mining station & L1 → LEZ Channel Deposit terminal
│   │   ├── TestimonialsView.qml    # On-chain testimonial broadcast card (Auto-bound author)
│   │   ├── ActivityLedgerView.qml  # Filterable transaction ledger & real-time telemetry (7 items)
│   │   ├── OnboardingView.qml      # Initial vault onboarding & seed phrase setup screen
│   │   ├── LockScreenView.qml      # Argon2id vault unlock & lock screen
│   │   └── qmldir
│   └── modals/                     # Interactive modal dialogs (Overlay Layer)
│       ├── UnlockModal.qml         # Argon2id master password prompt
│       ├── CreateWalletModal.qml   # 12-word BIP-39 mnemonic generator & backup
│       ├── RestoreWalletModal.qml  # Seed phrase import & recovery
│       ├── CreateAccountModal.qml  # Public Unshielded / Private Shielded account creator with privacy context
│       ├── ApprovalModal.qml       # dApp permission & effect simulation consent modal
│       ├── IdentityModal.qml       # Zero-knowledge identity commitment, nullifiers & BIP-340 Schnorr
│       ├── ProfileModal.qml        # Account identity switcher & sequential dApp request queue modal
│       ├── SettingsModal.qml       # Comprehensive account config, renaming, deletion, password change, key export & permissions
│       ├── TxDetailModal.qml       # Detailed on-chain transaction telemetry & block inspector
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

When you launch `LogosBasecamp`, **WALLEZ** will automatically appear in the workspace dock with the `wallez.jpg` icon.

## Continuous Integration & Quality Assurance

Automated GitHub Actions workflows are configured in `.github/workflows/`:
- **`ci-linux.yml`:** Validates `metadata.json` integrity, verifies `wallez.png` icon presence, enforces decoupled architecture line thresholds on `qml/Main.qml`, runs hermetic `qmlformat` styling and `qmllint` syntax/type checks via native `nix flake check`, and builds the module and portable bundles.
- **`ci-macos.yml`:** Validates Nix package compilation on `macos-latest`.
- **`testnet-smoke.yml`:** Periodic weekly workflow that tests live JSON-RPC connectivity with the LEZ testnet sequencer (`https://testnet.lez.logos.co`), checking `checkHealth`, `getLastBlockId`, and `getFeeState` before validating bundle construction.

## License

Dual-licensed under either:
- **Apache License, Version 2.0** ([LICENSE-APACHE](LICENSE-APACHE))
- **MIT License** ([LICENSE-MIT](LICENSE-MIT))

at your option.