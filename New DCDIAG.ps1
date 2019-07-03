function Get-DCDiagResults {
    [cmdletbinding()]
    param(
        # Parameter help description
        [Parameter()]
        $server = "LocalHost"

    )

    $dcdiag = (Dcdiag.exe /s:$Server) -split ('[\r\n]')

    $results = New-Object PSCustomObject
    $results | Add-Member -Type NoteProperty -Name "ServerName" -Value $Server

    foreach ($test in $dcdiag){
        Switch -RegEx ($test)
        {
            "Starting" {
                $testName = ($test -Replace ".*Starting test: ").Trim()
            }

            "passed test|failed test" {
                If ($test -Match "passed test"){
                    $TestStatus = "Passed"
                }
                Else{
                    $TestStatus = "Failed"
                }
            }
        }
        If ($null -ne $TestName -And $null -ne $TestStatus)
        {
            $Results | Add-Member -Name $("$TestName".Trim()) -Value $TestStatus -Type NoteProperty -force
            $TestName = $Null
            $TestStatus = $Null
        }
    }
    $AllDCDiags += $Results
    $AllDCDiags
}

function Get-RepAdminResults  {
    [cmdletbinding()]
    param(

        [Parameter()]
        $Server = "localhost"
    )
    $repadmin = @()
    $rep = (Invoke-Command $Server -ScriptBlock{repadmin /showrepl /repsto /csv | ConvertFrom-Csv})
    $serverOS = Get-WmiObject win32_operatingsystem -ComputerName $server


    ForEach($r in $rep) {
        # Adding properties to object
        $REPObject = New-Object PSCustomObject -Property @{
            Last_Success_Time = $r."last success time"
            Last_Failure_Status = $r."Last Failure Status"
            Last_Failure_Time = $r."last failure time"
            Number_of_failures = $r."number of failures"
        }
        if(($serverOS).caption -like "*2008*"){
            $REPObject | Add-Member -Name "Destination DSA Site" -MemberType NoteProperty -Value $r."Destination DSA Site"
            $REPObject | Add-Member -Name "Destination DSA" -MemberType NoteProperty -Value $r."Destination DSA"
            $REPObject | Add-Member -Name "Source DSA Site" -MemberType NoteProperty -Value $r."Source DSA Site"
            $REPObject | Add-Member -Name "Source DSA" -MemberType NoteProperty -Value $r."Source DSA"


        }else{
            $REPObject | Add-Member -Name "Destination DS Site" -MemberType NoteProperty -Value $r."Destination DS Site"
            $REPObject | Add-Member -Name "Destination DS" -MemberType NoteProperty -Value $r."Destination DS"
            $REPObject | Add-Member -Name "Source DS Site" -MemberType NoteProperty -Value $r."Source DS Site"
            $REPObject | Add-Member -Name "Source DS" -MemberType NoteProperty -Value $r."Source DS"
        }




        # Adding object to array
        $repadmin += $REPObject
        }



    $repadmin
}


<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE
    Another example of how to use this cmdlet
#>
function Get-ReplicationMethod {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        $server = "localhost"
    )
    $ntfrsService = Get-Service ntfrs -ComputerName $server
    $dfsService = Get-Service dfsr -ComputerName $server

    If(($ntfrsService).Status -eq "Running"){
        $replicationMethod = "ntfrs"
    }ElseIf(($dfsService).Status -eq "Running"){
        $replicationMethod = "dfsr"
    }else{
        Write-Error -Message "neither NtFrs or DFSR are running" -ErrorAction Stop
    }

    return $replicationMethod
}
<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE
    Another example of how to use this cmdlet
#>
function Get-DomainAlert {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipelineByPropertyName = $true
        )]
        [validateset("ntfrs", "dfs")]
        $replicationMethod
    )

    $Yesterday = (Get-Date) - (New-TimeSpan -Day 1)

    If($replicationMethod -eq "ntfrs"){
        $logName = "File Replication Service"
    }else{
        $logName = "DFS Replication"
    }
    $eventHash = @{
        LogName = $logName
        StartTime = $Yesterday

    }
    #search on hash table
    $events = Get-WinEvent -LogName $logName -ComputerName $computerName -FilterHashtable $eventHash
    $events

}

