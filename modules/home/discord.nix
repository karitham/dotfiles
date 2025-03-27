{
  lib,
  osConfig,
  pkgs,
  ...
}: {
  config = lib.mkIf osConfig.desktop.enable {
    home.packages = [pkgs.legcord];
    xdg.configFile."legcord/quickCss.css".text = ''
      @import url("https://catppuccin.github.io/discord/dist/catppuccin-macchiato.theme.css");

      /* Hide top bar */
      .visual-refresh {
        --custom-app-top-bar-height: 0px !important;
      }

      .visual-refresh .chat_f75fb0[data-has-border="true"],
      .visual-refresh .container__133bf,
      .visual-refresh .container_a592e1 {
        border-top: 0 !important;
      }

      .visual-refresh .sidebarListRounded_c48ade {
        border-top: 0 !important;
        border-top-left-radius: 0 !important;
      }

      .visual-refresh .scroller_ef3116 {
        padding-block: var(--space-md) !important;
      }

      /* Move inbox button */
      .bar_c38106 {
        z-index: 1000 !important;
        overflow: hidden !important;
      }

      .visual-refresh .toolbar__9293f,
      .visual-refresh .searchBar__1ac1c {
        margin-right: calc(var(--space-32) + var(--space-xs)) !important;
      }

      .visual-refresh .recentsIcon_c99c29 {
        position: fixed !important;
        top: 37px !important;
        right: var(--space-xs) !important;
      }

      /* Compact horizontal padding on server list */
      .visual-refresh {
        --custom-guild-list-padding: min(var(--space-sm)) !important;
      }

      /* Hide download app on server list */
      .listItem__650eb:has([data-list-item-id="guildsnav___app-download-button"]) {
        display: none !important;
      }

      /* Hide Nitro and Discord Shop tab */
      .channel__972a0:has(a[href="/shop"], a[href="/store"]) {
        display: none !important;
      }

      /* Hide gift button in chat message input */
      .buttons__74017 .button__201d5[aria-label="Send a gift"] {
        display: none !important;
      }
    '';
  };
}
