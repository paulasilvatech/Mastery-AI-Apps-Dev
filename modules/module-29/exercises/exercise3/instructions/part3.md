# Exercise 3: AI-Powered Enterprise System - Part 3: UI and Integration

## 🎯 Overview

This part continues the implementation of the user interface components, completes the Blazor application, and covers the final integration steps to bring all components together into a cohesive AI-powered enterprise system.

## 📋 Part 3 Objectives

- Complete the Blazor UI components
- Implement real-time dashboards
- Create interactive visualizations
- Set up API endpoints
- Configure dependency injection
- Deploy and test the complete system

## 🖥️ Step 5: Build User Interface with Blazor (Continued)

### 5.2 Create AI Conversation Component (Continued)

Continue with `src/WebApp/Components/AIConversation.razor`:

```razor
                        @if (message.Actions?.Any() == true)
                        {
                            <div class="message-actions">
                                @foreach (var action in message.Actions)
                                {
                                    <button class="action-btn" @onclick="() => HandleAction(action)">
                                        @action.Label
                                    </button>
                                }
                            </div>
                        }
                        @if (message.Visualizations?.Any() == true)
                        {
                            <div class="message-visualizations">
                                @foreach (var viz in message.Visualizations)
                                {
                                    <DynamicVisualization Data="viz" />
                                }
                            </div>
                        }
                    }
                    <div class="message-time">@message.Timestamp.ToString("HH:mm")</div>
                </div>
            </div>
        }
    </div>
    
    <div class="input-container">
        <div class="input-wrapper">
            <input type="text" @bind="_inputMessage" @bind:event="oninput"
                   @onkeypress="@(async (e) => { if (e.Key == "Enter") await SendMessage(); })"
                   placeholder="Ask me anything..."
                   disabled="@(_isProcessing || _isListening)" />
            @if (_isListening)
            {
                <div class="voice-indicator">
                    <span class="pulse"></span>
                    Listening...
                </div>
            }
            <button class="send-btn" @onclick="SendMessage" 
                    disabled="@(_isProcessing || string.IsNullOrWhiteSpace(_inputMessage))">
                @if (_isProcessing)
                {
                    <i class="fas fa-spinner fa-spin"></i>
                }
                else
                {
                    <i class="fas fa-paper-plane"></i>
                }
            </button>
        </div>
        @if (_suggestions?.Any() == true)
        {
            <div class="suggestions">
                @foreach (var suggestion in _suggestions)
                {
                    <button class="suggestion-chip" @onclick="() => UseSuggestion(suggestion)">
                        @suggestion
                    </button>
                }
            </div>
        }
    </div>
</div>

@code {
    [Parameter] public EventCallback<ConversationMessage> OnMessageSent { get; set; }
    [Parameter] public bool VoiceEnabled { get; set; }

    private ElementReference _messagesContainer;
    private List<ChatMessage> _messages = new();
    private string _inputMessage = "";
    private bool _isProcessing = false;
    private bool _isListening = false;
    private List<string> _suggestions = new();
    private string _conversationId = Guid.NewGuid().ToString();
    
    protected override async Task OnInitializedAsync()
    {
        // Add welcome message
        _messages.Add(new ChatMessage
        {
            IsUser = false,
            Content = "Hello! I'm your AI assistant. How can I help you today?",
            Timestamp = DateTime.Now
        });
        
        // Load suggestions
        _suggestions = new List<string>
        {
            "Show me today's performance metrics",
            "Analyze customer churn risk",
            "Generate sales forecast",
            "Find optimization opportunities"
        };
    }

    private async Task SendMessage()
    {
        if (string.IsNullOrWhiteSpace(_inputMessage) || _isProcessing)
            return;

        var userMessage = _inputMessage;
        _inputMessage = "";
        _suggestions.Clear();
        
        // Add user message
        _messages.Add(new ChatMessage
        {
            IsUser = true,
            Content = userMessage,
            Timestamp = DateTime.Now
        });
        
        // Add typing indicator
        var typingMessage = new ChatMessage
        {
            IsUser = false,
            IsTyping = true,
            Timestamp = DateTime.Now
        };
        _messages.Add(typingMessage);
        
        _isProcessing = true;
        StateHasChanged();
        await ScrollToBottom();

        try
        {
            // Send to conversational service
            var response = await ConversationalService.ProcessMessageAsync(new ConversationMessage
            {
                ConversationId = _conversationId,
                UserId = "current-user", // Get from auth context
                Content = userMessage,
                Metadata = new Dictionary<string, object>
                {
                    ["source"] = "web-ui",
                    ["timestamp"] = DateTime.UtcNow
                }
            });

            // Remove typing indicator
            _messages.Remove(typingMessage);
            
            // Add assistant response
            _messages.Add(new ChatMessage
            {
                IsUser = false,
                Content = response.Text,
                FormattedContent = FormatResponse(response.Text),
                Actions = response.Actions,
                Visualizations = response.Visualizations,
                Timestamp = DateTime.Now
            });
            
            // Update suggestions based on context
            if (response.Suggestions?.Any() == true)
            {
                _suggestions = response.Suggestions.Take(4).ToList();
            }
            
            // Invoke callback
            await OnMessageSent.InvokeAsync(new ConversationMessage
            {
                ConversationId = _conversationId,
                Content = userMessage
            });
        }
        catch (Exception ex)
        {
            _messages.Remove(typingMessage);
            _messages.Add(new ChatMessage
            {
                IsUser = false,
                Content = "I apologize, but I encountered an error. Please try again.",
                Timestamp = DateTime.Now
            });
        }
        finally
        {
            _isProcessing = false;
            StateHasChanged();
            await ScrollToBottom();
        }
    }

    private async Task ToggleVoiceInput()
    {
        if (_isListening)
        {
            await StopListening();
        }
        else
        {
            await StartListening();
        }
    }

    private async Task StartListening()
    {
        _isListening = true;
        StateHasChanged();
        
        try
        {
            // Start voice recognition through JS interop
            await JS.InvokeVoidAsync("startVoiceRecognition", DotNetObjectReference.Create(this));
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"Failed to start voice recognition: {ex.Message}");
            _isListening = false;
            StateHasChanged();
        }
    }

    private async Task StopListening()
    {
        _isListening = false;
        StateHasChanged();
        
        try
        {
            await JS.InvokeVoidAsync("stopVoiceRecognition");
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"Failed to stop voice recognition: {ex.Message}");
        }
    }

    [JSInvokable]
    public async Task OnVoiceResult(string transcript)
    {
        _inputMessage = transcript;
        _isListening = false;
        StateHasChanged();
        
        if (!string.IsNullOrWhiteSpace(transcript))
        {
            await SendMessage();
        }
    }

    private void UseSuggestion(string suggestion)
    {
        _inputMessage = suggestion;
        StateHasChanged();
    }

    private async Task HandleAction(ConversationAction action)
    {
        // Handle different action types
        switch (action.Type)
        {
            case "navigate":
                Navigation.NavigateTo(action.Parameters["url"].ToString());
                break;
                
            case "execute":
                await ExecuteAction(action);
                break;
                
            case "showDetails":
                await ShowDetails(action);
                break;
        }
    }

    private string FormatResponse(string text)
    {
        // Convert markdown to HTML
        // Add syntax highlighting for code blocks
        // Format tables and lists
        return Markdown.ToHtml(text, new MarkdownPipelineBuilder()
            .UseAdvancedExtensions()
            .Build());
    }

    private async Task ScrollToBottom()
    {
        await JS.InvokeVoidAsync("scrollToBottom", _messagesContainer);
    }

    public async Task SendMessageAsync(string message)
    {
        _inputMessage = message;
        await SendMessage();
    }

    public async Task ShowSystemMessageAsync(string message)
    {
        _messages.Add(new ChatMessage
        {
            IsUser = false,
            Content = message,
            IsSystem = true,
            Timestamp = DateTime.Now
        });
        StateHasChanged();
        await ScrollToBottom();
    }

    private void ClearConversation()
    {
        _messages.Clear();
        _conversationId = Guid.NewGuid().ToString();
        _messages.Add(new ChatMessage
        {
            IsUser = false,
            Content = "Conversation cleared. How can I help you?",
            Timestamp = DateTime.Now
        });
        StateHasChanged();
    }

    private class ChatMessage
    {
        public bool IsUser { get; set; }
        public string Content { get; set; } = "";
        public string? FormattedContent { get; set; }
        public bool IsTyping { get; set; }
        public bool IsSystem { get; set; }
        public DateTime Timestamp { get; set; }
        public List<ConversationAction>? Actions { get; set; }
        public List<Visualization>? Visualizations { get; set; }
    }
}

<style>
    .conversation-container {
        display: flex;
        flex-direction: column;
        height: 600px;
        background: var(--surface-color);
        border-radius: 1rem;
        overflow: hidden;
    }

    .conversation-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 1rem 1.5rem;
        border-bottom: 1px solid var(--border-color);
        background: var(--header-gradient);
    }

    .conversation-header h3 {
        margin: 0;
        color: var(--text-primary);
    }

    .conversation-actions {
        display: flex;
        gap: 0.5rem;
    }

    .voice-btn, .clear-btn {
        background: transparent;
        border: none;
        color: var(--text-secondary);
        cursor: pointer;
        padding: 0.5rem;
        border-radius: 0.5rem;
        transition: all 0.2s;
    }

    .voice-btn:hover, .clear-btn:hover {
        background: var(--hover-color);
        color: var(--text-primary);
    }

    .voice-btn.listening {
        color: var(--error-color);
        animation: pulse 1.5s infinite;
    }

    .messages-container {
        flex: 1;
        overflow-y: auto;
        padding: 1rem;
        scroll-behavior: smooth;
    }

    .message {
        display: flex;
        gap: 1rem;
        margin-bottom: 1rem;
        animation: fadeIn 0.3s ease-out;
    }

    .message.user {
        flex-direction: row-reverse;
    }

    .message-avatar {
        width: 2rem;
        height: 2rem;
        border-radius: 50%;
        background: var(--primary-gradient);
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        font-size: 0.875rem;
        flex-shrink: 0;
    }

    .message.user .message-avatar {
        background: var(--secondary-gradient);
    }

    .message-content {
        max-width: 70%;
    }

    .message-text {
        background: var(--message-bg);
        padding: 0.75rem 1rem;
        border-radius: 1rem;
        color: var(--text-primary);
    }

    .message.user .message-text {
        background: var(--primary-color);
        color: white;
    }

    .message-actions {
        display: flex;
        gap: 0.5rem;
        margin-top: 0.5rem;
    }

    .action-btn {
        background: transparent;
        border: 1px solid var(--primary-color);
        color: var(--primary-color);
        padding: 0.25rem 0.75rem;
        border-radius: 1rem;
        font-size: 0.875rem;
        cursor: pointer;
        transition: all 0.2s;
    }

    .action-btn:hover {
        background: var(--primary-color);
        color: white;
    }

    .message-time {
        font-size: 0.75rem;
        color: var(--text-secondary);
        margin-top: 0.25rem;
    }

    .typing-indicator {
        display: flex;
        gap: 0.25rem;
        padding: 1rem;
    }

    .typing-indicator span {
        width: 0.5rem;
        height: 0.5rem;
        background: var(--text-secondary);
        border-radius: 50%;
        animation: typing 1.4s infinite;
    }

    .typing-indicator span:nth-child(2) {
        animation-delay: 0.2s;
    }

    .typing-indicator span:nth-child(3) {
        animation-delay: 0.4s;
    }

    .input-container {
        padding: 1rem;
        border-top: 1px solid var(--border-color);
        background: var(--input-bg);
    }

    .input-wrapper {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        background: white;
        border: 1px solid var(--border-color);
        border-radius: 2rem;
        padding: 0.5rem 1rem;
        transition: all 0.2s;
    }

    .input-wrapper:focus-within {
        border-color: var(--primary-color);
        box-shadow: 0 0 0 3px var(--primary-color-alpha);
    }

    .input-wrapper input {
        flex: 1;
        border: none;
        outline: none;
        font-size: 1rem;
        color: var(--text-primary);
    }

    .voice-indicator {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        color: var(--error-color);
        font-size: 0.875rem;
    }

    .pulse {
        width: 0.5rem;
        height: 0.5rem;
        background: var(--error-color);
        border-radius: 50%;
        animation: pulse 1s infinite;
    }

    .send-btn {
        background: var(--primary-gradient);
        border: none;
        color: white;
        width: 2.5rem;
        height: 2.5rem;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        transition: all 0.2s;
        flex-shrink: 0;
    }

    .send-btn:hover:not(:disabled) {
        transform: scale(1.1);
    }

    .send-btn:disabled {
        opacity: 0.5;
        cursor: not-allowed;
    }

    .suggestions {
        display: flex;
        gap: 0.5rem;
        margin-top: 0.5rem;
        flex-wrap: wrap;
    }

    .suggestion-chip {
        background: var(--chip-bg);
        border: 1px solid var(--border-color);
        color: var(--text-primary);
        padding: 0.5rem 1rem;
        border-radius: 2rem;
        font-size: 0.875rem;
        cursor: pointer;
        transition: all 0.2s;
        white-space: nowrap;
    }

    .suggestion-chip:hover {
        background: var(--primary-color);
        color: white;
        border-color: var(--primary-color);
    }

    @keyframes fadeIn {
        from {
            opacity: 0;
            transform: translateY(10px);
        }
        to {
            opacity: 1;
            transform: translateY(0);
        }
    }

    @keyframes typing {
        0%, 60%, 100% {
            opacity: 0.3;
            transform: translateY(0);
        }
        30% {
            opacity: 1;
            transform: translateY(-10px);
        }
    }

    @keyframes pulse {
        0% {
            opacity: 1;
            transform: scale(1);
        }
        50% {
            opacity: 0.5;
            transform: scale(1.5);
        }
        100% {
            opacity: 1;
            transform: scale(1);
        }
    }
</style>

### 5.3 Create Real-Time Analytics Component

Create `src/WebApp/Components/RealtimeAnalytics.razor`:

```razor
@using AIEnterprise.WebApp.Services
@using System.Timers
@inject IStreamAnalyticsService StreamAnalyticsService
@inject IJSRuntime JS
@implements IAsyncDisposable

<div class="analytics-container">
    <div class="analytics-header">
        <h3>@Title</h3>
        <div class="stream-status">
            <span class="status-indicator @(_isConnected ? "connected" : "disconnected")"></span>
            <span>@(_isConnected ? "Live" : "Offline")</span>
        </div>
    </div>
    
    <div class="metrics-row">
        @foreach (var metric in _currentMetrics)
        {
            <div class="metric-box">
                <div class="metric-value">@metric.Value.ToString("N0")</div>
                <div class="metric-label">@metric.Label</div>
                <div class="metric-change @(metric.Change >= 0 ? "positive" : "negative")">
                    <i class="fas fa-arrow-@(metric.Change >= 0 ? "up" : "down")"></i>
                    @Math.Abs(metric.Change).ToString("P0")
                </div>
            </div>
        }
    </div>
    
    <div class="chart-container">
        <canvas @ref="_chartCanvas"></canvas>
    </div>
    
    @if (ShowAnomalies && _anomalies?.Any() == true)
    {
        <div class="anomalies-section">
            <h4>Detected Anomalies</h4>
            <div class="anomaly-list">
                @foreach (var anomaly in _anomalies.Take(5))
                {
                    <div class="anomaly-item @anomaly.Severity.ToLower()">
                        <div class="anomaly-time">@anomaly.Timestamp.ToString("HH:mm:ss")</div>
                        <div class="anomaly-description">@anomaly.Description</div>
                        <div class="anomaly-impact">Impact: @anomaly.Impact</div>
                    </div>
                }
            </div>
        </div>
    }
</div>

@code {
    [Parameter] public string StreamId { get; set; } = "default-stream";
    [Parameter] public int RefreshInterval { get; set; } = 1000;
    [Parameter] public bool ShowAnomalies { get; set; } = true;
    [Parameter] public string Title { get; set; } = "Real-Time Analytics";

    private ElementReference _chartCanvas;
    private IJSObjectReference? _chart;
    private Timer? _refreshTimer;
    private bool _isConnected = false;
    private List<Metric> _currentMetrics = new();
    private List<Anomaly> _anomalies = new();
    private Queue<DataPoint> _dataPoints = new();
    private const int MaxDataPoints = 100;

    protected override async Task OnAfterRenderAsync(bool firstRender)
    {
        if (firstRender)
        {
            await InitializeChart();
            await StartStreaming();
        }
    }

    private async Task InitializeChart()
    {
        var chartModule = await JS.InvokeAsync<IJSObjectReference>("import", "./js/charts.js");
        
        _chart = await chartModule.InvokeAsync<IJSObjectReference>("createRealtimeChart", _chartCanvas, new
        {
            type = "line",
            options = new
            {
                responsive = true,
                maintainAspectRatio = false,
                animation = new { duration = 0 },
                scales = new
                {
                    x = new
                    {
                        type = "time",
                        time = new { unit = "second" },
                        ticks = new { source = "auto", autoSkip = true }
                    },
                    y = new
                    {
                        beginAtZero = true,
                        ticks = new { precision = 0 }
                    }
                },
                plugins = new
                {
                    legend = new { display = false },
                    tooltip = new { mode = "index", intersect = false }
                }
            }
        });
    }

    private async Task StartStreaming()
    {
        try
        {
            _isConnected = await StreamAnalyticsService.ConnectAsync(StreamId);
            
            if (_isConnected)
            {
                // Set up data subscription
                StreamAnalyticsService.OnDataReceived += HandleDataReceived;
                StreamAnalyticsService.OnAnomalyDetected += HandleAnomalyDetected;
                
                // Start refresh timer
                _refreshTimer = new Timer(RefreshInterval);
                _refreshTimer.Elapsed += async (s, e) => await UpdateDisplay();
                _refreshTimer.Start();
            }
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"Failed to connect to stream: {ex.Message}");
            _isConnected = false;
        }
        
        StateHasChanged();
    }

    private void HandleDataReceived(StreamData data)
    {
        // Add to data points queue
        _dataPoints.Enqueue(new DataPoint
        {
            Timestamp = data.Timestamp,
            Value = data.Value,
            Metadata = data.Metadata
        });
        
        // Maintain queue size
        while (_dataPoints.Count > MaxDataPoints)
        {
            _dataPoints.Dequeue();
        }
        
        // Update metrics
        UpdateMetrics(data);
    }

    private void HandleAnomalyDetected(Anomaly anomaly)
    {
        _anomalies.Insert(0, anomaly);
        
        // Keep only recent anomalies
        if (_anomalies.Count > 10)
        {
            _anomalies.RemoveAt(_anomalies.Count - 1);
        }
        
        InvokeAsync(StateHasChanged);
    }

    private void UpdateMetrics(StreamData data)
    {
        // Calculate real-time metrics
        var values = _dataPoints.Select(p => p.Value).ToList();
        
        if (values.Any())
        {
            _currentMetrics = new List<Metric>
            {
                new Metric
                {
                    Label = "Current",
                    Value = data.Value,
                    Change = CalculateChange(data.Value, values.TakeLast(10).Average())
                },
                new Metric
                {
                    Label = "Average",
                    Value = values.Average(),
                    Change = CalculateChange(values.Average(), values.TakeLast(20).Average())
                },
                new Metric
                {
                    Label = "Peak",
                    Value = values.Max(),
                    Change = 0
                },
                new Metric
                {
                    Label = "Volume",
                    Value = values.Count,
                    Change = CalculateVolumeChange()
                }
            };
        }
    }

    private async Task UpdateDisplay()
    {
        if (_chart != null && _dataPoints.Any())
        {
            var chartData = _dataPoints.Select(p => new
            {
                x = p.Timestamp.ToString("HH:mm:ss"),
                y = p.Value
            }).ToArray();
            
            await _chart.InvokeVoidAsync("updateData", chartData);
        }
        
        await InvokeAsync(StateHasChanged);
    }

    private double CalculateChange(double current, double previous)
    {
        if (previous == 0) return 0;
        return (current - previous) / previous;
    }

    private double CalculateVolumeChange()
    {
        var now = DateTime.UtcNow;
        var currentMinute = _dataPoints.Count(p => p.Timestamp > now.AddMinutes(-1));
        var previousMinute = _dataPoints.Count(p => p.Timestamp > now.AddMinutes(-2) && p.Timestamp <= now.AddMinutes(-1));
        
        return CalculateChange(currentMinute, previousMinute);
    }

    public async ValueTask DisposeAsync()
    {
        _refreshTimer?.Dispose();
        
        if (_isConnected)
        {
            StreamAnalyticsService.OnDataReceived -= HandleDataReceived;
            StreamAnalyticsService.OnAnomalyDetected -= HandleAnomalyDetected;
            await StreamAnalyticsService.DisconnectAsync(StreamId);
        }
        
        if (_chart != null)
        {
            await _chart.InvokeVoidAsync("destroy");
            await _chart.DisposeAsync();
        }
    }

    private class Metric
    {
        public string Label { get; set; } = "";
        public double Value { get; set; }
        public double Change { get; set; }
    }

    private class DataPoint
    {
        public DateTime Timestamp { get; set; }
        public double Value { get; set; }
        public Dictionary<string, object>? Metadata { get; set; }
    }
}

<style>
    .analytics-container {
        height: 100%;
        display: flex;
        flex-direction: column;
    }

    .analytics-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1rem;
    }

    .analytics-header h3 {
        margin: 0;
        color: var(--text-primary);
    }

    .stream-status {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        font-size: 0.875rem;
        color: var(--text-secondary);
    }

    .status-indicator {
        width: 0.5rem;
        height: 0.5rem;
        border-radius: 50%;
        background: var(--text-secondary);
    }

    .status-indicator.connected {
        background: var(--success-color);
        animation: pulse 2s infinite;
    }

    .status-indicator.disconnected {
        background: var(--error-color);
    }

    .metrics-row {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
        gap: 1rem;
        margin-bottom: 1.5rem;
    }

    .metric-box {
        text-align: center;
        padding: 1rem;
        background: var(--metric-bg);
        border-radius: 0.5rem;
        transition: all 0.3s;
    }

    .metric-box:hover {
        transform: translateY(-2px);
        box-shadow: var(--shadow-sm);
    }

    .metric-value {
        font-size: 1.5rem;
        font-weight: 600;
        color: var(--text-primary);
    }

    .metric-label {
        font-size: 0.75rem;
        color: var(--text-secondary);
        text-transform: uppercase;
        margin-top: 0.25rem;
    }

    .metric-change {
        font-size: 0.875rem;
        margin-top: 0.5rem;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.25rem;
    }

    .metric-change.positive {
        color: var(--success-color);
    }

    .metric-change.negative {
        color: var(--error-color);
    }

    .chart-container {
        flex: 1;
        position: relative;
        min-height: 200px;
    }

    .anomalies-section {
        margin-top: 1.5rem;
        padding-top: 1.5rem;
        border-top: 1px solid var(--border-color);
    }

    .anomalies-section h4 {
        margin: 0 0 1rem 0;
        color: var(--text-primary);
        font-size: 1rem;
    }

    .anomaly-list {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }

    .anomaly-item {
        display: grid;
        grid-template-columns: auto 1fr auto;
        gap: 1rem;
        padding: 0.75rem;
        background: var(--anomaly-bg);
        border-radius: 0.5rem;
        border-left: 3px solid;
        font-size: 0.875rem;
    }

    .anomaly-item.low {
        border-color: var(--warning-color);
    }

    .anomaly-item.medium {
        border-color: var(--warning-color-dark);
    }

    .anomaly-item.high {
        border-color: var(--error-color);
    }

    .anomaly-time {
        color: var(--text-secondary);
        font-family: var(--font-mono);
    }

    .anomaly-description {
        color: var(--text-primary);
    }

    .anomaly-impact {
        color: var(--text-secondary);
        font-size: 0.75rem;
    }
</style>
```

## 🔌 Step 6: Create API Endpoints

### 6.1 Create Main API Controller

Create `src/API/Controllers/AIEnterpriseController.cs`:

```csharp
namespace AIEnterprise.API.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
[Authorize]
public class AIEnterpriseController : ControllerBase
{
    private readonly IConversationalService _conversationalService;
    private readonly ICustomer360Service _customerService;
    private readonly IDynamicPricingService _pricingService;
    private readonly IPredictiveAnalyticsService _analyticsService;
    private readonly ILogger<AIEnterpriseController> _logger;

    public AIEnterpriseController(
        IConversationalService conversationalService,
        ICustomer360Service customerService,
        IDynamicPricingService pricingService,
        IPredictiveAnalyticsService analyticsService,
        ILogger<AIEnterpriseController> logger)
    {
        _conversationalService = conversationalService;
        _customerService = customerService;
        _pricingService = pricingService;
        _analyticsService = analyticsService;
        _logger = logger;
    }

    [HttpPost("chat")]
    public async Task<ActionResult<ConversationResponse>> Chat(
        [FromBody] ChatRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value 
                ?? throw new UnauthorizedException();

            var response = await _conversationalService.ProcessMessageAsync(
                new ConversationMessage
                {
                    ConversationId = request.ConversationId ?? Guid.NewGuid().ToString(),
                    UserId = userId,
                    Content = request.Message,
                    Metadata = request.Metadata ?? new Dictionary<string, object>()
                },
                cancellationToken);

            return Ok(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Chat request failed");
            return StatusCode(500, new { error = "An error occurred processing your request" });
        }
    }

    [HttpPost("chat/stream")]
    public async Task ChatStream(
        [FromBody] ChatRequest request,
        CancellationToken cancellationToken)
    {
        Response.Headers.Add("Content-Type", "text/event-stream");
        Response.Headers.Add("Cache-Control", "no-cache");
        Response.Headers.Add("X-Accel-Buffering", "no");

        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value 
            ?? throw new UnauthorizedException();

        try
        {
            var streamingResponse = await _conversationalService.ProcessMessageStreamingAsync(
                new ConversationMessage
                {
                    ConversationId = request.ConversationId ?? Guid.NewGuid().ToString(),
                    UserId = userId,
                    Content = request.Message,
                    Metadata = request.Metadata ?? new Dictionary<string, object>()
                },
                cancellationToken);

            await foreach (var chunk in streamingResponse.GetResponseStream()
                .WithCancellation(cancellationToken))
            {
                var eventData = $"data: {JsonSerializer.Serialize(chunk)}\n\n";
                await Response.WriteAsync(eventData, cancellationToken);
                await Response.Body.FlushAsync(cancellationToken);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Streaming chat request failed");
            var errorEvent = $"data: {JsonSerializer.Serialize(new { error = ex.Message })}\n\n";
            await Response.WriteAsync(errorEvent, cancellationToken);
        }
    }

    [HttpGet("customers/{customerId}/360")]
    public async Task<ActionResult<CustomerProfile>> GetCustomer360(
        Guid customerId,
        [FromQuery] bool includeAI = true,
        CancellationToken cancellationToken)
    {
        try
        {
            var profile = await _customerService.GetComprehensiveProfileAsync(
                customerId,
                new ProfileOptions
                {
                    IncludePurchaseHistory = true,
                    IncludeInteractions = true,
                    IncludePredictiveInsights = true,
                    IncludeRelationships = true,
                    GenerateAIInsights = includeAI
                },
                cancellationToken);

            return Ok(profile);
        }
        catch (CustomerNotFoundException)
        {
            return NotFound(new { error = "Customer not found" });
        }
    }

    [HttpPost("pricing/calculate")]
    public async Task<ActionResult<PricingDecision>> CalculateDynamicPrice(
        [FromBody] PricingRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var decision = await _pricingService.CalculateDynamicPriceAsync(
                request.ProductId,
                new PricingContext
                {
                    Objective = request.Objective,
                    MinimumMargin = request.MinimumMargin ?? 20,
                    MaxPriceChangePercent = request.MaxPriceChange ?? 20,
                    CustomerSegment = request.CustomerSegment,
                    Channel = request.Channel
                },
                cancellationToken);

            return Ok(decision);
        }
        catch (ProductNotFoundException)
        {
            return NotFound(new { error = "Product not found" });
        }
    }

    [HttpPost("pricing/simulate")]
    public async Task<ActionResult<PriceSimulationResult>> SimulatePricing(
        [FromBody] SimulationRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _pricingService.SimulatePriceChangeAsync(
            request.ProductId,
            request.NewPrice,
            new SimulationParameters
            {
                SimulationPeriodDays = request.Days ?? 30,
                IncludeCompetitorResponse = request.IncludeCompetitors,
                IncludeCustomerSentiment = request.IncludeSentiment
            },
            cancellationToken);

        return Ok(result);
    }

    [HttpPost("analytics/forecast")]
    public async Task<ActionResult<SalesForecast>> ForecastSales(
        [FromBody] ForecastRequest request,
        CancellationToken cancellationToken)
    {
        var forecast = await _analyticsService.ForecastSalesAsync(
            request,
            cancellationToken);

        return Ok(forecast);
    }

    [HttpPost("analytics/churn")]
    public async Task<ActionResult<ChurnPrediction>> PredictChurn(
        [FromBody] ChurnRequest request,
        CancellationToken cancellationToken)
    {
        var prediction = await _analyticsService.PredictCustomerChurnAsync(
            request.CustomerId,
            new ChurnAnalysisOptions
            {
                TimeHorizonDays = request.TimeHorizon ?? 90,
                IncludeBehavioralFeatures = true,
                IncludeInteractionFeatures = true,
                IncludeSentimentAnalysis = true
            },
            cancellationToken);

        return Ok(prediction);
    }

    [HttpPost("analytics/anomalies")]
    public async Task<ActionResult<AnomalyDetectionResult>> DetectAnomalies(
        [FromBody] AnomalyRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _analyticsService.DetectAnomaliesAsync(
            new AnomalyDetectionRequest
            {
                DataSource = request.DataSource,
                TimeRange = new DateRange(request.StartDate, request.EndDate),
                Sensitivity = request.Sensitivity ?? AnomalySensitivity.Medium,
                IncludePatternAnalysis = request.AnalyzePatterns
            },
            cancellationToken);

        return Ok(result);
    }

    [HttpGet("health")]
    [AllowAnonymous]
    public async Task<ActionResult<HealthStatus>> GetHealth(
        CancellationToken cancellationToken)
    {
        var agentHealth = await _agentOrchestrator.CheckHealthAsync(cancellationToken);
        
        return Ok(new HealthStatus
        {
            Status = agentHealth.All(h => h.Status == HealthStatus.Healthy) 
                ? "Healthy" 
                : "Degraded",
            Timestamp = DateTime.UtcNow,
            Services = agentHealth.Select(h => new ServiceHealth
            {
                Name = h.AgentName,
                Status = h.Status.ToString(),
                Message = h.Message
            }).ToList()
        });
    }
}

public class ChatRequest
{
    public string? ConversationId { get; set; }
    public string Message { get; set; } = null!;
    public Dictionary<string, object>? Metadata { get; set; }
}

public class PricingRequest
{
    public Guid ProductId { get; set; }
    public PricingObjective Objective { get; set; } = PricingObjective.MaximizeRevenue;
    public decimal? MinimumMargin { get; set; }
    public decimal? MaxPriceChange { get; set; }
    public string? CustomerSegment { get; set; }
    public string? Channel { get; set; }
}

public class SimulationRequest
{
    public Guid ProductId { get; set; }
    public decimal NewPrice { get; set; }
    public int? Days { get; set; }
    public bool IncludeCompetitors { get; set; } = true;
    public bool IncludeSentiment { get; set; } = true;
}

public class ChurnRequest
{
    public Guid CustomerId { get; set; }
    public int? TimeHorizon { get; set; }
}

public class AnomalyRequest
{
    public string DataSource { get; set; } = null!;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public AnomalySensitivity? Sensitivity { get; set; }
    public bool AnalyzePatterns { get; set; } = true;
}
```

### 6.2 Create SignalR Hub for Real-Time Updates

Create `src/API/Hubs/DashboardHub.cs`:

```csharp
namespace AIEnterprise.API.Hubs;

[Authorize]
public class DashboardHub : Hub
{
    private readonly IEventProcessor _eventProcessor;
    private readonly ILogger<DashboardHub> _logger;
    private readonly IConnectionManager _connectionManager;

    public DashboardHub(
        IEventProcessor eventProcessor,
        ILogger<DashboardHub> logger,
        IConnectionManager connectionManager)
    {
        _eventProcessor = eventProcessor;
        _logger = logger;
        _connectionManager = connectionManager;
    }

    public override async Task OnConnectedAsync()
    {
        var userId = Context.UserIdentifier ?? "anonymous";
        await _connectionManager.AddConnectionAsync(userId, Context.ConnectionId);
        
        // Join user-specific group
        await Groups.AddToGroupAsync(Context.ConnectionId, $"user-{userId}");
        
        // Join role-based groups
        var roles = Context.User?.Claims
            .Where(c => c.Type == ClaimTypes.Role)
            .Select(c => c.Value) ?? new List<string>();
            
        foreach (var role in roles)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"role-{role}");
        }
        
        _logger.LogInformation(
            "User {UserId} connected with connection {ConnectionId}",
            userId,
            Context.ConnectionId);
            
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = Context.UserIdentifier ?? "anonymous";
        await _connectionManager.RemoveConnectionAsync(userId, Context.ConnectionId);
        
        _logger.LogInformation(
            "User {UserId} disconnected from connection {ConnectionId}",
            userId,
            Context.ConnectionId);
            
        await base.OnDisconnectedAsync(exception);
    }

    public async Task SubscribeToStream(string streamId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"stream-{streamId}");
        
        _logger.LogInformation(
            "Connection {ConnectionId} subscribed to stream {StreamId}",
            Context.ConnectionId,
            streamId);
    }

    public async Task UnsubscribeFromStream(string streamId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"stream-{streamId}");
        
        _logger.LogInformation(
            "Connection {ConnectionId} unsubscribed from stream {StreamId}",
            Context.ConnectionId,
            streamId);
    }

    public async Task SendCommand(string command, Dictionary<string, object> parameters)
    {
        var userId = Context.UserIdentifier ?? throw new UnauthorizedException();
        
        _logger.LogInformation(
            "User {UserId} sent command {Command}",
            userId,
            command);
            
        // Process command through event processor
        await _eventProcessor.ProcessCommandAsync(new CommandEvent
        {
            UserId = userId,
            Command = command,
            Parameters = parameters,
            Timestamp = DateTime.UtcNow
        });
    }
}
```

## ⚙️ Step 7: Configure Dependency Injection

### 7.1 Create Service Registration

Create `src/API/ServiceConfiguration.cs`:

```csharp
namespace AIEnterprise.API;

public static class ServiceConfiguration
{
    public static IServiceCollection AddAIEnterpriseServices(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        // Add core services
        services.AddScoped<ICustomer360Service, Customer360Service>();
        services.AddScoped<IDynamicPricingService, DynamicPricingService>();
        services.AddScoped<IPredictiveAnalyticsService, PredictiveAnalyticsService>();
        
        // Add AI services
        services.AddSingleton<IKernel>(sp =>
        {
            var builder = sp.GetRequiredService<EnterpriseKernelBuilder>();
            return builder.BuildKernel();
        });
        
        services.AddSingleton<EnterpriseKernelBuilder>();
        services.AddScoped<IAIService, SemanticKernelAIService>();
        services.AddScoped<IModelService, ModelService>();
        
        // Add infrastructure services
        services.AddSingleton<IVectorStore, CosmosVectorStore>();
        services.AddSingleton<IEventProcessor, EventProcessor>();
        services.AddSingleton<IStreamAnalytics, StreamAnalytics>();
        
        // Add agent services
        services.AddScoped<IAgent, BusinessAnalystAgent>();
        services.AddScoped<IAgent, CustomerInsightAgent>();
        services.AddScoped<IAgent, PricingOptimizationAgent>();
        services.AddScoped<IAgent, AnomalyDetectionAgent>();
        services.AddSingleton<IAgentOrchestrator, AgentOrchestrator>();
        
        // Add conversation services
        services.AddScoped<IConversationalService, ConversationalService>();
        services.AddScoped<INLUService, NLUService>();
        services.AddScoped<IConversationManager, ConversationManager>();
        services.AddScoped<IResponseGenerator, ResponseGenerator>();
        
        // Add voice services
        services.AddScoped<IVoiceService, VoiceService>();
        services.AddScoped<ISpeechRecognitionService, AzureSpeechRecognitionService>();
        services.AddScoped<ITextToSpeechService, AzureTextToSpeechService>();
        
        // Configure Azure services
        services.AddSingleton(sp =>
        {
            var endpoint = configuration["Azure:CosmosDB:Endpoint"];
            var key = configuration["Azure:CosmosDB:Key"];
            return new CosmosClient(endpoint, key, new CosmosClientOptions
            {
                SerializerOptions = new CosmosSerializationOptions
                {
                    PropertyNamingPolicy = CosmosPropertyNamingPolicy.CamelCase
                }
            });
        });
        
        // Configure OpenAI
        services.AddSingleton(sp =>
        {
            var endpoint = configuration["Azure:OpenAI:Endpoint"];
            var key = configuration["Azure:OpenAI:ApiKey"];
            return new OpenAIClient(new Uri(endpoint), new AzureKeyCredential(key));
        });
        
        // Configure caching
        services.AddStackExchangeRedisCache(options =>
        {
            options.Configuration = configuration.GetConnectionString("Redis");
            options.InstanceName = "AIEnterprise";
        });
        
        // Configure messaging
        services.AddSingleton(sp =>
        {
            var connectionString = configuration.GetConnectionString("EventHub");
            return new EventHubProducerClient(connectionString);
        });
        
        // Add telemetry
        services.AddSingleton<ITelemetryService, AITelemetryService>();
        services.AddApplicationInsightsTelemetry(configuration["ApplicationInsights:ConnectionString"]);
        
        // Add health checks
        services.AddHealthChecks()
            .AddCheck<AIHealthCheck>("ai_services")
            .AddCosmosDb(
                configuration["Azure:CosmosDB:ConnectionString"],
                name: "cosmos_db")
            .AddRedis(
                configuration.GetConnectionString("Redis"),
                name: "redis_cache");
                
        return services;
    }
    
    public static IServiceCollection AddAIEnterpriseAuthentication(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.Authority = configuration["AzureAd:Authority"];
                options.Audience = configuration["AzureAd:Audience"];
                
                options.Events = new JwtBearerEvents
                {
                    OnMessageReceived = context =>
                    {
                        // Support JWT in query string for SignalR
                        var accessToken = context.Request.Query["access_token"];
                        var path = context.HttpContext.Request.Path;
                        
                        if (!string.IsNullOrEmpty(accessToken) &&
                            path.StartsWithSegments("/hubs"))
                        {
                            context.Token = accessToken;
                        }
                        
                        return Task.CompletedTask;
                    }
                };
            });
            
        services.AddAuthorization(options =>
        {
            options.AddPolicy("AIUsers", policy =>
                policy.RequireAuthenticatedUser()
                      .RequireClaim("ai_access", "true"));
                      
            options.AddPolicy("Administrators", policy =>
                policy.RequireRole("Admin", "SystemAdmin"));
        });
        
        return services;
    }
}
```

### 7.2 Configure Program.cs

Create `src/API/Program.cs`:

```csharp
var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo 
    { 
        Title = "AI Enterprise API", 
        Version = "v1",
        Description = "AI-powered enterprise system API"
    });
    
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer"
    });
    
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new string[] { }
        }
    });
});

// Add SignalR
builder.Services.AddSignalR(options =>
{
    options.EnableDetailedErrors = builder.Environment.IsDevelopment();
    options.MaximumReceiveMessageSize = 1024 * 1024; // 1MB
})
.AddAzureSignalR(builder.Configuration.GetConnectionString("AzureSignalR"));

// Add CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowWebApp", policy =>
    {
        policy.WithOrigins(builder.Configuration["WebApp:Url"])
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

// Add custom services
builder.Services.AddAIEnterpriseServices(builder.Configuration);
builder.Services.AddAIEnterpriseAuthentication(builder.Configuration);

// Configure logging
builder.Logging.AddApplicationInsights();
builder.Logging.AddConsole();

// Add response compression
builder.Services.AddResponseCompression(options =>
{
    options.EnableForHttps = true;
    options.Providers.Add<BrotliCompressionProvider>();
    options.Providers.Add<GzipCompressionProvider>();
});

var app = builder.Build();

// Configure pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
else
{
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseResponseCompression();
app.UseCors("AllowWebApp");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<DashboardHub>("/hubs/dashboard");
app.MapHealthChecks("/health");

// Start background services
var eventProcessor = app.Services.GetRequiredService<IEventProcessor>();
_ = Task.Run(() => eventProcessor.StartProcessingAsync(app.Lifetime.ApplicationStopping));

app.Run();
```

## 🚀 Step 8: Deploy and Test

### 8.1 Create Deployment Scripts

Create `infrastructure/bicep/main.bicep`:

```bicep
targetScope = 'subscription'

@description('Name of the resource group')
param resourceGroupName string = 'rg-aienterprise-prod'

@description('Location for all resources')
param location string = 'eastus'

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'prod'

// Create resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

// Deploy resources
module resources 'resources.bicep' = {
  name: 'resources-deployment'
  scope: rg
  params: {
    location: location
    environment: environment
  }
}

// Deploy AI services
module aiServices 'ai-services.bicep' = {
  name: 'ai-services-deployment'
  scope: rg
  params: {
    location: location
    environment: environment
  }
}

// Deploy application
module application 'application.bicep' = {
  name: 'application-deployment'
  scope: rg
  params: {
    location: location
    environment: environment
    cosmosEndpoint: resources.outputs.cosmosEndpoint
    openAiEndpoint: aiServices.outputs.openAiEndpoint
    searchEndpoint: aiServices.outputs.searchEndpoint
  }
}

output appServiceUrl string = application.outputs.appServiceUrl
output apiEndpoint string = application.outputs.apiEndpoint
```

### 8.2 Create Test Suite

Create `tests/Integration/AIEnterpriseIntegrationTests.cs`:

```csharp
namespace AIEnterprise.Tests.Integration;

public class AIEnterpriseIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly HttpClient _client;

    public AIEnterpriseIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
        _client = _factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                // Override with test services
                services.AddSingleton<IVectorStore, InMemoryVectorStore>();
            });
        }).CreateClient();
    }

    [Fact]
    public async Task Chat_ShouldReturnValidResponse()
    {
        // Arrange
        var request = new ChatRequest
        {
            Message = "Show me customer insights"
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/v1/aienterprise/chat", request);

        // Assert
        response.EnsureSuccessStatusCode();
        var content = await response.Content.ReadFromJsonAsync<ConversationResponse>();
        
        Assert.NotNull(content);
        Assert.NotEmpty(content.Text);
        Assert.Equal(ResponseType.Success, content.Type);
    }

    [Fact]
    public async Task Customer360_ShouldReturnCompleteProfile()
    {
        // Arrange
        var customerId = Guid.NewGuid();
        
        // Act
        var response = await _client.GetAsync($"/api/v1/aienterprise/customers/{customerId}/360");
        
        // Assert
        response.EnsureSuccessStatusCode();
        var profile = await response.Content.ReadFromJsonAsync<CustomerProfile>();
        
        Assert.NotNull(profile);
        Assert.Equal(customerId, profile.CustomerId);
        Assert.NotNull(profile.PredictiveInsights);
    }

    [Theory]
    [InlineData(PricingObjective.MaximizeRevenue)]
    [InlineData(PricingObjective.MaximizeVolume)]
    [InlineData(PricingObjective.ClearInventory)]
    public async Task DynamicPricing_ShouldOptimizeForObjective(PricingObjective objective)
    {
        // Arrange
        var request = new PricingRequest
        {
            ProductId = Guid.NewGuid(),
            Objective = objective
        };
        
        // Act
        var response = await _client.PostAsJsonAsync("/api/v1/aienterprise/pricing/calculate", request);
        
        // Assert
        response.EnsureSuccessStatusCode();
        var decision = await response.Content.ReadFromJsonAsync<PricingDecision>();
        
        Assert.NotNull(decision);
        Assert.True(decision.CalculatedPrice > 0);
        Assert.True(decision.ConfidenceScore > 0.5);
    }
}
```

## 💡 Copilot Prompt Suggestions

**For Performance Optimization:**
```
Optimize the AI Enterprise system for high throughput:
- Implement request batching for AI operations
- Add response caching with Redis
- Use async/await throughout
- Implement circuit breakers for external services
- Add request rate limiting
Include distributed tracing with OpenTelemetry
```

**For Security Hardening:**
```
Add comprehensive security to the enterprise system:
- Implement row-level security for multi-tenant data
- Add API key rotation mechanism
- Encrypt sensitive data at rest and in transit
- Implement audit logging for all AI decisions
- Add GDPR compliance features
Include threat detection using Microsoft Sentinel
```

**For Monitoring Enhancement:**
```
Create a comprehensive monitoring solution that:
- Tracks AI model performance metrics
- Monitors token usage and costs
- Detects data drift in real-time
- Alerts on anomalous AI behavior
- Provides executive dashboards
Use Azure Monitor and custom metrics
```

## ✅ Part 3 Checklist

Before completing the exercise, ensure you have:

- [ ] Completed all UI components with Blazor
- [ ] Implemented real-time analytics dashboards
- [ ] Created all necessary API endpoints
- [ ] Configured dependency injection properly
- [ ] Set up authentication and authorization
- [ ] Created deployment scripts
- [ ] Written integration tests
- [ ] Tested end-to-end functionality
- [ ] Verified performance requirements

## 🎯 Exercise Summary

You've successfully built a complete AI-powered enterprise system with:

### **AI Foundation**
- Semantic Kernel configuration
- Vector search with Cosmos DB
- RAG pipeline implementation
- Multi-agent orchestration

### **Core Business Logic**
- Customer 360° view with AI insights
- Dynamic pricing optimization
- Predictive analytics
- Real-time anomaly detection

### **User Experience**
- Conversational AI interface
- Voice interaction support
- Real-time dashboards
- Interactive visualizations

### **Enterprise Features**
- Scalable architecture
- Security and compliance
- Monitoring and observability
- Production-ready deployment

## 🎉 Congratulations!

You've completed the most complex exercise in the workshop! This enterprise system demonstrates:

- **Integration** of multiple AI technologies
- **Scalability** for enterprise workloads
- **Security** for sensitive data
- **Usability** with modern UI/UX
- **Maintainability** with clean architecture

## 🚀 Next Steps

1. **Extend the System**:
   - Add more specialized agents
   - Implement advanced ML models
   - Create industry-specific features

2. **Optimize Performance**:
   - Implement caching strategies
   - Add database sharding
   - Optimize AI model inference

3. **Enhance Security**:
   - Add threat detection
   - Implement zero-trust architecture
   - Add compliance reporting

4. **Scale Globally**:
   - Multi-region deployment
   - CDN integration
   - Global data replication

## 📚 Additional Resources

- [Semantic Kernel Documentation](https://learn.microsoft.com/semantic-kernel/)
- [Azure AI Services](https://azure.microsoft.com/products/ai-services/)
- [Blazor Documentation](https://learn.microsoft.com/aspnet/core/blazor/)
- [Enterprise Architecture Patterns](https://learn.microsoft.com/azure/architecture/)

---

**🏆 Achievement Unlocked**: Enterprise AI Architect! You've mastered the integration of AI into enterprise systems, creating a production-ready solution that showcases the power of modern AI technologies.