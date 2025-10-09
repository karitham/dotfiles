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

      /* Hide download app on server list */
      .listItem__650eb:has([data-list-item-id="guildsnav___app-download-button"]) {
        display: none !important;
      }

      /* Hide Nitro and Discord Shop tab */
      .channel__972a0:has(a[href="/shop"], a[href="/store"]) {
        display: none !important;
      }

      /* Hide gift button in chat message input */
      .buttons__74017 > div:first-child {
        display: none !important;
      }
    '';
  };
}
