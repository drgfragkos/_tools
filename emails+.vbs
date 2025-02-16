'*****************************************************************************
' Description:
'   This VBScript extracts all unique email addresses from a given text file.
'
' Usage:
'   cscript //nologo emails+.vbs [-v] <InputFile>
'
' Examples:
'   cscript //nologo emails+.vbs sample.txt
'   cscript //nologo emails+.vbs -v sample.txt
'
' Note:
'   This script is designed to work with both cscript.exe and wscript.exe.
'   However, for a console-based experience and silent operation by default,
'   it is recommended to use cscript.exe.
'
'   The default behavior is silent execution. When the -v flag is specified,
'   verbose output is displayed.
'
' Author:
'   (c) @drgfragkos 2024
'
'*****************************************************************************

Option Explicit

Dim objArgs, fso, strFile, verbose
Set objArgs = WScript.Arguments

' Parse command-line arguments:
' Look for a "-v" flag for verbose output and the input file argument.
verbose = False
strFile = ""
Dim i, arg
For i = 0 To objArgs.Count - 1
    arg = Trim(objArgs(i))
    If LCase(arg) = "-v" Then
        verbose = True
    Else
        strFile = arg
    End If
Next

ErrCheck strFile = "", 1, "No input file specified. Please provide the file path."

Set fso = CreateObject("Scripting.FileSystemObject")
ErrCheck Not fso.FileExists(strFile), 1, "File not found: '" & strFile & "'"

Dim regEx, dictEmails
Set regEx = New RegExp
' Enhanced regular expression pattern:
'   - [A-Za-z0-9._%+-]+ : Matches the local part of the email.
'   - @                : Literal '@' symbol.
'   - [A-Za-z0-9.-]+   : Matches the domain.
'   - \.[A-Za-z]{2,}   : Matches the dot and top-level domain.
regEx.Pattern = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"
regEx.IgnoreCase = True
regEx.Global = True

' Dictionary to store unique email addresses
Set dictEmails = CreateObject("Scripting.Dictionary")

' Read the file line by line (more memory efficient than reading the whole file)
Dim inputFile, sLine, colMatches, sMatch
Set inputFile = fso.OpenTextFile(strFile, 1)

If verbose Then
    WScript.Echo "Processing file: " & strFile
End If

Do Until inputFile.AtEndOfStream
    sLine = inputFile.ReadLine
    Set colMatches = regEx.Execute(sLine)
    If colMatches.Count > 0 Then
        For Each sMatch In colMatches
            If Not dictEmails.Exists(sMatch.Value) Then
                dictEmails.Add sMatch.Value, sMatch.Value
            End If
        Next
    End If
Loop
inputFile.Close

' Write results to an output file if any email addresses were found.
If dictEmails.Count > 0 Then
    Dim dateStamp, outFileName, outFile, key, outputText
    ' Format the current date as YYYY-MM-DD
    dateStamp = Year(Date()) & "-" & Right("0" & Month(Date()), 2) & "-" & Right("0" & Day(Date()), 2)
    outFileName = dateStamp & "_" & fso.GetFileName(strFile)
    
    outputText = ""
    For Each key In dictEmails.Keys
        outputText = outputText & key & vbCrLf
    Next

    ' Open output file in append mode (creates new file if it doesn't exist)
    Set outFile = fso.OpenTextFile(outFileName, 8, True)
    outFile.WriteLine outputText
    outFile.Close

    If verbose Then
        WScript.Echo "Unique email addresses found: " & dictEmails.Count
        WScript.Echo "Results written to: " & outFileName
    End If
Else
    If verbose Then
        WScript.Echo "-- None Found --"
    End If
End If

' Clean up
Set regEx = Nothing
Set dictEmails = Nothing
Set fso = Nothing

'----------------------------------------------------------------------
' Subroutine: ErrCheck
' Description:
'   Checks for an error condition and, if met, displays an error message and
'   exits the script with the provided error code.
'
' Parameters:
'   blTest - Boolean test condition. If True, an error is raised.
'   iErrNum - The error number to exit with.
'   sTxt - The error message to display.
'----------------------------------------------------------------------
Sub ErrCheck(blTest, iErrNum, sTxt)
    If Not blTest Then Exit Sub
    Dim sErrText
    sErrText = "Error: " & sTxt
    MsgBox sErrText, vbSystemModal + vbCritical, "Error in: " & WScript.ScriptName
    WScript.Quit iErrNum
End Sub
