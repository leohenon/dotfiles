function gstage --description 'Select files with fzf and stage them'
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
    or begin
        echo "Not in a git repository"
        return 1
    end

    set -l candidates (
        begin
            git diff --name-only
            git ls-files --others --exclude-standard
            git ls-files --deleted
        end | sort -u
    )

    if test (count $candidates) -eq 0
        echo "No unstaged files"
        return 0
    end

    set -l picked (
        printf '%s\n' $candidates | fzf -m --prompt='stage > '
    )
    or return

    if test (count $picked) -eq 0
        return 0
    end

    git add -A -- $picked
end
