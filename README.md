## Compile contract

```sh
  yarn compile
```

## Depoly contract

deploy to godwoken-polyjuice chain using truffle and `@polyjuice-provider/truffle`.

first, set a `.env` file:

```sh
cat > ./.env <<EOF
WEB3_JSON_RPC=<godwoken wb3 rpc>
PRIVATE_KEY=<your eth test private key, do not use in production>
ERC20_ADDRESS=<your erc20-proxy contract address, you can depoly through the localhost:6100 UI page in kicker>
EOF
```

then run

```sh
  yarn deploy
```
