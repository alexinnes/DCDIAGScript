function get-DCDiagResults {
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
            $TestName = $Null; $TestStatus = $Null
        }
    }
    $AllDCDiags += $Results
    $AllDCDiags
}

function get-RepAdminResults  {
    [cmdletbinding()]
    param(

        [Parameter()]
        $Server = "localhost"
    )
    $repadmin = @()
    $rep = (Invoke-Command $Server -ScriptBlock{repadmin /showrepl /repsto /csv | ConvertFrom-Csv})
    
    If((Get-WmiObject win32_operatingsystem).caption -like "*Server 2012*"){

        ForEach($r in $rep) {
        # Adding properties to object
        $REPObject = New-Object PSCustomObject -Property @{
            Destination_DC = $r."destination dc"
            Source_DC = $r."source dc"
            Source_DC_Site = $r."Source DC Site"
            Last_Success_Time = $r."last success time"
            Last_Failure_Status = $r."Last Failure Status"
            Last_Failure_Time = $r."last failure time"
            Number_of_failures = $r."number of failures"

        }

        # Adding object to array
        $repadmin += $REPObject

        }
    }else{
        ForEach($r in $rep) {
            # Adding properties to object
            $REPObject = New-Object PSCustomObject -Property @{
                Destination_DC = $r."destination dsa"
                Source_DC = $r."source dsa"
                Source_DC_Site = $r."Source Dsa Site"
                Last_Success_Time = $r."last success time"
                Last_Failure_Status = $r."Last Failure Status"
                Last_Failure_Time = $r."last failure time"
                Number_of_failures = $r."number of failures"

            }

            # Adding object to array
            $repadmin += $REPObject

            }
    }

    $repadmin
}


