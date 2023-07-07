Param (
    [string] $SystemAccessToken,
    [string] $FeedName,
    [string] $FeedUrl,
    [switch] $UsePrivatePackageFeed
)

begin {
    $buildAndTestDeps = @(
        @{ ModuleName = "PSFramework"; RequiredVersion = "1.7.245" },
        @{ ModuleName = "Microsoft.Graph.Authentication"; RequiredVersion = "1.27.0"},
        @{ ModuleName = "Microsoft.Graph.Identity.DirectoryManagement"; RequiredVersion = "1.27.0"},
        @{ ModuleName = "Microsoft.Graph.Identity.Governance"; RequiredVersion = "1.27.0"},
        @{ ModuleName = "Pester"; RequiredVersion = "5.4.0" }
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