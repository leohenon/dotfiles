function _lh_load_theme_colors --description "Load theme colors from unified theme.json"
    set -l theme_file "$HOME/.config/theme.json"

    if not test -f $theme_file
        set -g LH_THEME_NAME "vesper"
        set -g LH_COLOR_FG "#FEFEFE"
        set -g LH_COLOR_MUTED "#A0A0A0"
        set -g LH_COLOR_MINT "#99FFE4"
        set -g LH_COLOR_ORANGE "#FFCFA8"
        set -g LH_COLOR_RED "#FF8080"
        return
    end

    set -g LH_THEME_NAME (jq -r '.name // "vesper"' $theme_file)
    set -g LH_COLOR_FG (jq -r '.colors.fg // "#FEFEFE"' $theme_file)
    set -g LH_COLOR_MUTED (jq -r '.colors.muted // "#A0A0A0"' $theme_file)
    set -g LH_COLOR_MINT (jq -r '.colors.mint // "#99FFE4"' $theme_file)
    set -g LH_COLOR_ORANGE (jq -r '.colors.orange // "#FFCFA8"' $theme_file)
    set -g LH_COLOR_RED (jq -r '.colors.red // "#FF8080"' $theme_file)
end
