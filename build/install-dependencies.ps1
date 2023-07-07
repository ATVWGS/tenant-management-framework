Param (
    [string] $SystemAccessToken,
    [string] $FeedName,
    [string] $FeedUrl,
    [switch] $UsePrivatePackageFeed
)

begin {
    $buildAndTestDeps = @(
        @{ ModuleName = "PSFramework"; ModuleVersion = "1.5.171" },
        "Microsoft.Graph.Authentication",
        "Microsoft.Graph.Identity.DirectoryManagement",
        "Microsoft.Graph.Identity.Governance",
        @{ ModuleName = "Pester"; ModuleVersion = "5.3.1" }
    )

    if ($PSBoundParameters.ContainsKey("UsePrivatePackageFeed")) {
        #region Register own package feed
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $feedToken = $SystemAccessToken | ConvertTo-SecureString -AsPlainText -Force
        $feedCredential = New-Object System.Management.Automation.PSCredential($SystemAccessToken, $feedToken)
        Register-PackageSource -Name $FeedName -ProviderName PowerShellGet -Location $FeedUrl -Trusted -Credential $feedCredential
        #endregion
    }
    else { $FeedName = "PSGallery" }    
}
process {
    #region Install dependencies
    foreach ($module in $buildAndTestDeps) {
        switch ($module.GetType().Name) {
            "String" { 
                $installParameters = @{
                    Name = $module
                    Scope = "CurrentUser"                    
                    Repository = $FeedName
                    Force = $true
                    SkipPublisherCheck = $true
                }
            }
            "Hashtable" { 
                $installParameters = @{
                    Name = $module["ModuleName"]
                    RequiredVersion = $module["RequiredVersion"]
                    Scope = "CurrentUser"                    
                    Repository = $FeedName
                    Force = $true
                    SkipPublisherCheck = $true
                }
            }
        }
        if ($PSBoundParameters.ContainsKey("UsePrivatePackageFeed")) {
            $installParameters["Credential"] = $feedCredential
        }
        Install-Module @installParameters -AllowClobber
    }    
    #endregion    
}