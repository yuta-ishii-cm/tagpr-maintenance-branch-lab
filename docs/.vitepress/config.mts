import { defineConfig } from 'vitepress';
import { withMermaid } from 'vitepress-plugin-mermaid';

const REPO_URL = 'https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab';

export default withMermaid(
  defineConfig({
    lang: 'ja',
    title: 'tagpr 保守ブランチ運用',
    description:
      'tagpr で機能リリースを回しながら、前のバージョンへの hotfix を保守ブランチから出す運用の検証記録',
    base: '/tagpr-maintenance-branch-lab/',
    cleanUrls: true,
    lastUpdated: true,
    srcExclude: ['README.md'],
    themeConfig: {
      nav: [
        { text: 'はじめに', link: '/concept' },
        { text: '導入手順', link: '/setup' },
        { text: '検証した場面', link: '/scenarios' },
      ],
      sidebar: [
        {
          text: '考え方',
          items: [
            { text: 'やりたいことと方針', link: '/concept' },
            { text: '運用ルール', link: '/rules' },
            { text: 'hotfix の流れ', link: '/flow' },
          ],
        },
        {
          text: '仕組み',
          items: [
            { text: 'ワークフローの中身', link: '/mechanism' },
            { text: 'tagpr で詰まった点', link: '/tagpr-pitfalls' },
          ],
        },
        {
          text: '試す',
          items: [
            { text: '導入手順', link: '/setup' },
            { text: '検証した場面と PR', link: '/scenarios' },
            { text: '残った課題', link: '/open-issues' },
          ],
        },
      ],
      socialLinks: [{ icon: 'github', link: REPO_URL }],
      editLink: {
        pattern: `${REPO_URL}/edit/main/docs/:path`,
        text: 'このページを GitHub で編集する',
      },
      outline: { label: 'このページの内容', level: [2, 3] },
      docFooter: { prev: '前のページ', next: '次のページ' },
      lastUpdated: { text: '最終更新' },
      search: { provider: 'local' },
    },
  })
);
