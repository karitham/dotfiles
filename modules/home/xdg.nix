{lib, ...}: {
  xdg.mimeApps = let
    editor = "Helix.desktop";
    browser = "zen.desktop";
  in {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http " = browser;
      "x-scheme-handler/https" = browser;
      "x-scheme-handler/chrome" = browser;
      "text/html" = browser;
      "application/x-extension-htm" = browser;
      "application/x-extension-html" = browser;
      "application/x-extension-shtml" = browser;
      "application/xhtml+xml" = browser;
      "application/x-extension-xhtml" = browser;
      "application/x-extension-xht" = browser;
      "x-scheme-handler/about" = browser;
      "x-scheme-handler/unknown" = browser;
      "x-scheme-handler/discord" = "legcord.desktop";
      "text/markdown" = editor;
      "text/plain" = editor;
    };
    associations = {
      added =
        {
          "x-scheme-handler/http" = browser;
          "x-scheme-handler/https" = browser;
          "text/html" = browser;
          "binary/octet-stream" = browser;
          "image/jpeg" = browser;
        }
        // lib.mergeAttrsList (map (lang: {
          "text/x-${lang}" = editor;
          "application/x-${lang}" = editor;
        }) ["python" "go" "mod" "ruby" "yaml"]);
    };
  };
}
