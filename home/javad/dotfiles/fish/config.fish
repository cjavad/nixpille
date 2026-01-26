# Minimal fish config for ISO live environment
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx PAGER less

# Simple greeting
function fish_greeting
    echo "Welcome to nixpille live environment"
    echo "Run 'nixpille-install' to begin installation"
end
