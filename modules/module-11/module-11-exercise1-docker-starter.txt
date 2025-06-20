# Exercise 1: Foundation - Service Decomposition
# Starter Docker Compose Configuration

version: '3.8'

services:
  # TODO: Define User Service
  user-service:
    build:
      context: ./user-service
      dockerfile: Dockerfile
    container_name: user-service
    ports:
      - "8001:8000"  # Map to different host port
    environment:
      - SERVICE_NAME=user-service
      # TODO: Add additional environment variables
    networks:
      - microservices-network
    # TODO: Add health check

  # TODO: Define Product Service
  product-service:
    build:
      context: ./product-service
      dockerfile: Dockerfile
    # TODO: Complete configuration
    # Remember to use port 8002:8000

  # TODO: Define Order Service
  order-service:
    # TODO: Complete configuration
    # Remember:
    # - Use port 8003:8000
    # - Add service URLs as environment variables
    # - Add depends_on for user and product services

networks:
  microservices-network:
    driver: bridge
    # TODO: Add network configuration if needed

# TODO: Add volumes if needed for persistence