/**
 * VINX - Interactive Web Client & Dynamic Release Loader
 * Auto-detects OS, syncs with GitHub Releases API, manages light/dark theme.
 */

(function () {
  'use strict';

  const REPO_OWNER = 'dan-seng';
  const REPO_NAME = 'downloader';
  const FALLBACK_TAG = 'v1.0.0';

  // SVG Icons
  const WINDOWS_ICON = `<svg class="os-icon" viewBox="0 0 24 24" fill="currentColor"><path d="M0 3.449L9.75 2.1v9.451H0m10.949-9.602L24 0v11.4H10.949M0 12.6h9.75v9.451L0 20.699M10.949 12.6H24V24l-12.9-1.801"/></svg>`;
  const LINUX_ICON = `<svg class="os-icon" viewBox="0 0 24 24" fill="currentColor"><path d="M12.003 2c-2.4 0-4.35 1.95-4.35 4.35 0 .58.11 1.14.33 1.65-.63.29-1.21.72-1.68 1.28-1.02 1.2-1.42 2.76-1.12 4.32.22 1.15.82 2.19 1.7 2.94-.03.22-.05.44-.05.66 0 2.65 2.3 4.8 5.17 4.8 2.87 0 5.17-2.15 5.17-4.8 0-.22-.02-.44-.05-.66.88-.75 1.48-1.79 1.7-2.94.3-1.56-.1-3.12-1.12-4.32-.47-.56-1.05-.99-1.68-1.28.22-.51.33-1.07.33-1.65 0-2.4-1.95-4.35-4.35-4.35zm0 1.5c1.58 0 2.85 1.27 2.85 2.85 0 .61-.19 1.18-.52 1.65h-4.66c-.33-.47-.52-1.04-.52-1.65 0-1.58 1.27-2.85 2.85-2.85zm-1.2 2.5a.75.75 0 1 1 0 1.5.75.75 0 0 1 0-1.5zm2.4 0a.75.75 0 1 1 0 1.5.75.75 0 0 1 0-1.5z"/></svg>`;
  
  const SUN_ICON = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2"/><path d="M12 20v2"/><path d="m4.93 4.93 1.41 1.41"/><path d="m17.66 17.66 1.41 1.41"/><path d="M2 12h2"/><path d="M20 12h2"/><path d="m6.34 17.66-1.41 1.41"/><path d="m19.07 4.93-1.41 1.41"/></svg>`;
  const MOON_ICON = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"/></svg>`;

  // Default direct release URLs
  const DEFAULT_URLS = {
    winExe: `https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/latest/download/VINX-windows-setup-x64.exe`,
    winZip: `https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/latest/download/VINX-windows-x64.zip`,
    linuxDeb: `https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/latest/download/VINX-linux-amd64.deb`,
    linuxTar: `https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/latest/download/VINX-linux-x64.tar.gz`,
    releasesPage: `https://github.com/${REPO_OWNER}/${REPO_NAME}/releases`
  };

  let releaseData = {
    tag: FALLBACK_TAG,
    urls: { ...DEFAULT_URLS },
    sizes: {
      winExe: '139 MB',
      winZip: '142 MB',
      linuxDeb: '118 MB',
      linuxTar: '124 MB'
    }
  };

  /**
   * Theme Management (Light / Dark)
   */
  function initTheme() {
    const savedTheme = localStorage.getItem('vinx_theme');
    const systemPrefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
    const currentTheme = savedTheme || (systemPrefersDark ? 'dark' : 'dark'); // default dark

    setTheme(currentTheme);

    const toggleBtn = document.getElementById('theme-toggle-btn');
    if (toggleBtn) {
      toggleBtn.addEventListener('click', () => {
        const activeTheme = document.documentElement.getAttribute('data-theme') || 'dark';
        const newTheme = activeTheme === 'dark' ? 'light' : 'dark';
        setTheme(newTheme);
      });
    }
  }

  function setTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    if (theme === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
    localStorage.setItem('vinx_theme', theme);

    // Update meta theme-color
    const metaThemeColor = document.querySelector('meta[name="theme-color"]');
    if (metaThemeColor) {
      metaThemeColor.setAttribute('content', theme === 'dark' ? '#070709' : '#fafafc');
    }

    // Update toggle button icon
    const toggleBtn = document.getElementById('theme-toggle-btn');
    if (toggleBtn) {
      toggleBtn.innerHTML = theme === 'dark' ? SUN_ICON : MOON_ICON;
      toggleBtn.setAttribute('title', theme === 'dark' ? 'Switch to Light Mode' : 'Switch to Dark Mode');
      toggleBtn.setAttribute('aria-label', theme === 'dark' ? 'Switch to Light Mode' : 'Switch to Dark Mode');
    }
  }

  /**
   * Detect User Operating System
   */
  function detectOS() {
    const userAgent = window.navigator.userAgent.toLowerCase();
    const platform = (window.navigator.userAgentData?.platform || window.navigator.platform || '').toLowerCase();

    if (platform.includes('win') || userAgent.includes('windows')) {
      return 'windows';
    }
    if (platform.includes('linux') || userAgent.includes('linux') || userAgent.includes('x11')) {
      return 'linux';
    }
    if (platform.includes('mac') || userAgent.includes('macintosh')) {
      return 'mac';
    }
    return 'windows'; // default fallback
  }

  /**
   * Format bytes to readable MB/GB
   */
  function formatBytes(bytes) {
    if (!bytes || isNaN(bytes)) return '';
    const mb = bytes / (1024 * 1024);
    return `${Math.round(mb)} MB`;
  }

  /**
   * Update UI download buttons based on OS and current active format
   */
  function updateDownloadButtons(os, formatOverride) {
    const primaryBtn = document.getElementById('primary-download-btn');
    const bottomBtn = document.getElementById('bottom-download-btn');
    const metaCaption = document.getElementById('meta-caption');
    const bottomMetaCaption = document.getElementById('bottom-meta-caption');
    const pills = document.querySelectorAll('.pill-link');

    let targetUrl = releaseData.urls.winExe;
    let label = `Download Windows Setup (${releaseData.sizes.winExe})`;
    let meta = `${releaseData.tag} • Windows 10/11 x64 • Free & Open Source`;
    let activeKey = 'winExe';
    let iconSvg = WINDOWS_ICON;

    if (formatOverride) {
      if (formatOverride === 'winExe') {
        targetUrl = releaseData.urls.winExe;
        label = `Download Windows Setup (${releaseData.sizes.winExe})`;
        meta = `${releaseData.tag} • Windows Installer (.exe) • 64-bit`;
        activeKey = 'winExe';
        iconSvg = WINDOWS_ICON;
      } else if (formatOverride === 'winZip') {
        targetUrl = releaseData.urls.winZip;
        label = `Download Windows Portable (${releaseData.sizes.winZip})`;
        meta = `${releaseData.tag} • Windows Portable (.zip) • Standalone`;
        activeKey = 'winZip';
        iconSvg = WINDOWS_ICON;
      } else if (formatOverride === 'linuxDeb') {
        targetUrl = releaseData.urls.linuxDeb;
        label = `Download Linux Debian (${releaseData.sizes.linuxDeb})`;
        meta = `${releaseData.tag} • Ubuntu / Debian / Mint (.deb) • 64-bit`;
        activeKey = 'linuxDeb';
        iconSvg = LINUX_ICON;
      } else if (formatOverride === 'linuxTar') {
        targetUrl = releaseData.urls.linuxTar;
        label = `Download Linux Standalone (${releaseData.sizes.linuxTar})`;
        meta = `${releaseData.tag} • All Distros: Arch, Fedora, openSUSE (.tar.gz)`;
        activeKey = 'linuxTar';
        iconSvg = LINUX_ICON;
      }
    } else {
      if (os === 'linux') {
        targetUrl = releaseData.urls.linuxDeb;
        label = `Download Linux Debian (${releaseData.sizes.linuxDeb})`;
        meta = `${releaseData.tag} • Ubuntu, Debian, Mint x64 • Free`;
        activeKey = 'linuxDeb';
        iconSvg = LINUX_ICON;
      } else {
        targetUrl = releaseData.urls.winExe;
        label = `Download Windows Setup (${releaseData.sizes.winExe})`;
        meta = `${releaseData.tag} • Windows 10/11 x64 • Free`;
        activeKey = 'winExe';
        iconSvg = WINDOWS_ICON;
      }
    }

    // Apply to Primary CTA
    if (primaryBtn) {
      primaryBtn.href = targetUrl;
      const iconSpan = primaryBtn.querySelector('.btn-icon');
      if (iconSpan) iconSpan.innerHTML = iconSvg;
      const textSpan = primaryBtn.querySelector('.btn-text');
      if (textSpan) textSpan.textContent = label;
    }

    // Apply to Bottom CTA
    if (bottomBtn) {
      bottomBtn.href = targetUrl;
      const iconSpan = bottomBtn.querySelector('.btn-icon');
      if (iconSpan) iconSpan.innerHTML = iconSvg;
      const textSpan = bottomBtn.querySelector('.btn-text');
      if (textSpan) textSpan.textContent = label;
    }

    // Apply captions
    if (metaCaption) metaCaption.textContent = meta;
    if (bottomMetaCaption) bottomMetaCaption.textContent = meta;

    // Update active pill styling
    pills.forEach((pill) => {
      const format = pill.getAttribute('data-format');
      if (format === activeKey) {
        pill.classList.add('active-pill');
      } else {
        pill.classList.remove('active-pill');
      }
    });
  }

  /**
   * Fetch Latest Release from GitHub API
   */
  async function fetchGitHubReleases() {
    try {
      const response = await fetch(`https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest`, {
        headers: { Accept: 'application/vnd.github.v3+json' }
      });

      if (!response.ok) return;

      const data = await response.json();
      if (data.tag_name) {
        releaseData.tag = data.tag_name;
      }

      if (Array.isArray(data.assets)) {
        data.assets.forEach((asset) => {
          const name = asset.name.toLowerCase();
          const downloadUrl = asset.browser_download_url;
          const size = formatBytes(asset.size);

          if (name.includes('setup') && name.endsWith('.exe')) {
            releaseData.urls.winExe = downloadUrl;
            if (size) releaseData.sizes.winExe = size;
          } else if (name.includes('windows') && name.endsWith('.zip')) {
            releaseData.urls.winZip = downloadUrl;
            if (size) releaseData.sizes.winZip = size;
          } else if (name.endsWith('.deb')) {
            releaseData.urls.linuxDeb = downloadUrl;
            if (size) releaseData.sizes.linuxDeb = size;
          } else if (name.includes('linux') && (name.endsWith('.tar.gz') || name.endsWith('.tgz'))) {
            releaseData.urls.linuxTar = downloadUrl;
            if (size) releaseData.sizes.linuxTar = size;
          }
        });
      }

      // Re-render with updated asset metadata
      const userOS = detectOS();
      updateDownloadButtons(userOS);
    } catch (err) {
      console.warn('Using fallback direct release paths:', err);
    }
  }

  /**
   * Initialize on DOM Ready
   */
  document.addEventListener('DOMContentLoaded', () => {
    initTheme();

    const userOS = detectOS();
    updateDownloadButtons(userOS);

    // Pill click listener to select formats
    document.querySelectorAll('.pill-link').forEach((pill) => {
      pill.addEventListener('click', (e) => {
        e.preventDefault();
        const format = pill.getAttribute('data-format');
        updateDownloadButtons(userOS, format);
      });
    });

    // Fetch real-time release info from GitHub API
    fetchGitHubReleases();
  });
})();
