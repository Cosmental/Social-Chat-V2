// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion

const lightCodeTheme = require('prism-react-renderer/themes/github');
const darkCodeTheme = require('prism-react-renderer/themes/dracula');

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Social Chat',
  tagline: 'Roblox\'s #1 Chat System',
  favicon: 'img/SocialChatLetter.png',

  // Set the production url of your site here
  url: 'https://cosmental.github.io',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/Social-Chat-V2/',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'Cosmental', // Usually your GitHub org/user name.
  projectName: 'Social Chat V2', // Usually your repo name.

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  // Even if you don't use internalization, you can use this field to set useful
  // metadata like html lang. For example, if your site is Chinese, you may want
  // to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/Cosmental/Social-Chat-V2',
        },

        blog: {
          showReadingTime: true,
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/Cosmental/Social-Chat-V2',
        },

        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      // Defaults
      colorMode: {
        defaultMode: 'dark',
        disableSwitch: false,
        respectPrefersColorScheme: true,
      },

      // Replace with your project's social card
      image: 'img/SocialChatLogo.png',
      navbar: {
        title: 'Social Chat',
        // logo: {
        //   alt: 'My Site Logo',
        //   src: 'img/SocialChatLetter.png',
        // },
        items: [
          {
            type: 'docSidebar',
            sidebarId: 'tutorialSidebar',
            position: 'left',
            label: 'Documentation',
          },
          {to: '/blog', label: 'Blog', position: 'left'},
          {
            href: 'https://github.com/Cosmental/Social-Chat-V2',
            label: 'GitHub',
            position: 'right',
          },
          {
            href: 'https://www.roblox.com/games/13069293535/SocialChat-Playground',
            label: 'Roblox',
            position: 'right',
          },
        ],
      },
      footer: {
        style: 'dark',
        links: [
          {
            title: 'Docs',
            items: [
              {
                label: 'SocialChat-v1',
                to: '/docs/SocialChat-v1',
              },
              {
                label: 'SocialChat-v2',
                to: '/docs/SocialChat-v2',
              },
            ],
          },
          {
            title: 'Community',
            items: [
              {
                label: 'Discord',
                href: 'https://discord.gg/4BVYecFEzA',
              },
              {
                label: 'Roblox',
                href: 'https://www.roblox.com/groups/15828562/SocialChat#!/about',
              },
              {
                label: 'Twitter',
                href: 'https://twitter.com/CosRBX',
              },
            ],
          },
          {
            title: 'More',
            items: [
              {
                label: 'Blog',
                to: '/blog',
              },
              {
                label: 'GitHub',
                href: 'https://github.com/Cosmental/Social-Chat-V2',
              },
            ],
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} SocialChat. Built with Docusaurus.`,
      },
      prism: {
        theme: lightCodeTheme,
        darkTheme: darkCodeTheme,
      },
    }),
};

module.exports = config;
