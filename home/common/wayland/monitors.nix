# Shared monitor definitions - single source of truth
# Used by both kanshi (hot-plug detection) and hyprland (workspace bindings)
let
  internal = {
    name = "internal";
    criteria = "eDP-1";
    mode = "3200x2000@120Hz";
    scale = 1.6;
  };

  externals = [
    {
      name = "left";
      criteria = "Dell Inc. DELL P2314H J8J3146IBZ8B";
      mode = "1920x1080@60Hz";
      position = "0,0";
      scale = 1.25;
      workspace = 1;
    }
    {
      name = "middle";
      criteria = "Dell Inc. DELL P2414H 36WJX37G044L";
      mode = "1920x1080@60Hz";
      position = "1536,0";
      scale = 1.25;
      workspace = 2;
    }
    {
      name = "right";
      criteria = "AOC 2460G4 GJXH9HA034303";
      mode = "1920x1080@60Hz";
      position = "3072,0";
      scale = 1.25;
      workspace = 3;
    }
  ];
in
{
  profiles = {
    # Docked, lid open — externals only (preferred, auto-selected)
    work-docked = {
      outputs = [ (internal // { status = "disable"; }) ] ++ externals;
    };

    # Docked, lid open — all 4 screens (manual: kanshictl switch work-docked-all)
    work-docked-all = {
      outputs = externals ++ [
        (
          internal
          // {
            position = "4608,0";
            workspace = 4;
          }
        )
      ];
    };

    # Docked, laptop screen only (manual: kanshictl switch work-docked-laptop)
    work-docked-laptop = {
      outputs = [
        (internal // { workspace = 1; })
      ]
      ++ map (m: {
        inherit (m) criteria;
        status = "disable";
      }) externals;
    };

    # Docked, lid closed — eDP-1 disconnected
    work-docked-no-laptop = {
      outputs = externals;
    };

    # Undocked
    laptop = {
      outputs = [ (internal // { workspace = 1; }) ];
    };
  };
}
