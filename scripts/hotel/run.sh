read -p "Please Input request rate (default: 100)" rate
rate=${rate:-100}
echo "Compiling"
make clean
make hotel
echo "Deploying"
sls deploy -c hotel.yml
read -p "Please Input HTTP gateway url for beldi-dev-gateway: " bp
echo "Initializing Database"
go run ./internal/hotel/init/init.go clean beldi
sleep 60
go run ./internal/hotel/init/init.go create beldi
sleep 60
go run ./internal/hotel/init/init.go populate beldi
echo "Running beldi"
ENDPOINT="$bp" ./tools/wrk -t4 -c$rate -d420s -R$rate -s ./benchmark/hotel/workload.lua --timeout 10s "$bp"
echo "Collecting metrics"
python ./scripts/hotel/hotel.py --command run --config beldi --duration 7
echo "Cleanup"
go run ./internal/hotel/init/init.go clean beldi
