# Kafka Setup Guide for JTS

## Prerequisites
- Docker and Docker Compose installed
- At least 20GB free disk space (100GB+ recommended when 4TB SSD is installed)
- Ports 2181, 8080, 8081, 9092-9094 available

## Initial Setup (Without 4TB SSD)

1. **Create data directories:**
```bash
cd infrastructure/kafka
mkdir -p data/zookeeper/data data/zookeeper/logs
mkdir -p data/kafka/kafka1 data/kafka/kafka2 data/kafka/kafka3
```

2. **Start Kafka cluster:**
```bash
docker-compose -f docker-compose.kafka.yml up -d
```

3. **Verify cluster health:**
```bash
# Check if all containers are running
docker-compose -f docker-compose.kafka.yml ps

# Check Kafka cluster status
docker exec jts-kafka1 kafka-broker-api-versions --bootstrap-server kafka1:29092
```

4. **Create topics:**
```bash
chmod +x setup-topics.sh
./setup-topics.sh
```

5. **Access Kafka UI:**
Open browser at http://localhost:8080 to monitor topics and messages

## After Installing 4TB SSD

1. **Stop Kafka cluster:**
```bash
docker-compose -f docker-compose.kafka.yml down
```

2. **Mount the SSD (example for Samsung 990 PRO):**
```bash
# Find the device
sudo fdisk -l

# Create partition (assuming /dev/nvme1n1)
sudo parted /dev/nvme1n1 mklabel gpt
sudo parted /dev/nvme1n1 mkpart primary ext4 0% 100%

# Format partition
sudo mkfs.ext4 /dev/nvme1n1p1

# Create mount point
sudo mkdir -p /mnt/ssd4tb

# Mount permanently (add to /etc/fstab)
echo "UUID=$(sudo blkid -s UUID -o value /dev/nvme1n1p1) /mnt/ssd4tb ext4 defaults,noatime 0 2" | sudo tee -a /etc/fstab
sudo mount -a

# Set permissions
sudo chown -R $USER:$USER /mnt/ssd4tb
```

3. **Move Kafka data to SSD:**
```bash
# Create Kafka directories on SSD
mkdir -p /mnt/ssd4tb/kafka/{kafka1,kafka2,kafka3}
mkdir -p /mnt/ssd4tb/zookeeper/{data,logs}

# Copy existing data (if any)
cp -r data/kafka/* /mnt/ssd4tb/kafka/
cp -r data/zookeeper/* /mnt/ssd4tb/zookeeper/
```

4. **Update docker-compose.kafka.yml volumes:**
Replace the volume paths:
```yaml
# Old path:
- ./data/kafka/kafka1:/var/lib/kafka/data
# New path:
- /mnt/ssd4tb/kafka/kafka1:/var/lib/kafka/data
```

5. **Restart Kafka cluster:**
```bash
docker-compose -f docker-compose.kafka.yml up -d
```

## Performance Tuning

### System Settings (Linux)
Add to `/etc/sysctl.conf`:
```bash
# Network optimizations for Kafka
net.core.rmem_default=31457280
net.core.rmem_max=33554432
net.core.wmem_default=31457280
net.core.wmem_max=33554432
net.core.netdev_max_backlog=5000
net.ipv4.tcp_rmem=4096 87380 33554432
net.ipv4.tcp_wmem=4096 65536 33554432
net.ipv4.tcp_max_syn_backlog=8096
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_tw_reuse=1
net.ipv4.ip_local_port_range=10240 65535

# File system
vm.swappiness=1
vm.dirty_background_ratio=5
vm.dirty_ratio=15
```

Apply settings:
```bash
sudo sysctl -p
```

### JVM Heap Settings
For production with 128GB RAM, update Kafka environment in docker-compose:
```yaml
KAFKA_HEAP_OPTS: "-Xmx8G -Xms8G"
KAFKA_JVM_PERFORMANCE_OPTS: "-XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35 -XX:+ExplicitGCInvokesConcurrent"
```

## Monitoring

### Key Metrics to Monitor
- **Throughput**: Messages/sec per topic
- **Latency**: End-to-end latency for critical topics
- **Disk Usage**: Monitor /mnt/ssd4tb usage
- **Consumer Lag**: Ensure consumers keep up with producers

### Prometheus Metrics (Optional)
Add JMX exporter for Prometheus:
```yaml
kafka-exporter:
  image: danielqsj/kafka-exporter:latest
  container_name: jts-kafka-exporter
  command: ["--kafka.server=kafka1:29092", "--kafka.server=kafka2:29093", "--kafka.server=kafka3:29094"]
  ports:
    - "9308:9308"
  networks:
    - jts-network
```

## Backup Strategy

1. **Critical Topics Backup:**
```bash
# Backup script (run daily)
#!/bin/bash
BACKUP_DIR="/mnt/nas/kafka-backups/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Export important topics
for topic in orders.executions portfolio.updates risk.alerts; do
  docker exec jts-kafka1 kafka-console-consumer \
    --bootstrap-server kafka1:29092 \
    --topic $topic \
    --from-beginning \
    --property print.timestamp=true \
    --timeout-ms 10000 > $BACKUP_DIR/$topic.json
done
```

2. **Sync to NAS:**
```bash
rsync -av /mnt/ssd4tb/kafka/ /mnt/nas/kafka-mirror/
```

## Troubleshooting

### Common Issues

1. **Broker not available:**
```bash
# Check logs
docker logs jts-kafka1

# Restart broker
docker-compose -f docker-compose.kafka.yml restart kafka1
```

2. **Consumer lag:**
```bash
# Check consumer groups
docker exec jts-kafka1 kafka-consumer-groups --bootstrap-server kafka1:29092 --list

# Check lag for specific group
docker exec jts-kafka1 kafka-consumer-groups --bootstrap-server kafka1:29092 --describe --group <group-name>
```

3. **Disk space issues:**
```bash
# Check disk usage
df -h /mnt/ssd4tb

# Force log cleanup
docker exec jts-kafka1 kafka-configs --bootstrap-server kafka1:29092 \
  --alter --entity-type topics --entity-name <topic-name> \
  --add-config retention.ms=3600000
```

## Security Notes
- Currently using PLAINTEXT for development
- For production, implement SASL/SSL authentication
- Restrict network access using firewall rules
- Regular security updates for Docker images