#!/bin/bash

# Kafka topic setup script for JTS
# Run this after Kafka cluster is up

KAFKA_BOOTSTRAP_SERVERS="localhost:9092,localhost:9093,localhost:9094"

echo "Waiting for Kafka to be ready..."
sleep 10

# Create market data topics with high throughput settings
echo "Creating market data topics..."

# Korean stock market data
docker exec jts-kafka1 kafka-topics --create \
  --bootstrap-server kafka1:29092 \
  --topic market-data.krx.ticks \
  --partitions 12 \
  --replication-factor 2 \
  --config retention.ms=86400000 \
  --config segment.ms=3600000 \
  --config compression.type=lz4 \
  --config max.message.bytes=1000000

docker exec jts-kafka1 kafka-topics --create \
  --bootstrap-server kafka1:29092 \
  --topic market-data.krx.candles \
  --partitions 6 \
  --replication-factor 2 \
  --config retention.ms=604800000 \
  --config segment.ms=86400000 \
  --config compression.type=lz4

# Cryptocurrency market data
docker exec jts-kafka1 kafka-topics --create \
  --bootstrap-server kafka1:29092 \
  --topic market-data.crypto.ticks \
  --partitions 12 \
  --replication-factor 2 \
  --config retention.ms=86400000 \
  --config segment.ms=3600000 \
  --config compression.type=lz4

docker exec jts-kafka1 kafka-topics --create \
  --bootstrap-server kafka1:29092 \
  --topic market-data.crypto.candles \
  --partitions 6 \
  --replication-factor 2 \
  --config retention.ms=604800000 \
  --config segment.ms=86400000 \
  --config compression.type=lz4

# Trading signal topics
echo "Creating trading signal topics..."

docker exec jts-kafka1 kafka-topics --create \
  --bootstrap-server kafka1:29092 \
  --topic signals.entry.buy \
  --partitions 3 \
  --replication-factor 2 \
  --config retention.ms=2592000000 \
  --config compression.type=snappy

docker exec jts-kafka1 kafka-topics --create \
  --bootstrap-server kafka1:29092 \
  --topic signals.entry.sell \
  --partitions 3 \
  --replication-factor 2 \
  --config retention.ms=2592000000 \
  --config compression.type=snappy

docker exec jts-kafka1 kafka-topics --create \
  --bootstrap-server kafka1:29092 \
  --topic signals.exit.all \
  --partitions 3 \
  --replication-factor 2 \
  --config retention.ms=2592000000 \
  --config compression.type=snappy

# Order execution topics
echo "Creating order execution topics..."

docker exec jts-kafka1 kafka-topics --create \
  --bootstrap-server kafka1:29092 \
  --topic orders.pending \
  --partitions 3 \
  --replication-factor 2 \
  --config retention.ms=86400000 \
  --config compression.type=snappy

docker exec jts-kafka1 kafka-topics --create \
  --bootstrap-server kafka1:29092 \
  --topic orders.executions \
  --partitions 3 \
  --replication-factor 2 \
  --config retention.ms=2592000000 \
  --config compression.type=snappy \
  --config min.insync.replicas=2

docker exec jts-kafka1 kafka-topics --create \
  --bootstrap-server kafka1:29092 \
  --topic orders.failures \
  --partitions 3 \
  --replication-factor 2 \
  --config retention.ms=604800000 \
  --config compression.type=snappy

# Portfolio and risk topics
echo "Creating portfolio and risk topics..."

docker exec jts-kafka1 kafka-topics --create \
  --bootstrap-server kafka1:29092 \
  --topic portfolio.updates \
  --partitions 3 \
  --replication-factor 2 \
  --config retention.ms=2592000000 \
  --config compression.type=snappy

docker exec jts-kafka1 kafka-topics --create \
  --bootstrap-server kafka1:29092 \
  --topic risk.alerts \
  --partitions 3 \
  --replication-factor 2 \
  --config retention.ms=604800000 \
  --config compression.type=snappy

docker exec jts-kafka1 kafka-topics --create \
  --bootstrap-server kafka1:29092 \
  --topic risk.metrics \
  --partitions 3 \
  --replication-factor 2 \
  --config retention.ms=86400000 \
  --config compression.type=snappy

# System monitoring topics
echo "Creating system monitoring topics..."

docker exec jts-kafka1 kafka-topics --create \
  --bootstrap-server kafka1:29092 \
  --topic system.health \
  --partitions 3 \
  --replication-factor 2 \
  --config retention.ms=259200000 \
  --config compression.type=snappy

docker exec jts-kafka1 kafka-topics --create \
  --bootstrap-server kafka1:29092 \
  --topic system.errors \
  --partitions 3 \
  --replication-factor 2 \
  --config retention.ms=604800000 \
  --config compression.type=snappy

docker exec jts-kafka1 kafka-topics --create \
  --bootstrap-server kafka1:29092 \
  --topic system.metrics \
  --partitions 3 \
  --replication-factor 2 \
  --config retention.ms=86400000 \
  --config compression.type=lz4

# Backtesting topics
echo "Creating backtesting topics..."

docker exec jts-kafka1 kafka-topics --create \
  --bootstrap-server kafka1:29092 \
  --topic backtest.requests \
  --partitions 3 \
  --replication-factor 2 \
  --config retention.ms=86400000 \
  --config compression.type=snappy

docker exec jts-kafka1 kafka-topics --create \
  --bootstrap-server kafka1:29092 \
  --topic backtest.results \
  --partitions 3 \
  --replication-factor 2 \
  --config retention.ms=2592000000 \
  --config compression.type=snappy

echo "Listing all topics..."
docker exec jts-kafka1 kafka-topics --list --bootstrap-server kafka1:29092

echo "Topic setup complete!"