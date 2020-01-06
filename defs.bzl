load("@bazel_skylib//lib:paths.bzl", "paths")

def my_latex_gen(name, main, deps):
    out = paths.replace_extension(main, ".pdf")
    native.genrule(
        name = name,
        srcs = [main] + deps,
        outs = [out],
        cmd_bash = "latexmk -cd -xelatex -latexoption=\"-shell-escape\" $(location " + main + ") && " +
                   "mv $$(dirname $(location " + main + "))/" + out + " $@",
    )
    checksum_inputs = [main, out] + deps
    checksum_output = paths.replace_extension(main, ".sha512")
    checksum_cmd = "sha512sum $(location " + out + \
                   ") $(location " + main + ") $(locations " + \
                   " ".join(deps) + ") > $@"
    print(checksum_cmd)
    native.genrule(
        name = name + "_checksum",
        srcs = checksum_inputs,
        outs = [checksum_output],
        cmd_bash = checksum_cmd,
    )
