# This is where the strings go, that are written by
# Write-PSFMessage, Stop-PSFFunction or the PSFramework validation scriptblocks
@{
    'TMF.ConfigurationFileNotFound' = 'Can not find configuration file {0}.'

    'New-TMFConfiguration.OutPath.PathDoesNotExist' = 'The path {0} does not exist. You can use -Force to create the configuration anyway!'
    'New-TMFConfiguration.OutPath.AlreadyExists' = 'There is already a Tenant configuration in the target directory ({0}). You can use -Force to create the configuration anyway!'
    'New-TMFConfiguration.OutPath.CreatingDirectory' = 'Creating configuration directory {0}.'
    'New-TMFConfiguration.OutPath.CreatingStructure' = 'Copying template structure to {0}.'        
    
    'Activate-TMFConfiguration.AlreadyActivated' = 'Configuration {0} ({1}) is already activated! Use -Force to overwrite.'
    'Activate-TMFConfiguration.RemovingAlreadyLoaded' = 'Unloading already activated configuration {0} ({1}).'
    'Activate-TMFConfiguration.Activating' = 'Activating {0} ({1}). This configuration will be considered when applying Tenant configuration.'
    'Activate-TMFConfiguration.Sort' = 'Sorting all activated configurations by weight.'

    'Deactivate-TMFConfiguration.NotActivated' = 'Configuration {0} is not activated.'
    'Deactivate-TMFConfiguration.Deactivating' = 'Deactivating {0}. This configuration will not be considered when applying Tenant configuration.'
}