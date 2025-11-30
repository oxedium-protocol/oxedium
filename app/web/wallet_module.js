const { VersionedTransaction } = solanaWeb3;

let pubKey = '';

function isInstalled(wallet) {
    return typeof window[wallet] !== "undefined";
}

async function connect(wallet) {
    const provider = window[wallet]?.solana || window[wallet];
    const resp = await provider?.connect();
    pubKey = resp?.publicKey?.toString() || provider.publicKey?.toString();
}


function address() {
    return pubKey;
}

function disconnect(wallet) {
    const provider = window[wallet]?.solana || window[wallet];
    return provider?.disconnect();
}

async function sendTransaction(wallet, tx) {
    const deserializedTx = VersionedTransaction.deserialize(tx);
    const provider = window[wallet]?.solana || window[wallet];
    const transaction = await provider?.signAndSendTransaction(deserializedTx);
    return transaction?.signature;
}


window.walletModule = { 
    isInstalled,
    connect,
    address,
    disconnect,
    sendTransaction
};
