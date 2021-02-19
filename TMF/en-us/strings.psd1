# This is where the strings go, that are written by
# Write-PSFMessage, Stop-PSFFunction or the PSFramework validation scriptblocks
@{
    'New-TMFConfiguration.OutPath.PathDoesNotExist' = 'The path {0} does not exist. You can use -Force to create the configuration anyway!'
    'New-TMFConfiguration.OutPath.AlreadyExists' = 'There is already a Tenant configuration in the target directory ({0}). You can use -Force to create the configuration anyway!'
    'New-TMFConfiguration.OutPath.CreatingDirectory' = 'Creating configuration directory {0}'
    'New-TMFConfiguration.OutPath.CreatingStructure' = 'Copying template structure {0}'
    'New-TMFConfiguration.AutoActivate' = 'Activating configuration {0}'
    'Activate-TMFConfiguration.PathDoesNotExist' = 'Can not find configuration {0}'
    'Activate-TMFConfiguration.AlreadyActivated' = 'Configuration {0} ({1}) is already activated! Use -Force to overwrite.'
}