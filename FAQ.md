# ❓ Frequently Asked Questions

## General Questions

### Q: How long does the complete workshop take?
**A:** The workshop contains 30 modules, each designed for 3 hours. Total time is 90 hours of content. Most participants complete it in 3-6 months depending on their pace and prior experience.

### Q: Can I skip modules?
**A:** Modules are designed to build on each other. While you can skip, we strongly recommend following the sequence for best results. Each track has prerequisites clearly marked.

### Q: What if I get stuck on an exercise?
**A:** Each exercise includes:
- Step-by-step instructions
- Starter code
- Complete solutions
- Troubleshooting guide

Start with the instructions, try the starter code, and reference the solution if needed.

### Q: Is this workshop suitable for beginners?
**A:** Yes! The Fundamentals track (Modules 1-5) is designed for beginners with basic programming knowledge. No AI experience required.

### Q: Do I need to complete all 30 modules?
**A:** Not necessarily. You can stop after any track completion:
- After Module 5: Basic AI coding skills
- After Module 10: Full-stack AI development
- After Module 15: Cloud-native development
- After Module 20: Enterprise-ready skills
- After Module 25: AI agent expertise
- After Module 30: Complete mastery

## Technical Questions

### Q: Do I need to pay for GitHub Copilot?
**A:** Yes, GitHub Copilot requires a subscription ($10/month individual or $19/month business). There's a 30-day free trial available.

### Q: Can I use the Azure free tier?
**A:** Yes, most modules work with Azure free tier. Modules 16-30 may require paid services, but costs are minimal (<$50/month if following cleanup procedures).

### Q: What programming languages do I need to know?
**A:** 
- Python (primary language, modules 1-25)
- Basic JavaScript/TypeScript (agent modules 21-25)
- C#/.NET (module 26 and 29)
- COBOL knowledge helpful but not required (module 27)

### Q: Is Windows required?
**A:** No, the workshop supports Windows, macOS, and Linux. Some minor adjustments may be needed for scripts on different platforms.

### Q: Can I use a different IDE instead of VS Code?
**A:** While VS Code is recommended for the best GitHub Copilot experience, you can use:
- Visual Studio 2022 (for .NET modules)
- JetBrains IDEs with Copilot plugin
- Neovim with Copilot plugin

However, instructions are written for VS Code.

### Q: What if I don't have 16GB RAM?
**A:** You can still complete most modules with 8GB RAM by:
- Running fewer services simultaneously
- Using cloud-based development environments
- Limiting Docker container resources

## Learning Path Questions

### Q: I'm a beginner. Where should I start?
**A:** Start with Module 1 and progress sequentially. The Fundamentals track (1-5) is designed for beginners with basic programming knowledge.

### Q: I'm experienced. Can I fast-track?
**A:** Yes! Complete the prerequisite checker for each track. You might start at Module 6 or 11 depending on your experience.

### Q: What's the difference between exercises?
**A:**
- ⭐ Easy (30-45 min): Guided, step-by-step
- ⭐⭐ Medium (45-60 min): Partial guidance, real scenarios
- ⭐⭐⭐ Hard (60-90 min): Minimal guidance, production-like

### Q: Should I complete all exercises in a module?
**A:** We recommend completing all three exercises per module to fully grasp the concepts. However, if time-constrained, prioritize exercises 1 and 2.

## AI and Agent Questions

### Q: What is MCP?
**A:** Model Context Protocol (MCP) is a standard for AI agents to communicate with external tools and systems. Module 23 covers this in depth.

### Q: Do I need to understand agents before Module 21?
**A:** No, but you should complete modules 1-20 first. The agent modules (21-25) build on previous concepts.

### Q: Can I build my own agents after this workshop?
**A:** Absolutely! Modules 21-25 teach you everything needed to build production-ready AI agents.

### Q: What's the difference between GitHub Copilot and GitHub Copilot Agents?
**A:** 
- **GitHub Copilot**: AI pair programmer for code suggestions
- **GitHub Copilot Agents**: Autonomous agents that can perform complex tasks, integrate with tools, and execute workflows

## Resource Questions

### Q: How do I clean up Azure resources?
**A:** Run the cleanup script after each module:
```bash
./scripts/cleanup-resources.sh --module [number]
```

### Q: Where are the exercise solutions?
**A:** In each exercise folder: `modules/module-XX/exercises/exerciseY/solution/`

### Q: Can I use this workshop for my team?
**A:** Yes, the workshop is designed for both individual and team learning. See the team learning guide in the main README.

### Q: Are there video tutorials?
**A:** Currently, the workshop is text-based with detailed instructions. Community members sometimes share video walkthroughs in the Discussions.

## Workshop Management

### Q: How do I track my progress?
**A:** 
- Use the progress backup script: `./scripts/backup-progress.sh`
- Check off completed modules in the README
- Keep a learning journal
- Use Git commits to track your work

### Q: Can I contribute to the workshop?
**A:** Yes! We welcome contributions. See CONTRIBUTING.md for guidelines. You can:
- Report issues
- Suggest improvements
- Add examples
- Fix typos

### Q: How often is the workshop updated?
**A:** We update the workshop quarterly with:
- New Azure/GitHub features
- Community feedback improvements
- Bug fixes
- Additional examples

### Q: Is there a certificate of completion?
**A:** While we don't offer official certificates, you'll have:
- A portfolio of 30 completed modules
- 90 working exercises
- Real-world projects to showcase
- Skills that speak for themselves

## Troubleshooting Questions

### Q: Copilot isn't giving good suggestions. What's wrong?
**A:** Try:
- Writing more descriptive comments
- Providing more context in your code
- Breaking complex problems into smaller parts
- Checking your internet connection

### Q: My Azure credits are running out. What should I do?
**A:** 
- Run cleanup scripts after each module
- Use smaller resource SKUs
- Set up cost alerts
- Consider the Azure student offer if eligible

### Q: The scripts aren't working on my system. Help!
**A:** 
- Check you're running from the workshop root directory
- Ensure scripts have execute permissions
- Try the PowerShell versions on Windows
- See TROUBLESHOOTING.md for platform-specific issues

## Career Questions

### Q: Will this workshop help me get a job?
**A:** The workshop provides practical, production-ready skills highly valued in the industry. Combined with your existing experience and a strong portfolio, it significantly enhances your marketability.

### Q: What roles can I target after completing this?
**A:** Depending on your background:
- AI/ML Engineer
- Cloud Solutions Architect
- DevOps Engineer
- Full-Stack Developer (AI-Enhanced)
- AI Agent Developer
- Enterprise Architect

### Q: Should I mention this workshop on my resume?
**A:** Yes! Include it as professional development, highlighting:
- 90 hours of hands-on AI development training
- 30 production-ready projects completed
- Specific technologies mastered
- Link to your GitHub portfolio

---

## Still have questions?

1. Check module-specific READMEs
2. Search [GitHub Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions)
3. Review [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
4. Ask in the community!

Remember: There are no silly questions. We're all here to learn! 🚀

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>
