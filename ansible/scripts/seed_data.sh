#!/bin/bash
# Seed test data into Redis cluster

echo "Seeding 1000 test keys into Redis cluster..."

for i in $(seq 1 1000); do
    redis-cli SET "key:$i" "value:$i"
done

echo "Data seeding completed. Total keys: $(redis-cli DBSIZE)"
