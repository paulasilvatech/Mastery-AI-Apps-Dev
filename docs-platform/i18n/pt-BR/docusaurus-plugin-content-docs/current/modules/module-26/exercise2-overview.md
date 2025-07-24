---
sidebar_position: 2
title: "Exercise 2: Overview"
description: "## 🎯 Objective"
---

# Exercício 2: Multi-Modal Agent System (⭐⭐ Médio - 45 minutos)

## 🎯 Objective
Implement a sophisticated multi-modal AI agent system that can process text, voice, images, and documents using Azure AI services, building upon the enterprise framework from Exercício 1.

## 🧠 O Que Você Aprenderá
- Azure Cognitive Services integration
- Voice processing with Speech Services
- Image analysis with Computer Vision
- Document processing with Form Recognizer
- Multi-modal agent orchestration
- Async processing patterns
- File handling and storage

## 📋 Pré-requisitos
- Completard Exercício 1
- Azure assinatura with AI services
- Understanding of async/await patterns
- Basic knowledge of Azure Storage

## 📚 Voltarground

Modern AI agents need to handle multiple input modalities:

- **Text**: Natural language processing and generation
- **Voice**: Speech-to-text and text-to-speech
- **Vision**: Image analysis and OCR
- **Documents**: PDF, Word, Excel processing

We'll create a unified agent system that seamlessly handles all these modalities using Azure AI services.

## 🏗️ Multi-Modal Architecture

```mermaid
graph TB
    subgraph "Input Processing"
        TXT[Text Input]
        VOI[Voice Input]
        IMG[Image Input]
        DOC[Document Input]
    end
    
    subgraph "Azure AI Services"
        STT[Speech Services]
        CV[Computer Vision]
        FR[Form Recognizer]
        OAI[Azure OpenAI]
    end
    
    subgraph "Agent Core"
        MOD[Modality Detector]
        ORC[Orchestrator]
        CTX[Context Manager]
        RES[Response Generator]
    end
    
    subgraph "Output Generation"
        TOUT[Text Output]
        VOUT[Voice Output]
        IOUT[Image Output]
        DOUT[Document Output]
    end
    
    TXT --&gt; MOD
    VOI --&gt; STT --&gt; MOD
    IMG --&gt; CV --&gt; MOD
    DOC --&gt; FR --&gt; MOD
    
    MOD --&gt; ORC
    ORC --&gt; CTX
    CTX --&gt; OAI
    OAI --&gt; RES
    
    RES --&gt; TOUT
    RES --&gt; VOUT
    RES --&gt; IOUT
    RES --&gt; DOUT
    
    style OAI fill:#0078D4
    style ORC fill:#FF6B35
    style MOD fill:#68217A
```

## 🛠️ Step-by-Step Instructions

### Step 1: Create Multi-Modal Domain Models

**Copilot Prompt Suggestion:**
```csharp
// Extend the domain model to support multi-modal inputs:
// - Add ModalityType enum (Text, Voice, Image, Document)
// - Create MultiModalMessage value object with content and metadata
// - Add processing state tracking
// - Include modality-specific properties
```

Create `Domain/ValueObjects/MultiModalMessage.cs`:
```csharp
using EnterpriseAgent.Domain.Common;

namespace EnterpriseAgent.Domain.ValueObjects;

public class MultiModalMessage : ValueObject
{
    public ModalityType Modality { get; private set; }
    public string Content { get; private set; }
    public byte[]? BinaryContent { get; private set; }
    public string? ContentType { get; private set; }
    public Dictionary<string, object> Metadata { get; private set; }
    public ProcessingState State { get; private set; }
    public DateTime ReceivedAt { get; private set; }
    public DateTime? ProcessedAt { get; private set; }

    private MultiModalMessage() 
    {
        Metadata = new Dictionary<string, object>();
    }

    public static MultiModalMessage CreateTextMessage(string content)
    {
        return new MultiModalMessage
        {
            Modality = ModalityType.Text,
            Content = content ?? throw new ArgumentNullException(nameof(content)),
            State = ProcessingState.Pending,
            ReceivedAt = DateTime.UtcNow
        };
    }

    public static MultiModalMessage CreateVoiceMessage(byte[] audioData, string contentType)
    {
        if (audioData == null || audioData.Length == 0)
            throw new ArgumentException("Audio data is required", nameof(audioData));

        return new MultiModalMessage
        {
            Modality = ModalityType.Voice,
            BinaryContent = audioData,
            ContentType = contentType,
            Content = string.Empty, // Will be filled after transcription
            State = ProcessingState.Pending,
            ReceivedAt = DateTime.UtcNow
        };
    }

    public static MultiModalMessage CreateImageMessage(byte[] imageData, string contentType, string? caption = null)
    {
        if (imageData == null || imageData.Length == 0)
            throw new ArgumentException("Image data is required", nameof(imageData));

        return new MultiModalMessage
        {
            Modality = ModalityType.Image,
            BinaryContent = imageData,
            ContentType = contentType,
            Content = caption ?? string.Empty,
            State = ProcessingState.Pending,
            ReceivedAt = DateTime.UtcNow
        };
    }

    public static MultiModalMessage CreateDocumentMessage(byte[] documentData, string contentType, string fileName)
    {
        if (documentData == null || documentData.Length == 0)
            throw new ArgumentException("Document data is required", nameof(documentData));

        var message = new MultiModalMessage
        {
            Modality = ModalityType.Document,
            BinaryContent = documentData,
            ContentType = contentType,
            Content = string.Empty, // Will be filled after extraction
            State = ProcessingState.Pending,
            ReceivedAt = DateTime.UtcNow
        };

        message.Metadata["fileName"] = fileName;
        return message;
    }

    public void MarkAsProcessed(string processedContent)
    {
        Content = processedContent;
        State = ProcessingState.Processed;
        ProcessedAt = DateTime.UtcNow;
    }

    public void MarkAsFailed(string errorMessage)
    {
        State = ProcessingState.Failed;
        ProcessedAt = DateTime.UtcNow;
        Metadata["error"] = errorMessage;
    }

    public void AddMetadata(string key, object value)
    {
        Metadata[key] = value;
    }

    protected override IEnumerable<object> GetEqualityComponents()
    {
        yield return Modality;
        yield return Content;
        yield return ReceivedAt;
    }
}

public enum ModalityType
{
    Text,
    Voice,
    Image,
    Document
}

public enum ProcessingState
{
    Pending,
    Processing,
    Processed,
    Failed
}
```

Create `Domain/Entities/MultiModalConversation.cs`:
```csharp
using EnterpriseAgent.Domain.Common;
using EnterpriseAgent.Domain.ValueObjects;

namespace EnterpriseAgent.Domain.Entities;

public class MultiModalConversation : Entity
{
    private readonly List<MultiModalMessage> _messages = new();
    private readonly List<ConversationArtifact> _artifacts = new();

    public Guid AgentId { get; private set; }
    public string UserId { get; private set; }
    public ConversationMode Mode { get; private set; }
    public ConversationContext Context { get; private set; }
    public DateTime StartedAt { get; private set; }
    public DateTime? EndedAt { get; private set; }
    public Dictionary<ModalityType, int> ModalityCount { get; private set; }

    public IReadOnlyCollection<MultiModalMessage> Messages =&gt; _messages.AsReadOnly();
    public IReadOnlyCollection<ConversationArtifact> Artifacts =&gt; _artifacts.AsReadOnly();

    private MultiModalConversation() 
    {
        ModalityCount = new Dictionary<ModalityType, int>();
    }

    public static MultiModalConversation Create(Guid agentId, string userId)
    {
        return new MultiModalConversation
        {
            Id = Guid.NewGuid(),
            AgentId = agentId,
            UserId = userId,
            Mode = ConversationMode.Interactive,
            Context = ConversationContext.Initialize(),
            StartedAt = DateTime.UtcNow,
            ModalityCount = Enum.GetValues<ModalityType>()
                .ToDictionary(m =&gt; m, m =&gt; 0)
        };
    }

    public void AddMessage(MultiModalMessage message)
    {
        _messages.Add(message);
        ModalityCount[message.Modality]++;
        Context = Context.Update(message);
    }

    public void AddArtifact(ConversationArtifact artifact)
    {
        _artifacts.Add(artifact);
    }

    public MultiModalMessage? GetLastUserMessage()
    {
        return _messages
            .Where(m =&gt; m.Metadata.ContainsKey("role") && 
                       m.Metadata["role"].ToString() == "user")
            .OrderByDescending(m =&gt; m.ReceivedAt)
            .FirstOrDefault();
    }

    public IEnumerable<MultiModalMessage> GetMessagesByModality(ModalityType modality)
    {
        return _messages.Where(m =&gt; m.Modality == modality);
    }
}

public class ConversationArtifact : Entity
{
    public string Name { get; private set; }
    public string Type { get; private set; }
    public string StorageUrl { get; private set; }
    public long Size { get; private set; }
    public DateTime CreatedAt { get; private set; }
    
    public static ConversationArtifact Create(string name, string type, string storageUrl, long size)
    {
        return new ConversationArtifact
        {
            Id = Guid.NewGuid(),
            Name = name,
            Type = type,
            StorageUrl = storageUrl,
            Size = size,
            CreatedAt = DateTime.UtcNow
        };
    }
}

public enum ConversationMode
{
    Interactive,
    Batch,
    Stream
}
```

### Step 2: Implement Azure AI Service Integrations

Create `Infrastructure/Services/AzureSpeechService.cs`:
```csharp
using Microsoft.CognitiveServices.Speech;
using Microsoft.CognitiveServices.Speech.Audio;
using EnterpriseAgent.Application.Common.Interfaces;
using Microsoft.Extensions.Options;

namespace EnterpriseAgent.Infrastructure.Services;

public class AzureSpeechService : ISpeechService
{
    private readonly SpeechConfig _speechConfig;
    private readonly ILogger<AzureSpeechService> _logger;

    public AzureSpeechService(
        IOptions<AzureSpeechOptions> options,
        ILogger<AzureSpeechService> logger)
    {
        _logger = logger;
        _speechConfig = SpeechConfig.FromSubscription(
            options.Value.SubscriptionKey,
            options.Value.Region
        );
        
        // Configure speech synthesis
        _speechConfig.SpeechSynthesisVoiceName = options.Value.DefaultVoice ?? "en-US-JennyNeural";
        _speechConfig.SpeechRecognitionLanguage = options.Value.DefaultLanguage ?? "en-US";
    }

    public async Task<string> TranscribeAudioAsync(
        byte[] audioData,
        string language = "en-US",
        CancellationToken cancellationToken = default)
    {
        try
        {
            using var audioStream = new MemoryStream(audioData);
            using var audioConfig = AudioConfig.FromStreamInput(
                AudioInputStream.CreatePushStream(AudioStreamFormat.GetWaveFormatPCM(16000, 16, 1))
            );
            
            using var recognizer = new SpeechRecognizer(_speechConfig, audioConfig);
            
            var result = await recognizer.RecognizeOnceAsync();
            
            switch (result.Reason)
            {
                case ResultReason.RecognizedSpeech:
                    _logger.LogInformation("Speech recognized: {Text}", result.Text);
                    return result.Text;
                    
                case ResultReason.NoMatch:
                    _logger.LogWarning("No speech could be recognized");
                    throw new InvalidOperationException("No speech could be recognized");
                    
                case ResultReason.Canceled:
                    var cancellation = CancellationDetails.FromResult(result);
                    _logger.LogError("Speech recognition canceled: {Reason}", cancellation.Reason);
                    throw new InvalidOperationException($"Speech recognition canceled: {cancellation.Reason}");
                    
                default:
                    throw new InvalidOperationException("Unknown recognition result");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during speech transcription");
            throw;
        }
    }

    public async Task<byte[]> SynthesizeSpeechAsync(
        string text,
        string? voice = null,
        CancellationToken cancellationToken = default)
    {
        try
        {
            if (voice != null)
            {
                _speechConfig.SpeechSynthesisVoiceName = voice;
            }

            using var synthesizer = new SpeechSynthesizer(_speechConfig, null);
            
            var result = await synthesizer.SpeakTextAsync(text);
            
            if (result.Reason == ResultReason.SynthesizingAudioCompleted)
            {
                _logger.LogInformation("Speech synthesis completed for {Length} characters", text.Length);
                return result.AudioData;
            }
            else if (result.Reason == ResultReason.Canceled)
            {
                var cancellation = SpeechSynthesisCancellationDetails.FromResult(result);
                _logger.LogError("Speech synthesis canceled: {Reason}", cancellation.Reason);
                throw new InvalidOperationException($"Speech synthesis failed: {cancellation.Reason}");
            }
            
            throw new InvalidOperationException("Speech synthesis failed");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during speech synthesis");
            throw;
        }
    }

    public async Task<SpeechAnalysis> AnalyzeSpeechAsync(
        byte[] audioData,
        CancellationToken cancellationToken = default)
    {
        // Analyze speech for sentiment, prosody, etc.
        var transcription = await TranscribeAudioAsync(audioData, cancellationToken: cancellationToken);
        
        // For now, return basic analysis
        // In production, integrate with additional services for prosody analysis
        return new SpeechAnalysis
        {
            Transcription = transcription,
            Language = _speechConfig.SpeechRecognitionLanguage,
            Confidence = 0.95f,
            Duration = TimeSpan.FromSeconds(audioData.Length / 32000.0), // Assuming 16kHz stereo
            Features = new Dictionary<string, object>
            {
                ["volume"] = "normal",
                ["pace"] = "moderate",
                ["pitch"] = "neutral"
            }
        };
    }
}
```

Create `Infrastructure/Services/AzureComputerVisionService.cs`:
```csharp
using Microsoft.Azure.CognitiveServices.Vision.ComputerVision;
using Microsoft.Azure.CognitiveServices.Vision.ComputerVision.Models;
using EnterpriseAgent.Application.Common.Interfaces;
using Microsoft.Extensions.Options;

namespace EnterpriseAgent.Infrastructure.Services;

public class AzureComputerVisionService : IVisionService
{
    private readonly ComputerVisionClient _client;
    private readonly ILogger<AzureComputerVisionService> _logger;
    private readonly List<VisualFeatureTypes?> _defaultFeatures;

    public AzureComputerVisionService(
        IOptions<AzureComputerVisionOptions> options,
        ILogger<AzureComputerVisionService> logger)
    {
        _logger = logger;
        _client = new ComputerVisionClient(new ApiKeyServiceClientCredentials(options.Value.SubscriptionKey))
        {
            Endpoint = options.Value.Endpoint
        };

        _defaultFeatures = new List<VisualFeatureTypes?>
        {
            VisualFeatureTypes.Categories,
            VisualFeatureTypes.Description,
            VisualFeatureTypes.Objects,
            VisualFeatureTypes.Tags,
            VisualFeatureTypes.Faces,
            VisualFeatureTypes.Color,
            VisualFeatureTypes.ImageType
        };
    }

    public async Task<ImageAnalysis> AnalyzeImageAsync(
        byte[] imageData,
        List<string>? features = null,
        CancellationToken cancellationToken = default)
    {
        try
        {
            using var stream = new MemoryStream(imageData);
            
            var visualFeatures = features?.Select(f =&gt; Enum.Parse<VisualFeatureTypes>(f, true))
                                         .Cast<VisualFeatureTypes?>()
                                         .ToList() ?? _defaultFeatures;

            var analysis = await _client.AnalyzeImageInStreamAsync(
                stream,
                visualFeatures,
                cancellationToken: cancellationToken
            );

            _logger.LogInformation("Image analyzed successfully. Tags: {TagCount}", analysis.Tags.Count);

            return new ImageAnalysis
            {
                Description = analysis.Description.Captions.FirstOrDefault()?.Text ?? "No description available",
                Confidence = analysis.Description.Captions.FirstOrDefault()?.Confidence ?? 0,
                Tags = analysis.Tags.Select(t => new ImageTag
                {
                    Name = t.Name,
                    Confidence = t.Confidence
                }).ToList(),
                Objects = analysis.Objects.Select(o => new DetectedObject
                {
                    Name = o.ObjectProperty,
                    Confidence = o.Confidence,
                    BoundingBox = new BoundingBox
                    {
                        X = o.Rectangle.X,
                        Y = o.Rectangle.Y,
                        Width = o.Rectangle.W,
                        Height = o.Rectangle.H
                    }
                }).ToList(),
                Metadata = new Dictionary<string, object>
                {
                    ["width"] = analysis.Metadata.Width,
                    ["height"] = analysis.Metadata.Height,
                    ["format"] = analysis.Metadata.Format,
                    ["dominantColor"] = analysis.Color.DominantColorForeground,
                    ["accentColor"] = analysis.Color.AccentColor
                }
            };
        }
        catch (ComputerVisionErrorResponseException ex)
        {
            _logger.LogError(ex, "Computer Vision API error: {Error}", ex.Response.Content);
            throw new InvalidOperationException("Image analysis failed", ex);
        }
    }

    public async Task<string> ExtractTextFromImageAsync(
        byte[] imageData,
        CancellationToken cancellationToken = default)
    {
        try
        {
            using var stream = new MemoryStream(imageData);
            
            // Start the OCR operation
            var textHeaders = await _client.ReadInStreamAsync(stream, cancellationToken: cancellationToken);
            string operationLocation = textHeaders.OperationLocation;
            string operationId = operationLocation.Substring(operationLocation.LastIndexOf('/') + 1);

            // Wait for the operation to complete
            ReadOperationResult results;
            do
            {
                results = await _client.GetReadResultAsync(Guid.Parse(operationId), cancellationToken);
                await Task.Delay(1000, cancellationToken);
            }
            while (results.Status == OperationStatusCodes.Running || 
                   results.Status == OperationStatusCodes.NotStarted);

            if (results.Status == OperationStatusCodes.Succeeded)
            {
                var textResults = results.AnalyzeResult.ReadResults;
                var extractedText = string.Join("\n", 
                    textResults.SelectMany(page =&gt; page.Lines.Select(line =&gt; line.Text))
                );
                
                _logger.LogInformation("Text extracted from image: {CharCount} characters", extractedText.Length);
                return extractedText;
            }
            
            throw new InvalidOperationException($"OCR operation failed with status: {results.Status}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error extracting text from image");
            throw;
        }
    }

    public async Task<byte[]> GenerateThumbnailAsync(
        byte[] imageData,
        int width,
        int height,
        bool smartCropping = true,
        CancellationToken cancellationToken = default)
    {
        try
        {
            using var stream = new MemoryStream(imageData);
            using var thumbnailStream = await _client.GenerateThumbnailInStreamAsync(
                width,
                height,
                stream,
                smartCropping,
                cancellationToken
            );

            using var memoryStream = new MemoryStream();
            await thumbnailStream.CopyToAsync(memoryStream, cancellationToken);
            
            return memoryStream.ToArray();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating thumbnail");
            throw;
        }
    }
}
```

Create `Infrastructure/Services/AzureFormRecognizerService.cs`:
```csharp
using Azure;
using Azure.AI.FormRecognizer.DocumentAnalysis;
using EnterpriseAgent.Application.Common.Interfaces;
using Microsoft.Extensions.Options;

namespace EnterpriseAgent.Infrastructure.Services;

public class AzureFormRecognizerService : IDocumentService
{
    private readonly DocumentAnalysisClient _client;
    private readonly ILogger<AzureFormRecognizerService> _logger;

    public AzureFormRecognizerService(
        IOptions<AzureFormRecognizerOptions> options,
        ILogger<AzureFormRecognizerService> logger)
    {
        _logger = logger;
        _client = new DocumentAnalysisClient(
            new Uri(options.Value.Endpoint),
            new AzureKeyCredential(options.Value.ApiKey)
        );
    }

    public async Task<DocumentAnalysis> AnalyzeDocumentAsync(
        byte[] documentData,
        string documentType,
        CancellationToken cancellationToken = default)
    {
        try
        {
            using var stream = new MemoryStream(documentData);
            
            // Determine the model to use based on document type
            string modelId = documentType.ToLower() switch
            {
                "invoice" =&gt; "prebuilt-invoice",
                "receipt" =&gt; "prebuilt-receipt",
                "businesscard" =&gt; "prebuilt-businessCard",
                "idcard" =&gt; "prebuilt-idDocument",
                _ =&gt; "prebuilt-document" // General document model
            };

            AnalyzeDocumentOperation operation = await _client.AnalyzeDocumentAsync(
                WaitUntil.Completed,
                modelId,
                stream,
                cancellationToken: cancellationToken
            );

            AnalyzeResult result = operation.Value;
            
            var analysis = new DocumentAnalysis
            {
                DocumentType = documentType,
                PageCount = result.Pages.Count,
                Content = result.Content,
                ExtractedData = new Dictionary<string, object>(),
                Tables = new List<ExtractedTable>(),
                KeyValuePairs = new Dictionary<string, string>()
            };

            // Extract key-value pairs
            foreach (var kvp in result.KeyValuePairs)
            {
                if (kvp.Key != null && kvp.Value != null)
                {
                    analysis.KeyValuePairs[kvp.Key.Content] = kvp.Value.Content;
                }
            }

            // Extract tables
            foreach (var table in result.Tables)
            {
                var extractedTable = new ExtractedTable
                {
                    RowCount = table.RowCount,
                    ColumnCount = table.ColumnCount,
                    Cells = table.Cells.Select(cell =&gt; new TableCell
                    {
                        RowIndex = cell.RowIndex,
                        ColumnIndex = cell.ColumnIndex,
                        Content = cell.Content,
                        RowSpan = cell.RowSpan ?? 1,
                        ColumnSpan = cell.ColumnSpan ?? 1
                    }).ToList()
                };
                analysis.Tables.Add(extractedTable);
            }

            // Extract document-specific fields based on type
            if (result.Documents.Any())
            {
                var doc = result.Documents.First();
                foreach (var field in doc.Fields)
                {
                    analysis.ExtractedData[field.Key] = ExtractFieldValue(field.Value);
                }
            }

            _logger.LogInformation(
                "Document analyzed: {PageCount} pages, {TableCount} tables, {FieldCount} fields extracted",
                analysis.PageCount,
                analysis.Tables.Count,
                analysis.ExtractedData.Count
            );

            return analysis;
        }
        catch (RequestFailedException ex)
        {
            _logger.LogError(ex, "Form Recognizer request failed");
            throw new InvalidOperationException("Document analysis failed", ex);
        }
    }

    public async Task<string> ExtractTextFromDocumentAsync(
        byte[] documentData,
        CancellationToken cancellationToken = default)
    {
        var analysis = await AnalyzeDocumentAsync(documentData, "general", cancellationToken);
        return analysis.Content;
    }

    public async Task<DocumentClassification> ClassifyDocumentAsync(
        byte[] documentData,
        CancellationToken cancellationToken = default)
    {
        // Use the general document model to classify
        var analysis = await AnalyzeDocumentAsync(documentData, "general", cancellationToken);
        
        // Simple classification based on content and structure
        var classification = new DocumentClassification
        {
            DocumentType = DetermineDocumentType(analysis),
            Confidence = 0.85f, // Placeholder - implement proper confidence scoring
            Language = "en", // Placeholder - implement language detection
            Metadata = new Dictionary<string, object>
            {
                ["pageCount"] = analysis.PageCount,
                ["hasT

ables"] = analysis.Tables.Any(),
                ["fieldCount"] = analysis.ExtractedData.Count
            }
        };

        return classification;
    }

    private object ExtractFieldValue(DocumentField field)
    {
        return field.FieldType switch
        {
            DocumentFieldType.String =&gt; field.Value.AsString(),
            DocumentFieldType.Date =&gt; field.Value.AsDate(),
            DocumentFieldType.Time =&gt; field.Value.AsTime(),
            DocumentFieldType.PhoneNumber =&gt; field.Value.AsPhoneNumber(),
            DocumentFieldType.Double =&gt; field.Value.AsDouble(),
            DocumentFieldType.Long =&gt; field.Value.AsLong(),
            DocumentFieldType.SelectionMark =&gt; field.Value.AsBoolean(),
            DocumentFieldType.Currency =&gt; field.Value.AsCurrency(),
            _ =&gt; field.Content
        };
    }

    private string DetermineDocumentType(DocumentAnalysis analysis)
    {
        // Simple heuristic-based classification
        var content = analysis.Content.ToLower();
        var data = analysis.ExtractedData;

        if (data.ContainsKey("InvoiceId") || content.Contains("invoice"))
            return "invoice";
        if (data.ContainsKey("ReceiptType") || content.Contains("receipt"))
            return "receipt";
        if (data.ContainsKey("ContactNames") || content.Contains("business card"))
            return "businesscard";
        if (content.Contains("contract") || content.Contains("agreement"))
            return "contract";
        if (content.Contains("report"))
            return "report";

        return "general";
    }
}
```

### Step 3: Create Multi-Modal Processing Pipeline

Create `Application/MultiModal/Commands/ProcessMultiModalMessageCommand.cs`:
```csharp
using MediatR;
using EnterpriseAgent.Domain.ValueObjects;
using EnterpriseAgent.Application.Common.Interfaces;

namespace EnterpriseAgent.Application.MultiModal.Commands;

public record ProcessMultiModalMessageCommand : IRequest<ProcessedMessageDto>
{
    public Guid AgentId { get; init; }
    public Guid ConversationId { get; init; }
    public ModalityType Modality { get; init; }
    public byte[]? BinaryContent { get; init; }
    public string? TextContent { get; init; }
    public string? ContentType { get; init; }
    public Dictionary<string, object> Metadata { get; init; } = new();
}

public class ProcessMultiModalMessageCommandHandler : IRequestHandler<ProcessMultiModalMessageCommand, ProcessedMessageDto>
{
    private readonly IMultiModalProcessor _processor;
    private readonly IConversationRepository _conversationRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<ProcessMultiModalMessageCommandHandler> _logger;

    public ProcessMultiModalMessageCommandHandler(
        IMultiModalProcessor processor,
        IConversationRepository conversationRepository,
        IUnitOfWork unitOfWork,
        ILogger<ProcessMultiModalMessageCommandHandler> logger)
    {
        _processor = processor;
        _conversationRepository = conversationRepository;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<ProcessedMessageDto> Handle(
        ProcessMultiModalMessageCommand request,
        CancellationToken cancellationToken)
    {
        _logger.LogInformation(
            "Processing {Modality} message for conversation {ConversationId}",
            request.Modality,
            request.ConversationId
        );

        // Get conversation
        var conversation = await _conversationRepository.GetByIdAsync(request.ConversationId, cancellationToken);
        if (conversation == null)
        {
            throw new NotFoundException($"Conversation {request.ConversationId} not found");
        }

        // Create multi-modal message
        MultiModalMessage message = request.Modality switch
        {
            ModalityType.Text =&gt; MultiModalMessage.CreateTextMessage(request.TextContent!),
            ModalityType.Voice =&gt; MultiModalMessage.CreateVoiceMessage(request.BinaryContent!, request.ContentType!),
            ModalityType.Image =&gt; MultiModalMessage.CreateImageMessage(request.BinaryContent!, request.ContentType!),
            ModalityType.Document =&gt; MultiModalMessage.CreateDocumentMessage(
                request.BinaryContent!,
                request.ContentType!,
                request.Metadata.GetValueOrDefault("fileName", "document").ToString()!
            ),
            _ =&gt; throw new NotSupportedException($"Modality {request.Modality} not supported")
        };

        // Add metadata
        foreach (var (key, value) in request.Metadata)
        {
            message.AddMetadata(key, value);
        }

        // Add to conversation
        conversation.AddMessage(message);

        // Process the message
        var processedContent = await _processor.ProcessAsync(message, cancellationToken);
        
        // Generate AI response
        var response = await _processor.GenerateResponseAsync(
            conversation,
            processedContent,
            cancellationToken
        );

        // Save changes
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return new ProcessedMessageDto
        {
            MessageId = message.Id,
            ConversationId = conversation.Id,
            Modality = message.Modality,
            ProcessedContent = processedContent.Content,
            ResponseContent = response.Content,
            ResponseModality = response.Modality,
            ProcessingTime = processedContent.ProcessingTime,
            Metadata = processedContent.Metadata
        };
    }
}
```

Create `Application/MultiModal/Services/MultiModalProcessor.cs`:
```csharp
using EnterpriseAgent.Domain.ValueObjects;
using EnterpriseAgent.Domain.Entities;
using EnterpriseAgent.Application.Common.Interfaces;

namespace EnterpriseAgent.Application.MultiModal.Services;

public class MultiModalProcessor : IMultiModalProcessor
{
    private readonly ISpeechService _speechService;
    private readonly IVisionService _visionService;
    private readonly IDocumentService _documentService;
    private readonly IAIService _aiService;
    private readonly IStorageService _storageService;
    private readonly ILogger<MultiModalProcessor> _logger;

    public MultiModalProcessor(
        ISpeechService speechService,
        IVisionService visionService,
        IDocumentService documentService,
        IAIService aiService,
        IStorageService storageService,
        ILogger<MultiModalProcessor> logger)
    {
        _speechService = speechService;
        _visionService = visionService;
        _documentService = documentService;
        _aiService = aiService;
        _storageService = storageService;
        _logger = logger;
    }

    public async Task<ProcessedContent> ProcessAsync(
        MultiModalMessage message,
        CancellationToken cancellationToken = default)
    {
        var startTime = DateTime.UtcNow;
        var metadata = new Dictionary<string, object>(message.Metadata);

        try
        {
            string processedContent = message.Modality switch
            {
                ModalityType.Text =&gt; await ProcessTextAsync(message, metadata, cancellationToken),
                ModalityType.Voice =&gt; await ProcessVoiceAsync(message, metadata, cancellationToken),
                ModalityType.Image =&gt; await ProcessImageAsync(message, metadata, cancellationToken),
                ModalityType.Document =&gt; await ProcessDocumentAsync(message, metadata, cancellationToken),
                _ =&gt; throw new NotSupportedException($"Modality {message.Modality} not supported")
            };

            message.MarkAsProcessed(processedContent);

            return new ProcessedContent
            {
                Content = processedContent,
                Modality = message.Modality,
                ProcessingTime = DateTime.UtcNow - startTime,
                Metadata = metadata
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing {Modality} message", message.Modality);
            message.MarkAsFailed(ex.Message);
            throw;
        }
    }

    private async Task<string> ProcessTextAsync(
        MultiModalMessage message,
        Dictionary<string, object> metadata,
        CancellationToken cancellationToken)
    {
        // Text is already processed, just return it
        metadata["wordCount"] = message.Content.Split(' ').Length;
        metadata["characterCount"] = message.Content.Length;
        
        return message.Content;
    }

    private async Task<string> ProcessVoiceAsync(
        MultiModalMessage message,
        Dictionary<string, object> metadata,
        CancellationToken cancellationToken)
    {
        _logger.LogInformation("Processing voice message, size: {Size} bytes", message.BinaryContent!.Length);

        // Transcribe audio
        var transcription = await _speechService.TranscribeAudioAsync(
            message.BinaryContent!,
            cancellationToken: cancellationToken
        );

        // Analyze speech characteristics
        var analysis = await _speechService.AnalyzeSpeechAsync(
            message.BinaryContent!,
            cancellationToken
        );

        metadata["transcription"] = transcription;
        metadata["duration"] = analysis.Duration.TotalSeconds;
        metadata["language"] = analysis.Language;
        metadata["confidence"] = analysis.Confidence;
        
        foreach (var feature in analysis.Features)
        {
            metadata[$"speech_{feature.Key}"] = feature.Value;
        }

        // Store audio file
        var audioUrl = await _storageService.UploadAsync(
            $"audio/{message.Id}.wav",
            message.BinaryContent!,
            message.ContentType!,
            cancellationToken
        );
        metadata["audioUrl"] = audioUrl;

        return transcription;
    }

    private async Task<string> ProcessImageAsync(
        MultiModalMessage message,
        Dictionary<string, object> metadata,
        CancellationToken cancellationToken)
    {
        _logger.LogInformation("Processing image, size: {Size} bytes", message.BinaryContent!.Length);

        // Analyze image
        var analysis = await _visionService.AnalyzeImageAsync(
            message.BinaryContent!,
            cancellationToken: cancellationToken
        );

        // Extract text if present
        var extractedText = await _visionService.ExtractTextFromImageAsync(
            message.BinaryContent!,
            cancellationToken
        );

        // Generate thumbnail
        var thumbnail = await _visionService.GenerateThumbnailAsync(
            message.BinaryContent!,
            200,
            200,
            cancellationToken: cancellationToken
        );

        // Store image and thumbnail
        var imageUrl = await _storageService.UploadAsync(
            $"images/{message.Id}.jpg",
            message.BinaryContent!,
            message.ContentType!,
            cancellationToken
        );
        
        var thumbnailUrl = await _storageService.UploadAsync(
            $"thumbnails/{message.Id}.jpg",
            thumbnail,
            "image/jpeg",
            cancellationToken
        );

        metadata["imageUrl"] = imageUrl;
        metadata["thumbnailUrl"] = thumbnailUrl;
        metadata["description"] = analysis.Description;
        metadata["confidence"] = analysis.Confidence;
        metadata["tags"] = string.Join(", ", analysis.Tags.Select(t =&gt; t.Name));
        metadata["objectCount"] = analysis.Objects.Count;
        
        if (!string.IsNullOrWhiteSpace(extractedText))
        {
            metadata["extractedText"] = extractedText;
        }

        // Build comprehensive description
        var contentBuilder = new StringBuilder();
        contentBuilder.AppendLine($"Image Description: {analysis.Description}");
        
        if (analysis.Objects.Any())
        {
            contentBuilder.AppendLine($"Detected Objects: {string.Join(", ", analysis.Objects.Select(o =&gt; o.Name))}");
        }
        
        if (!string.IsNullOrWhiteSpace(extractedText))
        {
            contentBuilder.AppendLine($"Text in Image: {extractedText}");
        }

        return contentBuilder.ToString();
    }

    private async Task<string> ProcessDocumentAsync(
        MultiModalMessage message,
        Dictionary<string, object> metadata,
        CancellationToken cancellationToken)
    {
        _logger.LogInformation(
            "Processing document: {FileName}, size: {Size} bytes",
            metadata.GetValueOrDefault("fileName", "unknown"),
            message.BinaryContent!.Length
        );

        // Classify document
        var classification = await _documentService.ClassifyDocumentAsync(
            message.BinaryContent!,
            cancellationToken
        );

        // Analyze document
        var analysis = await _documentService.AnalyzeDocumentAsync(
            message.BinaryContent!,
            classification.DocumentType,
            cancellationToken
        );

        // Store document
        var documentUrl = await _storageService.UploadAsync(
            $"documents/{message.Id}/{metadata.GetValueOrDefault("fileName", "document")}",
            message.BinaryContent!,
            message.ContentType!,
            cancellationToken
        );

        metadata["documentUrl"] = documentUrl;
        metadata["documentType"] = classification.DocumentType;
        metadata["pageCount"] = analysis.PageCount;
        metadata["tableCount"] = analysis.Tables.Count;
        metadata["extractedFields"] = analysis.ExtractedData.Count;

        // Build content summary
        var contentBuilder = new StringBuilder();
        contentBuilder.AppendLine($"Document Type: {classification.DocumentType}");
        contentBuilder.AppendLine($"Pages: {analysis.PageCount}");
        
        if (analysis.ExtractedData.Any())
        {
            contentBuilder.AppendLine("\nExtracted Information:");
            foreach (var (key, value) in analysis.ExtractedData.Take(10)) // Limit to first 10 fields
            {
                contentBuilder.AppendLine($"- {key}: {value}");
            }
        }
        
        if (!string.IsNullOrWhiteSpace(analysis.Content))
        {
            contentBuilder.AppendLine($"\nDocument Content (first 500 chars):");
            contentBuilder.AppendLine(analysis.Content.Substring(0, Math.Min(500, analysis.Content.Length)));
        }

        return contentBuilder.ToString();
    }

    public async Task<MultiModalResponse> GenerateResponseAsync(
        MultiModalConversation conversation,
        ProcessedContent processedContent,
        CancellationToken cancellationToken = default)
    {
        // Build context from conversation history
        var messages = BuildConversationContext(conversation, processedContent);
        
        // Get AI response
        var aiResponse = await _aiService.GetChatCompletionAsync(
            messages,
            "gpt-4",
            new Dictionary<string, object>
            {
                ["temperature"] = 0.7f,
                ["maxTokens"] = 2000
            },
            cancellationToken
        );

        // Determine response modality based on input and preferences
        var responseModality = DetermineResponseModality(
            processedContent.Modality,
            conversation.Context
        );

        // Convert response to appropriate modality
        var response = await ConvertResponseToModality(
            aiResponse.Content,
            responseModality,
            cancellationToken
        );

        return response;
    }

    private List<ChatMessage> BuildConversationContext(
        MultiModalConversation conversation,
        ProcessedContent currentMessage)
    {
        var messages = new List<ChatMessage>();
        
        // Add system prompt
        messages.Add(new ChatMessage
        {
            Role = "system",
            Content = "You are a helpful multi-modal AI assistant capable of understanding text, voice, images, and documents. Provide clear and contextual responses based on the user's input."
        });

        // Add conversation history (last 10 messages for context)
        foreach (var msg in conversation.Messages.TakeLast(10))
        {
            if (msg.State == ProcessingState.Processed)
            {
                var role = msg.Metadata.GetValueOrDefault("role", "user").ToString();
                messages.Add(new ChatMessage
                {
                    Role = role!,
                    Content = msg.Content
                });
            }
        }

        // Add current processed message
        messages.Add(new ChatMessage
        {
            Role = "user",
            Content = currentMessage.Content
        });

        return messages;
    }

    private ModalityType DetermineResponseModality(
        ModalityType inputModality,
        ConversationContext context)
    {
        // For now, respond in the same modality as input
        // In production, this could be based on user preferences or context
        return inputModality switch
        {
            ModalityType.Voice =&gt; ModalityType.Voice,
            ModalityType.Image =&gt; ModalityType.Text, // Can't generate images yet
            ModalityType.Document =&gt; ModalityType.Document,
            _ =&gt; ModalityType.Text
        };
    }

    private async Task<MultiModalResponse> ConvertResponseToModality(
        string textResponse,
        ModalityType targetModality,
        CancellationToken cancellationToken)
    {
        var response = new MultiModalResponse
        {
            Content = textResponse,
            Modality = targetModality,
            Metadata = new Dictionary<string, object>()
        };

        switch (targetModality)
        {
            case ModalityType.Voice:
                // Convert text to speech
                var audioData = await _speechService.SynthesizeSpeechAsync(
                    textResponse,
                    cancellationToken: cancellationToken
                );
                
                response.BinaryContent = audioData;
                response.ContentType = "audio/wav";
                response.Metadata["duration"] = audioData.Length / 32000.0; // Assuming 16kHz stereo
                break;
                
            case ModalityType.Document:
                // For document responses, we might generate a formatted document
                // For now, just return as text
                response.Modality = ModalityType.Text;
                break;
        }

        return response;
    }
}
```

### Step 4: Create API Endpoints for Multi-Modal Support

Create `API/Controllers/MultiModalController.cs`:
```csharp
using Microsoft.AspNetCore.Mvc;
using MediatR;
using EnterpriseAgent.Application.MultiModal.Commands;
using EnterpriseAgent.Domain.ValueObjects;

namespace EnterpriseAgent.API.Controllers;

[ApiController]
[Route("api/agents/{agentId}/conversations/{conversationId}/messages")]
public class MultiModalController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly ILogger<MultiModalController> _logger;
    private const long MaxFileSize = 10 * 1024 * 1024; // 10MB

    public MultiModalController(IMediator mediator, ILogger<MultiModalController> logger)
    {
        _mediator = mediator;
        _logger = logger;
    }

    /// <summary>
    /// Send a text message
    /// </summary>
    [HttpPost("text")]
    [ProducesResponseType(typeof(ProcessedMessageDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<ProcessedMessageDto>&gt; SendTextMessage(
        Guid agentId,
        Guid conversationId,
        [FromBody] SendTextMessageRequest request,
        CancellationToken cancellationToken)
    {
        var command = new ProcessMultiModalMessageCommand
        {
            AgentId = agentId,
            ConversationId = conversationId,
            Modality = ModalityType.Text,
            TextContent = request.Content,
            Metadata = request.Metadata ?? new Dictionary<string, object>()
        };

        var result = await _mediator.Send(command, cancellationToken);
        return Ok(result);
    }

    /// <summary>
    /// Send a voice message
    /// </summary>
    [HttpPost("voice")]
    [ProducesResponseType(typeof(ProcessedMessageDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [RequestSizeLimit(MaxFileSize)]
    public async Task<ActionResult<ProcessedMessageDto>&gt; SendVoiceMessage(
        Guid agentId,
        Guid conversationId,
        IFormFile audioFile,
        CancellationToken cancellationToken)
    {
        if (audioFile == null || audioFile.Length == 0)
        {
            return BadRequest("Audio file is required");
        }

        if (!IsValidAudioFormat(audioFile.ContentType))
        {
            return BadRequest("Invalid audio format. Supported formats: wav, mp3, m4a");
        }

        using var memoryStream = new MemoryStream();
        await audioFile.CopyToAsync(memoryStream, cancellationToken);

        var command = new ProcessMultiModalMessageCommand
        {
            AgentId = agentId,
            ConversationId = conversationId,
            Modality = ModalityType.Voice,
            BinaryContent = memoryStream.ToArray(),
            ContentType = audioFile.ContentType,
            Metadata = new Dictionary<string, object>
            {
                ["fileName"] = audioFile.FileName,
                ["fileSize"] = audioFile.Length
            }
        };

        var result = await _mediator.Send(command, cancellationToken);
        return Ok(result);
    }

    /// <summary>
    /// Send an image message
    /// </summary>
    [HttpPost("image")]
    [ProducesResponseType(typeof(ProcessedMessageDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [RequestSizeLimit(MaxFileSize)]
    public async Task<ActionResult<ProcessedMessageDto>&gt; SendImageMessage(
        Guid agentId,
        Guid conversationId,
        IFormFile imageFile,
        [FromForm] string? caption,
        CancellationToken cancellationToken)
    {
        if (imageFile == null || imageFile.Length == 0)
        {
            return BadRequest("Image file is required");
        }

        if (!IsValidImageFormat(imageFile.ContentType))
        {
            return BadRequest("Invalid image format. Supported formats: jpg, jpeg, png, gif, bmp");
        }

        using var memoryStream = new MemoryStream();
        await imageFile.CopyToAsync(memoryStream, cancellationToken);

        var command = new ProcessMultiModalMessageCommand
        {
            AgentId = agentId,
            ConversationId = conversationId,
            Modality = ModalityType.Image,
            BinaryContent = memoryStream.ToArray(),
            ContentType = imageFile.ContentType,
            TextContent = caption,
            Metadata = new Dictionary<string, object>
            {
                ["fileName"] = imageFile.FileName,
                ["fileSize"] = imageFile.Length
            }
        };

        var result = await _mediator.Send(command, cancellationToken);
        return Ok(result);
    }

    /// <summary>
    /// Send a document message
    /// </summary>
    [HttpPost("document")]
    [ProducesResponseType(typeof(ProcessedMessageDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [RequestSizeLimit(MaxFileSize)]
    public async Task<ActionResult<ProcessedMessageDto>&gt; SendDocumentMessage(
        Guid agentId,
        Guid conversationId,
        IFormFile documentFile,
        CancellationToken cancellationToken)
    {
        if (documentFile == null || documentFile.Length == 0)
        {
            return BadRequest("Document file is required");
        }

        if (!IsValidDocumentFormat(documentFile.ContentType))
        {
            return BadRequest("Invalid document format. Supported formats: pdf, docx, xlsx, pptx, txt");
        }

        using var memoryStream = new MemoryStream();
        await documentFile.CopyToAsync(memoryStream, cancellationToken);

        var command = new ProcessMultiModalMessageCommand
        {
            AgentId = agentId,
            ConversationId = conversationId,
            Modality = ModalityType.Document,
            BinaryContent = memoryStream.ToArray(),
            ContentType = documentFile.ContentType,
            Metadata = new Dictionary<string, object>
            {
                ["fileName"] = documentFile.FileName,
                ["fileSize"] = documentFile.Length
            }
        };

        var result = await _mediator.Send(command, cancellationToken);
        return Ok(result);
    }

    /// <summary>
    /// Stream voice response
    /// </summary>
    [HttpGet("{messageId}/voice-response")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetVoiceResponse(
        Guid agentId,
        Guid conversationId,
        Guid messageId,
        CancellationToken cancellationToken)
    {
        // Get voice response from storage
        var query = new GetVoiceResponseQuery(conversationId, messageId);
        var voiceData = await _mediator.Send(query, cancellationToken);

        if (voiceData == null)
        {
            return NotFound();
        }

        return File(voiceData.AudioData, voiceData.ContentType, $"response-{messageId}.wav");
    }

    private bool IsValidAudioFormat(string contentType)
    {
        var validFormats = new[] { "audio/wav", "audio/mp3", "audio/mpeg", "audio/m4a" };
        return validFormats.Contains(contentType, StringComparer.OrdinalIgnoreCase);
    }

    private bool IsValidImageFormat(string contentType)
    {
        var validFormats = new[] { "image/jpeg", "image/jpg", "image/png", "image/gif", "image/bmp" };
        return validFormats.Contains(contentType, StringComparer.OrdinalIgnoreCase);
    }

    private bool IsValidDocumentFormat(string contentType)
    {
        var validFormats = new[]
        {
            "application/pdf",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "application/vnd.openxmlformats-officedocument.presentationml.presentation",
            "text/plain"
        };
        return validFormats.Contains(contentType, StringComparer.OrdinalIgnoreCase);
    }
}

public class SendTextMessageRequest
{
    public string Content { get; set; } = string.Empty;
    public Dictionary<string, object>? Metadata { get; set; }
}
```

### Step 5: Configure Multi-Modal Services

Atualizar `Infrastructure/DependencyInjection.cs`:
```csharp
public static IServiceCollection AddInfrastructure(
    this IServiceCollection services,
    IConfiguration configuration)
{
    // ... existing registrations ...

    // Multi-modal services
    services.Configure<AzureSpeechOptions>(configuration.GetSection("AzureSpeech"));
    services.Configure<AzureComputerVisionOptions>(configuration.GetSection("AzureComputerVision"));
    services.Configure<AzureFormRecognizerOptions>(configuration.GetSection("AzureFormRecognizer"));

    services.AddSingleton<ISpeechService, AzureSpeechService>();
    services.AddSingleton<IVisionService, AzureComputerVisionService>();
    services.AddSingleton<IDocumentService, AzureFormRecognizerService>();
    services.AddScoped<IMultiModalProcessor, MultiModalProcessor>();

    // Storage service for binary content
    services.AddSingleton<IStorageService, AzureBlobStorageService>();

    return services;
}
```

Atualizar `appsettings.json`:
```json
{
  "AzureSpeech": {
    "SubscriptionKey": "your-speech-key",
    "Region": "eastus",
    "DefaultVoice": "en-US-JennyNeural",
    "DefaultLanguage": "en-US"
  },
  "AzureComputerVision": {
    "SubscriptionKey": "your-vision-key",
    "Endpoint": "https://your-resource.cognitiveservices.azure.com/"
  },
  "AzureFormRecognizer": {
    "ApiKey": "your-form-recognizer-key",
    "Endpoint": "https://your-resource.cognitiveservices.azure.com/"
  },
  "AzureStorage": {
    "ConnectionString": "DefaultEndpointsProtocol=https;AccountName=...",
    "ContainerName": "agent-artifacts"
  }
}
```

## 🏃 Running the Exercício

1. **Atualizar Azure service configurations:**
```powershell
cd EnterpriseAgent.API
dotnet user-secrets set "AzureSpeech:SubscriptionKey" "your-key"
dotnet user-secrets set "AzureComputerVision:SubscriptionKey" "your-key"
dotnet user-secrets set "AzureFormRecognizer:ApiKey" "your-key"
```

2. **Run database migrations:**
```powershell
dotnet ef migrations add AddMultiModalSupport
dotnet ef database update
```

3. **Run the API:**
```powershell
dotnet run
```

4. **Test multi-modal endpoints:**

```bash
# Send text message
curl -X POST https://localhost:7001/api/agents/{agentId}/conversations/{conversationId}/messages/text \
  -H "Content-Type: application/json" \
  -d '{
    "content": "What can you help me with today?"
  }'

# Send voice message
curl -X POST https://localhost:7001/api/agents/{agentId}/conversations/{conversationId}/messages/voice \
  -H "Content-Type: multipart/form-data" \
  -F "audioFile=@sample-audio.wav"

# Send image with caption
curl -X POST https://localhost:7001/api/agents/{agentId}/conversations/{conversationId}/messages/image \
  -H "Content-Type: multipart/form-data" \
  -F "imageFile=@sample-image.jpg" \
  -F "caption=What is in this image?"

# Send document
curl -X POST https://localhost:7001/api/agents/{agentId}/conversations/{conversationId}/messages/document \
  -H "Content-Type: multipart/form-data" \
  -F "documentFile=@sample-document.pdf"
```

5. **Test with sample files:**
   - Create or download sample audio, image, and document files
   - Use the Swagger UI at https://localhost:7001/swagger to test interactively

## 🎯 Validation

Your multi-modal agent system should now support:
- ✅ Text message processing with NLP
- ✅ Voice transcription and synthesis
- ✅ Image analysis and text extraction
- ✅ Document parsing and classification
- ✅ Unified conversation context across modalities
- ✅ File storage and retrieval
- ✅ Async processing for large files
- ✅ Proper error handling for each modality

## 🚀 Bonus Challenges

1. **Add Real-time Processing:**
   - Implement SignalR for streaming responses
   - Add progress notifications for long operations
   - Stream audio responses in chunks

2. **Enhanced Vision Capabilities:**
   - Add custom vision model support
   - Implement image generation with DALL-E
   - Add facial recognition (with privacy controls)

3. **Avançado Document Processing:**
   - Support for more document types
   - Table extraction and formatting
   - Multi-language document support

4. **Cross-Modal Features:**
   - Generate image captions as voice
   - Convert documents to audio books
   - Create visual summaries of conversations

## 📚 Additional Recursos

- [Azure Cognitive Services Documentação](https://docs.microsoft.com/azure/cognitive-services/)
- [Speech Service Documentação](https://docs.microsoft.com/azure/cognitive-services/speech-service/)
- [Computer Vision Documentação](https://docs.microsoft.com/azure/cognitive-services/computer-vision/)
- [Form Recognizer Documentação](https://docs.microsoft.com/azure/applied-ai-services/form-recognizer/)

## ⏭️ Próximo Exercício

Ready to add compliance and security features? Move on to [Exercício 3: Compliance-Ready Platform](/docs/modules/module-26/exercise3-overview) where you'll implement GDPR, HIPAA, and enterprise security!