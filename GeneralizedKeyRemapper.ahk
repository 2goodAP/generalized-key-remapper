#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; ----------------------------- Custom Settings ----------------------------- ;

#SingleInstance Force
#MaxHotkeysPerInterval 210

SetTitleMatchMode RegEx ; Enable RegEx matching for window titles.

; ---------------------------- Global Constants ---------------------------- ;

; Meta

VERSION := "v0.1"

; Paths

CONFIG_DIR := A_ScriptDir
PROFILES_DIR := A_ScriptDir . "\profiles"
ICONS_DIR := A_ScriptDir . "\icons"

CONFIG_FILE := CONFIG_DIR . "\GKRConfig.ini"
DEFAULT_PROFILE := PROFILES_DIR . "\default_profile.ini"

HOTKEYS_OFF_ICON := ICONS_DIR . "\gkr_off.ico"
HOTKEYS_ON_ICON := ICONS_DIR . "\gkr_on.ico"

; Key Modifiers

CTRL_KEY := "^"
LCTRL_KEY := "<^"
RCTRL_KEY := ">^"

SHIFT_KEY := "+"
LSHIFT_KEY := "<+"
RSHIFT_KEY := ">+"

WIN_KEY := "#"

ALT_KEY := "!"
LALT_KEY := "<!"
RALT_KEY := ">!"

ALTGR_KEY := "<^>!"

DEFAULT_GLOBAL_HOTKEY := "ctrl+f2"

; ---------------------------- Error Constants ---------------------------- ;

MISSING_CONFIG_ERROR := 1
CONFIG_READ_ERROR := 2
CONFIG_WRITE_ERROR := 3
GLOBAL_HOTKEY_ERROR := 4
REPEAT_MODIFIER_ERROR := 5
KEY_REMAP_ERROR := 6
WINDOW_NAME_ERROR := 7


; ----------------------------- Main Functions ----------------------------- ;


main:
{
	GKRStatus := "Off"

	changeTrayIcon(HOTKEYS_OFF_ICON)

	defaultConfig := "[General]"
					   . "`nglobal_hotkey=" . DEFAULT_GLOBAL_HOTKEY
					   . "`n[Profile]"
					   . "`nactive_profile=" . DEFAULT_PROFILE
	defaultProfile := "[Permission]"
					  . "`npermitted_windows="
					  . "`ndisable_source_key="
					  . "`n[Remapping]"

	configSettings := readConfigFile(CONFIG_FILE, defaultConfig)
	profileSettings := readConfigFile(configSettings["profile"]["active_profile"]
									  , defaultProfile)

	If (configSettings["general"]["global_hotkey"] = "")
	{
		MsgBox, % "Error processing global hotkey in:`n" CONFIG_FILE "`nMissing global hotkey."

		ExitApp, %GLOBAL_HOTKEY_ERROR%
	}

	globalHotkey := parseHotkey(configSettings["general"]["global_hotkey"])
	keyRemaps := parseRemaps(profileSettings["remapping"]
							 , profileSettings["permission"]["disable_source_key"])

	winGroupName := createWindowGroup(profileSettings["permission"]["permitted_windows"])

	activityToggleFunc := Func("toggleGKRActivity")
		.Bind(configSettings["general"]["active_profile"]
			  , winGroupName, keyRemaps, HOTKEYS_OFF_ICON, HOTKEYS_ON_ICON)

	Try
		Hotkey, %globalHotkey%, % activityToggleFunc
	Catch err
	{
		MsgBox, % "Error processing global hotkey in:`n" CONFIG_FILE "`n" err.message

		ExitApp, %GLOBAL_HOTKEY_ERROR%
	}

	Return
}


toggleGKRActivity(profile, groupName, remaps, offIcon, onIcon)
{
	Global GKRStatus

	If (GKRStatus = "On")
		GKRStatus:= "Off"
	Else
		GKRStatus := "On"

	MsgBox, % "Hotkey Remapping " GKRStatus
	changeTrayIcon(offIcon, onIcon, GKRStatus)

	remapKeysForGroup(remaps, groupName, GKRStatus)

	Return
}


; ------------------------ Remap-Specific Functions ------------------------ ;


parseRemaps(remaps, disableFromKey:="")
{
	If (remaps = "")
		Return ""

	Global KEY_REMAP_ERROR
	parsedRemaps := {}

	For fromKey, toKeys in remaps
	{
		If (fromKey != "" && toKeys = "")
		{
			MsgBox, % "Error binding " fromKey " to nothing in:`n" profile

			ExitApp, %KEY_REMAP_ERROR%
		}
		Else If (fromKey = "" && toKeys != "")
		{
			MsgBox, % "Error binding nothing to " toKeys " in:`n" profile

			ExitApp, %KEY_REMAP_ERROR%
		}
		Else If (fromKey != "" && toKeys != "")
		{
			toKeys := StrSplit(toKeys, "<~>", " `t")
			parsedFromKey := parseHotkey(fromKey)

			If (disableFromKey != "yes")
				parsedFromKey := "~" . parsedFromKey

			parsedRemaps[parsedFromKey] := []

			For _, toKey in toKeys
				parsedRemaps[parsedFromKey].Push(parseHotkey(toKey, True))
		}
	}

	Return parsedRemaps
}



remapKeysForGroup(remaps, groupName, hkStatus)
{
	Global KEY_REMAP_ERROR

	If (remaps != "")
		For fromKey, toKeys in remaps
			remapKeys(fromKey, toKeys, groupName, hkStatus)

	Return
}


remapKeys(fromKey, toKeys, groupName, hkStatus)
{
	Global KEY_REMAP_ERROR
	emulateToKeys := Func("_emulateKeys").Bind(toKeys)

	Try
	{
		Hotkey, IfWinActive, ahk_group %groupName%
		Hotkey, %fromKey%, % emulateToKeys, %hkStatus%
	}
	Catch e
	{
		MsgBox, % "Error processing remap.`n" e.message

		ExitApp, %KEY_REMAP_ERROR%
	}

	Return
}


; --------------------------- Utility Functions --------------------------- ;


changeTrayIcon(icn, altIcn:="", globalStatus:="Off")
{
	If (globalStatus = "Off")
	{
		If (icn = "")
			Return

		Try
			Menu, Tray, Icon, %icn%
		Catch e
		{
			MsgBox, % "Error loading icon:`n" icn
			Menu, Tray, Icon, *
		}
	}
	Else
	{
		If (altIcn = "")
			Return

		Try
			Menu, Tray, Icon, %altIcn%
		Catch e
		{
			MsgBox, % "Error loading icon:`n" altIcn
			Menu, Tray, Icon, *
		}
	}

	Return
}


readConfigFile(configFile, defaultConfig)
{
	Global MISSING_CONFIG_ERROR

	If (configFile = "")
	{
		MsgBox, % "Error processing configuration file.`nNo path specified for a valid config file."

		ExitApp, %MISSING_CONFIG_ERROR%
	}

	Global CONFIG_WRITE_ERROR, CONFIG_READ_ERROR
	SplitPath, configFile,, configDir
	config := {}

	If (FileExist(configDir) = "")
	{
		FileCreateDir, %configDir%

		If (ErrorLevel)
		{
			MsgBox, % "Error creating folder:`n" configDir "`nPlease check your disk space or try running the program as administrator."

			ExitApp, %CONFIG_WRITE_ERROR%
		}
	}

	If (FileExist(configFile) = "")
	{
		FileAppend, %defaultConfig%, %configFile%

		If (ErrorLevel)
		{
			MsgBox, "Error writing file:`n" configFile "`nPlease check your disk space or try running the program as administrator."

			ExitApp, %CONFIG_WRITE_ERROR%
		}
	}

	config := _readINIFile(configFile)

	If (config = "")
	{
		MsgBox, 0x4,, % "Error reading file:`n" configFile "`nRecreating it may solve the problem.`nRecreate it?"

		IfMsgBox Yes
		{
			FileDelete, %configFile%
			config := readConfigFile(configFile, defaultConfig)
		}
		Else
			ExitApp, %CONFIG_READ_ERROR%
	}
	Else
		config["firstRun"] := False

	Return config
}


createWindowGroup(permittedWins)
{
	groupName := "PermittedWindows"

	If (permittedWins = "")
	{
		GroupAdd, %groupName%

		Return groupName
	}

	windows := StrSplit(permittedWins, "<~>", " `t")

	For _, window in windows
	{
		If (RegExMatch(window, "i).+\.exe$"))
			GroupAdd, %groupName%, ahk_exe %window%
		Else
			GroupAdd, %groupName%, %window%
	}

	Return groupName
}


parseHotkey(hk, toSend:=False)
{
	If (hk = "" || hk = "+")
		Return ""

	Global REPEAT_MODIFIER_ERROR
	StringLower, hk, hk

	If (hk = "++")
		keys := ["+"]
	Else
		keys := StrSplit(hk, "+", " `t")

	If (toSend)
		parsedHk := "{" . keys[1] . "}"
	Else
		parsedHk := keys[1]

	If (keys.Length() > 1)
	{
		parsedHk := _handleModifiedHotkey(keys, toSend)

		If (parsedHK = "")
		{
			MsgBox, % "Error processing invalid hotkey " hk ".`nRepeating the same modifiers is not allowed."

			ExitApp, %REPEAT_MODIFIER_ERROR%
		}
	}

	Return parsedHk
}


; --------------------------- Internal Functions --------------------------- ;


_emulateKeys(keys)
{
	For _, key in keys
		Send %key%

	Return
}


_readINIFile(file)
{
	parsedINI := {}

	IniRead, headers, %file%

	If (headers = "" || headers = "ERROR")
		Return ""

	Loop, Parse, headers, `n
	{
		StringLower, header, A_LoopField

		IniRead, keyValPairs, %file%, %A_LoopField%

		If (keyValPairs = "")
			parsedINI[header] := ""
		Else
		{
			parsedINI[header] := {}

			Loop, Parse, keyValPairs, `n
			{
				pair := StrSplit(A_LoopField, "=", " `t")

				key := pair[1], value := pair[2]
				StringLower, key, key
				StringLower, value, value

				parsedINI[header][key] := value
			}
		}
	}

	Return parsedINI
}


_handleModifiedHotkey(keys, toSend:=False)
{
	Global WIN_KEY, CTRL_KEY, LCTRL_KEY, RCTRL_KEY
	Global SHIFT_KEY, LSHIFT_KEY, RSHIFT_KEY
	Global ALT_KEY, LALT_KEY, RALT_KEY, ALTGR_KEY
	foundMods := ""
	modifiedHk := ""

	For _, key in keys
	{
		Switch key
		{
		Case "win":
			if (not InStr(foundMods, WIN_KEY))
			{
				foundMods := foundMods . "," . WIN_KEY
				modifiedHk := modifiedHk . WIN_KEY
			}
			Else
				Return ""
		Case "ctrl":
			if (not InStr(foundMods, CTRL_KEY))
			{
				foundMods := foundMods . "," . CTRL_KEY
				modifiedHk := modifiedHk . CTRL_KEY
			}
			Else
				Return ""
		Case "lctrl":
			if (not InStr(foundMods, LCTRL_KEY))
			{
				foundMods := foundMods . "," . LCTRL_KEY
				modifiedHk := modifiedHk . LCTRL_KEY
			}
			Else
				Return ""
		Case "rctrl":
			if (not InStr(foundMods, RCTRL_KEY))
			{
				foundMods := foundMods . "," . RCTRL_KEY
				modifiedHk := modifiedHk . RCTRL_KEY
			}
			Else
				Return ""
		Case "shift":
			if (not InStr(foundMods, SHIFT_KEY))
			{
				foundMods := foundMods . "," . SHIFT_KEY
				modifiedHk := modifiedHk . SHIFT_KEY
			}
			Else
				Return ""
		Case "lshift":
			if (not InStr(foundMods, LSHIFT_KEY))
			{
				foundMods := foundMods . "," . LSHIFT_KEY
				modifiedHk := modifiedHk . LSHIFT_KEY
			}
			Else
				Return ""
		Case "rshift":
			if (not InStr(foundMods, RSHIFT_KEY))
			{
				foundMods := foundMods . "," . RSHIFT_KEY
				modifiedHk := modifiedHk . RSHIFT_KEY
			}
			Else
				Return ""
		Case "alt":
			if (not InStr(foundMods, ALT_KEY))
			{
				foundMods := foundMods . "," . ALT_KEY
				modifiedHk := modifiedHk . ALT_KEY
			}
			Else
				Return ""
		Case "lalt":
			if (not InStr(foundMods, LALT_KEY))
			{
				foundMods := foundMods . "," . LALT_KEY
				modifiedHk := modifiedHk . LALT_KEY
			}
			Else
				Return ""
		Case "ralt":
			if (not InStr(foundMods, RALT_KEY))
			{
				foundMods := foundMods . "," . RALT_KEY
				modifiedHk := modifiedHk . RALT_KEY
			}
			Else
				Return ""
		Case "altgr":
			If (not InStr(foundMods, ALTGR_KEY))
			{
				foundMods := foundMods . "," . ALTGR_KEY
				modifiedHk := modifiedHk . ALTGR_KEY
			}
			Else
				Return ""
		Default:
			If (toSend)
				modifiedHk := modifiedHk . "{" . key . "}"
			Else
				modifiedHk := modifiedHk . key
		}
	}

	Return modifiedHK
}