# Contrôle du stockage USB

Ce projet contient `usb_control.bat`, un lanceur qui ouvre une interface
graphique Windows. L’interface et la logique de contrôle sont dans
`src/usb_control.ps1`.

## Structure du projet

```text
usb_control.bat                 Lanceur Windows
src/usb_control.ps1             Interface et logique de contrôle
assets/                          Images de l’application et documentation
data/                            Journal et sauvegarde locale du Registre
.gitignore                       Exclut les données locales générées
README.md                        Documentation
```

## Aperçu

![Menu de contrôle USB](assets/usb-control-menu.png)

La photo d’arrière-plan de l’application est `assets/usb-control-background.jpg`.

## Utilisation

1. Créez la variable d’environnement Windows `USB_CONTROL_PASSWORD` pour votre
   compte et définissez le mot de passe de votre choix.
2. Fermez puis rouvrez votre terminal ou votre session Windows pour que la
   variable soit prise en compte.
3. Lancez `usb_control.bat`. Windows demandera automatiquement l’autorisation
   d’administrateur via l’UAC. Seule l’interface administrateur reste ouverte.
4. Consultez l’état du stockage USB et utilisez les boutons pour verrouiller,
   déverrouiller, restaurer la valeur initiale, ouvrir le journal ou quitter.
5. Saisissez le mot de passe dans la boîte de dialogue. La saisie est masquée.
6. Vérifiez le récapitulatif et confirmez les modifications du Registre.

Le script modifie la valeur `Start` du service Windows `USBSTOR`, puis vérifie
que la modification a bien été appliquée. Si le stockage est déjà dans l’état
demandé, le Registre n’est pas réécrit.

Les disques USB déjà connectés peuvent rester accessibles après le verrouillage.
Le script affiche un avertissement et demande confirmation avant de continuer.

Avant le premier verrouillage ou déverrouillage, la valeur initiale de `Start`
est enregistrée dans `data/usb_control.previous`. Le fichier est marqué en
lecture seule afin d’éviter une modification accidentelle. L’option de
restauration remet cette valeur.

Le journal des opérations est enregistré dans `data/usb_control.log`. Il indique
la date, l’action et le résultat, sans jamais contenir le mot de passe.

## Remarques

- Le verrouillage concerne les périphériques de stockage USB ; les autres
  périphériques USB, comme les claviers et les souris, peuvent continuer à
  fonctionner.
- Le mot de passe n’est pas enregistré dans les fichiers du projet. La variable
  d’environnement reste accessible à votre compte Windows et ne protège pas
  contre une personne ayant accès à cette session.
- Les images de l’application sont rangées dans `assets/`.
