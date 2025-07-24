#!/usr/bin/env python3
"""
Generate complete sidebar configuration with all modules and exercises
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

def generate_module_structure(module_num, module_name):
    """Generate sidebar structure for a single module"""
    module_str = f"{module_num:02d}"
    return f"""        {{
          type: 'category',
          label: 'Module {module_str}: {module_name}',
          items: [
            'modules/module-{module_str}/index',
            'modules/module-{module_str}/prerequisites',
            {{
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-{module_str}/exercise1-overview',
                'modules/module-{module_str}/exercise1-part1',
                'modules/module-{module_str}/exercise1-part2',
                'modules/module-{module_str}/exercise1-part3',
              ],
            }},
            {{
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-{module_str}/exercise2-overview',
                'modules/module-{module_str}/exercise2-part1',
                'modules/module-{module_str}/exercise2-part2',
                'modules/module-{module_str}/exercise2-part3',
              ],
            }},
            {{
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-{module_str}/exercise3-overview',
                'modules/module-{module_str}/exercise3-part1',
                'modules/module-{module_str}/exercise3-part2',
                'modules/module-{module_str}/exercise3-part3',
              ],
            }},
            'modules/module-{module_str}/best-practices',
          ],
        }}"""

def generate_track(track_name, track_emoji, module_range, collapsed=True):
    """Generate a track with all its modules"""
    modules = get_module_info()
    module_items = []
    
    for i in module_range:
        module_items.append(generate_module_structure(i, modules[i]))
    
    return f"""    {{
      type: 'category',
      label: '{track_emoji} {track_name}',
      items: [
{','.join(module_items)},
      ],
      collapsible: true,
      collapsed: {str(collapsed).lower()},
    }}"""

def generate_complete_sidebar():
    """Generate the complete sidebar configuration"""
    
    sidebar_content = """import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

/**
 * Creating a sidebar enables you to:
 - create an ordered group of docs
 - render a sidebar for each doc of that group
 - provide next/previous navigation
 */
const sidebars: SidebarsConfig = {
  // Main tutorial sidebar with all modules organized by tracks
  tutorialSidebar: [
    {
      type: 'doc',
      id: 'intro',
      label: '🚀 Welcome to AI Mastery',
    },
"""
    
    # Add all tracks
    tracks = [
        ("Fundamentals Track", "🟢", range(1, 6), False),  # Not collapsed
        ("Intermediate Development", "🔵", range(6, 11), True),
        ("Advanced Patterns", "🟠", range(11, 16), True),
        ("Enterprise Solutions", "🔴", range(16, 21), True),
        ("AI Agents & MCP", "🟣", range(21, 26), True),
        ("Enterprise Mastery", "⭐", range(26, 31), True),
    ]
    
    track_items = []
    for track_name, emoji, module_range, collapsed in tracks:
        track_items.append(generate_track(track_name, emoji, module_range, collapsed))
    
    sidebar_content += ',\n'.join(track_items)
    
    # Add additional resources
    sidebar_content += """,
    {
      type: 'category',
      label: '📚 Additional Resources',
      items: [
        'guias/quick-start',
        'guias/prerequisites',
        'guias/setup-local',
        'guias/troubleshooting',
        'guias/effective-prompts',
        'guias/faq',
        'infrastructure/index',
        'scripts/index',
      ],
      collapsible: true,
      collapsed: true,
    },
  ],
};

export default sidebars;"""
    
    return sidebar_content

def main():
    """Generate and save the complete sidebar configuration"""
    sidebar_content = generate_complete_sidebar()
    
    # Save to file
    output_path = "/Users/paulasilva/Documents/paulasilvatech/GH-Repos/Mastery-AI-Apps-Dev/docs-platform/sidebars.ts"
    with open(output_path, 'w') as f:
        f.write(sidebar_content)
    
    print("✅ Complete sidebar configuration generated!")
    print(f"📄 Saved to: {output_path}")

if __name__ == "__main__":
    main()