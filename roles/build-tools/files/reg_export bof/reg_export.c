// reg_export BOF
// Exports a registry hive or subkey to a UTF-16 LE .reg file (with BOM),
// compatible with reg.exe import on all modern Windows versions.
// No SeBackupPrivilege required — equivalent to `reg export HIVE <outfile>`.
//
// Args (BOF pack order): subkey (cstr), outfile (cstr), hive_offset (int)
//   hive_offset: 0=HKCR 1=HKCU 2=HKLM 3=HKU
//
// Place source at: src/Remote/reg_export/entry.c
// Build: x86_64-w64-mingw32-gcc -o reg_export.x64.o -c entry.c -masm=intel -Wall
// Place compiled .o at: Remote/reg_export/reg_export.x64.o

#include <windows.h>
#include "beacon.h"
#include "bofdefs.h"
#include "base.c"
#include "anticrash.c"
#include "stack.c"

DECLSPEC_IMPORT WINADVAPI LONG WINAPI ADVAPI32$RegEnumValueW(HKEY, DWORD, LPWSTR, LPDWORD, LPDWORD, LPDWORD, LPBYTE, LPDWORD);

// ── UTF-16 LE write helpers ───────────────────────────────────────────────────

static void fw_raw(HANDLE hf, const void* buf, DWORD n)
{
    DWORD written;
    KERNEL32$WriteFile(hf, buf, n, &written, NULL);
}

static void fw_bom(HANDLE hf)
{
    BYTE bom[2] = {0xFF, 0xFE};
    fw_raw(hf, bom, 2);
}

// Write n ASCII bytes as UTF-16 LE (each byte → byte + 0x00)
static void fw_a2w(HANDLE hf, const char* s, DWORD n)
{
    DWORD i;
    BYTE pair[2];
    pair[1] = 0;
    if (!n) n = (DWORD)MSVCRT$strlen(s);
    for (i = 0; i < n; i++) {
        pair[0] = (BYTE)s[i];
        fw_raw(hf, pair, 2);
    }
}

// Write nchars WCHARs as UTF-16 LE
static void fw_wchars(HANDLE hf, const WCHAR* ws, DWORD nchars)
{
    fw_raw(hf, ws, nchars * sizeof(WCHAR));
}

// Write escaped wide string content (for REG_SZ value data and value names)
static void fw_escaped_wstr(HANDLE hf, const WCHAR* data, DWORD nchars)
{
    DWORD i;
    for (i = 0; i < nchars; i++) {
        if (data[i] == L'\0') break;
        switch (data[i]) {
            case L'\\': fw_wchars(hf, L"\\\\", 2); break;
            case L'"':  fw_wchars(hf, L"\\\"", 2); break;
            case L'\n': fw_wchars(hf, L"\\n",  2); break;
            case L'\r': fw_wchars(hf, L"\\r",  2); break;
            default:    fw_raw(hf, &data[i], 2);   break;
        }
    }
}

// Write hex line as UTF-16 LE
static void fw_hex(HANDLE hf, const char* prefix, const BYTE* data, DWORD len)
{
    char buf[8];
    DWORD i;
    fw_a2w(hf, prefix, 0);
    for (i = 0; i < len; i++) {
        if (i > 0) {
            if (i % 25 == 0) fw_a2w(hf, ",\\\r\n  ", 6);
            else              fw_a2w(hf, ",", 1);
        }
        MSVCRT$sprintf(buf, "%02x", (unsigned int)(unsigned char)data[i]);
        fw_a2w(hf, buf, 2);
    }
    fw_a2w(hf, "\r\n", 2);
}

// ── Key traversal structures ──────────────────────────────────────────────────

typedef struct _regkeyval {
    char*  keypath;
    DWORD  dwkeypathsz;
    HKEY   hreg;
} regkeyval, *pregkeyval;

static pregkeyval init_regkey(const char* curpath, DWORD dwcurpathsz,
                               const char* childkey, DWORD dwchildkeysz, HKEY hreg)
{
    pregkeyval item = (pregkeyval)intAlloc(sizeof(regkeyval));
    item->dwkeypathsz = dwcurpathsz + (dwchildkeysz ? dwchildkeysz + 1 : 0);
    item->keypath = (char*)intAlloc(item->dwkeypathsz + 1);
    MSVCRT$memcpy(item->keypath, curpath, dwcurpathsz);
    if (dwchildkeysz > 0) {
        item->keypath[dwcurpathsz] = '\\';
        MSVCRT$memcpy(item->keypath + dwcurpathsz + 1, childkey, dwchildkeysz);
    }
    item->hreg = hreg;
    return item;
}

static void free_regkey(pregkeyval val)
{
    if (val->keypath) intFree(val->keypath);
    if (val->hreg)    ADVAPI32$RegCloseKey(val->hreg);
}

// ── Value export ──────────────────────────────────────────────────────────────
// Uses RegEnumValueW so REG_SZ data is already UTF-16 LE and can be written
// directly; other types are raw bytes and go through fw_hex unchanged.

static void export_values(HANDLE hf, HKEY hKey, DWORD cValues, DWORD cchMaxValue, DWORD cchMaxData)
{
    WCHAR* name = NULL;
    BYTE*  data = NULL;
    DWORD  nlen, dlen, type;
    DWORD  i;
    char   num[64];

    if (cValues == 0) return;

    name = (WCHAR*)intAlloc((cchMaxValue + 2) * sizeof(WCHAR));
    data = (BYTE*)intAlloc(cchMaxData + 4);
    if (!name || !data) goto done;

    for (i = 0; i < cValues; i++) {
        nlen = cchMaxValue + 2;
        dlen = cchMaxData + 4;
        MSVCRT$memset(name, 0, (cchMaxValue + 2) * sizeof(WCHAR));
        MSVCRT$memset(data, 0, cchMaxData + 4);

        if (ADVAPI32$RegEnumValueW(hKey, i, name, &nlen, NULL, &type, data, &dlen) != ERROR_SUCCESS)
            continue;

        if (nlen == 0) {
            fw_a2w(hf, "@=", 2);
        } else {
            fw_a2w(hf, "\"", 1);
            fw_escaped_wstr(hf, name, nlen);
            fw_a2w(hf, "\"=", 2);
        }

        switch (type) {
            case REG_SZ:
                fw_a2w(hf, "\"", 1);
                if (dlen > sizeof(WCHAR))
                    fw_escaped_wstr(hf, (WCHAR*)data, dlen / sizeof(WCHAR));
                fw_a2w(hf, "\"\r\n", 3);
                break;
            case REG_EXPAND_SZ:
                fw_hex(hf, "hex(2):", data, dlen);
                break;
            case REG_MULTI_SZ:
                fw_hex(hf, "hex(7):", data, dlen);
                break;
            case REG_BINARY:
                fw_hex(hf, "hex:", data, dlen);
                break;
            case REG_DWORD:
                if (dlen >= 4) {
                    MSVCRT$sprintf(num, "dword:%08x\r\n", (unsigned int)(*(DWORD*)data));
                    fw_a2w(hf, num, 0);
                }
                break;
            case REG_QWORD:
                fw_hex(hf, "hex(b):", data, dlen);
                break;
            default:
                MSVCRT$sprintf(num, "hex(%lx):", (unsigned long)type);
                fw_hex(hf, num, data, dlen);
                break;
        }
    }

done:
    if (name) intFree(name);
    if (data) intFree(data);
}

// ── Hive name ─────────────────────────────────────────────────────────────────

static const char* hive_str(int t)
{
    switch (t) {
        case 0: return "HKEY_CLASSES_ROOT";
        case 1: return "HKEY_CURRENT_USER";
        case 2: return "HKEY_LOCAL_MACHINE";
        case 3: return "HKEY_USERS";
        default: return "HKEY_UNKNOWN";
    }
}

// ── Entry point ───────────────────────────────────────────────────────────────

#ifdef BOF
VOID go(IN PCHAR Buffer, IN ULONG Length)
{
    datap       parser    = {0};
    const char* subkey    = NULL;
    const char* outfile   = NULL;
    int         t         = 0;
    HKEY        hive      = (HKEY)0x80000000;
    HKEY        rootkey   = NULL;
    HANDLE      hf        = INVALID_HANDLE_VALUE;
    Pstack      keyStack  = NULL;
    pregkeyval  curitem   = NULL;
    DWORD       dwresult  = 0;
    DWORD       sublen, hslen, plen;
    const char* hs;
    char*       rootpath  = NULL;

    DWORD cSubKeys = 0, cbMaxSubKey = 0;
    DWORD cValues  = 0, cchMaxValue = 0, cchMaxData = 0;
    char* subkeyname  = NULL;
    DWORD cbName      = 0;
    HKEY  childkey_h  = NULL;
    DWORD i           = 0;

    BeaconDataParse(&parser, Buffer, Length);
    subkey  = BeaconDataExtract(&parser, NULL);
    outfile = BeaconDataExtract(&parser, NULL);
    t       = BeaconDataInt(&parser);

    #pragma GCC diagnostic ignored "-Wint-to-pointer-cast"
    #pragma GCC diagnostic ignored "-Wpointer-to-int-cast"
    hive = (HKEY)((DWORD)hive + (DWORD)t);
    #pragma GCC diagnostic pop

    if (!bofstart()) return;

    sublen = (subkey && *subkey) ? (DWORD)MSVCRT$strlen(subkey) : 0;
    hs     = hive_str(t);
    hslen  = (DWORD)MSVCRT$strlen(hs);
    plen   = hslen + (sublen > 0 ? 1 + sublen : 0);

    rootpath = (char*)intAlloc(plen + 2);
    if (!rootpath) { internal_printf("intAlloc failed\n"); goto go_end; }
    MSVCRT$memcpy(rootpath, hs, hslen);
    if (sublen > 0) {
        rootpath[hslen] = '\\';
        MSVCRT$memcpy(rootpath + hslen + 1, subkey, sublen);
    }

    dwresult = ADVAPI32$RegOpenKeyExA(hive, sublen > 0 ? subkey : NULL, 0, KEY_READ, &rootkey);
    if (dwresult != ERROR_SUCCESS) {
        internal_printf("RegOpenKeyExA failed: %lu\n", dwresult);
        goto go_end;
    }

    {
        char* slash = MSVCRT$strrchr(outfile, '\\');
        if (slash && slash != outfile) {
            char* dir = (char*)intAlloc((DWORD)(slash - outfile) + 1);
            if (dir) {
                MSVCRT$memcpy(dir, outfile, (DWORD)(slash - outfile));
                KERNEL32$CreateDirectoryA(dir, NULL);
                intFree(dir);
            }
        }
    }

    hf = KERNEL32$CreateFileA(outfile, GENERIC_WRITE, 0, NULL,
                               CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hf == INVALID_HANDLE_VALUE) {
        internal_printf("CreateFileA failed: %lu\n", KERNEL32$GetLastError());
        goto go_end;
    }

    fw_bom(hf);
    fw_a2w(hf, "Windows Registry Editor Version 5.00\r\n", 0);

    keyStack = stackInit();
    keyStack->push(keyStack, init_regkey(rootpath, plen, NULL, 0, rootkey));
    rootkey = NULL;

    while ((curitem = keyStack->pop(keyStack)) != NULL) {
        fw_a2w(hf, "\r\n[", 3);
        fw_a2w(hf, curitem->keypath, curitem->dwkeypathsz);
        fw_a2w(hf, "]\r\n", 3);

        dwresult = ADVAPI32$RegQueryInfoKeyA(
            curitem->hreg, NULL, NULL, NULL,
            &cSubKeys, &cbMaxSubKey, NULL,
            &cValues, &cchMaxValue, &cchMaxData,
            NULL, NULL);

        if (dwresult != ERROR_SUCCESS) goto nextloop;

        export_values(hf, curitem->hreg, cValues, cchMaxValue, cchMaxData);

        if (cSubKeys > 0) {
            subkeyname = (char*)intAlloc(cbMaxSubKey + 2);
            if (!subkeyname) goto nextloop;

            for (i = 0; i < cSubKeys; i++) {
                cbName = cbMaxSubKey + 2;
                MSVCRT$memset(subkeyname, 0, cbMaxSubKey + 2);

                if (ADVAPI32$RegEnumKeyExA(curitem->hreg, i,
                        subkeyname, &cbName, NULL, NULL, NULL, NULL) != ERROR_SUCCESS)
                    continue;

                childkey_h = NULL;
                if (ADVAPI32$RegOpenKeyExA(curitem->hreg, subkeyname, 0,
                        KEY_READ, &childkey_h) != ERROR_SUCCESS) {
                    BeaconPrintf(CALLBACK_ERROR, "Could not open %s\\%s\n",
                        curitem->keypath, subkeyname);
                    continue;
                }
                keyStack->push(keyStack, init_regkey(
                    curitem->keypath, curitem->dwkeypathsz,
                    subkeyname, cbName, childkey_h));
            }

            intFree(subkeyname);
            subkeyname = NULL;
        }

nextloop:
        if (subkeyname) { intFree(subkeyname); subkeyname = NULL; }
        cSubKeys = 0; cbMaxSubKey = 0;
        cValues  = 0; cchMaxValue = 0; cchMaxData = 0;
        free_regkey(curitem);
        intFree(curitem);
        curitem = NULL;
    }

    KERNEL32$CloseHandle(hf);
    hf = INVALID_HANDLE_VALUE;
    internal_printf("Exported %s to %s\nDownload and delete when done.\n", rootpath, outfile);

go_end:
    if (subkeyname) intFree(subkeyname);
    if (rootpath)   intFree(rootpath);
    if (rootkey)    ADVAPI32$RegCloseKey(rootkey);
    if (hf != INVALID_HANDLE_VALUE) KERNEL32$CloseHandle(hf);
    if (keyStack)   keyStack->free(keyStack);
    printoutput(TRUE);
    bofstop();
}
#endif
