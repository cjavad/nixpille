# Shared monitor definitions - single source of truth
# Used by both kanshi (hot-plug detection) and hyprland (workspace bindings)
{
  profiles = {
    work-docked = {
      outputs = [
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
      disableInternal = true;
    };

    laptop = {
      outputs = [
        {
          name = "internal";
          criteria = "eDP-1";
          mode = "3200x2000@120Hz";
          scale = 1.6;
          workspace = 1;
        }
      ];
    };
  };
}
