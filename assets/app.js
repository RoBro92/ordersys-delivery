(() => {
  const root = document.documentElement;
  const themeToggle = document.getElementById("themeToggle");
  const installSection = document.getElementById("install");
  const installCommandEl = document.getElementById("installCommand");
  const updateCommandEl = document.getElementById("updateCommand");
  const copyInstallButton = document.getElementById("copyInstallCommand");
  const copyUpdateButton = document.getElementById("copyUpdateCommand");
  const copyInstallResult = document.getElementById("copyResultInstall");
  const copyUpdateResult = document.getElementById("copyResultUpdate");
  const viewInstallerBtn = document.getElementById("viewInstallerBtn");
  const viewUpdateBtn = document.getElementById("viewUpdateBtn");
  const installerModal = document.getElementById("installerModal");
  const closeInstallerBtn = document.getElementById("closeInstallerBtn");
  const installerStatus = document.getElementById("installerStatus");
  const installerModalTitle = document.getElementById("installerModalTitle");
  const installerScript = document.getElementById("installerScript");
  const currentVersion = document.getElementById("currentVersion");
  const lastChecked = document.getElementById("lastChecked");
  const stableHealth = document.getElementById("stableHealth");
  const changelogHealth = document.getElementById("changelogHealth");
  const changelogPreview = document.getElementById("changelogPreview");
  const versionManifestLink = document.getElementById("versionManifestLink");
  let cachedInstallerScript = null;

  function getPreferredTheme() {
    const saved = window.localStorage.getItem("ordersys-theme");
    if (saved === "light" || saved === "dark") {
      return saved;
    }
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  }

  function applyTheme(theme) {
    root.setAttribute("data-theme", theme);
    if (themeToggle) {
      themeToggle.textContent = theme === "dark" ? "Light mode" : "Dark mode";
      themeToggle.setAttribute("aria-label", theme === "dark" ? "Switch to light mode" : "Switch to dark mode");
    }
  }

  applyTheme(getPreferredTheme());

  if (themeToggle) {
    themeToggle.addEventListener("click", () => {
      const current = root.getAttribute("data-theme") === "dark" ? "dark" : "light";
      const next = current === "dark" ? "light" : "dark";
      applyTheme(next);
      window.localStorage.setItem("ordersys-theme", next);
    });
  }

  if (installerModal) {
    installerModal.hidden = true;
  }

  if (installSection && window.location.hash === "#install") {
    installSection.focus({ preventScroll: true });
  }

  async function copyCommand(commandEl, copyButton, copyResult) {
    if (!commandEl || !copyResult || !copyButton) {
      return;
    }
    const value = commandEl.textContent || "";
    try {
      await navigator.clipboard.writeText(value);
      copyResult.textContent = "Command copied to clipboard.";
      copyButton.textContent = "Copied";
      window.setTimeout(() => {
        copyButton.textContent = "Copy";
      }, 1400);
    } catch (_error) {
      copyResult.textContent = "Clipboard copy failed. Copy command manually.";
    }
  }

  if (copyInstallButton) {
    copyInstallButton.addEventListener("click", () => {
      void copyCommand(installCommandEl, copyInstallButton, copyInstallResult);
    });
  }

  if (copyUpdateButton) {
    copyUpdateButton.addEventListener("click", () => {
      void copyCommand(updateCommandEl, copyUpdateButton, copyUpdateResult);
    });
  }

  function closeInstallerModal() {
    if (!installerModal) {
      return;
    }
    installerModal.hidden = true;
    if (viewInstallerBtn) {
      viewInstallerBtn.focus({ preventScroll: true });
    }
  }

  async function loadScript(scriptUrl, scriptTitle, statusLabel) {
    if (!installerStatus || !installerScript || !installerModalTitle) {
      return;
    }

    installerModalTitle.textContent = scriptTitle;

    if (cachedInstallerScript !== null && cachedInstallerScript.url === scriptUrl) {
      installerScript.textContent = cachedInstallerScript.content;
      installerStatus.textContent = `Showing ${statusLabel}.`;
      return;
    }

    installerStatus.textContent = "Loading script...";
    installerScript.textContent = "";

    try {
      const response = await fetch(scriptUrl, { cache: "no-store" });
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      const content = await response.text();
      cachedInstallerScript = { url: scriptUrl, content };
      installerScript.textContent = content;
      installerStatus.textContent = `Showing ${statusLabel}.`;
    } catch (_error) {
      installerStatus.textContent = `Unable to load ${statusLabel} right now.`;
      installerScript.textContent = "";
    }
  }

  if (viewInstallerBtn && installerModal) {
    viewInstallerBtn.addEventListener("click", () => {
      installerModal.hidden = false;
      void loadScript("/install", "Installer Script", "/install");
    });
  }

  if (viewUpdateBtn && installerModal) {
    viewUpdateBtn.addEventListener("click", () => {
      installerModal.hidden = false;
      void loadScript("/update/ordersys-update.sh", "Update Script", "/update/ordersys-update.sh");
    });
  }

  if (closeInstallerBtn) {
    closeInstallerBtn.addEventListener("click", closeInstallerModal);
  }

  if (installerModal) {
    installerModal.addEventListener("click", (event) => {
      if (event.target === installerModal) {
        closeInstallerModal();
      }
    });
  }

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && installerModal && !installerModal.hidden) {
      closeInstallerModal();
    }
  });

  function stampCheckedTime() {
    if (!lastChecked) {
      return;
    }
    lastChecked.textContent = new Date().toLocaleString();
  }

  async function loadStable() {
    stampCheckedTime();
    try {
      const response = await fetch("/update/stable.json", { cache: "no-store" });
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      const payload = await response.json();
      const version = typeof payload.latest_version === "string" ? payload.latest_version.trim() : "";
      if (!version) {
        throw new Error("latest_version missing");
      }

      currentVersion.textContent = version;
      stableHealth.textContent = "OK";
      versionManifestLink.textContent = `/update/${version}.json`;
      versionManifestLink.setAttribute("href", `/update/${version}.json`);
    } catch (_error) {
      currentVersion.textContent = "Unavailable";
      stableHealth.textContent = "FAIL";
      versionManifestLink.textContent = "/update/stable.json";
      versionManifestLink.setAttribute("href", "/update/stable.json");
    }
  }

  async function loadChangelog() {
    try {
      const response = await fetch("/update/changelog.md", { cache: "no-store" });
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      const text = await response.text();
      const lines = text
        .split(/\r?\n/)
        .map((line) => line.trimEnd())
        .filter((line) => line.trim().length > 0)
        .slice(0, 25);

      if (lines.length === 0) {
        changelogHealth.textContent = "present (empty)";
        return;
      }

      changelogHealth.textContent = "present";
      changelogPreview.textContent = lines.join("\n");
      changelogPreview.hidden = false;
    } catch (_error) {
      changelogHealth.textContent = "missing/unavailable";
    }
  }

  void loadStable();
  void loadChangelog();
})();
