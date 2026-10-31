#!/usr/bin/env bash
# Prints the connection details the BitWisdom BTCPay plugin needs.
# Usage: ./connection-details.sh [container-name] [published-p2p-port]
# Receive-only: the key can read node info and create USDT invoices, nothing else.
set -euo pipefail
CONTAINER="${1:-bitwisdom-usdt-node_web_1}"
P2P_PORT="${2:-9740}"

docker exec -i -e HOST_NAME="$CONTAINER" -e P2P_PORT="$P2P_PORT" "$CONTAINER" sh -s << 'INNER'
NET=$(ls /data/.lnd/data/chain/bitcoin | head -1)
LNCLI="lncli --network=$NET --lnddir=/data/.lnd --rpcserver=localhost:10009"
DIR=/data/.lnd/baked
MAC=$DIR/usdtln-receive-combined.macaroon
mkdir -p "$DIR"

if [ ! -s "$MAC" ]; then
  SUFFIX=$(od -An -N4 -tx1 /dev/urandom | tr -d ' \n')
  ROOT=$(printf '%u' 0xffeeddcc$SUFFIX)
  $LNCLI bakemacaroon --root_key_id=$ROOT --allow_external_permissions \
    --save_to="$MAC" \
    uri:/lnrpc.Lightning/GetInfo \
    uri:/lnrpc.Lightning/ListChannels \
    uri:/lnrpc.Lightning/SubscribeInvoices \
    uri:/lnrpc.Lightning/LookupInvoice \
    uri:/lnrpc.Lightning/ListInvoices \
    uri:/tapchannelrpc.TaprootAssetChannels/AddInvoice \
    uri:/rfqrpc.Rfq/AddAssetBuyOrder \
    uri:/taprpc.TaprootAssets/GetInfo \
    uri:/taprpc.TaprootAssets/FetchAssetMeta > /dev/null
  echo "$SUFFIX" > "$DIR/usdtln-receive-combined.suffix"
fi

PUBKEY=$($LNCLI getinfo | grep identity_pubkey | cut -d'"' -f4)
SUFFIX=$(cat "$DIR/usdtln-receive-combined.suffix" 2>/dev/null || echo unknown)

echo "=== 1. gRPC address (litd, secure port) ==="
echo "${HOST_NAME}:8443"
echo
echo "=== 2. LiT TLS certificate (hex) ==="
od -An -tx1 -v /data/.lit/tls.cert | tr -d ' \n'; echo
echo
echo "=== 3. Receive-only macaroon (hex) - paste into BOTH plugin macaroon fields ==="
od -An -tx1 -v "$MAC" | tr -d ' \n'; echo
echo
echo "=== 4. Node URI for ordering channels ==="
echo "${PUBKEY}@<YOUR-PUBLIC-HOST-OR-ONION>:${P2P_PORT}"
echo "(public host / onion address not decided yet - see handoff notes)"
echo
echo "Network: $NET"
echo "Revoke this key with: lncli ... deletemacaroonid \$(printf '%u' 0xffeeddcc${SUFFIX})"
echo "Treat the macaroon like a password. Never log or commit it."
INNER
