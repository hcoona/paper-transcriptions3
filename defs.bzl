load("@bazel_skylib//lib:paths.bzl", "paths")

def my_latex_gen(name, main, deps):
    out = paths.replace_extension(main, ".pdf")
    native.genrule(
        name = name,
        srcs = [main] + deps,
        outs = [out],
        cmd_bash = "latexmk -cd -xelatex -latexoption=\"-shell-escape -interaction=errorstopmode -halt-on-error\" $(location " + main + ") && " +
                   "mv \"$$(dirname $(location " + main + "))/" + out + "\" \"$@\"",
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
