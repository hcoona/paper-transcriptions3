load("@bazel_skylib//lib:paths.bzl", "paths")

def my_latex_gen(name, main, deps, options = {"bibtex": True}):
    """Generate PDF file & SHA512 checksums for input files.

    Args:
      name: the name of the target.
      main: the latex main file.
      deps: the dependencies.
      options: extra options.
    """
    out = paths.replace_extension(main, ".pdf")

    latexmk_bibtex_str = ""
    if options["bibtex"]:
        latexmk_bibtex_str = ""
    else:
        latexmk_bibtex_str = "-bibtex-"

    cmd_bash = "latexmk -cd -xelatex " + latexmk_bibtex_str + " -latexoption=\"-shell-escape -interaction=errorstopmode -halt-on-error\" $(location " + main + ") && " + \
               "mv \"$$(dirname $(location " + main + "))/" + out + "\" \"$@\""
    cmd_ps = "latexmk.exe -cd -xelatex " + latexmk_bibtex_str + " -latexoption=\"-shell-escape -interaction=errorstopmode -halt-on-error\" $(location " + main + "); if ($$?) { " + \
             "mv \"$$(Split-Path -Parent $(location " + main + "))/" + out + "\" \"$@\" } "
    cmd_bat = "latexmk.exe -g -MSWinBackSlash -cd -xelatex " + latexmk_bibtex_str + " -latexoption=\"-shell-escape -interaction=errorstopmode -halt-on-error\" $(location " + main + ") && " + \
              "move /Y $(location " + main + ")\\..\\" + out + " $@"

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
    checksum_ps1 = (
        "Get-Item (@(" +
        ", ".join(
            [
                "\"$(location " + out + ")\"",
                "\"$(location " + main + ")\"",
            ] + [
                "\"$(location " + d + ")\""
                for d in deps
                if not d.startswith("//")
            ],
        ) + ")" +
        " ".join([
            " + \"$(locations " + d + ")\" -split \" \""
            for d in deps
            if d.startswith("//")
        ]) + ")" +
        " | Get-FileHash -Algorithm SHA512 " +
        " | %{ $$_.Hash.ToLower() + \"  \" + ((Resolve-Path -Relative $$_.Path) -replace \"\\.\\\\\", \"\" -replace \"\\\\\", \"/\") }" +
        " | Set-Content -Encoding UTF8 \"$@\""
    )
    native.genrule(
        name = name + "_checksum",
        srcs = checksum_inputs,
        outs = [checksum_output],
        cmd_bash = checksum_cmd,
        cmd_ps = checksum_ps1,
    )
