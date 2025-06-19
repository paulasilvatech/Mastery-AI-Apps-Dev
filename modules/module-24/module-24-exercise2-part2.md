# Exercise 2: Content Generation Pipeline - Part 2

## 🛠️ Continuing Implementation

### Step 5: Implement Editor Agent

**Copilot Prompt Suggestion:**
```typescript
// Create an editor agent that:
// - Reviews content for clarity and coherence
// - Fixes grammar and style issues
// - Improves readability and flow
// - Ensures consistency in tone and voice
// - Fact-checks claims and statements
// - Suggests improvements and enhancements
```

Create `src/agents/EditorAgent.ts`:
```typescript
import { BaseAgent } from '../../exercise1-research-system/src/agents/BaseAgent';
import { ChatOpenAI } from '@langchain/openai';
import { SystemMessage, HumanMessage } from '@langchain/core/messages';
import natural from 'natural';
import readingTime from 'reading-time';

interface EditingResult {
  editedContent: string;
  changes: Array<{
    type: 'grammar' | 'style' | 'clarity' | 'structure' | 'fact';
    original: string;
    revised: string;
    reason: string;
  }>;
  readability: {
    score: number;
    level: string;
    avgSentenceLength: number;
    avgWordLength: number;
  };
  suggestions: string[];
}

export class EditorAgent extends BaseAgent {
  private llm: ChatOpenAI;
  private tokenizer: any;

  constructor() {
    super({
      name: 'EditorAgent',
      capabilities: ['edit-content', 'proofread', 'improve-clarity']
    });
    
    this.llm = new ChatOpenAI({
      modelName: 'gpt-4',
      temperature: 0.3, // Lower temperature for more consistent editing
      maxTokens: 4000
    });
    
    this.tokenizer = new natural.WordTokenizer();
  }

  protected async execute(task: any): Promise<EditingResult> {
    const content = task.payload.content as string;
    const request = task.payload.request;
    
    this.logger.info('Editing content', {
      contentLength: content.length,
      wordCount: this.tokenizer.tokenize(content).length
    });
    
    // Analyze current content
    const analysis = this.analyzeContent(content);
    
    // Perform editing passes
    let editedContent = content;
    const allChanges: any[] = [];
    
    // Grammar and spelling check
    const grammarResult = await this.checkGrammar(editedContent, request);
    editedContent = grammarResult.content;
    allChanges.push(...grammarResult.changes);
    
    // Style and clarity improvements
    const styleResult = await this.improveStyle(editedContent, request);
    editedContent = styleResult.content;
    allChanges.push(...styleResult.changes);
    
    // Structure and flow optimization
    const structureResult = await this.optimizeStructure(editedContent, request);
    editedContent = structureResult.content;
    allChanges.push(...structureResult.changes);
    
    // Final readability analysis
    const readability = this.calculateReadability(editedContent);
    
    // Generate improvement suggestions
    const suggestions = await this.generateSuggestions(
      editedContent, 
      analysis, 
      readability
    );
    
    return {
      editedContent,
      changes: allChanges,
      readability,
      suggestions
    };
  }

  private analyzeContent(content: string): any {
    const sentences = content.match(/[^.!?]+[.!?]+/g) || [];
    const words = this.tokenizer.tokenize(content);
    const paragraphs = content.split('\n\n').filter(p => p.trim());
    
    return {
      sentenceCount: sentences.length,
      wordCount: words.length,
      paragraphCount: paragraphs.length,
      avgSentenceLength: words.length / sentences.length,
      avgParagraphLength: sentences.length / paragraphs.length,
      readingStats: readingTime(content)
    };
  }

  private async checkGrammar(
    content: string,
    request: any
  ): Promise<{ content: string; changes: any[] }> {
    const prompt = `You are a professional editor. Review the following content for grammar, spelling, and punctuation errors.

Content to edit:
${content}

Requirements:
- Fix all grammar and spelling errors
- Maintain the original tone and style
- Preserve the author's voice
- Only make necessary corrections

Return the corrected content.`;

    const response = await this.llm.invoke([
      new SystemMessage('You are an expert editor focused on grammar and correctness.'),
      new HumanMessage(prompt)
    ]);
    
    const editedContent = response.content as string;
    
    // Track changes (simplified - in production, use diff algorithm)
    const changes = this.detectChanges(
      content, 
      editedContent, 
      'grammar'
    );
    
    return { content: editedContent, changes };
  }

  private async improveStyle(
    content: string,
    request: any
  ): Promise<{ content: string; changes: any[] }> {
    const prompt = `You are a professional editor. Improve the style and clarity of the following content.

Content to edit:
${content}

Target audience: ${request.targetAudience}
Desired tone: ${request.tone}

Focus on:
1. Simplifying complex sentences
2. Removing redundancy
3. Improving word choice
4. Enhancing clarity
5. Maintaining consistent tone

Return the improved content.`;

    const response = await this.llm.invoke([
      new SystemMessage('You are an expert editor focused on style and clarity.'),
      new HumanMessage(prompt)
    ]);
    
    const editedContent = response.content as string;
    const changes = this.detectChanges(content, editedContent, 'style');
    
    return { content: editedContent, changes };
  }

  private async optimizeStructure(
    content: string,
    request: any
  ): Promise<{ content: string; changes: any[] }> {
    const prompt = `You are a professional editor. Optimize the structure and flow of the following content.

Content to edit:
${content}

Focus on:
1. Logical flow between paragraphs
2. Smooth transitions
3. Proper heading hierarchy
4. Balanced section lengths
5. Strong opening and closing

Make minimal changes to preserve the content while improving structure.

Return the optimized content.`;

    const response = await this.llm.invoke([
      new SystemMessage('You are an expert editor focused on content structure.'),
      new HumanMessage(prompt)
    ]);
    
    const editedContent = response.content as string;
    const changes = this.detectChanges(content, editedContent, 'structure');
    
    return { content: editedContent, changes };
  }

  private detectChanges(
    original: string,
    edited: string,
    type: string
  ): any[] {
    const changes: any[] = [];
    
    // Simple line-by-line comparison (use proper diff in production)
    const originalLines = original.split('\n');
    const editedLines = edited.split('\n');
    
    for (let i = 0; i < Math.max(originalLines.length, editedLines.length); i++) {
      const origLine = originalLines[i] || '';
      const editLine = editedLines[i] || '';
      
      if (origLine !== editLine && origLine.trim() && editLine.trim()) {
        changes.push({
          type,
          original: origLine.trim(),
          revised: editLine.trim(),
          reason: `${type} improvement`
        });
      }
    }
    
    return changes.slice(0, 10); // Limit to 10 most significant changes
  }

  private calculateReadability(content: string): any {
    const sentences = content.match(/[^.!?]+[.!?]+/g) || [];
    const words = this.tokenizer.tokenize(content);
    const syllables = this.countSyllables(words);
    
    // Flesch Reading Ease Score
    const avgSentenceLength = words.length / sentences.length;
    const avgSyllablesPerWord = syllables / words.length;
    
    const fleschScore = 206.835 - 
      1.015 * avgSentenceLength - 
      84.6 * avgSyllablesPerWord;
    
    // Determine reading level
    let level = 'Very Difficult';
    if (fleschScore >= 90) level = 'Very Easy';
    else if (fleschScore >= 80) level = 'Easy';
    else if (fleschScore >= 70) level = 'Fairly Easy';
    else if (fleschScore >= 60) level = 'Standard';
    else if (fleschScore >= 50) level = 'Fairly Difficult';
    else if (fleschScore >= 30) level = 'Difficult';
    
    return {
      score: Math.max(0, Math.min(100, fleschScore)),
      level,
      avgSentenceLength: Math.round(avgSentenceLength),
      avgWordLength: Math.round(words.join('').length / words.length)
    };
  }

  private countSyllables(words: string[]): number {
    let totalSyllables = 0;
    
    for (const word of words) {
      // Simple syllable counting (use CMU Pronouncing Dictionary in production)
      const syllables = word.toLowerCase()
        .replace(/[^a-z]/g, '')
        .replace(/[aeiou]{2,}/g, 'a')
        .match(/[aeiou]/g);
      
      totalSyllables += syllables ? syllables.length : 1;
    }
    
    return totalSyllables;
  }

  private async generateSuggestions(
    content: string,
    analysis: any,
    readability: any
  ): Promise<string[]> {
    const suggestions: string[] = [];
    
    // Readability suggestions
    if (readability.score < 60) {
      suggestions.push('Consider simplifying sentences for better readability');
    }
    
    if (analysis.avgSentenceLength > 25) {
      suggestions.push('Break up long sentences to improve flow');
    }
    
    if (analysis.avgParagraphLength > 5) {
      suggestions.push('Consider breaking up longer paragraphs');
    }
    
    // Structure suggestions
    const headings = content.match(/^#{1,6} .+$/gm) || [];
    if (headings.length < 3) {
      suggestions.push('Add more section headings to improve structure');
    }
    
    // Content suggestions
    const questions = content.match(/\?/g) || [];
    if (questions.length === 0) {
      suggestions.push('Consider adding questions to engage readers');
    }
    
    const lists = content.match(/^[\*\-\d]\. /gm) || [];
    if (lists.length === 0) {
      suggestions.push('Use bullet points or lists to break up information');
    }
    
    return suggestions;
  }
}
```

### Step 6: Implement SEO Optimization Agent

**Copilot Prompt Suggestion:**
```typescript
// Create an SEO optimization agent that:
// - Optimizes content for search engines
// - Ensures keyword placement and density
// - Creates meta descriptions and tags
// - Improves content structure for SEO
// - Generates schema markup suggestions
// - Analyzes competitor content
```

Create `src/agents/SEOAgent.ts`:
```typescript
import { BaseAgent } from '../../exercise1-research-system/src/agents/BaseAgent';
import keyword_extractor from 'keyword-extractor';
import stringSimilarity from 'string-similarity';

interface SEOResult {
  optimizedContent: string;
  metadata: {
    title: string;
    metaDescription: string;
    keywords: string[];
    tags: string[];
    slug: string;
  };
  analysis: {
    keywordDensity: Record<string, number>;
    headingStructure: Array<{ level: number; text: string }>;
    internalLinks: number;
    externalLinks: number;
    imageCount: number;
    wordCount: number;
    estimatedSEOScore: number;
  };
  recommendations: string[];
}

export class SEOAgent extends BaseAgent {
  constructor() {
    super({
      name: 'SEOAgent',
      capabilities: ['seo-optimization', 'keyword-analysis', 'meta-generation']
    });
  }

  protected async execute(task: any): Promise<SEOResult> {
    const content = task.payload.content as string;
    const request = task.payload.request;
    const targetKeywords = request.keywords || [];
    
    this.logger.info('Optimizing content for SEO', {
      targetKeywords,
      contentLength: content.length
    });
    
    // Analyze current content
    const analysis = this.analyzeContent(content, targetKeywords);
    
    // Optimize content
    let optimizedContent = content;
    
    // Optimize keyword placement
    optimizedContent = this.optimizeKeywordPlacement(
      optimizedContent, 
      targetKeywords
    );
    
    // Optimize headings
    optimizedContent = this.optimizeHeadings(
      optimizedContent, 
      targetKeywords
    );
    
    // Add internal structure
    optimizedContent = this.addSEOStructure(optimizedContent);
    
    // Generate metadata
    const metadata = this.generateMetadata(
      optimizedContent, 
      request, 
      targetKeywords
    );
    
    // Calculate SEO score
    const finalAnalysis = this.analyzeContent(optimizedContent, targetKeywords);
    const seoScore = this.calculateSEOScore(finalAnalysis, metadata);
    
    // Generate recommendations
    const recommendations = this.generateRecommendations(
      finalAnalysis, 
      seoScore
    );
    
    return {
      optimizedContent,
      metadata,
      analysis: {
        ...finalAnalysis,
        estimatedSEOScore: seoScore
      },
      recommendations
    };
  }

  private analyzeContent(
    content: string, 
    targetKeywords: string[]
  ): any {
    const words = content.toLowerCase().split(/\s+/);
    const wordCount = words.length;
    
    // Calculate keyword density
    const keywordDensity: Record<string, number> = {};
    
    targetKeywords.forEach(keyword => {
      const keywordLower = keyword.toLowerCase();
      const occurrences = content.toLowerCase().split(keywordLower).length - 1;
      const density = (occurrences / wordCount) * 100;
      keywordDensity[keyword] = Number(density.toFixed(2));
    });
    
    // Extract heading structure
    const headingStructure = this.extractHeadings(content);
    
    // Count links
    const internalLinks = (content.match(/\[.*?\]\(\/.*?\)/g) || []).length;
    const externalLinks = (content.match(/\[.*?\]\(https?:\/\/.*?\)/g) || []).length;
    
    // Count images
    const imageCount = (content.match(/!\[.*?\]\(.*?\)/g) || []).length;
    
    return {
      keywordDensity,
      headingStructure,
      internalLinks,
      externalLinks,
      imageCount,
      wordCount
    };
  }

  private optimizeKeywordPlacement(
    content: string, 
    keywords: string[]
  ): string {
    let optimized = content;
    
    // Ensure primary keyword appears in first paragraph
    const primaryKeyword = keywords[0];
    if (primaryKeyword) {
      const firstParagraph = optimized.split('\n\n')[0];
      
      if (!firstParagraph.toLowerCase().includes(primaryKeyword.toLowerCase())) {
        // Add keyword naturally to first paragraph
        const sentences = firstParagraph.split('. ');
        if (sentences.length > 1) {
          sentences[1] = `${sentences[1]} This relates to ${primaryKeyword}.`;
          optimized = optimized.replace(
            firstParagraph, 
            sentences.join('. ')
          );
        }
      }
    }
    
    // Distribute keywords throughout content
    keywords.forEach((keyword, index) => {
      const targetDensity = index === 0 ? 1.5 : 0.5; // Primary vs secondary
      const currentDensity = this.getKeywordDensity(optimized, keyword);
      
      if (currentDensity < targetDensity) {
        // Add keyword mentions where natural
        optimized = this.addKeywordMentions(optimized, keyword, targetDensity);
      }
    });
    
    return optimized;
  }

  private optimizeHeadings(
    content: string, 
    keywords: string[]
  ): string {
    let optimized = content;
    const headings = content.match(/^#{1,6} .+$/gm) || [];
    
    // Ensure at least one heading contains primary keyword
    const primaryKeyword = keywords[0];
    if (primaryKeyword && headings.length > 0) {
      const hasKeywordInHeading = headings.some(h => 
        h.toLowerCase().includes(primaryKeyword.toLowerCase())
      );
      
      if (!hasKeywordInHeading && headings.length > 1) {
        // Modify second heading to include keyword
        const secondHeading = headings[1];
        const modifiedHeading = this.addKeywordToHeading(
          secondHeading, 
          primaryKeyword
        );
        optimized = optimized.replace(secondHeading, modifiedHeading);
      }
    }
    
    return optimized;
  }

  private addSEOStructure(content: string): string {
    let structured = content;
    
    // Add table of contents for long content
    const headings = this.extractHeadings(content);
    if (headings.length > 4) {
      const toc = this.generateTableOfContents(headings);
      
      // Insert after introduction
      const firstHeadingIndex = structured.indexOf('\n## ');
      if (firstHeadingIndex > 0) {
        structured = 
          structured.slice(0, firstHeadingIndex) + 
          '\n\n' + toc + '\n' +
          structured.slice(firstHeadingIndex);
      }
    }
    
    // Add FAQ section if not present
    if (!structured.includes('FAQ') && !structured.includes('Frequently Asked')) {
      structured += '\n\n## Frequently Asked Questions\n\n';
      structured += this.generateFAQSection(content);
    }
    
    return structured;
  }

  private generateMetadata(
    content: string, 
    request: any,
    keywords: string[]
  ): any {
    // Extract title from content or use topic
    const titleMatch = content.match(/^# (.+)$/m);
    const title = titleMatch ? titleMatch[1] : request.topic;
    
    // Generate meta description
    const firstParagraph = content
      .split('\n\n')
      .find(p => p.trim() && !p.startsWith('#'));
    
    const metaDescription = this.generateMetaDescription(
      firstParagraph || '', 
      keywords[0]
    );
    
    // Generate slug
    const slug = title
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '');
    
    // Extract all relevant keywords
    const extractedKeywords = keyword_extractor.extract(content, {
      language: 'english',
      remove_digits: true,
      return_changed_case: true,
      remove_duplicates: true
    });
    
    // Combine with target keywords
    const allKeywords = [...new Set([...keywords, ...extractedKeywords.slice(0, 5)])];
    
    // Generate tags
    const tags = this.generateTags(content, request);
    
    return {
      title: this.optimizeTitle(title, keywords[0]),
      metaDescription,
      keywords: allKeywords,
      tags,
      slug
    };
  }

  private generateMetaDescription(text: string, primaryKeyword: string): string {
    // Truncate to ~155 characters
    let description = text.substring(0, 155);
    
    // Ensure it ends at a word boundary
    const lastSpace = description.lastIndexOf(' ');
    description = description.substring(0, lastSpace);
    
    // Ensure primary keyword is included
    if (!description.toLowerCase().includes(primaryKeyword.toLowerCase())) {
      const words = description.split(' ');
      if (words.length > 5) {
        words[4] = primaryKeyword;
        description = words.join(' ');
      }
    }
    
    return description + '...';
  }

  private optimizeTitle(title: string, primaryKeyword: string): string {
    // Ensure primary keyword is in title
    if (!title.toLowerCase().includes(primaryKeyword.toLowerCase())) {
      return `${title}: ${primaryKeyword} Guide`;
    }
    
    // Ensure title is optimal length (50-60 characters)
    if (title.length > 60) {
      return title.substring(0, 57) + '...';
    }
    
    return title;
  }

  private generateTags(content: string, request: any): string[] {
    const tags: string[] = [];
    
    // Add content type
    tags.push(request.type);
    
    // Add target audience
    if (request.targetAudience) {
      tags.push(request.targetAudience);
    }
    
    // Add topic-based tags
    const topicWords = request.topic.toLowerCase().split(' ');
    tags.push(...topicWords.filter((w: string) => w.length > 3));
    
    // Add year for time-sensitive content
    if (content.includes('2024') || content.includes('2025')) {
      tags.push('2024');
    }
    
    return [...new Set(tags)].slice(0, 10);
  }

  private calculateSEOScore(analysis: any, metadata: any): number {
    let score = 0;
    
    // Title optimization (20 points)
    if (metadata.title.length >= 30 && metadata.title.length <= 60) {
      score += 20;
    } else {
      score += 10;
    }
    
    // Meta description (15 points)
    if (metadata.metaDescription.length >= 120 && 
        metadata.metaDescription.length <= 160) {
      score += 15;
    } else {
      score += 7;
    }
    
    // Keyword density (20 points)
    const primaryDensity = Object.values(analysis.keywordDensity)[0] as number || 0;
    if (primaryDensity >= 0.5 && primaryDensity <= 2.5) {
      score += 20;
    } else if (primaryDensity > 0) {
      score += 10;
    }
    
    // Heading structure (15 points)
    if (analysis.headingStructure.length >= 3) {
      score += 15;
    } else {
      score += analysis.headingStructure.length * 5;
    }
    
    // Content length (15 points)
    if (analysis.wordCount >= 1000) {
      score += 15;
    } else if (analysis.wordCount >= 500) {
      score += 10;
    } else {
      score += 5;
    }
    
    // Links (10 points)
    if (analysis.internalLinks >= 2) score += 5;
    if (analysis.externalLinks >= 1) score += 5;
    
    // Images (5 points)
    if (analysis.imageCount >= 1) score += 5;
    
    return Math.min(100, score);
  }

  private generateRecommendations(analysis: any, seoScore: number): string[] {
    const recommendations: string[] = [];
    
    if (seoScore < 80) {
      recommendations.push(`Current SEO score: ${seoScore}/100. Room for improvement.`);
    }
    
    // Keyword recommendations
    const primaryDensity = Object.values(analysis.keywordDensity)[0] as number || 0;
    if (primaryDensity < 0.5) {
      recommendations.push('Increase primary keyword usage (target: 0.5-2.5%)');
    } else if (primaryDensity > 2.5) {
      recommendations.push('Reduce keyword density to avoid over-optimization');
    }
    
    // Structure recommendations
    if (analysis.headingStructure.length < 3) {
      recommendations.push('Add more subheadings to improve content structure');
    }
    
    // Content recommendations
    if (analysis.wordCount < 1000) {
      recommendations.push('Consider expanding content to 1000+ words for better SEO');
    }
    
    if (analysis.internalLinks === 0) {
      recommendations.push('Add internal links to related content');
    }
    
    if (analysis.imageCount === 0) {
      recommendations.push('Add relevant images with alt text');
    }
    
    // Technical recommendations
    recommendations.push('Consider adding schema markup for rich snippets');
    
    if (!analysis.hasFAQ) {
      recommendations.push('Add FAQ section for potential featured snippets');
    }
    
    return recommendations;
  }

  private extractHeadings(content: string): any[] {
    const headingRegex = /^(#{1,6}) (.+)$/gm;
    const headings: any[] = [];
    let match;
    
    while ((match = headingRegex.exec(content)) !== null) {
      headings.push({
        level: match[1].length,
        text: match[2]
      });
    }
    
    return headings;
  }

  private getKeywordDensity(content: string, keyword: string): number {
    const words = content.toLowerCase().split(/\s+/);
    const keywordLower = keyword.toLowerCase();
    const occurrences = content.toLowerCase().split(keywordLower).length - 1;
    return (occurrences / words.length) * 100;
  }

  private addKeywordMentions(
    content: string, 
    keyword: string, 
    targetDensity: number
  ): string {
    // This is a simplified implementation
    // In production, use NLP to add keywords naturally
    const currentDensity = this.getKeywordDensity(content, keyword);
    const wordsNeeded = Math.ceil(
      (targetDensity - currentDensity) * content.split(/\s+/).length / 100
    );
    
    if (wordsNeeded > 0) {
      // Add keyword in conclusion if not present
      const conclusionIndex = content.lastIndexOf('## Conclusion');
      if (conclusionIndex > 0 && 
          !content.slice(conclusionIndex).toLowerCase().includes(keyword.toLowerCase())) {
        const beforeConclusion = content.slice(0, conclusionIndex);
        const conclusion = content.slice(conclusionIndex);
        
        const updatedConclusion = conclusion.replace(
          'In summary,',
          `In summary, our exploration of ${keyword} shows that`
        );
        
        return beforeConclusion + updatedConclusion;
      }
    }
    
    return content;
  }

  private addKeywordToHeading(heading: string, keyword: string): string {
    // Add keyword naturally to heading
    const headingLevel = heading.match(/^#+/)?.[0] || '##';
    const headingText = heading.replace(/^#+ /, '');
    
    return `${headingLevel} ${headingText} for ${keyword}`;
  }

  private generateTableOfContents(headings: any[]): string {
    let toc = '## Table of Contents\n\n';
    
    headings.forEach(heading => {
      if (heading.level === 2) {
        const anchor = heading.text.toLowerCase().replace(/[^a-z0-9]+/g, '-');
        toc += `- [${heading.text}](#${anchor})\n`;
      }
    });
    
    return toc;
  }

  private generateFAQSection(content: string): string {
    // Generate simple FAQ based on content
    // In production, use AI to generate relevant questions
    return `**Q: What are the key takeaways?**
A: The main points covered in this article include...

**Q: How can I apply this information?**
A: You can start by implementing the strategies discussed...

**Q: Where can I learn more?**
A: For additional resources, consider exploring...`;
  }
}
```

### Step 7: Implement Publisher Agent

Create `src/agents/PublisherAgent.ts`:
```typescript
import { BaseAgent } from '../../exercise1-research-system/src/agents/BaseAgent';
import { Octokit } from '@octokit/rest';
import matter from 'gray-matter';
import MarkdownIt from 'markdown-it';

interface PublishingResult {
  published: boolean;
  platform: string;
  url?: string;
  id?: string;
  error?: string;
  metadata: {
    publishedAt: Date;
    lastModified?: Date;
    version: string;
    checksum: string;
  };
}

export class PublisherAgent extends BaseAgent {
  private octokit?: Octokit;
  private md: MarkdownIt;

  constructor() {
    super({
      name: 'PublisherAgent',
      capabilities: ['publish-content', 'format-content', 'deploy-content']
    });
    
    this.md = new MarkdownIt({
      html: true,
      linkify: true,
      typographer: true
    });
    
    // Initialize GitHub client if credentials available
    if (process.env.GITHUB_TOKEN) {
      this.octokit = new Octokit({
        auth: process.env.GITHUB_TOKEN
      });
    }
  }

  protected async execute(task: any): Promise<PublishingResult> {
    const content = task.payload.content as string;
    const metadata = task.payload.metadata;
    const platform = task.payload.platform || 'github';
    
    this.logger.info('Publishing content', {
      platform,
      contentLength: content.length
    });
    
    try {
      let result: PublishingResult;
      
      switch (platform) {
        case 'github':
          result = await this.publishToGitHub(content, metadata);
          break;
          
        case 'wordpress':
          result = await this.publishToWordPress(content, metadata);
          break;
          
        case 'medium':
          result = await this.publishToMedium(content, metadata);
          break;
          
        case 'local':
          result = await this.publishToLocal(content, metadata);
          break;
          
        default:
          throw new Error(`Unsupported platform: ${platform}`);
      }
      
      return result;
      
    } catch (error: any) {
      this.logger.error('Publishing failed', {
        platform,
        error: error.message
      });
      
      return {
        published: false,
        platform,
        error: error.message,
        metadata: {
          publishedAt: new Date(),
          version: '1.0.0',
          checksum: this.generateChecksum(content)
        }
      };
    }
  }

  private async publishToGitHub(
    content: string, 
    metadata: any
  ): Promise<PublishingResult> {
    if (!this.octokit) {
      throw new Error('GitHub client not initialized');
    }
    
    const owner = process.env.GITHUB_OWNER || 'your-username';
    const repo = process.env.GITHUB_REPO || 'content-repository';
    const branch = process.env.GITHUB_BRANCH || 'main';
    
    // Format content with front matter
    const formattedContent = this.formatWithFrontMatter(content, metadata);
    
    // Generate file path
    const date = new Date();
    const fileName = `${metadata.slug || 'untitled'}.md`;
    const path = `content/${date.getFullYear()}/${String(date.getMonth() + 1).padStart(2, '0')}/${fileName}`;
    
    try {
      // Check if file already exists
      let sha: string | undefined;
      try {
        const { data: existingFile } = await this.octokit.repos.getContent({
          owner,
          repo,
          path,
          ref: branch
        });
        
        if ('sha' in existingFile) {
          sha = existingFile.sha;
        }
      } catch (error) {
        // File doesn't exist, which is fine
      }
      
      // Create or update file
      const { data } = await this.octokit.repos.createOrUpdateFileContents({
        owner,
        repo,
        path,
        message: `Publish: ${metadata.title}`,
        content: Buffer.from(formattedContent).toString('base64'),
        branch,
        sha
      });
      
      const url = `https://github.com/${owner}/${repo}/blob/${branch}/${path}`;
      
      return {
        published: true,
        platform: 'github',
        url,
        id: data.content?.sha,
        metadata: {
          publishedAt: new Date(),
          version: '1.0.0',
          checksum: this.generateChecksum(formattedContent)
        }
      };
      
    } catch (error: any) {
      throw new Error(`GitHub publishing failed: ${error.message}`);
    }
  }

  private async publishToWordPress(
    content: string, 
    metadata: any
  ): Promise<PublishingResult> {
    // WordPress implementation (simplified)
    const wpUrl = process.env.WORDPRESS_URL;
    const wpUser = process.env.WORDPRESS_USER;
    const wpPassword = process.env.WORDPRESS_PASSWORD;
    
    if (!wpUrl || !wpUser || !wpPassword) {
      throw new Error('WordPress credentials not configured');
    }
    
    // Convert markdown to HTML
    const htmlContent = this.md.render(content);
    
    // In production, use WordPress REST API or XML-RPC
    const mockResponse = {
      id: Date.now().toString(),
      link: `${wpUrl}/?p=${Date.now()}`
    };
    
    return {
      published: true,
      platform: 'wordpress',
      url: mockResponse.link,
      id: mockResponse.id,
      metadata: {
        publishedAt: new Date(),
        version: '1.0.0',
        checksum: this.generateChecksum(htmlContent)
      }
    };
  }

  private async publishToMedium(
    content: string, 
    metadata: any
  ): Promise<PublishingResult> {
    // Medium implementation (simplified)
    const mediumToken = process.env.MEDIUM_TOKEN;
    
    if (!mediumToken) {
      throw new Error('Medium integration token not configured');
    }
    
    // In production, use Medium API
    const mockResponse = {
      id: Date.now().toString(),
      url: `https://medium.com/@user/${metadata.slug}`
    };
    
    return {
      published: true,
      platform: 'medium',
      url: mockResponse.url,
      id: mockResponse.id,
      metadata: {
        publishedAt: new Date(),
        version: '1.0.0',
        checksum: this.generateChecksum(content)
      }
    };
  }

  private async publishToLocal(
    content: string, 
    metadata: any
  ): Promise<PublishingResult> {
    const fs = await import('fs/promises');
    const path = await import('path');
    
    // Format content
    const formattedContent = this.formatWithFrontMatter(content, metadata);
    
    // Create directory structure
    const date = new Date();
    const dir = path.join(
      'content/published',
      date.getFullYear().toString(),
      String(date.getMonth() + 1).padStart(2, '0')
    );
    
    await fs.mkdir(dir, { recursive: true });
    
    // Write file
    const fileName = `${metadata.slug || 'untitled'}.md`;
    const filePath = path.join(dir, fileName);
    
    await fs.writeFile(filePath, formattedContent, 'utf8');
    
    return {
      published: true,
      platform: 'local',
      url: `file://${filePath}`,
      id: fileName,
      metadata: {
        publishedAt: new Date(),
        version: '1.0.0',
        checksum: this.generateChecksum(formattedContent)
      }
    };
  }

  private formatWithFrontMatter(content: string, metadata: any): string {
    const frontMatter = {
      title: metadata.title,
      description: metadata.metaDescription,
      date: new Date().toISOString(),
      tags: metadata.tags,
      keywords: metadata.keywords,
      author: 'AI Content Pipeline',
      ...metadata
    };
    
    // Remove any existing front matter
    const parsed = matter(content);
    const cleanContent = parsed.content;
    
    // Create new content with front matter
    return matter.stringify(cleanContent, frontMatter);
  }

  private generateChecksum(content: string): string {
    const crypto = require('crypto');
    return crypto
      .createHash('sha256')
      .update(content)
      .digest('hex')
      .substring(0, 8);
  }
}
```

### Step 8: Implement Pipeline Orchestrator

Create `src/pipeline/PipelineOrchestrator.ts`:
```typescript
import { ContentPipeline, ContentRequest, ContentStage } from './ContentPipeline';
import { ContentPlannerAgent } from '../agents/ContentPlannerAgent';
import { WriterAgent } from '../agents/WriterAgent';
import { EditorAgent } from '../agents/EditorAgent';
import { SEOAgent } from '../agents/SEOAgent';
import { PublisherAgent } from '../agents/PublisherAgent';
import Bull from 'bull';
import winston from 'winston';

export class PipelineOrchestrator {
  private pipeline: ContentPipeline;
  private agents: Map<string, any> = new Map();
  private logger: winston.Logger;

  constructor(redisUrl: string) {
    this.pipeline = new ContentPipeline(redisUrl);
    this.logger = winston.createLogger({
      level: 'info',
      format: winston.format.json(),
      defaultMeta: { service: 'pipeline-orchestrator' }
    });
    
    this.initializeAgents();
    this.setupStageProcessors();
  }

  private initializeAgents(): void {
    this.agents.set('planner', new ContentPlannerAgent());
    this.agents.set('writer', new WriterAgent());
    this.agents.set('editor', new EditorAgent());
    this.agents.set('seo', new SEOAgent());
    this.agents.set('publisher', new PublisherAgent());
    
    // Start all agents
    this.agents.forEach(agent => agent.start());
  }

  private setupStageProcessors(): void {
    // Planning stage
    this.pipeline.queues.get(ContentStage.PLANNING)?.process(async (job) => {
      const agent = this.agents.get('planner');
      const result = await agent.executeTask({
        id: job.id?.toString(),
        type: 'plan-content',
        payload: job.data
      });
      
      await this.pipeline.addContentVersion(
        job.data.jobId,
        JSON.stringify(result.result),
        { outline: result.result },
        agent.id,
        'Created content outline'
      );
      
      return result;
    });
    
    // Writing stage
    this.pipeline.queues.get(ContentStage.WRITING)?.process(async (job) => {
      const agent = this.agents.get('writer');
      const outline = JSON.parse(job.data.content);
      
      const result = await agent.executeTask({
        id: job.id?.toString(),
        type: 'write-content',
        payload: {
          outline,
          request: job.data.request,
          content: job.data.content
        }
      });
      
      await this.pipeline.addContentVersion(
        job.data.jobId,
        result.result,
        { wordCount: result.result.split(/\s+/).length },
        agent.id,
        'Generated initial draft'
      );
      
      // Perform quality check
      const qualityCheck = await this.pipeline.performQualityCheck(
        job.data.jobId,
        ContentStage.WRITING
      );
      
      if (!qualityCheck.passed) {
        throw new Error(`Quality check failed: ${qualityCheck.issues[0]?.message}`);
      }
      
      return result;
    });
    
    // Editing stage
    this.pipeline.queues.get(ContentStage.EDITING)?.process(async (job) => {
      const agent = this.agents.get('editor');
      
      const result = await agent.executeTask({
        id: job.id?.toString(),
        type: 'edit-content',
        payload: job.data
      });
      
      await this.pipeline.addContentVersion(
        job.data.jobId,
        result.result.editedContent,
        {
          changes: result.result.changes.length,
          readability: result.result.readability
        },
        agent.id,
        'Edited for clarity and correctness'
      );
      
      // Quality check
      const qualityCheck = await this.pipeline.performQualityCheck(
        job.data.jobId,
        ContentStage.EDITING
      );
      
      if (!qualityCheck.passed && qualityCheck.score < 60) {
        // Send back to writing if quality is too low
        job.data.request.requirements = [
          ...job.data.request.requirements || [],
          ...qualityCheck.issues.map((i: any) => i.suggestion).filter(Boolean)
        ];
        
        await this.pipeline.moveToStage(job.data.jobId, ContentStage.WRITING);
        return { retry: true };
      }
      
      return result;
    });
    
    // SEO optimization stage
    this.pipeline.queues.get(ContentStage.SEO_OPTIMIZATION)?.process(async (job) => {
      const agent = this.agents.get('seo');
      
      const result = await agent.executeTask({
        id: job.id?.toString(),
        type: 'seo-optimization',
        payload: job.data
      });
      
      await this.pipeline.addContentVersion(
        job.data.jobId,
        result.result.optimizedContent,
        {
          metadata: result.result.metadata,
          seoScore: result.result.analysis.estimatedSEOScore
        },
        agent.id,
        'Optimized for SEO'
      );
      
      return result;
    });
    
    // Review stage (final quality gate)
    this.pipeline.queues.get(ContentStage.REVIEW)?.process(async (job) => {
      // Perform final quality check
      const qualityCheck = await this.pipeline.performQualityCheck(
        job.data.jobId,
        ContentStage.REVIEW
      );
      
      if (!qualityCheck.passed || qualityCheck.score < 80) {
        // Determine which stage needs improvement
        const mainIssue = qualityCheck.issues[0];
        
        if (mainIssue?.type === 'grammar' || mainIssue?.type === 'clarity') {
          await this.pipeline.moveToStage(job.data.jobId, ContentStage.EDITING);
        } else if (mainIssue?.type === 'seo') {
          await this.pipeline.moveToStage(job.data.jobId, ContentStage.SEO_OPTIMIZATION);
        } else {
          await this.pipeline.moveToStage(job.data.jobId, ContentStage.WRITING);
        }
        
        return { retry: true, reason: mainIssue?.message };
      }
      
      return { approved: true, score: qualityCheck.score };
    });
    
    // Publishing stage
    this.pipeline.queues.get(ContentStage.PUBLISHING)?.process(async (job) => {
      const agent = this.agents.get('publisher');
      
      // Get latest metadata from SEO stage
      const jobStatus = await this.pipeline.getJobStatus(job.data.jobId);
      const seoVersion = jobStatus.versions.find((v: any) => 
        v.stage === ContentStage.SEO_OPTIMIZATION
      );
      
      const result = await agent.executeTask({
        id: job.id?.toString(),
        type: 'publish-content',
        payload: {
          content: job.data.content,
          metadata: seoVersion?.metadata?.metadata || {},
          platform: job.data.request.metadata?.platform || 'github'
        }
      });
      
      return result;
    });
  }

  async submitContent(request: ContentRequest): Promise<string> {
    return this.pipeline.submitContent(request);
  }

  async getStatus(jobId: string): Promise<any> {
    return this.pipeline.getJobStatus(jobId);
  }

  async shutdown(): Promise<void> {
    // Stop all agents
    await Promise.all(
      Array.from(this.agents.values()).map(agent => agent.stop())
    );
    
    // Shutdown pipeline
    await this.pipeline.shutdown();
  }
}
```

### Step 9: Create Demo Application

Create `src/demo.ts`:
```typescript
import { PipelineOrchestrator } from './pipeline/PipelineOrchestrator';
import { ContentRequest } from './pipeline/ContentPipeline';
import dotenv from 'dotenv';

dotenv.config();

async function demonstrateContentPipeline() {
  console.log('📝 Content Generation Pipeline Demo\n');
  
  const orchestrator = new PipelineOrchestrator(
    process.env.REDIS_URL || 'redis://localhost:6379'
  );
  
  // Create content request
  const request: ContentRequest = {
    id: 'demo-content-001',
    type: 'blog',
    topic: 'The Future of AI in Software Development',
    keywords: ['AI', 'software development', 'automation', 'productivity'],
    targetAudience: 'software developers and tech leaders',
    tone: 'professional',
    length: {
      min: 1200,
      max: 1500
    },
    requirements: [
      'Include real-world examples',
      'Discuss both benefits and challenges',
      'Provide actionable insights'
    ],
    metadata: {
      platform: 'github'
    }
  };
  
  try {
    // Submit content to pipeline
    console.log('📋 Submitting content request...');
    const jobId = await orchestrator.submitContent(request);
    console.log(`✅ Job submitted: ${jobId}\n`);
    
    // Monitor progress
    const interval = setInterval(async () => {
      const status = await orchestrator.getStatus(jobId);
      
      console.log(`📊 Progress: ${status.progress.toFixed(0)}% - Stage: ${status.stage}`);
      
      // Show stage-specific information
      if (status.metrics?.qualityScores) {
        const scores = Object.entries(status.metrics.qualityScores);
        if (scores.length > 0) {
          console.log('   Quality scores:', scores.map(([stage, score]) => 
            `${stage}: ${score}`
          ).join(', '));
        }
      }
      
      if (status.status === 'completed') {
        clearInterval(interval);
        
        console.log('\n🎉 Content pipeline completed!');
        console.log(`   Total time: ${(Date.now() - new Date(status.startTime).getTime()) / 1000}s`);
        console.log(`   Versions created: ${status.versions}`);
        console.log(`   Final quality score: ${status.metrics.qualityScores.review || 'N/A'}`);
        
        // Get final content
        const finalStatus = await orchestrator.getStatus(jobId);
        console.log('\n📄 Content published successfully!');
        
        // Shutdown
        setTimeout(async () => {
          await orchestrator.shutdown();
          console.log('\n👋 Pipeline shutdown complete');
          process.exit(0);
        }, 2000);
      }
      
      if (status.status === 'failed') {
        clearInterval(interval);
        console.error('\n❌ Pipeline failed at stage:', status.stage);
        await orchestrator.shutdown();
        process.exit(1);
      }
    }, 3000);
    
  } catch (error) {
    console.error('Demo error:', error);
    await orchestrator.shutdown();
    process.exit(1);
  }
}

// Run the demo
demonstrateContentPipeline().catch(console.error);
```

### Step 10: Update Package Scripts

Update `package.json`:
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

## 🏃 Running the Content Pipeline

1. **Start Redis:**
```bash
npm run start-redis
```

2. **Set environment variables:**
```bash
# Create .env file
REDIS_URL=redis://localhost:6379
OPENAI_API_KEY=your-api-key
GITHUB_TOKEN=your-github-token
GITHUB_OWNER=your-username
GITHUB_REPO=content-repo
```

3. **Run the pipeline:**
```bash
npm run build
npm start
```

## 🎯 Validation

Your Content Generation Pipeline should now:
- ✅ Plan content with detailed outlines
- ✅ Generate high-quality written content
- ✅ Edit for grammar, clarity, and style
- ✅ Optimize for SEO and search visibility
- ✅ Publish to multiple platforms
- ✅ Maintain quality through multiple checkpoints
- ✅ Track versions and changes throughout
- ✅ Handle failures with appropriate retries

## 📚 Additional Resources

- [Content Strategy Guide](https://contentmarketinginstitute.com/)
- [SEO Best Practices](https://moz.com/beginners-guide-to-seo)
- [Markdown Guide](https://www.markdownguide.org/)

## ⏭️ Next Exercise

Ready for the ultimate challenge? Move on to [Exercise 3: Distributed Problem Solver](../exercise3-problem-solver/) where you'll build a system that coordinates agents to solve complex computational problems!