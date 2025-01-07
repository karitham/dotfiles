{...}: {
  # [includeIf "hasconfig:remote.*.url:git+ssh://git@github/upfluence/**"]
  #     path = "~/upf/.gitconfig"
  xdg.configFile."git/config".text = ''
  [includeIf "hasconfig:remote.*.url:git+ssh://git@github.com/upfluence/**"]
      path = "~/upf/.gitconfig"
  [includeIf "hasconfig:remote.*.url:git@github.com:upfluence/**"]
      path = "~/upf/.gitconfig"
  '';
}
