{ pkgs, ... }:

{
  home.packages = with pkgs; [
    s-tui # Terminal-based CPU stress test & monitoring
    stress-ng # Stress testing tool (used by s-tui)
    powertop # Power consumption analysis
  ];
}
