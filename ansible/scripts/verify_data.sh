#!/bin/bash
# Verify data integrity in Redis cluster

echo "Verifying data integrity..."

missing_keys=0
total_keys=1000

for i in $(seq 1 1000); do
    value=$(redis-cli GET "key:$i")
    if [ "$value" != "value:$i" ]; then
        missing_keys=$((missing_keys + 1))
    fi
done

if [ $missing_keys -eq 0 ]; then
    echo "PASS: All $total_keys keys verified successfully"
    exit 0
else
    echo "FAIL: $missing_keys out of $total_keys keys are missing or incorrect"
    exit 1
fi
