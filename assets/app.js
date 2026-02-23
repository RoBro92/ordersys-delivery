(() => {
  const installSection = document.getElementById("install");
  const installCta = document.getElementById("installCta");
  const commandEl = document.getElementById("installCommand");
  const copyButton = document.getElementById("copyCommand");
  const copyResult = document.getElementById("copyResult");
  const currentVersion = document.getElementById("currentVersion");
  const lastChecked = document.getElementById("lastChecked");
  const stableHealth = document.getElementById("stableHealth");
  const changelogHealth = document.getElementById("changelogHealth");
  const changelogPreview = document.getElementById("changelogPreview");
  const versionManifestLink = document.getElementById("versionManifestLink");

  if (installCta && installSection) {
    installCta.addEventListener("click", () => {
      window.setTimeout(() => {
        installSection.focus({ preventScroll: true });
      }, 0);
    });
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
