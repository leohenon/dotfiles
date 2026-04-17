function gunstage --description 'Select staged files with fzf and unstage them'
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
    or begin
        echo "Not in a git repository"
        return 1
    end

    set -l candidates (git diff --cached --name-only)

    if test (count $candidates) -eq 0
        echo "No staged files"
        return 0
    end

    set -l picked (
        printf '%s\n' $candidates | fzf -m --prompt='unstage > '
    )
    or return

    if test (count $picked) -eq 0
        return 0
    end

    git restore --staged -- $picked
end
