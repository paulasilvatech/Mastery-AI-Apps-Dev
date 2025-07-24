---
sidebar_position: 3
title: "Exercise 2: Overview"
description: "## 🎯 Objective"
---

# Exercise 2: Encrypted AI Pipeline (⭐⭐ Medium - 45 minutes)

## 🎯 Objective

Build an end-to-end encrypted pipeline for AI model training and inference that protects sensitive data, model parameters, and predictions. Implement compliance logging for GDPR, HIPAA, and SOC2 requirements.

## 🔑 What You'll Learn

- Encrypt data at rest and in transit
- Secure AI model parameters
- Implement prompt injection protection
- Create compliance audit trails
- Handle sensitive data classification
- Monitor security events in real-time

## 📋 Requirements

- Azure OpenAI or GitHub Models access
- Azure Key Vault for encryption keys
- Azure Blob Storage for encrypted data
- Application Insights for monitoring
- Python with cryptography libraries

## 📝 Instructions

### Step 1: Set Up Encryption Infrastructure

Create the project structure:

```bash
mkdir encrypted-ai-pipeline
cd encrypted-ai-pipeline

# Install required packages
pip install azure-storage-blob==12.19.0
pip install azure-keyvault-keys==4.8.0
pip install cryptography==41.0.0
pip install openai==1.3.0
pip install pandas==2.1.0
pip install pydantic==2.4.0
```

### Step 2: Implement Data Encryption Service

**Copilot Prompt Suggestion:**
```
Create a Python encryption service that:
- Uses Azure Key Vault for key management
- Implements AES-256-GCM encryption for data
- Supports envelope encryption for large files
- Handles key rotation automatically
- Provides data classification (PII, PHI, PCI)
- Logs all encryption operations for compliance
Include async support and proper error handling.
```

**Expected Output:**
```python
import os
import base64
import json
from typing import Dict, Any, Optional, Tuple
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from azure.keyvault.keys import KeyClient
from azure.keyvault.keys.crypto import CryptographyClient, EncryptionAlgorithm
from azure.identity import DefaultAzureCredential
from enum import Enum
import asyncio
import logging
from datetime import datetime

logger = logging.getLogger(__name__)

class DataClassification(Enum):
    """Data sensitivity classifications."""
    PUBLIC = "public"
    INTERNAL = "internal"
    CONFIDENTIAL = "confidential"
    PII = "pii"  # Personally Identifiable Information
    PHI = "phi"  # Protected Health Information
    PCI = "pci"  # Payment Card Information

class EncryptionService:
    """Handles all encryption operations with compliance logging."""
    
    def __init__(self, key_vault_name: str):
        self.key_vault_url = f"https://{key_vault_name}.vault.azure.net/"
        self.credential = DefaultAzureCredential()
        self.key_client = KeyClient(
            vault_url=self.key_vault_url,
            credential=self.credential
        )
        self._key_cache = {}
        
    async def encrypt_data(
        self,
        data: bytes,
        classification: DataClassification,
        metadata: Optional[Dict[str, Any]] = None
    ) -&gt; Tuple[bytes, Dict[str, Any]]:
        """Encrypt data with envelope encryption."""
        try: