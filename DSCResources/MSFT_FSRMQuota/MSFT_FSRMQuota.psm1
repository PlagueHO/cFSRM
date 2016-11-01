Import-Module -Name (Join-Path `
    -Path (Split-Path -Path $PSScriptRoot -Parent) `
    -ChildPath 'CommonResourceHelper.psm1')
$LocalizedData = Get-LocalizedData -ResourceName 'MSFT_FSRMQuota'

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($LocalizedData.GettingQuotaMessage) `
            -f $Path
        ) -join '' )

    # Lookup the existing quota
    $Quota = Get-Quota -Path $Path

    $returnValue = @{
        Path = $Path
    }
    if ($Quota)
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.QuotaExistsMessage) `
                -f $Path
            ) -join '' )

        $returnValue += @{
            Ensure = 'Present'
            Description = $Quota.Description
            Size = $Quota.Size
            SoftLimit = $Quota.SoftLimit
            ThresholdPercentages = @($Quota.Threshold.Percentage)
            Disabled = $Quota.Disabled
            Template = $Quota.Template
            MatchesTemplate = $Quota.MatchesTemplate
        }
    }
    else
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.QuotaDoesNotExistMessage) `
                -f $Path
            ) -join '' )

        $returnValue += @{
            Ensure = 'Absent'
        }
    }

    $returnValue
} # Get-TargetResource

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Int64]
        $Size,

        [Parameter()]
        [System.Boolean]
        $SoftLimit,

        [Parameter()]
        [ValidateRange(0,100)]
        [System.Uint32[]]
        $ThresholdPercentages,

        [Parameter()]
        [System.Boolean]
        $Disabled,

        [Parameter()]
        [System.String]
        $Template,

        [Parameter()]
        [System.Boolean]
        $MatchesTemplate
    )

    # Remove any parameters that can't be splatted.
    $null = $PSBoundParameters.Remove('Ensure')
    $null = $PSBoundParameters.Remove('ThresholdPercentages')
    $null = $PSBoundParameters.Remove('MatchesTemplate')

    # Lookup the existing Quota
    $Quota = Get-Quota -Path $Path

    if ($Ensure -eq 'Present')
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.EnsureQuotaExistsMessage) `
                -f $Path
            ) -join '' )

        if (-not $MatchesTemplate)
        {
            # If the MatchesTemplate is not set Assemble the Threshold Percentages
            if ($Quota)
            {
                $Thresholds = [System.Collections.ArrayList]$Quota.Threshold
            }
            else
            {
                $Thresholds = [System.Collections.ArrayList]@()
            }

            # Scan through the required thresholds and add any that are misssing
            foreach ($ThresholdPercentage in $ThresholdPercentages)
            {
                If ($ThresholdPercentage -notin $Thresholds.Percentage)
                {
                    # The threshold percentage is missing so add it
                    $Thresholds += New-FSRMQuotaThreshold -Percentage $ThresholdPercentage

                    Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.QuotaThresholdAddedMessage) `
                            -f $Path,$ThresholdPercentage
                        ) -join '' )
                }
            }

            # Only remove thresholds that aren't passed IF a template isn't specified
            # because otherwise thresholds assigned by the template will get removed.
            if (-not $Quota.Template)
            {
                # Scan through the existing thresholds and remove any that are misssing
                for ($i = $Thresholds.Count-1; $i -ge 0; $i--)
                {
                    If ($Thresholds[$i].Percentage -notin $ThresholdPercentages)
                    {
                        # The threshold percentage exists but shouldn not so remove it
                        $Thresholds.Remove($i)

                        Write-Verbose -Message ( @(
                            "$($MyInvocation.MyCommand): "
                            $($LocalizedData.QuotaThresholdRemovedMessage) `
                                -f $Path,$Thresholds[$i].Percentage
                            ) -join '' )
                    }
                }
            }

            if ($Thresholds)
            {
                $PSBoundParameters.Add('Threshold',$Thresholds)
            }
        }

        if ($Quota)
        {
            # The Quota exists
            if ($MatchesTemplate -and ($Template -ne $Quota.Template))
            {
                # The template needs to be changed so the quota needs to be
                # Completely recreated.
                Remove-FSRMQuota `
                    -Path $Path `
                    -Confirm:$false `
                    -ErrorAction Stop
                New-FSRMQuota @PSBoundParameters `
                    -ErrorAction Stop

                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.QuotaRecreatedMessage) `
                        -f $Path
                    ) -join '' )
            }
            else
            {
                $PSBoundParameters.Remove('Template')
                Set-FSRMQuota @PSBoundParameters `
                    -ErrorAction Stop

                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.QuotaUpdatedMessage) `
                        -f $Path
                    ) -join '' )
            }
        }
        else
        {
            # Create the Quota
            New-FSRMQuota @PSBoundParameters `
                -ErrorAction Stop

            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.QuotaCreatedMessage) `
                    -f $Path
                ) -join '' )
        }
    }
    else
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.EnsureQuotaDoesNotExistMessage) `
                -f $Path
            ) -join '' )

        if ($Quota)
        {
            # The Quota shouldn't exist - remove it
            Remove-FSRMQuota -Path $Path -ErrorAction Stop

            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.QuotaRemovedMessage) `
                    -f $Path
                ) -join '' )
        } # if
    } # if
} # Set-TargetResource

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Int64]
        $Size,

        [Parameter()]
        [System.Boolean]
        $SoftLimit,

        [Parameter()]
        [ValidateRange(0,100)]
        [System.Uint32[]]
        $ThresholdPercentages,

        [Parameter()]
        [System.Boolean]
        $Disabled,

        [Parameter()]
        [System.String]
        $Template,

        [Parameter()]
        [System.Boolean]
        $MatchesTemplate
    )
    # Flag to signal whether settings are correct
    [Boolean] $desiredConfigurationMatch = $true

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($LocalizedData.TestingQuotaMessage) `
            -f $Path
        ) -join '' )

    # Check the properties are valid.
    Test-ResourceProperty @PSBoundParameters

    # Lookup the existing Quota
    $Quota = Get-Quota -Path $Path

    if ($Ensure -eq 'Present')
    {
        # The Quota should exist
        if ($Quota)
        {
            # The Quota exists already - check the parameters
            if ($MatchesTemplate)
            {
                # MatchesTemplate is set so only care if it matches template
                if (-not $Quota.MatchesTemplate)
                {
                    Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.QuotaDoesNotMatchTemplateNeedsUpdateMessage) `
                            -f $Path,'Description'
                        ) -join '' )
                    $desiredConfigurationMatch = $false
                }
            }
            else
            {
                if (($PSBoundParameters.ContainsKey('Size')) `
                    -and ($Quota.Size -ne $Size))
                {
                    Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.QuotaPropertyNeedsUpdateMessage) `
                            -f $Path,'Size'
                        ) -join '' )
                    $desiredConfigurationMatch = $false
                }

                if (($PSBoundParameters.ContainsKey('SoftLimit')) `
                    -and ($Quota.SoftLimit -ne $SoftLimit))
                {
                    Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.QuotaPropertyNeedsUpdateMessage) `
                            -f $Path,'SoftLimit'
                        ) -join '' )
                    $desiredConfigurationMatch = $false
                }

                # Check the threshold percentages
                if (($PSBoundParameters.ContainsKey('ThresholdPercentages')) `
                    -and (Compare-Object `
                    -ReferenceObject $ThresholdPercentages `
                    -DifferenceObject $Quota.Threshold.Percentage).Count -ne 0)
                {
                    Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.QuotaPropertyNeedsUpdateMessage) `
                            -f $Path,'ThresholdPercentages'
                        ) -join '' )
                    $desiredConfigurationMatch = $false
                }
            } # if ($MatchesTemplate)

            if (($PSBoundParameters.ContainsKey('Description')) `
                -and ($Quota.Description -ne $Description))
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.QuotaPropertyNeedsUpdateMessage) `
                        -f $Path,'Description'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            }

            if (($PSBoundParameters.ContainsKey('Disabled')) `
                -and ($Quota.Disabled -ne $Disabled))
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.QuotaPropertyNeedsUpdateMessage) `
                        -f $Path,'Disabled'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            }

            if (($PSBoundParameters.ContainsKey('Template')) `
                -and ($Quota.Template -ne $Template))
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.QuotaPropertyNeedsUpdateMessage) `
                        -f $Path,'Template'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            }
        }
        else
        {
            # Ths Quota doesn't exist but should
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                 $($LocalizedData.QuotaDoesNotExistButShouldMessage) `
                    -f  $Path
                ) -join '' )
            $desiredConfigurationMatch = $false
        }
    }
    else
    {
        # The Quota should not exist
        if ($Quota)
        {
            # The Quota exists but should not
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                 $($LocalizedData.QuotaExistsButShouldNotMessage) `
                    -f  $Path
                ) -join '' )
            $desiredConfigurationMatch = $false
        }
        else
        {
            # The Quota does not exist and should not
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                 $($LocalizedData.QuotaDoesNotExistAndShouldNotMessage) `
                    -f  $Path
                ) -join '' )
        }
    } # if
    return $desiredConfigurationMatch
} # Test-TargetResource

# Helper Functions

Function Get-Quota {
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )
    try
    {
        $Quota = Get-FSRMQuota -Path $Path -ErrorAction Stop
    }
    catch [Microsoft.Management.Infrastructure.CimException]
    {
        $Quota = $null
    }
    catch
    {
        Throw $_
    }
    Return $Quota
}

<#
.Synopsis
    This function validates the parameters passed. Called by Test-Resource.
    Will throw an error if any parameters are invalid.
#>
Function Test-ResourceProperty {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Int64]
        $Size,

        [Parameter()]
        [System.Boolean]
        $SoftLimit,

        [Parameter()]
        [ValidateRange(0,100)]
        [System.Uint32[]]
        $ThresholdPercentages,

        [Parameter()]
        [System.Boolean]
        $Disabled,

        [Parameter()]
        [System.String]
        $Template,

        [Parameter()]
        [System.Boolean]
        $MatchesTemplate
    )
    # Check the path exists
    if (-not (Test-Path -Path $Path))
    {
        $errorId = 'QuotaPathDoesNotExistError'
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
        $errorMessage = $($LocalizedData.QuotaPathDoesNotExistError) -f $Path
    }
    if ($Ensure -eq 'Absent')
    {
        # No further checks required if quota should be removed.
        return
    }
    if ($Template)
    {
        # Check the template exists
        try
        {
            $null = Get-FSRMQuotaTemplate -Name $Template -ErrorAction Stop
        }
        catch [Microsoft.PowerShell.Cmdletization.Cim.CimJobException]
        {
            $errorId = 'QuotaTemplateNotFoundError'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
            $errorMessage = $($LocalizedData.QuotaTemplateNotFoundError) -f $Path,$Template
        }
    }
    else
    {
        # A template wasn't specifed, ensure the matches template flag is false
        if ($MatchesTemplate)
        {
            $errorId = 'QuotaTemplateEmptyError'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
            $errorMessage = $($LocalizedData.QuotaTemplateEmptyError) -f $Path
        }
    }
    if ($errorId)
    {
        $exception = New-Object -TypeName System.InvalidOperationException `
            -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
            -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }
}

Export-ModuleMember -Function *-TargetResource
