# Fix-UnconstrainedDelegation.ps1

## 🛡️ Script d'audit et de remédiation Active Directory : Délégation non restreinte (Unconstrained Delegation)

`Fix-UnconstrainedDelegation.ps1` est un script PowerShell avancé destiné aux administrateurs système et aux analystes sécurité pour **identifier, corriger et restaurer** la configuration des objets Active Directory configurés avec une **délégation non restreinte** – une pratique obsolète et risquée exposant le domaine à des attaques de type **Kerberos Ticket Theft**.

---

## 🎯 Objectif

Ce script a pour but de :
- **Auditer** les objets (utilisateurs & ordinateurs) utilisant la délégation non restreinte.
- **Supprimer** le flag `TrustedForDelegation` pour renforcer la sécurité AD.
- **Restaurer** la configuration initiale à partir d’un fichier JSON si nécessaire.

---

## 🧰 Fonctionnalités

- **Menu interactif** avec couleurs pour une utilisation simple :
  - 🟨 `1. Exporter la configuration actuelle (simulation)`
  - 🟥 `2. Appliquer la correction`
  - 🟩 `3. Restaurer depuis une sauvegarde JSON`
  - `4. Quitter`

- **Mode simulation (option 1)** :
  - Liste tous les objets avec `TrustedForDelegation = true`.
  - Génère un fichier CSV (`delegation_audit.csv`) pour analyse sans toucher à AD.
  - Il faut enregistrer le script en Powershell. Au moment de l'éxécution de l'option 1 l'enregistrement du fichier CSV se fera dans le même répertoire que celui du script.

- **Mode remédiation (option 2)** :
  - Désactive la délégation non restreinte sur les objets concernés.
  - Crée un **fichier JSON de sauvegarde** avant toute modification (`delegation_backup.json`).

- **Mode restauration (option 3)** :
  - Réapplique la configuration initiale (restauration du flag).
  - Utilise le fichier JSON précédemment généré.
  - Le fichier **doit se trouver dans le même répertoire que le script**.

---

## 📌 Prérequis

- Être membre d’un domaine Active Directory.
- Avoir les droits suffisants :
  - Lecture AD (option 1).
  - Modification des objets AD (options 2 et 3).
- PowerShell 5.1+ ou PowerShell Core.
- Module `ActiveDirectory` disponible.

---

## 📂 Exemple d’utilisation

```powershell
.\Fix-UnconstrainedDelegation.ps1
