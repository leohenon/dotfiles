function gunstage --description 'Select staged files with fzf and unstage them'
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
    or begin
        echo "Not in a git repository"
        return 1
    end

    set -l has_head 0
    if git rev-parse --verify HEAD >/dev/null 2>&1
        set has_head 1
    end

    set -l candidates
    if test $has_head -eq 1
        set candidates (git diff --cached --name-only)
    else
        set candidates (git ls-files --cached)
    end

    if test (count $candidates) -eq 0
        echo "No staged files"
        return 0
    end

    set -l picked (
        printf '%s\n' $candidates | fzf \
            --multi \
            --prompt='unstage > ' \
            --header='Tab mark | U all | Enter ok' \
            --bind='U:select-all+accept' \
            --preview='git diff --cached --color=always --root -- {} 2>/dev/null' \
            --preview-window='right:60%'
    )
    or return

    if test (count $picked) -eq 0
        return 0
    end

    if test $has_head -eq 1
        git restore --staged -- $picked
    else
        git rm --cached -r -- $picked
    end
end
