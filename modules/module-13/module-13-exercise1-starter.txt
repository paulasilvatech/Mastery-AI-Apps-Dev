// main.bicep - Starter template for Exercise 1
// TODO: Complete this Bicep template to deploy:
// - App Service Plan (Linux, B1 tier for dev)
// - Web App running Python 3.11
// - Storage Account (Standard_LRS)
// - Application Insights

@description('The environment name (dev, staging, prod)')
param environment string = 'dev'

@description('The Azure region for resources')
param location string = resourceGroup().location

@description('Base name for resources')
param appName string

// TODO: Add variables for resource names
// Use naming convention: resourceType-appName-environment
// Example: asp-myapp-dev

// TODO: Add tags variable for resource management

// TODO: Create App Service Plan resource
// Name: Use the appServicePlanName variable
// SKU: B1 for dev/staging, P1v3 for prod
// Kind: linux

// TODO: Create Web App resource
// Reference the App Service Plan
// Configure for Python 3.11
// Add Application Insights connection

// TODO: Create Storage Account
// Standard_LRS tier
// Enable HTTPS only
// Minimum TLS 1.2

// TODO: Create Application Insights
// Type: web
// Link to the web app

// TODO: Add outputs
// - Web App URL
// - Web App Name
// - Storage Account Name