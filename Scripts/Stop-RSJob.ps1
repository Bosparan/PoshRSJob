Function Stop-RSJob {
    [cmdletbinding(
        DefaultParameterSetName='Job'
    )]
    Param (
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True,
        ParameterSetName='Name')]
        [string[]]$Name,
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True,
        ParameterSetName='Id')]
        [int[]]$Id,
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True,
        ParameterSetName='Guid')]
        [guid[]]$InstanceID,
        [parameter(ValueFromPipeline=$True,ParameterSetName='Job')]
        [PoshRS.PowerShell.RSJob[]]$Job
    )
    Begin {        
        If ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }  
        Write-Debug "Begin"      
        $List = New-Object System.Collections.ArrayList
        $StringBuilder = New-Object System.Text.StringBuilder

        #Take care of bound parameters
        If ($PSBoundParameters['Name']) {
            [void]$list.AddRange($Name)
            $Bound = $True
        }
        If ($PSBoundParameters['Id']) {
            [void]$list.AddRange($Id)
            $Bound = $True
        }
        If ($PSBoundParameters['InstanceId']) {
            [void]$list.AddRange($InstanceId)
            $Bound = $True
        }
        If ($PSBoundParameters['Job']) {
            [void]$list.AddRange($Job)
            $Bound = $True
        }
        Write-Debug "Process"
    }
    Process {
        If (-Not $Bound) {
            [void]$List.Add($_)
        }
    }
    End {
        Write-Debug "End"
        Write-Debug "ParameterSet: $($PSCmdlet.parametersetname)"
        Switch ($PSCmdlet.parametersetname) {
            'Name' {
                $Items = '"{0}"' -f (($list | ForEach {"^{0}$" -f $_}) -join '|') -replace '\*','.*'
                [void]$StringBuilder.Append("`$_.Name -match $Items") 
                $ScriptBlock = [scriptblock]::Create($StringBuilder.ToString())                    
            }
            'Id' {
                $Items = '"{0}"' -f (($list | ForEach {"^{0}$" -f $_}) -join '|')
                [void]$StringBuilder.Append("`$_.Id -match $Items") 
                $ScriptBlock = [scriptblock]::Create($StringBuilder.ToString())                
            }
            'Guid' {
                $Items = '"{0}"' -f (($list | ForEach {"^{0}$" -f $_}) -join '|')
                [void]$StringBuilder.Append("`$_.InstanceId -match $Items")   
                $ScriptBlock = [scriptblock]::Create($StringBuilder.ToString())   
            }
            Default {$ScriptBlock=$Null}
        }
        If ($ScriptBlock) {
            Write-Verbose "Using ScriptBlock"
            $ToStop = $jobs | Where $ScriptBlock
        } Else {
            $ToStop = $List
        }
        [System.Threading.Monitor]::Enter($Jobs.syncroot) 
        $ToStop | ForEach {
            Write-Verbose "Stopping $($_.InstanceId)"
            [void]$_.InnerJob.Dispose()
        }
        [System.Threading.Monitor]::Exit($Jobs.syncroot) 
    }  
}
