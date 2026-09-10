/**
 * VINX - Interactive Web Client & Dynamic Release Loader
 * Auto-detects OS, syncs with GitHub Releases API, and manages download links.
 */

(function () {
  'use strict';

  const REPO_OWNER = 'dan-seng';
  const REPO_NAME = 'downloader';
  const FALLBACK_TAG = 'v1.0.0';

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

    if (formatOverride) {
      if (formatOverride === 'winExe') {
        targetUrl = releaseData.urls.winExe;
        label = `Download Windows Setup (${releaseData.sizes.winExe})`;
        meta = `${releaseData.tag} • Windows Installer (.exe) • 64-bit`;
        activeKey = 'winExe';
      } else if (formatOverride === 'winZip') {
        targetUrl = releaseData.urls.winZip;
        label = `Download Windows Portable (${releaseData.sizes.winZip})`;
        meta = `${releaseData.tag} • Windows Portable (.zip) • No Install Needed`;
        activeKey = 'winZip';
      } else if (formatOverride === 'linuxDeb') {
        targetUrl = releaseData.urls.linuxDeb;
        label = `Download Linux Debian (${releaseData.sizes.linuxDeb})`;
        meta = `${releaseData.tag} • Ubuntu / Debian / Mint (.deb) • 64-bit`;
        activeKey = 'linuxDeb';
      } else if (formatOverride === 'linuxTar') {
        targetUrl = releaseData.urls.linuxTar;
        label = `Download Linux Archive (${releaseData.sizes.linuxTar})`;
        meta = `${releaseData.tag} • Linux Standalone (.tar.gz) • All Distros`;
        activeKey = 'linuxTar';
      }
    } else {
      if (os === 'linux') {
        targetUrl = releaseData.urls.linuxDeb;
        label = `Download Linux Debian (${releaseData.sizes.linuxDeb})`;
        meta = `${releaseData.tag} • Ubuntu, Debian, Mint x64 • Free`;
        activeKey = 'linuxDeb';
      } else {
        targetUrl = releaseData.urls.winExe;
        label = `Download Windows Setup (${releaseData.sizes.winExe})`;
        meta = `${releaseData.tag} • Windows 10/11 x64 • Free`;
        activeKey = 'winExe';
      }
    }

    // Apply to Primary CTA
    if (primaryBtn) {
      primaryBtn.href = targetUrl;
      const textSpan = primaryBtn.querySelector('.btn-text');
      if (textSpan) textSpan.textContent = label;
    }

    // Apply to Bottom CTA
    if (bottomBtn) {
      bottomBtn.href = targetUrl;
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
