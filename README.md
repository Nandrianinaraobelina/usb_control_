# Contrôle du stockage USB

Ce projet contient un seul script Windows, `usb_control.bat`, qui permet de
verrouiller ou de déverrouiller l’accès aux périphériques de stockage USB.

## Aperçu

![Menu du contrôle USB](usb-control-menu.png)

## Utilisation

1. Ouvrez `usb_control.bat` dans un éditeur de texte et remplacez `CHANGE_ME`
   par le mot de passe de votre choix.
2. Lancez le fichier en tant qu’administrateur : clic droit sur le fichier,
   puis **Exécuter en tant qu’administrateur**.
3. Choisissez une option dans le menu :
   - `1` pour verrouiller le stockage USB ;
   - `2` pour le déverrouiller.
4. Saisissez le mot de passe configuré.

Le script modifie la valeur `Start` du service Windows `USBSTOR`. Les droits
administrateur sont nécessaires pour appliquer cette modification.

## Remarques

- Le verrouillage concerne les périphériques de stockage USB ; il ne désactive
  pas nécessairement les autres périphériques USB, comme les claviers ou les
  souris.
- Le mot de passe est enregistré en clair dans le fichier `.bat`. Il constitue
  une protection simple contre une utilisation accidentelle, pas une sécurité
  contre une personne pouvant lire ou modifier le fichier.
- Pour rétablir le réglage précédent, choisissez l’option `2`.
