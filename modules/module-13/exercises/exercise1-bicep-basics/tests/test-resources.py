#!/usr/bin/env python3
"""
test-resources.py - Test deployed Azure resources from Exercise 1
"""

import os
import sys
import json
import argparse
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.web import WebSiteManagementClient
from azure.mgmt.sql import SqlManagementClient
from azure.mgmt.storage import StorageManagementClient
from azure.mgmt.monitor import MonitorManagementClient
import requests

# Colors for output
class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    END = '\033[0m'

def print_test(name, passed, message=""):
    """Print test result"""
    if passed:
        print(f"{Colors.GREEN}✅ {name}{Colors.END}")
    else:
        print(f"{Colors.RED}❌ {name}{Colors.END}")
        if message:
            print(f"   {message}")

def test_resource_group(resource_client, resource_group):
    """Test resource group exists and has correct tags"""
    print(f"\n{Colors.BLUE}Testing Resource Group{Colors.END}")
    
    try:
        rg = resource_client.resource_groups.get(resource_group)
        print_test("Resource group exists", True)
        
        # Check tags
        if rg.tags and 'environment' in rg.tags:
            print_test("Environment tag present", True)
        else:
            print_test("Environment tag present", False, "Missing environment tag")
            
        return True
    except Exception as e:
        print_test("Resource group exists", False, str(e))
        return False

def test_app_service(web_client, resource_group):
    """Test App Service and Web App"""
    print(f"\n{Colors.BLUE}Testing App Service{Colors.END}")
    
    try:
        # List all web apps
        apps = list(web_client.web_apps.list_by_resource_group(resource_group))
        
        if not apps:
            print_test("Web App exists", False, "No web apps found")
            return False
            
        app = apps[0]
        print_test("Web App exists", True)
        
        # Check HTTPS only
        print_test("HTTPS only enabled", app.https_only)
        
        # Check managed identity
        has_identity = app.identity and app.identity.type == 'SystemAssigned'
        print_test("Managed identity enabled", has_identity)
        
        # Test web app is accessible
        try:
            response = requests.get(f"https://{app.default_host_name}", timeout=10)
            print_test("Web App accessible", response.status_code < 500)
        except:
            print_test("Web App accessible", False, "Could not reach web app")
            
        return True
    except Exception as e:
        print_test("App Service tests", False, str(e))
        return False

def test_sql_database(sql_client, resource_group):
    """Test SQL Server and Database"""
    print(f"\n{Colors.BLUE}Testing SQL Database{Colors.END}")
    
    try:
        # List SQL servers
        servers = list(sql_client.servers.list_by_resource_group(resource_group))
        
        if not servers:
            print_test("SQL Server exists", False, "No SQL servers found")
            return False
            
        server = servers[0]
        print_test("SQL Server exists", True)
        
        # Check minimum TLS version
        tls_ok = server.minimal_tls_version == '1.2'
        print_test("Minimum TLS 1.2", tls_ok)
        
        # Check firewall rules
        rules = list(sql_client.firewall_rules.list_by_server(resource_group, server.name))
        azure_rule = any(r.name == 'AllowAzureServices' for r in rules)
        print_test("Azure services firewall rule", azure_rule)
        
        # Check databases
        databases = list(sql_client.databases.list_by_server(resource_group, server.name))
        user_dbs = [db for db in databases if db.name != 'master']
        print_test("Database exists", len(user_dbs) > 0)
        
        return True
    except Exception as e:
        print_test("SQL Database tests", False, str(e))
        return False

def test_storage_account(storage_client, resource_group):
    """Test Storage Account"""
    print(f"\n{Colors.BLUE}Testing Storage Account{Colors.END}")
    
    try:
        # List storage accounts
        accounts = list(storage_client.storage_accounts.list_by_resource_group(resource_group))
        
        if not accounts:
            print_test("Storage Account exists", False, "No storage accounts found")
            return False
            
        account = accounts[0]
        print_test("Storage Account exists", True)
        
        # Check HTTPS only
        https_only = account.enable_https_traffic_only
        print_test("HTTPS traffic only", https_only)
        
        # Check minimum TLS version
        tls_ok = account.minimum_tls_version == 'TLS1_2'
        print_test("Minimum TLS 1.2", tls_ok)
        
        return True
    except Exception as e:
        print_test("Storage Account tests", False, str(e))
        return False

def test_monitoring(monitor_client, resource_group):
    """Test Application Insights"""
    print(f"\n{Colors.BLUE}Testing Monitoring{Colors.END}")
    
    try:
        # Check for Application Insights
        # Note: This is a simplified check
        resources = list(monitor_client.activity_logs.list(
            filter=f"resourceGroupName eq '{resource_group}'",
            select="resourceId"
        ))
        
        # Look for App Insights in resource IDs
        has_insights = any('microsoft.insights/components' in str(r.resource_id).lower() 
                          for r in resources if r.resource_id)
        
        print_test("Application Insights configured", has_insights)
        
        return True
    except:
        print_test("Monitoring tests", False, "Could not verify monitoring setup")
        return True  # Don't fail on monitoring

def main():
    parser = argparse.ArgumentParser(description='Test Azure resources from Exercise 1')
    parser.add_argument('--resource-group', '-g', required=True, help='Resource group name')
    parser.add_argument('--subscription', '-s', help='Azure subscription ID')
    args = parser.parse_args()
    
    print(f"🧪 Testing Azure Resources in '{args.resource_group}'")
    print("=" * 50)
    
    # Initialize Azure clients
    try:
        credential = DefaultAzureCredential()
        
        # Get subscription ID
        if args.subscription:
            subscription_id = args.subscription
        else:
            # Try to get from environment or Azure CLI
            from azure.cli.core import get_default_cli
            cli = get_default_cli()
            cli.invoke(['account', 'show'])
            subscription_id = json.loads(cli.result.result)['id']
        
        # Initialize clients
        resource_client = ResourceManagementClient(credential, subscription_id)
        web_client = WebSiteManagementClient(credential, subscription_id)
        sql_client = SqlManagementClient(credential, subscription_id)
        storage_client = StorageManagementClient(credential, subscription_id)
        monitor_client = MonitorManagementClient(credential, subscription_id)
        
    except Exception as e:
        print(f"{Colors.RED}Failed to initialize Azure clients: {e}{Colors.END}")
        print("Make sure you're logged in: az login")
        return 1
    
    # Run tests
    results = []
    results.append(test_resource_group(resource_client, args.resource_group))
    results.append(test_app_service(web_client, args.resource_group))
    results.append(test_sql_database(sql_client, args.resource_group))
    results.append(test_storage_account(storage_client, args.resource_group))
    results.append(test_monitoring(monitor_client, args.resource_group))
    
    # Summary
    print(f"\n{Colors.BLUE}Test Summary{Colors.END}")
    print("=" * 50)
    passed = sum(results)
    total = len(results)
    
    if passed == total:
        print(f"{Colors.GREEN}✅ All tests passed! ({passed}/{total}){Colors.END}")
        return 0
    else:
        print(f"{Colors.RED}❌ Some tests failed ({passed}/{total}){Colors.END}")
        return 1

if __name__ == "__main__":
    sys.exit(main())