---
sidebar_position: 2
title: "Exercise 2: Part 1"
description: "## 🎯 Objective"
---

# Ejercicio 2: Content Generation Pipeline (⭐⭐ Medio - 45 minutos)

## 🎯 Objective
Build a multi-agent content generation pipeline where specialized agents collaborate to create, edit, optimize, and publish high-quality content through a structured workflow.

## 🧠 Lo Que Aprenderás
- Pipeline architecture for content generation
- Agent specialization for creative tasks
- Quality control through multi-stage review
- Content optimization strategies
- Workflow state management
- Publishing automation

## 📋 Prerrequisitos
- Completard Ejercicio 1
- Understanding of content workflows
- Familiarity with LLM APIs
- Basic knowledge of content management

## 📚 Atrásground

A Content Generation Pipeline demonstrates how multiple AI agents can collaborate to produce high-quality content more effectively than a single agent. The pipeline includes:

- **Content Planner**: Outlines structure and key points
- **Writer Agent**: Creates initial content draft
- **Editaror Agent**: Revisars and improves content
- **SEO Agent**: Optimizes for search and engagement
- **Publisher Agent**: Formats and publishes content

Each stage adds value while maintaining consistency and quality.

## 🏗️ Architecture Resumen

```mermaid
graph LR
    subgraph "Content Pipeline"
        A[Pipeline Orchestrator] --&gt; B[Content Queue]
        
        B --&gt; C[Content Planner]
        C --&gt; D[Writer Agent]
        D --&gt; E[Editor Agent]
        E --&gt; F[SEO Agent]
        F --&gt; G[Publisher Agent]
        
        H[Quality Gate] --&gt; D
        H --&gt; E
        H --&gt; F
        
        I[Content Store] --&gt; C
        I --&gt; D
        I --&gt; E
        I --&gt; F
        I --&gt; G
        
        J[Analytics] --&gt; A
        J --&gt; F
    end
    
    K[Content Request] --&gt; A
    G --&gt; L[Published Content]
    
    style A fill:#4CAF50
    style H fill:#FF9800
    style I fill:#2196F3
    style J fill:#9C27B0
```

## 🛠️ Step-by-Step Instructions

### Step 1: Project Setup

**Copilot Prompt Suggestion:**
```typescript
// Create a TypeScript project for a content generation pipeline that:
// - Has specialized agents for planning, writing, editing, SEO, and publishing
// - Implements quality gates between stages
// - Manages content state throughout the pipeline
// - Includes version control for content iterations
// - Provides analytics and performance tracking
// - Supports multiple content types and formats
```

1. **Initialize the project:**
```bash
mkdir content-generation-pipeline
cd content-generation-pipeline
npm init -y
```

2. **Install dependencies:**
```bash
# Core dependencies
npm install \
  bull \
  ioredis \
  @langchain/core \
  @langchain/openai \
  zod \
  gray-matter \
  markdown-it

# Content processing
npm install \
  natural \
  keyword-extractor \
  reading-time \
  string-similarity

# Publishing and formatting
npm install \
  @octokit/rest \
  wordpress-api \
  medium-sdk

# Utilities
npm install \
  winston \
  dotenv \
  node-cache \
  p-queue

# Development dependencies
npm install --save-dev \
  typescript \
  @types/node \
  ts-node \
  nodemon \
  jest \
  @types/jest
```

3. **Create directory structure:**
```bash
mkdir -p src/{agents,pipeline,quality,storage,publishing,analytics,utils}
mkdir -p tests/{unit,integration}
mkdir -p content/{drafts,published,templates}
```

### Step 2: Define Content Pipeline Base

**Copilot Prompt Suggestion:**
```typescript
// Create a content pipeline base that:
// - Defines content stages and transitions
// - Manages pipeline state and flow
// - Implements quality checkpoints
// - Tracks content versions
// - Handles rollbacks and corrections
// - Provides pipeline analytics
```

Create `src/pipeline/ContentPipeline.ts`:
```typescript
import { EventEmitter } from 'events';
import Bull from 'bull';
import { z } from 'zod';
import winston from 'winston';
import { v4 as uuidv4 } from 'uuid';

// Content schema definition
export const ContentSchema = z.object({
  id: z.string(),
  type: z.enum(['blog', 'article', 'social', 'newsletter', 'documentation']),
  topic: z.string(),
  keywords: z.array(z.string()),
  targetAudience: z.string(),
  tone: z.enum(['formal', 'casual', 'technical', 'friendly', 'professional']),
  length: z.object({
    min: z.number(),
    max: z.number()
  }),
  requirements: z.array(z.string()).optional(),
  metadata: z.record(z.any()).optional()
});

export type ContentRequest = z.infer<typeof ContentSchema>;

export interface ContentVersion {
  version: number;
  stage: ContentStage;
  content: string;
  metadata: Record<string, any>;
  createdBy: string;
  createdAt: Date;
  changes?: string;
}

export enum ContentStage {
  REQUEST = 'request',
  PLANNING = 'planning',
  WRITING = 'writing',
  EDITING = 'editing',
  SEO_OPTIMIZATION = 'seo_optimization',
  REVIEW = 'review',
  PUBLISHING = 'publishing',
  PUBLISHED = 'published',
  FAILED = 'failed'
}

export interface PipelineJob {
  id: string;
  contentId: string;
  stage: ContentStage;
  request: ContentRequest;
  versions: ContentVersion[];
  currentVersion: number;
  status: 'active' | 'completed' | 'failed' | 'paused';
  startTime: Date;
  endTime?: Date;
  metrics: {
    stagesDuration: Record<string, number>;
    qualityScores: Record<string, number>;
    revisions: number;
  };
}

export interface QualityCheckResult {
  passed: boolean;
  score: number;
  issues: Array<{
    type: string;
    severity: 'low' | 'medium' | 'high';
    message: string;
    suggestion?: string;
  }>;
}

export class ContentPipeline extends EventEmitter {
  private queues: Map<ContentStage, Bull.Queue> = new Map();
  private jobs: Map<string, PipelineJob> = new Map();
  private logger: winston.Logger;
  private redisUrl: string;

  constructor(redisUrl: string) {
    super();
    
    this.redisUrl = redisUrl;
    this.logger = winston.createLogger({
      level: 'info',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
      ),
      defaultMeta: { service: 'content-pipeline' }
    });
    
    this.initializeQueues();
  }

  private initializeQueues(): void {
    const stages = Object.values(ContentStage);
    
    stages.forEach(stage =&gt; {
      if (stage !== ContentStage.REQUEST && stage !== ContentStage.FAILED) {
        const queue = new Bull(`content-${stage}`, this.redisUrl, {
          defaultJobOptions: {
            attempts: 3,
            backoff: {
              type: 'exponential',
              delay: 2000
            }
          }
        });
        
        this.queues.set(stage, queue);
        
        // Setup queue event handlers
        queue.on('completed', (job, result) =&gt; {
          this.handleStageCompleted(stage, job, result);
        });
        
        queue.on('failed', (job, err) =&gt; {
          this.handleStageFailed(stage, job, err);
        });
      }
    });
  }

  async submitContent(request: ContentRequest): Promise<string> {
    // Validate request
    const validated = ContentSchema.parse(request);
    
    const jobId = validated.id || uuidv4();
    
    // Create pipeline job
    const job: PipelineJob = {
      id: jobId,
      contentId: jobId,
      stage: ContentStage.REQUEST,
      request: validated,
      versions: [],
      currentVersion: 0,
      status: 'active',
      startTime: new Date(),
      metrics: {
        stagesDuration: {},
        qualityScores: {},
        revisions: 0
      }
    };
    
    this.jobs.set(jobId, job);
    
    this.logger.info('Content submitted to pipeline', {
      jobId,
      type: validated.type,
      topic: validated.topic
    });
    
    // Start pipeline with planning stage
    await this.moveToStage(jobId, ContentStage.PLANNING);
    
    this.emit('content-submitted', { jobId, request: validated });
    
    return jobId;
  }

  private async moveToStage(jobId: string, stage: ContentStage): Promise<void> {
    const job = this.jobs.get(jobId);
    if (!job) {
      throw new Error(`Job not found: ${jobId}`);
    }
    
    const previousStage = job.stage;
    job.stage = stage;
    
    // Record stage duration
    if (previousStage !== ContentStage.REQUEST) {
      const duration = Date.now() - this.getStageStartTime(job, previousStage);
      job.metrics.stagesDuration[previousStage] = duration;
    }
    
    // Add to appropriate queue
    const queue = this.queues.get(stage);
    if (queue) {
      await queue.add({
        jobId,
        stage,
        content: job.versions[job.currentVersion - 1]?.content || '',
        request: job.request,
        previousStage
      });
      
      this.logger.info('Job moved to stage', {
        jobId,
        stage,
        previousStage
      });
      
      this.emit('stage-transition', {
        jobId,
        from: previousStage,
        to: stage
      });
    }
  }

  private getStageStartTime(job: PipelineJob, stage: ContentStage): number {
    // Calculate based on previous stages duration
    let totalDuration = job.startTime.getTime();
    
    const stageOrder = [
      ContentStage.PLANNING,
      ContentStage.WRITING,
      ContentStage.EDITING,
      ContentStage.SEO_OPTIMIZATION,
      ContentStage.REVIEW,
      ContentStage.PUBLISHING
    ];
    
    for (const s of stageOrder) {
      if (s === stage) break;
      totalDuration += job.metrics.stagesDuration[s] || 0;
    }
    
    return totalDuration;
  }

  async addContentVersion(
    jobId: string, 
    content: string, 
    metadata: Record<string, any>,
    agentId: string,
    changes?: string
  ): Promise<void> {
    const job = this.jobs.get(jobId);
    if (!job) {
      throw new Error(`Job not found: ${jobId}`);
    }
    
    const version: ContentVersion = {
      version: job.versions.length + 1,
      stage: job.stage,
      content,
      metadata,
      createdBy: agentId,
      createdAt: new Date(),
      changes
    };
    
    job.versions.push(version);
    job.currentVersion = version.version;
    
    this.logger.info('Content version added', {
      jobId,
      version: version.version,
      stage: job.stage,
      contentLength: content.length
    });
    
    this.emit('version-created', {
      jobId,
      version
    });
  }

  async performQualityCheck(
    jobId: string, 
    stage: ContentStage
  ): Promise<QualityCheckResult> {
    const job = this.jobs.get(jobId);
    if (!job) {
      throw new Error(`Job not found: ${jobId}`);
    }
    
    const content = job.versions[job.currentVersion - 1]?.content || '';
    const result = await this.runQualityChecks(content, stage, job.request);
    
    // Record quality score
    job.metrics.qualityScores[stage] = result.score;
    
    this.logger.info('Quality check performed', {
      jobId,
      stage,
      passed: result.passed,
      score: result.score,
      issues: result.issues.length
    });
    
    this.emit('quality-check', {
      jobId,
      stage,
      result
    });
    
    return result;
  }

  private async runQualityChecks(
    content: string, 
    stage: ContentStage,
    request: ContentRequest
  ): Promise<QualityCheckResult> {
    const issues: any[] = [];
    let score = 100;
    
    // Basic checks
    if (!content || content.trim().length === 0) {
      issues.push({
        type: 'empty-content',
        severity: 'high',
        message: 'Content is empty'
      });
      score = 0;
    }
    
    // Length check
    const wordCount = content.split(/\s+/).length;
    if (wordCount &lt; request.length.min) {
      issues.push({
        type: 'too-short',
        severity: 'medium',
        message: `Content is ${request.length.min - wordCount} words short`,
        suggestion: 'Expand on key points'
      });
      score -= 20;
    } else if (wordCount &gt; request.length.max) {
      issues.push({
        type: 'too-long',
        severity: 'low',
        message: `Content exceeds limit by ${wordCount - request.length.max} words`,
        suggestion: 'Consider trimming redundant sections'
      });
      score -= 10;
    }
    
    // Stage-specific checks
    switch (stage) {
      case ContentStage.WRITING:
        // Check for structure
        if (!content.includes('#') && request.type !== 'social') {
          issues.push({
            type: 'no-structure',
            severity: 'medium',
            message: 'Content lacks proper heading structure'
          });
          score -= 15;
        }
        break;
        
      case ContentStage.EDITING:
        // Check for grammar issues (simplified)
        const grammarPatterns = [
          /\s{\`2,\`}/g, // Multiple spaces
          /[.?!]{\`2,\`}/g, // Multiple punctuation
          /\b(\w+)\s+\1\b/gi // Repeated words
        ];
        
        grammarPatterns.forEach(pattern =&gt; {
          if (pattern.test(content)) {
            issues.push({
              type: 'grammar',
              severity: 'low',
              message: 'Grammar issues detected',
              suggestion: 'Review grammar and punctuation'
            });
            score -= 5;
          }
        });
        break;
        
      case ContentStage.SEO_OPTIMIZATION:
        // Check keyword usage
        const contentLower = content.toLowerCase();
        const missingKeywords = request.keywords.filter(keyword =&gt; 
          !contentLower.includes(keyword.toLowerCase())
        );
        
        if (missingKeywords.length &gt; 0) {
          issues.push({
            type: 'missing-keywords',
            severity: 'medium',
            message: `Missing keywords: ${missingKeywords.join(', ')}`,
            suggestion: 'Naturally incorporate missing keywords'
          });
          score -= 5 * missingKeywords.length;
        }
        break;
    }
    
    return {
      passed: score &gt;= 70,
      score: Math.max(0, score),
      issues
    };
  }

  private async handleStageCompleted(
    stage: ContentStage, 
    job: Bull.Job, 
    result: any
  ): Promise<void> {
    const jobId = job.data.jobId;
    const pipelineJob = this.jobs.get(jobId);
    
    if (!pipelineJob) return;
    
    this.logger.info('Stage completed', {
      jobId,
      stage,
      duration: Date.now() - job.processedOn!
    });
    
    // Determine next stage
    const nextStage = this.getNextStage(stage, pipelineJob);
    
    if (nextStage) {
      await this.moveToStage(jobId, nextStage);
    } else {
      // Pipeline completed
      this.completePipeline(jobId);
    }
  }

  private getNextStage(
    currentStage: ContentStage, 
    job: PipelineJob
  ): ContentStage | null {
    const stageFlow: Record<ContentStage, ContentStage | null> = {
      [ContentStage.REQUEST]: ContentStage.PLANNING,
      [ContentStage.PLANNING]: ContentStage.WRITING,
      [ContentStage.WRITING]: ContentStage.EDITING,
      [ContentStage.EDITING]: ContentStage.SEO_OPTIMIZATION,
      [ContentStage.SEO_OPTIMIZATION]: ContentStage.REVIEW,
      [ContentStage.REVIEW]: ContentStage.PUBLISHING,
      [ContentStage.PUBLISHING]: ContentStage.PUBLISHED,
      [ContentStage.PUBLISHED]: null,
      [ContentStage.FAILED]: null
    };
    
    return stageFlow[currentStage];
  }

  private async handleStageFailed(
    stage: ContentStage, 
    job: Bull.Job, 
    error: Error
  ): Promise<void> {
    const jobId = job.data.jobId;
    const pipelineJob = this.jobs.get(jobId);
    
    if (!pipelineJob) return;
    
    this.logger.error('Stage failed', {
      jobId,
      stage,
      error: error.message,
      attempts: job.attemptsMade
    });
    
    if (job.attemptsMade &gt;= 3) {
      // Max retries reached
      pipelineJob.status = 'failed';
      pipelineJob.stage = ContentStage.FAILED;
      pipelineJob.endTime = new Date();
      
      this.emit('pipeline-failed', {
        jobId,
        stage,
        error: error.message
      });
    }
  }

  private completePipeline(jobId: string): void {
    const job = this.jobs.get(jobId);
    if (!job) return;
    
    job.status = 'completed';
    job.endTime = new Date();
    
    const totalDuration = job.endTime.getTime() - job.startTime.getTime();
    
    this.logger.info('Pipeline completed', {
      jobId,
      totalDuration,
      versions: job.versions.length,
      finalScore: job.metrics.qualityScores[ContentStage.REVIEW] || 0
    });
    
    this.emit('pipeline-completed', {
      jobId,
      content: job.versions[job.currentVersion - 1].content,
      metrics: job.metrics,
      duration: totalDuration
    });
  }

  async getJobStatus(jobId: string): Promise<any> {
    const job = this.jobs.get(jobId);
    if (!job) {
      throw new Error(`Job not found: ${jobId}`);
    }
    
    return {
      id: job.id,
      stage: job.stage,
      status: job.status,
      currentVersion: job.currentVersion,
      versions: job.versions.length,
      startTime: job.startTime,
      endTime: job.endTime,
      metrics: job.metrics,
      progress: this.calculateProgress(job)
    };
  }

  private calculateProgress(job: PipelineJob): number {
    const stages = [
      ContentStage.PLANNING,
      ContentStage.WRITING,
      ContentStage.EDITING,
      ContentStage.SEO_OPTIMIZATION,
      ContentStage.REVIEW,
      ContentStage.PUBLISHING,
      ContentStage.PUBLISHED
    ];
    
    const currentIndex = stages.indexOf(job.stage);
    return currentIndex &gt;= 0 ? ((currentIndex + 1) / stages.length) * 100 : 0;
  }

  async shutdown(): Promise<void> {
    for (const queue of this.queues.values()) {
      await queue.close();
    }
    
    this.removeAllListeners();
  }
}
```

### Step 3: Implement Content Planner Agent

**Copilot Prompt Suggestion:**
```typescript
// Create a content planner agent that:
// - Analyzes content requirements and topic
// - Creates detailed content outline
// - Identifies key points to cover
// - Suggests content structure and flow
// - Determines optimal content format
// - Provides research references
```

Create `src/agents/ContentPlannerAgent.ts`:
```typescript
import { BaseAgent } from '../../exercise1-research-system/src/agents/BaseAgent';
import { ChatOpenAI } from '@langchain/openai';
import { SystemMessage, HumanMessage } from '@langchain/core/messages';
import { ContentRequest } from '../pipeline/ContentPipeline';
import { z } from 'zod';

const ContentOutlineSchema = z.object({
  title: z.string(),
  subtitle: z.string().optional(),
  introduction: z.object({
    hook: z.string(),
    context: z.string(),
    thesis: z.string()
  }),
  sections: z.array(z.object({
    heading: z.string(),
    keyPoints: z.array(z.string()),
    supportingDetails: z.array(z.string()).optional(),
    callToAction: z.string().optional()
  })),
  conclusion: z.object({
    summary: z.string(),
    callToAction: z.string(),
    nextSteps: z.array(z.string()).optional()
  }),
  keywords: z.array(z.string()),
  references: z.array(z.string()).optional(),
  estimatedReadTime: z.number()
});

export type ContentOutline = z.infer<typeof ContentOutlineSchema>;

export class ContentPlannerAgent extends BaseAgent {
  private llm: ChatOpenAI;

  constructor() {
    super({
      name: 'ContentPlannerAgent',
      capabilities: ['plan-content', 'create-outline', 'structure-content']
    });
    
    this.llm = new ChatOpenAI({
      modelName: 'gpt-4',
      temperature: 0.7,
      maxTokens: 2000
    });
  }

  protected async execute(task: any): Promise<ContentOutline> {
    const request = task.payload.request as ContentRequest;
    
    this.logger.info('Planning content', {
      type: request.type,
      topic: request.topic,
      targetLength: `${request.length.min}-${request.length.max} words`
    });
    
    // Create planning prompt
    const systemPrompt = this.createSystemPrompt(request);
    const userPrompt = this.createUserPrompt(request);
    
    // Generate outline
    const response = await this.llm.invoke([
      new SystemMessage(systemPrompt),
      new HumanMessage(userPrompt)
    ]);
    
    // Parse and validate outline
    const outline = this.parseOutline(response.content as string, request);
    
    // Enhance with additional planning
    const enhancedOutline = await this.enhanceOutline(outline, request);
    
    return enhancedOutline;
  }

  private createSystemPrompt(request: ContentRequest): string {
    return `You are an expert content strategist specializing in creating detailed content outlines.
    
Your task is to create a comprehensive outline for ${request.type} content that:
1. Addresses the topic thoroughly
2. Engages the ${request.targetAudience} audience
3. Maintains a ${request.tone} tone
4. Incorporates the keywords naturally
5. Meets the length requirements (${request.length.min}-${request.length.max} words)

Format your response as a structured outline with clear sections and key points.`;
  }

  private createUserPrompt(request: ContentRequest): string {
    let prompt = `Create a detailed outline for the following content:

Topic: ${request.topic}
Type: ${request.type}
Target Audience: ${request.targetAudience}
Tone: ${request.tone}
Keywords to include: ${request.keywords.join(', ')}`;

    if (request.requirements && request.requirements.length &gt; 0) {
      prompt += `\n\nSpecific requirements:\n${request.requirements.map(r =&gt; `- ${r}`).join('\n')}`;
    }

    prompt += `\n\nProvide a complete outline with:
1. Compelling title and subtitle
2. Introduction with hook, context, and thesis
3. Main sections with key points and supporting details
4. Strong conclusion with call to action
5. Estimated reading time`;

    return prompt;
  }

  private parseOutline(response: string, request: ContentRequest): ContentOutline {
    // In production, use more sophisticated parsing
    // This is a simplified version
    const sections = [];
    
    // Extract sections from response
    const sectionMatches = response.match(/## .+/g) || [];
    
    for (let i = 0; i &lt; Math.min(sectionMatches.length, 5); i++) {
      sections.push({
        heading: sectionMatches[i].replace('## ', ''),
        keyPoints: [
          `Key point 1 for section ${i + 1}`,
          `Key point 2 for section ${i + 1}`,
          `Key point 3 for section ${i + 1}`
        ],
        supportingDetails: [
          `Supporting detail for section ${i + 1}`
        ]
      });
    }
    
    // Estimate reading time based on target length
    const avgReadingSpeed = 200; // words per minute
    const estimatedWords = (request.length.min + request.length.max) / 2;
    const estimatedReadTime = Math.ceil(estimatedWords / avgReadingSpeed);
    
    return {
      title: `${request.topic}: A Comprehensive Guide`,
      subtitle: `Everything ${request.targetAudience} needs to know`,
      introduction: {
        hook: `Discover the essential insights about ${request.topic}`,
        context: `In today's landscape, understanding ${request.topic} is crucial`,
        thesis: `This ${request.type} will provide you with actionable insights`
      },
      sections: sections.length &gt; 0 ? sections : [
        {
          heading: 'Understanding the Basics',
          keyPoints: ['Foundation concepts', 'Core principles', 'Key terminology']
        },
        {
          heading: 'Practical Applications',
          keyPoints: ['Real-world examples', 'Best practices', 'Common use cases']
        },
        {
          heading: 'Advanced Considerations',
          keyPoints: ['Expert insights', 'Future trends', 'Optimization strategies']
        }
      ],
      conclusion: {
        summary: `Key takeaways about ${request.topic}`,
        callToAction: 'Start implementing these insights today',
        nextSteps: ['Apply the concepts', 'Share with your team', 'Continue learning']
      },
      keywords: request.keywords,
      references: ['Industry reports', 'Expert interviews', 'Case studies'],
      estimatedReadTime
    };
  }

  private async enhanceOutline(
    outline: ContentOutline, 
    request: ContentRequest
  ): Promise<ContentOutline> {
    // Add keyword distribution across sections
    const keywordsPerSection = Math.ceil(request.keywords.length / outline.sections.length);
    
    outline.sections.forEach((section, index) =&gt; {
      const startIdx = index * keywordsPerSection;
      const endIdx = startIdx + keywordsPerSection;
      const sectionKeywords = request.keywords.slice(startIdx, endIdx);
      
      // Add keywords to section details
      if (!section.supportingDetails) {
        section.supportingDetails = [];
      }
      
      section.supportingDetails.push(
        `Focus keywords: ${sectionKeywords.join(', ')}`
      );
    });
    
    // Add content-type specific enhancements
    switch (request.type) {
      case 'blog':
        outline.sections.push({
          heading: 'Frequently Asked Questions',
          keyPoints: ['Common queries', 'Expert answers', 'Additional resources']
        });
        break;
        
      case 'documentation':
        outline.sections.unshift({
          heading: 'Prerequisites',
          keyPoints: ['Required knowledge', 'Setup instructions', 'Environment requirements']
        });
        break;
        
      case 'social':
        // Simplify for social media
        outline.sections = outline.sections.slice(0, 2);
        break;
    }
    
    return outline;
  }
}
```

### Step 4: Implement Writer Agent

Create `src/agents/WriterAgent.ts`:
```typescript
import { BaseAgent } from '../../exercise1-research-system/src/agents/BaseAgent';
import { ChatOpenAI } from '@langchain/openai';
import { SystemMessage, HumanMessage } from '@langchain/core/messages';
import { ContentOutline } from './ContentPlannerAgent';
import { ContentRequest } from '../pipeline/ContentPipeline';

export class WriterAgent extends BaseAgent {
  private llm: ChatOpenAI;

  constructor() {
    super({
      name: 'WriterAgent',
      capabilities: ['write-content', 'generate-text', 'create-draft']
    });
    
    this.llm = new ChatOpenAI({
      modelName: 'gpt-4',
      temperature: 0.8,
      maxTokens: 4000
    });
  }

  protected async execute(task: any): Promise<string> {
    const outline = task.payload.outline as ContentOutline;
    const request = task.payload.request as ContentRequest;
    const previousContent = task.payload.content as string;
    
    this.logger.info('Writing content', {
      sections: outline.sections.length,
      targetLength: `${request.length.min}-${request.length.max} words`
    });
    
    // Generate content section by section
    const sections: string[] = [];
    
    // Write introduction
    const intro = await this.writeIntroduction(outline, request);
    sections.push(intro);
    
    // Write main sections
    for (const section of outline.sections) {
      const sectionContent = await this.writeSection(section, request, outline);
      sections.push(sectionContent);
      
      // Check length periodically
      const currentLength = sections.join('\n\n').split(/\s+/).length;
      if (currentLength &gt; request.length.max) {
        break;
      }
    }
    
    // Write conclusion
    const conclusion = await this.writeConclusion(outline, request);
    sections.push(conclusion);
    
    // Combine and format
    const fullContent = this.formatContent(
      sections,
      outline,
      request
    );
    
    return fullContent;
  }

  private async writeIntroduction(
    outline: ContentOutline,
    request: ContentRequest
  ): Promise<string> {
    const prompt = `Write an engaging introduction for a ${request.type} about "${outline.title}".

Hook: ${outline.introduction.hook}
Context: ${outline.introduction.context}
Thesis: ${outline.introduction.thesis}

Target audience: ${request.targetAudience}
Tone: ${request.tone}

The introduction should:
1. Grab attention immediately
2. Establish relevance for the reader
3. Preview what's to come
4. Be approximately 150-200 words`;

    const response = await this.llm.invoke([
      new SystemMessage('You are an expert content writer.'),
      new HumanMessage(prompt)
    ]);
    
    return response.content as string;
  }

  private async writeSection(
    section: any,
    request: ContentRequest,
    outline: ContentOutline
  ): Promise<string> {
    const prompt = `Write a section for a ${request.type} with the following details:

Section heading: ${section.heading}
Key points to cover:
${section.keyPoints.map((p: string) =&gt; `- ${p}`).join('\n')}

${section.supportingDetails ? `Supporting details:\n${section.supportingDetails.map((d: string) =&gt; `- ${d}`).join('\n')}` : ''}

Target audience: ${request.targetAudience}
Tone: ${request.tone}

The section should:
1. Be informative and engaging
2. Include specific examples where relevant
3. Maintain consistent tone
4. Be approximately 200-300 words`;

    const response = await this.llm.invoke([
      new SystemMessage('You are an expert content writer.'),
      new HumanMessage(prompt)
    ]);
    
    return `## ${section.heading}\n\n${response.content}`;
  }

  private async writeConclusion(
    outline: ContentOutline,
    request: ContentRequest
  ): Promise<string> {
    const prompt = `Write a compelling conclusion for a ${request.type} about "${outline.title}".

Summary points: ${outline.conclusion.summary}
Call to action: ${outline.conclusion.callToAction}
${outline.conclusion.nextSteps ? `Next steps: ${outline.conclusion.nextSteps.join(', ')}` : ''}

Target audience: ${request.targetAudience}
Tone: ${request.tone}

The conclusion should:
1. Summarize key insights
2. Reinforce the main message
3. Motivate action
4. Be approximately 100-150 words`;

    const response = await this.llm.invoke([
      new SystemMessage('You are an expert content writer.'),
      new HumanMessage(prompt)
    ]);
    
    return `## Conclusion\n\n${response.content}`;
  }

  private formatContent(
    sections: string[],
    outline: ContentOutline,
    request: ContentRequest
  ): string {
    let content = '';
    
    // Add title and subtitle
    content += `# ${outline.title}\n\n`;
    if (outline.subtitle) {
      content += `*${outline.subtitle}*\n\n`;
    }
    
    // Add metadata for certain content types
    if (request.type === 'blog' || request.type === 'article') {
      content += `---\n`;
      content += `reading_time: ${outline.estimatedReadTime} min\n`;
      content += `keywords: ${outline.keywords.join(', ')}\n`;
      content += `---\n\n`;
    }
    
    // Add sections
    content += sections.join('\n\n');
    
    // Add references if available
    if (outline.references && outline.references.length &gt; 0) {
      content += '\n\n## References\n\n';
      outline.references.forEach((ref, index) =&gt; {
        content += `${index + 1}. ${ref}\n`;
      });
    }
    
    return content.trim();
  }
}
```

## ⏭️ Próximos Pasos

Continuar to [Partee 2](./exercise1-part2) where we'll implement:
- Editaror Agent
- SEO Optimization Agent
- Publisher Agent
- Quality Gate System
- Completar pipeline integration