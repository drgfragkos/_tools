Const Removable = 1
Const Fixed = 2
Const Network = 3
Const CDROM = 4
Const RAMDisk = 5

Set oFSO = CreateObject("Scripting.FileSystemObject")
Set drives = oFSO.Drives

NewLine=Chr(10)
Line = ""

For Each drive In drives
	Line = Line & "Drive " & drive.Path
	Line = Line & " " & ShowDriveType(Drive)
	If drive.IsReady Then Line = Line & ", ready" Else Line = Line & ", notready"

	If drive.IsReady Then
		If drive.DriveType=Network Then
			Line = Line & ", Label=" & drive.ShareName
		Else
			Line = Line & ", Label=" & drive.VolumeName
		End If

	Line = Line & ", FS=" & drive.FileSystem
	Line = Line & ", Total=" & Int(drive.TotalSize/1000000)
	Line = Line & ", Free=" & Int(drive.FreeSpace/1000000)
	Line = Line & ", Available=" & Int(drive.AvailableSpace/1000000)
	Line = Line & ", Serial=" & Hex(drive.SerialNumber)
	End If

	Line = Line & NewLine
Next

wscript.echo Line

Function ShowDriveType(Drive)
	Select Case drive.DriveType
		Case Removable
			T = "Removable"
		Case Fixed
			T = "Fixed"
		Case Network
			T = "Network"
		Case CDROM
			T = "CD-ROM"
		Case RAMDisk
			T = "RAM Disk"
		Case Else
			T = "Unknown"
	End Select
	ShowDriveType = T
End Function
