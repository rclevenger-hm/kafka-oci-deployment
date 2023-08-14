#!/bin/bash

JMX_PORT=9999
KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=$JMX_PORT -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"

echo "Gathering Kafka metrics..."
jmxterm -l localhost:$JMX_PORT -n -v silent -i <(echo "get -b kafka.server:type=BrokerTopicMetrics,name=MessagesInPerSec OneMinuteRate")

exit 0
