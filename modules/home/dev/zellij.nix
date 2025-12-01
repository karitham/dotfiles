{inputs', ...}: {
  programs.zellij = {
    enable = true;
    settings = {
      scroll_buffer_size = 5000;
      default_shell = "nu";
      post_command_discovery_hook = ''
        direnv exec . -- ($env.RESURRECT_COMMAND)
      '';
      pane_frames = false;

      keybinds = {
        shared._children = [
          {
            bind = {
              _args = ["Alt f"];
              ToggleFloatingPanes = {};
            };
          }
        ];
      };
    };
  };

  programs.nushell.configFile.text = ''
    if ($env | get -o ZELLIJ | is-not-empty) {
      $env.config = ($env.config | upsert hooks {
      pre_prompt: [ {
          zellij action rename-tab (pwd | path basename)
      } ]
      pre_execution: [ { ||
          let cmd = if ((commandline | str length) > 8) {
            (commandline | str substring 0..6) + "..."
          } else commandline

          zellij action rename-tab ((pwd | path basename) + ' | ' + ($cmd))
      } ]
      })
    }
  '';

  # https://github.com/merikan/.dotfiles/blob/main/config/zellij/themes/zjstatus/catppuccin.kdl
  xdg.configFile."zellij/layouts/default.kdl".text = ''
    layout {
        default_tab_template {
            children
            pane size=1 borderless=true {
                plugin location="file://${inputs'.zjstatus.packages.default}/bin/zjstatus.wasm" {
                  color_rosewater "#f4dbd6"
                  color_flamingo "#f0c6c6"
                  color_pink "#f5bde6"
                  color_mauve "#c6a0f6"
                  color_red "#ed8796"
                  color_maroon "#ee99a0"
                  color_peach "#f5a97f"
                  color_yellow "#eed49f"
                  color_green "#a6da95"
                  color_teal "#8bd5ca"
                  color_sky "#91d7e3"
                  color_sapphire "#7dc4e4"
                  color_blue "#8aadf4"
                  color_lavender "#b7bdf8"
                  color_text "#cad3f5"
                  color_subtext1 "#b8c0e0"
                  color_subtext0 "#a5adcb"
                  color_overlay2 "#939ab7"
                  color_overlay1 "#8087a2"
                  color_overlay0 "#6e738d"
                  color_surface2 "#5b6078"
                  color_surface1 "#494d64"
                  color_surface0 "#363a4f"
                  color_base "#24273a"
                  color_mantle "#1e2030"
                  color_crust "#181926"

                  format_left   "#[bg=$surface0,fg=$sapphire]#[bg=$sapphire,fg=$crust,bold] {session} #[bg=$surface0]{mode}#[bg=$surface0] {tabs}"
                  format_center "{notifications}"
                  format_right  "#[bg=$surface0,fg=$maroon]#[bg=$maroon,fg=$crust]󰃭 #[bg=$surface1,fg=$maroon,bold] {datetime}#[bg=$surface0,fg=$surface1]"
                  format_space  "#[bg=$surface0]"
                  format_hide_on_overlength "true"
                  format_precedence "lrc"

                  border_enabled  "false"
                  border_char     "─"
                  border_format   "#[bg=$surface0]{char}"
                  border_position "top"

                  mode_normal        "#[bg=$green,fg=$crust,bold] NORMAL#[bg=$surface0,fg=$green]"
                  mode_tmux          "#[bg=$mauve,fg=$crust,bold] TMUX#[bg=$surface0,fg=$mauve]"
                  mode_locked        "#[bg=$red,fg=$crust,bold] LOCKED#[bg=$surface0,fg=$red]"
                  mode_pane          "#[bg=$teal,fg=$crust,bold] PANE#[bg=$surface0,fg=teal]"
                  mode_tab           "#[bg=$teal,fg=$crust,bold] TAB#[bg=$surface0,fg=$teal]"
                  mode_scroll        "#[bg=$flamingo,fg=$crust,bold] SCROLL#[bg=$surface0,fg=$flamingo]"
                  mode_enter_search  "#[bg=$flamingo,fg=$crust,bold] ENT-SEARCH#[bg=$surfaco,fg=$flamingo]"
                  mode_search        "#[bg=$flamingo,fg=$crust,bold] SEARCHARCH#[bg=$surfac0,fg=$flamingo]"
                  mode_resize        "#[bg=$yellow,fg=$crust,bold] RESIZE#[bg=$surfac0,fg=$yellow]"
                  mode_rename_tab    "#[bg=$yellow,fg=$crust,bold] RENAME-TAB#[bg=$surface0,fg=$yellow]"
                  mode_rename_pane   "#[bg=$yellow,fg=$crust,bold] RENAME-PANE#[bg=$surface0,fg=$yellow]"
                  mode_move          "#[bg=$yellow,fg=$crust,bold] MOVE#[bg=$surface0,fg=$yellow]"
                  mode_session       "#[bg=$pink,fg=$crust,bold] SESSION#[bg=$surface0,fg=$pink]"
                  mode_prompt        "#[bg=$pink,fg=$crust,bold] PROMPT#[bg=$surface0,fg=$pink]"

                  tab_normal              "#[bg=$surface0,fg=$blue]#[bg=$blue,fg=$crust,bold]{index} #[bg=$surface1,fg=$blue,bold] {name}{floating_indicator}#[bg=$surface0,fg=$surface1]"
                  tab_normal_fullscreen   "#[bg=$surface0,fg=$blue]#[bg=$blue,fg=$crust,bold]{index} #[bg=$surface1,fg=$blue,bold] {name}{fullscreen_indicator}#[bg=$surface0,fg=$surface1]"
                  tab_normal_sync         "#[bg=$surface0,fg=$blue]#[bg=$blue,fg=$crust,bold]{index} #[bg=$surface1,fg=$blue,bold] {name}{sync_indicator}#[bg=$surface0,fg=$surface1]"
                  tab_active              "#[bg=$surface0,fg=$peach]#[bg=$peach,fg=$crust,bold]{index} #[bg=$surface1,fg=$peach,bold] {name}{floating_indicator}#[bg=$surface0,fg=$surface1]"
                  tab_active_fullscreen   "#[bg=$surface0,fg=$peach]#[bg=$peach,fg=$crust,bold]{index} #[bg=$surface1,fg=$peach,bold] {name}{fullscreen_indicator}#[bg=$surface0,fg=$surface1]"
                  tab_active_sync         "#[bg=$surface0,fg=$peach]#[bg=$peach,fg=$crust,bold]{index} #[bg=$surface1,fg=$peach,bold] {name}{sync_indicator}#[bg=$surface0,fg=$surface1]"
                  tab_separator           "#[bg=$surface0] "

                  tab_sync_indicator       " "
                  tab_fullscreen_indicator " 󰊓"
                  tab_floating_indicator   " 󰹙"

                  notification_format_unread "#[bg=surface0,fg=$yellow]#[bg=$yellow,fg=$crust] #[bg=$surface1,fg=$yellow] {message}#[bg=$surface0,fg=$yellow]"
                  notification_format_no_notifications ""
                  notification_show_interval "10"

                  command_user_command    "whoami"
                  command_user_format     "{stdout}"
                  command_user_interval   "10"
                  command_user_rendermode "static"

                  datetime          "{format}"
                  datetime_format   "%Y-%m-%d 󰅐 %H:%M"
                  datetime_timezone "Europe/Paris"
                }
            }
        }
    }
  '';
}
