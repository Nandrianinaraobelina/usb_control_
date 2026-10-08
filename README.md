# Contrôle du stockage USB

Ce projet contient un script Windows unique, `usb_control.bat`, qui permet de
verrouiller ou de déverrouiller les périphériques de stockage USB.
Le script configure la console en UTF-8 pour afficher correctement les accents.

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
   - `2` pour le déverrouiller ;
   - `3` pour restaurer la valeur initiale du Registre ;
   - `4` pour ouvrir le journal des opérations ;
   - `5` pour quitter.
5. Saisissez le mot de passe configuré. La saisie reste masquée à l’écran.
6. Vérifiez le récapitulatif de l’état actuel et de l’action demandée, puis
   tapez `OUI` pour confirmer la modification du Registre Windows.

Le script modifie la valeur `Start` du service Windows `USBSTOR`. Les droits
d’administrateur sont nécessaires et seront demandés automatiquement. Après
la modification, le script relit la valeur du Registre afin de vérifier que le
changement a bien été appliqué.
Si le stockage est déjà dans l’état demandé, le script ne réécrit pas le Registre.

Le script vérifie aussi les disques USB actuellement connectés. Ceux-ci peuvent
rester accessibles après le verrouillage ; déconnectez-les puis reconnectez-les
après l’opération. Si Windows ne permet pas de vérifier leur présence, le
script l’indique.

Avant le premier verrouillage ou déverrouillage, la valeur initiale de `Start`
est enregistrée dans `usb_control.previous`, à côté du script. L’option `3`
restaure cette valeur. Conservez ce fichier si vous souhaitez pouvoir revenir
à la configuration d’origine.

Les opérations et leurs résultats sont ajoutés à `usb_control.log`, à côté du
script. Le journal contient la date, l’action et le résultat, jamais le mot de
passe.

## Remarques

- Le verrouillage concerne les périphériques de stockage USB ; les autres
  périphériques USB, comme les claviers et les souris, peuvent continuer à
  fonctionner.
- Le mot de passe n’est pas enregistré dans les fichiers du projet. La variable
  d’environnement reste accessible à votre compte Windows et ne protège pas
  contre une personne ayant accès à cette session.
- Pour déverrouiller le stockage USB, choisissez l’option `2`.
