---
sidebar_position: 3
title: "Exercise 3: Overview"
description: "## 🎯 Objective"
---

# Exercício 3: Compliance-Ready Platform (⭐⭐⭐ Difícil - 90 minutos)

## 🎯 Objective
Build a comprehensive compliance-ready AI agent platform that meets GDPR, HIPAA, SOC 2, and other enterprise regulatory requirements, including audit trails, data privacy, encryption, and consent management.

## 🧠 O Que Você Aprenderá
- GDPR compliance implementation
- HIPAA security requirements
- Audit trail and logging systems
- Data encryption at rest and in transit
- Consent management
- Data retention and deletion policies
- Privacy by design principles
- Compliance reporting

## 📋 Pré-requisitos
- Completard Exercícios 1 and 2
- Understanding of data privacy regulations
- Knowledge of encryption concepts
- Familiarity with audit requirements

## 📚 Voltarground

Empresarial AI systems must comply with various regulations:

- **GDPR**: EU data protection regulation
- **HIPAA**: US healthcare information privacy
- **SOC 2**: Security, availability, and confidentiality
- **CCPA**: California consumer privacy act
- **ISO 27001**: Information security management

Key compliance requirements include:
- Data subject rights (access, deletion, portability)
- Consent management
- Data minimization
- Privacy by design
- Security controls
- Audit trails

## 🏗️ Compliance Architecture

```mermaid
graph TB
    subgraph "User Layer"
        U[User]
        C[Consent UI]
        P[Privacy Portal]
    end
    
    subgraph "API Gateway"
        GW[Gateway]
        AUTH[Authentication]
        AUTHZ[Authorization]
        ENC[Encryption]
    end
    
    subgraph "Compliance Layer"
        CM[Consent Manager]
        PM[Privacy Manager]
        AM[Audit Manager]
        DG[Data Governor]
    end
    
    subgraph "Application Layer"
        AGT[Agent Service]
        PROC[Data Processor]
        ANON[Anonymizer]
    end
    
    subgraph "Data Layer"
        DB[(Encrypted DB)]
        AUDIT[(Audit Log)]
        VAULT[(Key Vault)]
        ARCH[(Archive)]
    end
    
    subgraph "Monitoring"
        SIEM[SIEM]
        COMP[Compliance Dashboard]
        ALERT[Alert System]
    end
    
    U --&gt; C
    U --&gt; P
    C --&gt; GW
    P --&gt; GW
    
    GW --&gt; AUTH
    AUTH --&gt; AUTHZ
    AUTHZ --&gt; ENC
    
    ENC --&gt; CM
    ENC --&gt; PM
    ENC --&gt; AM
    
    CM --&gt; AGT
    PM --&gt; PROC
    AM --&gt; AUDIT
    
    PROC --&gt; ANON
    AGT --&gt; DB
    
    DG --&gt; DB
    DG --&gt; ARCH
    
    AM --&gt; SIEM
    SIEM --&gt; COMP
    SIEM --&gt; ALERT
    
    VAULT --&gt; ENC
    VAULT --&gt; DB
    
    style CM fill:#4CAF50
    style PM fill:#2196F3
    style AM fill:#FF9800
    style VAULT fill:#F44336
```

## 🛠️ Step-by-Step Instructions

### Step 1: Implement Data Privacy Domain Models

**Copilot Prompt Suggestion:**
```csharp
// Create domain models for compliance that include:
// - DataSubject entity with rights management
// - Consent aggregate with version tracking
// - PersonalData value object with classification
// - AuditEntry entity with immutability
// - DataRetention policies
// Follow GDPR Article 4 definitions
```

Create `Domain/Compliance/DataSubject.cs`:
```csharp
using EnterpriseAgent.Domain.Common;
using EnterpriseAgent.Domain.Compliance.Events;

namespace EnterpriseAgent.Domain.Compliance;

public class DataSubject : AggregateRoot
{
    private readonly List<Consent> _consents = new();
    private readonly List<DataRequest> _dataRequests = new();
    private readonly List<PersonalDataRecord> _personalData = new();

    public string SubjectId { get; private set; } // External ID (user ID, email, etc.)
    public SubjectType Type { get; private set; }
    public string Jurisdiction { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime? DeletedAt { get; private set; }
    public bool IsDeleted =&gt; DeletedAt.HasValue;
    public PrivacyPreferences Preferences { get; private set; }

    public IReadOnlyCollection<Consent> Consents =&gt; _consents.AsReadOnly();
    public IReadOnlyCollection<DataRequest> DataRequests =&gt; _dataRequests.AsReadOnly();
    public IReadOnlyCollection<PersonalDataRecord> PersonalData =&gt; _personalData.AsReadOnly();

    private DataSubject() { }

    public static DataSubject Create(
        string subjectId,
        SubjectType type,
        string jurisdiction)
    {
        if (string.IsNullOrWhiteSpace(subjectId))
            throw new ArgumentException("Subject ID is required", nameof(subjectId));

        var dataSubject = new DataSubject
        {
            Id = Guid.NewGuid(),
            SubjectId = subjectId,
            Type = type,
            Jurisdiction = jurisdiction,
            CreatedAt = DateTime.UtcNow,
            Preferences = PrivacyPreferences.Default()
        };

        dataSubject.AddDomainEvent(new DataSubjectCreatedEvent(
            dataSubject.Id,
            subjectId,
            type,
            jurisdiction
        ));

        return dataSubject;
    }

    public Consent GrantConsent(
        string purpose,
        string scope,
        DateTime? expiresAt = null,
        Dictionary<string, object>? metadata = null)
    {
        if (_consents.Any(c =&gt; c.Purpose == purpose && c.IsActive))
        {
            throw new InvalidOperationException($"Active consent already exists for purpose: {purpose}");
        }

        var consent = Consent.Create(
            Id,
            purpose,
            scope,
            ConsentSource.Explicit,
            expiresAt,
            metadata
        );

        _consents.Add(consent);

        AddDomainEvent(new ConsentGrantedEvent(
            Id,
            consent.Id,
            purpose,
            scope
        ));

        return consent;
    }

    public void RevokeConsent(Guid consentId, string reason)
    {
        var consent = _consents.FirstOrDefault(c =&gt; c.Id == consentId);
        if (consent == null)
            throw new InvalidOperationException($"Consent {consentId} not found");

        consent.Revoke(reason);

        AddDomainEvent(new ConsentRevokedEvent(
            Id,
            consentId,
            consent.Purpose,
            reason
        ));
    }

    public bool HasActiveConsent(string purpose)
    {
        return _consents.Any(c =&gt; c.Purpose == purpose && c.IsActive);
    }

    public DataRequest CreateDataRequest(DataRequestType type, string requestedBy)
    {
        var request = DataRequest.Create(Id, type, requestedBy);
        _dataRequests.Add(request);

        AddDomainEvent(new DataRequestCreatedEvent(
            Id,
            request.Id,
            type,
            requestedBy
        ));

        return request;
    }

    public void RecordPersonalData(
        string category,
        string dataType,
        DataSensitivity sensitivity,
        string source,
        DateTime? retentionUntil = null)
    {
        var record = PersonalDataRecord.Create(
            category,
            dataType,
            sensitivity,
            source,
            retentionUntil
        );

        _personalData.Add(record);

        AddDomainEvent(new PersonalDataRecordedEvent(
            Id,
            category,
            dataType,
            sensitivity
        ));
    }

    public void MarkForDeletion(string reason)
    {
        if (IsDeleted)
            throw new InvalidOperationException("Data subject already marked for deletion");

        DeletedAt = DateTime.UtcNow;

        AddDomainEvent(new DataSubjectDeletionRequestedEvent(
            Id,
            SubjectId,
            reason
        ));
    }

    public void UpdatePrivacyPreferences(PrivacyPreferences preferences)
    {
        Preferences = preferences ?? throw new ArgumentNullException(nameof(preferences));

        AddDomainEvent(new PrivacyPreferencesUpdatedEvent(
            Id,
            preferences
        ));
    }
}

public enum SubjectType
{
    Individual,
    Employee,
    Customer,
    Prospect,
    Partner
}

public enum DataRequestType
{
    Access,         // GDPR Article 15
    Rectification,  // GDPR Article 16
    Erasure,        // GDPR Article 17 (Right to be forgotten)
    Portability,    // GDPR Article 20
    Restriction,    // GDPR Article 18
    Objection      // GDPR Article 21
}
```

Create `Domain/Compliance/Consent.cs`:
```csharp
using EnterpriseAgent.Domain.Common;

namespace EnterpriseAgent.Domain.Compliance;

public class Consent : Entity
{
    public Guid DataSubjectId { get; private set; }
    public string Purpose { get; private set; }
    public string Scope { get; private set; }
    public ConsentSource Source { get; private set; }
    public DateTime GrantedAt { get; private set; }
    public DateTime? RevokedAt { get; private set; }
    public DateTime? ExpiresAt { get; private set; }
    public string? RevokeReason { get; private set; }
    public int Version { get; private set; }
    public Dictionary<string, object> Metadata { get; private set; }

    public bool IsActive =&gt; !RevokedAt.HasValue && 
                           (!ExpiresAt.HasValue || ExpiresAt.Value &gt; DateTime.UtcNow);

    private Consent() 
    {
        Metadata = new Dictionary<string, object>();
    }

    public static Consent Create(
        Guid dataSubjectId,
        string purpose,
        string scope,
        ConsentSource source,
        DateTime? expiresAt = null,
        Dictionary<string, object>? metadata = null)
    {
        return new Consent
        {
            Id = Guid.NewGuid(),
            DataSubjectId = dataSubjectId,
            Purpose = purpose,
            Scope = scope,
            Source = source,
            GrantedAt = DateTime.UtcNow,
            ExpiresAt = expiresAt,
            Version = 1,
            Metadata = metadata ?? new Dictionary<string, object>()
        };
    }

    public void Revoke(string reason)
    {
        if (!IsActive)
            throw new InvalidOperationException("Consent is not active");

        RevokedAt = DateTime.UtcNow;
        RevokeReason = reason;
    }

    public Consent CreateNewVersion(string updatedScope, DateTime? newExpiresAt = null)
    {
        return new Consent
        {
            Id = Guid.NewGuid(),
            DataSubjectId = DataSubjectId,
            Purpose = Purpose,
            Scope = updatedScope,
            Source = Source,
            GrantedAt = DateTime.UtcNow,
            ExpiresAt = newExpiresAt,
            Version = Version + 1,
            Metadata = new Dictionary<string, object>(Metadata)
        };
    }
}

public enum ConsentSource
{
    Explicit,    // Direct consent from user
    Implicit,    // Legitimate interest
    Contract,    // Necessary for contract
    Legal,       // Legal obligation
    Vital        // Vital interests
}
```

Create `Domain/Compliance/AuditEntry.cs`:
```csharp
using EnterpriseAgent.Domain.Common;

namespace EnterpriseAgent.Domain.Compliance;

public class AuditEntry : Entity
{
    public DateTime Timestamp { get; private set; }
    public string UserId { get; private set; }
    public string Action { get; private set; }
    public string ResourceType { get; private set; }
    public string ResourceId { get; private set; }
    public AuditResult Result { get; private set; }
    public string? FailureReason { get; private set; }
    public Dictionary<string, object> Context { get; private set; }
    public string IpAddress { get; private set; }
    public string UserAgent { get; private set; }
    public string? CorrelationId { get; private set; }
    public TimeSpan Duration { get; private set; }

    // Immutable - no setters exposed
    private AuditEntry() 
    {
        Context = new Dictionary<string, object>();
    }

    public static AuditEntry Create(
        string userId,
        string action,
        string resourceType,
        string resourceId,
        AuditResult result,
        string ipAddress,
        string userAgent,
        TimeSpan duration,
        string? correlationId = null,
        string? failureReason = null,
        Dictionary<string, object>? context = null)
    {
        return new AuditEntry
        {
            Id = Guid.NewGuid(),
            Timestamp = DateTime.UtcNow,
            UserId = userId ?? "system",
            Action = action ?? throw new ArgumentNullException(nameof(action)),
            ResourceType = resourceType ?? throw new ArgumentNullException(nameof(resourceType)),
            ResourceId = resourceId ?? throw new ArgumentNullException(nameof(resourceId)),
            Result = result,
            FailureReason = failureReason,
            IpAddress = ipAddress ?? "unknown",
            UserAgent = userAgent ?? "unknown",
            Duration = duration,
            CorrelationId = correlationId,
            Context = context ?? new Dictionary<string, object>()
        };
    }

    public string ToLogString()
    {
        return $"[{Timestamp:yyyy-MM-dd HH:mm:ss.fff}] {UserId} {Action} {ResourceType}/{ResourceId} " +
               $"Result={Result} Duration={Duration.TotalMilliseconds}ms IP={IpAddress}";
    }
}

public enum AuditResult
{
    Success,
    Failure,
    PartialSuccess,
    Unauthorized,
    NotFound
}
```

Create `Domain/ValueObjects/PersonalData.cs`:
```csharp
using EnterpriseAgent.Domain.Common;

namespace EnterpriseAgent.Domain.ValueObjects;

public class PersonalData : ValueObject
{
    public string Category { get; private set; }
    public string DataType { get; private set; }
    public DataSensitivity Sensitivity { get; private set; }
    public bool IsSpecialCategory { get; private set; } // GDPR Article 9
    public EncryptionInfo Encryption { get; private set; }
    public RetentionPolicy Retention { get; private set; }

    private PersonalData() { }

    public static PersonalData Create(
        string category,
        string dataType,
        DataSensitivity sensitivity,
        bool isSpecialCategory = false)
    {
        return new PersonalData
        {
            Category = category ?? throw new ArgumentNullException(nameof(category)),
            DataType = dataType ?? throw new ArgumentNullException(nameof(dataType)),
            Sensitivity = sensitivity,
            IsSpecialCategory = isSpecialCategory,
            Encryption = EncryptionInfo.Default(),
            Retention = RetentionPolicy.Default()
        };
    }

    protected override IEnumerable<object> GetEqualityComponents()
    {
        yield return Category;
        yield return DataType;
        yield return Sensitivity;
    }
}

public enum DataSensitivity
{
    Public,
    Internal,
    Confidential,
    Restricted,
    TopSecret
}

public class EncryptionInfo : ValueObject
{
    public bool IsEncrypted { get; private set; }
    public string Algorithm { get; private set; }
    public int KeySize { get; private set; }
    public string KeyId { get; private set; }

    public static EncryptionInfo Default()
    {
        return new EncryptionInfo
        {
            IsEncrypted = true,
            Algorithm = "AES-256-GCM",
            KeySize = 256,
            KeyId = "default"
        };
    }

    protected override IEnumerable<object> GetEqualityComponents()
    {
        yield return IsEncrypted;
        yield return Algorithm;
        yield return KeyId;
    }
}

public class RetentionPolicy : ValueObject
{
    public TimeSpan RetentionPeriod { get; private set; }
    public string LegalBasis { get; private set; }
    public bool AutoDelete { get; private set; }

    public static RetentionPolicy Default()
    {
        return new RetentionPolicy
        {
            RetentionPeriod = TimeSpan.FromDays(365 * 2), // 2 years default
            LegalBasis = "Legitimate interest",
            AutoDelete = true
        };
    }

    public static RetentionPolicy ForHealthData()
    {
        return new RetentionPolicy
        {
            RetentionPeriod = TimeSpan.FromDays(365 * 7), // 7 years for health data
            LegalBasis = "Legal requirement (HIPAA)",
            AutoDelete = false // Manual review required
        };
    }

    protected override IEnumerable<object> GetEqualityComponents()
    {
        yield return RetentionPeriod;
        yield return LegalBasis;
        yield return AutoDelete;
    }
}
```

### Step 2: Implement Compliance Services

Create `Application/Compliance/Services/ConsentService.cs`:
```csharp
using EnterpriseAgent.Domain.Compliance;
using EnterpriseAgent.Application.Common.Interfaces;

namespace EnterpriseAgent.Application.Compliance.Services;

public class ConsentService : IConsentService
{
    private readonly IDataSubjectRepository _dataSubjectRepository;
    private readonly IAuditService _auditService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<ConsentService> _logger;

    public ConsentService(
        IDataSubjectRepository dataSubjectRepository,
        IAuditService auditService,
        IUnitOfWork unitOfWork,
        ILogger<ConsentService> logger)
    {
        _dataSubjectRepository = dataSubjectRepository;
        _auditService = auditService;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<ConsentResult> RequestConsentAsync(
        string subjectId,
        string purpose,
        string scope,
        ConsentContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            // Get or create data subject
            var dataSubject = await _dataSubjectRepository.GetBySubjectIdAsync(subjectId, cancellationToken)
                ?? DataSubject.Create(
                    subjectId,
                    DetermineSubjectType(context),
                    context.Jurisdiction
                );

            // Check if consent already exists
            if (dataSubject.HasActiveConsent(purpose))
            {
                return new ConsentResult
                {
                    Success = true,
                    ConsentId = dataSubject.Consents
                        .First(c =&gt; c.Purpose == purpose && c.IsActive).Id,
                    AlreadyGranted = true
                };
            }

            // Grant consent
            var consent = dataSubject.GrantConsent(
                purpose,
                scope,
                context.ExpiresAt,
                context.Metadata
            );

            // Save changes
            if (!await _dataSubjectRepository.ExistsAsync(dataSubject.Id, cancellationToken))
            {
                await _dataSubjectRepository.AddAsync(dataSubject, cancellationToken);
            }
            else
            {
                _dataSubjectRepository.Update(dataSubject);
            }

            await _unitOfWork.SaveChangesAsync(cancellationToken);

            // Audit the consent
            await _auditService.LogAsync(
                context.UserId,
                "GrantConsent",
                "DataSubject",
                dataSubject.Id.ToString(),
                AuditResult.Success,
                context,
                cancellationToken
            );

            _logger.LogInformation(
                "Consent granted for subject {SubjectId}, purpose: {Purpose}",
                subjectId,
                purpose
            );

            return new ConsentResult
            {
                Success = true,
                ConsentId = consent.Id,
                ExpiresAt = consent.ExpiresAt
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error granting consent for subject {SubjectId}", subjectId);

            await _auditService.LogAsync(
                context.UserId,
                "GrantConsent",
                "DataSubject",
                subjectId,
                AuditResult.Failure,
                context,
                cancellationToken,
                ex.Message
            );

            throw;
        }
    }

    public async Task<bool> VerifyConsentAsync(
        string subjectId,
        string purpose,
        CancellationToken cancellationToken = default)
    {
        var dataSubject = await _dataSubjectRepository.GetBySubjectIdAsync(subjectId, cancellationToken);
        return dataSubject?.HasActiveConsent(purpose) ?? false;
    }

    public async Task RevokeConsentAsync(
        string subjectId,
        Guid consentId,
        string reason,
        ConsentContext context,
        CancellationToken cancellationToken = default)
    {
        var dataSubject = await _dataSubjectRepository.GetBySubjectIdAsync(subjectId, cancellationToken);
        if (dataSubject == null)
        {
            throw new InvalidOperationException($"Data subject {subjectId} not found");
        }

        dataSubject.RevokeConsent(consentId, reason);
        
        _dataSubjectRepository.Update(dataSubject);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        await _auditService.LogAsync(
            context.UserId,
            "RevokeConsent",
            "Consent",
            consentId.ToString(),
            AuditResult.Success,
            context,
            cancellationToken
        );

        _logger.LogInformation(
            "Consent {ConsentId} revoked for subject {SubjectId}",
            consentId,
            subjectId
        );
    }

    public async Task<IEnumerable<ConsentDto>&gt; GetConsentsAsync(
        string subjectId,
        bool includeRevoked = false,
        CancellationToken cancellationToken = default)
    {
        var dataSubject = await _dataSubjectRepository.GetBySubjectIdAsync(subjectId, cancellationToken);
        if (dataSubject == null)
        {
            return Enumerable.Empty<ConsentDto>();
        }

        var consents = includeRevoked
            ? dataSubject.Consents
            : dataSubject.Consents.Where(c =&gt; c.IsActive);

        return consents.Select(c =&gt; new ConsentDto
        {
            Id = c.Id,
            Purpose = c.Purpose,
            Scope = c.Scope,
            GrantedAt = c.GrantedAt,
            ExpiresAt = c.ExpiresAt,
            IsActive = c.IsActive,
            Source = c.Source.ToString()
        });
    }

    private SubjectType DetermineSubjectType(ConsentContext context)
    {
        // Logic to determine subject type based on context
        return context.Metadata.ContainsKey("employeeId") 
            ? SubjectType.Employee 
            : SubjectType.Customer;
    }
}
```

Create `Infrastructure/Compliance/EncryptionService.cs`:
```csharp
using System.Security.Cryptography;
using Microsoft.AspNetCore.DataProtection;
using EnterpriseAgent.Application.Common.Interfaces;

namespace EnterpriseAgent.Infrastructure.Compliance;

public class EncryptionService : IEncryptionService
{
    private readonly IDataProtector _protector;
    private readonly IKeyVaultService _keyVault;
    private readonly ILogger<EncryptionService> _logger;
    private readonly Dictionary<string, byte[]> _keyCache = new();
    private readonly SemaphoreSlim _cacheLock = new(1, 1);

    public EncryptionService(
        IDataProtectionProvider dataProtectionProvider,
        IKeyVaultService keyVault,
        ILogger<EncryptionService> logger)
    {
        _protector = dataProtectionProvider.CreateProtector("EnterpriseAgent.PersonalData");
        _keyVault = keyVault;
        _logger = logger;
    }

    public async Task<EncryptedData> EncryptAsync(
        string plainText,
        string keyId = "default",
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrEmpty(plainText))
            return new EncryptedData { Data = plainText, IsEncrypted = false };

        try
        {
            var key = await GetEncryptionKeyAsync(keyId, cancellationToken);
            
            using var aes = Aes.Create();
            aes.Key = key;
            aes.GenerateIV();

            using var encryptor = aes.CreateEncryptor();
            using var msEncrypt = new MemoryStream();
            using (var csEncrypt = new CryptoStream(msEncrypt, encryptor, CryptoStreamMode.Write))
            using (var swEncrypt = new StreamWriter(csEncrypt))
            {
                await swEncrypt.WriteAsync(plainText);
            }

            var encrypted = msEncrypt.ToArray();
            var result = new byte[aes.IV.Length + encrypted.Length];
            
            // Prepend IV to encrypted data
            Buffer.BlockCopy(aes.IV, 0, result, 0, aes.IV.Length);
            Buffer.BlockCopy(encrypted, 0, result, aes.IV.Length, encrypted.Length);

            return new EncryptedData
            {
                Data = Convert.ToBase64String(result),
                IsEncrypted = true,
                Algorithm = "AES-256-GCM",
                KeyId = keyId,
                EncryptedAt = DateTime.UtcNow
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Encryption failed for key {KeyId}", keyId);
            throw new InvalidOperationException("Encryption failed", ex);
        }
    }

    public async Task<string> DecryptAsync(
        EncryptedData encryptedData,
        CancellationToken cancellationToken = default)
    {
        if (!encryptedData.IsEncrypted || string.IsNullOrEmpty(encryptedData.Data))
            return encryptedData.Data ?? string.Empty;

        try
        {
            var key = await GetEncryptionKeyAsync(encryptedData.KeyId, cancellationToken);
            var fullCipher = Convert.FromBase64String(encryptedData.Data);

            using var aes = Aes.Create();
            aes.Key = key;

            // Extract IV from beginning of data
            var iv = new byte[aes.BlockSize / 8];
            var cipher = new byte[fullCipher.Length - iv.Length];
            
            Buffer.BlockCopy(fullCipher, 0, iv, 0, iv.Length);
            Buffer.BlockCopy(fullCipher, iv.Length, cipher, 0, cipher.Length);
            
            aes.IV = iv;

            using var decryptor = aes.CreateDecryptor();
            using var msDecrypt = new MemoryStream(cipher);
            using var csDecrypt = new CryptoStream(msDecrypt, decryptor, CryptoStreamMode.Read);
            using var srDecrypt = new StreamReader(csDecrypt);
            
            return await srDecrypt.ReadToEndAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Decryption failed for key {KeyId}", encryptedData.KeyId);
            throw new InvalidOperationException("Decryption failed", ex);
        }
    }

    public async Task<byte[]> EncryptBinaryAsync(
        byte[] data,
        string keyId = "default",
        CancellationToken cancellationToken = default)
    {
        if (data == null || data.Length == 0)
            return data;

        var base64 = Convert.ToBase64String(data);
        var encrypted = await EncryptAsync(base64, keyId, cancellationToken);
        return Convert.FromBase64String(encrypted.Data);
    }

    public async Task<byte[]> DecryptBinaryAsync(
        byte[] encryptedData,
        string keyId = "default",
        CancellationToken cancellationToken = default)
    {
        if (encryptedData == null || encryptedData.Length == 0)
            return encryptedData;

        var encrypted = new EncryptedData
        {
            Data = Convert.ToBase64String(encryptedData),
            IsEncrypted = true,
            KeyId = keyId
        };

        var decrypted = await DecryptAsync(encrypted, cancellationToken);
        return Convert.FromBase64String(decrypted);
    }

    public string HashData(string data, string salt = "")
    {
        using var sha256 = SHA256.Create();
        var bytes = Encoding.UTF8.GetBytes(data + salt);
        var hash = sha256.ComputeHash(bytes);
        return Convert.ToBase64String(hash);
    }

    public bool VerifyHash(string data, string hash, string salt = "")
    {
        var computedHash = HashData(data, salt);
        return computedHash == hash;
    }

    private async Task<byte[]> GetEncryptionKeyAsync(string keyId, CancellationToken cancellationToken)
    {
        await _cacheLock.WaitAsync(cancellationToken);
        try
        {
            if (_keyCache.TryGetValue(keyId, out var cachedKey))
                return cachedKey;

            var keySecret = await _keyVault.GetSecretAsync($"encryption-key-{keyId}", cancellationToken);
            var key = Convert.FromBase64String(keySecret);
            
            _keyCache[keyId] = key;
            return key;
        }
        finally
        {
            _cacheLock.Release();
        }
    }
}

public class EncryptedData
{
    public string Data { get; set; } = string.Empty;
    public bool IsEncrypted { get; set; }
    public string Algorithm { get; set; } = string.Empty;
    public string KeyId { get; set; } = string.Empty;
    public DateTime? EncryptedAt { get; set; }
}
```

Create `Infrastructure/Compliance/AuditService.cs`:
```csharp
using EnterpriseAgent.Domain.Compliance;
using EnterpriseAgent.Application.Common.Interfaces;
using System.Diagnostics;

namespace EnterpriseAgent.Infrastructure.Compliance;

public class AuditService : IAuditService
{
    private readonly IAuditRepository _auditRepository;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly ILogger<AuditService> _logger;
    private readonly IEventPublisher _eventPublisher;

    public AuditService(
        IAuditRepository auditRepository,
        IHttpContextAccessor httpContextAccessor,
        ILogger<AuditService> logger,
        IEventPublisher eventPublisher)
    {
        _auditRepository = auditRepository;
        _httpContextAccessor = httpContextAccessor;
        _logger = logger;
        _eventPublisher = eventPublisher;
    }

    public async Task LogAsync(
        string userId,
        string action,
        string resourceType,
        string resourceId,
        AuditResult result,
        object? context = null,
        CancellationToken cancellationToken = default,
        string? failureReason = null)
    {
        var stopwatch = Stopwatch.StartNew();
        
        try
        {
            var httpContext = _httpContextAccessor.HttpContext;
            var ipAddress = GetClientIpAddress(httpContext);
            var userAgent = httpContext?.Request.Headers["User-Agent"].ToString() ?? "Unknown";
            var correlationId = httpContext?.TraceIdentifier;

            var contextDict = new Dictionary<string, object>();
            if (context != null)
            {
                // Serialize context object to dictionary
                foreach (var prop in context.GetType().GetProperties())
                {
                    var value = prop.GetValue(context);
                    if (value != null)
                    {
                        contextDict[prop.Name] = value;
                    }
                }
            }

            // Add additional context
            contextDict["Environment"] = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production";
            contextDict["MachineName"] = Environment.MachineName;
            contextDict["ProcessId"] = Environment.ProcessId;

            var auditEntry = AuditEntry.Create(
                userId,
                action,
                resourceType,
                resourceId,
                result,
                ipAddress,
                userAgent,
                stopwatch.Elapsed,
                correlationId,
                failureReason,
                contextDict
            );

            await _auditRepository.AddAsync(auditEntry, cancellationToken);

            // Log to structured logging
            _logger.LogInformation(
                "Audit: {Action} on {ResourceType}/{ResourceId} by {UserId} - Result: {Result}",
                action,
                resourceType,
                resourceId,
                userId,
                result
            );

            // Publish audit event for real-time monitoring
            await _eventPublisher.PublishAsync(new AuditLogCreatedEvent
            {
                AuditId = auditEntry.Id,
                Action = action,
                ResourceType = resourceType,
                ResourceId = resourceId,
                UserId = userId,
                Result = result,
                Timestamp = auditEntry.Timestamp
            }, cancellationToken);

            // Alert on suspicious activities
            if (await IsSuspiciousActivityAsync(userId, action, result, cancellationToken))
            {
                await _eventPublisher.PublishAsync(new SuspiciousActivityDetectedEvent
                {
                    UserId = userId,
                    Action = action,
                    Reason = "Multiple failed attempts or unusual pattern detected"
                }, cancellationToken);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create audit log for action {Action}", action);
            // Don't throw - auditing should not break the main flow
        }
    }

    public async Task<IEnumerable<AuditEntry>&gt; GetAuditLogsAsync(
        AuditQuery query,
        CancellationToken cancellationToken = default)
    {
        return await _auditRepository.QueryAsync(query, cancellationToken);
    }

    public async Task<AuditReport> GenerateComplianceReportAsync(
        DateTime startDate,
        DateTime endDate,
        string? resourceType = null,
        CancellationToken cancellationToken = default)
    {
        var query = new AuditQuery
        {
            StartDate = startDate,
            EndDate = endDate,
            ResourceType = resourceType
        };

        var entries = await _auditRepository.QueryAsync(query, cancellationToken);

        var report = new AuditReport
        {
            StartDate = startDate,
            EndDate = endDate,
            TotalEntries = entries.Count(),
            EntriesByAction = entries.GroupBy(e =&gt; e.Action)
                .ToDictionary(g =&gt; g.Key, g =&gt; g.Count()),
            EntriesByResult = entries.GroupBy(e =&gt; e.Result)
                .ToDictionary(g =&gt; g.Key, g =&gt; g.Count()),
            EntriesByUser = entries.GroupBy(e =&gt; e.UserId)
                .Take(10)
                .ToDictionary(g =&gt; g.Key, g =&gt; g.Count()),
            FailureReasons = entries
                .Where(e =&gt; e.Result == AuditResult.Failure && !string.IsNullOrEmpty(e.FailureReason))
                .GroupBy(e =&gt; e.FailureReason!)
                .ToDictionary(g =&gt; g.Key, g =&gt; g.Count()),
            AverageResponseTime = entries.Any() 
                ? TimeSpan.FromMilliseconds(entries.Average(e =&gt; e.Duration.TotalMilliseconds))
                : TimeSpan.Zero
        };

        return report;
    }

    private string GetClientIpAddress(HttpContext? context)
    {
        if (context == null)
            return "Unknown";

        // Check for forwarded headers (behind proxy/load balancer)
        var forwarded = context.Request.Headers["X-Forwarded-For"].FirstOrDefault();
        if (!string.IsNullOrEmpty(forwarded))
        {
            return forwarded.Split(',')[0].Trim();
        }

        // Check X-Real-IP header
        var realIp = context.Request.Headers["X-Real-IP"].FirstOrDefault();
        if (!string.IsNullOrEmpty(realIp))
        {
            return realIp;
        }

        // Fall back to remote IP
        return context.Connection.RemoteIpAddress?.ToString() ?? "Unknown";
    }

    private async Task<bool> IsSuspiciousActivityAsync(
        string userId,
        string action,
        AuditResult result,
        CancellationToken cancellationToken)
    {
        // Check for multiple failed attempts
        if (result == AuditResult.Failure)
        {
            var recentFailures = await _auditRepository.CountRecentFailuresAsync(
                userId,
                TimeSpan.FromMinutes(5),
                cancellationToken
            );

            return recentFailures &gt; 5;
        }

        // Check for unusual activity patterns
        var recentActions = await _auditRepository.GetRecentActionsAsync(
            userId,
            TimeSpan.FromMinutes(1),
            cancellationToken
        );

        return recentActions.Count() &gt; 100; // More than 100 actions per minute
    }
}
```

### Step 3: Implement Data Privacy Manager

Create `Application/Compliance/Services/PrivacyManager.cs`:
```csharp
using EnterpriseAgent.Domain.Compliance;
using EnterpriseAgent.Application.Common.Interfaces;

namespace EnterpriseAgent.Application.Compliance.Services;

public class PrivacyManager : IPrivacyManager
{
    private readonly IDataSubjectRepository _dataSubjectRepository;
    private readonly IPersonalDataRepository _personalDataRepository;
    private readonly IEncryptionService _encryptionService;
    private readonly IAuditService _auditService;
    private readonly IAnonymizationService _anonymizationService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<PrivacyManager> _logger;

    public PrivacyManager(
        IDataSubjectRepository dataSubjectRepository,
        IPersonalDataRepository personalDataRepository,
        IEncryptionService encryptionService,
        IAuditService auditService,
        IAnonymizationService anonymizationService,
        IUnitOfWork unitOfWork,
        ILogger<PrivacyManager> logger)
    {
        _dataSubjectRepository = dataSubjectRepository;
        _personalDataRepository = personalDataRepository;
        _encryptionService = encryptionService;
        _auditService = auditService;
        _anonymizationService = anonymizationService;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<DataAccessResponse> HandleDataAccessRequestAsync(
        string subjectId,
        DataAccessRequest request,
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation(
            "Processing data access request for subject {SubjectId}",
            subjectId
        );

        var dataSubject = await _dataSubjectRepository.GetBySubjectIdAsync(subjectId, cancellationToken);
        if (dataSubject == null)
        {
            return new DataAccessResponse
            {
                Success = false,
                Message = "No data found for the specified subject"
            };
        }

        // Create data request record
        var dataRequest = dataSubject.CreateDataRequest(
            DataRequestType.Access,
            request.RequestedBy
        );

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        // Collect all personal data
        var personalData = await CollectPersonalDataAsync(subjectId, cancellationToken);

        // Audit the access
        await _auditService.LogAsync(
            request.RequestedBy,
            "DataAccess",
            "DataSubject",
            subjectId,
            AuditResult.Success,
            new { RequestId = dataRequest.Id },
            cancellationToken
        );

        return new DataAccessResponse
        {
            Success = true,
            RequestId = dataRequest.Id,
            Data = personalData,
            GeneratedAt = DateTime.UtcNow,
            ExpiresAt = DateTime.UtcNow.AddDays(30)
        };
    }

    public async Task<DataDeletionResponse> HandleDataDeletionRequestAsync(
        string subjectId,
        DataDeletionRequest request,
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation(
            "Processing data deletion request for subject {SubjectId}",
            subjectId
        );

        var dataSubject = await _dataSubjectRepository.GetBySubjectIdAsync(subjectId, cancellationToken);
        if (dataSubject == null)
        {
            return new DataDeletionResponse
            {
                Success = false,
                Message = "No data found for the specified subject"
            };
        }

        // Check for legal holds or retention requirements
        var retentionCheck = await CheckRetentionRequirementsAsync(subjectId, cancellationToken);
        if (!retentionCheck.CanDelete)
        {
            return new DataDeletionResponse
            {
                Success = false,
                Message = $"Data cannot be deleted: {retentionCheck.Reason}",
                RetentionUntil = retentionCheck.RetentionUntil
            };
        }

        // Create deletion request
        var dataRequest = dataSubject.CreateDataRequest(
            DataRequestType.Erasure,
            request.RequestedBy
        );

        // Mark for deletion
        dataSubject.MarkForDeletion(request.Reason);

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        // Schedule deletion job
        await ScheduleDeletionJobAsync(subjectId, dataRequest.Id, cancellationToken);

        // Audit the deletion request
        await _auditService.LogAsync(
            request.RequestedBy,
            "DataDeletion",
            "DataSubject",
            subjectId,
            AuditResult.Success,
            new { RequestId = dataRequest.Id, Reason = request.Reason },
            cancellationToken
        );

        return new DataDeletionResponse
        {
            Success = true,
            RequestId = dataRequest.Id,
            ScheduledDeletionDate = DateTime.UtcNow.AddDays(30), // 30-day grace period
            Message = "Data deletion has been scheduled"
        };
    }

    public async Task<AnonymizationResponse> AnonymizeDataAsync(
        string subjectId,
        AnonymizationRequest request,
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation(
            "Anonymizing data for subject {SubjectId}",
            subjectId
        );

        var personalData = await _personalDataRepository.GetBySubjectIdAsync(subjectId, cancellationToken);
        var anonymizedCount = 0;

        foreach (var data in personalData)
        {
            if (ShouldAnonymize(data, request.Categories))
            {
                var anonymized = await _anonymizationService.AnonymizeAsync(
                    data,
                    request.Technique,
                    cancellationToken
                );

                await _personalDataRepository.UpdateAsync(anonymized, cancellationToken);
                anonymizedCount++;
            }
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        await _auditService.LogAsync(
            request.RequestedBy,
            "DataAnonymization",
            "DataSubject",
            subjectId,
            AuditResult.Success,
            new { AnonymizedCount = anonymizedCount, Technique = request.Technique },
            cancellationToken
        );

        return new AnonymizationResponse
        {
            Success = true,
            AnonymizedRecords = anonymizedCount,
            Technique = request.Technique.ToString()
        };
    }

    private async Task<PersonalDataCollection> CollectPersonalDataAsync(
        string subjectId,
        CancellationToken cancellationToken)
    {
        var collection = new PersonalDataCollection
        {
            SubjectId = subjectId,
            CollectedAt = DateTime.UtcNow,
            Categories = new Dictionary<string, List<PersonalDataItem>&gt;()
        };

        // Get all personal data from various sources
        var personalData = await _personalDataRepository.GetBySubjectIdAsync(subjectId, cancellationToken);
        
        foreach (var data in personalData)
        {
            var category = data.Category;
            if (!collection.Categories.ContainsKey(category))
            {
                collection.Categories[category] = new List<PersonalDataItem>();
            }

            // Decrypt if necessary
            var value = data.IsEncrypted
                ? await _encryptionService.DecryptAsync(data.EncryptedValue, cancellationToken)
                : data.Value;

            collection.Categories[category].Add(new PersonalDataItem
            {
                DataType = data.DataType,
                Value = value,
                CollectedAt = data.CollectedAt,
                Source = data.Source,
                Sensitivity = data.Sensitivity.ToString()
            });
        }

        // Get conversation data
        var conversations = await GetConversationDataAsync(subjectId, cancellationToken);
        if (conversations.Any())
        {
            collection.Categories["Conversations"] = conversations;
        }

        // Get consent records
        var consents = await GetConsentDataAsync(subjectId, cancellationToken);
        if (consents.Any())
        {
            collection.Categories["Consents"] = consents;
        }

        return collection;
    }

    private async Task<RetentionCheckResult> CheckRetentionRequirementsAsync(
        string subjectId,
        CancellationToken cancellationToken)
    {
        // Check for legal holds
        var legalHold = await _personalDataRepository.HasLegalHoldAsync(subjectId, cancellationToken);
        if (legalHold)
        {
            return new RetentionCheckResult
            {
                CanDelete = false,
                Reason = "Data is under legal hold"
            };
        }

        // Check for active contracts or obligations
        var activeObligations = await _personalDataRepository.GetActiveObligationsAsync(subjectId, cancellationToken);
        if (activeObligations.Any())
        {
            var latestObligation = activeObligations
                .OrderByDescending(o =&gt; o.ExpiresAt)
                .First();

            return new RetentionCheckResult
            {
                CanDelete = false,
                Reason = "Active contractual obligations exist",
                RetentionUntil = latestObligation.ExpiresAt
            };
        }

        // Check regulatory requirements
        var regulatoryRetention = await CheckRegulatoryRetentionAsync(subjectId, cancellationToken);
        if (regulatoryRetention.HasValue)
        {
            return new RetentionCheckResult
            {
                CanDelete = false,
                Reason = "Regulatory retention requirements",
                RetentionUntil = regulatoryRetention.Value
            };
        }

        return new RetentionCheckResult { CanDelete = true };
    }

    private async Task ScheduleDeletionJobAsync(
        string subjectId,
        Guid requestId,
        CancellationToken cancellationToken)
    {
        // Schedule background job for data deletion
        // This would integrate with your job scheduling system (Hangfire, Azure Functions, etc.)
        _logger.LogInformation(
            "Scheduling deletion job for subject {SubjectId}, request {RequestId}",
            subjectId,
            requestId
        );
    }

    private bool ShouldAnonymize(PersonalDataRecord data, List<string> categories)
    {
        if (!categories.Any())
            return true;

        return categories.Contains(data.Category, StringComparer.OrdinalIgnoreCase);
    }

    private async Task<DateTime?> CheckRegulatoryRetentionAsync(
        string subjectId,
        CancellationToken cancellationToken)
    {
        // Implement regulatory checks based on data types and jurisdiction
        // For example, HIPAA requires 6-year retention for certain health records
        var healthData = await _personalDataRepository.HasHealthDataAsync(subjectId, cancellationToken);
        if (healthData)
        {
            return DateTime.UtcNow.AddYears(6);
        }

        return null;
    }
}
```

### Step 4: Create Compliance API Endpoints

Create `API/Controllers/ComplianceController.cs`:
```csharp
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using EnterpriseAgent.Application.Compliance.Commands;
using EnterpriseAgent.Application.Compliance.Queries;
using MediatR;

namespace EnterpriseAgent.API.Controllers;

[ApiController]
[Route("api/compliance")]
[Authorize]
public class ComplianceController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly ILogger<ComplianceController> _logger;

    public ComplianceController(IMediator mediator, ILogger<ComplianceController> logger)
    {
        _mediator = mediator;
        _logger = logger;
    }

    /// <summary>
    /// Grant consent for data processing
    /// </summary>
    [HttpPost("consent")]
    [ProducesResponseType(typeof(ConsentResultDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<ConsentResultDto>&gt; GrantConsent(
        [FromBody] GrantConsentCommand command,
        CancellationToken cancellationToken)
    {
        command = command with { UserId = User.Identity?.Name ?? "anonymous" };
        var result = await _mediator.Send(command, cancellationToken);
        return Ok(result);
    }

    /// <summary>
    /// Revoke consent
    /// </summary>
    [HttpDelete("consent/{consentId}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> RevokeConsent(
        Guid consentId,
        [FromBody] RevokeConsentRequest request,
        CancellationToken cancellationToken)
    {
        var command = new RevokeConsentCommand
        {
            ConsentId = consentId,
            Reason = request.Reason,
            UserId = User.Identity?.Name ?? "anonymous"
        };

        await _mediator.Send(command, cancellationToken);
        return NoContent();
    }

    /// <summary>
    /// Get consent status for a user
    /// </summary>
    [HttpGet("consent/status")]
    [ProducesResponseType(typeof(ConsentStatusDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<ConsentStatusDto>&gt; GetConsentStatus(
        [FromQuery] string? purpose = null,
        CancellationToken cancellationToken = default)
    {
        var query = new GetConsentStatusQuery
        {
            SubjectId = User.Identity?.Name ?? throw new UnauthorizedAccessException(),
            Purpose = purpose
        };

        var result = await _mediator.Send(query, cancellationToken);
        return Ok(result);
    }

    /// <summary>
    /// Request access to personal data (GDPR Article 15)
    /// </summary>
    [HttpPost("data-access")]
    [ProducesResponseType(typeof(DataAccessResponseDto), StatusCodes.Status202Accepted)]
    public async Task<ActionResult<DataAccessResponseDto>&gt; RequestDataAccess(
        CancellationToken cancellationToken)
    {
        var command = new DataAccessCommand
        {
            SubjectId = User.Identity?.Name ?? throw new UnauthorizedAccessException(),
            RequestedBy = User.Identity.Name
        };

        var result = await _mediator.Send(command, cancellationToken);
        return Accepted(result);
    }

    /// <summary>
    /// Request data deletion (GDPR Article 17 - Right to be forgotten)
    /// </summary>
    [HttpPost("data-deletion")]
    [ProducesResponseType(typeof(DataDeletionResponseDto), StatusCodes.Status202Accepted)]
    public async Task<ActionResult<DataDeletionResponseDto>&gt; RequestDataDeletion(
        [FromBody] DataDeletionRequest request,
        CancellationToken cancellationToken)
    {
        var command = new DataDeletionCommand
        {
            SubjectId = User.Identity?.Name ?? throw new UnauthorizedAccessException(),
            Reason = request.Reason,
            RequestedBy = User.Identity.Name
        };

        var result = await _mediator.Send(command, cancellationToken);
        return Accepted(result);
    }

    /// <summary>
    /// Request data portability (GDPR Article 20)
    /// </summary>
    [HttpPost("data-portability")]
    [ProducesResponseType(typeof(FileResult), StatusCodes.Status200OK)]
    public async Task<IActionResult> RequestDataPortability(
        [FromQuery] string format = "json",
        CancellationToken cancellationToken = default)
    {
        var command = new DataPortabilityCommand
        {
            SubjectId = User.Identity?.Name ?? throw new UnauthorizedAccessException(),
            Format = format,
            RequestedBy = User.Identity.Name
        };

        var result = await _mediator.Send(command, cancellationToken);
        
        var contentType = format.ToLower() switch
        {
            "json" =&gt; "application/json",
            "xml" =&gt; "application/xml",
            "csv" =&gt; "text/csv",
            _ =&gt; "application/octet-stream"
        };

        return File(result.Data, contentType, $"personal-data-{DateTime.UtcNow:yyyyMMdd}.{format}");
    }

    /// <summary>
    /// Get audit logs (for authorized personnel only)
    /// </summary>
    [HttpGet("audit-logs")]
    [Authorize(Roles = "Auditor,Admin")]
    [ProducesResponseType(typeof(IEnumerable<AuditLogDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IEnumerable<AuditLogDto>&gt;&gt; GetAuditLogs(
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        [FromQuery] string? userId = null,
        [FromQuery] string? action = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken cancellationToken = default)
    {
        var query = new GetAuditLogsQuery
        {
            StartDate = startDate ?? DateTime.UtcNow.AddDays(-7),
            EndDate = endDate ?? DateTime.UtcNow,
            UserId = userId,
            Action = action,
            Page = page,
            PageSize = pageSize
        };

        var result = await _mediator.Send(query, cancellationToken);
        return Ok(result);
    }

    /// <summary>
    /// Generate compliance report
    /// </summary>
    [HttpGet("reports/compliance")]
    [Authorize(Roles = "Auditor,Admin,ComplianceOfficer")]
    [ProducesResponseType(typeof(ComplianceReportDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<ComplianceReportDto>&gt; GenerateComplianceReport(
        [FromQuery] DateTime startDate,
        [FromQuery] DateTime endDate,
        [FromQuery] string? category = null,
        CancellationToken cancellationToken = default)
    {
        var query = new GenerateComplianceReportQuery
        {
            StartDate = startDate,
            EndDate = endDate,
            Category = category
        };

        var result = await _mediator.Send(query, cancellationToken);
        return Ok(result);
    }

    /// <summary>
    /// Update privacy preferences
    /// </summary>
    [HttpPut("privacy-preferences")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> UpdatePrivacyPreferences(
        [FromBody] UpdatePrivacyPreferencesCommand command,
        CancellationToken cancellationToken)
    {
        command = command with { SubjectId = User.Identity?.Name ?? throw new UnauthorizedAccessException() };
        await _mediator.Send(command, cancellationToken);
        return NoContent();
    }

    /// <summary>
    /// Get data retention policy
    /// </summary>
    [HttpGet("retention-policy")]
    [ProducesResponseType(typeof(RetentionPolicyDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<RetentionPolicyDto>&gt; GetRetentionPolicy(
        [FromQuery] string? dataCategory = null,
        CancellationToken cancellationToken = default)
    {
        var query = new GetRetentionPolicyQuery { DataCategory = dataCategory };
        var result = await _mediator.Send(query, cancellationToken);
        return Ok(result);
    }
}

public class RevokeConsentRequest
{
    public string Reason { get; set; } = string.Empty;
}

public class DataDeletionRequest
{
    public string Reason { get; set; } = string.Empty;
}
```

### Step 5: Implement Security Middleware

Create `API/Middleware/SecurityHeadersMiddleware.cs`:
```csharp
namespace EnterpriseAgent.API.Middleware;

public class SecurityHeadersMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<SecurityHeadersMiddleware> _logger;

    public SecurityHeadersMiddleware(RequestDelegate next, ILogger<SecurityHeadersMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Add security headers
        context.Response.Headers.Add("X-Content-Type-Options", "nosniff");
        context.Response.Headers.Add("X-Frame-Options", "DENY");
        context.Response.Headers.Add("X-XSS-Protection", "1; mode=block");
        context.Response.Headers.Add("Referrer-Policy", "strict-origin-when-cross-origin");
        context.Response.Headers.Add("Permissions-Policy", "geolocation=(), microphone=(), camera=()");
        
        // Content Security Policy
        context.Response.Headers.Add("Content-Security-Policy", 
            "default-src 'self'; " +
            "script-src 'self' 'unsafe-inline' 'unsafe-eval'; " +
            "style-src 'self' 'unsafe-inline'; " +
            "img-src 'self' data: https:; " +
            "font-src 'self'; " +
            "connect-src 'self' https://api.openai.com https://*.cognitiveservices.azure.com; " +
            "frame-ancestors 'none';");

        // Strict Transport Security (HSTS)
        if (context.Request.IsHttps)
        {
            context.Response.Headers.Add("Strict-Transport-Security", "max-age=31536000; includeSubDomains");
        }

        await _next(context);
    }
}
```

Create `API/Middleware/DataProtectionMiddleware.cs`:
```csharp
using System.Text.RegularExpressions;

namespace EnterpriseAgent.API.Middleware;

public class DataProtectionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<DataProtectionMiddleware> _logger;
    private readonly List<Regex> _sensitivePatterns;

    public DataProtectionMiddleware(RequestDelegate next, ILogger<DataProtectionMiddleware> logger)
    {
        _next = next;
        _logger = logger;
        
        // Define patterns for sensitive data
        _sensitivePatterns = new List<Regex>
        {
            new Regex(@"\b\d{\`3\`}-\d{\`2\`}-\d{\`4\`}\b", RegexOptions.Compiled), // SSN
            new Regex(@"\b\d{\`16\`}\b", RegexOptions.Compiled), // Credit card
            new Regex(@"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{\`2,\`}\b", RegexOptions.Compiled), // Email
            new Regex(@"\b\d{\`3\`}\.\d{\`3\`}\.\d{\`3\`}-\d{\`2\`}\b", RegexOptions.Compiled), // CPF (Brazil)
        };
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Enable request body buffering for logging
        context.Request.EnableBuffering();

        // Capture response body
        var originalBodyStream = context.Response.Body;
        using var responseBody = new MemoryStream();
        context.Response.Body = responseBody;

        try
        {
            await _next(context);

            // Check response for sensitive data
            context.Response.Body.Seek(0, SeekOrigin.Begin);
            var responseText = await new StreamReader(context.Response.Body).ReadToEndAsync();
            
            if (ContainsSensitiveData(responseText))
            {
                _logger.LogWarning(
                    "Potential sensitive data detected in response for {Path}",
                    context.Request.Path
                );
                
                // In production, you might want to:
                // 1. Mask the sensitive data
                // 2. Alert security team
                // 3. Block the response
            }

            context.Response.Body.Seek(0, SeekOrigin.Begin);
            await responseBody.CopyToAsync(originalBodyStream);
        }
        finally
        {
            context.Response.Body = originalBodyStream;
        }
    }

    private bool ContainsSensitiveData(string text)
    {
        return _sensitivePatterns.Any(pattern =&gt; pattern.IsMatch(text));
    }
}
```

### Step 6: Configure Compliance Features

Atualizar `API/Program.cs`:
```csharp
// Add compliance services
builder.Services.AddCompliance(builder.Configuration);

// Add security headers
app.UseMiddleware<SecurityHeadersMiddleware>();

// Add data protection
app.UseMiddleware<DataProtectionMiddleware>();

// Add HTTPS redirection
app.UseHttpsRedirection();

// Add HSTS
app.UseHsts();

// Add authentication and authorization
app.UseAuthentication();
app.UseAuthorization();

// Add audit middleware
app.UseMiddleware<AuditMiddleware>();
```

Create `Infrastructure/Compliance/ComplianceConfiguration.cs`:
```csharp
public static class ComplianceConfiguration
{
    public static IServiceCollection AddCompliance(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        // Consent management
        services.AddScoped<IConsentService, ConsentService>();
        
        // Privacy management
        services.AddScoped<IPrivacyManager, PrivacyManager>();
        
        // Encryption
        services.AddSingleton<IEncryptionService, EncryptionService>();
        services.AddDataProtection()
            .PersistKeysToAzureBlobStorage(configuration["DataProtection:BlobStorage"])
            .ProtectKeysWithAzureKeyVault(configuration["DataProtection:KeyVault"]);
        
        // Audit
        services.AddScoped<IAuditService, AuditService>();
        services.AddScoped<IAuditRepository, AuditRepository>();
        
        // Anonymization
        services.AddScoped<IAnonymizationService, AnonymizationService>();
        
        // Key Vault
        services.AddSingleton<IKeyVaultService, AzureKeyVaultService>();
        
        // Configure cookie policy
        services.Configure<CookiePolicyOptions>(options =&gt;
        {
            options.CheckConsentNeeded = context =&gt; true;
            options.MinimumSameSitePolicy = SameSiteMode.Strict;
            options.Secure = CookieSecurePolicy.Always;
        });
        
        // Configure identity options
        services.Configure<IdentityOptions>(options =&gt;
        {
            // Password settings
            options.Password.RequireDigit = true;
            options.Password.RequireLowercase = true;
            options.Password.RequireUppercase = true;
            options.Password.RequireNonAlphanumeric = true;
            options.Password.RequiredLength = 12;
            
            // Lockout settings
            options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(30);
            options.Lockout.MaxFailedAccessAttempts = 3;
            
            // User settings
            options.User.RequireUniqueEmail = true;
        });
        
        return services;
    }
}
```

## 🏃 Running the Exercício

1. **Configure compliance settings:**
```powershell
cd EnterpriseAgent.API
dotnet user-secrets set "DataProtection:KeyVault" "https://your-keyvault.vault.azure.net/"
dotnet user-secrets set "DataProtection:BlobStorage" "your-blob-connection-string"
```

2. **Run database migrations:**
```powershell
dotnet ef migrations add AddComplianceSupport
dotnet ef database update
```

3. **Run the API with HTTPS:**
```powershell
dotnet run --launch-profile https
```

4. **Test compliance endpoints:**

```bash
# Grant consent
curl -X POST https://localhost:7001/api/compliance/consent \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "purpose": "marketing",
    "scope": "email",
    "expiresAt": "2024-12-31T23:59:59Z"
  }'

# Request data access
curl -X POST https://localhost:7001/api/compliance/data-access \
  -H "Authorization: Bearer <token>"

# Update privacy preferences
curl -X PUT https://localhost:7001/api/compliance/privacy-preferences \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "marketingEmails": false,
    "dataSharing": false,
    "analytics": true
  }'

# Get audit logs (admin only)
curl https://localhost:7001/api/compliance/audit-logs?startDate=2024-01-01 \
  -H "Authorization: Bearer <admin-token>"
```

5. **Verify compliance features:**
   - Verificar that sensitive data is encrypted in the database
   - Verify audit logs are being created
   - Test consent management flow
   - Validate data export functionality

## 🎯 Validation

Your compliance-ready platform should now have:
- ✅ GDPR compliance with data subject rights
- ✅ Consent management with versioning
- ✅ Data encryption at rest and in transit
- ✅ Comprehensive audit logging
- ✅ Data retention and deletion policies
- ✅ Privacy by design implementation
- ✅ Security headers and middleware
- ✅ Compliance reporting capabilities

## 🚀 Bonus Challenges

1. **Add HIPAA Compliance:**
   - Implement BAA tracking
   - Add PHI encryption
   - Create access controls
   - Implement audit trails for health data

2. **Implement Zero-Knowledge Architecture:**
   - Client-side encryption
   - Homomorphic encryption for processing
   - Secure multi-party computation

3. **Add Compliance Automation:**
   - Automated compliance checks
   - Policy violation detection
   - Automated remediation
   - Compliance scorecards

4. **Enhanced Privacy Features:**
   - Differential privacy
   - Federated learning support
   - Privacy-preserving analytics
   - Synthetic data generation

## 📚 Additional Recursos

- [GDPR Developer Guia](https://gdpr.eu/checklist/)
- [HIPAA Compliance Guia](https://www.hhs.gov/hipaa/for-professionals/security/index.html)
- [SOC 2 Compliance](https://www.aicpa.org/interestareas/frc/assuranceadvisoryservices/aicpasoc2report)
- [Privacy by Design Framework](https://www.ipc.on.ca/wp-content/uploads/resources/7foundationalprinciples.pdf)

## ✅ Módulo 26 Completar!

Congratulations! You've completed Módulo 26 and built a comprehensive enterprise AI agent platform with:
- Clean Architecture and DDD
- Multi-modal capabilities
- Full compliance and security features

### 🎯 What's Próximo?

- Módulo 27: COBOL to Modern AI Migration
- Módulo 28: Avançado DevOps & Security
- Módulo 29: Empresarial Architecture Revisar
- Módulo 30: Capstone Project

---

**Remember**: Enterprise AI requires continuous attention to security, compliance, and governance. Keep your platform updated with the latest regulations and best practices!