#!/bin/bash

echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config
echo "ECS_ENABLE_CONTAINER_METADATA=true" >> /etc/ecs/ecs.config
echo "ECS_ENABLE_TASK_IAM_ROLE=true" >> /etc/ecs/ecs.config
echo "ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true" >> /etc/ecs/ecs.config
echo "ECS_ENABLE_TASK_ENI=true" >> /etc/ecs/ecs.config
echo "ECS_WARM_POOLS_CHECK=true" >> /etc/ecs/ecs.config
