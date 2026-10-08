# Contrôle du stockage USB

Ce projet contient un seul script Windows, `usb_control.bat`, qui permet de
verrouiller ou de déverrouiller l’accès aux périphériques de stockage USB.

## Aperçu

![Menu du contrôle USB](usb-control-menu.png)

## Utilisation

1. Dans les variables d’environnement Windows de votre compte, créez
   `USB_CONTROL_PASSWORD` et attribuez-lui le mot de passe de votre choix.
   Fermez puis rouvrez votre session ou votre terminal après l’avoir configuré.
2. Lancez `usb_control.bat`. Le script demandera automatiquement l’autorisation
   administrateur via Windows (UAC).
3. Choisissez une option dans le menu :
   - `1` pour verrouiller le stockage USB ;
   - `2` pour le déverrouiller.
4. Saisissez le mot de passe configuré.

Le script modifie la valeur `Start` du service Windows `USBSTOR`. L’autorisation
administrateur est nécessaire et sera demandée automatiquement.

## Remarques

- Le verrouillage concerne les périphériques de stockage USB ; il ne désactive
  pas nécessairement les autres périphériques USB, comme les claviers ou les
  souris.
- Le mot de passe n’est pas stocké dans le fichier du projet. La variable
  d’environnement Windows reste accessible à votre compte et ne remplace pas
  une véritable protection contre un utilisateur ayant accès à cette session.
- Pour rétablir le réglage précédent, choisissez l’option `2`.
