#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; Custom Settings

#SingleInstance Force
#MaxThreadsPerHotkey 1
#MaxHotkeysPerInterval 210

SetTitleMatchMode RegEx ; Enable RegEx matching for window titles.

; Global Constants

PROFILES_DIR := A_ScriptDir . "\Profiles"
SETTINGS_DIR := A_ScriptDir

SETTINGS_FILE := SETTINGS_DIR . "\GKRSettings.ini"
DEFAULT_PROFILE := PROFILES_DIR . "\DefaultProfile.csv"

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


; ------------------------------ Main ------------------------------ ;
main:
{
	GKRState := "Off"
	confSettings := initConfiguration()
	winGroupName := createWindowGroup(confSettings["allowedWindows"])
	globalHotkey := parseHotkey(confSettings["globalHotkey"])
	
	activityToggleFunc := Func("toggleGKRActivity")
		.Bind(confSettings["activeProfile"], winGroupName)
	
	Hotkey, %globalHotkey%, % activityToggleFunc
	
	Return
}
	
toggleGKRActivity(profile, groupName)
{
	Global GKRState
	
	If (GKRState = "On")
		GKRState:= "Off"
	Else
		GKRState := "On"
	
	MsgBox, Hotkeys %GKRState%
	rebindFromProfileForGroup(profile, groupName, GKRState)
	
	Return
}


; ------------------------------ Rebinds ------------------------------ ;

rebindFromProfileForGroup(profile, groupName, state)
{
	Loop, Read, %profile%
	{
		keys := StrSplit(A_LoopReadLine, ",")
		rebindKeys(keys[1], keys[2], groupName, state)
	}

	Return
}

rebindKeys(fromKey, toKey, groupName, state)
{
	If (fromKey != "" && toKey != "" )
	{
		toKeyDown := Func("_keyDown").Bind(toKey)
		toKeyUp := Func("_keyUp").Bind(toKey)
		
		Hotkey, IfWinActive, ahk_group %groupName%
		Hotkey, ~%fromKey%, % toKeyDown, %state%
		Hotkey, ~%fromKey% up, % toKeyUp, %state%
	}
	
	Return
}

_keyDown(target)
{
	Send, {%target% down}
	return
}

_keyUp(target)
{
	Send, {%target% up}
	return
}


; ------------------------------ Utility ------------------------------ ;

initConfiguration()
{
	global DEFAULT_PROFILE, DEFAULT_GLOBAL_HOTKEY, SETTINGS_FILE
	settings := Array()
	
	If (FileExist(SETTINGS_FILE) = "")
	{
		settings["firstRun"] := True
		settings["activeProfile"] := DEFAULT_PROFILE
		settings["globalHotkey"] := DEFAULT_GLOBAL_HOTKEY

		defaultSettings := "[General]"
						   . "`nglobalHotkey=" . settings["globalHotkey"]
						   . "`nactiveProfile=" . settings["activeProfile"]
						   . "`nallowedWindows="
		
		FileAppend, %defaultSettings%, %SETTINGS_FILE%
		
		If (ErrorLevel)
		{
			MsgBox, Error writing file %SETTINGS_FILE%.
			
			IfMsgBox Retry
				Reload
			Else
				ExitApp
		}
	}
	Else
	{
		settings["firstRun"] := False
		
		IniRead, settingSections, %SETTINGS_FILE%
		
		If (settingSections = "" || settingSections = "ERROR")
		{
			MsgBox, %SETTINGS_FILE% seems to be corrupted and recreating it may solve the problem. Recreate it?
			
			IfMsgBox Ok
			{
				FileDelete, %SETTINGS_FILE%
				Reload
			}
			Else
				ExitApp
		}
		
		Loop, Parse, settingSections, `n
		{
			IniRead, keyValPairs, %SETTINGS_FILE%, %A_LoopField%
			
			Loop, Parse, keyValPairs, `n
			{
				pair := StrSplit(A_LoopField, "=")
				key := pair[1]
				settings[key] := pair[2]
			}
		}
	}

	Return settings
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


parseHotkey(hk)
{
	StringUpper, hk, hk
	keys := StrSplit(hk, "+")
	parsedHk := ""
	
	If (keys.Length() > 1)
	{
		parsedHk := _handleModifiedHotkey(keys)
	}
	Else If (keys.Length() = 1)
	{
		parsedHk := hk
	}
	
	Return parsedHk
}

_handleModifiedHotkey(keys)
{
	global WIN_KEY, CTRL_KEY, LCTRL_KEY, RCTRL_KEY
	global SHIFT_KEY, LSHIFT_KEY, RSHIFT_KEY
	global ALT_KEY, ALTGR_KEY
	foundMods := []
	modifiedHk := ""

	For _, key in keys
	{		
		Switch key
		{
		Case "WIN":
			if (not InStr(foundMods, WIN_KEY))
			{
				foundMods := foundMods . WIN_KEY
				modifiedHK := modifiedHK . WIN_KEY
			}
			Else
			{
				MsgBox, Invalid hotkey %hk%. Repeating %key% modifiers are not allowed.
			}
		Case "CTRL":
			if (not InStr(foundMods, CTRL_KEY))
			{
				foundMods := foundMods . CTRL_KEY
				modifiedHK := modifiedHK . CTRL_KEY
			}
			Else
			{
				MsgBox, Invalid hotkey %hk%. Repeating %key% modifiers are not allowed.
			}
		Case "LCTRL":
			if (not InStr(foundMods, LCTRL_KEY))
			{
				foundMods := foundMods . LCTRL_KEY
				modifiedHK := modifiedHK . LCTRL_KEY
			}
			Else
			{
				MsgBox, Invalid hotkey %hk%. Repeating %key% modifiers are not allowed.
			}
		Case "RCTRL":
			if (not InStr(foundMods, RCTRL_KEY))
			{
				foundMods := foundMods . RCTRL_KEY
				modifiedHK := modifiedHK . RCTRL_KEY
			}
			Else
			{
				MsgBox, Invalid hotkey %hk%. Repeating %key% modifiers are not allowed.
			}
		Case "SHIFT":
			if (not InStr(foundMods, SHIFT_KEY))
			{
				foundMods := foundMods . SHIFT_KEY
				modifiedHK := modifiedHK . SHIFT_KEY
			}
			Else
			{
				MsgBox, Invalid hotkey %hk%. Repeating %key% modifiers are not allowed.
			}
		Case "LSHIFT":
			if (not InStr(foundMods, LSHIFT_KEY))
			{
				foundMods := foundMods . LSHIFT_KEY
				modifiedHK := modifiedHK . LSHIFT_KEY
			}
			Else
			{
				MsgBox, Invalid hotkey %hk%. Repeating %key% modifiers are not allowed.
			}
		Case "RSHIFT":
			if (not InStr(foundMods, RSHIFT_KEY))
			{
				foundMods := foundMods . RSHIFT_KEY
				modifiedHK := modifiedHK . RSHIFT_KEY
			}
			Else
			{
				MsgBox, Invalid hotkey %hk%. Repeating %key% modifiers are not allowed.
			}
		Case "ALT":
			if (not InStr(foundMods, ALT_KEY))
			{
				foundMods := foundMods . ALT_KEY
				modifiedHK := modifiedHK . ALT_KEY
			}
			Else
			{
				MsgBox, Invalid hotkey %hk%. Repeating %key% modifiers are not allowed.
			}
		Case "ALTGR":
			If (not InStr(foundMods, ALTGR_KEY))
			{
				foundMods := foundMods . ALTGR_KEY
				modifiedHK := modifiedHK . ALTGR_KEY
			}
			Else
			{
				MsgBox, Invalid hotkey %hk%. Repeating %key% modifiers are not allowed.
			}
		Default:
			modifiedHK := modifiedHK . key
		}
	}
		
	Return modifiedHK
}
