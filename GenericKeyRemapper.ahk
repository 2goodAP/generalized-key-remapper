#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; ----------------------------- Custom Settings ----------------------------- ;

#SingleInstance Force
#MaxHotkeysPerInterval 210

SetTitleMatchMode RegEx ; Enable RegEx matching for window titles.

; ---------------------------- Global Constants ---------------------------- ;

PROFILES_DIR := A_ScriptDir . "\Profiles"
SETTINGS_DIR := A_ScriptDir

SETTINGS_FILE := SETTINGS_DIR . "\GKRSettings.ini"
DEFAULT_PROFILE := PROFILES_DIR . "\DefaultProfile.ini"

CTRL_KEY := "^"
LCTRL_KEY := "<^"
RCTRL_KEY := ">^"

SHIFT_KEY := "+"
LSHIFT_KEY := "<+"
RSHIFT_KEY := ">+"

WIN_KEY := "#"

ALT_KEY := "!"
ALTGR_KEY := "<^>!"

DEFAULT_GLOBAL_HOTKEY := "CTRL+F2"

; ---------------------------- Error Constants ---------------------------- ;

CONFIG_READ_ERROR := 1
CONFIG_WRITE_ERROR := 2
KEY_REBIND_ERROR := 3
REPEAT_MODIFIER_ERROR := 4
GLOBAL_HOTKEY_ERROR := 5


; ------------------------------ Main ------------------------------ ;


main:
{
	GKRState := "Off"
	defaultSettings := "[General]"
					   . "`nglobalHotkey=" . DEFAULT_GLOBAL_HOTKEY
					   . "`nactiveProfile=" . DEFAULT_PROFILE
	defaultProfile := "[Window]"
					  . "`nallowedWindows="
					  . "`n[Rebinds]"

	configSettings := initConfiguration(SETTINGS_FILE, defaultSettings)
	profileSettings := initConfiguration(configSettings["General"]["activeProfile"]
										 , defaultProfile)

	If (configSettings["General"]["globalHotkey"] = "")
	{
		MsgBox, Error processing missing global hotkey in %SETTINGS_FILE%.
		
		ExitApp, GLOBAL_HOTKEY_ERROR
	}
	
	globalHotkey := parseHotkey(configSettings["General"]["globalHotkey"])
	keyRebinds := parseRebinds(profileSettings["Rebinds"])
	
	winGroupName := createWindowGroup(profileSettings["Window"]["allowedWindows"])
	
	activityToggleFunc := Func("toggleGKRActivity")
		.Bind(configSettings["General"]["activeProfile"]
			  , winGroupName, keyRebinds)
	
	Try
		Hotkey, ^f2, % activityToggleFunc
	Catch err
	{
		MsgBox, % "Error processing global hotkey in " SETTINGS_FILE ". " err.message
		
		ExitApp, GLOBAL_HOTKEY_ERROR
	}
	
	Return
}
	
	
toggleGKRActivity(profile, groupName, rebinds)
{
	Global GKRState
	
	If (GKRState = "On")
		GKRState:= "Off"
	Else
		GKRState := "On"
	
	MsgBox, Hotkeys %GKRState%
	rebindKeysForGroup(rebinds, groupName, GKRState)
	
	Return
}


; ------------------------------ Rebinds ------------------------------ ;


parseRebinds(rebinds)
{	
	If (rebinds = "")
		Return ""

	Global KEY_REBIND_ERROR
	parsedRebinds := {}
	
	For fromKey, toKeys in rebinds
	{
		If (fromKey != "" && toKeys = "")
		{
			MsgBox, Error binding %fromKey% to nothing in %profile%.

			ExitApp, KEY_REBIND_ERROR
		}
		Else If (fromKey = "" && toKeys != "")
		{
			MsgBox, Error binding nothing to %toKeys% in %profile%.

			ExitApp, KEY_REBIND_ERROR
		}
		Else If (fromKey != "" && toKeys != "")
		{
			toKeys := StrSplit(toKeys, "<~>")
			parsedFromKey := parseHotkey(fromKey)
			parsedRebinds[parsedFromKey] := []

			For _, toKey in toKeys
				parsedRebinds[parsedFromKey].Push(parseHotkey(toKey, True))
		}
	}
	
	Return parsedRebinds
}



rebindKeysForGroup(rebinds, groupName, hkState)
{
	Global KEY_REBIND_ERROR
	
	If (rebinds != "")
		For fromKey, toKeys in rebinds
			rebindKeys(fromKey, toKeys, groupName, hkState)

	Return
}


rebindKeys(fromKey, toKeys, groupName, hkState)
{
	simulateToKeys := Func("_simulateKeys").Bind(toKeys)
	Hotkey, IfWinActive, ahk_group %groupName%
	Hotkey, ~%fromKey%, % simulateToKeys, %hkState%
	
	Return
}


; ------------------------------ Utility ------------------------------ ;


initConfiguration(configFile, defaultConfig)
{
	Global CONFIG_WRITE_ERROR, CONFIG_READ_ERROR
	config := {}
	
	If (FileExist(configFile) = "")
	{		
		FileAppend, %defaultConfig%, %configFile%
		
		If (ErrorLevel)
		{
			MsgBox, Error writing file %configFile%. Please check your disk space or try running the program as administrator.

			ExitApp, CONFIG_WRITE_ERROR
		}
	}

	config := _readINIFile(configFile)

	If (config = "")
	{
		MsgBox, 0x4,, Error reading %configFile%. Recreating it may solve the problem. Recreate it?

		IfMsgBox Yes
		{
			FileDelete, %configFile%
			config := initConfiguration(configFile, defaultConfig)
		}
		Else
			ExitApp, CONFIG_READ_ERROR
	}
	Else
		config["firstRun"] := False
	
	Return config
}


createWindowGroup(allowedWins)
{
	groupName := "AllowedWindows"

	If (allowedWins = "")
	{
		GroupAdd, %groupName%
		
		Return groupName
	}
	
	windows := StrSplit(allowedWins, "<~>")
	
	For _, window in windows
	{		
		If (RegExMatch(window, "i).*\.exe$"))
			GroupAdd, %groupName%, ahk_exe %window%
		Else
			GroupAdd, %groupName%, %window%
	}
	
	Return groupName
}


parseHotkey(hk, toSend:=False)
{
	If (hk = "")
		Return ""

	Global REPEAT_MODIFIER_ERROR
	StringLower, hk, hk
	MsgBox, %hk%
	keys := StrSplit(hk, "+")
	
	If (toSend)
		parsedHk := "{" . hk . "}"
	Else
		parsedHk := hk
	
	If (keys.Length() > 1)
	{
		parsedHk := _handleModifiedHotkey(keys, toSend)
			
		If (parsedHK = "")
		{
			MsgBox, Error processing invalid hotkey %hk%. Repeating the same modifiers is not allowed.
			
			ExitApp, REPEAT_MODIFIER_ERROR
		}
	}
	MsgBox, %parsedHk%
	
	Return parsedHk
}


; ------------------------------ Internal ------------------------------ ;


_simulateKeys(keys)
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
		header := A_LoopField

		IniRead, keyValPairs, %file%, %A_LoopField%
		
		If (keyValPairs = "")
			parsedINI[header] := ""
		Else
		{
			parsedINI[header] := {}

			Loop, Parse, keyValPairs, `n
			{
				pair := StrSplit(A_LoopField, "=")
				parsedINI[header][pair[1]] := pair[2]
			}
		}
	}
	
	Return parsedINI
}


_handleModifiedHotkey(keys, toSend:=False)
{
	global WIN_KEY, CTRL_KEY, LCTRL_KEY, RCTRL_KEY
	global SHIFT_KEY, LSHIFT_KEY, RSHIFT_KEY
	global ALT_KEY, ALTGR_KEY
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
