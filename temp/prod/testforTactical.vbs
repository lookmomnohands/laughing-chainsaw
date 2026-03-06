' VBScript to check if a specific process is running using TaskList and write to a file

' Specify the name of the process to check (without the .exe extension)
Dim processName
processName = "tacticalrmm" ' Change this to the process you want to check

' Create a shell object to run the command
Dim objShell, command, tempFile, fso, outputFile, processFound
Set objShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' Create a temporary file to store the output
tempFile = fso.GetSpecialFolder(2) & "\tasklist_output.txt" ' 2 = Temporary folder

' Run the TaskList command and redirect output to the temporary file
command = "cmd /c tasklist > """ & tempFile & """"
objShell.Run command, 0, True ' Run the command silently and wait for it to finish

' Initialize the processFound flag
processFound = False

' Read the output from the temporary file
If fso.FileExists(tempFile) Then
    Set outputFile = fso.OpenTextFile(tempFile, 1) ' 1 = ForReading
    Do While Not outputFile.AtEndOfStream
        Dim line
        line = outputFile.ReadLine()
        
        ' Check if the line contains the process name
        If InStr(1, line, processName & ".exe", vbTextCompare) > 0 Then
            processFound = True
            Exit Do
        End If
    Loop
    outputFile.Close
End If

' Prepare the status for the output file
Dim status
If processFound Then
    status = "Yes"
Else
    status = "No"
End If

' Write the status to the specified file without a newline
Dim statusFile
statusFile = "C:\temp\prod\tactical_status.txt" ' Path to the output file
Set outputFile = fso.CreateTextFile(statusFile, True) ' Create or overwrite the file
outputFile.Write status ' Use Write instead of WriteLine
outputFile.Close

' Clean up
If fso.FileExists(tempFile) Then fso.DeleteFile tempFile ' Delete the temporary file
Set outputFile = Nothing
Set fso = Nothing
Set objShell = Nothing
