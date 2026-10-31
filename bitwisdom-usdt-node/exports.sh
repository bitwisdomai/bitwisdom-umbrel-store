export APP_BITWISDOM_USDT_NODE_WALLET_PASSWORD="$(derive_entropy "${app_entropy_identifier}-wallet-password")"

case "${APP_BITCOIN_NETWORK:-}" in
	mainnet|testnet|testnet4|signet|regtest)
		export APP_BITWISDOM_USDT_NODE_CHAIN_FLAG="--lnd.bitcoin.${APP_BITCOIN_NETWORK}"
		;;
	*)
		echo "Warning (${EXPORTS_APP_ID}): Bitcoin network '${APP_BITCOIN_NETWORK:-unset}' is not supported"
		export APP_BITWISDOM_USDT_NODE_CHAIN_FLAG="--lnd.bitcoin.mainnet"
		;;
esac

# Price service for USDT quotes: real one on mainnet, litd's built-in mock on regtest only, unset elsewhere.
case "${APP_BITCOIN_NETWORK:-}" in
	mainnet)
		oracle_address="rfqrpc://price-oracle.amboss.tech:443"
		;;
	regtest)
		oracle_address="use_mock_price_oracle_service_promise_to_not_use_on_mainnet"
		;;
	*)
		oracle_address=""
		;;
esac
export APP_BITWISDOM_USDT_NODE_ORACLE_FLAG="--taproot-assets.experimental.rfq.priceoracleaddress=${oracle_address}"
