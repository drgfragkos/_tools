'*****************************************************************************
' Description:
'   This VBScript extracts all unique email addresses from a given text file.
'
' Usage:
'   cscript //nologo emails.vbs <InputFile>
'
' Examples:
'   cscript //nologo emails.vbs sample.txt
'
' Note:
'   This script is designed to work with both cscript.exe and wscript.exe.
'   However, for a console-based experience and silent operation by default,
'   it is recommended to use cscript.exe.
'
' Author:
'   (c) @drgfragkos 2012
'
'*****************************************************************************

Option Explicit

Dim objArgs, fso, strFile, strTestString
Dim strPattern, strAllMatches

Set objArgs = WScript.Arguments

ErrCheck objArgs.Count < 1, 1, "No argument specified."

strFile = objArgs(0)

Set fso = CreateObject("Scripting.FileSystemObject")
ErrCheck Not fso.FileExists(strFile), 1, "File supplied as argument cannot be found: '" & strFile & "'"

'# WScript.Echo "Checking file contents for email addresses: '" & strFile & "'" & vbCrlf

strPattern = "([\w-\.]+)@[\w-]{2,}(\.[\w-]{2,}){1,5}"

strTestString = fso.OpenTextFile(strFile, 1).ReadAll

strAllMatches = fGetMatches(strPattern, strTestString)

If strAllMatches <> "" Then
    'WScript.Echo strAllMatches
    dim Stuff, dateStamp, WriteStuff
    dateStamp = Date()
    Stuff = strAllMatches
    Set WriteStuff = fso.OpenTextFile(dateStamp & "_" & strFile,8,True)
    WriteStuff.WriteLine(Stuff)
    WriteStuff.Close
    SET WriteStuff = NOTHING
    SET fso = NOTHING
Else
    WScript.Echo "-- None Found --"
End If

'# WScript.Echo vbCrlf & "End of " & WScript.ScriptName

Function fGetMatches(sPattern, sStr)
    Dim regEx, retVal, sMatch, colMatches, temp
    Set regEx = New RegExp     ' Create a regular expression.
    regEx.Pattern = sPattern   ' Set pattern.
    regEx.IgnoreCase = True   ' Set case insensitivity.
    regEx.Global = True        ' Set global applicability.

    Set colMatches = regEx.Execute(sStr)   ' Execute search.

    If colMatches.Count = 0 Then
        temp = ""
    Else
        For Each sMatch In colMatches
            temp = temp & sMatch & "¶"
        Next
        temp = Left(temp, Len(temp) - 1)
        temp = Replace(temp, "¶", vbCrlf)
    End If
    fGetMatches = temp
End Function

Sub ErrCheck(blTest, iErrNum, sTxt)
    Dim sErrText
    If Not blTest Then Exit Sub
    sErrText = "Error: " & sTxt
    MsgBox sErrText, vbSystemModal + vbCritical, "Error in: " & WScript.ScriptName
    WScript.Quit iErrNum
End Sub
                                              