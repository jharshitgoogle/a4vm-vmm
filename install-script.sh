echo "Hello from installer script"
bootstrapToken=$1
echo $bootstrapToken

curl -X POST https://httpbin.org/post -H "Content-Type: application/json" -d '{"bootstrapToken" : $bootstrapToken}'
