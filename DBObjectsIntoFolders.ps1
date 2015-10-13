

# Scripts db, tables, views in database of your choice
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null
[System.Reflection.Assembly]::LoadWithPartialName("System.Data") | out-null

$dbname = "test"
$filename = "c:\temp\output.txt" 
$serverName = "localhost"

$srv = new-object "Microsoft.SqlServer.Management.SMO.Server" $serverName
$srv.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.View], "IsSystemObject")

$db = New-Object "Microsoft.SqlServer.Management.SMO.Database"
$db = $srv.Databases[$dbname]

$scr = New-Object "Microsoft.SqlServer.Management.Smo.Scripter"
$deptype = New-Object "Microsoft.SqlServer.Management.Smo.DependencyType"

$scr.Server = $srv
$options = New-Object "Microsoft.SqlServer.Management.SMO.ScriptingOptions"
$options.DriAll = $True
$options.ClusteredIndexes = $true
$options.Default = $true
$options.DriAll = $true
$options.Indexes = $true
$options.IncludeHeaders = $true
$options.AppendToFile = $false
$options.FileName = $filename
$options.ToFileOnly = $true

$scr.Options = $options
$scr.Script($db)
$scr.Script([Microsoft.SqlServer.Management.Smo.SqlSmoObject[]]$db.Tables)


#-------------------------------------------------------------
# Lists space used by tables in database of your choice
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null

$server = 'localhost'#$args[0]
$dbname = 'AdventureWorks2008R2'#$args[1]
$output = "c:\temp\output.txt"

$srv = New-Object "Microsoft.SqlServer.Management.SMO.Server" $server
$db = New-Object ("Microsoft.SqlServer.Management.SMO.Database")
$scr = New-Object ("Microsoft.SqlServer.Management.Smo.Scripter")

$db = $srv.Databases[$dbname]

$scr.Server = $srv
$options = New-Object ("Microsoft.SqlServer.Management.SMO.ScriptingOptions")
$options.DriAll = $True
$options.ClusteredIndexes = $true
$options.Default = $true
$options.DriAll = $true
$options.Indexes = $true
$options.IncludeHeaders = $true
$options.AppendToFile = $false
$options.FileName = $output
$options.ToFileOnly = $true

$scr.Options = $options
$scr.Script($db.Tables)

$options.AppendToFile = $true
$views = $db.Views | where {$_.IsSystemObject -eq $false}
$scr.Script($views)

#-----------------------------------------------------
# Script all tables in the test database
#	$Objects += $db.Views
#	$Objects += $db.StoredProcedures
#	$Objects += $db.UserDefinedFunctions
#$scrp.Script([Microsoft.SqlServer.Management.Sdk.Sfc.Urn[]]$Objects)
function Script-DBObjects
{
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Management.Sdk.Sfc") | out-null
	 
	$s = new-object ('Microsoft.SqlServer.Management.Smo.Server') 'localhost'
	$db = $s.Databases['test']
	
	$Objects = $db.Tables | where {$_.IsSystemObject -eq $false}
	$Objects += $db.Views | where {$_.IsSystemObject -eq $false}
	$Objects += $db.StoredProcedures | where {$_.IsSystemObject -eq $false}
	$Objects += $db.UserDefinedFunctions | where {$_.IsSystemObject -eq $false}
	
	$scrp = new-object ('Microsoft.SqlServer.Management.Smo.Scripter') ($s)
	 
	$scrp.Options.AppendToFile = $False
	$scrp.Options.ClusteredIndexes = $True
	$scrp.Options.DriAll = $True
	$scrp.Options.ScriptDrops = $False
	$scrp.Options.IncludeHeaders = $True
	$scrp.Options.ToFileOnly = $True
	$scrp.Options.Indexes = $True
	$scrp.Options.WithDependencies = $True
	 
	$scrp.Options.FileName = 'C:\TEMP\test.SQL'
	
	$scrp.Script([Microsoft.SqlServer.Management.Smo.SqlSmoObject[]]$Objects)
}


#---------------------------------------------
# Script-DBObjectsIntoFolders "localhost" "test"
function Script-DBObjectsIntoFolders([string]$server, [string]$dbname)
{
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null	
	$SMOserver = New-Object ('Microsoft.SqlServer.Management.Smo.Server') -argumentlist $server	
	$db = $SMOserver.databases[$dbname]	

	$Objects = $db.Tables
	$Objects += $db.Views
	$Objects += $db.StoredProcedures
	$Objects += $db.UserDefinedFunctions

	#Build this portion of the directory structure out here in case scripting takes more than one minute.
	$SavePath = "C:\TEMP\Databases\" + $($dbname)
	$DateFolder = get-date -format yyyyMMddHHmm
	new-item -type directory -name "$DateFolder"-path "$SavePath"

	foreach ($ScriptThis in $Objects | where {!($_.IsSystemObject)}) 
	{
		#Need to Add Some mkDirs for the different $Fldr=$ScriptThis.GetType().Name
		$scriptr = new-object ('Microsoft.SqlServer.Management.Smo.Scripter') ($SMOserver)
		$scriptr.Options.AppendToFile = $True
		$scriptr.Options.AllowSystemObjects = $False
		$scriptr.Options.ClusteredIndexes = $True
		$scriptr.Options.DriAll = $True
		$scriptr.Options.ScriptDrops = $False
		$scriptr.Options.IncludeHeaders = $True
		$scriptr.Options.ToFileOnly = $True
		$scriptr.Options.Indexes = $True
		$scriptr.Options.Permissions = $True
		$scriptr.Options.WithDependencies = $False
		#Script the Drop too#
		$ScriptDrop = new-object ('Microsoft.SqlServer.Management.Smo.Scripter') ($SMOserver)
		$ScriptDrop.Options.AppendToFile = $True
		$ScriptDrop.Options.AllowSystemObjects = $False
		$ScriptDrop.Options.ClusteredIndexes = $True
		$ScriptDrop.Options.DriAll = $True
		$ScriptDrop.Options.ScriptDrops = $True
		$ScriptDrop.Options.IncludeHeaders = $True
		$ScriptDrop.Options.ToFileOnly = $True
		$ScriptDrop.Options.Indexes = $True
		$ScriptDrop.Options.WithDependencies = $False

		#This section builds folder structures.  Remove the date folder if you want to overwrite
		$TypeFolder=$ScriptThis.GetType().Name
		if ((Test-Path -Path "$SavePath\$DateFolder\$TypeFolder") -eq "true")
		{
			"Scripting Out $TypeFolder $ScriptThis"
		}
		else 
		{
			new-item -type directory -name "$TypeFolder"-path "$SavePath\$DateFolder"
		}
		
		$ScriptFile = $ScriptThis -replace "\[|\]"
		$ScriptDrop.Options.FileName = "" + $($SavePath) + "\" + $($DateFolder) + "\" + $($TypeFolder) + "\" + $($ScriptFile) + ".SQL"
		$scriptr.Options.FileName = "$SavePath\$DateFolder\$TypeFolder\$ScriptFile.SQL"

		#This is where each object actually gets scripted one at a time.
		$ScriptDrop.Script($ScriptThis)
		$scriptr.Script($ScriptThis)
	}
}


#--------------------------------
# Scripts db, tables, views in database of your choice
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null
[System.Reflection.Assembly]::LoadWithPartialName("System.Data") | out-null

$dbname = "Database Name"
$filename = "c:\temp\output.txt" 
$serverName = "Server Name"

$srv = new-object "Microsoft.SqlServer.Management.SMO.Server" $serverName
$srv.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.View], "IsSystemObject")

$db = New-Object "Microsoft.SqlServer.Management.SMO.Database"
$db = $srv.Databases[$dbname]

$scr = New-Object "Microsoft.SqlServer.Management.Smo.Scripter"
$deptype = New-Object "Microsoft.SqlServer.Management.Smo.DependencyType"

$scr.Server = $srv
$options = New-Object "Microsoft.SqlServer.Management.SMO.ScriptingOptions"
$options.DriAll = $True
$options.ClusteredIndexes = $true
$options.Default = $true
$options.DriAll = $true
$options.Indexes = $true
$options.IncludeHeaders = $true
$options.AppendToFile = $false
$options.FileName = $filename
$options.ToFileOnly = $true

$scr.Options = $options
$scr.Script($db)
$scr.Script($db.Tables)
$options.AppendToFile = $true
$views = $db.Views | where {$_.IsSystemObject -eq $false}
$scr.Script($views)

$tree = $scr.DiscoverDependencies($db.Tables, $True)

$depwalker = New-Object "Microsoft.SqlServer.Management.SMO.DependencyWalker"
$depcoll = $depwalker.WalkDependencies($tree)

#Using the sp_generate_inserts from the webpage http://vyaskn.tripod.com/code.htm

$col = $depcoll | foreach {
 "EXEC sp_generate_inserts '" + $_.Urn.GetAttribute("Name") + "'"
}

$ds = New-Object "System.Data.DataSet"
$ds = $db.ExecuteWithResults($col)

# using the Piping features to go from Tables, to Table, to Rows, to Row and to Column 1 $_[0]
$ds.Tables | foreach { $_.Rows | foreach {$_[0]} }

#-------------------------------------------------------