<powershell>

#$instanceId = Get-EC2InstanceMetadata -Category InstanceId

Import-Module AWSPowerShell

$extract_path = "C:\CRB\Bootstrap_Files\Win\"
$download_path = "C:\CRB\Bootstrap_Files\downloads\"

try {
    New-Item -ItemType Directory -Path $download_path
    # The bootstrap buckets live in us-east-1; pin the region so
cross-region
    # deployments (e.g. il-central-1) don't hit the wrong S3 endpoint.
    Get-S3Object -BucketName ${s3_bootstrap_location} -Key
"win_bootstrap_files.zip" -Region us-east-1 | Read-S3Object -Folder
$download_path -Region us-east-1

}
catch {
    {
        Write-Host("Could not download bootstrap files from S3 -
terminating execution")
        return
    }
}


try {
    Expand-Archive -Path
"C:\CRB\Bootstrap_Files\downloads\win_bootstrap_files.zip" -DestinationPath
$extract_path
}
catch {
    {
        Write-Host("Could not extract bootstrap files from S3 - terminating
execution")
        return
    }
}

try {
    Get-ChildItem -PATH c:\CRB\Bootstrap_Files\win | Sort-Object |
ForEach-Object -Process  {
        Invoke-Expression ( $_.FullName )
    }
}
catch {
    {
        Write-Host("Could not execute bootstrap files from S3 - terminating
execution")
        return
    }
}


</powershell>