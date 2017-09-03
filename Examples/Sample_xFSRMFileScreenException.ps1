# This configuration add a File Screen Exception that Includes 'E-mail Files' to
# the path 'D:\Users'.
configuration Sample_FSRMFileScreenException
{
    Import-DscResource -Module FSRMDsc

    Node $NodeName
    {
        FSRMFileScreenException DUsersFileScreenException
        {
            Path = 'd:\users'
            Description = 'File Screen for Blocking Some Files'
            Ensure = 'Present'
            IncludeGroup = 'E-mail Files'
        } # End of FSRMFileScreenException Resource
    } # End of Node
} # End of Configuration
