# Generalized Key Remapper (GKR)

Have you ever had the problem where an app or a game does not allow you to remap some of their most critical functionality to specific buttons.
 This problem may be specially relevant to gamers as many game titles do not allow remapping inputs.
 Even the programs that allow such remaps sometimes limit the remapping to only a subset of the keys present on a keyboard, for eg. alphabet keys.

Maybe you want to map a functionality to a combination of easily reachable buttons, for eg. Alt+z.
 However some apps and many games do not allow such combos to be mapped onto any functionality.

Or perhaps you are someone who uses an unconventional button layout, either out of perference or some physical limitation.
 I myself am a left handed person who perfers to use the mouse with my main hand. So, I have my right hand on the keyboard on most circumstances
 and would like all the shortcuts or game bindings to be towards the right side of the keyboard.

__GKR aims to solve these problems with a simple, lightweight and configurable AutoHotkey script for remapping keyboard and mouse buttons to various other keyboard or mouse buttons.__


## Disclaimer

- GKR is not a malware. GKR itself does not, and will never, send any of your inputs or keystrokes over the internet as long as AutoHotkey does not do it too.

- Since GKR only uses AutoHotkey to perform the remapping, it should be quite safe for most applications or games.
 However, the anti-hack software in some online games may recogonize this script as a malware, which may lead your account being banned in some shape or form.
 As AutoHotkey itself does not guarentee 100% safety in all online apps, and especially games,
 __use this script at your own discretion as I will not be responsible for any bans or account dismissals relating to the use of the script.__


## Features

- Toggle your rebinds on or off using a configurable global hotkey.
- Multiple profiles that allow you to set up different remappings.
- Remappings can be enabled only for specific windows as necessary.


## Installation


## Usage and Basic Configuration

After downloading, simply run the script "GeneralizedKeyRemapper.exe".
 A black keyboard icon will appear in the system tray signifying that the script is now running.
 On the very first run, a configuration file "GKRConfig.ini", a directory "profiles" and a profile file "profiles\default_profile.ini" will automatically be generated,
 as shown in the directory structure below. 
 
__Directory Structure:__

```
.  
|- GeneralizedKeyRemapper.exe  
|- GKRConfig.ini  
|- profiles  
   |- default_profile.ini
```
 
To change rebinds, open up "profiles\default_profile.ini" in Notepad, or any other text editor,
 and add lines in the `[Rebinds]` section as follows:

	[Permission]
	permitted_windows=
	disable_source_key=
	[Rebinds]
	<pre>
	</b>a=b</b>
	</b>ctrl+z=alt+f+s</b>
	</pre>

Then restart the "GeneralizedKeyRemapper.exe" script and press the *global hotkey*, which is `ctrl+f2` by default (hold down ctrl and then press f2) to enable hotkeys.
 The tray icon will change to a white keyboard, a popup window will show up with the message "Hotkey Remapping On" and the remaps will now be available.

- Everytime you hit the `a` key the active window will behave as if `a` and `b` keys have been pressed sequentially.
- Everytime you hit `ctrl+z` the active window will behave as if `ctrl+z` and `alt+f+s` have been pressed sequentially.
 
To turn off this behavior, simply press the *global hotkey* (`ctrl+f2` by default) again. The tray icon will revert back to the black keyboard, another popup saying "Hotkey Remapping Off" will appear and all the remappings will be disabled.

You can keep enabling and disabling the hotkey remapping as you see fit using the *global hotkey*.

GKR supports a bunch of other handy configuration option which will make your experience more pleasant.
 Check out the [__Detailed_Configuration__](#Detailed-Configuration) section below to learn more about them.

### Modifier Keys

As you may have observed in the above example, modifier keys such as "ctrl" and "alt" can be specified using the modifier name followed by a `+` sign.
 The following modifier names are allowed by GKR:
 
- "win" for both the left or the right windows keys.
- "ctrl" for both the left or the right control keys.
- "alt" for both the left or the right alternate keys.
- "shift" for both the left or the right shift keys.
- "lctrl" and "rctrl" for only the left and the right control keys respectively.
- "lalt" and "ralt" for only the left and the right alternate keys respectively.
- "lshift" and "rshift" for only the left and the right shift keys respectively.
- "altgr" for the special altgr key (generally the right alt) in case "ralt" does not work for you.


## Detailed Configuration

__Warning:__ Do not forget to *restart* the "GeneralizedKeyRemapper.exe" script every time you modify any value in either the configuration file or the profile file for the changes to take effect.
 Also make sure to enable the hotkey remappings by pressing the *global hotkey* (`ctrl+f2` by default). 

You can further configure GKR to make it more favourable for your personal use.
 In this section, we will discuss all the important config settings by correlating them to their respective features.

__Notes:__ 
1. Many of the settings explained below are present in the active profile file. The path to this file can be found in "GKRConfig.ini" under the "[Profile]" section.
 In the example given below the active profile file is located at "__D:\profiles\default_profile.ini__"

	[General]
	global_hotkey=ctrl+f2
	[Profile]
	<pre>
	active_profile=<b>D:\profiles\default_profile.ini</b>
	</pre>

2. Please refer to the [AutoHotkey Keylist](https://www.autohotkey.com/docs/KeyList.htm) to access the list of all the valid key names.

### Change the Global Hotkey

To change the global hotkey, simply change the value of the `global_hotkey` field in "GKRConfig.ini" to a valid regular or modified key name.
 Then restart the script to apply the new global hotkey.

Example:

	[General]
	<pre>
	<b>global_hotkey=ctrl+shift+z</b>
	</pre>
	[Profile]
	active_profile=d:\profiles\default_profiles.ini
		
This changes your global hotkey to `ctrl+shift+z` instead of the default `ctrl+f2` on subsequent runs.

### Switch Active Profiles

You can create multiple profiles with different remappings and different allowed windows for each profile.
 To achieve this, change the value of the `active_profile` field in "GKRConfig.ini" to the path to your profile.
 Now restart the script for the new profile to take effect.

If the specified profile file does not already exist, it will be created automatically with the default settings on the next run.
 
Example:
		
	[General]
	global_hotkey=ctrl+f2
	[Profile]
	<pre>
	</b>active_profile=d:\profiles\my_profile.ini</b>
	</pre>
	
This change either applies the settings present in "d:\profiles\my_profile.ini" (or creates the file with default settings, if it does not already exist) on the next run of the script.

### Remap One Keyress to Behave as Multiple Keypresses

In the active profile file, you can assign remaps such that pressing one key will emulate the pressing of multiple keys.

Example:

	[Permission]
	permitted_windows=
	disable_source_key=
	[Remapping]
	<pre>
	<b>a=b<~>c<~>ctrl+a</b>
	<b>x=ctrl+x<~>ctrl+v</b>
	</pre>

__Note:__ The `<~>` symbol is used to separate multiple target keys from one another.

After adding the remaps `a=b<~>c<~>ctrl+a` and `x=ctrl+x<~>ctrl+v` into your profile file, restarting the script and turning on the hotkeys,

- Pressing the `a` key will produce the same result as pressing `a`, `b`, `c` and `ctrl+a` sequentially.
- Pressing the `x` key will produce the same result as pressing `ctrl+x` and `ctrl+v` sequentially.

You can add as many of such remappings as you feel necessary.

### Disable the Source Key

In the examples given in the [previous section](#Remap-One-Keypress-to-Behave-as-Multiple-Keypresses), you may have noticed that the source key (the key that you pressed) is not being masked,
 i.e. it is still being registererd as a pressed key/key sequence.
 This behavior can cause problems if you are remapping a key with predefined functionality, such as `ctrl+a` to something else.

Example:

	[Permission]
	permitted_windows=
	disable_source_key=
	[Remapping]
	<pre>
	<b>ctrl+a=shift+a</b>
	</pre>

In the above example, while pressing `ctrl+a`, both `ctrl+a` as well as `shift+a` get registered.
 If you are in a text editing program, that can replace all the text in window to an `A`.
 
To avoid this problem, you can set the `disable_source_key` field to `Yes` in the active profile and restart the script to avoid this problem.

Example:

	[Permission]
	permitted_windows=
	<pre>
	<b>disable_source_key=Yes</b>
	</pre>
	[Remapping]
	ctrl+a=shift+a

Now the default behavior behavior of `ctrl+a` will be supressed and it will only behave as it it were `shift+a`.

# Enable Hotkey Remaps on Selected Windows Only

The hotkey remaps that we have been learning about in the previous sections are applicable to any active window,
 i.e. they will work whether Notepad, Windows Explorer, or Firefox is currently active.
 
This may be a source of inconvenience as some hotkeys may be intrusive to some of these apps.
 You can avoid this problem by using the `permitted_windows` field in the active profile file.
 
Example:

	[Permission]
	<pre>
	<b>permitted_windows=AutoHotkey Help<~>Untitled - Notepad</b>
	</pre>
	disable_source_key=
	[Remapping]
	ctrl+a=shift+a
		
__Note:__ The `<~>` symbol is used to separate multiple window titles from one another.
		
Applying the example profile above will make sure that the `ctrl+a` hotkey remap will activate only when a window with a title *exactly matching* "AutoHotkey Help" or "Untitled - Notepad" are currently active.

You can also specify __regular expressions__ to represent the window titles to make them more generalized.

Example:

	[Permission]
	<pre>
	<b>permitted_windows=.*AutoHotkey.*<~>.*Notepad.*</b>
	</pre>
	disable_source_key=
	[Remapping]
	ctrl+a=shift+a
		
Applying the example profile above will make sure that the `ctrl+a` hotkey remap will activate when a window title contains "AutoHotkey" or "Notepad" at any location,
 i.e. the hotkey remap `ctrl+a` will work under windows with titles containing "Notepad", "Notepad++", "AutoHotkey Help", "Ahk2Exe for AutoHotkey", and so on.

You can also supply various __options__ to the regular expressions to further generalize the window names.

Example:

	[Permission]
	<pre>
	<b>permitted_windows=i).*autohotkey.*<~>i).*notepad.*</b>
	</pre>
	disable_source_key=
	[Remapping]
	ctrl+a=shift+a
		
The above configuration file has the same effect as the example before as the "i)" option allows for case-insensitive matching,
 i.e. the hotkey remap `ctrl+a` will not only work under windows with titles containing "Notepad", "Notepad++", "AutoHotkey Help", "Ahk2Exe for AutoHotkey"
 but will also work under windows with titles containing "notepad", "notepad++", "autohotkey help", "ahk2exe for autohotkey".
 
__Note:__ You can learn more about the regular expression syntax and options supported by GKR under [AutoHotkey's Regular Expression Quick Reference](https://www.autohotkey.com/docs/misc/RegEx-QuickRef.htm).


## Acknowledgements and Attributions

Some ideas and inspirations, not code however, were derived from the following projects:

- [mouse2joystick_custom_CEMU](https://github.com/CemuUser8/mouse2joystick_custom_CEMU) by [CemuUser8](https://github.com/CemuUser8).
- [EMU Light - Enhanced Moveset Utility](https://www.nexusmods.com/darksouls3/mods/83) by [KowboyBebop](https://www.nexusmods.com/darksouls3/users/1630965).

The white keyboard and black keyboard tray icons were created using icons made by [Freepik](https://www.freepik.com) from [www.flaticon.com](https://www.flaticon.com).
