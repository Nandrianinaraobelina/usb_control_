# Fifehezana ny fitahirizana USB

Ity tetikasa ity dia misy rakitra Windows iray, `usb_control.bat`, izay
ahafahana manidy na manokatra indray ny fitaovana fitahirizana USB.

## Sary

![Menu fifehezana ny USB](usb-control-menu.png)

## Fampiasana

1. Mamoròna environment variable `USB_CONTROL_PASSWORD` ao amin'ny kaontinao
   Windows, ary apetraho ao ny tenimiafina tianao hampiasaina.
2. Akatòny ary sokafy indray ny terminal na ny session Windows mba hampiharana
   ilay variable.
3. Alefaso ny `usb_control.bat`. Hangataka ho azy ny alalana ho mpitantana
   amin'ny alalan'ny Windows (UAC) ilay rakitra. Raha lavinao na nofoananao
   ilay fangatahana, dia hampiseho hafatra mazava ilay script.
4. Jereo aloha ny sata ankehitriny asehon'ny script. Avy eo safidio ny safidy
   ao amin'ny menu:
   - `1` hanidy ny fitahirizana USB;
   - `2` hanokatra indray azy.
5. Ampidiro ilay tenimiafina napetraka. Tsy hiseho eo amin'ny efijery ny
   soratra rehefa manoratra azy ianao.
6. Soraty `ENY` raha hanamafy ny fanovana ao amin'ny rejisitra Windows.

Manova ny sanda `Start` an'ny service Windows `USBSTOR` ilay script. Ilaina ny
alalana ho mpitantana, ary hangatahana ho azy izany.

## Fanamarihana

- Ny fitaovana fitahirizana USB ihany no voakasiky ny fanidiana; mety mbola
  hiasa ny fitaovana USB hafa toy ny klavier sy ny souris.
- Tsy voatahiry ao amin'ny rakitra tetikasa ny tenimiafina. Azo vakin'ny
  kaontinao Windows ilay environment variable, ka tsy fiarovana amin'ny olona
  afaka mampiasa io kaonty io izany.
- Raha hanokatra indray ny fitahirizana USB, safidio ny `2`.
