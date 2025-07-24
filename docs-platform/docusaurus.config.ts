import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const config: Config = {
  title: 'Master AI Apps Dev',
  tagline: 'Comprehensive AI-Powered Development Workshop',
  favicon: 'img/favicon.ico',

  // Set the production url of your site here
  url: 'http://localhost:3000',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'paulasilvatech', // Usually your GitHub org/user name.
  projectName: 'Mastery-AI-Apps-Dev', // Usually your repo name.

  onBrokenLinks: 'warn',
  onBrokenMarkdownLinks: 'warn',
  onBrokenAnchors: 'warn',
  
  // Fix chunk loading issues
  webpack: {
    jsLoader: (isServer) => ({
      loader: require.resolve('babel-loader'),
      options: {
        presets: [require.resolve('@docusaurus/core/lib/babel/preset')],
      },
    }),
  },

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/tree/main/docs-platform/',
        },
        blog: false, // Disable blog
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    // Replace with your project's social card
    image: 'img/docusaurus-social-card.jpg',
    navbar: {
      title: 'AI Mastery Workshop',
      logo: {
        alt: 'AI Mastery Logo',
        src: 'img/logo.svg',
        srcDark: 'img/logo-dark.svg',
      },
      items: [
        {
          to: '/docs/intro',
          position: 'left',
          label: 'Documentation',
        },
        {
          to: '/docs/modules/module-01/',
          position: 'left',
          label: 'Start Learning',
        },
        {
          href: 'https://github.com/paulasilvatech/Mastery-AI-Apps-Dev',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Workshop',
          items: [
            {
              label: 'Get Started',
              to: '/docs/intro',
            },
            {
              label: 'Prerequisites',
              to: '/docs/guias/prerequisites',
            },
          ],
        },
        {
          title: 'Community',
          items: [
            {
              label: 'GitHub',
              href: 'https://github.com/paulasilvatech/Mastery-AI-Apps-Dev',
            },
            {
              label: 'Discussions',
              href: 'https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions',
            },
          ],
        },
        {
          title: 'More',
          items: [
            {
              label: 'GitHub',
              href: 'https://github.com/paulasilvatech',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Paula Silva Tech. Developed by <a href="https://github.com/paulasilvatech" target="_blank">@paulasilvatech</a>. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
    },
    colorMode: {
      defaultMode: 'light',
      disableSwitch: false,
      respectPrefersColorScheme: true,
    },
  } satisfies Preset.ThemeConfig,
};

export default config;