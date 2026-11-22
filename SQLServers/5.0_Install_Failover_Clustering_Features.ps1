Start-Transcript -Append c:\CRB\Bootstrap_Files\Win\5_ClusteringFeatures_log.txt

cls 

Write-Host '
!!!!! This script needs to be run on all cluster nodes : !!!!!! ' -ForegroundColor Cyan
 
 $UserInput = Read-Host "Enter YES to proceed or any other value to quit" 


    if ($UserInput -ne "yes") {
        Write-Host "  Exiting the script..." -ForegroundColor Yellow
        return}
     elseif ($UserInput -eq "yes") {
        Write-Host "  Proceeding with the script to install Failover features:" -ForegroundColor Green
         }


Add-WindowsFeature RSAT-Clustering-PowerShell
 
Install-WindowsFeature -Name Failover-Clustering –IncludeManagementTools
 ##--- Requires restart after this command above


Write-Host "Clustering features done!" -ForegroundColor Yellow

Write-Host "Restarting PC for Feature install of Failover-Clustering"  -ForegroundColor Yellow
 Restart-Computer -Force


 Stop-Transcript