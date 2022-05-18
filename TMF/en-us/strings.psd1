# This is where the strings go, that are written by
# Write-PSFMessage, Stop-PSFFunction or the PSFramework validation scriptblocks
@{
    'TMF.ConfigurationFileNotFound' = 'Can not find configuration file {0}.'
    'TMF.RegisterComponent.AlreadyLoaded' = 'A {0} with name "{1}" from source configuration {2} has already been loaded. Ignoring {0}.'
    'TMF.PrerequisiteNotActivated' = '[{0}] Configuration "{1}" is not activated. Please activate related configurations before this configuration. It is also possible to activate them in a single command.'
    'TMF.TenantInformation' = 'Currently connected to <c="red">{0}</c> (<c="gray">{1}</c>)'
    'TMF.StartingTestForResource' = 'Starting tests for <c="yellow">{0}</c>'
    'TMF.StartingInvokeForResource' = 'Invoking <c="yellow">{0}</c>'
    'TMF.TestResult.BeautifySimple' = '[Tenant: <c="gray">{0}</c>][{2} Resource: <c="gray">{1}</c>] Required Action (<c="{4}">{3}</c>)'
    'TMF.TestResult.BeautifyPropertyChange' = ' > [<c="gray">{1}</c>][Property: <c="green">(</c><c="gray">{3}</c><c="green">)</c>] Action: (<c="yellow">{4}</c>) Value: (<c="gray">{5}</c>)'    
    'TMF.NoDefinitions' = 'No <c="gray">{0}</c> definitions are loaded. There is nothing to do.'
    'TMF.CannotResolveResource' = 'Cannot resolve {0} resource. Searched in the current tenant and in the loaded desired configuration.'
    'TMF.UserCanceled' = 'User canceled the operation.'
    'TMF.Error.QueryWithFilterFailed' = 'Query with filter {0} failed.'

    'TMF.Register.PropertySetNotPossible' = 'The provided property set for "{0}" (Type: {1}) is not applicable.'
    'TMF.Register.PropertyWrongType' = 'The provided property set for "{0}" (Type: {1}) is not applicable. The child property {2} has the wrong type. Must be {3} and is {4}.'

    'TMF.Test.RelatedResourceDoesNotExist' = 'The related {0} {0} for the {0} {1} does not exist at the moment. Cannot test {0}.'
    'TMF.Test.MultipleResourcesError' = 'There are multiple {0} with displayName {1} already created. Please clean your Tenant.'
    'TMF.Test.MissingPolicyRuleTemplate' = 'Referenced policy rule template {1} for {0} not found.'

    'TMF.Invoke.ActionTypeUnknown' = 'Action type (<c="yellow">{0}</c>) is unknown!'
    'TMF.Invoke.ActionFailed' = '[Tenant: <c="gray">{0}</c>][{1} Resource: <c="gray">{2}</c>] Action ({3}) failed! Stopping actions.'
    'TMF.Invoke.SendingRequestWithBody' = '[{0} {1}] Sending request with body {2}'
    'TMF.Invoke.SendingRequest' = '[{0} {1}] Sending request'
    'TMF.Invoke.ActionCompleted' = '[Tenant: <c="gray">{0}</c>][{1} Resource: <c="gray">{2}</c>] <c="green">Completed</c>.'

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
    'Deactivate-TMFConfiguration.DeactivatingAll' = 'Deactivating all configurations. No configuration will be considered when applying Tenant configuration.'

    'Load-TmfConfiguration.NotSupportedComponent' = 'Component {0} from configuration {1} is currently not supported and will be ignored.'    

    'Test-GraphConnection.Failed' = 'You are not connected to any Microsoft Tenant! Use Connect-MgGraph before testing or invoking settings.'
    'Test-AzureConnection.Failed' = 'You are not connected with a Microsoft Tenant for Azure Resource Management! Use Connect-AzAccount before testing or invoking settings.'
}