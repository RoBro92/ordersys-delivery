(() => {
  const installSection = document.getElementById("install");
  const commandEl = document.getElementById("installCommand");
  const copyButton = document.getElementById("copyCommand");
  const copyResult = document.getElementById("copyResult");
  const viewInstallerBtn = document.getElementById("viewInstallerBtn");
  const installerModal = document.getElementById("installerModal");
  const closeInstallerBtn = document.getElementById("closeInstallerBtn");
  const installerStatus = document.getElementById("installerStatus");
  const installerScript = document.getElementById("installerScript");
  const currentVersion = document.getElementById("currentVersion");
  const lastChecked = document.getElementById("lastChecked");
  const stableHealth = document.getElementById("stableHealth");
  const changelogHealth = document.getElementById("changelogHealth");
  const changelogPreview = document.getElementById("changelogPreview");
  const versionManifestLink = document.getElementById("versionManifestLink");
  let cachedInstallerScript = null;

  if (installSection && window.location.hash === "#install") {
    installSection.focus({ preventScroll: true });
  }

  async function copyCommand() {
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

  if (copyButton) {
    copyButton.addEventListener("click", () => {
      void copyCommand();
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

  async function loadInstallerScript() {
    if (!installerStatus || !installerScript) {
      return;
    }

    if (cachedInstallerScript !== null) {
      installerScript.textContent = cachedInstallerScript;
      installerStatus.textContent = "Showing /install script.";
      return;
    }

    installerStatus.textContent = "Loading installer script...";
    installerScript.textContent = "";

    try {
      const response = await fetch("/install", { cache: "no-store" });
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      cachedInstallerScript = await response.text();
      installerScript.textContent = cachedInstallerScript;
      installerStatus.textContent = "Showing /install script.";
    } catch (_error) {
      installerStatus.textContent = "Unable to load /install right now.";
      installerScript.textContent = "";
    }
  }

  if (viewInstallerBtn && installerModal) {
    viewInstallerBtn.addEventListener("click", () => {
      installerModal.hidden = false;
      void loadInstallerScript();
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
