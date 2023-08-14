#!/bin/bash

echo "Gathering Zookeeper metrics..."
echo mntr | nc localhost 2181

exit 0
