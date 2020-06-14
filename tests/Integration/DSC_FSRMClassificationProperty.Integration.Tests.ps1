$script:dscModuleName = 'FSRMDsc'
$script:dscResourceName = 'DSC_FSRMClassificationProperty'

try
{
    Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
}
catch [System.IO.FileNotFoundException]
{
    throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
}

$script:testEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType 'Integration'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

try
{
    Describe "$($script:DSCResourceName) Integration Tests" {
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).Config.ps1"
        . $configFile

        Describe "$($script:dscResourceName)_Integration" {
            $configData = @{
                AllNodes = @(
                    @{
                        NodeName      = 'localhost'
                        Name          = 'IntegrationTest'
                        DisplayName   = 'Integration Test'
                        Type          = 'SingleChoice'
                        Ensure        = 'Present'
                        Description   = 'Integration Test Property'
                        PossibleValue = @( 'Value1', 'Value2', 'Value3' )
                        Parameters    = @( 'Parameter1=Value1', 'Parameter2=Value2')
                    }
                )
            }

            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData

                    $startDscConfigurationParameters = @{
                        Path         = $TestDrive
                        ComputerName = 'localhost'
                        Wait         = $true
                        Verbose      = $true
                        Force        = $true
                        ErrorAction  = 'Stop'
                    }

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {
                    Get-DscConfiguration -Verbose -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                }
                $current.Name | Should -BeExactly $configData.AllNodes[0].Name
                $current.DisplayName | Should -BeExactly $configData.AllNodes[0].DisplayName
                $current.Type | Should -BeExactly $configData.AllNodes[0].Type
                $current.Description | Should -BeExactly $configData.AllNodes[0].Description
                (Compare-Object `
                        -ReferenceObject $current.PossibleValue `
                        -DifferenceObject $configData.AllNodes[0].PossibleValue).Count | Should -Be 0
                (Compare-Object `
                        -ReferenceObject $current.Parameters `
                        -DifferenceObject $configData.AllNodes[0].Parameters).Count | Should -Be 0
            }

            # Clean up
            Remove-FSRMClassificationPropertyDefinition `
                -Name $configData.AllNodes[0].Name `
                -Confirm:$false
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
