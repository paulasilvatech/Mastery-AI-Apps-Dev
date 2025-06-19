# Instructions for the Mastery AI Code Development Workshop

## Objective
Deliver a complete, modular, and hands-on workshop focused on mastering AI-powered development using GitHub Copilot, GitHub Platform, and Azure. The workshop provides a comprehensive 30-module journey from fundamentals to advanced agent orchestration, ensuring participants achieve true mastery in AI development.

## 📦 General Guidelines

### Language
All documentation must be written in English.

### Structure
Each module must be divided into 3 parts:
1. **Module Overview** - Conceptual understanding and objectives
2. **Hands-on Exercises** - Three progressive exercises (easy → medium → hard)
3. **Best Practices** - Production-ready patterns and recommendations

### Style
- Educational, explanatory, and detailed
- Include conceptual explanations and step-by-step instructions
- Progressive complexity building on previous modules
- Real-world, production-focused examples

### Format
- Break down large documents into smaller parts to avoid token limits
- Use clear sections with headers
- Include code snippets with explanations
- Add visual elements for complex concepts

### Validation
- Review existing documents in the project knowledge base
- Ensure 100% coverage of all topics
- Validate against current Azure and GitHub features
- Test all code examples and exercises

### Technology Focus
- **GitHub Ecosystem**: GitHub Copilot (including Agents), GitHub Models, GitHub Actions, GitHub Advanced Security, Model Context Protocol (MCP)
- **Azure Platform**: Azure AI Foundry, Azure AI Search, Azure OpenAI, Cosmos DB (vector search), Azure Monitor, Microsoft Sentinel
- **Development**: Infrastructure as Code (IaC), CI/CD, DevSecOps, Multi-agent orchestration
- **Languages**: Python (primary), .NET (enterprise modules), TypeScript/JavaScript

## 🧩 Module Design

### Language Distribution
- **Modules 1-20**: Python as primary language
- **Modules 21-25**: Python with TypeScript for agent development
- **Module 26**: .NET focused (enterprise)
- **Module 27**: COBOL modernization (legacy to modern)
- **Module 28**: Mixed languages (security focus)
- **Module 29**: .NET enterprise review
- **Module 30**: All languages (comprehensive challenge)

### Each Module Must Include
1. **Conceptual Explanation** - Theory and principles
2. **3 Progressive Exercises**:
   - Easy (⭐): 30-45 minutes, guided implementation
   - Medium (⭐⭐): 45-60 minutes, real-world scenario
   - Hard (⭐⭐⭐): 60-90 minutes, production challenge
3. **Visual Diagrams** - Mermaid or SVG for architecture/flow
4. **Official Links** - Microsoft Learn, GitHub Docs, Azure Documentation
5. **Independent Project** - Apply learning in new context
6. **Copilot Prompt Suggestions** - Best practices for AI assistance

### Copilot Prompt Format
```markdown
**Copilot Prompt Suggestion:**
"Create a Python function that [specific task] with:
- [Requirement 1]
- [Requirement 2]
- [Error handling]
Include type hints and documentation."

**Expected Output:**
A complete function with proper structure, error handling, and documentation.
(Note: Output may vary based on context and model updates)
```

## 📘 Documentation Requirements

### Repository-Level Documentation (Required)
These documents must exist at the repository root:

1. **README.md** - Complete workshop overview (30 modules)
2. **PREREQUISITES.md** - Detailed setup requirements for all tracks
3. **QUICKSTART.md** - Get started in 5 minutes guide
4. **TROUBLESHOOTING.md** - Common issues and solutions
5. **FAQ.md** - Frequently asked questions
6. **PROMPT-GUIDE.md** - Best practices for AI prompting
7. **GITOPS-GUIDE.md** - GitOps implementation patterns
8. **scripts/** - Repository-wide scripts:
   - `setup-workshop.sh` - Complete environment setup
   - `validate-prerequisites.sh` - Check all requirements
   - `cleanup-resources.sh` - Remove Azure resources
   - `quick-start.sh` - Fast track setup
9. **infrastructure/** - IaC templates:
   - `bicep/` - Azure Bicep templates for all modules
   - `terraform/` - Terraform alternatives
   - `github-actions/` - Reusable workflows
   - `arm-templates/` - Legacy ARM support
10. **docs/** - Additional documentation:
    - `architecture-decisions.md`
    - `security-guidelines.md`
    - `cost-optimization.md`
    - `monitoring-setup.md`

### Per Module Documentation
1. **README.md** - Module overview, objectives, duration
2. **prerequisites.md** - Module-specific requirements
3. **exercises/** - Three exercise folders:
   - **part1/** - Instructions (split if needed)
   - **part2/** - Continuation for complex exercises
   - **starter/** - Starting code
   - **solution/** - Complete solution
   - **tests/** - Validation tests
4. **best-practices.md** - Production patterns
5. **resources/** - Module-specific resources
6. **troubleshooting.md** - Module-specific issues

### Exercise Documentation Structure
For exercises that exceed document limits:
```
exercise1-easy/
├── instructions/
│   ├── part1.md    # Setup and initial steps
│   ├── part2.md    # Implementation details
│   └── part3.md    # Testing and validation
├── starter/
├── solution/
└── tests/
```

## 🔌 GitHub Copilot & Agent Features

### Core Copilot Features (Modules 1-10)
- Code suggestions and completions
- Multi-file editing
- Workspace management
- Chat and edit modes
- Custom instructions
- Context optimization

### Advanced Features (Modules 11-20)
- Copilot for Testing
- Copilot Autofix
- Code optimization
- Architecture suggestions
- Security scanning integration
- Performance recommendations

### Agent Development (Modules 21-25)
- GitHub Copilot Agents
- Custom agent creation
- Tool integration
- Function calling
- Agent communication
- Multi-agent orchestration

## 🤖 AI Agent & MCP Coverage

### Module 21-23: Agent Fundamentals
- Agent architectures
- Building custom agents
- Model Context Protocol (MCP) deep dive
- MCP server development
- MCP client implementation
- Security considerations

### Module 24-25: Advanced Orchestration
- Multi-agent coordination
- Complex workflows
- Error handling and recovery
- Performance optimization
- Enterprise patterns
- Production deployment

## ☁️ Azure Integration

### AI Services
- **Azure AI Foundry** - Complete AI platform
- **Azure OpenAI Service** - GPT-4, embeddings
- **Azure AI Search** - Vector search capabilities
- **Cosmos DB** - Vector search support
- **GitHub Models** - Experimentation to production flow

### Infrastructure & DevOps
- **Azure Kubernetes Service (AKS)**
- **Azure Functions** - Serverless compute
- **Azure Monitor** - Application Insights, Log Analytics
- **Microsoft Sentinel** - SIEM and SOAR
- **Microsoft Defender for Cloud** - Security posture

### Monitoring & Observability
- Azure Monitor for cloud resources
- Application Insights for applications
- Prometheus & Grafana for metrics
- Distributed tracing
- Custom dashboards

## 🔗 MCP Integration Requirements

### Use Official MCPs Only
- Azure MCP for cloud services
- GitHub MCP for development tools
- No custom MCP servers unless teaching MCP development

### MCP Implementation Topics
- Understanding MCP architecture
- Building MCP servers (Module 23)
- Creating MCP clients
- Security and authentication
- Real-world integration examples
- Enterprise deployment patterns

## 📋 Module-Specific Requirements

### Fundamentals Track (1-5)
- Focus on core concepts
- Gentle learning curve
- Lots of guided examples
- Building confidence

### Intermediate Track (6-10)
- Real application building
- Integration patterns
- Best practices introduction
- Team collaboration

### Advanced Track (11-15)
- Architecture focus
- Scalability patterns
- Production considerations
- Cost optimization

### Enterprise Track (16-20)
- Security-first approach
- Compliance requirements
- Monitoring and observability
- Deployment strategies

### AI Agents Track (21-25)
- Deep technical content
- Hands-on agent building
- MCP protocol mastery
- Complex orchestration

### Enterprise Mastery (26-28)
- .NET enterprise patterns (Module 26)
- COBOL modernization (Module 27)
- Agentic DevOps (Module 28)

### Validation Track (29-30)
- Comprehensive review (.NET focus - Module 29)
- Ultimate challenge covering all content (Module 30)

## ✅ Quality Checklist

Each module must pass these criteria:
- [ ] Three working exercises with solutions
- [ ] Clear learning objectives
- [ ] Production-ready code examples
- [ ] Proper error handling demonstrated
- [ ] Security best practices included
- [ ] Performance considerations addressed
- [ ] Cost implications discussed
- [ ] Monitoring and logging implemented
- [ ] Documentation complete and clear
- [ ] All dependencies listed and tested

## 📚 Reference Materials

Use only official documentation sources:
- [GitHub Copilot Documentation](https://docs.github.com/copilot)
- [GitHub Models Documentation](https://docs.github.com/models)
- [Azure AI Documentation](https://learn.microsoft.com/azure/ai-services/)
- [Azure AI Search](https://learn.microsoft.com/azure/search/)
- [Model Context Protocol Specification](https://github.com/modelcontextprotocol/specification)
- [Microsoft Learn](https://learn.microsoft.com)
- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Azure Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)

---

## 🚀 Final Notes

This workshop represents the most comprehensive AI development program available. Maintain the highest standards of quality, ensuring every participant gains practical, production-ready skills that transform their career. The journey from Module 1 to Module 30 should be smooth, logical, and inspiring.

**Remember**: We're not just teaching tools—we're creating AI development masters who will lead the industry forward.