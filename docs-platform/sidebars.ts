import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

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
    {
      type: 'category',
      label: '🟢 Fundamentals Track',
      items: [
        {
          type: 'category',
          label: 'Module 01: AI Development Fundamentals',
          items: [
            'modules/module-01/index',
            'modules/module-01/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-01/exercise1-overview',
                'modules/module-01/exercise1-part1',
                'modules/module-01/exercise1-part2',
                'modules/module-01/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-01/exercise2-overview',
                'modules/module-01/exercise2-part1',
                'modules/module-01/exercise2-part2',
                'modules/module-01/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-01/exercise3-overview',
                'modules/module-01/exercise3-part1',
                'modules/module-01/exercise3-part2',
                'modules/module-01/exercise3-part3',
              ],
            },
            'modules/module-01/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 02: GitHub Copilot Mastery',
          items: [
            'modules/module-02/index',
            'modules/module-02/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-02/exercise1-overview',
                'modules/module-02/exercise1-part1',
                'modules/module-02/exercise1-part2',
                'modules/module-02/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-02/exercise2-overview',
                'modules/module-02/exercise2-part1',
                'modules/module-02/exercise2-part2',
                'modules/module-02/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-02/exercise3-overview',
                'modules/module-02/exercise3-part1',
                'modules/module-02/exercise3-part2',
                'modules/module-02/exercise3-part3',
              ],
            },
            'modules/module-02/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 03: Advanced Prompt Engineering',
          items: [
            'modules/module-03/index',
            'modules/module-03/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-03/exercise1-overview',
                'modules/module-03/exercise1-part1',
                'modules/module-03/exercise1-part2',
                'modules/module-03/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-03/exercise2-overview',
                'modules/module-03/exercise2-part1',
                'modules/module-03/exercise2-part2',
                'modules/module-03/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-03/exercise3-overview',
                'modules/module-03/exercise3-part1',
                'modules/module-03/exercise3-part2',
                'modules/module-03/exercise3-part3',
              ],
            },
            'modules/module-03/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 04: Testing and Debugging with AI',
          items: [
            'modules/module-04/index',
            'modules/module-04/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-04/exercise1-overview',
                'modules/module-04/exercise1-part1',
                'modules/module-04/exercise1-part2',
                'modules/module-04/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-04/exercise2-overview',
                'modules/module-04/exercise2-part1',
                'modules/module-04/exercise2-part2',
                'modules/module-04/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-04/exercise3-overview',
                'modules/module-04/exercise3-part1',
                'modules/module-04/exercise3-part2',
                'modules/module-04/exercise3-part3',
              ],
            },
            'modules/module-04/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 05: AI-Powered Documentation',
          items: [
            'modules/module-05/index',
            'modules/module-05/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-05/exercise1-overview',
                'modules/module-05/exercise1-part1',
                'modules/module-05/exercise1-part2',
                'modules/module-05/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-05/exercise2-overview',
                'modules/module-05/exercise2-part1',
                'modules/module-05/exercise2-part2',
                'modules/module-05/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-05/exercise3-overview',
                'modules/module-05/exercise3-part1',
                'modules/module-05/exercise3-part2',
                'modules/module-05/exercise3-part3',
              ],
            },
            'modules/module-05/best-practices',
          ],
        },
      ],
      collapsible: true,
      collapsed: false,
    },
    {
      type: 'category',
      label: '🔵 Intermediate Development',
      items: [
        {
          type: 'category',
          label: 'Module 06: AI Pair Programming Patterns',
          items: [
            'modules/module-06/index',
            'modules/module-06/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-06/exercise1-overview',
                'modules/module-06/exercise1-part1',
                'modules/module-06/exercise1-part2',
                'modules/module-06/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-06/exercise2-overview',
                'modules/module-06/exercise2-part1',
                'modules/module-06/exercise2-part2',
                'modules/module-06/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-06/exercise3-overview',
                'modules/module-06/exercise3-part1',
                'modules/module-06/exercise3-part2',
                'modules/module-06/exercise3-part3',
              ],
            },
            'modules/module-06/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 07: Copilot Workspace Deep Dive',
          items: [
            'modules/module-07/index',
            'modules/module-07/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-07/exercise1-overview',
                'modules/module-07/exercise1-part1',
                'modules/module-07/exercise1-part2',
                'modules/module-07/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-07/exercise2-overview',
                'modules/module-07/exercise2-part1',
                'modules/module-07/exercise2-part2',
                'modules/module-07/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-07/exercise3-overview',
                'modules/module-07/exercise3-part1',
                'modules/module-07/exercise3-part2',
                'modules/module-07/exercise3-part3',
              ],
            },
            'modules/module-07/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 08: API Development with AI',
          items: [
            'modules/module-08/index',
            'modules/module-08/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-08/exercise1-overview',
                'modules/module-08/exercise1-part1',
                'modules/module-08/exercise1-part2',
                'modules/module-08/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-08/exercise2-overview',
                'modules/module-08/exercise2-part1',
                'modules/module-08/exercise2-part2',
                'modules/module-08/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-08/exercise3-overview',
                'modules/module-08/exercise3-part1',
                'modules/module-08/exercise3-part2',
                'modules/module-08/exercise3-part3',
              ],
            },
            'modules/module-08/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 09: Database Design with AI',
          items: [
            'modules/module-09/index',
            'modules/module-09/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-09/exercise1-overview',
                'modules/module-09/exercise1-part1',
                'modules/module-09/exercise1-part2',
                'modules/module-09/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-09/exercise2-overview',
                'modules/module-09/exercise2-part1',
                'modules/module-09/exercise2-part2',
                'modules/module-09/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-09/exercise3-overview',
                'modules/module-09/exercise3-part1',
                'modules/module-09/exercise3-part2',
                'modules/module-09/exercise3-part3',
              ],
            },
            'modules/module-09/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 10: Real-time Systems with AI',
          items: [
            'modules/module-10/index',
            'modules/module-10/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-10/exercise1-overview',
                'modules/module-10/exercise1-part1',
                'modules/module-10/exercise1-part2',
                'modules/module-10/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-10/exercise2-overview',
                'modules/module-10/exercise2-part1',
                'modules/module-10/exercise2-part2',
                'modules/module-10/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-10/exercise3-overview',
                'modules/module-10/exercise3-part1',
                'modules/module-10/exercise3-part2',
                'modules/module-10/exercise3-part3',
              ],
            },
            'modules/module-10/best-practices',
          ],
        },
      ],
      collapsible: true,
      collapsed: true,
    },
    {
      type: 'category',
      label: '🟠 Advanced Patterns',
      items: [
        {
          type: 'category',
          label: 'Module 11: Microservices Architecture',
          items: [
            'modules/module-11/index',
            'modules/module-11/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-11/exercise1-overview',
                'modules/module-11/exercise1-part1',
                'modules/module-11/exercise1-part2',
                'modules/module-11/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-11/exercise2-overview',
                'modules/module-11/exercise2-part1',
                'modules/module-11/exercise2-part2',
                'modules/module-11/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-11/exercise3-overview',
                'modules/module-11/exercise3-part1',
                'modules/module-11/exercise3-part2',
                'modules/module-11/exercise3-part3',
              ],
            },
            'modules/module-11/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 12: Cloud-Native with AI',
          items: [
            'modules/module-12/index',
            'modules/module-12/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-12/exercise1-overview',
                'modules/module-12/exercise1-part1',
                'modules/module-12/exercise1-part2',
                'modules/module-12/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-12/exercise2-overview',
                'modules/module-12/exercise2-part1',
                'modules/module-12/exercise2-part2',
                'modules/module-12/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-12/exercise3-overview',
                'modules/module-12/exercise3-part1',
                'modules/module-12/exercise3-part2',
                'modules/module-12/exercise3-part3',
              ],
            },
            'modules/module-12/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 13: DevOps Automation',
          items: [
            'modules/module-13/index',
            'modules/module-13/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-13/exercise1-overview',
                'modules/module-13/exercise1-part1',
                'modules/module-13/exercise1-part2',
                'modules/module-13/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-13/exercise2-overview',
                'modules/module-13/exercise2-part1',
                'modules/module-13/exercise2-part2',
                'modules/module-13/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-13/exercise3-overview',
                'modules/module-13/exercise3-part1',
                'modules/module-13/exercise3-part2',
                'modules/module-13/exercise3-part3',
              ],
            },
            'modules/module-13/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 14: Performance Optimization',
          items: [
            'modules/module-14/index',
            'modules/module-14/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-14/exercise1-overview',
                'modules/module-14/exercise1-part1',
                'modules/module-14/exercise1-part2',
                'modules/module-14/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-14/exercise2-overview',
                'modules/module-14/exercise2-part1',
                'modules/module-14/exercise2-part2',
                'modules/module-14/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-14/exercise3-overview',
                'modules/module-14/exercise3-part1',
                'modules/module-14/exercise3-part2',
                'modules/module-14/exercise3-part3',
              ],
            },
            'modules/module-14/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 15: Security with AI',
          items: [
            'modules/module-15/index',
            'modules/module-15/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-15/exercise1-overview',
                'modules/module-15/exercise1-part1',
                'modules/module-15/exercise1-part2',
                'modules/module-15/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-15/exercise2-overview',
                'modules/module-15/exercise2-part1',
                'modules/module-15/exercise2-part2',
                'modules/module-15/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-15/exercise3-overview',
                'modules/module-15/exercise3-part1',
                'modules/module-15/exercise3-part2',
                'modules/module-15/exercise3-part3',
              ],
            },
            'modules/module-15/best-practices',
          ],
        },
      ],
      collapsible: true,
      collapsed: true,
    },
    {
      type: 'category',
      label: '🔴 Enterprise Solutions',
      items: [
        {
          type: 'category',
          label: 'Module 16: Enterprise Patterns',
          items: [
            'modules/module-16/index',
            'modules/module-16/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-16/exercise1-overview',
                'modules/module-16/exercise1-part1',
                'modules/module-16/exercise1-part2',
                'modules/module-16/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-16/exercise2-overview',
                'modules/module-16/exercise2-part1',
                'modules/module-16/exercise2-part2',
                'modules/module-16/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-16/exercise3-overview',
                'modules/module-16/exercise3-part1',
                'modules/module-16/exercise3-part2',
                'modules/module-16/exercise3-part3',
              ],
            },
            'modules/module-16/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 17: System Integration',
          items: [
            'modules/module-17/index',
            'modules/module-17/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-17/exercise1-overview',
                'modules/module-17/exercise1-part1',
                'modules/module-17/exercise1-part2',
                'modules/module-17/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-17/exercise2-overview',
                'modules/module-17/exercise2-part1',
                'modules/module-17/exercise2-part2',
                'modules/module-17/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-17/exercise3-overview',
                'modules/module-17/exercise3-part1',
                'modules/module-17/exercise3-part2',
                'modules/module-17/exercise3-part3',
              ],
            },
            'modules/module-17/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 18: Event-Driven Architecture',
          items: [
            'modules/module-18/index',
            'modules/module-18/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-18/exercise1-overview',
                'modules/module-18/exercise1-part1',
                'modules/module-18/exercise1-part2',
                'modules/module-18/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-18/exercise2-overview',
                'modules/module-18/exercise2-part1',
                'modules/module-18/exercise2-part2',
                'modules/module-18/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-18/exercise3-overview',
                'modules/module-18/exercise3-part1',
                'modules/module-18/exercise3-part2',
                'modules/module-18/exercise3-part3',
              ],
            },
            'modules/module-18/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 19: Monitoring and Observability',
          items: [
            'modules/module-19/index',
            'modules/module-19/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-19/exercise1-overview',
                'modules/module-19/exercise1-part1',
                'modules/module-19/exercise1-part2',
                'modules/module-19/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-19/exercise2-overview',
                'modules/module-19/exercise2-part1',
                'modules/module-19/exercise2-part2',
                'modules/module-19/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-19/exercise3-overview',
                'modules/module-19/exercise3-part1',
                'modules/module-19/exercise3-part2',
                'modules/module-19/exercise3-part3',
              ],
            },
            'modules/module-19/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 20: Production Deployment',
          items: [
            'modules/module-20/index',
            'modules/module-20/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-20/exercise1-overview',
                'modules/module-20/exercise1-part1',
                'modules/module-20/exercise1-part2',
                'modules/module-20/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-20/exercise2-overview',
                'modules/module-20/exercise2-part1',
                'modules/module-20/exercise2-part2',
                'modules/module-20/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-20/exercise3-overview',
                'modules/module-20/exercise3-part1',
                'modules/module-20/exercise3-part2',
                'modules/module-20/exercise3-part3',
              ],
            },
            'modules/module-20/best-practices',
          ],
        },
      ],
      collapsible: true,
      collapsed: true,
    },
    {
      type: 'category',
      label: '🟣 AI Agents & MCP',
      items: [
        {
          type: 'category',
          label: 'Module 21: AI Agents Fundamentals',
          items: [
            'modules/module-21/index',
            'modules/module-21/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-21/exercise1-overview',
                'modules/module-21/exercise1-part1',
                'modules/module-21/exercise1-part2',
                'modules/module-21/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-21/exercise2-overview',
                'modules/module-21/exercise2-part1',
                'modules/module-21/exercise2-part2',
                'modules/module-21/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-21/exercise3-overview',
                'modules/module-21/exercise3-part1',
                'modules/module-21/exercise3-part2',
                'modules/module-21/exercise3-part3',
              ],
            },
            'modules/module-21/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 22: Building Custom Agents',
          items: [
            'modules/module-22/index',
            'modules/module-22/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-22/exercise1-overview',
                'modules/module-22/exercise1-part1',
                'modules/module-22/exercise1-part2',
                'modules/module-22/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-22/exercise2-overview',
                'modules/module-22/exercise2-part1',
                'modules/module-22/exercise2-part2',
                'modules/module-22/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-22/exercise3-overview',
                'modules/module-22/exercise3-part1',
                'modules/module-22/exercise3-part2',
                'modules/module-22/exercise3-part3',
              ],
            },
            'modules/module-22/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 23: Model Context Protocol (MCP)',
          items: [
            'modules/module-23/index',
            'modules/module-23/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-23/exercise1-overview',
                'modules/module-23/exercise1-part1',
                'modules/module-23/exercise1-part2',
                'modules/module-23/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-23/exercise2-overview',
                'modules/module-23/exercise2-part1',
                'modules/module-23/exercise2-part2',
                'modules/module-23/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-23/exercise3-overview',
                'modules/module-23/exercise3-part1',
                'modules/module-23/exercise3-part2',
                'modules/module-23/exercise3-part3',
              ],
            },
            'modules/module-23/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 24: Multi-Agent Orchestration',
          items: [
            'modules/module-24/index',
            'modules/module-24/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-24/exercise1-overview',
                'modules/module-24/exercise1-part1',
                'modules/module-24/exercise1-part2',
                'modules/module-24/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-24/exercise2-overview',
                'modules/module-24/exercise2-part1',
                'modules/module-24/exercise2-part2',
                'modules/module-24/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-24/exercise3-overview',
                'modules/module-24/exercise3-part1',
                'modules/module-24/exercise3-part2',
                'modules/module-24/exercise3-part3',
              ],
            },
            'modules/module-24/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 25: Production AI Agents',
          items: [
            'modules/module-25/index',
            'modules/module-25/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-25/exercise1-overview',
                'modules/module-25/exercise1-part1',
                'modules/module-25/exercise1-part2',
                'modules/module-25/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-25/exercise2-overview',
                'modules/module-25/exercise2-part1',
                'modules/module-25/exercise2-part2',
                'modules/module-25/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-25/exercise3-overview',
                'modules/module-25/exercise3-part1',
                'modules/module-25/exercise3-part2',
                'modules/module-25/exercise3-part3',
              ],
            },
            'modules/module-25/best-practices',
          ],
        },
      ],
      collapsible: true,
      collapsed: true,
    },
    {
      type: 'category',
      label: '⭐ Enterprise Mastery',
      items: [
        {
          type: 'category',
          label: 'Module 26: Advanced Architecture Patterns',
          items: [
            'modules/module-26/index',
            'modules/module-26/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-26/exercise1-overview',
                'modules/module-26/exercise1-part1',
                'modules/module-26/exercise1-part2',
                'modules/module-26/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-26/exercise2-overview',
                'modules/module-26/exercise2-part1',
                'modules/module-26/exercise2-part2',
                'modules/module-26/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-26/exercise3-overview',
                'modules/module-26/exercise3-part1',
                'modules/module-26/exercise3-part2',
                'modules/module-26/exercise3-part3',
              ],
            },
            'modules/module-26/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 27: Legacy Modernization with AI',
          items: [
            'modules/module-27/index',
            'modules/module-27/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-27/exercise1-overview',
                'modules/module-27/exercise1-part1',
                'modules/module-27/exercise1-part2',
                'modules/module-27/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-27/exercise2-overview',
                'modules/module-27/exercise2-part1',
                'modules/module-27/exercise2-part2',
                'modules/module-27/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-27/exercise3-overview',
                'modules/module-27/exercise3-part1',
                'modules/module-27/exercise3-part2',
                'modules/module-27/exercise3-part3',
              ],
            },
            'modules/module-27/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 28: Innovation Lab',
          items: [
            'modules/module-28/index',
            'modules/module-28/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-28/exercise1-overview',
                'modules/module-28/exercise1-part1',
                'modules/module-28/exercise1-part2',
                'modules/module-28/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-28/exercise2-overview',
                'modules/module-28/exercise2-part1',
                'modules/module-28/exercise2-part2',
                'modules/module-28/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-28/exercise3-overview',
                'modules/module-28/exercise3-part1',
                'modules/module-28/exercise3-part2',
                'modules/module-28/exercise3-part3',
              ],
            },
            'modules/module-28/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 29: Capstone Project',
          items: [
            'modules/module-29/index',
            'modules/module-29/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-29/exercise1-overview',
                'modules/module-29/exercise1-part1',
                'modules/module-29/exercise1-part2',
                'modules/module-29/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-29/exercise2-overview',
                'modules/module-29/exercise2-part1',
                'modules/module-29/exercise2-part2',
                'modules/module-29/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-29/exercise3-overview',
                'modules/module-29/exercise3-part1',
                'modules/module-29/exercise3-part2',
                'modules/module-29/exercise3-part3',
              ],
            },
            'modules/module-29/best-practices',
          ],
        },
        {
          type: 'category',
          label: 'Module 30: Final Assessment & Certification',
          items: [
            'modules/module-30/index',
            'modules/module-30/prerequisites',
            {
              type: 'category',
              label: 'Exercise 1',
              items: [
                'modules/module-30/exercise1-overview',
                'modules/module-30/exercise1-part1',
                'modules/module-30/exercise1-part2',
                'modules/module-30/exercise1-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 2',
              items: [
                'modules/module-30/exercise2-overview',
                'modules/module-30/exercise2-part1',
                'modules/module-30/exercise2-part2',
                'modules/module-30/exercise2-part3',
              ],
            },
            {
              type: 'category',
              label: 'Exercise 3',
              items: [
                'modules/module-30/exercise3-overview',
                'modules/module-30/exercise3-part1',
                'modules/module-30/exercise3-part2',
                'modules/module-30/exercise3-part3',
              ],
            },
            'modules/module-30/best-practices',
          ],
        },
      ],
      collapsible: true,
      collapsed: true,
    },
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
        'infrastructure/infrastructure-index',
        'scripts/scripts-index',
      ],
      collapsible: true,
      collapsed: true,
    },
  ],
};

export default sidebars;