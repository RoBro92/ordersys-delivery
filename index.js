(() => {
  const versionStatus = document.getElementById("versionStatus");
  const changelogStatus = document.getElementById("changelogStatus");
  const changelogPreview = document.getElementById("changelogPreview");

  async function loadVersion() {
    try {
      const response = await fetch("/update/stable.json", { cache: "no-store" });
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const payload = await response.json();
      if (!payload || typeof payload.latest_version !== "string" || !payload.latest_version.trim()) {
        throw new Error("latest_version missing");
      }

      versionStatus.textContent = `Current version: ${payload.latest_version}`;
      versionStatus.className = "status-line ok";
    } catch (error) {
      versionStatus.textContent = "Current version unavailable: unable to fetch /update/stable.json.";
      versionStatus.className = "status-line warn";
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
        changelogStatus.textContent = "Changelog is available but empty.";
        changelogStatus.className = "status-line";
        return;
      }

      changelogStatus.textContent = "Changelog preview (first 25 non-empty lines):";
      changelogStatus.className = "status-line ok";
      changelogPreview.textContent = lines.join("\n");
      changelogPreview.hidden = false;
    } catch (error) {
      changelogStatus.textContent = "Changelog preview unavailable: /update/changelog.md not found or unreadable.";
      changelogStatus.className = "status-line warn";
    }
  }

  void loadVersion();
  void loadChangelog();
})();
