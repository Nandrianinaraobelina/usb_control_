# Contrôle du stockage USB

Ce projet contient un script Windows unique, `usb_control.bat`, qui permet de
verrouiller ou de déverrouiller les périphériques de stockage USB.

## Aperçu

![Menu de contrôle USB](usb-control-menu.png)

## Utilisation

1. Créez la variable d’environnement Windows `USB_CONTROL_PASSWORD` pour votre
   compte et définissez le mot de passe de votre choix.
2. Fermez puis rouvrez votre terminal ou votre session Windows pour que la
   variable soit prise en compte.
3. Lancez `usb_control.bat`. Windows demandera automatiquement l’autorisation
   d’administrateur via l’UAC. Si vous refusez ou annulez la demande, le script
   affichera un message explicite.
4. Consultez l’état actuel affiché, puis choisissez une option dans le menu :
   - `1` pour verrouiller le stockage USB ;
   - `2` pour le déverrouiller.
5. Saisissez le mot de passe configuré. La saisie reste masquée à l’écran.
6. Tapez `ENY` pour confirmer la modification du Registre Windows.

Le script modifie la valeur `Start` du service Windows `USBSTOR`. Les droits
d’administrateur sont nécessaires et seront demandés automatiquement. Après
la modification, le script relit la valeur du Registre afin de vérifier que le
changement a bien été appliqué.

## Remarques

- Le verrouillage concerne les périphériques de stockage USB ; les autres
  périphériques USB, comme les claviers et les souris, peuvent continuer à
  fonctionner.
- Le mot de passe n’est pas enregistré dans les fichiers du projet. La variable
  d’environnement reste accessible à votre compte Windows et ne protège pas
  contre une personne ayant accès à cette session.
- Pour déverrouiller le stockage USB, choisissez l’option `2`.
