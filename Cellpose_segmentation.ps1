# Usage Note:
# 1. put this script file to the folder of the input image
# 2. open powershell and go to the folder of the input image
# 3. in powershell: "conda activate cellpose"
# 4. in powershell: ".\Cellpose_segmenetation_V0.3.ps1"



# Set the directory for BF_Dir
$BF_Dir = "$PWD\Output_Results\BF_Dir"

# Check whether the file exists
while (-not (Test-Path "$BF_Dir\Is_BF_Ready.csv")) {
    Write-Host "Waiting for BF files!"
    Start-Sleep -Seconds 10  # Or adjust the sleep time as needed
}

Write-Host "BF files are ready."

# Run cellpose with diameter=10, model=cyto3
python -m cellpose --dir $BF_Dir --pretrained_model cyto3 --diameter 10.0 --chan 0 --chan2 0 --use_gpu --gpu_device 0 --save_png --verbose | Tee-Object -file $BF_Dir\Cellposs.Log.txt

# Create a file when done
New-Item -Path "$BF_Dir\cellpose_done.txt" -ItemType File

Write-Host "All PowerShell script completed!"


# .\Cellpose_segmenetation_V0.3.ps1 | Tee-Object -file .\Cellposs.Log.txt

