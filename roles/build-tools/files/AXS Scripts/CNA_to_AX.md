# CNA to AX Script Translation Notes

## Command Registration

| CNA | AX |
|---|---|
| `beacon_command_register(name, desc, usage)` | `ax.create_command(name, desc, usage)` + `ax.register_commands_group(...)` |

**CNA:**
```cna
beacon_command_register(
    "cmd",
    "Description",
    "Args: cmd <arg1> <arg2>"
);
```

**AX:**
```javascript
let cmd = ax.create_command("cmd", "Description", "cmd <arg1> <arg2>");
let group = ax.create_commands_group("cmd", [cmd]);
ax.register_commands_group(group, ["beacon", "gopher", "kharon", "CrystalForge"], ["windows"], []);
```

Registration filters: `agents` (beacon, gopher), `os` (windows, linux, macos), `listeners` (BeaconHTTP, BeaconSMB). Empty array = all.

---

## Argument Parsing

| CNA | AX |
|---|---|
| Positional `$2`, `$3`, `$4` | `parsed_json["arg_name"]` |
| No built-in arg validation | `addArgString`, `addArgInt`, `addArgBool`, `addArgFile` |

```javascript
cmd.addArgString("action",    true,  "add or remove");   // required
cmd.addArgString("task_name", true,  "Name of task");
cmd.addArgString("command",   false, "Command to run");  // optional
```

---

## BOF Packing

| CNA format char | AX type | C unpack |
|---|---|---|
| `z` | `cstr` | `BeaconDataExtract` (zero-terminated) |
| `Z` | `wstr` | `(wchar_t*)BeaconDataExtract` (wide string) |
| `i` | `int` | `BeaconDataInt` (4-byte) |
| `s` | `short` | `BeaconDataShort` (2-byte) |
| `b` | `bytes` | `BeaconDataExtract` (raw binary) |

**CNA:**
```cna
$args = bof_pack($1, "zzz", $2, $3, $4);
```

**AX:**
```javascript
let args = ax.bof_pack("cstr,cstr,cstr", [arg1, arg2, arg3]);
```

---

## BOF Execution

| CNA | AX |
|---|---|
| `script_resource("file.x64.o")` | `ax.script_dir() + "_bin/file." + ax.arch(id) + ".o"` |
| `beacon_inline_execute($1, $data, "go", $args)` | `ax.execute_alias(id, cmdline, \`execute bof ${bof_path} ${args}\`, "msg")` |
| `btask($1, "msg")` | message param in `ax.execute_alias` |

**CNA:**
```cna
alias mycommand {
    local('$handle $data $args');
    $handle = openf(script_resource("mycommand.x64.o"));
    $data   = readb($handle, -1);
    closef($handle);
    $args = bof_pack($1, "zi", $2, $3);
    btask($1, "Running mycommand.");
    beacon_inline_execute($1, $data, "go", $args);
}
```

**AX:**
```javascript
cmd.setPreHook(function(id, cmdline, parsed_json, parsed_lines) {
    let bof_path = ax.script_dir() + "_bin/mycommand." + ax.arch(id) + ".o";
    let args     = ax.bof_pack("cstr,int", [parsed_json["name"], parsed_json["count"]]);
    ax.execute_alias(id, cmdline, `execute bof ${bof_path} ${args}`, "Running mycommand.");
});
```

Place `.o` files in a `_bin/` subdirectory alongside the script. Using `ax.arch(id)` instead of hardcoding `x64` allows x86/x64 selection at runtime.

---

## Logging / Output

| CNA | AX |
|---|---|
| `blog($1, "msg")` | `ax.log(text)` |
| `berror($1, "msg")` | `ax.log_error(text)` |
| `btask($1, "msg")` | message param in `ax.execute_alias` |
