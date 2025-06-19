# Exercise 3: AI-Powered Enterprise System - Part 1: AI Foundation and Infrastructure

## 🎯 Overview

In this first part, you'll establish the AI foundation for the enterprise system, including Semantic Kernel setup, vector database configuration, RAG pipeline implementation, and multi-agent system architecture.

## 📋 Part 1 Objectives

- Set up Semantic Kernel with enterprise configuration
- Configure vector databases for semantic search
- Implement RAG (Retrieval Augmented Generation) pipeline
- Create base AI agents for different domains
- Establish AI service abstractions
- Set up monitoring for AI operations

## 🏗️ Step 1: Create Solution Structure

### 1.1 Create the Solution

```bash
# Create solution directory
mkdir AIEnterprise
cd AIEnterprise

# Create solution
dotnet new sln -n AIEnterprise

# Create project structure
mkdir -p src/{Core/Domain,Core/Application,AI/Kernel,AI/Agents,Infrastructure,API,WebApp}
mkdir -p tests/{Unit,Integration,AI,Load}
mkdir -p notebooks
mkdir -p infrastructure/{bicep,kubernetes}
```

### 1.2 Create Core Projects

```bash
# Domain project
cd src/Core/Domain
dotnet new classlib -n AIEnterprise.Domain
cd ../../..
dotnet sln add src/Core/Domain/AIEnterprise.Domain.csproj

# Application project
cd src/Core/Application
dotnet new classlib -n AIEnterprise.Application
cd ../../..
dotnet sln add src/Core/Application/AIEnterprise.Application.csproj

# AI Kernel project
cd src/AI/Kernel
dotnet new classlib -n AIEnterprise.AI.Kernel
cd ../../..
dotnet sln add src/AI/Kernel/AIEnterprise.AI.Kernel.csproj

# AI Agents project
cd src/AI/Agents
dotnet new classlib -n AIEnterprise.AI.Agents
cd ../../..
dotnet sln add src/AI/Agents/AIEnterprise.AI.Agents.csproj

# Add references
cd src/Core/Application
dotnet add reference ../Domain/AIEnterprise.Domain.csproj

cd ../../AI/Kernel
dotnet add reference ../../Core/Application/AIEnterprise.Application.csproj

cd ../Agents
dotnet add reference ../Kernel/AIEnterprise.AI.Kernel.csproj

cd ../../..
```

### 1.3 Install AI Packages

```bash
# AI Kernel project packages
cd src/AI/Kernel
dotnet add package Microsoft.SemanticKernel
dotnet add package Microsoft.SemanticKernel.Connectors.OpenAI
dotnet add package Microsoft.SemanticKernel.Connectors.Memory.AzureCognitiveSearch
dotnet add package Microsoft.SemanticKernel.Plugins.Memory
dotnet add package Azure.AI.OpenAI
dotnet add package Azure.Search.Documents
dotnet add package Microsoft.ML
dotnet add package Microsoft.Azure.Cosmos

# Infrastructure packages
cd ../../Infrastructure
dotnet add package Azure.Storage.Blobs
dotnet add package Azure.Messaging.EventHubs
dotnet add package Azure.Monitor.Query
dotnet add package Microsoft.Azure.CognitiveServices.Vision.ComputerVision
dotnet add package Microsoft.CognitiveServices.Speech

cd ../../..
```

## 🧠 Step 2: Configure Semantic Kernel

### 2.1 Create Kernel Configuration

Create `src/AI/Kernel/Configuration/KernelConfiguration.cs`:

```csharp
namespace AIEnterprise.AI.Kernel.Configuration;

public class KernelConfiguration
{
    public string ServiceId { get; set; } = "enterprise-ai";
    public OpenAIConfiguration OpenAI { get; set; } = new();
    public AzureSearchConfiguration Search { get; set; } = new();
    public MemoryConfiguration Memory { get; set; } = new();
    public List<PluginConfiguration> Plugins { get; set; } = new();
}

public class OpenAIConfiguration
{
    public string Endpoint { get; set; } = null!;
    public string ApiKey { get; set; } = null!;
    public string ChatDeploymentName { get; set; } = "gpt-4";
    public string EmbeddingDeploymentName { get; set; } = "text-embedding-ada-002";
    public int MaxTokens { get; set; } = 4000;
    public double Temperature { get; set; } = 0.7;
}

public class AzureSearchConfiguration
{
    public string Endpoint { get; set; } = null!;
    public string ApiKey { get; set; } = null!;
    public string IndexName { get; set; } = "enterprise-knowledge";
    public int SearchResultsLimit { get; set; } = 10;
}

public class MemoryConfiguration
{
    public int MaxMemoryTokens { get; set; } = 2000;
    public int ConversationHistoryLimit { get; set; } = 10;
    public bool EnableSemanticMemory { get; set; } = true;
    public bool EnableEpisodicMemory { get; set; } = true;
}

public class PluginConfiguration
{
    public string Name { get; set; } = null!;
    public string Type { get; set; } = null!;
    public bool Enabled { get; set; } = true;
    public Dictionary<string, object> Settings { get; set; } = new();
}
```

### 2.2 Create Kernel Builder

Create `src/AI/Kernel/Services/EnterpriseKernelBuilder.cs`:

```csharp
namespace AIEnterprise.AI.Kernel.Services;

public class EnterpriseKernelBuilder
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<EnterpriseKernelBuilder> _logger;
    private readonly ITelemetryService _telemetry;

    public EnterpriseKernelBuilder(
        IConfiguration configuration,
        ILogger<EnterpriseKernelBuilder> logger,
        ITelemetryService telemetry)
    {
        _configuration = configuration;
        _logger = logger;
        _telemetry = telemetry;
    }

    public IKernel BuildKernel()
    {
        var kernelConfig = _configuration
            .GetSection("AIKernel")
            .Get<KernelConfiguration>() ?? new KernelConfiguration();

        var builder = Kernel.CreateBuilder();

        // Configure OpenAI
        ConfigureOpenAI(builder, kernelConfig.OpenAI);

        // Configure Memory
        ConfigureMemory(builder, kernelConfig);

        // Add plugins
        ConfigurePlugins(builder, kernelConfig.Plugins);

        // Add telemetry
        builder.Services.AddSingleton(_telemetry);

        var kernel = builder.Build();

        _logger.LogInformation(
            "Enterprise kernel built with {PluginCount} plugins",
            kernelConfig.Plugins.Count);

        return kernel;
    }

    private void ConfigureOpenAI(IKernelBuilder builder, OpenAIConfiguration config)
    {
        builder.AddAzureOpenAIChatCompletion(
            deploymentName: config.ChatDeploymentName,
            endpoint: config.Endpoint,
            apiKey: config.ApiKey,
            serviceId: "chat");

        builder.AddAzureOpenAITextEmbeddingGeneration(
            deploymentName: config.EmbeddingDeploymentName,
            endpoint: config.Endpoint,
            apiKey: config.ApiKey,
            serviceId: "embeddings");
    }

    private void ConfigureMemory(IKernelBuilder builder, KernelConfiguration config)
    {
        // Add Azure Cognitive Search as memory store
        var memoryBuilder = new MemoryBuilder();
        
        memoryBuilder.WithAzureOpenAITextEmbeddingGeneration(
            config.OpenAI.EmbeddingDeploymentName,
            config.OpenAI.Endpoint,
            config.OpenAI.ApiKey);

        memoryBuilder.WithMemoryStore(new AzureCognitiveSearchMemoryStore(
            config.Search.Endpoint,
            config.Search.ApiKey));

        var memory = memoryBuilder.Build();
        
        builder.Services.AddSingleton<ISemanticTextMemory>(memory);
    }

    private void ConfigurePlugins(IKernelBuilder builder, List<PluginConfiguration> plugins)
    {
        foreach (var pluginConfig in plugins.Where(p => p.Enabled))
        {
            switch (pluginConfig.Type)
            {
                case "Native":
                    LoadNativePlugin(builder, pluginConfig);
                    break;
                case "Semantic":
                    LoadSemanticPlugin(builder, pluginConfig);
                    break;
                case "Custom":
                    LoadCustomPlugin(builder, pluginConfig);
                    break;
            }
        }
    }

    private void LoadNativePlugin(IKernelBuilder builder, PluginConfiguration config)
    {
        var pluginInstance = config.Name switch
        {
            "BusinessPlugin" => new BusinessIntelligencePlugin(_telemetry),
            "DataPlugin" => new EnterpriseDataPlugin(_configuration),
            "SecurityPlugin" => new SecurityPlugin(_logger),
            _ => throw new NotSupportedException($"Unknown plugin: {config.Name}")
        };

        builder.Plugins.AddFromObject(pluginInstance, config.Name);
    }

    private void LoadSemanticPlugin(IKernelBuilder builder, PluginConfiguration config)
    {
        var pluginDirectory = Path.Combine(
            AppDomain.CurrentDomain.BaseDirectory,
            "Plugins",
            config.Name);

        builder.Plugins.AddFromPromptDirectory(pluginDirectory);
    }

    private void LoadCustomPlugin(IKernelBuilder builder, PluginConfiguration config)
    {
        // Load custom plugins from assemblies
        var assemblyPath = config.Settings["AssemblyPath"]?.ToString();
        if (!string.IsNullOrEmpty(assemblyPath))
        {
            var assembly = Assembly.LoadFrom(assemblyPath);
            var pluginType = assembly.GetType(config.Settings["TypeName"]?.ToString() ?? "");
            
            if (pluginType != null)
            {
                var pluginInstance = Activator.CreateInstance(pluginType);
                builder.Plugins.AddFromObject(pluginInstance!, config.Name);
            }
        }
    }
}
```

### 2.3 Create AI Service Abstractions

Create `src/AI/Kernel/Abstractions/IAIService.cs`:

```csharp
namespace AIEnterprise.AI.Kernel.Abstractions;

public interface IAIService
{
    Task<ConversationResponse> ProcessConversationAsync(
        ConversationRequest request,
        CancellationToken cancellationToken = default);
        
    Task<AnalysisResult> AnalyzeDocumentAsync(
        DocumentAnalysisRequest request,
        CancellationToken cancellationToken = default);
        
    Task<PredictionResult> PredictAsync(
        PredictionRequest request,
        CancellationToken cancellationToken = default);
        
    Task<List<Recommendation>> GetRecommendationsAsync(
        RecommendationRequest request,
        CancellationToken cancellationToken = default);
}

public record ConversationRequest(
    string UserId,
    string Message,
    List<ConversationContext> History,
    Dictionary<string, object> Variables);

public record ConversationResponse(
    string Response,
    string Intent,
    double Confidence,
    List<SuggestedAction> Actions,
    Dictionary<string, object> Metadata);

public record ConversationContext(
    string Role,
    string Message,
    DateTime Timestamp);

public record SuggestedAction(
    string Type,
    string Description,
    Dictionary<string, object> Parameters);

public record DocumentAnalysisRequest(
    byte[] Document,
    string DocumentType,
    List<string> AnalysisTypes);

public record AnalysisResult(
    string Summary,
    List<ExtractedEntity> Entities,
    Dictionary<string, double> Sentiments,
    List<KeyPhrase> KeyPhrases,
    Dictionary<string, object> CustomAnalysis);

public record PredictionRequest(
    string ModelName,
    Dictionary<string, object> Features,
    PredictionType Type);

public record PredictionResult(
    object Prediction,
    double Confidence,
    Dictionary<string, double> Probabilities,
    List<FeatureImportance> ImportantFeatures);

public record RecommendationRequest(
    string UserId,
    string Context,
    int MaxRecommendations,
    Dictionary<string, object> Filters);

public record Recommendation(
    string Id,
    string Type,
    string Title,
    string Description,
    double Score,
    Dictionary<string, object> Metadata);

public enum PredictionType
{
    Classification,
    Regression,
    Clustering,
    AnomalyDetection,
    Forecasting
}
```

## 🔍 Step 3: Implement RAG Pipeline

### 3.1 Create Document Processor

Create `src/AI/Kernel/Services/DocumentProcessor.cs`:

```csharp
namespace AIEnterprise.AI.Kernel.Services;

public class DocumentProcessor : IDocumentProcessor
{
    private readonly IConfiguration _configuration;
    private readonly ITextSplitter _textSplitter;
    private readonly IEmbeddingGenerator _embeddingGenerator;
    private readonly IVectorStore _vectorStore;
    private readonly ILogger<DocumentProcessor> _logger;

    public DocumentProcessor(
        IConfiguration configuration,
        ITextSplitter textSplitter,
        IEmbeddingGenerator embeddingGenerator,
        IVectorStore vectorStore,
        ILogger<DocumentProcessor> logger)
    {
        _configuration = configuration;
        _textSplitter = textSplitter;
        _embeddingGenerator = embeddingGenerator;
        _vectorStore = vectorStore;
        _logger = logger;
    }

    public async Task<ProcessingResult> ProcessDocumentAsync(
        Stream documentStream,
        DocumentMetadata metadata,
        CancellationToken cancellationToken = default)
    {
        try
        {
            // Extract text based on document type
            var extractedText = await ExtractTextAsync(
                documentStream, 
                metadata.ContentType, 
                cancellationToken);

            // Split into chunks
            var chunks = await _textSplitter.SplitTextAsync(
                extractedText,
                new SplitOptions
                {
                    MaxChunkSize = 1000,
                    ChunkOverlap = 200,
                    SeparatorPattern = @"(?<=[.!?])\s+",
                    PreserveFormatting = true
                });

            // Generate embeddings for each chunk
            var documents = new List<VectorDocument>();
            
            foreach (var (chunk, index) in chunks.Select((c, i) => (c, i)))
            {
                var embedding = await _embeddingGenerator.GenerateEmbeddingAsync(
                    chunk.Text,
                    cancellationToken);

                var document = new VectorDocument
                {
                    Id = $"{metadata.DocumentId}_chunk_{index}",
                    Content = chunk.Text,
                    Embedding = embedding,
                    Metadata = new Dictionary<string, object>
                    {
                        ["DocumentId"] = metadata.DocumentId,
                        ["ChunkIndex"] = index,
                        ["Source"] = metadata.Source,
                        ["Title"] = metadata.Title,
                        ["Author"] = metadata.Author ?? "Unknown",
                        ["CreatedDate"] = metadata.CreatedDate,
                        ["ChunkStart"] = chunk.StartPosition,
                        ["ChunkEnd"] = chunk.EndPosition
                    }
                };

                documents.Add(document);
            }

            // Store in vector database
            await _vectorStore.UpsertBatchAsync(
                metadata.CollectionName,
                documents,
                cancellationToken);

            _logger.LogInformation(
                "Processed document {DocumentId} into {ChunkCount} chunks",
                metadata.DocumentId,
                chunks.Count);

            return new ProcessingResult
            {
                Success = true,
                DocumentId = metadata.DocumentId,
                ChunksCreated = chunks.Count,
                TotalTokens = chunks.Sum(c => c.TokenCount)
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Failed to process document {DocumentId}",
                metadata.DocumentId);
                
            return new ProcessingResult
            {
                Success = false,
                DocumentId = metadata.DocumentId,
                Error = ex.Message
            };
        }
    }

    private async Task<string> ExtractTextAsync(
        Stream documentStream,
        string contentType,
        CancellationToken cancellationToken)
    {
        return contentType switch
        {
            "application/pdf" => await ExtractPdfTextAsync(documentStream, cancellationToken),
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => 
                await ExtractDocxTextAsync(documentStream, cancellationToken),
            "text/plain" => await ExtractPlainTextAsync(documentStream, cancellationToken),
            "text/html" => await ExtractHtmlTextAsync(documentStream, cancellationToken),
            _ => throw new NotSupportedException($"Content type {contentType} not supported")
        };
    }

    private async Task<string> ExtractPdfTextAsync(
        Stream pdfStream,
        CancellationToken cancellationToken)
    {
        // Use Azure Form Recognizer or similar service
        var client = new DocumentAnalysisClient(
            new Uri(_configuration["FormRecognizer:Endpoint"]),
            new AzureKeyCredential(_configuration["FormRecognizer:ApiKey"]));

        var operation = await client.AnalyzeDocumentAsync(
            WaitUntil.Completed,
            "prebuilt-read",
            pdfStream,
            cancellationToken: cancellationToken);

        var result = operation.Value;
        var text = string.Join("\n", result.Pages.SelectMany(p => p.Lines).Select(l => l.Content));
        
        return text;
    }

    // Additional extraction methods...
}

public interface ITextSplitter
{
    Task<List<TextChunk>> SplitTextAsync(string text, SplitOptions options);
}

public class SmartTextSplitter : ITextSplitter
{
    private readonly ILogger<SmartTextSplitter> _logger;

    public SmartTextSplitter(ILogger<SmartTextSplitter> logger)
    {
        _logger = logger;
    }

    public async Task<List<TextChunk>> SplitTextAsync(string text, SplitOptions options)
    {
        var chunks = new List<TextChunk>();
        var sentences = SplitIntoSentences(text, options.SeparatorPattern);
        
        var currentChunk = new StringBuilder();
        var currentTokenCount = 0;
        var startPosition = 0;
        var currentPosition = 0;

        foreach (var sentence in sentences)
        {
            var sentenceTokens = EstimateTokenCount(sentence);
            
            if (currentTokenCount + sentenceTokens > options.MaxChunkSize && currentChunk.Length > 0)
            {
                // Save current chunk
                chunks.Add(new TextChunk
                {
                    Text = currentChunk.ToString().Trim(),
                    TokenCount = currentTokenCount,
                    StartPosition = startPosition,
                    EndPosition = currentPosition
                });

                // Start new chunk with overlap
                currentChunk.Clear();
                currentTokenCount = 0;
                startPosition = Math.Max(0, currentPosition - options.ChunkOverlap);
                
                // Add overlap from previous chunk if needed
                if (options.ChunkOverlap > 0 && chunks.Count > 0)
                {
                    var overlapText = GetOverlapText(text, startPosition, currentPosition);
                    currentChunk.Append(overlapText);
                    currentTokenCount = EstimateTokenCount(overlapText);
                }
            }

            currentChunk.AppendLine(sentence);
            currentTokenCount += sentenceTokens;
            currentPosition += sentence.Length;
        }

        // Add final chunk
        if (currentChunk.Length > 0)
        {
            chunks.Add(new TextChunk
            {
                Text = currentChunk.ToString().Trim(),
                TokenCount = currentTokenCount,
                StartPosition = startPosition,
                EndPosition = text.Length
            });
        }

        _logger.LogDebug(
            "Split text into {ChunkCount} chunks, average size {AvgSize} tokens",
            chunks.Count,
            chunks.Average(c => c.TokenCount));

        return chunks;
    }

    private List<string> SplitIntoSentences(string text, string pattern)
    {
        if (string.IsNullOrEmpty(pattern))
            pattern = @"(?<=[.!?])\s+";
            
        return Regex.Split(text, pattern)
            .Where(s => !string.IsNullOrWhiteSpace(s))
            .ToList();
    }

    private int EstimateTokenCount(string text)
    {
        // Rough estimation: 1 token ≈ 4 characters
        return (int)Math.Ceiling(text.Length / 4.0);
    }

    private string GetOverlapText(string text, int start, int end)
    {
        var length = Math.Min(end - start, text.Length - start);
        return text.Substring(start, length);
    }
}

public class TextChunk
{
    public string Text { get; set; } = null!;
    public int TokenCount { get; set; }
    public int StartPosition { get; set; }
    public int EndPosition { get; set; }
}

public class SplitOptions
{
    public int MaxChunkSize { get; set; } = 1000;
    public int ChunkOverlap { get; set; } = 200;
    public string SeparatorPattern { get; set; } = @"(?<=[.!?])\s+";
    public bool PreserveFormatting { get; set; } = true;
}
```

### 3.2 Create Vector Store Implementation

Create `src/Infrastructure/AI/VectorStore/CosmosVectorStore.cs`:

```csharp
namespace AIEnterprise.Infrastructure.AI.VectorStore;

public class CosmosVectorStore : IVectorStore
{
    private readonly CosmosClient _cosmosClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<CosmosVectorStore> _logger;
    private readonly ITelemetryService _telemetry;

    public CosmosVectorStore(
        CosmosClient cosmosClient,
        IConfiguration configuration,
        ILogger<CosmosVectorStore> logger,
        ITelemetryService telemetry)
    {
        _cosmosClient = cosmosClient;
        _configuration = configuration;
        _logger = logger;
        _telemetry = telemetry;
    }

    public async Task<string> UpsertAsync(
        string collectionName,
        VectorDocument document,
        CancellationToken cancellationToken = default)
    {
        using var activity = _telemetry.StartActivity("VectorStore.Upsert");
        
        try
        {
            var container = await GetOrCreateContainerAsync(collectionName, cancellationToken);
            
            var cosmosDoc = new CosmosVectorDocument
            {
                id = document.Id,
                content = document.Content,
                embedding = document.Embedding,
                metadata = document.Metadata,
                _ts = DateTimeOffset.UtcNow.ToUnixTimeSeconds()
            };

            var response = await container.UpsertItemAsync(
                cosmosDoc,
                new PartitionKey(GetPartitionKey(document)),
                cancellationToken: cancellationToken);

            _telemetry.TrackMetric("VectorStore.DocumentSize", document.Embedding.Length);
            
            return response.Resource.id;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Failed to upsert document {DocumentId} to collection {Collection}",
                document.Id,
                collectionName);
            throw;
        }
    }

    public async Task UpsertBatchAsync(
        string collectionName,
        IEnumerable<VectorDocument> documents,
        CancellationToken cancellationToken = default)
    {
        using var activity = _telemetry.StartActivity("VectorStore.UpsertBatch");
        
        var container = await GetOrCreateContainerAsync(collectionName, cancellationToken);
        var tasks = new List<Task>();
        
        // Use bulk operations for better performance
        foreach (var batch in documents.Chunk(100))
        {
            var batchTasks = batch.Select(doc => UpsertAsync(collectionName, doc, cancellationToken));
            tasks.AddRange(batchTasks);
            
            // Rate limiting
            if (tasks.Count >= 10)
            {
                await Task.WhenAll(tasks);
                tasks.Clear();
                await Task.Delay(100, cancellationToken);
            }
        }
        
        if (tasks.Any())
        {
            await Task.WhenAll(tasks);
        }
        
        _telemetry.TrackMetric("VectorStore.BatchSize", documents.Count());
    }

    public async Task<List<VectorSearchResult>> SearchAsync(
        string collectionName,
        float[] queryEmbedding,
        int topK = 10,
        Dictionary<string, object>? filters = null,
        CancellationToken cancellationToken = default)
    {
        using var activity = _telemetry.StartActivity("VectorStore.Search");
        
        var container = await GetOrCreateContainerAsync(collectionName, cancellationToken);
        
        // Build query with vector search
        var queryBuilder = new StringBuilder();
        queryBuilder.Append("SELECT TOP @topK ");
        queryBuilder.Append("c.id, c.content, c.metadata, ");
        queryBuilder.Append("VectorDistance(c.embedding, @queryEmbedding) AS score ");
        queryBuilder.Append("FROM c ");
        
        if (filters != null && filters.Any())
        {
            queryBuilder.Append("WHERE ");
            var filterClauses = filters.Select((f, i) => $"c.metadata.{f.Key} = @filter{i}");
            queryBuilder.Append(string.Join(" AND ", filterClauses));
        }
        
        queryBuilder.Append(" ORDER BY VectorDistance(c.embedding, @queryEmbedding)");

        var queryDefinition = new QueryDefinition(queryBuilder.ToString())
            .WithParameter("@topK", topK)
            .WithParameter("@queryEmbedding", queryEmbedding);

        if (filters != null)
        {
            var filterIndex = 0;
            foreach (var filter in filters)
            {
                queryDefinition.WithParameter($"@filter{filterIndex}", filter.Value);
                filterIndex++;
            }
        }

        var results = new List<VectorSearchResult>();
        
        using var iterator = container.GetItemQueryIterator<CosmosVectorSearchResult>(queryDefinition);
        
        while (iterator.HasMoreResults)
        {
            var response = await iterator.ReadNextAsync(cancellationToken);
            
            results.AddRange(response.Select(r => new VectorSearchResult
            {
                Id = r.id,
                Content = r.content,
                Score = r.score,
                Metadata = r.metadata
            }));
        }
        
        _telemetry.TrackMetric("VectorStore.SearchResults", results.Count);
        
        return results.OrderBy(r => r.Score).Take(topK).ToList();
    }

    public async Task<VectorDocument?> GetAsync(
        string collectionName,
        string documentId,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var container = await GetOrCreateContainerAsync(collectionName, cancellationToken);
            
            var response = await container.ReadItemAsync<CosmosVectorDocument>(
                documentId,
                new PartitionKey(GetPartitionKeyFromId(documentId)),
                cancellationToken: cancellationToken);

            return new VectorDocument
            {
                Id = response.Resource.id,
                Content = response.Resource.content,
                Embedding = response.Resource.embedding,
                Metadata = response.Resource.metadata
            };
        }
        catch (CosmosException ex) when (ex.StatusCode == HttpStatusCode.NotFound)
        {
            return null;
        }
    }

    public async Task<bool> DeleteAsync(
        string collectionName,
        string documentId,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var container = await GetOrCreateContainerAsync(collectionName, cancellationToken);
            
            await container.DeleteItemAsync<CosmosVectorDocument>(
                documentId,
                new PartitionKey(GetPartitionKeyFromId(documentId)),
                cancellationToken: cancellationToken);
                
            return true;
        }
        catch (CosmosException ex) when (ex.StatusCode == HttpStatusCode.NotFound)
        {
            return false;
        }
    }

    private async Task<Container> GetOrCreateContainerAsync(
        string collectionName,
        CancellationToken cancellationToken)
    {
        var database = _cosmosClient.GetDatabase(_configuration["Cosmos:DatabaseName"]);
        
        var containerProperties = new ContainerProperties
        {
            Id = collectionName,
            PartitionKeyPath = "/partitionKey",
            VectorEmbeddingPolicy = new VectorEmbeddingPolicy(new Collection<Embedding>
            {
                new Embedding
                {
                    Path = "/embedding",
                    DataType = VectorDataType.Float32,
                    Dimensions = 1536, // OpenAI embeddings dimension
                    DistanceFunction = DistanceFunction.Cosine
                }
            }),
            IndexingPolicy = new IndexingPolicy
            {
                VectorIndexes = new Collection<VectorIndexPath>
                {
                    new VectorIndexPath
                    {
                        Path = "/embedding",
                        Type = VectorIndexType.Flat
                    }
                }
            }
        };

        var response = await database.CreateContainerIfNotExistsAsync(
            containerProperties,
            throughput: 1000,
            cancellationToken: cancellationToken);

        return response.Container;
    }

    private string GetPartitionKey(VectorDocument document)
    {
        // Use document source or type as partition key for better distribution
        if (document.Metadata.TryGetValue("Source", out var source))
        {
            return source.ToString() ?? "default";
        }
        
        return "default";
    }

    private string GetPartitionKeyFromId(string documentId)
    {
        // Extract partition key from document ID if encoded
        var parts = documentId.Split('_');
        return parts.Length > 1 ? parts[0] : "default";
    }
}

internal class CosmosVectorDocument
{
    public string id { get; set; } = null!;
    public string content { get; set; } = null!;
    public float[] embedding { get; set; } = null!;
    public Dictionary<string, object> metadata { get; set; } = new();
    public long _ts { get; set; }
    public string partitionKey => GetPartitionKey();
    
    private string GetPartitionKey()
    {
        return metadata.TryGetValue("Source", out var source) 
            ? source.ToString() ?? "default" 
            : "default";
    }
}

internal class CosmosVectorSearchResult
{
    public string id { get; set; } = null!;
    public string content { get; set; } = null!;
    public Dictionary<string, object> metadata { get; set; } = new();
    public double score { get; set; }
}
```

## 🤖 Step 4: Create AI Agents

### 4.1 Create Base Agent

Create `src/AI/Agents/Base/AgentBase.cs`:

```csharp
namespace AIEnterprise.AI.Agents.Base;

public abstract class AgentBase : IAgent
{
    protected readonly IKernel Kernel;
    protected readonly ILogger Logger;
    protected readonly ITelemetryService Telemetry;
    protected readonly AgentConfiguration Configuration;

    protected AgentBase(
        IKernel kernel,
        ILogger logger,
        ITelemetryService telemetry,
        AgentConfiguration configuration)
    {
        Kernel = kernel;
        Logger = logger;
        Telemetry = telemetry;
        Configuration = configuration;
    }

    public string Id => Configuration.Id;
    public string Name => Configuration.Name;
    public string Description => Configuration.Description;
    public List<string> Capabilities => Configuration.Capabilities;

    public virtual async Task<AgentResponse> ProcessAsync(
        AgentRequest request,
        CancellationToken cancellationToken = default)
    {
        using var activity = Telemetry.StartActivity($"Agent.{Name}.Process");
        
        try
        {
            // Pre-process request
            var context = await PrepareContextAsync(request, cancellationToken);
            
            // Execute agent logic
            var result = await ExecuteAsync(context, cancellationToken);
            
            // Post-process result
            var response = await PrepareResponseAsync(result, context, cancellationToken);
            
            Telemetry.TrackEvent("AgentProcessed", new Dictionary<string, string>
            {
                ["AgentId"] = Id,
                ["RequestType"] = request.Type,
                ["Success"] = "true"
            });
            
            return response;
        }
        catch (Exception ex)
        {
            Logger.LogError(ex,
                "Agent {AgentName} failed to process request {RequestId}",
                Name,
                request.Id);
                
            Telemetry.TrackException(ex, new Dictionary<string, string>
            {
                ["AgentId"] = Id,
                ["RequestId"] = request.Id
            });
            
            return new AgentResponse
            {
                Success = false,
                Error = ex.Message,
                AgentId = Id
            };
        }
    }

    protected abstract Task<AgentContext> PrepareContextAsync(
        AgentRequest request,
        CancellationToken cancellationToken);
        
    protected abstract Task<AgentResult> ExecuteAsync(
        AgentContext context,
        CancellationToken cancellationToken);
        
    protected abstract Task<AgentResponse> PrepareResponseAsync(
        AgentResult result,
        AgentContext context,
        CancellationToken cancellationToken);

    public virtual bool CanHandle(AgentRequest request)
    {
        return Configuration.SupportedRequestTypes.Contains(request.Type);
    }

    public virtual async Task<HealthCheckResult> CheckHealthAsync(
        CancellationToken cancellationToken = default)
    {
        try
        {
            // Test kernel connectivity
            var testPrompt = "Test";
            var result = await Kernel.InvokePromptAsync(testPrompt, cancellationToken: cancellationToken);
            
            return new HealthCheckResult
            {
                Healthy = true,
                AgentId = Id,
                Message = "Agent is operational"
            };
        }
        catch (Exception ex)
        {
            return new HealthCheckResult
            {
                Healthy = false,
                AgentId = Id,
                Message = $"Agent health check failed: {ex.Message}"
            };
        }
    }
}

public interface IAgent
{
    string Id { get; }
    string Name { get; }
    string Description { get; }
    List<string> Capabilities { get; }
    
    Task<AgentResponse> ProcessAsync(AgentRequest request, CancellationToken cancellationToken = default);
    bool CanHandle(AgentRequest request);
    Task<HealthCheckResult> CheckHealthAsync(CancellationToken cancellationToken = default);
}

public class AgentConfiguration
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = null!;
    public string Description { get; set; } = null!;
    public List<string> Capabilities { get; set; } = new();
    public List<string> SupportedRequestTypes { get; set; } = new();
    public Dictionary<string, object> Settings { get; set; } = new();
}

public class AgentRequest
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Type { get; set; } = null!;
    public string UserId { get; set; } = null!;
    public Dictionary<string, object> Parameters { get; set; } = new();
    public List<Attachment> Attachments { get; set; } = new();
    public AgentContext? Context { get; set; }
}

public class AgentResponse
{
    public bool Success { get; set; }
    public string? Error { get; set; }
    public string AgentId { get; set; } = null!;
    public object? Result { get; set; }
    public Dictionary<string, object> Metadata { get; set; } = new();
    public List<AgentAction> Actions { get; set; } = new();
}

public class AgentContext
{
    public string ConversationId { get; set; } = null!;
    public List<Message> History { get; set; } = new();
    public Dictionary<string, object> Variables { get; set; } = new();
    public UserProfile? User { get; set; }
}

public class AgentResult
{
    public object Data { get; set; } = null!;
    public List<AgentAction> SuggestedActions { get; set; } = new();
    public Dictionary<string, object> Insights { get; set; } = new();
}

public class AgentAction
{
    public string Type { get; set; } = null!;
    public string Description { get; set; } = null!;
    public Dictionary<string, object> Parameters { get; set; } = new();
    public double Confidence { get; set; }
}
```

### 4.2 Create Specialized Agents

Create `src/AI/Agents/Specialized/BusinessAnalystAgent.cs`:

```csharp
namespace AIEnterprise.AI.Agents.Specialized;

public class BusinessAnalystAgent : AgentBase
{
    private readonly IBusinessDataService _dataService;
    private readonly IAnalyticsService _analyticsService;
    private readonly IReportingService _reportingService;

    public BusinessAnalystAgent(
        IKernel kernel,
        ILogger<BusinessAnalystAgent> logger,
        ITelemetryService telemetry,
        AgentConfiguration configuration,
        IBusinessDataService dataService,
        IAnalyticsService analyticsService,
        IReportingService reportingService)
        : base(kernel, logger, telemetry, configuration)
    {
        _dataService = dataService;
        _analyticsService = analyticsService;
        _reportingService = reportingService;
    }

    protected override async Task<AgentContext> PrepareContextAsync(
        AgentRequest request,
        CancellationToken cancellationToken)
    {
        var context = request.Context ?? new AgentContext
        {
            ConversationId = Guid.NewGuid().ToString(),
            User = await GetUserProfileAsync(request.UserId, cancellationToken)
        };

        // Enrich context with business data
        if (request.Parameters.TryGetValue("timeRange", out var timeRange))
        {
            context.Variables["businessMetrics"] = await _dataService
                .GetMetricsAsync(timeRange.ToString(), cancellationToken);
        }

        return context;
    }

    protected override async Task<AgentResult> ExecuteAsync(
        AgentContext context,
        CancellationToken cancellationToken)
    {
        // Analyze the request using Semantic Kernel
        var analysisPrompt = $"""
        You are an expert business analyst AI assistant.
        Analyze the following business question and provide insights:
        
        User Question: {context.Variables["userQuestion"]}
        
        Available Business Metrics:
        {JsonSerializer.Serialize(context.Variables.GetValueOrDefault("businessMetrics", new {}))}
        
        Provide:
        1. Direct answer to the question
        2. Key insights from the data
        3. Recommendations for action
        4. Suggested follow-up analyses
        
        Format your response as structured JSON.
        """;

        var response = await Kernel.InvokePromptAsync<string>(
            analysisPrompt,
            cancellationToken: cancellationToken);

        var analysisResult = JsonSerializer.Deserialize<BusinessAnalysis>(response);

        // Perform additional analytics if needed
        if (analysisResult?.RequiresDeepAnalysis == true)
        {
            var deepAnalysis = await _analyticsService.PerformDeepAnalysisAsync(
                analysisResult.AnalysisType,
                context.Variables,
                cancellationToken);
                
            analysisResult.DeepAnalysisResults = deepAnalysis;
        }

        // Generate visualizations if applicable
        if (analysisResult?.VisualizationRequired == true)
        {
            var charts = await GenerateVisualizationsAsync(
                analysisResult,
                context,
                cancellationToken);
                
            analysisResult.Visualizations = charts;
        }

        return new AgentResult
        {
            Data = analysisResult!,
            SuggestedActions = GenerateSuggestedActions(analysisResult),
            Insights = ExtractKeyInsights(analysisResult)
        };
    }

    protected override async Task<AgentResponse> PrepareResponseAsync(
        AgentResult result,
        AgentContext context,
        CancellationToken cancellationToken)
    {
        var analysis = result.Data as BusinessAnalysis;
        
        // Generate report if requested
        string? reportUrl = null;
        if (context.Variables.ContainsKey("generateReport") && 
            (bool)context.Variables["generateReport"])
        {
            reportUrl = await _reportingService.GenerateReportAsync(
                analysis!,
                context.User?.Id ?? "anonymous",
                cancellationToken);
        }

        return new AgentResponse
        {
            Success = true,
            AgentId = Id,
            Result = new
            {
                Summary = analysis?.Summary,
                Insights = analysis?.KeyInsights,
                Recommendations = analysis?.Recommendations,
                Visualizations = analysis?.Visualizations,
                ReportUrl = reportUrl
            },
            Metadata = new Dictionary<string, object>
            {
                ["AnalysisDepth"] = analysis?.RequiresDeepAnalysis == true ? "Deep" : "Standard",
                ["DataPoints"] = analysis?.DataPointsAnalyzed ?? 0,
                ["ConfidenceScore"] = analysis?.ConfidenceScore ?? 0
            },
            Actions = result.SuggestedActions
        };
    }

    private List<AgentAction> GenerateSuggestedActions(BusinessAnalysis analysis)
    {
        var actions = new List<AgentAction>();

        if (analysis.Recommendations != null)
        {
            foreach (var recommendation in analysis.Recommendations)
            {
                actions.Add(new AgentAction
                {
                    Type = "BusinessAction",
                    Description = recommendation.Description,
                    Parameters = new Dictionary<string, object>
                    {
                        ["Priority"] = recommendation.Priority,
                        ["Impact"] = recommendation.EstimatedImpact,
                        ["Effort"] = recommendation.EstimatedEffort
                    },
                    Confidence = recommendation.Confidence
                });
            }
        }

        return actions;
    }

    private Dictionary<string, object> ExtractKeyInsights(BusinessAnalysis analysis)
    {
        return new Dictionary<string, object>
        {
            ["TrendDirection"] = analysis.TrendAnalysis?.Direction ?? "Stable",
            ["AnomaliesDetected"] = analysis.Anomalies?.Count ?? 0,
            ["TopFactors"] = analysis.KeyInsights?.Take(3).Select(i => i.Factor).ToList() ?? new List<string>(),
            ["RiskLevel"] = analysis.RiskAssessment?.Level ?? "Low"
        };
    }

    private async Task<List<Visualization>> GenerateVisualizationsAsync(
        BusinessAnalysis analysis,
        AgentContext context,
        CancellationToken cancellationToken)
    {
        var visualizations = new List<Visualization>();

        // Generate appropriate charts based on analysis type
        if (analysis.DataPointsAnalyzed > 0)
        {
            var chartData = PrepareChartData(analysis);
            
            foreach (var data in chartData)
            {
                var viz = await _analyticsService.GenerateVisualizationAsync(
                    data.Type,
                    data.Data,
                    data.Options,
                    cancellationToken);
                    
                visualizations.Add(viz);
            }
        }

        return visualizations;
    }
}

public class BusinessAnalysis
{
    public string Summary { get; set; } = null!;
    public List<KeyInsight> KeyInsights { get; set; } = new();
    public List<Recommendation> Recommendations { get; set; } = new();
    public bool RequiresDeepAnalysis { get; set; }
    public string? AnalysisType { get; set; }
    public object? DeepAnalysisResults { get; set; }
    public bool VisualizationRequired { get; set; }
    public List<Visualization>? Visualizations { get; set; }
    public int DataPointsAnalyzed { get; set; }
    public double ConfidenceScore { get; set; }
    public TrendAnalysis? TrendAnalysis { get; set; }
    public List<Anomaly>? Anomalies { get; set; }
    public RiskAssessment? RiskAssessment { get; set; }
}

public class KeyInsight
{
    public string Factor { get; set; } = null!;
    public string Description { get; set; } = null!;
    public double Impact { get; set; }
}

public class Recommendation
{
    public string Description { get; set; } = null!;
    public string Priority { get; set; } = null!;
    public double EstimatedImpact { get; set; }
    public double EstimatedEffort { get; set; }
    public double Confidence { get; set; }
}
```

### 4.3 Create Agent Orchestrator

Create `src/AI/Agents/Orchestration/AgentOrchestrator.cs`:

```csharp
namespace AIEnterprise.AI.Agents.Orchestration;

public class AgentOrchestrator : IAgentOrchestrator
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<AgentOrchestrator> _logger;
    private readonly ITelemetryService _telemetry;
    private readonly Dictionary<string, IAgent> _agents;
    private readonly IAgentRouter _router;

    public AgentOrchestrator(
        IServiceProvider serviceProvider,
        ILogger<AgentOrchestrator> logger,
        ITelemetryService telemetry,
        IAgentRouter router)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
        _telemetry = telemetry;
        _router = router;
        _agents = new Dictionary<string, IAgent>();
        
        InitializeAgents();
    }

    private void InitializeAgents()
    {
        // Load all registered agents
        var agentTypes = Assembly.GetExecutingAssembly()
            .GetTypes()
            .Where(t => t.IsClass && !t.IsAbstract && typeof(IAgent).IsAssignableFrom(t));

        foreach (var agentType in agentTypes)
        {
            try
            {
                var agent = (IAgent)_serviceProvider.GetRequiredService(agentType);
                _agents[agent.Id] = agent;
                
                _logger.LogInformation(
                    "Registered agent {AgentName} with ID {AgentId}",
                    agent.Name,
                    agent.Id);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "Failed to initialize agent {AgentType}",
                    agentType.Name);
            }
        }
    }

    public async Task<OrchestrationResult> ProcessRequestAsync(
        OrchestrationRequest request,
        CancellationToken cancellationToken = default)
    {
        using var activity = _telemetry.StartActivity("AgentOrchestrator.ProcessRequest");
        
        try
        {
            // Route request to appropriate agents
            var routing = await _router.RouteRequestAsync(request, _agents.Values.ToList(), cancellationToken);
            
            if (!routing.Agents.Any())
            {
                return new OrchestrationResult
                {
                    Success = false,
                    Error = "No suitable agents found for this request"
                };
            }

            // Execute based on orchestration pattern
            var results = routing.Pattern switch
            {
                OrchestrationPattern.Sequential => await ExecuteSequentialAsync(
                    routing.Agents, request, cancellationToken),
                    
                OrchestrationPattern.Parallel => await ExecuteParallelAsync(
                    routing.Agents, request, cancellationToken),
                    
                OrchestrationPattern.Pipeline => await ExecutePipelineAsync(
                    routing.Agents, request, cancellationToken),
                    
                OrchestrationPattern.Voting => await ExecuteVotingAsync(
                    routing.Agents, request, cancellationToken),
                    
                _ => throw new NotSupportedException($"Pattern {routing.Pattern} not supported")
            };

            // Aggregate results
            var finalResult = await AggregateResultsAsync(results, routing.Pattern, cancellationToken);
            
            _telemetry.TrackEvent("OrchestrationCompleted", new Dictionary<string, string>
            {
                ["Pattern"] = routing.Pattern.ToString(),
                ["AgentCount"] = routing.Agents.Count.ToString(),
                ["Success"] = finalResult.Success.ToString()
            });
            
            return finalResult;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Orchestration failed for request {RequestId}",
                request.Id);
                
            return new OrchestrationResult
            {
                Success = false,
                Error = ex.Message
            };
        }
    }

    private async Task<List<AgentResponse>> ExecuteSequentialAsync(
        List<IAgent> agents,
        OrchestrationRequest request,
        CancellationToken cancellationToken)
    {
        var results = new List<AgentResponse>();
        AgentContext? currentContext = null;

        foreach (var agent in agents)
        {
            var agentRequest = new AgentRequest
            {
                Type = request.Type,
                UserId = request.UserId,
                Parameters = request.Parameters,
                Context = currentContext
            };

            var response = await agent.ProcessAsync(agentRequest, cancellationToken);
            results.Add(response);

            if (!response.Success)
            {
                break; // Stop on first failure in sequential mode
            }

            // Update context for next agent
            currentContext = UpdateContext(currentContext, response);
        }

        return results;
    }

    private async Task<List<AgentResponse>> ExecuteParallelAsync(
        List<IAgent> agents,
        OrchestrationRequest request,
        CancellationToken cancellationToken)
    {
        var tasks = agents.Select(agent =>
        {
            var agentRequest = new AgentRequest
            {
                Type = request.Type,
                UserId = request.UserId,
                Parameters = request.Parameters,
                Context = request.InitialContext
            };
            
            return agent.ProcessAsync(agentRequest, cancellationToken);
        });

        var results = await Task.WhenAll(tasks);
        return results.ToList();
    }

    private async Task<List<AgentResponse>> ExecutePipelineAsync(
        List<IAgent> agents,
        OrchestrationRequest request,
        CancellationToken cancellationToken)
    {
        var results = new List<AgentResponse>();
        object? pipelineData = request.Parameters;

        foreach (var agent in agents)
        {
            var agentRequest = new AgentRequest
            {
                Type = request.Type,
                UserId = request.UserId,
                Parameters = new Dictionary<string, object>
                {
                    ["pipelineData"] = pipelineData ?? new { }
                },
                Context = request.InitialContext
            };

            var response = await agent.ProcessAsync(agentRequest, cancellationToken);
            results.Add(response);

            if (!response.Success)
            {
                break; // Stop pipeline on failure
            }

            // Pass result to next stage
            pipelineData = response.Result;
        }

        return results;
    }

    private async Task<List<AgentResponse>> ExecuteVotingAsync(
        List<IAgent> agents,
        OrchestrationRequest request,
        CancellationToken cancellationToken)
    {
        // Execute all agents in parallel
        var responses = await ExecuteParallelAsync(agents, request, cancellationToken);
        
        // Apply voting logic
        var votingResult = ApplyVotingLogic(responses);
        
        // Add voting metadata
        foreach (var response in responses)
        {
            response.Metadata["VotingResult"] = votingResult;
        }

        return responses;
    }

    private async Task<OrchestrationResult> AggregateResultsAsync(
        List<AgentResponse> responses,
        OrchestrationPattern pattern,
        CancellationToken cancellationToken)
    {
        var aggregator = new ResultAggregator(_logger);
        
        var aggregatedResult = pattern switch
        {
            OrchestrationPattern.Sequential => aggregator.AggregateSequential(responses),
            OrchestrationPattern.Parallel => aggregator.AggregateParallel(responses),
            OrchestrationPattern.Pipeline => aggregator.AggregatePipeline(responses),
            OrchestrationPattern.Voting => aggregator.AggregateVoting(responses),
            _ => throw new NotSupportedException()
        };

        return new OrchestrationResult
        {
            Success = aggregatedResult.Success,
            Result = aggregatedResult.Data,
            AgentResponses = responses,
            Metadata = new Dictionary<string, object>
            {
                ["TotalAgents"] = responses.Count,
                ["SuccessfulAgents"] = responses.Count(r => r.Success),
                ["Pattern"] = pattern.ToString(),
                ["AggregationMethod"] = aggregatedResult.Method
            }
        };
    }

    private AgentContext UpdateContext(AgentContext? current, AgentResponse response)
    {
        var context = current ?? new AgentContext
        {
            ConversationId = Guid.NewGuid().ToString()
        };

        // Add response to history
        context.History.Add(new Message
        {
            Role = "agent",
            Content = JsonSerializer.Serialize(response.Result),
            Timestamp = DateTime.UtcNow,
            Metadata = response.Metadata
        });

        // Merge any new variables
        if (response.Metadata.TryGetValue("ContextVariables", out var variables) && 
            variables is Dictionary<string, object> vars)
        {
            foreach (var kvp in vars)
            {
                context.Variables[kvp.Key] = kvp.Value;
            }
        }

        return context;
    }

    public async Task<List<AgentHealth>> CheckHealthAsync(CancellationToken cancellationToken = default)
    {
        var healthChecks = await Task.WhenAll(
            _agents.Values.Select(agent => CheckAgentHealthAsync(agent, cancellationToken)));
            
        return healthChecks.ToList();
    }

    private async Task<AgentHealth> CheckAgentHealthAsync(IAgent agent, CancellationToken cancellationToken)
    {
        try
        {
            var result = await agent.CheckHealthAsync(cancellationToken);
            
            return new AgentHealth
            {
                AgentId = agent.Id,
                AgentName = agent.Name,
                Status = result.Healthy ? HealthStatus.Healthy : HealthStatus.Unhealthy,
                Message = result.Message,
                LastChecked = DateTime.UtcNow
            };
        }
        catch (Exception ex)
        {
            return new AgentHealth
            {
                AgentId = agent.Id,
                AgentName = agent.Name,
                Status = HealthStatus.Unhealthy,
                Message = ex.Message,
                LastChecked = DateTime.UtcNow
            };
        }
    }
}

public interface IAgentOrchestrator
{
    Task<OrchestrationResult> ProcessRequestAsync(
        OrchestrationRequest request,
        CancellationToken cancellationToken = default);
        
    Task<List<AgentHealth>> CheckHealthAsync(
        CancellationToken cancellationToken = default);
}

public class OrchestrationRequest
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Type { get; set; } = null!;
    public string UserId { get; set; } = null!;
    public Dictionary<string, object> Parameters { get; set; } = new();
    public AgentContext? InitialContext { get; set; }
    public OrchestrationPattern PreferredPattern { get; set; } = OrchestrationPattern.Auto;
}

public class OrchestrationResult
{
    public bool Success { get; set; }
    public string? Error { get; set; }
    public object? Result { get; set; }
    public List<AgentResponse> AgentResponses { get; set; } = new();
    public Dictionary<string, object> Metadata { get; set; } = new();
}

public enum OrchestrationPattern
{
    Auto,
    Sequential,
    Parallel,
    Pipeline,
    Voting
}
```

## 📊 Step 5: Set Up AI Monitoring

### 5.1 Create Telemetry Service

Create `src/Infrastructure/Monitoring/AITelemetryService.cs`:

```csharp
namespace AIEnterprise.Infrastructure.Monitoring;

public class AITelemetryService : ITelemetryService
{
    private readonly TelemetryClient _telemetryClient;
    private readonly ILogger<AITelemetryService> _logger;
    private readonly ActivitySource _activitySource;
    private readonly IMeterFactory _meterFactory;
    private readonly Meter _meter;

    // Metrics
    private readonly Counter<long> _aiRequestCounter;
    private readonly Histogram<double> _aiRequestDuration;
    private readonly Counter<long> _tokenUsageCounter;
    private readonly ObservableGauge<double> _activeAgentsGauge;

    public AITelemetryService(
        TelemetryClient telemetryClient,
        ILogger<AITelemetryService> logger,
        IMeterFactory meterFactory)
    {
        _telemetryClient = telemetryClient;
        _logger = logger;
        _activitySource = new ActivitySource("AIEnterprise.AI");
        _meterFactory = meterFactory;
        
        // Create meter
        _meter = _meterFactory.Create("AIEnterprise.AI.Metrics");
        
        // Initialize metrics
        _aiRequestCounter = _meter.CreateCounter<long>(
            "ai.requests.total",
            description: "Total number of AI requests");
            
        _aiRequestDuration = _meter.CreateHistogram<double>(
            "ai.request.duration",
            unit: "ms",
            description: "AI request duration");
            
        _tokenUsageCounter = _meter.CreateCounter<long>(
            "ai.tokens.used",
            description: "Total tokens consumed");
            
        _activeAgentsGauge = _meter.CreateObservableGauge(
            "ai.agents.active",
            () => GetActiveAgentCount(),
            description: "Number of active AI agents");
    }

    public Activity? StartActivity(string name, ActivityKind kind = ActivityKind.Internal)
    {
        var activity = _activitySource.StartActivity(name, kind);
        
        if (activity != null)
        {
            activity.SetTag("service.name", "AIEnterprise");
            activity.SetTag("service.version", GetType().Assembly.GetName().Version?.ToString());
        }
        
        return activity;
    }

    public void TrackAIRequest(
        string operationType,
        string model,
        double duration,
        bool success,
        Dictionary<string, object>? properties = null)
    {
        var tags = new TagList
        {
            { "operation", operationType },
            { "model", model },
            { "success", success }
        };

        _aiRequestCounter.Add(1, tags);
        _aiRequestDuration.Record(duration, tags);

        var telemetryProperties = new Dictionary<string, string>
        {
            ["OperationType"] = operationType,
            ["Model"] = model,
            ["Success"] = success.ToString(),
            ["Duration"] = duration.ToString("F2")
        };

        if (properties != null)
        {
            foreach (var prop in properties)
            {
                telemetryProperties[prop.Key] = prop.Value?.ToString() ?? "";
            }
        }

        _telemetryClient.TrackEvent("AIRequest", telemetryProperties);
    }

    public void TrackTokenUsage(
        string model,
        int promptTokens,
        int completionTokens,
        string operation)
    {
        var totalTokens = promptTokens + completionTokens;
        
        var tags = new TagList
        {
            { "model", model },
            { "operation", operation },
            { "token_type", "prompt" }
        };
        
        _tokenUsageCounter.Add(promptTokens, tags);
        
        tags["token_type"] = "completion";
        _tokenUsageCounter.Add(completionTokens, tags);

        _telemetryClient.TrackMetric("TokenUsage", totalTokens, new Dictionary<string, string>
        {
            ["Model"] = model,
            ["Operation"] = operation,
            ["PromptTokens"] = promptTokens.ToString(),
            ["CompletionTokens"] = completionTokens.ToString()
        });

        // Track cost estimation
        var estimatedCost = CalculateTokenCost(model, promptTokens, completionTokens);
        
        _telemetryClient.TrackMetric("EstimatedCost", estimatedCost, new Dictionary<string, string>
        {
            ["Model"] = model,
            ["Operation"] = operation
        });
    }

    public void TrackEmbeddingOperation(
        string operation,
        int vectorCount,
        int dimensionality,
        double duration)
    {
        _telemetryClient.TrackEvent("EmbeddingOperation", new Dictionary<string, string>
        {
            ["Operation"] = operation,
            ["VectorCount"] = vectorCount.ToString(),
            ["Dimensionality"] = dimensionality.ToString(),
            ["Duration"] = duration.ToString("F2")
        });

        _telemetryClient.TrackMetric("EmbeddingVectorsProcessed", vectorCount);
    }

    public void TrackRAGOperation(
        string operation,
        int documentsRetrieved,
        double averageRelevanceScore,
        double duration)
    {
        _telemetryClient.TrackEvent("RAGOperation", new Dictionary<string, string>
        {
            ["Operation"] = operation,
            ["DocumentsRetrieved"] = documentsRetrieved.ToString(),
            ["AverageRelevanceScore"] = averageRelevanceScore.ToString("F3"),
            ["Duration"] = duration.ToString("F2")
        });
    }

    public void TrackAgentExecution(
        string agentId,
        string agentName,
        string requestType,
        double duration,
        bool success,
        Dictionary<string, object>? metadata = null)
    {
        var properties = new Dictionary<string, string>
        {
            ["AgentId"] = agentId,
            ["AgentName"] = agentName,
            ["RequestType"] = requestType,
            ["Duration"] = duration.ToString("F2"),
            ["Success"] = success.ToString()
        };

        if (metadata != null)
        {
            foreach (var item in metadata)
            {
                properties[$"Agent.{item.Key}"] = item.Value?.ToString() ?? "";
            }
        }

        _telemetryClient.TrackEvent("AgentExecution", properties);
        
        if (!success)
        {
            _telemetryClient.TrackMetric("AgentFailures", 1, new Dictionary<string, string>
            {
                ["AgentName"] = agentName
            });
        }
    }

    public void TrackException(Exception exception, Dictionary<string, string>? properties = null)
    {
        _telemetryClient.TrackException(exception, properties);
        
        _logger.LogError(exception,
            "Exception tracked: {ExceptionType}",
            exception.GetType().Name);
    }

    public void TrackEvent(string eventName, Dictionary<string, string>? properties = null)
    {
        _telemetryClient.TrackEvent(eventName, properties);
    }

    public void TrackMetric(string name, double value, Dictionary<string, string>? properties = null)
    {
        _telemetryClient.TrackMetric(name, value, properties);
    }

    private double CalculateTokenCost(string model, int promptTokens, int completionTokens)
    {
        // Pricing per 1K tokens (example rates)
        var pricing = model switch
        {
            "gpt-4" => (prompt: 0.03, completion: 0.06),
            "gpt-3.5-turbo" => (prompt: 0.0015, completion: 0.002),
            _ => (prompt: 0.01, completion: 0.02)
        };

        var promptCost = (promptTokens / 1000.0) * pricing.prompt;
        var completionCost = (completionTokens / 1000.0) * pricing.completion;
        
        return promptCost + completionCost;
    }

    private double GetActiveAgentCount()
    {
        // This would be implemented to track actual active agent count
        // For now, return a placeholder
        return 5.0;
    }
}
```

## 💡 Copilot Prompt Suggestions

**For Vector Search Implementation:**
```
Create a hybrid search implementation that:
- Combines vector similarity with keyword search
- Implements BM25 scoring for text relevance
- Uses RRF (Reciprocal Rank Fusion) for result merging
- Supports filtering by metadata
- Includes query expansion with synonyms
Show the complete implementation with Azure Cognitive Search
```

**For Agent Communication:**
```
Implement an agent communication protocol that:
- Supports direct agent-to-agent messaging
- Implements publish-subscribe patterns
- Handles request-response with timeouts
- Includes message prioritization
- Supports broadcast messages
Use Redis pub/sub for the implementation
```

**For AI Cost Optimization:**
```
Create a cost optimization service that:
- Tracks token usage per user/department
- Implements caching for repeated queries
- Uses smaller models when appropriate
- Batches embedding operations
- Sets budget alerts and limits
Include cost projection and reporting
```

## ✅ Part 1 Checklist

Before moving to Part 2, ensure you have:

- [ ] Set up Semantic Kernel configuration
- [ ] Implemented vector database with Cosmos DB
- [ ] Created RAG pipeline with document processing
- [ ] Built base agent architecture
- [ ] Implemented specialized agents
- [ ] Created agent orchestrator
- [ ] Set up AI telemetry and monitoring
- [ ] Configured cost tracking
- [ ] Tested vector search functionality

## 🎯 Part 1 Summary

You've successfully:
- Established a robust AI foundation with Semantic Kernel
- Implemented enterprise-grade vector search
- Created a scalable RAG pipeline
- Built a flexible multi-agent system
- Set up comprehensive monitoring

## ⏭️ Next Steps

Continue to [Part 2: Core Implementation](part2-implementation.md) where you'll:
- Build the business domain services
- Create conversational interfaces
- Implement predictive analytics
- Add real-time processing
- Create the user interface

---

**🏆 Achievement**: You've built the AI foundation for an enterprise system! This architecture can handle complex AI workloads while maintaining performance, scalability, and cost efficiency.