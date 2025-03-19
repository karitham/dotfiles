{
  config,
  lib,
  pkgs,
  ...
}: {
  config = let
    wms = (lib.optional config.desktop.hyprland pkgs.hyprland) ++ (lib.optional config.desktop.niri pkgs.niri);
  in
    lib.mkIf (config.desktop.enable) {
      environment.systemPackages = wms;
      # services = {
      #   greetd = let
      #     tuigreet = lib.getExe pkgs.greetd.tuigreet;
      #     wm = lib.meta.getExe (builtins.head wms);
      #   in {
      #     enable = true;
      #     vt = 7; # # tty to skip startup messages
      #     settings = {
      #       default_session.command = ''
      #         ${tuigreet} \
      #           --time \
      #           --asterisks \
      #           --remember \
      #           --cmd ${wm}
      #       '';
      #     };
      #   };
      # };
    };
}
