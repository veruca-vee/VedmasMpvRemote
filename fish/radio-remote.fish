# radio-remote — fish wrapper for the radio-remote package. 🖤🩷
# The remote itself is a bash program (installed on PATH); this just
# makes it a first-class citizen of the radio suite in fish.
function radio-remote --description "drawn picture remote for the radio suite"
    set -l bin (command -s radio-remote)
    if test -z "$bin"
        echo "radio-remote: executable not on PATH — run the package install.sh" >&2
        return 127
    end
    command radio-remote $argv
end
