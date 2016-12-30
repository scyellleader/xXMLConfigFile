function Get-XMLItem
{
  [CmdletBinding()]
  param
  (
    [string]$ConfigPath,
    [string]$XPath,
    [string]$Name,
    [string]$Value,
    [Boolean]$isAttribute,
    [string]$Attribute1 = 'key',
    [string]$Attribute2 = 'value',
    [string]$XMLNS,
    [string]$NSPrefix = 'ns',
    [Boolean]$DoBackup,
    $VerbosePreference
  )
    #read XML
    $xml = [xml](Get-Content $ConfigPath -ErrorAction Stop)
    $root = $xml.get_DocumentElement()
    if(!$XMLNS){
      #create XML namespacemanager from document
      $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
      $ns.AddNameSpace("$NSPrefix",$xml.DocumentElement.NamespaceURI)
    }
    else {
      #create XML namespacemanager
      $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
      $ns.AddNameSpace("$NSPrefix",$XMLNS)
    }
    #add XMLNameSpaceManager to XPath
    $XPath = $XPath -replace "/(?!/)", "/$($NSPrefix):" 
    Write-Verbose -Message "XPath:$($Xpath)"
    Write-Verbose -Message "NamespaceURI:$($xml.DocumentElement.NamespaceURI)"

    if (!$isAttribute) {
      $Item = $root.SelectSingleNode("$XPath[@$Attribute1=`'$Name`']",$ns).$Attribute2
    }
    else {
        if ($root.SelectSingleNode($XPath,$ns).HasAttribute($Name)) {
            $Item = $root.SelectSingleNode($XPath,$ns).GetAttribute($Name)
        }
    }
    if ($Item) {
        Write-Verbose "$($Name) found with value $($Item)!"
        return $Item
    }
    else {
        Write-Verbose "$($Name) could not be found!"
        return $null
    }
}

function Set-XMLItem
{
  [CmdletBinding()]
  param
  (
    [string]$ConfigPath,
    [string]$XPath,
    [string]$Name,
    [string]$Value,
    [Boolean]$isAttribute,
    [string]$Attribute1 = 'key',
    [string]$Attribute2 = 'value',
    [string]$XMLNS,
    [string]$NSPrefix = 'ns',
    [Boolean]$DoBackup,
    $VerbosePreference
  )
  try {
    if ($DoBackup) {
        $CurrentDate = (get-date).tostring("MMddyyyy-hhmmss")
        $Backup = $ConfigPath + "_$CurrentDate" + ".bak" 
        try {
            $xml.Save($Backup)
        }
        catch {
            Write-Verbose $_
        }
    }
    #read XML
    $xml = [xml](Get-Content $ConfigPath -ErrorAction Stop)
    $root = $xml.get_DocumentElement()
    if(!$XMLNS){
      #create XML namespacemanager from document
      $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
      $ns.AddNameSpace("$NSPrefix",$xml.DocumentElement.NamespaceURI)
    }
    else {
      #create XML namespacemanager
      $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
      $ns.AddNameSpace("$NSPrefix",$XMLNS)
    }
    #add XMLNameSpaceManager to XPath
    $XPath = $XPath -replace "/(?!/)", "/$($NSPrefix):"
    Write-Verbose -Message "XPath:$($Xpath)"
    Write-Verbose -Message "NamespaceURI:$($xml.DocumentElement.NamespaceURI)"

    if (!$isAttribute) {
        if ($null -ne $root.SelectSingleNode("$XPath[@$Attribute1=`'$Name`']",$ns)) {
            Write-Verbose "$($Name) found and will be set to $($Value)!"
            $root.SelectSingleNode("$XPath[@$Attribute1=`'$Name`']",$ns).SetAttribute($Attribute2,$Value)
        }
        else {
            Write-Verbose "$($Name) could not be found!"
            break
        }
    }
    else {
        if ($root.SelectSingleNode($XPath,$ns).HasAttribute($Name)) {
            Write-Verbose "$($Name) found and will be set to $($Value)!"
            $root.SelectSingleNode($XPath,$ns).SetAttribute($Name,$Value)
        }
        else {
            Write-Verbose "$($Name) could not be found!"
            break
        }
    }
    $xml.Save($ConfigPath)
  }
  catch {
    Write-Verbose $_
  }
}

function Add-XMLItem
{
  [CmdletBinding()]
  param
  (
    [string]$ConfigPath,
    [string]$XPath,
    [string]$Name,
    [string]$Value,
    [Boolean]$isAttribute,
    [string]$Attribute1 = 'key',
    [string]$Attribute2 = 'value',
    [string]$XMLNS,
    [string]$NSPrefix = 'ns',
    [Boolean]$DoBackup,
    $VerbosePreference
  )
  try {
    #read XML
    $xml = [xml](Get-Content $ConfigPath -ErrorAction Stop)
    $root = $xml.get_DocumentElement()
    if(!$XMLNS){
      #create XML namespacemanager from document
      $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
      $ns.AddNameSpace("$NSPrefix",$xml.DocumentElement.NamespaceURI)
    }
    else {
      #create XML namespacemanager
      $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
      $ns.AddNameSpace("$NSPrefix",$XMLNS)
    }
    #add XMLNameSpaceManager to XPath
    $XPath = $XPath -replace "/(?!/)", "/$($NSPrefix):"
    Write-Verbose -Message "XPath:$($Xpath)"
    Write-Verbose -Message "NamespaceURI:$($xml.DocumentElement.NamespaceURI)"

    if ($DoBackup) {
        $CurrentDate = (get-date).tostring("MMddyyyy-hhmmss")
        $Backup = $ConfigPath + "_$CurrentDate" + ".bak" 
        try {
            $xml.Save($Backup)
        }
        catch {
            Write-Vebose $Error[0].Exception
        }
    }
    if (!$isAttribute) {
        if ($root.SelectSingleNode("$XPath[@$Attribute1=`'$Name`']",$ns)){
            Write-Verbose "An element already exist!";
            break
        }
        else {
            #get parent node
            $Parent=$root.SelectSingleNode($XPath,$ns).get_ParentNode()
            #create element
            #$Element = $xml.CreateElement($ElementName);
            $Element = $xml.CreateElement($($XPath.Split('/')[-1] -replace ("$($NSPrefix):","")),$xml.DocumentElement.NamespaceURI)
            #create attributes
            $Attr1=$xml.CreateAttribute($Attribute1)
            $Attr2=$xml.CreateAttribute($Attribute2)
            #set attributes
            $Attr1.set_Value($Name)
            $Attr2.set_Value($Value)
            #add attributes to element
            $Element.SetAttributeNode($Attr1) | Out-Null
            $Element.SetAttributeNode($Attr2) | Out-Null
            #append element
            $Parent.AppendChild($Element) | Out-Null
        }
    }
    else {
        if (!$null -eq $root.SelectSingleNode($XPath,$ns)) {
            if ($root.SelectSingleNode($XPath,$ns).HasAttribute($Name)) {
                Write-Verbose "An attribute already exist!"
                break
            }
            else {
                $root.SelectSingleNode($Xpath,$ns).SetAttribute($Name,$Value)
            }
        }
        else {
            Write-Verbose "Nothing found!"
        }
    }
    $xml.Save($ConfigPath)
  }
  catch {
    Write-Verbose $_
  }
}

function Remove-XMLItem
{
  [CmdletBinding()]
  param
  (
    [string]$ConfigPath,
    [string]$XPath,
    [string]$Name,
    [string]$Value,
    [Boolean]$isAttribute,
    [string]$Attribute1 = 'key',
    [string]$Attribute2 = 'value',
    [string]$XMLNS,
    [string]$NSPrefix = 'ns',
    [Boolean]$DoBackup,
    $VerbosePreference
  )
  try {
    if ($DoBackup) {
        $CurrentDate = (get-date).tostring("MMddyyyy-hhmmss")
        $Backup = $ConfigPath + "_$CurrentDate" + ".bak" 
        try {
            $xml.Save($Backup)
        }
        catch {
            Write-Verbose $_
        }
    }
    #read XML
    $xml = [xml](Get-Content $ConfigPath -ErrorAction Stop)
    $root = $xml.get_DocumentElement()
    if(!$XMLNS){
      #create XML namespacemanager from document
      $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
      $ns.AddNameSpace("$NSPrefix",$xml.DocumentElement.NamespaceURI)
    }
    else {
      #create XML namespacemanager
      $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
      $ns.AddNameSpace("$NSPrefix",$XMLNS)
    }
    #add XMLNameSpaceManager to XPath
    $XPath = $XPath -replace "/(?!/)", "/$($NSPrefix):"
    Write-Verbose -Message "XPath:$($Xpath)"
    Write-Verbose -Message "NamespaceURI:$($xml.DocumentElement.NamespaceURI)"

    if (!$isAttribute) {
        if (!$root.SelectSingleNode("$XPath[@$Attribute1=`'$Name`']",$ns)){
            Write-Verbose "Nothing found!"
            break;
        }
        else {
            #get node
            $Node = $root.SelectSingleNode("$XPath[@$Attribute1=`'$Name`']",$ns)
            #get parent node and remove node
            $Node.get_ParentNode().RemoveChild($Node) | Out-Null
        }
    }
    else {
        if (!$null -eq $root.SelectSingleNode($XPath,$ns)) {
            if ($root.SelectSingleNode($XPath,$ns).HasAttribute($Name)) {
                $root.SelectSingleNode($Xpath,$ns).RemoveAttribute($Name)
            }
            else {
                Write-Verbose "Nothing found!"
                break
            }
        }
        else {
            Write-Verbose "Nothing found!"
        }
    }
    $xml.Save($ConfigPath)
  }
  catch {
    Write-Verbose $_
  }
}

function Test-XMLItemExist
{
  [CmdletBinding()]
  [OutputType([System.Boolean])]
  param
  (
    [string]$ConfigPath,
    [string]$XPath,
    [string]$Name,
    [string]$Value,
    [Boolean]$isAttribute,
    [string]$Attribute1 = 'key',
    [string]$Attribute2 = 'value',
    [string]$XMLNS,
    [string]$NSPrefix = 'ns',
    [Boolean]$DoBackup,
    $VerbosePreference
  )
    [boolean]$result = $false
    #read XML
    $xml = [xml](Get-Content $ConfigPath -ErrorAction Stop)
    $root = $xml.get_DocumentElement()
    if(!$XMLNS){
      #create XML namespacemanager from document
      $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
      $ns.AddNameSpace("$NSPrefix",$xml.DocumentElement.NamespaceURI)
    }
    else {
      #create XML namespacemanager
      $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
      $ns.AddNameSpace("$NSPrefix",$XMLNS)
    }
    #add XMLNameSpaceManager to XPath
    $XPath = $XPath -replace "/(?!/)", "/$($NSPrefix):"
    Write-Verbose -Message "XPath:$($Xpath)"
    Write-Verbose -Message "NamespaceURI:$($xml.DocumentElement.NamespaceURI)"
    
    if (!$isAttribute) {
        $Item = $root.SelectSingleNode("$XPath[@$Attribute1=`'$Name`']",$ns)
        if ($null -ne $root.SelectSingleNode("$XPath[@$Attribute1=`'$Name`']",$ns)) {
            $result = $true
        }
    }
    else {
        if ($root.SelectSingleNode($XPath,$ns).HasAttribute($Name)) {
            $result = $true
        }
    }
    return $result
}

Export-ModuleMember -Function *