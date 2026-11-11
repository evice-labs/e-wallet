## Changelog

All notable changes to the Wallez UI Module are documented in this file.

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

