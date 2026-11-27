## Changelog

All notable changes to the Wallez UI Module are documented in this file.

## [v0.3.0] - 2026-11-28

### LEZ Testnet 0.4 & Core Module v0.3.0 Alignment
- **Network Branding (`qml/views/OnboardingView.qml`, `qml/modals/TxDetailModal.qml`):** Updated Testnet labels to `LOGOS LEZ TESTNET 0.4` and `Logos LEZ Testnet 0.4`.
- **Dual-Market Gas & Shielding Fee Calibration (`qml/state/GasCalculator.qml`, `qml/state/TransferController.qml`, views):**
  - Updated `limitStandard` fallback to `10,000,000` (`wallet::DEFAULT_GAS_LIMIT`) and calibrated `pub_to_priv` / private `storBytes` & `gasShield` constants against LEZ `v0.4.0` (`PRIVATE_VERIFY_GAS = 409,764`, `PROOF_BYTES = 223,047`).
  - Updated `setMaxAmount()` and `validate()` to reserve `GasCalculator` dual-market fees instead of subtracting raw `gasLimitValue` or checking pre-v0.4.0 `5,070,616` recipient bounds.
- **Module Packaging & Version Bump (`flake.lock`, `metadata.json`, `README.md`):** Updated `e_wallet_core` flake input to `v0.3.0`, synchronized `README.md`, and bumped `metadata.json` to `0.3.0`.

## [v0.2.6] - 2026-11-26

### Onboarding & Ledger Refinements (PR #16)
- **Split-Card Onboarding & Ledger Stall Detection (`b00ea70`):** Refined split-card onboarding layout, unified corner radii across controls, and added ledger stall detection.

## [v0.2.5] - 2026-11-18

### BIP-39 Restore & Theme Fixes (PR #15)
- **Restore Lengths & LGO Unit Labels (`7ff941c`, `71e0e5b`):** Supported 12/15/18/21/24-word BIP-39 restore lengths, standardized LGO unit labels, aligned theme tokens, and formatted `OnboardingView.qml` with `qmlformat`.

## [v0.2.4] - 2026-11-16

### Approval Modal & Timeout Sync (PR #13)
- **Redesigned Approval Flow (`db591d5`, `e92b063`):** Redesigned `ApprovalModal.qml`, fixed `UNVERIFIED` parsing, synchronized cancel/timeout states, and bumped `metadata.json` to `0.2.4`.

## [v0.2.3] - 2026-11-16

### Universal dApp Approvals & Ledger Hardening (PR #12)
- **dApp Approvals & Activity Tracking (`ba8f0ad`, `4851606`):** Added universal dApp approval prompts, unified activity tracking, ledger hardening, and bumped `metadata.json` to `0.2.3`.

## [v0.2.2] - 2026-11-11

### UI & Layout Hardening
- **Add Token Holding Modal Layout Fix (`qml/modals/AddTokenModal.qml`):**
  - Resolved layout collision where action buttons ("Cancel" and "Add Token Holding") overlapped and clipped the bottom rounded border of the "HOLDING ACCOUNT & PRIVACY CONFIGURATION" card.
  - Relocated modal action buttons to the modal footer level with an elastic layout spacer (`Item { Layout.fillHeight: true }`).
  - Corrected vertical margin calculations (`implicitHeight: + 24`) for both specification cards.
  - Adjusted modal `dialogHeight` from `485` to `525` to provide comfortable visual padding without clipping.
- **Dynamic Block Height Status Display (`qml/modals/TxDetailModal.qml`, `qml/views/ActivityLedgerView.qml`):**
  - Updated confirmed transactions to display authentic block height format (`Block #<height>`), replacing static text labels.
- **Deposit Bridging & Button Styling (`qml/views/FundingBridgeView.qml`, `qml/state/FundingBridgeController.qml`):**
  - Restored "Bridging..." action button text color to crisp white.
  - Removed obsolete "in mempool" button state.
  - Synchronized "Bridging..." button state with active mining deposit activity until confirmed by the sequencer, upon which "Start Mining" becomes re-enabled.
- **Pure & Idiomatic Reconciliation Logic:**
  - Removed arbitrary client-side drop assumption timers, establishing live sequencer JSON-RPC queries via `e-wallet-core` as the single source of truth for transaction confirmation.
- **Module Version:**
  - Bumped module version in `metadata.json` to `0.2.2`.

## [v0.2.1] - 2026-11-10

### Features & Telemetry
- **Protocol-Adaptive Sequencer Reconciliation Engine:**
  - Event-driven reconciliation timer querying `getTransactionStatus` directly via `e-wallet-core` adhering to Basecamp's zero-network sandbox.
- **Deterministic zkVM Gas Telemetry & Reserve Normalization:**
  - Evaluates and normalizes gas execution cycles in `TxDetailModal.qml` and `ActivityLedgerView.qml` via `GasCalculator.qml` (275,456 baseline reserve).
- **Status Taxonomy Hardening:**
  - Dark yellow branding (`#D4A017`) for in-flight channel deposits, amber/muted gray for pending sequencer states.

## [v0.2.0] - 2026-11-09

### Initial Stable Release
- Neo-skeuomorphic single-screen Bento grid UI.
- 4-way asset transfer routing (Public/Shielded).
- Multi-account portfolio with persistent active selection.
- Native EmPoWer mining station and L1 → LEZ bridge view.
- On-chain testimonials mini-app.
- Hardware keystore settings and informed consent approvals.

