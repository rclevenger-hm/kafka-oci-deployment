#!/bin/bash

echo "Gathering Kafka Manager metrics..."
jstat -gcutil $(pgrep -f kafka-manager)

exit 0
