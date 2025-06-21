# Architecture Decisions

This document captures the key architectural decisions made for the Mastery AI Code Development Workshop.

## Decision Records

### ADR-001: Technology Stack
**Date**: 2025-01-20  
**Status**: Accepted  
**Context**: Need to select primary technologies for the workshop  
**Decision**: 
- Primary language: Python 3.11+
- Secondary languages: TypeScript/JavaScript (agents), C#/.NET 8 (enterprise)
- Cloud platform: Microsoft Azure
- AI services: GitHub Copilot, Azure OpenAI, GitHub Models
**Consequences**: Unified stack that aligns with industry standards

### ADR-002: Module Structure
**Date**: 2025-01-21  
**Status**: Accepted  
**Context**: Need consistent structure across 30 modules  
**Decision**: Each module contains:
- README.md (overview)
- prerequisites.md
- exercises/ (3 progressive exercises)
- best-practices.md
- resources/
**Consequences**: Predictable learning experience

### ADR-003: Infrastructure as Code
**Date**: 2025-01-22  
**Status**: Accepted  
**Context**: Need reproducible infrastructure  
**Decision**: 
- Primary: Azure Bicep
- Alternative: Terraform
- GitOps workflow with GitHub Actions
**Consequences**: Automated, version-controlled infrastructure

### ADR-004: Security Model
**Date**: 2025-01-23  
**Status**: Accepted  
**Context**: Enterprise-ready security requirements  
**Decision**:
- Zero-trust architecture
- Managed identities for Azure resources
- Key Vault for all secrets
- GitHub Advanced Security integration
**Consequences**: Secure by default, compliance-ready

### ADR-005: AI Agent Architecture
**Date**: 2025-01-24  
**Status**: Accepted  
**Context**: Need to teach modern agent patterns  
**Decision**:
- Model Context Protocol (MCP) as standard
- Multi-agent orchestration patterns
- Event-driven communication
- Tool integration via function calling
**Consequences**: Industry-standard agent development

### ADR-006: Monitoring Strategy
**Date**: 2025-01-25  
**Status**: Accepted  
**Context**: Need comprehensive observability  
**Decision**:
- Azure Monitor + Application Insights
- OpenTelemetry for tracing
- Custom dashboards per module
- Cost tracking built-in
**Consequences**: Full visibility into systems

### ADR-007: Testing Approach
**Date**: 2025-01-26  
**Status**: Accepted  
**Context**: Need to ensure quality  
**Decision**:
- Unit tests for all solutions
- Integration tests for APIs
- E2E tests for critical paths
- AI-assisted test generation
**Consequences**: High-quality, tested code

### ADR-008: Documentation Standards
**Date**: 2025-01-27  
**Status**: Accepted  
**Context**: Need clear, consistent documentation  
**Decision**:
- Markdown for all docs
- Mermaid for diagrams
- Code comments in English
- Copilot prompt examples throughout
**Consequences**: Accessible, maintainable documentation

## Design Principles

1. **Progressive Complexity**: Start simple, build complexity
2. **Production-Ready**: All code should be production-quality
3. **Cloud-Native**: Design for cloud from the start
4. **AI-First**: Leverage AI assistance throughout
5. **Security by Design**: Security is not an afterthought
6. **Cost-Conscious**: Consider and optimize costs
7. **Observable**: Everything should be monitorable
8. **Automatable**: Prefer automation over manual processes

## Technology Choices

### Core Platform
- **GitHub**: Version control, CI/CD, security scanning
- **Azure**: Cloud infrastructure and AI services
- **VS Code**: Primary development environment

### Languages & Frameworks
- **Python**: FastAPI, pytest, asyncio
- **TypeScript**: Node.js, Express, Jest
- **C#/.NET**: ASP.NET Core, xUnit
- **Infrastructure**: Bicep, Terraform

### AI Services
- **GitHub Copilot**: Code assistance
- **Azure OpenAI**: GPT-4, embeddings
- **GitHub Models**: Model experimentation
- **Azure AI Search**: Vector search, RAG

### Data Stores
- **Cosmos DB**: NoSQL with vector search
- **PostgreSQL**: Relational data
- **Redis**: Caching and session state
- **Azure Storage**: Blob storage

### Monitoring & Security
- **Azure Monitor**: Metrics and logs
- **Application Insights**: APM
- **Microsoft Sentinel**: SIEM
- **Defender for Cloud**: Security posture

## Module-Specific Architecture

### Fundamentals (1-5)
- Monolithic applications
- Local development focus
- Basic cloud deployment

### Intermediate (6-10)
- Multi-tier applications
- API-first design
- Container deployment

### Advanced (11-15)
- Microservices architecture
- Event-driven patterns
- Kubernetes orchestration

### Enterprise (16-20)
- Distributed systems
- CQRS and event sourcing
- Multi-region deployment

### AI Agents (21-25)
- Agent frameworks
- MCP implementation
- Multi-agent systems

### Mastery (26-30)
- Enterprise patterns
- Legacy modernization
- Comprehensive systems
