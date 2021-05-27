# Formatplus
Ce script permet de formater des disques USB en FAT 32.

Ce script peut fonctionner de deux manières :
* 1 - En mode interactif (c'est le mode par défaut).
* 2 - En mode non interactif (avec l'option -d sd...)
 
Le script doit être lancé en tant que ROOT !                                                 
                                                  
Options:                                          
*    -h    : Aide.
*    -v    : Affiche la version du script.
*    -l    : Ajoute le formatage long du disque.
* -d <sdX> : Permet de passer en argument le nom du disque exemple : sda, sdb...

Usage: ./formatplus.sh -[l|h|v] -d sd...                                            
