$script:DSCModuleName = 'FSRMDsc'
$script:DSCResourceName = 'DSR_FSRMClassificationProperty'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
[System.String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $script:DSCResourceName {
        $script:DSCResourceName = 'DSR_FSRMClassificationProperty'

        # Create the Mock -CommandName Objects that will be used for running tests
        $script:MockClassificationPossibleValue1 = New-CimInstance `
            -ClassName 'MSFT_FSRMClassificationPropertyDefinitionValue' `
            -Namespace Root/Microsoft/Windows/FSRM `
            -ClientOnly `
            -Property @{
            Name        = 'Top Secret'
            Description = ''
        }

        $script:MockClassificationPossibleValue2 = New-CimInstance `
            -ClassName 'MSFT_FSRMClassificationPropertyDefinitionValue' `
            -Namespace Root/Microsoft/Windows/FSRM `
            -ClientOnly `
            -Property @{
            Name        = 'Secret'
            Description = ''
        }

        $script:MockClassificationPossibleValue3 = New-CimInstance `
            -ClassName 'MSFT_FSRMClassificationPropertyDefinitionValue' `
            -Namespace Root/Microsoft/Windows/FSRM `
            -ClientOnly `
            -Property @{
            Name        = 'Confidential'
            Description = ''
        }

        $script:ClassificationProperty = [PSObject]@{
            Name          = 'Privacy'
            DisplayName   = 'File Privacy'
            Type          = 'SingleChoice'
            Ensure        = 'Present'
            Description   = 'File Privacy Property'
            PossibleValue = @( $script:MockClassificationPossibleValue1.Name, $script:MockClassificationPossibleValue2.Name, $script:MockClassificationPossibleValue3.Name )
            Parameters    = @( 'Parameter1=Value1', 'Parameter2=Value2')
            Verbose       = $true
        }

        $script:MockClassificationProperty = New-CimInstance `
            -ClassName 'MSFT_FSRMClassificationPropertyDefinitionDefinition' `
            -Namespace Root/Microsoft/Windows/FSRM `
            -ClientOnly `
            -Property @{
            Name          = $script:ClassificationProperty.Name
            DisplayName   = $script:ClassificationProperty.DisplayName
            Type          = $script:ClassificationProperty.Type
            Description   = $script:ClassificationProperty.Description
            Parameters    = $script:ClassificationProperty.Parameters
            PossibleValue = [Microsoft.Management.Infrastructure.CimInstance[]]@( $script:MockClassificationPossibleValue1, $script:MockClassificationPossibleValue2, $script:MockClassificationPossibleValue3 )
        }

        Describe "$($script:DSCResourceName)\Get-TargetResource" {
            Context 'No classification properties exist' {
                Mock -CommandName Get-FSRMClassificationPropertyDefinition

                It 'Should return absent classification property' {
                    $result = Get-TargetResource -Name $script:ClassificationProperty.Name -Type $script:ClassificationProperty.Type -Verbose
                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FSRMClassificationPropertyDefinition -Exactly 1
                }
            }

            Context 'Requested classification property does exist' {
                Mock -CommandName Get-FSRMClassificationPropertyDefinition -MockWith { $script:MockClassificationProperty }

                It 'Should return correct classification property' {
                    $result = Get-TargetResource -Name $script:ClassificationProperty.Name -Type $script:ClassificationProperty.Type -Verbose
                    $result.Ensure | Should -Be 'Present'
                    $result.Name | Should -Be $script:ClassificationProperty.Name
                    $result.DisplayName | Should -Be $script:ClassificationProperty.DisplayName
                    $result.Description | Should -Be $script:ClassificationProperty.Description
                    $result.Type | Should -Be $script:ClassificationProperty.Type
                    $result.PossibleValue | Should -Be $script:ClassificationProperty.PossibleValue
                    $result.Parameters | Should -Be $script:ClassificationProperty.Parameters
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FSRMClassificationPropertyDefinition -Exactly 1
                }
            }
        }

        Describe "$($script:DSCResourceName)\Set-TargetResource" {
            Context 'classification property does not exist but should' {
                Mock -CommandName Get-FSRMClassificationPropertyDefinition
                Mock -CommandName New-FSRMClassificationPropertyDefinition
                Mock -CommandName Set-FSRMClassificationPropertyDefinition
                Mock -CommandName Remove-FSRMClassificationPropertyDefinition

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $script:ClassificationProperty.Clone()
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FSRMClassificationPropertyDefinition -Exactly 1
                    Assert-MockCalled -CommandName New-FSRMClassificationPropertyDefinition -Exactly 1
                    Assert-MockCalled -CommandName Set-FSRMClassificationPropertyDefinition -Exactly 0
                    Assert-MockCalled -CommandName Remove-FSRMClassificationPropertyDefinition -Exactly 0
                }
            }

            Context 'classification property exists and should but has a different DisplayName' {
                Mock -CommandName Get-FSRMClassificationPropertyDefinition -MockWith { $script:MockClassificationProperty }
                Mock -CommandName New-FSRMClassificationPropertyDefinition
                Mock -CommandName Set-FSRMClassificationPropertyDefinition
                Mock -CommandName Remove-FSRMClassificationPropertyDefinition

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $script:ClassificationProperty.Clone()
                        $setTargetResourceParameters.DisplayName = 'Different'
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FSRMClassificationPropertyDefinition -Exactly 1
                    Assert-MockCalled -CommandName New-FSRMClassificationPropertyDefinition -Exactly 0
                    Assert-MockCalled -CommandName Set-FSRMClassificationPropertyDefinition -Exactly 1
                    Assert-MockCalled -CommandName Remove-FSRMClassificationPropertyDefinition -Exactly 0
                }
            }

            Context 'classification property exists and should but has a different Description' {
                Mock -CommandName Get-FSRMClassificationPropertyDefinition -MockWith { $script:MockClassificationProperty }
                Mock -CommandName New-FSRMClassificationPropertyDefinition
                Mock -CommandName Set-FSRMClassificationPropertyDefinition
                Mock -CommandName Remove-FSRMClassificationPropertyDefinition

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $script:ClassificationProperty.Clone()
                        $setTargetResourceParameters.Description = 'Different'
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FSRMClassificationPropertyDefinition -Exactly 1
                    Assert-MockCalled -CommandName New-FSRMClassificationPropertyDefinition -Exactly 0
                    Assert-MockCalled -CommandName Set-FSRMClassificationPropertyDefinition -Exactly 1
                    Assert-MockCalled -CommandName Remove-FSRMClassificationPropertyDefinition -Exactly 0
                }
            }

            Context 'classification property exists and should but has a different Type' {
                Mock -CommandName Get-FSRMClassificationPropertyDefinition -MockWith { $script:MockClassificationProperty }
                Mock -CommandName New-FSRMClassificationPropertyDefinition
                Mock -CommandName Set-FSRMClassificationPropertyDefinition
                Mock -CommandName Remove-FSRMClassificationPropertyDefinition

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $script:ClassificationProperty.Clone()
                        $setTargetResourceParameters.Type = 'YesNo'
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FSRMClassificationPropertyDefinition -Exactly 1
                    Assert-MockCalled -CommandName New-FSRMClassificationPropertyDefinition -Exactly 1
                    Assert-MockCalled -CommandName Set-FSRMClassificationPropertyDefinition -Exactly 0
                    Assert-MockCalled -CommandName Remove-FSRMClassificationPropertyDefinition -Exactly 1
                }
            }

            Context 'classification property exists and should but has a different PossibleValue' {
                Mock -CommandName Get-FSRMClassificationPropertyDefinition -MockWith { $script:MockClassificationProperty }
                Mock -CommandName New-FSRMClassificationPropertyDefinition
                Mock -CommandName Set-FSRMClassificationPropertyDefinition
                Mock -CommandName Remove-FSRMClassificationPropertyDefinition

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $script:ClassificationProperty.Clone()
                        $setTargetResourceParameters.PossibleValue = @( $script:MockClassificationPossibleValue1.Name, $script:MockClassificationPossibleValue2.Name )
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FSRMClassificationPropertyDefinition -Exactly 1
                    Assert-MockCalled -CommandName New-FSRMClassificationPropertyDefinition -Exactly 0
                    Assert-MockCalled -CommandName Set-FSRMClassificationPropertyDefinition -Exactly 1
                    Assert-MockCalled -CommandName Remove-FSRMClassificationPropertyDefinition -Exactly 0
                }
            }

            Context 'classification property exists and should but has a different Parameters' {
                Mock -CommandName Get-FSRMClassificationPropertyDefinition -MockWith { $script:MockClassificationProperty }
                Mock -CommandName New-FSRMClassificationPropertyDefinition
                Mock -CommandName Set-FSRMClassificationPropertyDefinition
                Mock -CommandName Remove-FSRMClassificationPropertyDefinition

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $script:ClassificationProperty.Clone()
                        $setTargetResourceParameters.Parameters = @( 'Parameter1=Value3', 'Parameter2=Value4')
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FSRMClassificationPropertyDefinition -Exactly 1
                    Assert-MockCalled -CommandName New-FSRMClassificationPropertyDefinition -Exactly 0
                    Assert-MockCalled -CommandName Set-FSRMClassificationPropertyDefinition -Exactly 1
                    Assert-MockCalled -CommandName Remove-FSRMClassificationPropertyDefinition -Exactly 0
                }
            }

            Context 'classification property exists and but should not' {
                Mock -CommandName Get-FSRMClassificationPropertyDefinition -MockWith { $script:MockClassificationProperty }
                Mock -CommandName New-FSRMClassificationPropertyDefinition
                Mock -CommandName Set-FSRMClassificationPropertyDefinition
                Mock -CommandName Remove-FSRMClassificationPropertyDefinition

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $script:ClassificationProperty.Clone()
                        $setTargetResourceParameters.Ensure = 'Absent'
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FSRMClassificationPropertyDefinition -Exactly 1
                    Assert-MockCalled -CommandName New-FSRMClassificationPropertyDefinition -Exactly 0
                    Assert-MockCalled -CommandName Set-FSRMClassificationPropertyDefinition -Exactly 0
                    Assert-MockCalled -CommandName Remove-FSRMClassificationPropertyDefinition -Exactly 1
                }
            }

            Context 'classification property does not exist and should not' {
                Mock -CommandName Get-FSRMClassificationPropertyDefinition
                Mock -CommandName New-FSRMClassificationPropertyDefinition
                Mock -CommandName Set-FSRMClassificationPropertyDefinition
                Mock -CommandName Remove-FSRMClassificationPropertyDefinition

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $script:ClassificationProperty.Clone()
                        $setTargetResourceParameters.Ensure = 'Absent'
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FSRMClassificationPropertyDefinition -Exactly 1
                    Assert-MockCalled -CommandName New-FSRMClassificationPropertyDefinition -Exactly 0
                    Assert-MockCalled -CommandName Set-FSRMClassificationPropertyDefinition -Exactly 0
                    Assert-MockCalled -CommandName Remove-FSRMClassificationPropertyDefinition -Exactly 0
                }
            }
        }

        Describe "$($script:DSCResourceName)\Test-TargetResource" {
            Context 'classification property does not exist but should' {
                Mock -CommandName Get-FSRMClassificationPropertyDefinition

                It 'Should return false' {
                    $testTargetResourceParameters = $script:ClassificationProperty.Clone()
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false

                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FSRMClassificationPropertyDefinition -Exactly 1
                }
            }

            Context 'classification property exists and should but has a different DisplayName' {
                Mock -CommandName Get-FSRMClassificationPropertyDefinition -MockWith { $script:MockClassificationProperty }

                It 'Should return false' {
                    {
                        $testTargetResourceParameters = $script:ClassificationProperty.Clone()
                        $testTargetResourceParameters.DisplayName = 'Different'
                        Test-TargetResource @testTargetResourceParameters | Should -Be $false
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FSRMClassificationPropertyDefinition -Exactly 1
                }
            }

            Context 'classification property exists and should but has a different Description' {
                Mock -CommandName Get-FSRMClassificationPropertyDefinition -MockWith { $script:MockClassificationProperty }

                It 'Should return false' {
                    {
                        $testTargetResourceParameters = $script:ClassificationProperty.Clone()
                        $testTargetResourceParameters.Description = 'Different'
                        Test-TargetResource @testTargetResourceParameters | Should -Be $false
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FSRMClassificationPropertyDefinition -Exactly 1
                }
            }

            Context 'classification property exists and should but has a different Type' {
                Mock -CommandName Get-FSRMClassificationPropertyDefinition -MockWith { $script:MockClassificationProperty }

                It 'Should return false' {
                    {
                        $testTargetResourceParameters = $script:ClassificationProperty.Clone()
                        $testTargetResourceParameters.Type = 'YesNo'
                        Test-TargetResource @testTargetResourceParameters | Should -Be $false
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FSRMClassificationPropertyDefinition -Exactly 1
                }
            }

            Context 'classification property exists and should but has a different PossibleValue' {
                Mock -CommandName Get-FSRMClassificationPropertyDefinition -MockWith { $script:MockClassificationProperty }

                It 'Should return false' {
                    {
                        $testTargetResourceParameters = $script:ClassificationProperty.Clone()
                        $testTargetResourceParameters.PossibleValue = @( $script:MockClassificationPossibleValue1.Name, $script:MockClassificationPossibleValue2.Name )
                        Test-TargetResource @testTargetResourceParameters | Should -Be $false
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FSRMClassificationPropertyDefinition -Exactly 1
                }
            }

            Context 'classification property exists and should but has a different Parameters' {
                Mock -CommandName Get-FSRMClassificationPropertyDefinition -MockWith { $script:MockClassificationProperty }

                It 'Should return false' {
                    {
                        $testTargetResourceParameters = $script:ClassificationProperty.Clone()
                        $testTargetResourceParameters.Parameters = @( 'Parameter1=Value3', 'Parameter2=Value4')
                        Test-TargetResource @testTargetResourceParameters | Should -Be $false
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FSRMClassificationPropertyDefinition -Exactly 1
                }
            }

            Context 'classification property exists and should and all parameters match' {
                Mock -CommandName Get-FSRMClassificationPropertyDefinition -MockWith { $script:MockClassificationProperty }

                It 'Should return true' {
                    {
                        $testTargetResourceParameters = $script:ClassificationProperty.Clone()
                        Test-TargetResource @testTargetResourceParameters | Should -Be $true
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FSRMClassificationPropertyDefinition -Exactly 1
                }
            }

            Context 'classification property exists and but should not' {
                Mock -CommandName Get-FSRMClassificationPropertyDefinition -MockWith { $script:MockClassificationProperty }

                It 'Should return false' {
                    {
                        $testTargetResourceParameters = $script:ClassificationProperty.Clone()
                        $testTargetResourceParameters.Ensure = 'Absent'
                        Test-TargetResource @testTargetResourceParameters | Should -Be $false
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FSRMClassificationPropertyDefinition -Exactly 1
                }
            }

            Context 'classification property does not exist and should not' {
                Mock -CommandName Get-FSRMClassificationPropertyDefinition

                It 'Should return true' {
                    {
                        $testTargetResourceParameters = $script:ClassificationProperty.Clone()
                        $testTargetResourceParameters.Ensure = 'Absent'
                        Test-TargetResource @testTargetResourceParameters | Should -Be $true
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FSRMClassificationPropertyDefinition -Exactly 1
                }
            }
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
