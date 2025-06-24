Import-Module ActiveDirectory

function Show-Menu {
    Clear-Host
    Write-Host "============================================="
    Write-Host "  Fix-UnconstrainedDelegation.ps1 - MENU"
    Write-Host "============================================="
    Write-Host "" -NoNewline
    Write-Host "1. Exporter la configuration actuelle (simulation)" -ForegroundColor Yellow
    Write-Host "" -NoNewline
    Write-Host "2. Appliquer la correction (desactiver Unconstrained Delegation)" -ForegroundColor Red
    Write-Host "" -NoNewline
    Write-Host "3. Restaurer depuis une sauvegarde JSON" -ForegroundColor Green
    Write-Host "4. Quitter"
    Write-Host "============================================="
}

function Show-Tutorial {
    param ([string]$Option)

    Clear-Host
    switch ($Option) {
        '1' {
            Write-Host "*** Export de la configuration actuelle ***" -ForegroundColor Cyan
            Write-Host "Ce mode effectue une simulation sans appliquer de modifications."
            Write-Host "Il permet de lister tous les objets AD avec la delegation non restreinte activee."
            Write-Host "Un fichier CSV est genere pour analyse."
            Write-Host "Prérequis : droits de lecture dans Active Directory."
        }
        '2' {
            Write-Host "*** Application de la correction ***" -ForegroundColor Cyan
            Write-Host "Ce mode supprime l'attribut 'TrustedForDelegation' des objets AD identifies."
            Write-Host "Un fichier de sauvegarde JSON est automatiquement genere avant toute modification."
            Write-Host "Prérequis : droits de modification sur les objets AD."
            Write-Host "Attention : cette action modifie directement la configuration AD."
        }
        '3' {
            Write-Host "*** Restauration depuis sauvegarde ***" -ForegroundColor Cyan
            Write-Host "Cette fonction restaure les objets AD a leur etat initial en reappliquant l'attribut 'TrustedForDelegation'."
            Write-Host "Elle repose sur le fichier JSON genere lors de l'etape de correction."
            Write-Host "Le fichier de sauvegarde JSON doit etre place dans le meme repertoire que ce script."
            Write-Host "Prérequis : disposer du fichier de sauvegarde et des droits de modification AD."
        }
    }
    Write-Host ""
    Pause
}

function Export-DelegationReport {
    param (
        [string]$ExportPath = "delegation_audit.csv"
    )

    $results = @()

    $computers = Get-ADComputer -Filter {TrustedForDelegation -eq $true} -Properties TrustedForDelegation, OperatingSystem, DistinguishedName
    $users = Get-ADUser -Filter {TrustedForDelegation -eq $true} -Properties TrustedForDelegation, DistinguishedName

    foreach ($obj in $computers + $users) {
        $results += [PSCustomObject]@{
            Name               = $obj.Name
            Type               = if ($obj.objectClass -eq 'computer') { 'Computer' } else { 'User' }
            DistinguishedName  = $obj.DistinguishedName
            OperatingSystem    = $obj.OperatingSystem
            TrustedForDelegation = $obj.TrustedForDelegation
        }
    }

    if ($results.Count -gt 0) {
        $results | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
        Write-Host "Export termine : $ExportPath" -ForegroundColor Green
    } else {
        Write-Host "Aucun objet avec Unconstrained Delegation detecte." -ForegroundColor Yellow
    }
}

function Fix-Delegation {
    param (
        [string]$BackupPath = "delegation_backup.json"
    )

    $fixedObjects = @()

    $computers = Get-ADComputer -Filter {TrustedForDelegation -eq $true} -Properties TrustedForDelegation
    $users = Get-ADUser -Filter {TrustedForDelegation -eq $true} -Properties TrustedForDelegation

    $targets = $computers + $users

    if ($targets.Count -eq 0) {
        Write-Host "Aucun objet avec Unconstrained Delegation detecte." -ForegroundColor Yellow
        return
    }

    $backup = @()
    foreach ($obj in $targets) {
        $backup += [PSCustomObject]@{
            Name = $obj.Name
            DistinguishedName = $obj.DistinguishedName
            ObjectClass = $obj.objectClass
            TrustedForDelegation = $obj.TrustedForDelegation
        }

        try {
            Set-ADObject -Identity $obj.DistinguishedName -Clear TrustedForDelegation -ErrorAction Stop
            Write-Host "Desactivation delegation : $($obj.Name)" -ForegroundColor Green
            $fixedObjects += $obj
        } catch {
            Write-Host "Erreur sur $($obj.Name) : $_" -ForegroundColor Red
        }
    }

    $backup | ConvertTo-Json -Depth 5 | Out-File -FilePath $BackupPath -Encoding UTF8
    Write-Host "Backup enregistre : $BackupPath" -ForegroundColor Cyan
}

function Restore-Delegation {
    param (
        [string]$BackupPath = "delegation_backup.json"
    )

    if (-not (Test-Path $BackupPath)) {
        Write-Host "Fichier de sauvegarde introuvable : $BackupPath" -ForegroundColor Red
        return
    }

    $backupContent = Get-Content $BackupPath -Raw | ConvertFrom-Json

    foreach ($entry in $backupContent) {
        try {
            if ($entry.TrustedForDelegation -eq $true) {
                Set-ADObject -Identity $entry.DistinguishedName -Add @{TrustedForDelegation = $true} -ErrorAction Stop
                Write-Host "Delegation restauree : $($entry.Name)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Erreur lors de la restauration pour $($entry.Name) : $_" -ForegroundColor Red
        }
    }

    Write-Host "Restauration terminee." -ForegroundColor Green
}

# Menu principal
while ($true) {
    Show-Menu
    $choice = Read-Host "Veuillez choisir une option (1-4)"

    switch ($choice) {
        '1' {
            Show-Tutorial -Option '1'
            $exportPath = Read-Host "Chemin de l'export CSV (defaut : delegation_audit.csv)"
            if (-not $exportPath) { $exportPath = "delegation_audit.csv" }
            Export-DelegationReport -ExportPath $exportPath
            Pause
        }
        '2' {
            Show-Tutorial -Option '2'
            $backupPath = Read-Host "Chemin du fichier de backup JSON (defaut : delegation_backup.json)"
            if (-not $backupPath) { $backupPath = "delegation_backup.json" }
            Fix-Delegation -BackupPath $backupPath
            Pause
        }
        '3' {
            Show-Tutorial -Option '3'
            $restorePath = Read-Host "Nom du fichier de sauvegarde JSON (defaut : delegation_backup.json) dans le meme repertoire que ce script"
            if (-not $restorePath) { $restorePath = "delegation_backup.json" }
            $fullPath = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath $restorePath
            Restore-Delegation -BackupPath $fullPath
            Pause
        }
        '4' {
            break
        }
        default {
            Write-Host "Choix invalide." -ForegroundColor Red
        }
    }
}
