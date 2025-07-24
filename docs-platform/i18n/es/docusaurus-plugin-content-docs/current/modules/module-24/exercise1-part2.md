---
sidebar_position: 4
title: "Exercise 1: Part 2"
description: "## 🛠️ Continuing Implementation"
---

# Ejercicio 1: ReBuscar Assistant System - Partee 2

## 🛠️ Continuing Implementation

### Step 5: Implement Analysis Agent

**Copilot Prompt Suggestion:**
```typescript
// Create an analysis agent that:
// - Processes research data from multiple sources
// - Identifies patterns and trends
// - Performs statistical analysis
// - Validates data quality
// - Generates insights and metrics
// - Produces structured analysis results
```

Create `src/agents/AnalysisAgent.ts`:
```typescript
import { BaseAgent, Task } from './BaseAgent';
import * as stats from 'simple-statistics';

interface AnalysisTask {
  data: any[];
  analysisType: 'statistical' | 'sentiment' | 'trend' | 'comparative';
  parameters?: {
    metrics?: string[];
    groupBy?: string;
    timeRange?: { start: Date; end: Date };
  };
}

interface AnalysisResult {
  type: string;
  insights: Array<{
    category: string;
    finding: string;
    confidence: number;
    evidence: any[];
  }>;
  metrics: Record<string, any>;
  patterns: Array<{
    type: string;
    description: string;
    strength: number;
  }>;
  recommendations: string[];
  timestamp: Date;
}

export class AnalysisAgent extends BaseAgent {
  constructor() {
    super({
      name: 'AnalysisAgent',
      capabilities: ['analyze', 'statistical-analysis', 'pattern-recognition']
    });
  }

  protected async execute(task: Task): Promise<AnalysisResult> {
    const analysisTask = task.payload as AnalysisTask;
    
    this.logger.info('Starting analysis', {
      taskId: task.id,
      analysisType: analysisTask.analysisType,
      dataPoints: analysisTask.data.length
    });
    
    let result: AnalysisResult;
    
    switch (analysisTask.analysisType) {
      case 'statistical':
        result = await this.performStatisticalAnalysis(analysisTask);
        break;
      case 'sentiment':
        result = await this.performSentimentAnalysis(analysisTask);
        break;
      case 'trend':
        result = await this.performTrendAnalysis(analysisTask);
        break;
      case 'comparative':
        result = await this.performComparativeAnalysis(analysisTask);
        break;
      default:
        throw new Error(`Unknown analysis type: ${analysisTask.analysisType}`);
    }
    
    return result;
  }

  private async performStatisticalAnalysis(
    task: AnalysisTask
  ): Promise<AnalysisResult> {
    const insights: any[] = [];
    const metrics: Record<string, any> = {};
    const patterns: any[] = [];
    
    // Extract numerical data
    const numericalData = this.extractNumericalData(task.data);
    
    if (numericalData.length &gt; 0) {
      // Calculate basic statistics
      metrics.mean = stats.mean(numericalData);
      metrics.median = stats.median(numericalData);
      metrics.standardDeviation = stats.standardDeviation(numericalData);
      metrics.min = stats.min(numericalData);
      metrics.max = stats.max(numericalData);
      
      // Identify outliers
      const outliers = this.findOutliers(numericalData);
      if (outliers.length &gt; 0) {
        insights.push({
          category: 'outliers',
          finding: `Found ${outliers.length} outliers in the data`,
          confidence: 0.9,
          evidence: outliers
        });
      }
      
      // Check for normal distribution
      const isNormal = this.checkNormalDistribution(numericalData);
      patterns.push({
        type: 'distribution',
        description: isNormal ? 'Data follows normal distribution' : 
                               'Data does not follow normal distribution',
        strength: 0.8
      });
    }
    
    // Analyze categorical data
    const categoricalInsights = this.analyzeCategoricalData(task.data);
    insights.push(...categoricalInsights);
    
    // Generate recommendations
    const recommendations = this.generateStatisticalRecommendations(
      insights, 
      metrics, 
      patterns
    );
    
    return {
      type: 'statistical',
      insights,
      metrics,
      patterns,
      recommendations,
      timestamp: new Date()
    };
  }

  private async performSentimentAnalysis(
    task: AnalysisTask
  ): Promise<AnalysisResult> {
    // Simplified sentiment analysis
    const sentiments = task.data.map(item =&gt; {
      const text = JSON.stringify(item).toLowerCase();
      let score = 0;
      
      // Simple keyword-based sentiment (use ML model in production)
      const positiveWords = ['good', 'great', 'excellent', 'positive', 'success'];
      const negativeWords = ['bad', 'poor', 'negative', 'failure', 'problem'];
      
      positiveWords.forEach(word =&gt; {
        if (text.includes(word)) score += 1;
      });
      
      negativeWords.forEach(word =&gt; {
        if (text.includes(word)) score -= 1;
      });
      
      return { item, score };
    });
    
    const avgSentiment = sentiments.reduce((sum, s) =&gt; sum + s.score, 0) / 
                        sentiments.length;
    
    return {
      type: 'sentiment',
      insights: [{
        category: 'overall-sentiment',
        finding: avgSentiment &gt; 0 ? 'Positive sentiment detected' : 
                avgSentiment &lt; 0 ? 'Negative sentiment detected' : 
                'Neutral sentiment',
        confidence: Math.abs(avgSentiment) * 0.3,
        evidence: sentiments.slice(0, 5)
      }],
      metrics: {
        averageSentiment: avgSentiment,
        positiveCount: sentiments.filter(s =&gt; s.score &gt; 0).length,
        negativeCount: sentiments.filter(s =&gt; s.score &lt; 0).length,
        neutralCount: sentiments.filter(s =&gt; s.score === 0).length
      },
      patterns: [],
      recommendations: [
        avgSentiment &lt; 0 ? 'Address negative sentiment sources' : 
        'Maintain positive momentum'
      ],
      timestamp: new Date()
    };
  }

  private async performTrendAnalysis(
    task: AnalysisTask
  ): Promise<AnalysisResult> {
    // Sort data by time if available
    const timeSeriesData = this.extractTimeSeriesData(task.data);
    
    const insights: any[] = [];
    const patterns: any[] = [];
    
    if (timeSeriesData.length &gt; 2) {
      // Calculate trend
      const trend = this.calculateTrend(timeSeriesData);
      
      patterns.push({
        type: 'trend',
        description: trend &gt; 0 ? 'Upward trend' : 
                    trend &lt; 0 ? 'Downward trend' : 
                    'No significant trend',
        strength: Math.abs(trend)
      });
      
      // Detect seasonality
      const seasonality = this.detectSeasonality(timeSeriesData);
      if (seasonality) {
        patterns.push({
          type: 'seasonality',
          description: `Seasonal pattern detected with period of ${seasonality.period}`,
          strength: seasonality.strength
        });
      }
      
      // Find change points
      const changePoints = this.findChangePoints(timeSeriesData);
      if (changePoints.length &gt; 0) {
        insights.push({
          category: 'change-points',
          finding: `${changePoints.length} significant changes detected`,
          confidence: 0.85,
          evidence: changePoints
        });
      }
    }
    
    return {
      type: 'trend',
      insights,
      metrics: {
        dataPoints: timeSeriesData.length,
        timeRange: timeSeriesData.length &gt; 0 ? {
          start: timeSeriesData[0].time,
          end: timeSeriesData[timeSeriesData.length - 1].time
        } : null
      },
      patterns,
      recommendations: this.generateTrendRecommendations(patterns),
      timestamp: new Date()
    };
  }

  private async performComparativeAnalysis(
    task: AnalysisTask
  ): Promise<AnalysisResult> {
    // Group data for comparison
    const groups = this.groupData(task.data, task.parameters?.groupBy || 'category');
    
    const insights: any[] = [];
    const metrics: Record<string, any> = {};
    
    // Compare groups
    const groupStats = new Map<string, any>();
    
    for (const [groupName, groupData] of groups) {
      const stats = this.calculateGroupStatistics(groupData);
      groupStats.set(groupName, stats);
      metrics[`group_${groupName}`] = stats;
    }
    
    // Find significant differences
    const differences = this.findSignificantDifferences(groupStats);
    
    insights.push(...differences.map(diff =&gt; ({
      category: 'comparative',
      finding: diff.description,
      confidence: diff.significance,
      evidence: [diff.group1, diff.group2]
    })));
    
    return {
      type: 'comparative',
      insights,
      metrics,
      patterns: [],
      recommendations: this.generateComparativeRecommendations(differences),
      timestamp: new Date()
    };
  }

  private extractNumericalData(data: any[]): number[] {
    const numbers: number[] = [];
    
    const extractNumbers = (obj: any): void =&gt; {
      if (typeof obj === 'number') {
        numbers.push(obj);
      } else if (typeof obj === 'object' && obj !== null) {
        Object.values(obj).forEach(extractNumbers);
      }
    };
    
    data.forEach(extractNumbers);
    return numbers;
  }

  private findOutliers(data: number[]): number[] {
    const q1 = stats.quantile(data, 0.25);
    const q3 = stats.quantile(data, 0.75);
    const iqr = q3 - q1;
    
    const lowerBound = q1 - 1.5 * iqr;
    const upperBound = q3 + 1.5 * iqr;
    
    return data.filter(value =&gt; value &lt; lowerBound || value &gt; upperBound);
  }

  private checkNormalDistribution(data: number[]): boolean {
    // Simplified normality check (use proper tests in production)
    const mean = stats.mean(data);
    const median = stats.median(data);
    const stdDev = stats.standardDeviation(data);
    
    // Check if mean ≈ median (within 10% of std dev)
    return Math.abs(mean - median) &lt; 0.1 * stdDev;
  }

  private analyzeCategoricalData(data: any[]): any[] {
    const insights: any[] = [];
    const categories = new Map<string, number>();
    
    // Count occurrences
    data.forEach(item =&gt; {
      const category = item.category || item.type || 'unknown';
      categories.set(category, (categories.get(category) || 0) + 1);
    });
    
    // Find dominant categories
    const sortedCategories = Array.from(categories.entries())
      .sort(([, a], [, b]) =&gt; b - a);
    
    if (sortedCategories.length &gt; 0) {
      const [dominant, count] = sortedCategories[0];
      const percentage = (count / data.length) * 100;
      
      insights.push({
        category: 'distribution',
        finding: `"${dominant}" is the dominant category (${percentage.toFixed(1)}%)`,
        confidence: 0.95,
        evidence: sortedCategories.slice(0, 5)
      });
    }
    
    return insights;
  }

  private extractTimeSeriesData(data: any[]): Array<{ time: Date; value: number }> {
    return data
      .filter(item => item.timestamp || item.date || item.time)
      .map(item => ({
        time: new Date(item.timestamp || item.date || item.time),
        value: item.value || item.count || 0
      }))
      .sort((a, b) => a.time.getTime() - b.time.getTime());
  }

  private calculateTrend(data: Array<{ time: Date; value: number }>): number {
    if (data.length Less than 2) return 0;
    
    // Simple linear regression
    const x = data.map((_, i) => i);
    const y = data.map(d => d.value);
    
    const regression = stats.linearRegression([x, y]);
    return regression.m; // slope indicates trend
  }

  private detectSeasonality(
    data: Array<{ time: Date; value: number }>
  ): { period: number; strength: number } | null {
    // Simplified seasonality detection
    if (data.length Less than 12) return null;
    
    // Check for monthly pattern (simplified)
    const monthlyAverages = new Map<number, number[]>();
    
    data.forEach(point => {
      const month = point.time.getMonth();
      if (!monthlyAverages.has(month)) {
        monthlyAverages.set(month, []);
      }
      monthlyAverages.get(month)!.push(point.value);
    });
    
    // Calculate variance between months
    const monthlyMeans = Array.from(monthlyAverages.entries())
      .map(([month, values]) => ({
        month,
        mean: stats.mean(values)
      }));
    
    if (monthlyMeans.length >= 6) {
      const variance = stats.variance(monthlyMeans.map(m => m.mean));
      const overallMean = stats.mean(data.map(d => d.value));
      
      const strength = variance / (overallMean * overallMean);
      
      if (strength > 0.1) {
        return { period: 12, strength };
      }
    }
    
    return null;
  }

  private findChangePoints(
    data: Array<{ time: Date; value: number }>
  ): Array<{ index: number; magnitude: number }> {
    const changePoints: Array<{ index: number; magnitude: number }> = [];
    
    if (data.length Less than 10) return changePoints;
    
    // Simple change point detection using moving averages
    const windowSize = Math.floor(data.length / 10);
    
    for (let i = windowSize; i < data.length - windowSize; i++) {
      const before = data.slice(i - windowSize, i).map(d => d.value);
      const after = data.slice(i, i + windowSize).map(d => d.value);
      
      const meanBefore = stats.mean(before);
      const meanAfter = stats.mean(after);
      
      const change = Math.abs(meanAfter - meanBefore) / meanBefore;
      
      if (change > 0.3) { // 30% change threshold
        changePoints.push({ index: i, magnitude: change });
      }
    }
    
    return changePoints;
  }

  private groupData(data: any[], groupBy: string): Map<string, any[]> {
    const groups = new Map<string, any[]>();
    
    data.forEach(item => {
      const key = item[groupBy] || 'other';
      if (!groups.has(key)) {
        groups.set(key, []);
      }
      groups.get(key)!.push(item);
    });
    
    return groups;
  }

  private calculateGroupStatistics(data: any[]): any {
    const numerical = this.extractNumericalData(data);
    
    return {
      count: data.length,
      mean: numerical.length > 0 ? stats.mean(numerical) : null,
      median: numerical.length > 0 ? stats.median(numerical) : null,
      stdDev: numerical.length > 0 ? stats.standardDeviation(numerical) : null
    };
  }

  private findSignificantDifferences(groupStats: Map<string, any>): any[] {
    const differences: any[] = [];
    const groups = Array.from(groupStats.entries());
    
    for (let i = 0; i &lt; groups.length; i++) {
      for (let j = i + 1; j &lt; groups.length; j++) {
        const [name1, stats1] = groups[i];
        const [name2, stats2] = groups[j];
        
        if (stats1.mean !== null && stats2.mean !== null) {
          const diff = Math.abs(stats1.mean - stats2.mean);
          const avgStdDev = (stats1.stdDev + stats2.stdDev) / 2;
          
          if (diff &gt; avgStdDev) {
            differences.push({
              group1: name1,
              group2: name2,
              difference: diff,
              significance: Math.min(diff / avgStdDev, 1),
              description: `${name1} differs significantly from ${name2}`
            });
          }
        }
      }
    }
    
    return differences;
  }

  private generateStatisticalRecommendations(
    insights: any[], 
    metrics: any, 
    patterns: any[]
  ): string[] {
    const recommendations: string[] = [];
    
    if (insights.some(i =&gt; i.category === 'outliers')) {
      recommendations.push('Investigate outliers for data quality issues or exceptional cases');
    }
    
    if (metrics.standardDeviation && metrics.mean) {
      const cv = metrics.standardDeviation / metrics.mean;
      if (cv &gt; 0.5) {
        recommendations.push('High variability detected - consider segmentation analysis');
      }
    }
    
    return recommendations;
  }

  private generateTrendRecommendations(patterns: any[]): string[] {
    const recommendations: string[] = [];
    
    const trend = patterns.find(p =&gt; p.type === 'trend');
    if (trend) {
      if (trend.description.includes('Upward')) {
        recommendations.push('Continue monitoring growth trajectory');
        recommendations.push('Prepare for scale if trend continues');
      } else if (trend.description.includes('Downward')) {
        recommendations.push('Investigate root causes of decline');
        recommendations.push('Implement corrective measures');
      }
    }
    
    if (patterns.some(p =&gt; p.type === 'seasonality')) {
      recommendations.push('Plan resources according to seasonal patterns');
    }
    
    return recommendations;
  }

  private generateComparativeRecommendations(differences: any[]): string[] {
    const recommendations: string[] = [];
    
    if (differences.length &gt; 0) {
      recommendations.push('Focus on understanding drivers of group differences');
      
      const highPerformers = differences
        .filter(d =&gt; d.significance &gt; 0.8)
        .map(d =&gt; d.group1);
      
      if (highPerformers.length &gt; 0) {
        recommendations.push(`Study best practices from: ${highPerformers.join(', ')}`);
      }
    }
    
    return recommendations;
  }
}
```

### Step 6: Implement Synthesis Agent

Create `src/agents/SynthesisAgent.ts`:
```typescript
import { BaseAgent, Task } from './BaseAgent';

interface SynthesisTask {
  researchResults: any;
  analysisResults: any;
  context?: {
    objective: string;
    audience: string;
    format: string;
  };
}

interface SynthesisResult {
  summary: {
    executive: string;
    detailed: string;
  };
  keyFindings: Array<{
    finding: string;
    importance: 'high' | 'medium' | 'low';
    supporting_evidence: any[];
  }>;
  connections: Array<{
    items: string[];
    relationship: string;
    strength: number;
  }>;
  conclusions: string[];
  nextSteps: string[];
}

export class SynthesisAgent extends BaseAgent {
  constructor() {
    super({
      name: 'SynthesisAgent',
      capabilities: ['synthesize', 'combine-insights', 'draw-conclusions']
    });
  }

  protected async execute(task: Task): Promise<SynthesisResult> {
    const synthTask = task.payload as SynthesisTask;
    
    // Extract key information from research
    const researchSummary = this.summarizeResearch(synthTask.researchResults);
    
    // Extract insights from analysis
    const analysisInsights = this.extractAnalysisInsights(synthTask.analysisResults);
    
    // Find connections between findings
    const connections = this.findConnections(researchSummary, analysisInsights);
    
    // Generate key findings
    const keyFindings = this.generateKeyFindings(
      researchSummary, 
      analysisInsights, 
      connections
    );
    
    // Draw conclusions
    const conclusions = this.drawConclusions(keyFindings, connections);
    
    // Recommend next steps
    const nextSteps = this.recommendNextSteps(
      keyFindings, 
      conclusions, 
      synthTask.context
    );
    
    return {
      summary: {
        executive: this.generateExecutiveSummary(keyFindings, conclusions),
        detailed: this.generateDetailedSummary(
          researchSummary, 
          analysisInsights, 
          keyFindings
        )
      },
      keyFindings,
      connections,
      conclusions,
      nextSteps
    };
  }

  private summarizeResearch(researchResults: any): any {
    return {
      totalSources: researchResults.sources?.length || 0,
      mainTopics: researchResults.keywords || [],
      summary: researchResults.summary || '',
      confidence: this.calculateConfidence(researchResults)
    };
  }

  private extractAnalysisInsights(analysisResults: any): any[] {
    const insights: any[] = [];
    
    if (analysisResults.insights) {
      insights.push(...analysisResults.insights);
    }
    
    if (analysisResults.patterns) {
      insights.push(...analysisResults.patterns.map((p: any) =&gt; ({
        category: 'pattern',
        finding: p.description,
        confidence: p.strength
      })));
    }
    
    return insights;
  }

  private findConnections(research: any, insights: any[]): any[] {
    const connections: any[] = [];
    
    // Find topic-insight connections
    research.mainTopics.forEach((topic: string) =&gt; {
      insights.forEach(insight =&gt; {
        if (insight.finding.toLowerCase().includes(topic.toLowerCase())) {
          connections.push({
            items: [topic, insight.finding],
            relationship: 'related-to',
            strength: 0.7
          });
        }
      });
    });
    
    return connections;
  }

  private generateKeyFindings(
    research: any, 
    insights: any[], 
    connections: any[]
  ): any[] {
    const findings: any[] = [];
    
    // High confidence insights become key findings
    insights
      .filter(i =&gt; i.confidence &gt; 0.7)
      .forEach(insight =&gt; {
        findings.push({
          finding: insight.finding,
          importance: this.determineImportance(insight, connections),
          supporting_evidence: [insight.evidence || []]
        });
      });
    
    // Sort by importance
    findings.sort((a, b) =&gt; {
      const importanceOrder = { high: 3, medium: 2, low: 1 };
      return importanceOrder[b.importance] - importanceOrder[a.importance];
    });
    
    return findings.slice(0, 5); // Top 5 findings
  }

  private determineImportance(
    insight: any, 
    connections: any[]
  ): 'high' | 'medium' | 'low' {
    const connectionCount = connections.filter(c =&gt; 
      c.items.some((item: string) =&gt; item === insight.finding)
    ).length;
    
    if (insight.confidence &gt; 0.8 && connectionCount &gt; 2) return 'high';
    if (insight.confidence &gt; 0.6 || connectionCount &gt; 1) return 'medium';
    return 'low';
  }

  private drawConclusions(findings: any[], connections: any[]): string[] {
    const conclusions: string[] = [];
    
    // High importance findings lead to conclusions
    findings
      .filter(f =&gt; f.importance === 'high')
      .forEach(finding =&gt; {
        conclusions.push(`Based on the analysis, ${finding.finding}`);
      });
    
    // Strong connections indicate relationships
    connections
      .filter(c =&gt; c.strength &gt; 0.8)
      .forEach(connection =&gt; {
        conclusions.push(
          `There is a strong ${connection.relationship} between ${connection.items.join(' and ')}`
        );
      });
    
    return conclusions;
  }

  private recommendNextSteps(
    findings: any[], 
    conclusions: string[], 
    context?: any
  ): string[] {
    const nextSteps: string[] = [];
    
    // Based on findings
    findings.forEach(finding =&gt; {
      if (finding.importance === 'high') {
        nextSteps.push(`Further investigate: ${finding.finding}`);
      }
    });
    
    // Based on context
    if (context?.objective) {
      nextSteps.push(`Align findings with objective: ${context.objective}`);
    }
    
    // General recommendations
    if (findings.length &lt; 3) {
      nextSteps.push('Expand research scope for more comprehensive findings');
    }
    
    return nextSteps.slice(0, 5);
  }

  private generateExecutiveSummary(
    findings: any[], 
    conclusions: string[]
  ): string {
    const topFindings = findings.slice(0, 3).map(f =&gt; f.finding).join('; ');
    const mainConclusion = conclusions[0] || 'No definitive conclusions drawn';
    
    return `Key findings include: ${topFindings}. ${mainConclusion}`;
  }

  private generateDetailedSummary(
    research: any, 
    insights: any[], 
    findings: any[]
  ): string {
    return `Research covered ${research.totalSources} sources focusing on ${research.mainTopics.join(', ')}. ` +
           `Analysis revealed ${insights.length} insights, with ${findings.length} key findings identified. ` +
           `Confidence level: ${(research.confidence * 100).toFixed(0)}%.`;
  }

  private calculateConfidence(results: any): number {
    let confidence = 0.5;
    
    if (results.sources?.length &gt; 5) confidence += 0.2;
    if (results.sources?.length &gt; 10) confidence += 0.1;
    if (results.keywords?.length &gt; 5) confidence += 0.1;
    if (results.summary?.length &gt; 100) confidence += 0.1;
    
    return Math.min(confidence, 1.0);
  }
}
```

### Step 7: Implement ReBuscar Orchestrator

Create `src/orchestrator/ResearchOrchestrator.ts`:
```typescript
import { EventEmitter } from 'eventemitter3';
import { v4 as uuidv4 } from 'uuid';
import { BaseAgent } from '../agents/BaseAgent';
import { ResearchAgent } from '../agents/ResearchAgent';
import { AnalysisAgent } from '../agents/AnalysisAgent';
import { SynthesisAgent } from '../agents/SynthesisAgent';
import { MessageBus, Message } from '../communication/MessageBus';
import winston from 'winston';

export interface ResearchRequest {
  id?: string;
  query: string;
  objective: string;
  scope?: {
    sources?: string[];
    timeRange?: { start: Date; end: Date };
    maxResults?: number;
  };
  options?: {
    analysisTypes?: string[];
    outputFormat?: string;
    priority?: number;
  };
}

export interface ResearchWorkflow {
  id: string;
  request: ResearchRequest;
  status: 'pending' | 'running' | 'completed' | 'failed';
  currentStep: string;
  steps: WorkflowStep[];
  results: Map<string, any>;
  startTime: Date;
  endTime?: Date;
  error?: string;
}

interface WorkflowStep {
  id: string;
  agentId: string;
  taskType: string;
  status: 'pending' | 'running' | 'completed' | 'failed';
  dependencies: string[];
  result?: any;
  error?: string;
}

export class ResearchOrchestrator extends EventEmitter {
  private agents: Map<string, BaseAgent> = new Map();
  private workflows: Map<string, ResearchWorkflow> = new Map();
  private messageBus: MessageBus;
  private logger: winston.Logger;

  constructor(redisUrl: string) {
    super();
    
    this.messageBus = new MessageBus(redisUrl);
    this.logger = winston.createLogger({
      level: 'info',
      format: winston.format.json(),
      defaultMeta: { component: 'ResearchOrchestrator' }
    });
    
    this.setupAgents();
    this.setupMessageHandlers();
  }

  private setupAgents(): void {
    // Create specialized agents
    const researchAgent = new ResearchAgent();
    const analysisAgent = new AnalysisAgent();
    const synthesisAgent = new SynthesisAgent();
    
    // Register agents
    this.registerAgent(researchAgent);
    this.registerAgent(analysisAgent);
    this.registerAgent(synthesisAgent);
  }

  private registerAgent(agent: BaseAgent): void {
    this.agents.set(agent.id, agent);
    
    // Setup agent event handlers
    agent.on('task-completed', (result) =&gt; {
      this.handleTaskCompleted(result);
    });
    
    agent.on('task-failed', (result) =&gt; {
      this.handleTaskFailed(result);
    });
    
    agent.on('health-update', (health) =&gt; {
      this.logger.info('Agent health update', health);
    });
    
    // Subscribe agent to message bus
    this.messageBus.subscribe(
      agent.id,
      agent.capabilities,
      async (message) =&gt; {
        if (message.type === 'task-assignment') {
          await agent.executeTask(message.payload);
        }
      }
    );
    
    this.logger.info('Agent registered', {
      agentId: agent.id,
      name: agent.name,
      capabilities: agent.capabilities
    });
  }

  async startWorkflow(request: ResearchRequest): Promise<string> {
    const workflowId = request.id || uuidv4();
    
    // Create workflow
    const workflow: ResearchWorkflow = {
      id: workflowId,
      request,
      status: 'pending',
      currentStep: 'initialization',
      steps: this.createWorkflowSteps(request),
      results: new Map(),
      startTime: new Date()
    };
    
    this.workflows.set(workflowId, workflow);
    
    this.logger.info('Starting research workflow', {
      workflowId,
      query: request.query,
      objective: request.objective
    });
    
    // Start all agents
    await Promise.all(
      Array.from(this.agents.values()).map(agent =&gt; agent.start())
    );
    
    // Begin workflow execution
    workflow.status = 'running';
    this.executeNextStep(workflowId);
    
    this.emit('workflow-started', { workflowId, request });
    
    return workflowId;
  }

  private createWorkflowSteps(request: ResearchRequest): WorkflowStep[] {
    const steps: WorkflowStep[] = [];
    
    // Step 1: Research
    const researchStep: WorkflowStep = {
      id: uuidv4(),
      agentId: this.findAgentByCapability('research')!.id,
      taskType: 'research',
      status: 'pending',
      dependencies: []
    };
    steps.push(researchStep);
    
    // Step 2: Analysis (depends on research)
    const analysisTypes = request.options?.analysisTypes || ['statistical'];
    
    analysisTypes.forEach(type =&gt; {
      steps.push({
        id: uuidv4(),
        agentId: this.findAgentByCapability('analyze')!.id,
        taskType: `analyze-${type}`,
        status: 'pending',
        dependencies: [researchStep.id]
      });
    });
    
    // Step 3: Synthesis (depends on all analysis)
    const analysisStepIds = steps
      .filter(s =&gt; s.taskType.startsWith('analyze'))
      .map(s =&gt; s.id);
    
    steps.push({
      id: uuidv4(),
      agentId: this.findAgentByCapability('synthesize')!.id,
      taskType: 'synthesize',
      status: 'pending',
      dependencies: analysisStepIds
    });
    
    return steps;
  }

  private findAgentByCapability(capability: string): BaseAgent | undefined {
    return Array.from(this.agents.values()).find(agent =&gt; 
      agent.canHandle(capability)
    );
  }

  private async executeNextStep(workflowId: string): Promise<void> {
    const workflow = this.workflows.get(workflowId);
    if (!workflow) return;
    
    // Find next executable step
    const nextStep = workflow.steps.find(step =&gt; 
      step.status === 'pending' &&
      step.dependencies.every(depId =&gt; 
        workflow.steps.find(s =&gt; s.id === depId)?.status === 'completed'
      )
    );
    
    if (!nextStep) {
      // Check if workflow is complete
      const allCompleted = workflow.steps.every(s =&gt; 
        s.status === 'completed' || s.status === 'failed'
      );
      
      if (allCompleted) {
        this.completeWorkflow(workflowId);
      }
      return;
    }
    
    // Execute step
    nextStep.status = 'running';
    workflow.currentStep = nextStep.taskType;
    
    const agent = this.agents.get(nextStep.agentId);
    if (!agent) {
      nextStep.status = 'failed';
      nextStep.error = 'Agent not found';
      this.executeNextStep(workflowId);
      return;
    }
    
    // Prepare task payload
    const taskPayload = this.prepareTaskPayload(workflow, nextStep);
    
    // Send task to agent
    const message: Message = {
      id: uuidv4(),
      type: 'task-assignment',
      from: 'orchestrator',
      to: agent.id,
      payload: {
        id: nextStep.id,
        type: nextStep.taskType,
        payload: taskPayload,
        priority: workflow.request.options?.priority
      },
      timestamp: new Date()
    };
    
    await this.messageBus.publish(message);
    
    this.logger.info('Task assigned', {
      workflowId,
      stepId: nextStep.id,
      agentId: agent.id,
      taskType: nextStep.taskType
    });
  }

  private prepareTaskPayload(
    workflow: ResearchWorkflow, 
    step: WorkflowStep
  ): any {
    const basePayload: any = {};
    
    if (step.taskType === 'research') {
      return {
        query: workflow.request.query,
        sources: workflow.request.scope?.sources,
        maxResults: workflow.request.scope?.maxResults
      };
    }
    
    if (step.taskType.startsWith('analyze')) {
      const researchResult = workflow.steps
        .find(s =&gt; s.taskType === 'research')?.result;
      
      return {
        data: researchResult?.sources || [],
        analysisType: step.taskType.replace('analyze-', '')
      };
    }
    
    if (step.taskType === 'synthesize') {
      const researchResult = workflow.steps
        .find(s =&gt; s.taskType === 'research')?.result;
      
      const analysisResults = workflow.steps
        .filter(s =&gt; s.taskType.startsWith('analyze'))
        .map(s =&gt; s.result)
        .filter(Boolean);
      
      return {
        researchResults: researchResult,
        analysisResults: analysisResults[0], // Simplified
        context: {
          objective: workflow.request.objective,
          audience: 'general',
          format: workflow.request.options?.outputFormat || 'detailed'
        }
      };
    }
    
    return basePayload;
  }

  private handleTaskCompleted(result: any): void {
    // Find workflow and step
    for (const [workflowId, workflow] of this.workflows) {
      const step = workflow.steps.find(s =&gt; s.id === result.taskId);
      
      if (step) {
        step.status = 'completed';
        step.result = result.result;
        
        workflow.results.set(step.taskType, result.result);
        
        this.logger.info('Task completed', {
          workflowId,
          stepId: step.id,
          taskType: step.taskType
        });
        
        this.emit('step-completed', {
          workflowId,
          step,
          result: result.result
        });
        
        // Execute next step
        this.executeNextStep(workflowId);
        
        break;
      }
    }
  }

  private handleTaskFailed(result: any): void {
    // Find workflow and step
    for (const [workflowId, workflow] of this.workflows) {
      const step = workflow.steps.find(s =&gt; s.id === result.taskId);
      
      if (step) {
        step.status = 'failed';
        step.error = result.error;
        
        this.logger.error('Task failed', {
          workflowId,
          stepId: step.id,
          taskType: step.taskType,
          error: result.error
        });
        
        this.emit('step-failed', {
          workflowId,
          step,
          error: result.error
        });
        
        // Decide whether to continue or fail workflow
        if (step.taskType === 'research') {
          // Critical failure - fail entire workflow
          this.failWorkflow(workflowId, 'Research step failed');
        } else {
          // Try to continue with other steps
          this.executeNextStep(workflowId);
        }
        
        break;
      }
    }
  }

  private completeWorkflow(workflowId: string): void {
    const workflow = this.workflows.get(workflowId);
    if (!workflow) return;
    
    workflow.status = 'completed';
    workflow.endTime = new Date();
    
    const duration = workflow.endTime.getTime() - workflow.startTime.getTime();
    
    this.logger.info('Workflow completed', {
      workflowId,
      duration,
      steps: workflow.steps.length
    });
    
    // Compile final result
    const finalResult = {
      request: workflow.request,
      results: Object.fromEntries(workflow.results),
      summary: workflow.results.get('synthesize'),
      duration,
      completedAt: workflow.endTime
    };
    
    this.emit('workflow-completed', {
      workflowId,
      result: finalResult
    });
  }

  private failWorkflow(workflowId: string, error: string): void {
    const workflow = this.workflows.get(workflowId);
    if (!workflow) return;
    
    workflow.status = 'failed';
    workflow.error = error;
    workflow.endTime = new Date();
    
    this.logger.error('Workflow failed', {
      workflowId,
      error
    });
    
    this.emit('workflow-failed', {
      workflowId,
      error
    });
  }

  private setupMessageHandlers(): void {
    // Additional message handling if needed
  }

  async getWorkflowStatus(workflowId: string): Promise<any> {
    const workflow = this.workflows.get(workflowId);
    if (!workflow) {
      throw new Error(`Workflow not found: ${workflowId}`);
    }
    
    return {
      id: workflow.id,
      status: workflow.status,
      currentStep: workflow.currentStep,
      progress: {
        total: workflow.steps.length,
        completed: workflow.steps.filter(s =&gt; s.status === 'completed').length,
        failed: workflow.steps.filter(s =&gt; s.status === 'failed').length
      },
      startTime: workflow.startTime,
      endTime: workflow.endTime,
      results: workflow.status === 'completed' ? 
        Object.fromEntries(workflow.results) : undefined
    };
  }

  async shutdown(): Promise<void> {
    // Stop all agents
    await Promise.all(
      Array.from(this.agents.values()).map(agent =&gt; agent.stop())
    );
    
    // Shutdown message bus
    await this.messageBus.shutdown();
    
    this.removeAllListeners();
  }
}
```

### Step 8: Create Demo Application

Create `src/demo.ts`:
```typescript
import { ResearchOrchestrator, ResearchRequest } from './orchestrator/ResearchOrchestrator';
import dotenv from 'dotenv';

dotenv.config();

async function demonstrateResearchSystem() {
  console.log('🔬 Research Assistant System Demo\n');
  
  const orchestrator = new ResearchOrchestrator(
    process.env.REDIS_URL || 'redis://localhost:6379'
  );
  
  // Setup event handlers
  orchestrator.on('workflow-started', ({ workflowId, request }) =&gt; {
    console.log(`📋 Workflow started: ${workflowId}`);
    console.log(`   Query: ${request.query}`);
    console.log(`   Objective: ${request.objective}\n`);
  });
  
  orchestrator.on('step-completed', ({ workflowId, step }) =&gt; {
    console.log(`✅ Step completed: ${step.taskType}`);
  });
  
  orchestrator.on('workflow-completed', ({ workflowId, result }) =&gt; {
    console.log(`\n🎉 Workflow completed: ${workflowId}`);
    console.log(`   Duration: ${result.duration}ms`);
    
    if (result.summary) {
      console.log('\n📊 Executive Summary:');
      console.log(result.summary.summary?.executive);
      
      console.log('\n🔍 Key Findings:');
      result.summary.keyFindings?.forEach((finding: any, index: number) =&gt; {
        console.log(`${index + 1}. ${finding.finding} (${finding.importance})`);
      });
      
      console.log('\n📌 Conclusions:');
      result.summary.conclusions?.forEach((conclusion: string) =&gt; {
        console.log(`- ${conclusion}`);
      });
      
      console.log('\n👉 Next Steps:');
      result.summary.nextSteps?.forEach((step: string) =&gt; {
        console.log(`- ${step}`);
      });
    }
  });
  
  orchestrator.on('workflow-failed', ({ workflowId, error }) =&gt; {
    console.error(`❌ Workflow failed: ${workflowId}`);
    console.error(`   Error: ${error}`);
  });
  
  // Create research request
  const request: ResearchRequest = {
    query: 'Impact of AI on software development productivity',
    objective: 'Understand how AI tools like GitHub Copilot affect developer productivity',
    scope: {
      sources: ['web', 'academic', 'news'],
      maxResults: 10
    },
    options: {
      analysisTypes: ['statistical', 'trend'],
      outputFormat: 'detailed',
      priority: 2
    }
  };
  
  try {
    // Start the workflow
    const workflowId = await orchestrator.startWorkflow(request);
    
    // Poll for status
    const pollInterval = setInterval(async () =&gt; {
      const status = await orchestrator.getWorkflowStatus(workflowId);
      
      console.log(`\n📈 Progress: ${status.progress.completed}/${status.progress.total} steps`);
      
      if (status.status === 'completed' || status.status === 'failed') {
        clearInterval(pollInterval);
        
        // Shutdown
        setTimeout(async () =&gt; {
          await orchestrator.shutdown();
          console.log('\n👋 System shutdown complete');
          process.exit(0);
        }, 2000);
      }
    }, 2000);
    
  } catch (error) {
    console.error('Demo error:', error);
    await orchestrator.shutdown();
    process.exit(1);
  }
}

// Run the demo
demonstrateResearchSystem().catch(console.error);
```

### Step 9: Add Scripts and Configuration

Actualizar `package.json`:
```json
{
  "scripts": {
    "build": "tsc",
    "start": "node dist/demo.js",
    "dev": "nodemon --exec ts-node src/demo.ts",
    "test": "jest",
    "start-redis": "docker run -d -p 6379:6379 redis:7-alpine",
    "lint": "eslint src/**/*.ts",
    "format": "prettier --write src/**/*.ts"
  }
}
```

## 🏃 Running the ReBuscar System

1. **Start Redis:**
```bash
npm run start-redis
# Or if already installed locally:
redis-server
```

2. **Build and run:**
```bash
npm run build
npm start
```

## 🎯 Validation

Your Research Assistant System should now:
- ✅ Have specialized agents working together
- ✅ Coordinate tasks through the orchestrator
- ✅ Communicate via message bus
- ✅ Execute multi-step research workflows
- ✅ Synthesize findings from multiple sources
- ✅ Handle failures gracefully
- ✅ Provide comprehensive research results

## 📚 Additional Recursos

- [Multi-Agent Systems](https://www.cs.cmu.edu/~softagents/multi.html)
- [Workflow Patterns](https://www.workflowpatterns.com/)
- [Message-Driven Architecture](https://www.enterpriseintegrationpatterns.com/patterns/messaging/)

## ⏭️ Siguiente Ejercicio

Ready to build more complex workflows? Move on to [Ejercicio 2: Content Generation Pipeline](/docs/modules/module-24/exercise2-overview) where you'll create a complete content creation system!