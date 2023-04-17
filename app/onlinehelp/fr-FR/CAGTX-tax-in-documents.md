---
title: Utiliser les taxes dans les documents | Microsoft Docs
description: Describes how to set up each customer’s preferred method of sending sales documents, for example, email, PDF, electronic document, and so on.
services: project-madeira
documentationcenter: ''
author: SorenGP
ms.service: dynamics365-business-central
ms.topic: article
ms.devlang: na
ms.tgt_pltfrm: na
ms.workload: na
ms.search.keywords: email, PDF, electronic document
ms.date: 04/01/2019
ms.author: sgroespe

---
# Utiliser les taxes dans les documents

## Saisie d'un document

Nous prendrons comme exemple une commande de vente, le principe étant le même pour les documents d'achats et de services.

Pour enregistrer *une commande de vente*, suivez les étapes suivantes :

1. Choisissez l'icône ![Lightbulb that opens the Tell Me feature](media/ui-search/search_small.png "Tell me what you want to do") , saisissez **Commandes vente** , puis sélectionnez le lien associé.
2. Sélectionner la fonction **+ Nouveau** à partir de la liste des commandes vente.

La saisie n'est pas différente d'une saisie standard de BC, elle ne sera pas détaillée. Il faut juste que vous utilisiez un client et un article, prévus dans le paramétrage de la taxe.

⚠ ***La fonction de gestion des acomptes n’est pas compatible avec la gestion des taxes.***

## Lancer le document

Le lancement du document génèrera la ou les lignes de taxe précédemment paramétrées.

Pour lancer, suivez les étapes suivantes :

1. Se positionner dans la fiche souhaitée, puis :
2. Cliquer sur *Lancer* dans le ruban.
3. Puis cliquer *Lancer*.

Vous devez voir apparaître la ou les lignes de taxes dans la grille de votre document.

**Note** : 

- La mise à jour s’effectue à partir de 3 actions :

  \-    Le lancer manuel du document ou en utilisant le bouton *Mise à jour des taxes* dans le ruban *Traitement*.

  \-    L’expédition ou la réception du document alors que le document n’est pas lancé.

  \-    La facturation.

- Calcul des taxes :

  \-    Ligne : Les taxes calculées à la ligne seront placées en dessous de chaque ligne à partir de laquelle la taxe est calculée. A noter que ces lignes seront indentées pour améliorer la visibilité.

  \-    Total : Les taxes calculées à la ligne seront placé à la suite du document.

## Détail des lignes de taxe

Il est possible de consulter les lignes de taxe du document.

Pour cela, suivez les étapes suivantes :

1. Se positionner dans la fiche souhaitée, puis :
2. Cliquer sur *Traitement* dans le ruban.
3. Puis cliquer *Ligne taxes*.

Les différentes lignes de taxe apparaissent, pour justifier le calcul de la taxe, avec les information ci-dessous :

| Champ              | Description                                                  |
| ------------------ | ------------------------------------------------------------ |
| Code taxe          | Code taxe défini dans le paramétrage de la taxe.             |
| Type               | Type défini dans le paramétrage de la taxe.                  |
| N°                 | N° défini dans le paramétrage de la taxe.                    |
| Description        | Description lié au champ N°.                                 |
| Quantité           | Dépend du paramétrage de la taxe.                            |
| Prix unitaire HT   | Montant unitaire de la taxe calculée avant arrondi.          |
| Montant            | Montant ligne arrondi (quantité * Prix unitaire HT)          |
| Montant TTC        | Montant TTC de la ligne                                      |
| Ligne taxe origine | N° de la ligne du document à l'origine du calcul de la taxe. |

**Notes** : 

- <u>Affectation frais annexes</u> :

  \-    Le traitement de mise à jour des taxes effectue automatiquement une *Affectation des frais annexes*.
  
  Dans le cas où **Type de calcul = Total**, la répartition des frais annexes proposée, est fonction du "Type valeur par défaut" :
  
  ​		Si **Type valeur par défaut** = **Valeur unitaire**, alors la répartition de la ligne de frais annexe se fait au prorata de la quantité de chaque ligne d’article concernée par la taxe.
  
  ​		Si **Type valeur par défaut** = **Pourcentage**, alors la répartition de la ligne de frais annexe se fait au prorata du montant HT de chaque ligne d’article concernée par la taxe.
  
  \-    Vous pouvez utiliser le bouton *Affectation frais annexes* dans le ruban pour modifier cette affectation par défaut.
  
  
  
- <u>Quantité</u> : 

  La quantité de la ligne de taxe dépend du paramétrage de cette taxe :

  - Si **Type de calcul = Total ou Ligne** et **Type valeur par défaut** = **Valeur forfaitaire**, la Quantité est égale à 1.
  - Si **Type de calcul = Total** et **Type valeur par défaut** = **Pourcentage**, la Quantité est égale à 1.
  - Si **Type de calcul = Total** et **Type valeur par défaut** = **Valeur unitaire**, la Quantité est égale à la somme des quantités des lignes du document correspondant à cette taxe.
  - Si **Type de calcul = Ligne** et **Type valeur par défaut** = **Pourcentage ou Valeur unitaire**, la Quantité est égale à la quantité de la ligne du document à partir de laquelle la taxe est calculée.

## Autres informations

1. Expédition et facturation des taxes : 

   Le standard BC impose qu’une ligne de document doit être expédiée ou reçue avant d’être facturée. Cette règle de gestion justifie à elle seule l’option de validation des taxes dans le paramétrage.

- Première : La ligne de taxe concernée par ce paramétrage sera expédiée ou reçue dès la première expédition de la ligne de document à partir de laquelle la taxe est calculée.
- Prorata : La ligne de taxe concernée par ce paramétrage sera expédiée ou reçue au prorata de la ligne de document à partir de laquelle la taxe est calculée.
  - ⚠ Cette option ne concerne pas les taxes calculées sur total.
- Dernière : La ligne de taxe concernée par ce paramétrage sera expédiée ou reçue lorsque la ligne de document, à partir de laquelle la taxe est calculée, est entièrement expédiée.

2. Impact de la facturation sur la mise à jour des taxes :

   Une taxe facturée partiellement ou totalement ne sera plus mise à jour par le traitement de calcul des taxes. La mise à jour sera donc à réaliser manuellement.

    Lors de la facturation, une taxe issue du traitement d’extraction des expéditions ou des réceptions ne sera pas mise à jour par le traitement de calcul des taxes.

## Voir aussi

[Aperçu du module Taxes](CAGTX-overview.md)   
[Paramétrer le module de taxes](CAGTX-setup.md)   
[Utilisation de Business Central](https://docs.microsoft.com/fr-FR/dynamics365/business-central/ui-work-product)