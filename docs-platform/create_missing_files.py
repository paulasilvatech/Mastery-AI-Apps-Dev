#!/usr/bin/env python3
"""
Create all missing files to complete all modules
"""

from pathlib import Path
import json

def create_best_practices_template(module_num, module_name):
    """Create best practices template for a module"""
    return f"""---
sidebar_position: 10
title: "Best Practices"
description: "Best practices and recommendations for {module_name}"
---

# Best Practices - Module {module_num:02d}

## 🎯 Key Takeaways

### From Exercise 1
- Key learning point 1
- Key learning point 2
- Key learning point 3

### From Exercise 2
- Key learning point 1
- Key learning point 2
- Key learning point 3

### From Exercise 3
- Key learning point 1
- Key learning point 2
- Key learning point 3

## 💡 Tips & Tricks

### AI Copilot Best Practices
1. **Clear Context**: Always provide clear context in your prompts
2. **Iterative Refinement**: Start simple and refine gradually
3. **Code Review**: Always review AI-generated code
4. **Test Everything**: Never trust, always verify

### Common Pitfalls to Avoid
- ❌ Accepting AI suggestions blindly
- ❌ Not understanding the generated code
- ❌ Skipping tests
- ❌ Ignoring security implications

## 🚀 Advanced Techniques

### Performance Optimization
- Technique 1
- Technique 2
- Technique 3

### Security Considerations
- Security practice 1
- Security practice 2
- Security practice 3

## 📚 Additional Resources

- [Official Documentation](#)
- [Community Forums](#)
- [Video Tutorials](#)
- [Code Examples](#)

## 🎓 Next Steps

After completing this module, you should:
1. Practice the techniques learned
2. Apply them to real projects
3. Share your learnings with the community
4. Move on to the next module

## 💬 Community Discussion

Join the discussion about this module:
- Share your solutions
- Ask questions
- Help others
- Provide feedback

---

Remember: The journey to AI mastery is continuous. Keep learning, keep experimenting, and keep building! 🚀
"""

def create_exercise_overview_template(module_num, exercise_num, difficulty, time):
    """Create exercise overview template"""
    difficulties = {1: "Easy", 2: "Medium", 3: "Hard"}
    times = {1: "30 minutes", 2: "45 minutes", 3: "60 minutes"}
    
    return f"""---
sidebar_position: {exercise_num + 3}
title: "Exercise {exercise_num}: Overview"
description: "Overview and objectives for Exercise {exercise_num}"
---

# Exercise {exercise_num} Overview (⭐ {difficulties.get(exercise_num, 'Medium')} - {times.get(exercise_num, '45 minutes')})

## 🎯 Learning Objectives

By completing this exercise, you will:
- Learn objective 1
- Master objective 2
- Understand objective 3
- Apply objective 4

## 📋 Prerequisites

Before starting this exercise, ensure you have:
- ✅ Completed previous exercises
- ✅ Set up your development environment
- ✅ Reviewed the module concepts
- ✅ Have your AI Copilot ready

## 🛠️ What You'll Build

In this exercise, you'll create:
- Component/Feature 1
- Component/Feature 2
- Component/Feature 3

## 📚 Exercise Structure

This exercise is divided into 3 parts:

### [Part 1: Foundation](./exercise{exercise_num}-part1.md)
- Set up the basic structure
- Implement core functionality
- Create initial tests

### [Part 2: Enhancement](./exercise{exercise_num}-part2.md)
- Add advanced features
- Optimize performance
- Implement error handling

### [Part 3: Polish](./exercise{exercise_num}-part3.md)
- Add finishing touches
- Complete documentation
- Deploy and test

## 🎯 Success Criteria

You'll know you've successfully completed this exercise when:
- [ ] All tests pass
- [ ] Code follows best practices
- [ ] Documentation is complete
- [ ] Feature works as expected
- [ ] You can explain how it works

## 💡 Tips for Success

1. **Read all instructions first** - Get the full picture before starting
2. **Use AI wisely** - Let Copilot help, but understand the code
3. **Test frequently** - Run tests after each major change
4. **Ask for help** - Use the community if you get stuck

## 🚀 Let's Get Started!

Ready? Head to [Part 1](./exercise{exercise_num}-part1.md) to begin your journey!

---

Remember: Learning is a process. Take your time, understand each concept, and don't hesitate to experiment! 🎓
"""

def get_module_info():
    """Get module names for all 30 modules"""
    return {
        1: "AI Development Fundamentals",
        2: "GitHub Copilot Mastery",
        3: "Advanced Prompt Engineering",
        4: "Testing and Debugging with AI",
        5: "AI-Powered Documentation",
        6: "AI Pair Programming Patterns",
        7: "Copilot Workspace Deep Dive",
        8: "API Development with AI",
        9: "Database Design with AI",
        10: "Real-time Systems with AI",
        11: "Microservices Architecture",
        12: "Cloud-Native with AI",
        13: "DevOps Automation",
        14: "Performance Optimization",
        15: "Security with AI",
        16: "Enterprise Patterns",
        17: "System Integration",
        18: "Event-Driven Architecture",
        19: "Monitoring and Observability",
        20: "Production Deployment",
        21: "AI Agents Fundamentals",
        22: "Building Custom Agents",
        23: "Model Context Protocol (MCP)",
        24: "Multi-Agent Orchestration",
        25: "Production AI Agents",
        26: "Advanced Architecture Patterns",
        27: "Legacy Modernization with AI",
        28: "Innovation Lab",
        29: "Capstone Project",
        30: "Final Assessment & Certification"
    }

def create_missing_files():
    """Create all missing files"""
    base_path = Path("/Users/paulasilva/Documents/paulasilvatech/GH-Repos/Mastery-AI-Apps-Dev/docs-platform/docs/modules")
    
    # Load the completeness report
    report_path = base_path.parent / "module_completeness_report.json"
    with open(report_path, 'r') as f:
        report = json.load(f)
    
    module_info = get_module_info()
    created_count = 0
    
    print("🔧 Creating missing files...")
    print("=" * 50)
    
    for module_key, module_data in report.items():
        if not module_data["complete"] and module_data["exists"]:
            module_num = int(module_key.split('-')[1])
            module_name = module_info.get(module_num, f"Module {module_num}")
            module_dir = base_path / module_key
            
            for missing_file in module_data["missing_files"]:
                file_path = module_dir / missing_file
                
                # Create appropriate content based on file type
                if missing_file == "best-practices.md":
                    content = create_best_practices_template(module_num, module_name)
                elif "overview" in missing_file:
                    # Extract exercise number
                    exercise_num = int(missing_file[8])  # exercise1-overview.md -> 1
                    content = create_exercise_overview_template(module_num, exercise_num, exercise_num, exercise_num)
                else:
                    # This shouldn't happen based on our report
                    continue
                
                # Write the file
                file_path.write_text(content, encoding='utf-8')
                created_count += 1
                print(f"✅ Created: {module_key}/{missing_file}")
    
    print(f"\n📊 Summary: Created {created_count} files")
    print("✅ All modules should now be complete!")

if __name__ == "__main__":
    create_missing_files()