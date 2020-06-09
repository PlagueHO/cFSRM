$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

# Import Localization Strings
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Retrieves the FSRM Classification Property with the specified Name and Type.

    .PARAMETER Name
        The name of the FSRM Classification Property.

    .PARAMETER Type
        The type of the FSRM Classification Property.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('OrderedList', 'MultiChoice', 'SingleChoice', 'String', 'MultiString', 'Integer', 'YesNo', 'DateTime')]
        [System.String]
        $Type
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.GettingClassificationPropertyMessage) `
                -f $Name
        ) -join '' )

    $classificationProperty = Get-ClassificationProperty -Name $Name

    $returnValue = @{
        Name = $Name
    }
    if ($classificationProperty)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.ClassificationPropertyExistsMessage) `
                    -f $Name
            ) -join '' )

        $returnValue += @{
            Ensure        = 'Present'
            DisplayName   = $classificationProperty.DisplayName
            Description   = $classificationProperty.Description
            Type          = $classificationProperty.Type
            PossibleValue = $classificationProperty.PossibleValue.Name
            Parameters    = $classificationProperty.Parameters
        }
    }
    else
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.ClassificationPropertyDoesNotExistMessage) `
                    -f $Name
            ) -join '' )

        $returnValue += @{
            Ensure = 'Absent'
        }
    }

    $returnValue
} # Get-TargetResource

<#
    .SYNOPSIS
        Sets the FSRM Classification Property with the specified Name and Type.

    .PARAMETER Name
        The name of the FSRM Classification Property.

    .PARAMETER Type
        The type of the FSRM Classification Property.

    .PARAMETER DisplayName
        The display name for the FSRM Classification Property.

    .PARAMETER Description
        The description for the FSRM Classification Property.

    .PARAMETER Ensure
        Specifies whether the FSRM Classification Property should exist.

    .PARAMETER PossibleValue
        An array of possible values that this FSRM Classification Property can take on.

    .PARAMETER Parameters
        An array of parameters in the format <name>=<value> that can be used by the File
        Classification Infrastructure.
#>
function Set-TargetResource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('OrderedList', 'MultiChoice', 'SingleChoice', 'String', 'MultiString', 'Integer', 'YesNo', 'DateTime')]
        [System.String]
        $Type,

        [Parameter()]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.String[]]
        $PossibleValue,

        [Parameter()]
        [System.String[]]
        $Parameters
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.SettingClassificationPropertyMessage) `
                -f $Name
        ) -join '' )

    # Remove any parameters that can't be splatted.
    $null = $PSBoundParameters.Remove('Ensure')

    # Lookup the existing Classification Property
    $classificationProperty = Get-ClassificationProperty -Name $Name

    if ($Ensure -eq 'Present')
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.EnsureClassificationPropertyExistsMessage) `
                    -f $Name
            ) -join '' )

        # Assemble an ArrayList of DSC_FSRMClassificationPropertyDefinitionValue if
        # the PossibleValue parameter was passed
        $newPossibleValue = @()
        if ($PSBoundParameters.ContainsKey('PossibleValue'))
        {
            foreach ($value in $PossibleValue)
            {
                $newPossibleValue += @(New-FSRMClassificationPropertyValue -Name $value)
            }
        }
        $null = $PSBoundParameters.Remove('PossibleValue')

        if ($classificationProperty)
        {
            # The Classification Property exists

            # Copy the descriptions from any existing Possible Value items into the
            # Descriptions of any of the matching Possible Values that were passed
            foreach ($newValue in $newPossibleValue)
            {
                foreach ($value in $classificationProperty.PossibleValue)
                {
                    if ($null -eq $newValue.Name)
                    {
                        # PossibleValue already exists - copy the description
                        $newValue.Description = $value.Description
                    }
                }
            }

            # Do we need to assign any PossibleValues?
            if ($newPossibleValue.Count -gt 0)
            {
                $null = $PSBoundParameters.Add('PossibleValue', $newPossibleValue)
            }

            # Is the type specified and different?
            if ($PSBoundParameters.ContainsKey('Type') `
                    -and ($Type -ne $classificationProperty.Type))
            {
                # The type is different so the Classification Property needs to be removed
                # and re-created.
                Remove-FSRMClassificationPropertyDefinition -Name $Name -ErrorAction Stop
                New-FSRMClassificationPropertyDefinition @PSBoundParameters -ErrorAction Stop

                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.ClassificationPropertyRecreatedMessage) `
                            -f $Name
                    ) -join '' )
            }
            else
            {
                $null = $PSBoundParameters.Remove('Type')
                Set-FSRMClassificationPropertyDefinition @PSBoundParameters -ErrorAction Stop
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.ClassificationPropertyUpdatedMessage) `
                            -f $Name
                    ) -join '' )
            }
        }
        else
        {
            # Do we need to assign any PossibleValues?
            if ($newPossibleValue.Count -gt 0)
            {
                $null = $PSBoundParameters.Add('PossibleValue', $newPossibleValue)
            }

            # Create the Classification Property
            New-FSRMClassificationPropertyDefinition @PSBoundParameters -ErrorAction Stop

            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.ClassificationPropertyCreatedMessage) `
                        -f $Name
                ) -join '' )
        }
    }
    else
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.EnsureClassificationPropertyDoesNotExistMessage) `
                    -f $Name
            ) -join '' )

        if ($classificationProperty)
        {
            # The Classification Property shouldn't exist - remove it
            Remove-FSRMClassificationPropertyDefinition -Name $Name -ErrorAction Stop

            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.ClassificationPropertyRemovedMessage) `
                        -f $Name
                ) -join '' )
        } # if
    } # if
} # Set-TargetResource

<#
    .SYNOPSIS
        Tests the FSRM Classification Property with the specified Name and Type.

    .PARAMETER Name
        The name of the FSRM Classification Property.

    .PARAMETER Type
        The type of the FSRM Classification Property.

    .PARAMETER DisplayName
        The display name for the FSRM Classification Property.

    .PARAMETER Description
        The description for the FSRM Classification Property.

    .PARAMETER Ensure
        Specifies whether the FSRM Classification Property should exist.

    .PARAMETER PossibleValue
        An array of possible values that this FSRM Classification Property can take on.

    .PARAMETER Parameters
        An array of parameters in the format <name>=<value> that can be used by the File
        Classification Infrastructure.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('OrderedList', 'MultiChoice', 'SingleChoice', 'String', 'MultiString', 'Integer', 'YesNo', 'DateTime')]
        [System.String]
        $Type,

        [Parameter()]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.String[]]
        $PossibleValue,

        [Parameter()]
        [System.String[]]
        $Parameters
    )
    # Flag to signal whether settings are correct
    $desiredConfigurationMatch = $true

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.TestingClassificationPropertyMessage) `
                -f $Name
        ) -join '' )

    # Lookup the existing Classification Property
    $classificationProperty = Get-ClassificationProperty -Name $Name

    if ($Ensure -eq 'Present')
    {
        # The Classification Property should exist
        if ($classificationProperty)
        {
            # The Classification Property exists already - check the parameters
            if (($Description) -and ($classificationProperty.Description -ne $Description))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.ClassificationPropertyNeedsUpdateMessage) `
                            -f $Name, 'Description'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            }

            if (($DisplayName) -and ($classificationProperty.DisplayName -ne $DisplayName))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.ClassificationPropertyNeedsUpdateMessage) `
                            -f $Name, 'DisplayName'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            }

            if (($Type) -and ($classificationProperty.Type -ne $Type))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.ClassificationPropertyNeedsUpdateMessage) `
                            -f $Name, 'Type'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            }

            # Logic: If Parameters is provided and is different to existing parameters.
            $existingParameters = @()
            if ($classificationProperty.Parameters)
            {
                $existingParameters = $classificationProperty.Parameters
            }

            if (($Parameters) `
                    -and (Compare-Object `
                        -ReferenceObject $Parameters `
                        -DifferenceObject $existingParameters).Count -ne 0)
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.ClassificationPropertyNeedsUpdateMessage) `
                            -f $Name, 'Parameters'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            }

            if (($PossibleValue) `
                    -and (Compare-Object `
                        -ReferenceObject $PossibleValue `
                        -DifferenceObject $classificationProperty.PossibleValue.Name).Count -ne 0)
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.ClassificationPropertyNeedsUpdateMessage) `
                            -f $Name, 'PossibleValue'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            }

        }
        else
        {
            # Ths Classification Property doesn't exist but should
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.ClassificationPropertyDoesNotExistButShouldMessage) `
                        -f $Name
                ) -join '' )
            $desiredConfigurationMatch = $false
        }
    }
    else
    {
        # The Classification Property should not exist
        if ($classificationProperty)
        {
            # The Classification Property exists but should not
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.ClassificationPropertyExistsButShouldNotMessage) `
                        -f $Name
                ) -join '' )
            $desiredConfigurationMatch = $false
        }
        else
        {
            # The Classification Property does not exist and should not
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.ClassificationPropertyDoesNotExistAndShouldNotMessage) `
                        -f $Name
                ) -join '' )
        }
    } # if
    return $desiredConfigurationMatch
} # Test-TargetResource

<#
    .SYNOPSIS
        Gets the FSRM Classification Property Object with the specified Name.

    .PARAMETER Name
        The name of the FSRM Classification Property.
#>
function Get-ClassificationProperty
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )
    try
    {
        $classificationProperty = Get-FSRMClassificationPropertyDefinition `
            -Name $Name `
            -ErrorAction Stop
    }
    catch [Microsoft.PowerShell.Cmdletization.Cim.CimJobException]
    {
        $classificationProperty = $null
    }
    catch
    {
        throw $_
    }

    return $classificationProperty
}

Export-ModuleMember -Function *-TargetResource
