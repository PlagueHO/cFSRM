$script:dscModuleName = 'FSRMDsc'
$script:dscResourceName = 'DSC_FSRMFileScreen'

function Invoke-TestSetup
{
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
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

# Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        # Create the Mock -CommandName Objects that will be used for running tests
        $script:TestFileScreen = [PSObject]@{
            Path            = $ENV:Temp
            Description     = 'File Screen for Blocking Some Files'
            Ensure          = 'Present'
            Active          = $false
            IncludeGroup    = [System.Collections.ArrayList]@( 'Audio and Video Files', 'Executable Files', 'Backup Files' )
            Template        = 'Block Some Files'
            MatchesTemplate = $false
            Verbose         = $true
        }

        $script:MockFileScreen = [PSObject]@{
            Path            = $script:TestFileScreen.Path
            Description     = $script:TestFileScreen.Description
            Active          = $script:TestFileScreen.Active
            IncludeGroup    = $script:TestFileScreen.IncludeGroup.Clone()
            Template        = $script:TestFileScreen.Template
            MatchesTemplate = $script:TestFileScreen.MatchesTemplate
        }

        $script:MockFileScreenMatch = $script:MockFileScreen.Clone()
        $script:MockFileScreenMatch.MatchesTemplate = $true

        Describe 'DSC_FSRMFileScreen\Get-TargetResource' {
            Context 'No File Screens exist' {
                Mock -CommandName Get-FsrmFileScreen

                It 'Should return absent File Screen' {
                    $result = Get-TargetResource -Path $script:TestFileScreen.Path -Verbose
                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreen -Exactly 1
                }
            }

            Context 'Requested File Screen does exist' {
                Mock -CommandName Get-FsrmFileScreen -MockWith { return @($script:MockFileScreen) }

                It 'Should return correct File Screen' {
                    $result = Get-TargetResource -Path $script:TestFileScreen.Path -Verbose
                    $result.Ensure | Should -Be 'Present'
                    $result.Path | Should -Be $script:TestFileScreen.Path
                    $result.Description | Should -Be $script:TestFileScreen.Description
                    $result.IncludeGroup | Should -Be $script:TestFileScreen.IncludeGroup
                    $result.Active | Should -Be $script:TestFileScreen.Active
                    $result.Template | Should -Be $script:TestFileScreen.Template
                    $result.MatchesTemplate | Should -Be $script:TestFileScreen.MatchesTemplate
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreen -Exactly 1
                }
            }
        }

        Describe 'DSC_FSRMFileScreen\Set-TargetResource' {
            Context 'File Screen does not exist but should' {
                Mock -CommandName Assert-ResourcePropertiesValid
                Mock -CommandName Get-FsrmFileScreen
                Mock -CommandName New-FsrmFileScreen
                Mock -CommandName Set-FsrmFileScreen
                Mock -CommandName Remove-FsrmFileScreen

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $script:TestFileScreen.Clone()
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreen -Exactly 1
                    Assert-MockCalled -CommandName New-FsrmFileScreen -Exactly 1
                    Assert-MockCalled -CommandName Set-FsrmFileScreen -Exactly 0
                    Assert-MockCalled -CommandName Remove-FsrmFileScreen -Exactly 0
                }
            }

            Context 'File Screen exists and should but has a different Description' {
                Mock -CommandName Assert-ResourcePropertiesValid
                Mock -CommandName Get-FsrmFileScreen -MockWith { $script:MockFileScreen }
                Mock -CommandName New-FsrmFileScreen
                Mock -CommandName Set-FsrmFileScreen
                Mock -CommandName Remove-FsrmFileScreen

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $script:TestFileScreen.Clone()
                        $setTargetResourceParameters.Description = 'Different'
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreen -Exactly 1
                    Assert-MockCalled -CommandName New-FsrmFileScreen -Exactly 0
                    Assert-MockCalled -CommandName Set-FsrmFileScreen -Exactly 1
                    Assert-MockCalled -CommandName Remove-FsrmFileScreen -Exactly 0
                }
            }

            Context 'File Screen exists and should but has a different Active' {
                Mock -CommandName Assert-ResourcePropertiesValid
                Mock -CommandName Get-FsrmFileScreen -MockWith { $script:MockFileScreen }
                Mock -CommandName New-FsrmFileScreen
                Mock -CommandName Set-FsrmFileScreen
                Mock -CommandName Remove-FsrmFileScreen

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $script:TestFileScreen.Clone()
                        $setTargetResourceParameters.Active = (-not $setTargetResourceParameters.Active)
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreen -Exactly 1
                    Assert-MockCalled -CommandName New-FsrmFileScreen -Exactly 0
                    Assert-MockCalled -CommandName Set-FsrmFileScreen -Exactly 1
                    Assert-MockCalled -CommandName Remove-FsrmFileScreen -Exactly 0
                }
            }

            Context 'File Screen exists and should but has a different IncludeGroup' {
                Mock -CommandName Assert-ResourcePropertiesValid
                Mock -CommandName Get-FsrmFileScreen -MockWith { $script:MockFileScreen }
                Mock -CommandName New-FsrmFileScreen
                Mock -CommandName Set-FsrmFileScreen
                Mock -CommandName Remove-FsrmFileScreen

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $script:TestFileScreen.Clone()
                        $setTargetResourceParameters.IncludeGroup = @( 'Different' )
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreen -Exactly 1
                    Assert-MockCalled -CommandName New-FsrmFileScreen -Exactly 0
                    Assert-MockCalled -CommandName Set-FsrmFileScreen -Exactly 1
                    Assert-MockCalled -CommandName Remove-FsrmFileScreen -Exactly 0
                }
            }

            Context 'File Screen exists and but should not' {
                Mock -CommandName Assert-ResourcePropertiesValid
                Mock -CommandName Get-FsrmFileScreen -MockWith { $script:MockFileScreen }
                Mock -CommandName New-FsrmFileScreen
                Mock -CommandName Set-FsrmFileScreen
                Mock -CommandName Remove-FsrmFileScreen

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $script:TestFileScreen.Clone()
                        $setTargetResourceParameters.Ensure = 'Absent'
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreen -Exactly 1
                    Assert-MockCalled -CommandName New-FsrmFileScreen -Exactly 0
                    Assert-MockCalled -CommandName Set-FsrmFileScreen -Exactly 0
                    Assert-MockCalled -CommandName Remove-FsrmFileScreen -Exactly 1
                }
            }

            Context 'File Screen does not exist and should not' {
                Mock -CommandName Assert-ResourcePropertiesValid
                Mock -CommandName Get-FsrmFileScreen
                Mock -CommandName New-FsrmFileScreen
                Mock -CommandName Set-FsrmFileScreen
                Mock -CommandName Remove-FsrmFileScreen

                It 'Should not throw error' {
                    {
                        $setTargetResourceParameters = $script:TestFileScreen.Clone()
                        $setTargetResourceParameters.Ensure = 'Absent'
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreen -Exactly 1
                    Assert-MockCalled -CommandName New-FsrmFileScreen -Exactly 0
                    Assert-MockCalled -CommandName Set-FsrmFileScreen -Exactly 0
                    Assert-MockCalled -CommandName Remove-FsrmFileScreen -Exactly 0
                }
            }
        }

        Describe 'DSC_FSRMFileScreen\Test-TargetResource' {
            Context 'File Screen path does not exist' {
                Mock -CommandName Get-FsrmFileScreenTemplate
                Mock -CommandName Test-Path -MockWith { $false }

                It 'Should throw an FileScreenPathDoesNotExistError exception' {
                    $testTargetResourceParameters = $script:TestFileScreen.Clone()

                    $errorId = 'FileScreenPathDoesNotExistError'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $errorMessage = $($script:localizedData.FileScreenPathDoesNotExistError) -f $testTargetResourceParameters.Path
                    $exception = New-Object -TypeName System.InvalidOperationException `
                        -ArgumentList $errorMessage
                    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $exception, $errorId, $errorCategory, $null

                    { Test-TargetResource @testTargetResourceParameters } | Should -Throw $errorRecord
                }
            }

            Context 'FileScreen template does not exist' {
                Mock -CommandName Get-FSRMFileScreenTemplate -MockWith { throw (New-Object -TypeName Microsoft.PowerShell.Cmdletization.Cim.CimJobException) }

                It 'Should throw an FileScreenTemplateNotFoundError exception' {
                    $testTargetResourceParameters = $script:TestFileScreen.Clone()

                    $errorId = 'FileScreenTemplateNotFoundError'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $errorMessage = $($script:localizedData.FileScreenTemplateNotFoundError) -f $testTargetResourceParameters.Path, $testTargetResourceParameters.Template
                    $exception = New-Object -TypeName System.InvalidOperationException `
                        -ArgumentList $errorMessage
                    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $exception, $errorId, $errorCategory, $null

                    { Test-TargetResource @testTargetResourceParameters } | Should -Throw $errorRecord
                }
            }

            Context 'File Screen template not specified but MatchesTemplate is true' {
                It 'Should throw an FileScreenTemplateEmptyError exception' {
                    $testTargetResourceParameters = $script:TestFileScreen.Clone()
                    $testTargetResourceParameters.MatchesTemplate = $true
                    $testTargetResourceParameters.Template = ''

                    $errorId = 'FileScreenTemplateEmptyError'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $errorMessage = $($script:localizedData.FileScreenTemplateEmptyError) -f $testTargetResourceParameters.Path
                    $exception = New-Object -TypeName System.InvalidOperationException `
                        -ArgumentList $errorMessage
                    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $exception, $errorId, $errorCategory, $null

                    { Test-TargetResource @testTargetResourceParameters } | Should -Throw $errorRecord
                }
            }

            Context 'File Screen does not exist but should' {
                Mock -CommandName Get-FsrmFileScreen
                Mock -CommandName Get-FsrmFileScreenTemplate

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestFileScreen.Clone()
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false

                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreen -Exactly 1
                }
            }

            Context 'File Screen exists and should but has a different Description' {
                Mock -CommandName Get-FsrmFileScreen -MockWith { $script:MockFileScreen }
                Mock -CommandName Get-FsrmFileScreenTemplate

                It 'Should return false' {
                    {
                        $testTargetResourceParameters = $script:TestFileScreen.Clone()
                        $testTargetResourceParameters.Description = 'Different'
                        Test-TargetResource @testTargetResourceParameters | Should -Be $false
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreen -Exactly 1
                }
            }

            Context 'File Screen exists and should but has a different Active' {
                Mock -CommandName Get-FsrmFileScreen -MockWith { $script:MockFileScreen }
                Mock -CommandName Get-FsrmFileScreenTemplate

                It 'Should return false' {
                    {
                        $testTargetResourceParameters = $script:TestFileScreen.Clone()
                        $testTargetResourceParameters.Active = (-not $testTargetResourceParameters.Active)
                        Test-TargetResource @testTargetResourceParameters | Should -Be $false
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreen -Exactly 1
                }
            }

            Context 'File Screen exists and should but has a different IncludeGroup' {
                Mock -CommandName Get-FsrmFileScreen -MockWith { $script:MockFileScreen }
                Mock -CommandName Get-FsrmFileScreenTemplate

                It 'Should return false' {
                    {
                        $testTargetResourceParameters = $script:TestFileScreen.Clone()
                        $testTargetResourceParameters.IncludeGroup = @( 'Different' )
                        Test-TargetResource @testTargetResourceParameters | Should -Be $false
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreen -Exactly 1
                }
            }

            Context 'File Screen exists and should but has a different Template' {
                Mock -CommandName Get-FsrmFileScreen -MockWith { $script:MockFileScreen }
                Mock -CommandName Get-FsrmFileScreenTemplate

                It 'Should return false' {
                    {
                        $testTargetResourceParameters = $script:TestFileScreen.Clone()
                        $testTargetResourceParameters.Template = 'Block Image Files'
                        Test-TargetResource @testTargetResourceParameters | Should -Be $false
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreen -Exactly 1
                }
            }

            Context 'File Screen exists and should and MatchesTemplate is set but does not match' {
                Mock -CommandName Get-FsrmFileScreen -MockWith { $script:MockFileScreen }
                Mock -CommandName Get-FsrmFileScreenTemplate

                It 'Should return false' {
                    {
                        $testTargetResourceParameters = $script:TestFileScreen.Clone()
                        $testTargetResourceParameters.MatchesTemplate = $true
                        Test-TargetResource @testTargetResourceParameters | Should -Be $false
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreen -Exactly 1
                }
            }

            Context 'File Screen exists and should and MatchesTemplate is set and does match' {
                Mock -CommandName Get-FsrmFileScreen -MockWith { $script:MockFileScreenMatch }
                Mock -CommandName Get-FsrmFileScreenTemplate

                It 'Should return true' {
                    {
                        $testTargetResourceParameters = $script:TestFileScreen.Clone()
                        $testTargetResourceParameters.MatchesTemplate = $true
                        Test-TargetResource @testTargetResourceParameters | Should -Be $true
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreen -Exactly 1
                }
            }

            Context 'File Screen exists and should and all parameters match' {
                Mock -CommandName Get-FsrmFileScreen -MockWith { $script:MockFileScreen }
                Mock -CommandName Get-FsrmFileScreenTemplate

                It 'Should return true' {
                    {
                        $testTargetResourceParameters = $script:TestFileScreen.Clone()
                        Test-TargetResource @testTargetResourceParameters | Should -Be $true
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreen -Exactly 1
                }
            }

            Context 'File Screen exists and but should not' {
                Mock -CommandName Get-FsrmFileScreen -MockWith { $script:MockFileScreen }
                Mock -CommandName Get-FsrmFileScreenTemplate

                It 'Should return false' {
                    {
                        $testTargetResourceParameters = $script:TestFileScreen.Clone()
                        $testTargetResourceParameters.Ensure = 'Absent'
                        Test-TargetResource @testTargetResourceParameters | Should -Be $false
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreen -Exactly 1
                }
            }

            Context 'File Screen does not exist and should not' {
                Mock -CommandName Get-FsrmFileScreen
                Mock -CommandName Get-FsrmFileScreenTemplate

                It 'Should return true' {
                    {
                        $testTargetResourceParameters = $script:TestFileScreen.Clone()
                        $testTargetResourceParameters.Ensure = 'Absent'
                        Test-TargetResource @testTargetResourceParameters | Should -Be $true
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreen -Exactly 1
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
