let cmd = ax.create_command(
    "timestomp-bof",
    "Timestomps the creation, last access and last write time of a target file to match a supplied source file that exists on the same system.",
    "timestomp-bof <target-file> <source-file>"
);

cmd.addArgString("target_file", true, "File whose timestamps will be overwritten");
cmd.addArgString("source_file", true, "File whose timestamps will be copied");

cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let target = parsed_json["target_file"];
    let source = parsed_json["source_file"];

    let bof_path = ax.script_dir() + "timestomp." + ax.arch(id) + ".o";
    let args     = ax.bof_pack("cstr,cstr", [target, source]);

    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "TimeStomp_bof: by robot");
});

let group = ax.create_commands_group("timestomp", [cmd]);
ax.register_commands_group(group, ["beacon", "gopher", "kharon", "CrystalForge"], ["windows"], []);
