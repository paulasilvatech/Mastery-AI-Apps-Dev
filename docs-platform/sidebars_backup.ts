import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

/**
 * Creating a sidebar enables you to:
 - create an ordered group of docs
 - render a sidebar for each doc of that group
 - provide next/previous navigation

 The sidebars can be generated from the filesystem, or explicitly defined here.

 Create as many sidebars as you want.
 */
import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

/**
 * Creating a sidebar enables you to:
 - create an ordered group of docs
 - render a sidebar for each doc of that group
 - provide next/previous navigation

 The sidebars can be generated from the filesystem, or explicitly defined here.

 Create as many sidebars as you want.
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
        'modules/module-01/index',
        'modules/module-02/index',
        'modules/module-03/index',
        'modules/module-04/index',
        'modules/module-05/index',
      ],
      collapsible: true,
      collapsed: false,
    },
    {
      type: 'category',
      label: '🔵 Intermediate Development',
      items: [
        'modules/module-06/index',
        'modules/module-07/index',
        'modules/module-08/index',
        'modules/module-09/index',
        'modules/module-10/index',
      ],
      collapsible: true,
      collapsed: true,
    },
    {
      type: 'category',
      label: '🟠 Advanced Patterns',
      items: [
        'modules/module-11/index',
        'modules/module-12/index',
        'modules/module-13/index',
        'modules/module-14/index',
        'modules/module-15/index',
      ],
      collapsible: true,
      collapsed: true,
    },
    {
      type: 'category',
      label: '🔴 Enterprise Solutions',
      items: [
        'modules/module-16/index',
        'modules/module-17/index',
        'modules/module-18/index',
        'modules/module-19/index',
        'modules/module-20/index',
      ],
      collapsible: true,
      collapsed: true,
    },
    {
      type: 'category',
      label: '🟣 AI Agents & MCP',
      items: [
        'modules/module-21/index',
        'modules/module-22/index',
        'modules/module-23/index',
        'modules/module-24/index',
        'modules/module-25/index',
      ],
      collapsible: true,
      collapsed: true,
    },
    {
      type: 'category',
      label: '⭐ Enterprise Mastery',
      items: [
        'modules/module-26/index',
        'modules/module-27/index',
        'modules/module-28/index',
        'modules/module-29/index',
        'modules/module-30/index',
      ],
      collapsible: true,
      collapsed: true,
    },
    {
      type: 'category',
      label: '📥 Downloads & Resources',
      items: [
        'downloads/index',
      ],
      collapsible: true,
      collapsed: true,
    },
  ],
};

export default sidebars;
