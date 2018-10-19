'******************************************************************************
' Error-code 0 = no error encounterd
' Error-code 1 = generic error
' Error-code 2 = incorrect number of arguments
' Error-code 3 = devcon not found
'******************************************************************************
Option Explicit

Dim objFso, objWso, objWmi, objReg, objArgs
Dim stdIn, stdOut, stdErr
Dim strComputer, strScriptPath, strUsage
Dim objLogFile
Dim bolVirtual
Dim strArguments
Dim strArchitecture
Dim strDevcon
Dim arrCurrentDevicesHwid(), arrCurrentDevicesName()
Dim arrAllDevicesHwid(), arrAllDevicesName()
Dim arrPotentialNonPresentDevicesHwid(), arrPotentialNonPresentDevicesName()
Dim arrNonPresentDevicesHwid(), arrNonPresentDevicesName()

Const HKCU = &H80000001
Const HKLM = &H80000002

Const conForReading	  = 1
Const conForWriting	  = 2
Const conForAppending = 8

strComputer   = "."
strScriptPath = Left(WScript.ScriptFullName,InstrRev(WScript.ScriptFullName,"\"))
strUsage      = "Usage: cscript " & WScript.ScriptName

Set objFso  = CreateObject("Scripting.FileSystemObject")
Set objWso  = CreateObject("Wscript.Shell")
Set objWmi  = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
Set objReg  = GetObject("winmgmts:\\" & strComputer & "\root\default:StdRegProv")
Set objArgs = WScript.Arguments

Set stdIn  = WScript.StdIn
Set stdOut = WScript.StdOut
Set stdErr = WScript.StdErr

Call Main()
	
WScript.Quit

'******************************************************************************
Sub Main()

	' Does logs dir exists on d:?
	If objFso.FolderExists("d:\logs") Then
		' Yes. Open file for writing.
		Set objLogFile = objFso.OpenTextFile("d:\logs\"& WScript.ScriptName & ".log", conForWriting, True)
	' No. Does logs dir exist on c:?
	Else
		If Not objFso.FolderExists("c:\logs") Then
			objFso.CreateFolder("c:\logs")
		End If
		Set objLogFile = objFso.OpenTextFile("c:\logs\"& WScript.ScriptName & ".log", conForWriting, True)
	End If

	Call subCheckScriptingHost()
	Call subCheckArguments()
	Call subCheckDevcon()
	Call subRetrieveArchitecture()
	Call subDetermineCurrentDevices()
	Call subDetermineAllDevices()
	Call subDeterminePotentialNonPresentDevices()
	Call subRemoveNonPresentDevices()
	Call subRescanDevices()

End Sub

'******************************************************************************
Sub subCheckScriptingHost()

	Dim strCmd
	Dim strArgument
	Dim strOutput

	' Was the script started with cscript or cscript?	
	If Not InStr(UCase(WScript.FullName), "CSCRIPT") <> 0 Then
		' Script started with wscript. Restart script with cscript.
		strCmd = "cmd /k cscript.exe " & Chr(34) & WScript.ScriptFullName & Chr(34)
		' Enumerate arguments given with original startup command.
		For Each strArgument In WScript.Arguments
			strCmd = strCmd & " " & strArgument
		Next
		' Run script with cscript ant original parameters.
		strOutput = objWso.Run(strCmd, 1, False)
		' Quit this instance of the script that was started with wscript. 
		WScript.Quit
	End If

End Sub

'******************************************************************************
Sub subCheckArguments()

	Call subLogIt(objLogFile, "Checking script arguments...", "screen")
	Call subLogIt(objLogFile, "", "screen")
	
	Dim intCounter

	' Enumerate all arguments.	
	'For intCounter = 0 To objArgs.Count - 1
		' Log arguments to screen.
		'Call subLogIt(objLogFile, "Script argument #" & intCounter & " = " & objArgs(intCounter) & ".", "screen")
		'Call subLogIt(objLogFile, "", "screen")
	'Next

	' Is there no argument?
	If objArgs.Count = 0 Then
		Call subLogIt(objLogFile, "Correct number of input parameters specified.", "screen")
		Call subLogIt(objLogFile, "", "screen")
	Else
		' More than 1 argument specified. This is not allowed.
		Call subLogIt(objLogFile, "Incorrect number of input parameters specified. Script will now quit.", "screen")
		Call subLogIt(objLogFile, "", "screen")
		' Display correct usage of command.
		Call subLogIt(objLogFile, strUsage, "screen")
		Call subLogIt(objLogFile, "", "screen")
		WScript.Quit(2)
	End If

End Sub

'******************************************************************************
Sub subLogIt(objLogTextFile, strLogText, strLogType)

	Dim strLogFileText

	Err.Clear
	If Lcase(strLogType) = "both" Or Lcase(strLogType) = "screen" Then
		StdOut.WriteLine(strLogText)
	End If 
	If Lcase(strLogType) = "both" Or Lcase(strLogType) = "logfile" Then
		strLogFileText = Now & "  " & strLogText
		objLogTextFile.WriteLine(strLogFileText)
	End If
	If Err.Number Then
		objLogTextFile.WriteLine ("- ERROR 0X" & CStr(Hex(Err.Number)) & " " & Err.Description & " -")
		Err.Clear
	End If

End Sub

'******************************************************************************
Function funEvalReturnCode(strCode)

	' Is returncode 0?
	If strCode = 0 Then
		' No errror encountered.
		funEvalReturnCode = True
		' Log success.
		Call subLogIt(objLogFile, "Operation succeeded.", "logfile")
	Else
		' Error encountered.
		funEvalReturnCode = False
		' Log failure.
		Call subLogIt(objLogFile, "Operation failed.", "logfile")
	End If
	Call subLogIt(objLogFile, "", "logfile")

End Function

'******************************************************************************
Sub subCheckDevcon()

	Call subLogIt(objLogFile, "Checking if devcon.exe is available...", "both")
	Call subLogIt(objLogFile, "", "both")

	If objFso.FileExists(strScriptPath & "devcon.exe") Then
		Call subLogIt(objLogFile, "Devcon found.", "both")
		Call subLogIt(objLogFile, "", "both")
	Else
		Call subLogIt(objLogFile, "Devcon.exe not found! Script will quit.", "both")
		WScript.Quit(3)
	End If

	Call subLogIt(objLogFile, "Checking if devcon64.exe is available...", "both")
	Call subLogIt(objLogFile, "", "both")

	If objFso.FileExists(strScriptPath & "devcon64.exe") Then
		Call subLogIt(objLogFile, "Devcon64.exe found.", "both")
		Call subLogIt(objLogFile, "", "both")
	Else
		Call subLogIt(objLogFile, "Devcon64.exe not found! Script will quit.", "both")
		WScript.Quit(4)
	End If

	Call subLogIt(objLogFile, "Done.", "both")
	Call subLogIt(objLogFile, "", "both")

End Sub

'******************************************************************************
Sub subRetrieveArchitecture()

	Call subLogIt(objLogFile, "Retrieving architecture...", "both")
	Call subLogIt(objLogFile, "", "both")

	Dim colItems, objItem

	Set colItems = objWmi.ExecQuery("Select * from Win32_Processor")

	For Each objItem In colItems
		strArchitecture = objItem.AddressWidth
	Next

	Call subLogIt(objLogFile, "Architecture is " & strArchitecture & " bit.", "both")
	Call subLogIt(objLogFile, "", "both")

	Set colItems = Nothing

End Sub

'******************************************************************************
Sub subDetermineCurrentDevices()

	Call subLogIt(objLogFile, "Enumerate present devices...", "both")
	Call subLogIt(objLogFile, "", "both")

	Dim strCmd
	Dim objExec
	Dim intCounter
	Dim strReply
	Dim arrTemp

	intCounter = 0

	Select Case strArchitecture
		Case "32"
			strDevcon = "devcon.exe"
		Case "64"
			strDevcon = "devcon64.exe"
		Case Else
			Call subLogIt(objLogFile, "Architecture is unknown! Script will quit.", "both")
			WScript.Quit(5)
	End Select

	strCmd = Chr(34) & strScriptPath & strDevcon & Chr(34) & " find *"
	Call subLogIt(objLogFile, strCmd, "logfile")
	Call subLogIt(objLogFile, "", "logfile")
	Set objExec = objWso.Exec(strCmd)
	Do While Not objExec.StdOut.AtEndOfStream
		strReply = objExec.StdOut.ReadLine
		intCounter = intCounter + 1
		Call subLogIt(objLogFile, "#" & intCounter & " strReply = " & strReply, "logfile")
		On Error GoTo 0
		If InStr(strReply, ":") > 0 Or InStr(strReply, "\") > 0 Then
			On Error Resume Next
			If UBound(arrCurrentDevicesHwid) = -1 Then
				ReDim Preserve arrCurrentDevicesHwid(0)
				ReDim Preserve arrCurrentDevicesName(0)
			Else
				ReDim Preserve arrCurrentDevicesHwid(UBound(arrCurrentDevicesHwid) + 1)
				ReDim Preserve arrCurrentDevicesName(UBound(arrCurrentDevicesName) + 1)
			End If
			On Error GoTo 0
			If InStr(strReply, ":") > 0 Then
				arrTemp = Split(strReply, ":", -1)
				arrCurrentDevicesHwid(UBound(arrCurrentDevicesHwid)) = Trim(arrTemp(0))
				arrCurrentDevicesName(UBound(arrCurrentDevicesName)) = Trim(arrTemp(1))
			Else
				arrCurrentDevicesHwid(UBound(arrCurrentDevicesHwid)) = Trim(strReply)
			End If
		End If
	Loop

	Set objExec = Nothing

	Call subLogIt(objLogFile, (UBound(arrCurrentDevicesHwid) + 1) & " present devices detected.", "both")
	Call subLogIt(objLogFile, "", "both")
	Call subLogIt(objLogFile, "Done.", "both")
	Call subLogIt(objLogFile, "", "both")

End Sub

'******************************************************************************
Sub subDetermineAllDevices()

	Call subLogIt(objLogFile, "Enumerate all devices (both present and non-present)...", "both")
	Call subLogIt(objLogFile, "", "both")

	Dim strCmd
	Dim objExec
	Dim intCounter
	Dim strReply
	Dim strReplyTemp
	Dim strName2
	Dim strHwid2
	Dim arrTemp

	intCounter = 0
	
	strCmd = Chr(34) & strScriptPath & strDevcon & Chr(34) & " findall *"
	Call subLogIt(objLogFile, strCmd, "logfile")
	Call subLogIt(objLogFile, "", "logfile")
	Set objExec = objWso.Exec(strCmd)
	Do While Not objExec.StdOut.AtEndOfStream
		strReply = objExec.StdOut.ReadLine
		intCounter = intCounter + 1
		Call subLogIt(objLogFile, "#" & intCounter & " strReply = " & strReply, "logfile")
		On Error GoTo 0
		If InStr(strReply, ":") > 0 Or InStr(strReply, "\") > 0 Then
			On Error Resume Next
			If UBound(arrAllDevicesHwid) = -1 Then
				ReDim Preserve arrAllDevicesHwid(0)
				ReDim Preserve arrAllDevicesName(0)
			Else
				ReDim Preserve arrAllDevicesHwid(UBound(arrAllDevicesHwid) + 1)
				ReDim Preserve arrAllDevicesName(UBound(arrAllDevicesName) + 1)
			End If
			On Error GoTo 0
			If InStr(strReply, ":") > 0 Then
				' Due to a bug in devcon.exe 2 devices can be on the same line.
				If InStr(Instr(strReply, ":") + 1, strReply, ":") > 0 Then
					strName2 = Trim(Right(strReply, Len(strReply) - InStrRev(strReply, ":")))
					strReplyTemp = Trim(Left(strReply, InStrRev(strReply, ":") - 1))
					strHwid2 = Right(strReplyTemp, Len(strReplyTemp) - InStrRev(strReplyTemp, " "))
					strReplyTemp = Trim(Left(strReplyTemp, InStrRev(strReplyTemp, " ")))
					arrTemp = Split(strReplyTemp, ":", -1)
					arrAllDevicesHwid(UBound(arrAllDevicesHwid)) = Trim(arrTemp(0))
					arrAllDevicesName(UBound(arrAllDevicesName)) = Trim(arrTemp(1))
					ReDim Preserve arrAllDevicesHwid(UBound(arrAllDevicesHwid) + 1)
					ReDim Preserve arrAllDevicesName(UBound(arrAllDevicesName) + 1)
					arrAllDevicesHwid(UBound(arrAllDevicesHwid)) = strHwid2
					arrAllDevicesName(UBound(arrAllDevicesName)) = strName2
				Else
					arrTemp = Split(strReply, ":", -1)
					arrAllDevicesHwid(UBound(arrAllDevicesHwid)) = Trim(arrTemp(0))
					arrAllDevicesName(UBound(arrAllDevicesName)) = Trim(arrTemp(1))
				End If
			Else
				arrAllDevicesHwid(UBound(arrAllDevicesHwid)) = Trim(strReply)
			End If
		End If
	Loop

	Set objExec = Nothing

	Call subLogIt(objLogFile, (UBound(arrAllDevicesHwid) + 1) & " present and non-present devices detected.", "both")
	Call subLogIt(objLogFile, "", "both")
	Call subLogIt(objLogFile, "Done.", "both")
	Call subLogIt(objLogFile, "", "both")

End Sub

'******************************************************************************
Sub subDeterminePotentialNonPresentDevices()

	Call subLogIt(objLogFile, "Determine potential non-present devices...", "both")
	Call subLogIt(objLogFile, "", "both")

	Dim intCounter
	Dim intCounter2
	Dim intCounter3
	Dim bolPresentDevice
	
	For intCounter = LBound(arrAllDevicesHwid) To UBound(arrAllDevicesHwid)
		bolPresentDevice = False
		For intCounter2 = LBound(arrCurrentDevicesHwid) To UBound(arrCurrentDevicesHwid)
			If Lcase(arrAllDevicesHwid(intCounter)) = Lcase(arrCurrentDevicesHwid(intCounter2)) Then
				bolPresentDevice = True
				Exit For
			End If
		Next
		If Not bolPresentDevice Then
			On Error Resume Next
			If UBound(arrPotentialNonPresentDevicesHwid) = -1 Then
				ReDim Preserve arrPotentialNonPresentDevicesHwid(0)
				ReDim Preserve arrPotentialNonPresentDevicesName(0)
			Else
				ReDim Preserve arrPotentialNonPresentDevicesHwid(UBound(arrPotentialNonPresentDevicesHwid) + 1)
				ReDim Preserve arrPotentialNonPresentDevicesName(UBound(arrPotentialNonPresentDevicesName) + 1)
			End If
			On Error GoTo 0
			arrPotentialNonPresentDevicesHwid(UBound(arrPotentialNonPresentDevicesHwid)) = arrAllDevicesHwid(intCounter)
			arrPotentialNonPresentDevicesName(UBound(arrPotentialNonPresentDevicesName)) = arrAllDevicesName(intCounter)
			Call subLogIt(objLogFile, arrAllDevicesName(intCounter) & " - " & arrAllDevicesHwid(intCounter), "logfile")
		End If	
	Next
	
	For intCounter = LBound(arrPotentialNonPresentDevicesHwid) To UBound(arrPotentialNonPresentDevicesHwid)
		Call subLogIt(objLogFile, arrPotentialNonPresentDevicesName(intCounter) & " - " & arrPotentialNonPresentDevicesHwid(intCounter), "logfile")
	Next	
	
	Call subLogIt(objLogFile, "", "logfile")
	Call subLogIt(objLogFile, (UBound(arrPotentialNonPresentDevicesHwid) + 1) & " potential non-present devices.", "both")
	Call subLogIt(objLogFile, "", "both")
	Call subLogIt(objLogFile, "Done.", "both")
	Call subLogIt(objLogFile, "", "both")

End Sub

'******************************************************************************
Sub subRemoveNonPresentDevices()

	Call subLogIt(objLogFile, "Removing non-present devices...", "both")
	Call subLogIt(objLogFile, "", "both")

	Dim intCounter
	Dim strCmd
	Dim objExec
	Dim strReply

	For intCounter = LBound(arrPotentialNonPresentDevicesHwid) To UBound(arrPotentialNonPresentDevicesHwid)
		strCmd = Chr(34) & strScriptPath & strDevcon & Chr(34) & " remove " & Chr(34) & "@" & arrPotentialNonPresentDevicesHwid(intCounter) & Chr(34)
		Call subLogIt(objLogFile, strCmd, "logfile")
		Call subLogIt(objLogFile, "Removing " & arrPotentialNonPresentDevicesName(intCounter) & ".", "screen")
		Set objExec = objWso.Exec(strCmd)
		Do While Not objExec.StdOut.AtEndOfStream
			strReply = objExec.StdOut.ReadLine
			Call subLogIt(objLogFile, strReply, "logfile")
		Loop
	Next
	Call subLogIt(objLogFile, "", "both")

	Set objExec = Nothing

	Call subLogIt(objLogFile, "Done.", "both")
	Call subLogIt(objLogFile, "", "both")

End Sub

'******************************************************************************
Sub subRescanDevices()

	Call subLogIt(objLogFile, "Rescanning devices...", "both")
	Call subLogIt(objLogFile, "", "both")

	Dim strCmd
	Dim objExec
	Dim strReply

	strCmd = Chr(34) & strScriptPath & strDevcon & Chr(34) & " rescan"
	Call subLogIt(objLogFile, strCmd, "logfile")
	Call subLogIt(objLogFile, "", "logfile")
	Set objExec = objWso.Exec(strCmd)
	Do While Not objExec.StdOut.AtEndOfStream
		strReply = objExec.StdOut.ReadLine
		Call subLogIt(objLogFile, strReply, "logfile")
	Loop
	Call subLogIt(objLogFile, "", "logfile")

	Set objExec = Nothing

	Call subLogIt(objLogFile, "Done.", "both")
	Call subLogIt(objLogFile, "", "both")

End Sub
