load("@bazel_skylib//lib:paths.bzl", "paths")

def my_latex_gen(name, main, deps, options = {"bibtex": True}):
    out = paths.replace_extension(main, ".pdf")
    if options["bibtex"]:
        cmd_bash = "latexmk -cd -xelatex -latexoption=\"-shell-escape -interaction=errorstopmode -halt-on-error\" $(location " + main + ") && " + \
                   "mv \"$$(dirname $(location " + main + "))/" + out + "\" \"$@\""
        cmd_ps = "latexmk.exe -cd -xelatex -latexoption=\"-shell-escape -interaction=errorstopmode -halt-on-error\" $(location " + main + "); if ($$?) { " + \
                 "mv \"$$(Split-Path -Parent $(location " + main + "))/" + out + "\" \"$@\" } "
        cmd_bat = "latexmk.exe -cd -xelatex -latexoption=\"-shell-escape -interaction=errorstopmode -halt-on-error\" $(location " + main + ") && " + \
                  "move /Y \"$(location " + main + ")\\..\\" + out + "\" \"$@\" && dir \"$@\""
    else:
        cmd_bash = "latexmk -cd -bibtex- -xelatex -latexoption=\"-shell-escape -interaction=errorstopmode -halt-on-error\" $(location " + main + ") && " + \
                   "mv \"$$(dirname $(location " + main + "))/" + out + "\" \"$@\""
        cmd_ps = "latexmk -cd -bibtex- -xelatex -latexoption=\"-shell-escape -interaction=errorstopmode -halt-on-error\" $(location " + main + "); if ($$?) { " + \
                 "mv \"$$(Split-Path -Parent $(location " + main + "))/" + out + "\" \"$@\" } "
        cmd_bat = "latexmk.exe -cd -bibtex- -xelatex -latexoption=\"-shell-escape -interaction=errorstopmode -halt-on-error\" $(location " + main + ") && " + \
                  "move /Y \"$(location " + main + ")\\..\\" + out + "\" \"$@\" && dir \"$@\""
    native.genrule(
        name = name,
        srcs = [main] + deps,
        outs = [out],
        cmd_bash = cmd_bash,
        # cmd_ps = cmd_ps,
        cmd_bat = cmd_bat,
        local = 1,
    )
    checksum_inputs = [main, out] + deps
    checksum_output = paths.replace_extension(main, ".sha512")
    checksum_cmd = " ".join(
        [
            "sha512sum",
            "$(location " + out + ")",
            "$(location " + main + ")",
        ] + [
            "$(location " + d + ")"
            for d in deps
            if not d.startswith("//")
        ] + [
            "$(locations " + d + ")"
            for d in deps
            if d.startswith("//")
        ] + [
            " > \"$@\"",
        ],
    )
    native.genrule(
        name = name + "_checksum",
        srcs = checksum_inputs,
        outs = [checksum_output],
        cmd_bash = checksum_cmd,
    )
