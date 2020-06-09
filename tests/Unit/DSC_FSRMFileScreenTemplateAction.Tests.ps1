$script:dscModuleName = 'FSRMDsc'
$script:dscResourceName = 'DSC_FSRMFileScreenTemplateAction'

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
        # General purpose Action Mocks
        $script:MockEmail = New-CimInstance `
            -ClassName 'MSFT_FSRMAction' `
            -Namespace Root/Microsoft/Windows/FSRM `
            -ClientOnly `
            -Property @{
            Type    = 'Email'
            Subject = '[FileScreen Threshold]% FileScreen threshold exceeded'
            Body    = 'User [Source Io Owner] has exceed the [FileScreen Threshold]% FileScreen threshold for FileScreen on [FileScreen Path] on server [Server]. The FileScreen limit is [FileScreen Limit MB] MB and the current usage is [FileScreen Used MB] MB ([FileScreen Used Percent]% of limit).'
            MailBCC = ''
            MailCC  = 'fileserveradmins@contoso.com'
            MailTo  = '[Source Io Owner Email]'
        }

        $script:MockCommand = New-CimInstance `
            -ClassName 'MSFT_FSRMAction' `
            -Namespace Root/Microsoft/Windows/FSRM `
            -ClientOnly `
            -Property @{
            Type              = 'Command'
            Command           = 'c:\dothis.cmd'
            CommandParameters = ''
            KillTimeOut       = 60
            RunLimitInterval  = 3600
            SecurityLevel     = 'LocalSystem'
            ShouldLogError    = $true
            WorkingDirectory  = 'c:\'
        }

        $script:MockEvent = New-CimInstance `
            -ClassName 'MSFT_FSRMAction' `
            -Namespace Root/Microsoft/Windows/FSRM `
            -ClientOnly `
            -Property @{
            Type      = 'Event'
            Body      = 'User [Source Io Owner] has exceed the [FileScreen Threshold]% FileScreen threshold for FileScreen on [FileScreen Path] on server [Server]. The FileScreen limit is [FileScreen Limit MB] MB and the current usage is [FileScreen Used MB] MB ([FileScreen Used Percent]% of limit).'
            EventType = 'Warning'
        }

        $script:MockReport = New-CimInstance `
            -ClassName 'MSFT_FSRMAction' `
            -Namespace Root/Microsoft/Windows/FSRM `
            -ClientOnly `
            -Property @{
            Type        = 'Report'
            ReportTypes = @('DuplicateFiles', 'LargeFiles', 'FileScreenUsage')
        }

        # File Screen Template mocks
        $script:MockFileScreenTemplate = New-CimInstance `
            -ClassName 'MSFT_FSRMFileScreenTemplate' `
            -Namespace Root/Microsoft/Windows/FSRM `
            -ClientOnly `
            -Property @{
            Name         = 'Block Some Files'
            Description  = 'File Screen Templates for Blocking Some Files'
            Ensure       = 'Present'
            Active       = $true
            IncludeGroup = @( 'Audio and Video Files', 'Executable Files', 'Backup Files' )
            Notification = [Microsoft.Management.Infrastructure.CimInstance[]]@(
                $script:MockEmail, $script:MockCommand, $script:MockEvent
            )
        }

        $script:MockFileScreenTemplateReportOnly = New-CimInstance `
        -ClassName 'MSFT_FSRMFileScreenTemplate' `
        -Namespace Root/Microsoft/Windows/FSRM `
        -ClientOnly `
        -Property @{
        Name         = 'Block Some Files'
        Description  = 'File Screen Templates for Blocking Some Files'
        Ensure       = 'Present'
        Active       = $true
        IncludeGroup = @( 'Audio and Video Files', 'Executable Files', 'Backup Files' )
        Notification = [Microsoft.Management.Infrastructure.CimInstance[]]@(
            $script:MockReport
        )
    }

        $script:TestFileScreenTemplateActionEmail = [PSObject]@{
            Name    = $script:MockFileScreenTemplate.Name
            Type    = 'Email'
            Verbose = $true
        }

        $script:TestFileScreenTemplateActionSetEmail = $script:TestFileScreenTemplateActionEmail.Clone()
        $script:TestFileScreenTemplateActionSetEmail += [PSObject]@{
            Ensure  = 'Present'
            Subject = $script:MockEmail.Subject
            Body    = $script:MockEmail.Body
            MailBCC = $script:MockEmail.MailBCC
            MailCC  = $script:MockEmail.MailCC
            MailTo  = $script:MockEmail.MailTo
        }

        $script:TestFileScreenTemplateActionEvent = [PSObject]@{
            Name    = $script:MockFileScreenTemplate.Name
            Type    = 'Event'
            Verbose = $true
        }

        $script:TestFileScreenTemplateActionSetEvent = $script:TestFileScreenTemplateActionEvent.Clone()
        $script:TestFileScreenTemplateActionSetEvent += [PSObject]@{
            Ensure    = 'Present'
            Body      = $script:MockEvent.Body
            EventType = $script:MockEvent.EventType
        }

        $script:TestFileScreenTemplateActionCommand = [PSObject]@{
            Name    = $script:MockFileScreenTemplate.Name
            Type    = 'Command'
            Verbose = $true
        }

        $script:TestFileScreenTemplateActionSetCommand = $script:TestFileScreenTemplateActionCommand.Clone()
        $script:TestFileScreenTemplateActionSetCommand += [PSObject]@{
            Ensure            = 'Present'
            Command           = $script:MockCommand.Command
            CommandParameters = $script:MockCommand.CommandParameters
            KillTimeOut       = $script:MockCommand.KillTimeOut
            RunLimitInterval  = $script:MockCommand.RunLimitInterval
            SecurityLevel     = $script:MockCommand.SecurityLevel
            ShouldLogError    = $script:MockCommand.ShouldLogError
            WorkingDirectory  = $script:MockCommand.WorkingDirectory
        }

        $script:TestFileScreenTemplateActionReport = [PSObject]@{
            Name    = $script:MockFileScreenTemplate.Name
            Type    = 'Report'
            Verbose = $true
        }

        $script:TestFileScreenTemplateActionSetReport = $script:TestFileScreenTemplateActionReport.Clone()
        $script:TestFileScreenTemplateActionSetReport += [PSObject]@{
            Ensure      = 'Present'
            ReportTypes = $script:MockReport.ReportTypes
        }

        Describe 'DSC_FSRMFileScreenTemplateAction\Get-TargetResource' {
            Context 'File Screen template does not exist' {
                Mock -CommandName Get-FsrmFileScreenTemplate { throw (New-Object -TypeName Microsoft.PowerShell.Cmdletization.Cim.CimJobException) }

                It 'Should throw FileScreenTemplateNotFound exception' {
                    $getTargetResourceParameters = $script:TestFileScreenTemplateActionEmail.Clone()

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($($script:localizedData.FileScreenTemplateNotFoundError) -f $getTargetResourceParameters.Name, $getTargetResourceParameters.Type) `
                        -ArgumentName 'Name'

                    { $result = Get-TargetResource @getTargetResourceParameters } | Should -Throw $errorRecord
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                }
            }

            Context 'File Screen template exists but action does not' {
                Mock -CommandName Get-FsrmFileScreenTemplate -MockWith { return @($script:MockFileScreenTemplate) }

                It 'Should return absent File Screen template action' {
                    $getTargetResourceParameters = $script:TestFileScreenTemplateActionReport.Clone()
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                }
            }

            Context 'File Screen template and action exists' {
                Mock -CommandName Get-FsrmFileScreenTemplate -MockWith { return @($script:MockFileScreenTemplate) }

                It 'Should return correct File Screen template action' {
                    $getTargetResourceParameters = $script:TestFileScreenTemplateActionEmail.Clone()
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                    $result.Type | Should -Be 'Email'
                    $result.Subject | Should -Be $script:MockEmail.Subject
                    $result.Body | Should -Be $script:MockEmail.Body
                    $result.MailBCC | Should -Be $script:MockEmail.MailBCC
                    $result.MailCC | Should -Be $script:MockEmail.MailCC
                    $result.MailTo | Should -Be $script:MockEmail.MailTo
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                }
            }
        }

        Describe 'DSC_FSRMFileScreenTemplateAction\Set-TargetResource' {
            Context 'File Screen template does not exist' {
                Mock -CommandName Get-FsrmFileScreenTemplate -MockWith { throw (New-Object -TypeName Microsoft.PowerShell.Cmdletization.Cim.CimJobException) }
                Mock -CommandName Set-FsrmFileScreenTemplate

                It 'Should throw FileScreenTemplateNotFound exception' {
                    $setTargetResourceParameters = $script:TestFileScreenTemplateActionEmail.Clone()

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($($script:localizedData.FileScreenTemplateNotFoundError) -f $setTargetResourceParameters.Name, $setTargetResourceParameters.Type) `
                        -ArgumentName 'Name'

                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw $errorRecord
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                    Assert-MockCalled -CommandName Set-FsrmFileScreenTemplate -Exactly 0
                }
            }

            Context 'File Screen template exists but action does not' {
                Mock -CommandName Get-FsrmFileScreenTemplate -MockWith { return @($script:MockFileScreenTemplate) }
                Mock -CommandName Set-FsrmFileScreenTemplate

                It 'Should not throw exception' {
                    $setTargetResourceParameters = $script:TestFileScreenTemplateActionSetEvent.Clone()
                    $setTargetResourceParameters.Type = 'Event'
                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                    Assert-MockCalled -CommandName Set-FsrmFileScreenTemplate -Exactly 1
                }
            }

            Context 'File Screen template exists and action exists' {
                Mock -CommandName Get-FsrmFileScreenTemplate -MockWith { return @($script:MockFileScreenTemplate) }
                Mock -CommandName Set-FsrmFileScreenTemplate

                It 'Should not throw exception' {
                    $setTargetResourceParameters = $script:TestFileScreenTemplateActionSetEmail.Clone()
                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                    Assert-MockCalled -CommandName Set-FsrmFileScreenTemplate -Exactly 1
                }
            }

            Context 'File Screen template exists and action exists but should not' {
                Mock -CommandName Get-FsrmFileScreenTemplate -MockWith { return @($script:MockFileScreenTemplate) }
                Mock -CommandName Set-FsrmFileScreenTemplate

                It 'Should not throw exception' {
                    $setTargetResourceParameters = $script:TestFileScreenTemplateActionSetEmail.Clone()
                    $setTargetResourceParameters.Ensure = 'Absent'
                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                    Assert-MockCalled -CommandName Set-FsrmFileScreenTemplate -Exactly 1
                }
            }
        }

        Describe 'DSC_FSRMFileScreenTemplateAction\Test-TargetResource' {
            Context 'File Screen template does not exist' {
                Mock -CommandName Get-FsrmFileScreenTemplate -MockWith { throw (New-Object -TypeName Microsoft.PowerShell.Cmdletization.Cim.CimJobException) }

                It 'Should throw FileScreenTemplateNotFound exception' {
                    $testTargetResourceParameters = $script:TestFileScreenTemplateActionEmail.Clone()

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($($script:localizedData.FileScreenTemplateNotFoundError) -f $testTargetResourceParameters.Name, $testTargetResourceParameters.Type) `
                        -ArgumentName 'Name'

                    { Test-TargetResource @testTargetResourceParameters } | Should -Throw $errorRecord
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                }
            }

            Context 'File Screen template exists but action does not' {
                Mock -CommandName Get-FsrmFileScreenTemplate -MockWith { return @($script:MockFileScreenTemplate) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestFileScreenTemplateActionSetReport.Clone()
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                }
            }

            Context 'File Screen template exists and matching action exists' {
                Mock -CommandName Get-FsrmFileScreenTemplate -MockWith { return @($script:MockFileScreenTemplate) }

                It 'Should return true' {
                    $testTargetResourceParameters = $script:TestFileScreenTemplateActionSetEmail.Clone()
                    Test-TargetResource @testTargetResourceParameters | Should -Be $true
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                }
            }

            Context 'File Screen template exists and action with different Subject exists' {
                Mock -CommandName Get-FsrmFileScreenTemplate -MockWith { return @($script:MockFileScreenTemplate) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestFileScreenTemplateActionSetEmail.Clone()
                    $testTargetResourceParameters.Subject = 'Different'
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                }
            }

            Context 'File Screen template exists and action with different Body exists' {
                Mock -CommandName Get-FsrmFileScreenTemplate -MockWith { return @($script:MockFileScreenTemplate) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestFileScreenTemplateActionSetEmail.Clone()
                    $testTargetResourceParameters.Body = 'Different'
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                }
            }

            Context 'File Screen template exists and action with different Mail BCC exists' {
                Mock -CommandName Get-FsrmFileScreenTemplate -MockWith { return @($script:MockFileScreenTemplate) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestFileScreenTemplateActionSetEmail.Clone()
                    $testTargetResourceParameters.MailBCC = 'Different'
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                }
            }

            Context 'File Screen template exists and action with different Mail CC exists' {
                Mock -CommandName Get-FsrmFileScreenTemplate -MockWith { return @($script:MockFileScreenTemplate) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestFileScreenTemplateActionSetEmail.Clone()
                    $testTargetResourceParameters.MailCC = 'Different'
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                }
            }

            Context 'File Screen template exists and action with different Mail To exists' {
                Mock -CommandName Get-FsrmFileScreenTemplate -MockWith { return @($script:MockFileScreenTemplate) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestFileScreenTemplateActionSetEmail.Clone()
                    $testTargetResourceParameters.MailTo = 'Different'
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                }
            }

            Context 'File Screen template exists and action with different Command exists' {
                Mock -CommandName Get-FsrmFileScreenTemplate -MockWith { return @($script:MockFileScreenTemplate) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestFileScreenTemplateActionSetCommand.Clone()
                    $testTargetResourceParameters.Command = 'Different'
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                }
            }

            Context 'File Screen template exists and action with different CommandParameters exists' {
                Mock -CommandName Get-FsrmFileScreenTemplate -MockWith { return @($script:MockFileScreenTemplate) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestFileScreenTemplateActionSetCommand.Clone()
                    $testTargetResourceParameters.CommandParameters = 'Different'
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                }
            }

            Context 'File Screen template exists and action with different KillTimeOut exists' {
                Mock -CommandName Get-FsrmFileScreenTemplate -MockWith { return @($script:MockFileScreenTemplate) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestFileScreenTemplateActionSetCommand.Clone()
                    $testTargetResourceParameters.KillTimeOut = $testTargetResourceParameters.KillTimeOut + 1
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                }
            }

            Context 'File Screen template exists and action with different RunLimitInterval exists' {
                Mock -CommandName Get-FsrmFileScreenTemplate -MockWith { return @($script:MockFileScreenTemplate) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestFileScreenTemplateActionSetCommand.Clone()
                    $testTargetResourceParameters.RunLimitInterval = $testTargetResourceParameters.RunLimitInterval + 1
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                }
            }

            Context 'File Screen template exists and action with different SecurityLevel exists' {
                Mock -CommandName Get-FsrmFileScreenTemplate -MockWith { return @($script:MockFileScreenTemplate) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestFileScreenTemplateActionSetCommand.Clone()
                    $testTargetResourceParameters.SecurityLevel = 'NetworkService'
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                }
            }

            Context 'File Screen template exists and action with different ShouldLogError exists' {
                Mock -CommandName Get-FsrmFileScreenTemplate -MockWith { return @($script:MockFileScreenTemplate) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestFileScreenTemplateActionSetCommand.Clone()
                    $testTargetResourceParameters.ShouldLogError = (-not $testTargetResourceParameters.ShouldLogError)
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                }
            }

            Context 'File Screen template exists and action with different WorkingDirectory exists' {
                Mock -CommandName Get-FsrmFileScreenTemplate -MockWith { return @($script:MockFileScreenTemplate) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestFileScreenTemplateActionSetCommand.Clone()
                    $testTargetResourceParameters.WorkingDirectory = 'Different'
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                }
            }

            Context 'File Screen template exists and action with different ReportTypes exists' {

                Mock -CommandName Get-FsrmFileScreenTemplate -MockWith { return @($script:MockFileScreenTemplateReportOnly) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestFileScreenTemplateActionSetReport.Clone()
                    $testTargetResourceParameters.ReportTypes = @( 'LeastRecentlyAccessed' )
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                }
            }

            Context 'File Screen template exists and action exists but should not' {
                Mock -CommandName Get-FsrmFileScreenTemplate -MockWith { return @($script:MockFileScreenTemplate) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestFileScreenTemplateActionSetEmail.Clone()
                    $testTargetResourceParameters.Ensure = 'Absent'
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmFileScreenTemplate -Exactly 1
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
