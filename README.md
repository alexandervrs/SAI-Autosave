#SAI Autosave

Autosave feature for Paint Tool SAI
version 3.0.0 by Alexander Vourtsis (@alexandervrs)


###Introduction
A free AutoIt powered script to autosave your SAI work on set intervals by triggering the Ctrl+S shortcut on your SAI window.
The utility can also take screen snapshots of SAI at set intervals more frequently, so if a crash occurs before you manage to save, you might be able to salvage the drawing and proceed to recreate the art using your screen-captured work in progress as reference. 
Furthermore as the utility saves, it can also store backups of the SAI files for you complete with date and time in the filename, so in case of a file corruption you can hopefully go back to a previous file and resume work from there. (Not available with SAI 2)
Finally it can also just remind you to save by popping a notification at set times.
This utility is provided AS-IS. Use it however you like!

Note that the script will check if the SAI window has focus first before saving and wait for you to switch to SAI if not (due to the script sending the Ctrl+S key shortcut to the SAI window), if you have the Blink setting on and the icon is visible on the Tray, then it will blink until you focus SAI. Also if you haven't saved the file first, you will probably get the Save dialog the first time the autosave occurs, naturally. You can Quit the utility manually from the system tray. If you close SAI, the script will exit automatically the next time it tries to autosave but doesn't find SAI open.

A word of warning, when you are editing other pictures that are not meant to be auto-saved, it's best to Pause the script first or set the AskBeforeSaving setting. Remember that the script will trigger the save shortcut, so anything in SAI that has focus, will be saved. To Pause the script from the system tray icon, right click and choose "Pause". When you need autosave back, the same way you can resume the script.

###Installation
Copy "SAI Autosave.exe" inside your Paint Tool SAI folder (Usually "C:\Paint Tool SAI") and make a shortcut to your Desktop/Taskbar. Every time you click on the icon, it will launch SAI with enabled autosave feature (You can disable this as well with the Settings - see below)

###Privileges Warning
The utility sends key commands to the SAI window, takes screenshots of it, performs file operations for the backups and uses explorer.exe to open folders which are not allowed under a Limited User account. As such the utility needs to be ran with elevated privileges, otherwise it may not function properly.

###Settings
You can access the utility's settings window by right clicking on the system tray icon and choosing the Settings option.
To customize the utility further, you can open the "Autosave Settings.ini" file and tweak the following settings:

* SaveMode (since 2.0.0)
Defines the manner of autosaving, setting to 0 will save the file and take a snapshot, 1 will only save the file, 2 will only take a snapshot, 3 will take a snapshot and show a notification reminder to save your work and 4 will just show a reminder

* SaveFileInterval
Default to 15 minutes, this is the interval that the autosave occurs

* SnapshotInterval (since 2.0.0)
Default to 180000 milliseconds (3 minutes), this is the interval that the snapshot capture occurs, the snapshots are kept in a folder named ~SAIAutosave.Snapshots and will be in your SAI folder

* Autolaunch
If set to 1 (default), it will also auto-launch sai.exe, useful if you want to make a shortcut to SAI Autosave.exe so that the Autosave functionality is available every time you open SAI through that shortcut.
Set it to 0 if you want to start SAI & the autosave utility manually instead.

* Path
By default, the utility tries to execute the "sai.exe" that exists in the same folder, if your SAI installation is elsewhere or want to keep this utility in its own folder, then you'll need to change the Path option to point to your SAI folder (don't include the trailing slash e.g. Path=C:\Paint Tool SAI ), default is "." (same directory)

* FileName
By default "sai.exe", the SAI executable name

* Silent
Whether the utility will not display any notifications while starting up and saving, use 1 for on, 0 for off

* Blink
The tray icon will blink if SAI does not have focus and the script is trying to save in order to remind you. Setting this to 0 will disable this, 1 is default.

* PausedOnStart (since 1.0.1)
Default is 0, when set to 1, then the Autosave feature will be paused when the utility starts and you will need to enable it via the option in the system tray icon.

* KeepBackups (since 2.0.0)
This will trigger a file backup whenever the utility autosaves, the backups are kept in a folder named ~SAIAutosave.Backups and will be in your SAI folder

* SaiVersion (since 3.0.0)
This defines which version of SAI is used, usually determines which window the utility will search for.

* AskBeforeSaving (since 3.0.0)
Whether the utility will popup a dialog before every save attempt asking the user if they want to save the currently opened file.

* WaitUntilProgramOpens (since 3.0.0)
Milliseconds to wait after SAI has been launched with a file as parameter. Raise this if SAI takes too long to launch, default is 1000 (1 second)


* If you accidentally mess up the "Autosave Settings.ini" file, just delete it and the utility will re-create it with its default settings.


###Changelog
* version 3.0.0 (1 September 2020, 03:10 UTC+2)
ADD: Support for SAI version 2
ADD: A quick Setup process when the utility is first used
ADD: Tray menu options to open the Snapshot and Backup folders
ADD: Tray option to trigger a Snapshot anytime
FIX: Fixed issue with reminder messages popping up endlessly
FIX: Small issue in Settings dialog with text scale
FIX: Utility now requires Admin rights to comply with UAC

* version 2.0.0 (16 June 2019, 05:22 UTC+2)
ADD: Ability for the utility to also snap screenshots periodically
ADD: Ability to Backup files when saving or with the context menu
ADD: Ability to show a reminder
ADD: Settings dialog with most common options included

* version 1.0.3 (19 April 2015, 20:00 UTC+2)
FIX: Fixed bug causing script only saving once and then quitting while SAI was still active

* version 1.0.2 (11 March 2015, 00:36 UTC+2)
FIX: Removed info before save, didn't work correct with Sleep() function, instead added the info to tray context menu & tooltip
FIX: Pause functionality fixes, not resuming correctly
ADD: Remaining time until next save in tray context menu and tooltip

* version 1.0.1 (10 March 2015, 22:58 UTC+2)
ADD: Added Pause/Resume feature
ADD: Script will now inform 3 seconds before autosaving begins
ADD: PausedOnStart .ini setting, default is 0 (If you can't see it, delete the "Autosave Settings.ini" file)
FIX: Fixed not saving when mouse/pen was pressed (now script waits until you release mouse/pen)
FIX: Fixed not exiting automatically if a program/folder title had the word "SAI" in it (now also checks process e.g. sai.exe)

* version 1.0.0 (09 March 2015, 00:57 UTC+2)
First release of the application