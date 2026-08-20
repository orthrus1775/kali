const REG_HIVES = { HKCR: 0, HKCU: 1, HKLM: 2, HKU: 3 };

function execBof(id, cmdline, bofname, args, msg, ttp) {
    let bof_path = ax.script_dir() + "_bin/reg_query." + ax.arch(id) + ".o";
    let task_msg = (msg && msg !== "") ? msg : "Tasked agent to run " + bofname + " BOF";
    if (ttp && ttp !== "") task_msg += " (" + ttp + ")";
    let exec_cmd = args ? `execute bof ${bof_path} ${args}` : `execute bof ${bof_path}`;
    ax.execute_alias(id, cmdline, exec_cmd, task_msg);
}

let reg_query_cmd = ax.create_command(
    "reg_query",
    "Query a registry key or value.",
    "reg_query <HIVE> <path> [key] [--host <hostname>]\n  Hives: HKLM HKCU HKU HKCR\n  Examples:\n    reg_query HKLM SOFTWARE\\Microsoft\\Windows\n    reg_query HKLM SOFTWARE\\Microsoft\\Windows CurrentVersion\n    reg_query HKLM SOFTWARE\\Microsoft\\Windows --host \\\\dc01"
);
reg_query_cmd.addArgString("hive", true,  "registry hive: HKLM, HKCU, HKU, HKCR");
reg_query_cmd.addArgString("path", false, "registry path (omit for hive root)");
reg_query_cmd.addArgString("key",  false, "specific value to query");
reg_query_cmd.addArgFlagString("--host", "hostname", false, "target hostname (default: local)");
reg_query_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let hostname = parsed_json["hostname"] || null;
    let hive_str = parsed_json["hive"].toUpperCase();
    if (!(hive_str in REG_HIVES)) throw new Error("Invalid registry hive: " + hive_str + ". Use: HKLM, HKCU, HKU, HKCR");
    let args = ax.bof_pack("cstr,int,cstr,cstr,int", [hostname, REG_HIVES[hive_str], parsed_json["path"] || "", parsed_json["key"] || "", 0]);
    execBof(id, cmdline, "reg_query", args, null, null);
});

let group = ax.create_commands_group("reg_query", [reg_query_cmd]);
ax.register_commands_group(group, ["beacon", "gopher", "kharon", "CrystalForge"], ["windows"], []);
