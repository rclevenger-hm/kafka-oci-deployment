#!/bin/bash

echo "Gathering Schema Registry metrics..."
curl -s localhost:8081/metrics

exit 0
