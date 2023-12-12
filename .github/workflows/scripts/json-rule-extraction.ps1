# Variables
$currentDirectory = Get-Location
#$outputDirectory = Join-Path -Path $currentDirectory -ChildPath "Rules"
$outputDirectory = "..\SentinelContent\ExtractedRules"
$inputFilePath = "RuleExport\Export.json"

# Check for output directory
Write-Host "Testing for output directory -" $outputDirectory
if (-not (Test-Path -Path $outputDirectory)) {
    Write-Host "Creating output directory -" $outputDirectory
    New-Item -ItemType Directory -Path $outputDirectory
}
Write-Host "DONE" -ForegroundColor Green

# Check for input file
Write-Host "Testing for input file -" $inputFilePath
if (-not (Test-Path -Path $inputFilePath)) {
    Write-Host "Input file missing!" $inputFilePath
    Exit
}
Write-Host "DONE" -ForegroundColor Green

# Read the JSON content
# Get rules from the resources key
$jsonExport = Get-Content $inputFilePath -raw | ConvertFrom-Json
$rules = $jsonExport.resources

# Check if there are any rules in the JSON
if ($rules.Count -gt 0) {
    Write-Host $rules.Count "rules"
    } else {
    Write-Host "No rules found in the JSON file."
}


# ARM Template
$armTemplate = '{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "workspace": {
            "type": "String"
        }
    },
    "resources": [
        // ... Your resources here
    ]
}'

# Convert the JSON string into a PowerShell object
$armObject = $armTemplate | ConvertFrom-Json

# Extract the resources array
$resources = $armObject.resources

# Remove the resources property from the original object to create a template
$armObject.PSObject.Properties.Remove('resources')

Write-Host

# Iterate over each resource and create individual JSON files
Write-Host "--------------------"
Write-Host "Iterating over rules"
Write-Host "--------------------"
foreach ($rule in $rules) {
   
    # Check if the DisplayName exists and starts with "TS-"
    if ($null -ne $rule.properties.DisplayName -and $rule.properties.DisplayName.StartsWith("TS-")) {

        Write-Host "Parsing rule  -" $rule.properties.DisplayName

        # Define the output file name based on the resource name or ID
        $displayName = $rule.properties.DisplayName.ToLower() -replace ' ', '-'
        $outputFileName = $displayName -replace '[<>:"/\|\?\*]', ''
        $outputFilePath = Join-Path -Path $outputDirectory -ChildPath "${outputFileName}.json"

        # Remove workspace info from query
        $rule.properties.query = $rule.properties.query -replace '(workspace\(.*?\).)', ''

        # Create a new object for the individual resource file
        $individualObject = $armObject | Select-Object *, @{Name='resources'; Expression={,@($rule)}}

        # Convert the new object to a JSON string
        $individualJsonString = $individualObject | ConvertTo-Json -Depth 100

        # Save the JSON string to a file
        $individualJsonString | Set-Content -Path $outputFilePath

    } else {
        Write-Host "Ignoring rule -" $rule.properties.DisplayName
    }
}


<#
foreach ($rule in $rules) {
    Write-Host "abc"



    
    # Check if the DisplayName exists and starts with "TS-"
    if ($null -ne $rule.properties.DisplayName -and $rule.properties.DisplayName.StartsWith("TS-")) {
        
        # Extract DisplayName, convert to lowercase, replace spaces with "-", remove invalid file name characters
        $displayName = $rule.properties.DisplayName.ToLower() -replace ' ', '-'
        $fileName = $displayName -replace '[<>:"/\|\?\*]', ''
        $filePath = Join-Path -Path $outputDirectory -ChildPath ("$fileName.json")

        # Remove workspace info from query
        $rule.properties.query = $rule.properties.query -replace '(workspace\(.*?\).)', ''

        # Convert back to json
        $ruleJson = $rule | ConvertTo-Json -Depth 99 | Out-File -FilePath $filePath -Force
        Write-Host "Created -" $filePath
    } else {
        Write-Host "Ignoring rule -" $rule.properties.DisplayName
    }


    
}
#>