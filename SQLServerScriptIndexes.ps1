

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Management.Sdk.Sfc") | out-null
	 
$s = new-object ('Microsoft.SqlServer.Management.Smo.Server') 'localhost'
$db = $s.Databases['MCPTestLocal']

$tables = $db.Tables | where {$_.IsSystemObject -eq $false}
Write-Host "$table Count= $($table.Count)"

$scriptOptions = new-object ('Microsoft.SqlServer.Management.Smo.ScriptingOptions')
$scriptOptions.ScriptDrops = $True
$scriptOptions.IncludeIfNotExists = $True

Write-Host("---------------- INDEX -----------------------")
$stream = [System.IO.StreamWriter] "C:\temp\indexes.sql"
foreach ($table in $tables) 
{ 
	Write-Host "$table RowCount= $($table.RowCount) Indexes=$($table.Indexes.Count)"
	foreach ($index in $table.Indexes)
	{
		Write-Host "$index"
		
		# Generating IF EXISTS and DROP command for table indexes
        $indexScripts = $index.Script($scriptOptions)
        foreach ($script in $indexScripts)
		{
        	$stream.WriteLine($script)
			$stream.WriteLine("")
		}
 
        # Generating CREATE INDEX command for table indexes
        $indexScripts = $index.Script()
        foreach ($script in $indexScripts)
		{
            $stream.WriteLine($script)
			$stream.WriteLine("")
		}
	}
}

$stream.Close();
$stream.Dispose();

$stream = [System.IO.StreamWriter] "C:\temp\indexes.sql"
$stream.WriteLine("---------------- FOREIGNKEY -----------------------")
foreach ($table in $tables) 
{ 
	Write-Host "$table ForeignKeys=$($table.ForeignKeys.Count)"
	foreach ($foreignKey in $table.ForeignKeys)
	{
		Write-Host "$index"
		
		# Generating IF EXISTS and DROP command for table indexes
        $foreignKeyScripts = $foreignKey.Script($scriptOptions)
        foreach ($script in $foreignKeyScripts)
		{
        	$stream.WriteLine($script)
			$stream.WriteLine("")
		}
 
        # Generating CREATE INDEX command for table indexes
        $foreignKeyScripts = $foreignKey.Script()
        foreach ($script in $foreignKeyScripts)
		{
            $stream.WriteLine($script)
			$stream.WriteLine("")
		}
	}
}

$stream.Close();
$stream.Dispose();

#$scripter = new-object ('Microsoft.SqlServer.Management.Smo.Scripter') ($s)
#$scripter.Script([Microsoft.SqlServer.Management.Smo.SqlSmoObject[]]$Tables)

