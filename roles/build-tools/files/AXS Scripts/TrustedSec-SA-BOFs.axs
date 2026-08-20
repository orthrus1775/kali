// ============================================================
// TrustedSec CS-Situational-Awareness-BOF kit — AXS conversion
// Original CNA: https://github.com/trustedsec/CS-Situational-Awareness-BOF
//
// BOF file layout expected alongside this script:
//   <bofname>/<bofname>.<arch>.o
// e.g.  dir/dir.x64.o, ldapsearch/ldapsearch.x64.o, ...
// Special cases: netuse_*, netGroupList*, netLocalGroup* share a single BOF:
//   netuse/netuse.<arch>.o
//   netgroup/netgroup.<arch>.o   netlocalgroup/netlocalgroup.<arch>.o  netlocalgroup2/netlocalgroup2.<arch>.o
//   netuserenum/netuserenum.<arch>.o  (used by both userenum and domainenum)
//   get-netsession/get-netsession.<arch>.o
//   get-netsession2/get-netsession2.<arch>.o
// ============================================================

// ── Constants ───────────────────────────────────────────────

const RECORD_MAPPING = {
    A: 1, NS: 2, MD: 3, MF: 4, CNAME: 5, SOA: 6, MB: 7, MG: 8,
    MR: 9, WKS: 0xb, PTR: 0xc, HINFO: 0xd, MINFO: 0xe, MX: 0xf,
    TEXT: 0x10, RP: 0x11, AFSDB: 0x12, X25: 0x13, ISDN: 0x14,
    RT: 0x15, AAAA: 0x1c, SRV: 0x21, WINSR: 0xff02, KEY: 0x0019,
    ANY: 0xff
};

const ENUM_TYPE = { all: 1, locked: 2, disabled: 3, active: 4 };

const REG_HIVES = { HKCR: 0, HKCU: 1, HKLM: 2, HKU: 3 };

// ── Helper ──────────────────────────────────────────────────

function execBof(id, cmdline, bofname, args, msg, ttp) {
    let bof_path  = ax.script_dir() + bofname + "/" + bofname + "." + ax.arch(id) + ".o";
    let task_msg  = (msg && msg !== "") ? msg : "Tasked agent to run " + bofname + " BOF";
    if (ttp && ttp !== "") task_msg += " (" + ttp + ")";
    let exec_cmd  = args ? `execute bof ${bof_path} ${args}` : `execute bof ${bof_path}`;
    ax.execute_alias(id, cmdline, exec_cmd, task_msg);
}

// ── Commands ────────────────────────────────────────────────

// dir
let dir_cmd = ax.create_command("dir", "Lists a target directory using BOF.", "dir [directory] [/s]");
dir_cmd.addArgString("directory", false, "target directory (default: .\\)");
dir_cmd.addArgBool("/s", "include subdirectories");
dir_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let targetdir = parsed_json["directory"] || ".\\";
    let subdirs   = parsed_json["/s"] ? 1 : 0;
    let ttp       = targetdir.startsWith("\\\\") ? "T1135" : "T1083";
    let msg       = targetdir.startsWith("\\\\") ? `Issuing remote dir to ${targetdir}` : `Issuing local dir to ${targetdir}`;
    let args      = ax.bof_pack("cstr,short", [targetdir, subdirs]);
    execBof(id, cmdline, "dir", args, msg, ttp);
});

// env
let env_cmd = ax.create_command("env", "Print environment variables for current process.", "env");
env_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    execBof(id, cmdline, "env", null, null, "T1082");
});

// ldapsearch
let ldapsearch_cmd = ax.create_command(
    "ldapsearch",
    "BOF - Perform LDAP search.",
    "ldapsearch <query> [--attributes <attrs>] [--count <n>] [--scope <1-3>] [--hostname <host>] [--dn <base>] [--ldaps]"
);
ldapsearch_cmd.addArgString("query", true, "LDAP query");
ldapsearch_cmd.addArgFlagString("--attributes", "attributes", false, "comma-separated attributes (default: *)");
ldapsearch_cmd.addArgFlagInt("--count", "count", false, "max result size (default: 0 = unlimited)");
ldapsearch_cmd.addArgFlagInt("--scope", "scope", false, "1=BASE 2=LEVEL 3=SUBTREE (default: 3)");
ldapsearch_cmd.addArgFlagString("--hostname", "hostname", false, "hostname or IP for LDAP connection");
ldapsearch_cmd.addArgFlagString("--dn", "dn", false, "LDAP query base DN");
ldapsearch_cmd.addArgBool("--ldaps", "use LDAPS");
ldapsearch_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let query      = parsed_json["query"];
    let attributes = parsed_json["attributes"] || "*";
    let count      = parsed_json["count"]      || 0;
    let scope      = parsed_json["scope"]      || 3;
    let hostname   = parsed_json["hostname"]   || "";
    let dn         = parsed_json["dn"]         || "";
    let ldaps      = parsed_json["--ldaps"]    ? 1 : 0;
    let args = ax.bof_pack("cstr,cstr,int,int,cstr,cstr,int", [query, attributes, count, scope, hostname, dn, ldaps]);
    execBof(id, cmdline, "ldapsearch", args, null, "T1018,T1069.002,T1087.002,T1087.003,T1087.004,T1482");
});

// nonpagedldapsearch
let nonpagedldapsearch_cmd = ax.create_command(
    "nonpagedldapsearch",
    "Non-paged LDAP search (use if ldapsearch fails with paging error).",
    "nonpagedldapsearch <query> [--attributes <attrs>] [--count <n>] [--hostname <host>] [--domain <domain>]"
);
nonpagedldapsearch_cmd.addArgString("query", true, "LDAP query");
nonpagedldapsearch_cmd.addArgFlagString("--attributes", "attributes", false, "comma-separated attributes");
nonpagedldapsearch_cmd.addArgFlagInt("--count", "count", false, "max result size");
nonpagedldapsearch_cmd.addArgFlagString("--hostname", "hostname", false, "hostname or IP");
nonpagedldapsearch_cmd.addArgFlagString("--domain", "domain", false, "domain name");
nonpagedldapsearch_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let query      = parsed_json["query"];
    let attributes = parsed_json["attributes"] || "";
    let count      = parsed_json["count"]      || 0;
    let hostname   = parsed_json["hostname"]   || "";
    let domain     = parsed_json["domain"]     || "";
    let args = ax.bof_pack("cstr,cstr,int,cstr,cstr", [query, attributes, count, hostname, domain]);
    execBof(id, cmdline, "nonpagedldapsearch", args, null, "T1018,T1069.002,T1087.002,T1087.003,T1087.004,T1482");
});

// ipconfig
let ipconfig_cmd = ax.create_command("ipconfig", "Runs an internal ipconfig command.", "ipconfig");
ipconfig_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    execBof(id, cmdline, "ipconfig", null, null, "T1016");
});

// get_dpapi_system
let get_dpapi_system_cmd = ax.create_command("get_dpapi_system", "Print DPAPI_SYSTEM and boot key if able.", "get_dpapi_system");
get_dpapi_system_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    execBof(id, cmdline, "get_dpapi_system", null, null, null);
});

// arp
let arp_cmd = ax.create_command("arp", "Runs an internal ARP command.", "arp");
arp_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    execBof(id, cmdline, "arp", null, null, "T1016,T1018");
});

// nslookup
let nslookup_cmd = ax.create_command(
    "nslookup",
    "Internally perform a DNS query.",
    "nslookup <lookup> [server] [TYPE]\n  TYPE: A NS CNAME MX AAAA TXT SRV PTR SOA ANY (default: A)"
);
nslookup_cmd.addArgString("lookup", true, "hostname or IP to query");
nslookup_cmd.addArgString("server", false, "DNS server to query (default: system)");
nslookup_cmd.addArgString("type", false, "record type (default: A)");
nslookup_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let lookup   = parsed_json["lookup"];
    let server   = parsed_json["server"] || "";
    let type_str = (parsed_json["type"] || "A").toUpperCase();
    let type     = RECORD_MAPPING[type_str] !== undefined ? RECORD_MAPPING[type_str] : RECORD_MAPPING["A"];

    if (server === "127.0.0.1") {
        throw new Error("Localhost DNS queries have potential to crash, refusing");
    }
    if (ax.arch(id) === "x86") {
        ax.log("x86 agents do not support custom DNS nameservers, overriding to default");
        server = "";
    }
    let args = ax.bof_pack("cstr,cstr,short", [lookup, server, type]);
    execBof(id, cmdline, "nslookup", args, `Attempting to resolve ${lookup}`, "T1018");
});

// netview
let netview_cmd = ax.create_command("netview", "Lists local workstations and servers.", "netview [domain]");
netview_cmd.addArgString("domain", false, "optional NetBIOS domain name");
netview_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("wstr", [parsed_json["domain"] || ""]);
    execBof(id, cmdline, "netview", args, null, "T1018");
});

// listdns
let listdns_cmd = ax.create_command("listdns", "Lists DNS cache entries.", "listdns");
listdns_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    execBof(id, cmdline, "listdns", null, null, null);
});

// listmods
let listmods_cmd = ax.create_command("listmods", "Lists process modules.", "listmods [pid]");
listmods_cmd.addArgInt("pid", false, "process ID (default: 0 = current)");
listmods_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("int", [parsed_json["pid"] || 0]);
    execBof(id, cmdline, "listmods", args, null, null);
});

// locale
let locale_cmd = ax.create_command("locale", "Retrieve system locale, date format, and country.", "locale");
locale_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    execBof(id, cmdline, "locale", null, "Retrieving system locale information", "T1614,T1614.001");
});

// notepad
let notepad_cmd = ax.create_command(
    "notepad",
    "Search for open Notepad/Notepad++ windows and grab editor contents.",
    "notepad"
);
notepad_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    execBof(id, cmdline, "notepad", null, "Searching for open notepad windows", "T1552");
});

// netuse_add
let netuse_add_cmd = ax.create_command(
    "netuse_add",
    "Connect to a shared resource.",
    "netuse_add <share> <username> <password> [/DEVICE:<name>] [/PERSIST] [/REQUIREPRIVACY]"
);
netuse_add_cmd.addArgString("share", true, "network share (e.g. \\\\server\\share)");
netuse_add_cmd.addArgString("username", true, "username (use \"\" for current user)");
netuse_add_cmd.addArgString("password", true, "password (use \"\" for default)");
netuse_add_cmd.addArgFlagString("/DEVICE", "device", false, "local device to bind (e.g. Y)");
netuse_add_cmd.addArgBool("/PERSIST", "persist the connection");
netuse_add_cmd.addArgBool("/REQUIREPRIVACY", "require SMBv3 encryption");
netuse_add_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let share   = parsed_json["share"];
    let user    = parsed_json["username"];
    let pass    = parsed_json["password"];
    let device  = parsed_json["device"] ? parsed_json["device"] + ":" : "";
    let persist = parsed_json["/PERSIST"]        ? 1 : 0;
    let reqenc  = parsed_json["/REQUIREPRIVACY"] ? 1 : 0;
    let args = ax.bof_pack("short,wstr,wstr,wstr,wstr,short,short", [1, share, user, pass, device, persist, reqenc]);
    execBof(id, cmdline, "netuse", args, null, "T1570,T1021.002");
});

// netuse_list
let netuse_list_cmd = ax.create_command("netuse_list", "Lists local bound connections.", "netuse_list [device|share]");
netuse_list_cmd.addArgString("target", false, "device name or remote share to query");
netuse_list_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let target = parsed_json["target"] || "";
    if (target.length === 1) target = target + ":";
    else if (target.length > 2 && !target.startsWith("\\\\")) target = "\\\\" + target;
    let args = ax.bof_pack("short,wstr", [2, target]);
    execBof(id, cmdline, "netuse", args, null, "T1135");
});

// netuse_delete
let netuse_delete_cmd = ax.create_command(
    "netuse_delete",
    "Disconnects from a shared resource.",
    "netuse_delete <device|share> [/PERSIST] [/FORCE]"
);
netuse_delete_cmd.addArgString("target", true, "device name or share to disconnect");
netuse_delete_cmd.addArgBool("/PERSIST", "delete persistent mapping so it is not restored");
netuse_delete_cmd.addArgBool("/FORCE", "force disconnect even if resources are open");
netuse_delete_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let target  = parsed_json["target"];
    if (target.length === 1) target = target + ":";
    else if (target.length > 2 && !target.startsWith("\\\\")) target = "\\\\" + target;
    let persist = parsed_json["/PERSIST"] ? 1 : 0;
    let force   = parsed_json["/FORCE"]   ? 1 : 0;
    let args = ax.bof_pack("short,wstr,short,short", [3, target, persist, force]);
    execBof(id, cmdline, "netuse", args, null, "T1570,T1021.002");
});

// netuser
let netuser_cmd = ax.create_command(
    "netuser",
    "List user info.",
    "netuser <username> [domain]"
);
netuser_cmd.addArgString("username", true, "username to query");
netuser_cmd.addArgString("domain", false, "DNS or NetBIOS domain (default: local computer)");
netuser_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("wstr,wstr", [parsed_json["username"], parsed_json["domain"] || ""]);
    execBof(id, cmdline, "netuser", args, null, "T1087.001");
});

// windowlist
let windowlist_cmd = ax.create_command("windowlist", "List visible windows.", "windowlist [all]");
windowlist_cmd.addArgBool("all", "show every window, not just desktop-visible ones");
windowlist_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("int", [parsed_json["all"] ? 1 : 0]);
    execBof(id, cmdline, "windowlist", args, null, "T1010");
});

// netstat
let netstat_cmd = ax.create_command(
    "netstat",
    "Get local IPv4/IPv6 UDP/TCP listening and connected ports.",
    "netstat [ipv4] [ipv6] [tcp] [udp]"
);
netstat_cmd.addArgBool("ipv4", "filter for IPv4");
netstat_cmd.addArgBool("ipv6", "filter for IPv6");
netstat_cmd.addArgBool("tcp",  "filter for TCP");
netstat_cmd.addArgBool("udp",  "filter for UDP");
netstat_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let has_v4  = parsed_json["ipv4"] || false;
    let has_v6  = parsed_json["ipv6"] || false;
    let has_tcp = parsed_json["tcp"]  || false;
    let has_udp = parsed_json["udp"]  || false;

    if (!has_v4 && !has_v6)   { has_v4 = true; has_v6 = true; }
    if (!has_tcp && !has_udp) { has_tcp = true; has_udp = true; }

    let mask = 0;
    if (has_v4  && has_tcp) mask |= 0x0001;
    if (has_v6  && has_tcp) mask |= 0x0010;
    if (has_v4  && has_udp) mask |= 0x0100;
    if (has_v6  && has_udp) mask |= 0x1000;

    let args = ax.bof_pack("int", [mask]);
    execBof(id, cmdline, "netstat", args, null, "T1049");
});

// routeprint
let routeprint_cmd = ax.create_command("routeprint", "Prints IPv4 routes on the machine.", "routeprint");
routeprint_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    execBof(id, cmdline, "routeprint", null, null, "T1016");
});

// whoami
let whoami_cmd = ax.create_command("whoami", "Internal whoami /all without spawning cmd.exe.", "whoami");
whoami_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    execBof(id, cmdline, "whoami", null, null, "T1033");
});

// userenum
let userenum_cmd = ax.create_command(
    "userenum",
    "List computer user accounts.",
    "userenum [all|active|locked|disabled]"
);
userenum_cmd.addArgString("filter", false, "account filter: all, active, locked, disabled (default: all)");
userenum_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let filter = parsed_json["filter"] || "all";
    if (!(filter in ENUM_TYPE)) throw new Error("Invalid filter. Use: all, active, locked, disabled");
    let args = ax.bof_pack("int,int", [0, ENUM_TYPE[filter]]);
    execBof(id, cmdline, "netuserenum", args, null, "T1087.001");
});

// domainenum
let domainenum_cmd = ax.create_command(
    "domainenum",
    "List user accounts in the current domain.",
    "domainenum [all|active|locked|disabled]"
);
domainenum_cmd.addArgString("filter", false, "account filter: all, active, locked, disabled (default: all)");
domainenum_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let filter = parsed_json["filter"] || "all";
    if (!(filter in ENUM_TYPE)) throw new Error("Invalid filter. Use: all, active, locked, disabled");
    let args = ax.bof_pack("int,int", [1, ENUM_TYPE[filter]]);
    execBof(id, cmdline, "netuserenum", args, null, "T1087.002");
});

// driversigs
let driversigs_cmd = ax.create_command("driversigs", "Checks drivers for known EDR vendor names.", "driversigs");
driversigs_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    execBof(id, cmdline, "driversigs", null, null, "T1518.001");
});

// netshares
let netshares_cmd = ax.create_command("netshares", "List shares on local or remote computer.", "netshares [\\\\computername]");
netshares_cmd.addArgString("target", false, "target computer");
netshares_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("wstr,int", [parsed_json["target"] || "", 0]);
    execBof(id, cmdline, "netshares", args, null, "T1135");
});

// netsharesAdmin
let netsharesAdmin_cmd = ax.create_command(
    "netsharesAdmin",
    "List shares with extended info (requires admin).",
    "netsharesAdmin [\\\\computername]"
);
netsharesAdmin_cmd.addArgString("target", false, "target computer");
netsharesAdmin_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("wstr,int", [parsed_json["target"] || "", 1]);
    execBof(id, cmdline, "netshares", args, null, "T1135");
});

// netGroupList
let netGroupList_cmd = ax.create_command("netGroupList", "List groups in this domain.", "netGroupList [domain]");
netGroupList_cmd.addArgString("domain", false, "domain name");
netGroupList_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("short,wstr,wstr", [0, parsed_json["domain"] || "", ""]);
    execBof(id, cmdline, "netgroup", args, null, "T1069.002");
});

// netGroupListMembers
let netGroupListMembers_cmd = ax.create_command(
    "netGroupListMembers",
    "List members of a domain group.",
    "netGroupListMembers <group> [domain]"
);
netGroupListMembers_cmd.addArgString("group", true, "group name");
netGroupListMembers_cmd.addArgString("domain", false, "domain name");
netGroupListMembers_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("short,wstr,wstr", [1, parsed_json["domain"] || "", parsed_json["group"]]);
    execBof(id, cmdline, "netgroup", args, null, "T1069.002");
});

// netLocalGroupList
let netLocalGroupList_cmd = ax.create_command("netLocalGroupList", "List local groups on a server.", "netLocalGroupList [server]");
netLocalGroupList_cmd.addArgString("server", false, "server name");
netLocalGroupList_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("short,wstr,wstr", [0, parsed_json["server"] || "", ""]);
    execBof(id, cmdline, "netlocalgroup", args, null, "T1069.001");
});

// netLocalGroupListMembers
let netLocalGroupListMembers_cmd = ax.create_command(
    "netLocalGroupListMembers",
    "List members of a local group.",
    "netLocalGroupListMembers <group> [server]"
);
netLocalGroupListMembers_cmd.addArgString("group", true, "group name");
netLocalGroupListMembers_cmd.addArgString("server", false, "server name");
netLocalGroupListMembers_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("short,wstr,wstr", [1, parsed_json["server"] || "", parsed_json["group"]]);
    execBof(id, cmdline, "netlocalgroup", args, null, "T1069.001");
});

// netLocalGroupListMembers2
let netLocalGroupListMembers2_cmd = ax.create_command(
    "netLocalGroupListMembers2",
    "List local group members (bofhound compatible output).",
    "netLocalGroupListMembers2 [group] [server]\n  Use \"\" for group to query all interesting local groups"
);
netLocalGroupListMembers2_cmd.addArgString("group", false, "group name (omit or \"\" for all interesting groups)");
netLocalGroupListMembers2_cmd.addArgString("server", false, "server name");
netLocalGroupListMembers2_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("wstr,wstr", [parsed_json["server"] || "", parsed_json["group"] || ""]);
    execBof(id, cmdline, "netlocalgroup2", args, null, "T1069.001");
});

// schtasksenum
let schtasksenum_cmd = ax.create_command(
    "schtasksenum",
    "Enumerates all scheduled tasks on the local or target machine.",
    "schtasksenum [target]"
);
schtasksenum_cmd.addArgString("target", false, "target machine");
schtasksenum_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("wstr", [parsed_json["target"] || ""]);
    execBof(id, cmdline, "schtasksenum", args, null, null);
});

// schtasksquery
let schtasksquery_cmd = ax.create_command(
    "schtasksquery",
    "Lists details of a scheduled task.",
    "schtasksquery [server] <taskname>\n  taskname must be full path e.g. \\Microsoft\\Windows\\MUI\\LpRemove"
);
schtasksquery_cmd.addArgString("server",   false, "target server");
schtasksquery_cmd.addArgString("taskname", true,  "task full path");
schtasksquery_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("wstr,wstr", [parsed_json["server"] || "", parsed_json["taskname"]]);
    execBof(id, cmdline, "schtasksquery", args, null, null);
});

// cacls
let cacls_cmd = ax.create_command(
    "cacls",
    "Lists file permissions. Wildcards supported.",
    "cacls <path>\n  F=Full R=Read+Exec C=Read/Write/Exec/Del W=Write"
);
cacls_cmd.addArgString("path", true, "file path (wildcards supported, e.g. C:\\windows\\system32\\*)");
cacls_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("wstr", [parsed_json["path"]]);
    execBof(id, cmdline, "cacls", args, null, null);
});

// sc_query
let sc_query_cmd = ax.create_command(
    "sc_query",
    "Queries a service's status.",
    "sc_query [servicename] [hostname]\n  Omit both to enumerate all local services"
);
sc_query_cmd.addArgString("servicename", false, "service name");
sc_query_cmd.addArgString("hostname",    false, "target hostname");
sc_query_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("cstr,cstr", [parsed_json["hostname"] || null, parsed_json["servicename"] || null]);
    execBof(id, cmdline, "sc_query", args, null, "T1007");
});

// sc_qc
let sc_qc_cmd = ax.create_command("sc_qc", "Queries a service's configuration.", "sc_qc <servicename> [hostname]");
sc_qc_cmd.addArgString("servicename", true,  "service name");
sc_qc_cmd.addArgString("hostname",    false, "target hostname");
sc_qc_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("cstr,cstr", [parsed_json["hostname"] || null, parsed_json["servicename"]]);
    execBof(id, cmdline, "sc_qc", args, null, "T1007");
});

// sc_qdescription
let sc_qdescription_cmd = ax.create_command("sc_qdescription", "Queries a service's description.", "sc_qdescription <servicename> [hostname]");
sc_qdescription_cmd.addArgString("servicename", true,  "service name");
sc_qdescription_cmd.addArgString("hostname",    false, "target hostname");
sc_qdescription_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("cstr,cstr", [parsed_json["hostname"] || null, parsed_json["servicename"]]);
    execBof(id, cmdline, "sc_qdescription", args, null, "T1007");
});

// sc_qfailure
let sc_qfailure_cmd = ax.create_command("sc_qfailure", "Lists service failure actions.", "sc_qfailure <servicename> [hostname]");
sc_qfailure_cmd.addArgString("servicename", true,  "service name");
sc_qfailure_cmd.addArgString("hostname",    false, "target hostname");
sc_qfailure_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("cstr,cstr", [parsed_json["hostname"] || null, parsed_json["servicename"]]);
    execBof(id, cmdline, "sc_qfailure", args, null, "T1007");
});

// sc_qtriggerinfo
let sc_qtriggerinfo_cmd = ax.create_command("sc_qtriggerinfo", "Lists service triggers.", "sc_qtriggerinfo <servicename> [hostname]");
sc_qtriggerinfo_cmd.addArgString("servicename", true,  "service name");
sc_qtriggerinfo_cmd.addArgString("hostname",    false, "target hostname");
sc_qtriggerinfo_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("cstr,cstr", [parsed_json["hostname"] || null, parsed_json["servicename"]]);
    execBof(id, cmdline, "sc_qtriggerinfo", args, null, "T1007");
});

// sc_enum
let sc_enum_cmd = ax.create_command("sc_enum", "Enumerate all service configs in depth.", "sc_enum [hostname]");
sc_enum_cmd.addArgString("hostname", false, "target hostname");
sc_enum_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("cstr", [parsed_json["hostname"] || null]);
    execBof(id, cmdline, "sc_enum", args, null, "T1007");
});

// reg_query
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

// reg_query_recursive
let reg_query_recursive_cmd = ax.create_command(
    "reg_query_recursive",
    "Recursively query a registry key.",
    "reg_query_recursive <HIVE> [path] [--host <hostname>]\n  Hives: HKLM HKCU HKU HKCR\n  Examples:\n    reg_query_recursive HKCU\n    reg_query_recursive HKLM SOFTWARE\\Microsoft --host \\\\dc01"
);
reg_query_recursive_cmd.addArgString("hive", true,  "registry hive: HKLM, HKCU, HKU, HKCR");
reg_query_recursive_cmd.addArgString("path", false, "registry path (omit for hive root)");
reg_query_recursive_cmd.addArgFlagString("--host", "hostname", false, "target hostname (default: local)");
reg_query_recursive_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let hostname = parsed_json["hostname"] || null;
    let hive_str = parsed_json["hive"].toUpperCase();
    if (!(hive_str in REG_HIVES)) throw new Error("Invalid registry hive: " + hive_str + ". Use: HKLM, HKCU, HKU, HKCR");
    let args = ax.bof_pack("cstr,int,cstr,cstr,int", [hostname, REG_HIVES[hive_str], parsed_json["path"] || "", "", 1]);
    execBof(id, cmdline, "reg_query", args, null, null);
});

// tasklist
let tasklist_cmd = ax.create_command(
    "tasklist",
    "Lists currently running processes via WMI.",
    "tasklist [system]\n  Omit or use '.' for local system"
);
tasklist_cmd.addArgString("system", false, "remote system (default: local)");
tasklist_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let system   = parsed_json["system"] || ".";
    let resource = `\\\\${system}\\root\\cimv2`;
    let args     = ax.bof_pack("wstr", [resource]);
    execBof(id, cmdline, "tasklist", args, `Connecting to ${resource} and retrieving process list`, "T1057");
});

// wmi_query
let wmi_query_cmd = ax.create_command(
    "wmi_query",
    "Runs a general WMI query.",
    "wmi_query <query> [system] [namespace]\n  namespace default: root\\cimv2"
);
wmi_query_cmd.addArgString("query",     true,  "WQL query");
wmi_query_cmd.addArgString("system",    false, "remote system (default: .)");
wmi_query_cmd.addArgString("namespace", false, "WMI namespace (default: root\\cimv2)");
wmi_query_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let query     = parsed_json["query"];
    let system    = parsed_json["system"]    || ".";
    let namespace = parsed_json["namespace"] || "root\\cimv2";
    let resource  = `\\\\${system}\\${namespace}`;
    let args      = ax.bof_pack("wstr,wstr,wstr,wstr", [system, namespace, query, resource]);
    execBof(id, cmdline, "wmi_query", args, `Connecting to \\\\${system}\\${namespace} and running WMI query '${query}'`, null);
});

// netsession
let netsession_cmd = ax.create_command("netsession", "List sessions on a server.", "netsession <computer>");
netsession_cmd.addArgString("computer", true, "target computer");
netsession_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("wstr", [parsed_json["computer"]]);
    execBof(id, cmdline, "get-netsession", args, null, "T1049");
});

// netsession2
let netsession2_cmd = ax.create_command(
    "netsession2",
    "List sessions on a server (bofhound compatible output).",
    "netsession2 [computer] [method] [dnsserver]\n  method: 1=DNS (default), 2=NetWkstaGetInfo"
);
netsession2_cmd.addArgString("computer",  false, "target computer");
netsession2_cmd.addArgInt("method",       false, "resolution method: 1=DNS, 2=NetWkstaGetInfo (default: 1)");
netsession2_cmd.addArgString("dnsserver", false, "DNS server");
netsession2_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("wstr,short,cstr", [
        parsed_json["computer"]  || "",
        parsed_json["method"]    || 1,
        parsed_json["dnsserver"] || ""
    ]);
    execBof(id, cmdline, "get-netsession2", args, null, "T1049");
});

// resources
let resources_cmd = ax.create_command("resources", "List available memory and primary disk space.", "resources");
resources_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    execBof(id, cmdline, "resources", null, null, "T1082");
});

// uptime
let uptime_cmd = ax.create_command("uptime", "Lists system boot time.", "uptime");
uptime_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    execBof(id, cmdline, "uptime", null, null, "T1082");
});

// useridletime
let useridletime_cmd = ax.create_command("useridletime", "Shows the user's idle time.", "useridletime");
useridletime_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    execBof(id, cmdline, "useridletime", null, null, "T1082");
});

// enum_filter_driver
let enum_filter_driver_cmd = ax.create_command(
    "enum_filter_driver",
    "Lists filter drivers on the system (CSV: type, name, altitude).",
    "enum_filter_driver [system]"
);
enum_filter_driver_cmd.addArgString("system", false, "remote system to connect to");
enum_filter_driver_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("cstr", [parsed_json["system"] || null]);
    execBof(id, cmdline, "enum_filter_driver", args, "Retrieving list of filter drivers", "T1518.001");
});

// adv_audit_policies
let adv_audit_policies_cmd = ax.create_command(
    "adv_audit_policies",
    "Retrieves advanced security audit policies.",
    "adv_audit_policies"
);
adv_audit_policies_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let iswow64 = (ax.is64(id) && ax.arch(id) === "x86") ? 1 : 0;
    let args    = ax.bof_pack("int", [iswow64]);
    execBof(id, cmdline, "adv_audit_policies", args, `Retrieving advanced security audit policies... iswow64: ${iswow64}`, null);
});

// listpipes  (CNA used bls "//./pipe/" — routing through the dir BOF)
let listpipes_cmd = ax.create_command("listpipes", "Lists local named pipes.", "listpipes");
listpipes_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    ax.execute_alias(id, cmdline, "dir //./pipe/", "Listing Named Pipes (DS0023)");
});

// enumLocalSessions
let enumLocalSessions_cmd = ax.create_command(
    "enumLocalSessions",
    "Enumerate currently attached user sessions (local and RDP).",
    "enumLocalSessions"
);
enumLocalSessions_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    execBof(id, cmdline, "enumlocalsessions", null, null, "T1033");
});

// findLoadedModule
let findLoadedModule_cmd = ax.create_command(
    "findLoadedModule",
    "Finds processes loading a specific DLL. Searches are partial (*match*).",
    "findLoadedModule <dll> [process]"
);
findLoadedModule_cmd.addArgString("dll",     true,  "partial DLL name");
findLoadedModule_cmd.addArgString("process", false, "partial process name filter");
findLoadedModule_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    if (ax.is64(id) && ax.arch(id) === "x86") {
        throw new Error("Cannot run under WOW64 (32-bit process on 64-bit host)");
    }
    let args = ax.bof_pack("cstr,cstr", [parsed_json["dll"], parsed_json["process"] || ""]);
    execBof(id, cmdline, "findLoadedModule", args, null, null);
});

// adcs_enum
let adcs_enum_cmd = ax.create_command(
    "adcs_enum",
    "Enumerates CAs and certificate templates using Win32 functions.",
    "adcs_enum [domain]"
);
adcs_enum_cmd.addArgString("domain", false, "target domain (default: current domain)");
adcs_enum_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("wstr", [parsed_json["domain"] || ""]);
    execBof(id, cmdline, "adcs_enum", args, null, null);
});

// adcs_enum_com
let adcs_enum_com_cmd = ax.create_command(
    "adcs_enum_com",
    "Enumerates CAs and certificate templates using ICertConfig COM object.",
    "adcs_enum_com"
);
adcs_enum_com_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    execBof(id, cmdline, "adcs_enum_com", null, null, null);
});

// adcs_enum_com2
let adcs_enum_com2_cmd = ax.create_command(
    "adcs_enum_com2",
    "Enumerates CAs and certificate templates using IX509PolicyServerListManager COM object.",
    "adcs_enum_com2"
);
adcs_enum_com2_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    execBof(id, cmdline, "adcs_enum_com2", null, null, null);
});

// vssenum
let vssenum_cmd = ax.create_command(
    "vssenum",
    "Enumerate VSS snapshots on a remote machine.",
    "vssenum <hostname> [sharename]\n  sharename defaults to C$"
);
vssenum_cmd.addArgString("hostname",  true,  "target hostname");
vssenum_cmd.addArgString("sharename", false, "share name (default: C$)");
vssenum_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("wstr,wstr", [parsed_json["hostname"], parsed_json["sharename"] || "C$"]);
    execBof(id, cmdline, "vssenum", args, null, null);
});

// get_password_policy
let get_password_policy_cmd = ax.create_command(
    "get_password_policy",
    "Gets a server or DC's configured password policy.",
    "get_password_policy <hostname>\n  Use \"\" to target local computer"
);
get_password_policy_cmd.addArgString("hostname", true, "target server or DC");
get_password_policy_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("wstr", [parsed_json["hostname"]]);
    execBof(id, cmdline, "get_password_policy", args, null, "T1201");
});

// probe
let probe_cmd = ax.create_command(
    "probe",
    "Check if a port is open. Default timeout: 5 seconds.",
    "probe <host> <port> [timeout]"
);
probe_cmd.addArgString("host",    true,  "target host");
probe_cmd.addArgInt("port",       true,  "port number (1-65535)");
probe_cmd.addArgInt("timeout",    false, "timeout in seconds (default: 5)");
probe_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let port = parsed_json["port"];
    if (port < 1 || port > 65535) throw new Error("Port out of range (1-65535)");
    let args = ax.bof_pack("cstr,int,int", [parsed_json["host"], port, parsed_json["timeout"] || 5]);
    execBof(id, cmdline, "probe", args, null, "T1046");
});

// list_firewall_rules
let list_firewall_rules_cmd = ax.create_command("list_firewall_rules", "List all Windows firewall rules.", "list_firewall_rules");
list_firewall_rules_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    execBof(id, cmdline, "list_firewall_rules", null, null, null);
});

// netloggedon
let netloggedon_cmd = ax.create_command(
    "netloggedon",
    "Returns users logged on to a machine (requires admin).",
    "netloggedon [\\\\computername]"
);
netloggedon_cmd.addArgString("target", false, "target computer");
netloggedon_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("wstr,int", [parsed_json["target"] || "", 0]);
    execBof(id, cmdline, "netloggedon", args, null, "T1049");
});

// netloggedon2
let netloggedon2_cmd = ax.create_command(
    "netloggedon2",
    "Returns users logged on via NetWkstaUserEnum (requires admin, bofhound compatible).",
    "netloggedon2 [computername]"
);
netloggedon2_cmd.addArgString("target", false, "target computer");
netloggedon2_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("wstr,int", [parsed_json["target"] || "", 0]);
    execBof(id, cmdline, "netloggedon2", args, null, "T1049");
});

// netuptime
let netuptime_cmd = ax.create_command(
    "netuptime",
    "Returns boot time for a local or remote machine.",
    "netuptime [\\\\computername]"
);
netuptime_cmd.addArgString("target", false, "target computer");
netuptime_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("wstr,int", [parsed_json["target"] || "", 0]);
    execBof(id, cmdline, "netuptime", args, null, "T1082");
});

// nettime
let nettime_cmd = ax.create_command("nettime", "Returns current time on a remote (or local) machine.", "nettime [target]");
nettime_cmd.addArgString("target", false, "target hostname or IP");
nettime_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("wstr", [parsed_json["target"] || ""]);
    execBof(id, cmdline, "nettime", args, null, "T1082");
});

// regsession
let regsession_cmd = ax.create_command(
    "regsession",
    "Returns users logged on via registry (requires admin, bofhound compatible).",
    "regsession [computername]"
);
regsession_cmd.addArgString("target", false, "target computer");
regsession_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("cstr", [parsed_json["target"] || ""]);
    execBof(id, cmdline, "regsession", args, null, "T1049");
});

// aadjoininfo
let aadjoininfo_cmd = ax.create_command("aadjoininfo", "Retrieve Azure AD / Entra ID join information.", "aadjoininfo");
aadjoininfo_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    execBof(id, cmdline, "aadjoininfo", null, null, "T1082");
});

// get_session_info
let get_session_info_cmd = ax.create_command(
    "get_session_info",
    "Returns auth package, logon server, and current session ID.",
    "get_session_info"
);
get_session_info_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    execBof(id, cmdline, "get_session_info", null, null, null);
});

// ldapsecuritycheck
let ldapsecuritycheck_cmd = ax.create_command(
    "ldapsecuritycheck",
    "Check LDAP signing and LDAPS channel binding requirements on a DC.",
    "ldapsecuritycheck [dc]\n  Auto-discovers DC if not provided. Generates Event ID 2889 on target DC."
);
ldapsecuritycheck_cmd.addArgString("dc", false, "Domain Controller hostname or IP");
ldapsecuritycheck_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("wstr", [parsed_json["dc"] || ""]);
    execBof(id, cmdline, "ldapsecuritycheck", args, null, "T1018");
});

// sha256
let sha256_cmd = ax.create_command("sha256", "Returns the SHA-256 hash of a file.", "sha256 <filename>");
sha256_cmd.addArgString("filename", true, "path to file");
sha256_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("cstr", [parsed_json["filename"]]);
    execBof(id, cmdline, "sha256", args, null, null);
});

// md5
let md5_cmd = ax.create_command("md5", "Returns the MD5 hash of a file.", "md5 <filename>");
md5_cmd.addArgString("filename", true, "path to file");
md5_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("cstr", [parsed_json["filename"]]);
    execBof(id, cmdline, "md5", args, null, null);
});

// sha1
let sha1_cmd = ax.create_command("sha1", "Returns the SHA-1 hash of a file.", "sha1 <filename>");
sha1_cmd.addArgString("filename", true, "path to file");
sha1_cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let args = ax.bof_pack("cstr", [parsed_json["filename"]]);
    execBof(id, cmdline, "sha1", args, null, null);
});

// ── Registration ────────────────────────────────────────────

let group = ax.create_commands_group("TrustedSec-SA-BOFs", [
    dir_cmd, env_cmd, ldapsearch_cmd, nonpagedldapsearch_cmd,
    ipconfig_cmd, get_dpapi_system_cmd, arp_cmd, nslookup_cmd,
    netview_cmd, listdns_cmd, listmods_cmd, locale_cmd, notepad_cmd,
    netuse_add_cmd, netuse_list_cmd, netuse_delete_cmd, netuser_cmd,
    windowlist_cmd, netstat_cmd, routeprint_cmd, whoami_cmd,
    userenum_cmd, domainenum_cmd, driversigs_cmd,
    netshares_cmd, netsharesAdmin_cmd,
    netGroupList_cmd, netGroupListMembers_cmd,
    netLocalGroupList_cmd, netLocalGroupListMembers_cmd, netLocalGroupListMembers2_cmd,
    schtasksenum_cmd, schtasksquery_cmd, cacls_cmd,
    sc_query_cmd, sc_qc_cmd, sc_qdescription_cmd, sc_qfailure_cmd, sc_qtriggerinfo_cmd, sc_enum_cmd,
    reg_query_cmd, reg_query_recursive_cmd,
    tasklist_cmd, wmi_query_cmd,
    netsession_cmd, netsession2_cmd,
    resources_cmd, uptime_cmd, useridletime_cmd,
    enum_filter_driver_cmd, adv_audit_policies_cmd,
    listpipes_cmd, enumLocalSessions_cmd, findLoadedModule_cmd,
    adcs_enum_cmd, adcs_enum_com_cmd, adcs_enum_com2_cmd,
    vssenum_cmd, get_password_policy_cmd, probe_cmd, list_firewall_rules_cmd,
    netloggedon_cmd, netloggedon2_cmd, netuptime_cmd, nettime_cmd,
    regsession_cmd, aadjoininfo_cmd, get_session_info_cmd,
    ldapsecuritycheck_cmd, sha256_cmd, md5_cmd, sha1_cmd
]);

ax.register_commands_group(group, ["beacon", "gopher", "kharon", "CrystalForge"], ["windows"], []);
