import QtQuick

QtObject {
    id: gasCalc

    // Protocol Constants from logos-execution-zone (fee/core/src/market.rs)
    readonly property int baseFeeExec: 8          // BASE_FEE_EXEC_MIN (atomic units per execution cycle)
    readonly property int baseFeeStor: 8          // BASE_FEE_STOR_MIN (atomic units per byte of storage)
    readonly property double atomicPerLez: 1e9     // 1 LEZ = 1,000,000,000 atomic units

    // Execution Cycles benchmarks (RISC-V zkVM cycles)
    readonly property int gasPublicNative: 2968    // Standard native transparent transfer
    readonly property int gasPublicToken: 3450     // Standard fungible token transfer
    readonly property int gasShield: 409764        // market::PRIVATE_VERIFY_GAS (PrivacyPreserving shield verification)
    readonly property int gasPrivateVerify: 409764 // market::PRIVATE_VERIFY_GAS (Succinct receipt verification)
    readonly property int gasContractBase: 2968    // Base smart contract invocation overhead

    // Storage byte sizes (wire serialized message length)
    readonly property int storPublicNative: 280
    readonly property int storPublicToken: 320
    readonly property int storShield: 235661       // market::PROOF_BYTES (223047) + shield message/context bytes
    readonly property int storPrivate: 237302      // market::PROOF_BYTES (223047) + private tx message/context bytes
    readonly property int storContractBase: 430

    // Standard Declared Gas Limits
    readonly property int limitStandard: 10000000  // wallet::DEFAULT_GAS_LIMIT (fee_core::market::MAX_GAS_EXEC)
    readonly property int limitPrivate: 500000

    function calculateTransferGas(transferMode, isToken) {
        var execCycles = gasPublicNative;
        var storBytes = storPublicNative;
        var limit = limitStandard;

        if (transferMode === "pub_to_priv") {
            execCycles = gasShield;
            storBytes = storShield;
            limit = limitPrivate;
        } else if (transferMode === "priv_to_pub") {
            execCycles = gasPrivateVerify;
            storBytes = storPrivate;
            limit = limitPrivate;
        } else if (transferMode === "priv_to_priv") {
            execCycles = gasPrivateVerify;
            storBytes = storPrivate;
            limit = limitPrivate;
        } else {
            // pub_to_pub
            if (isToken) {
                execCycles = gasPublicToken;
                storBytes = storPublicToken;
            } else {
                execCycles = gasPublicNative;
                storBytes = storPublicNative;
            }
            limit = limitStandard;
        }

        return formatGasResult(execCycles, storBytes, limit);
    }

    function calculateContractCallGas(calldataLen) {
        var len = (calldataLen !== undefined && calldataLen !== null) ? Number(calldataLen) : 64;
        // Instruction execution cycles + Borsh payload deserialization (~8 cycles per byte)
        var execCycles = gasContractBase + 450 + Math.round(len * 8);
        var storBytes = storContractBase + len;
        return formatGasResult(execCycles, storBytes, limitStandard);
    }

    function formatGasResult(execCycles, storBytes, gasLimit) {
        // LEZ protocol formula: fee = (gas_exec * base_fee_exec) + (gas_stor * base_fee_stor)
        var atomicFee = (execCycles * baseFeeExec) + (storBytes * baseFeeStor);
        var feeLez = (atomicFee / atomicPerLez).toFixed(6);

        return {
            execCycles: execCycles,
            storBytes: storBytes,
            gasLimit: gasLimit,
            gasLimitFormatted: gasLimit.toLocaleString(),
            atomicFee: atomicFee,
            feeLez: feeLez,
            displayStr: execCycles.toLocaleString()
        };
    }

    function normalizeDisplay(rawGasUsed, isIncoming, category, status, detail) {
        if (isIncoming) {
            return "0 (Paid by Sender)";
        }
        var cat = String(category || "");
        var st = String(status || "");
        var det = String(detail || "");

        var isTestimonial = (cat === "Testimonials") || (st === "Ledger") || (det.indexOf("Broadcast") !== -1) || (det.indexOf("zkVM") !== -1);
        var isDapp = (cat === "dApps") || (st.toUpperCase() === "DAPP");
        var isPrivate = (cat === "Shields") || (st === "Private") || (st === "Shield") || (st === "Unshield");

        if (isDapp) {
            if (rawGasUsed && String(rawGasUsed).trim().length > 0 && rawGasUsed !== "-" && String(rawGasUsed).indexOf("2,968") === -1) {
                return String(rawGasUsed).replace(/\s*\([^)]*\)/g, "").replace(/\s*units\b/gi, "").replace(/(^|\s+)LEZ\b/gi, "$1").trim();
            }
            return "275,640";
        }
        if (isTestimonial) {
            return "275,456";
        }
        if (isPrivate) {
            return formatGasResult(gasPrivateVerify, storPrivate, limitPrivate).displayStr; // "409,764"
        }

        if (!rawGasUsed || rawGasUsed === "" || rawGasUsed === "-" || rawGasUsed.indexOf("2,968") !== -1 || rawGasUsed.indexOf("2968") !== -1) {
            return formatGasResult(gasPublicNative, storPublicNative, limitStandard).displayStr; // "2,968"
        }

        // Clean any residual "units", parentheses, or "LEZ" from past entries
        var cleaned = String(rawGasUsed).replace(/\s*\([^)]*\)/g, "").replace(/\s*units\b/gi, "").replace(/(^|\s+)LEZ\b/gi, "$1").trim();

        return cleaned || formatGasResult(gasPublicNative, storPublicNative, limitStandard).displayStr;
    }
}
