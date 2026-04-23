# RecycleBinSize by Zabbix Agent – Zabbix Template

## Description

This Zabbix template monitors the disk space used by **user Trash / Recycle Bin directories** on a per-user basis.

It is based on **Zabbix Agent / Agent 2**, **Low-Level Discovery (LLD)**, and custom scripts that scan user Trash directories (Windows Recycle Bin or Linux Trash) and calculate the size used by each local user.

For every discovered user, Zabbix creates an item to monitor the Trash size and a trigger to alert when it exceeds a defined threshold.

**Compatible with Zabbix 6.4 / 7.0 / 7.2 / 7.4**
**Tested on Zabbix 7.4.6**

---

## Why

This template is particularly useful in environments where desktops are backed up using full-image backup solutions (e.g., Veeam Agent, Acronis).  

Without monitoring, large Recycle Bins or Trash folders can unnecessarily inflate backup sizes, consuming storage and increasing backup times.  

By tracking the Trash / Recycle Bin size per user, this template helps prevent wasted backup space and allows administrators to enforce cleanup policies before backups are performed.

---

## How It Works

1. A Low-Level Discovery rule runs on the host via Zabbix Agent / Agent 2.
2. A script scans the Trash / Recycle Bin directories:
   - On Windows: `C:\$Recycle.Bin`
   - On Linux: `~/.local/share/Trash`
3. User IDs or SIDs are converted into readable usernames.
4. System and default accounts are excluded from monitoring.
5. For each discovered user:
   - An item is created to monitor Trash size.
   - A trigger is created to alert when the size exceeds a configurable threshold.

---

## Components Overview

### Zabbix Template

The template contains:

- One **Low-Level Discovery rule** to discover users with a Trash / Recycle Bin folder  
- One **item prototype** to collect Trash / Recycle Bin size per user  
- One **trigger prototype** to detect when the size exceeds the threshold  
- One **user macro** to define the maximum allowed Trash / Recycle Bin size  

### Low-Level Discovery (LLD)

The discovery rule dynamically identifies users by inspecting Trash / Recycle Bin directories and returns a JSON structure compatible with Zabbix LLD.

Each discovered user automatically generates:

- A monitoring item  
- A trigger linked to that item  

### Items

For each discovered user, an item collects:

- The total size of the user’s Trash / Recycle Bin  
- The value in bytes (`UINT64` recommended)  
- Updates at a fixed interval (hourly by default)  

Usernames are normalized to ensure compatibility with Zabbix item keys.

### Triggers

Triggers evaluate the Trash / Recycle Bin size for each user.  
When the size remains above the defined threshold (default 1GB), an alert is raised, helping detect excessive disk usage.

### Macros

**{$RECYCLEBIN_THRESHOLD}**  

Defines the maximum allowed Trash / Recycle Bin size per user:

- Can be overridden at the host level  
- Allows different limits for different hosts  
- Does not require editing the template to adjust alerts  

---

## Script Integration

Custom scripts:

- Enumerate Trash / Recycle Bin folders  
- Convert user IDs/SIDs to usernames  
- Exclude system and default accounts  
- Calculate total size of deleted files per user  
- Return data for both discovery (LLD) and per-user checks  

On Windows, the template uses a **PowerShell script**;  
on Linux, it uses a **bash / shell script** that inspects `~/.local/share/Trash`.

---

## Zabbix Agent Integration

Custom parameters in Zabbix Agent / Agent 2 execute the scripts and return results to the Zabbix server.  
This allows native monitoring of hosts without external dependencies.

---

## Installation

### 1. Import the Template

Import the Zabbix template into your Zabbix server and link it to the desired hosts.

### 2. Zabbix Agent 2 Configuration (Windows)

Place the custom Zabbix Agent 2 configuration file `recyclebinW.conf` in the agent include directory:

`C:\Program Files\Zabbix Agent 2\zabbix_agent2.d\` (Windows)

or `recyclebinL.conf` in:

`/etc/zabbix/zabbix_agent2.d/recyclebinsize.conf` (Linux)


This configuration defines the custom parameters used by the template.

### 3. Script Placement

Create a folder for Zabbix scripts:

`C:\Zabbix\` (Windows)

or

`/usr/local/bin/` (Linux)


Place the corresponding script there (`recyclebinsizeW.ps1` for Windows, `recyclebinsizeL.sh` for Linux).

For Linux only, make it executable:

```
chmod +x /usr/local/bin/recyclebinsizeL.sh
```

And enable sudo NOPASSWD for Zabbix user:
```
echo 'Defaults:zabbix !requiretty
zabbix ALL=(ALL) NOPASSWD: /usr/local/bin/recyclebinsizeL.sh' > /etc/sudoers.d/zabbix.conf
```

### 4. Restart Zabbix Agent / Agent 2

After placing the configuration file and script, restart the **Zabbix Agent / Agent 2** service to apply the changes.

---

## Use Cases

- Detect oversized Recycle Bin / Trash folders per user  
- Prevent unnecessary disk space consumption  
- Monitor shared Windows and Linux systems  
- Enforce cleanup policies via alerting  

---

## Compatibility

- Windows and Linux operating systems  
- Zabbix Server **6.4+**  
- Zabbix Agent / Agent 2  
- Scripts must be present on each host for proper discovery  

---

## Notes

- Only real user accounts are monitored  
- System and default accounts are excluded  
- Discovery and monitoring are fully automatic  
- No manual item creation is required  

---

## Disclaimer

This template is provided as-is and should be tested in a non-production environment before deployment in critical systems.
