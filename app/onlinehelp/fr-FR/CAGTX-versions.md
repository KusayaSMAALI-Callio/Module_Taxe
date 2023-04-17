---
5688title: Historique des versions | Groupe Calliope Docs
description: Shows the version history for the app.
services: calliopacks
documentationcenter: ''
author: fecarnot

ms.service: dynamics365-business-central
ms.topic: na
ms.devlang: na
ms.tgt_pltfrm: na
ms.workload: na
ms.search.keywords: na
ms.date: 03/29/2021
ms.author: fecarnot

---
# Historique des versions

## Mise à jour 19.2 

Disponibilité : Janvier 2023.       
Versions Dynamics 365 Business Central : de 19.4 à 22.X .

Les problèmes suivants sont résolus dans cette mise à jour  :

| ID    | Titre                                                        |
| ----- | ------------------------------------------------------------ |
| 10726 | Avec une taxe calculée au prorata, le fait d'ouvrir et relancer un document augmente la quantité de la ligne de taxe de manière erronée. |
| 11167 | Il est impossible de passer par des flux standards pour corriger une facture de vente enregistrée contenant des lignes de taxe. La fonction **Copie document** a été corrigée afin de permettre la copie d'un document contenant des lignes de taxe. |

## Mise à jour 19.1 

Disponibilité : Décembre 2022.       
Versions Dynamics 365 Business Central : de 16.2 à 19.X .

La modification technique suivante a été ajoutée dans cette mise à jour  :

| ID    | Titre                                                        |
| ----- | ------------------------------------------------------------ |
| 10343 | Des évènements techniques (**Events**) sont ajoutés dans le code. Ces évènements sont les suivants :<br/>**OnAfterModifyTaxQtyToPostLine** (codeunit **CAGTX_Purch. Tax Management**)<br/>**OnAfterModifyTaxQtyToPostLine** (codeunit **CAGTX_Sales. Tax Management**) |

## Mise à jour 19.0 

Disponibilité : Avril 2022.       
Versions Dynamics 365 Business Central : de 19.4 à 20.X .
Version précédente : 16.3

## Mise à jour 16.5 

Disponibilité : Janvier 2023.       
Versions Dynamics 365 Business Central : de 16.2 à 19.X .

Les problèmes suivants sont résolus dans cette mise à jour  :

| ID    | Titre                                                        |
| ----- | ------------------------------------------------------------ |
| 10726 | Avec une taxe calculée au prorata, le fait d'ouvrir et relancer un document augmente la quantité de la ligne de taxe de manière erronée. |
| 11167 | Il est impossible de passer par des flux standards pour corriger une facture de vente enregistrée contenant des lignes de taxe. La fonction **Copie document** a été corrigée afin de permettre la copie d'un document contenant des lignes de taxe. |

## Mise à jour 16.4 

Disponibilité : Décembre 2022.       
Versions Dynamics 365 Business Central : de 16.2 à 19.X .

La modification technique suivante a été ajoutée dans cette mise à jour  :

| ID    | Titre                                                        |
| ----- | ------------------------------------------------------------ |
| 10343 | Des évènements techniques (**Events**) sont ajoutés dans le code. Ces évènements sont les suivants :<br/>**OnAfterModifyTaxQtyToPostLine** (codeunit **CAGTX_Purch. Tax Management**)<br/>**OnAfterModifyTaxQtyToPostLine** (codeunit **CAGTX_Sales. Tax Management**) |

## Mise à jour 16.3 

Disponibilité : Mars 2022.       
Versions Dynamics 365 Business Central : de 16.2 à 19.X .

Les fonctionnalités suivantes sont ajoutées dans cette mise à jour  :

| ID   | Titre                                                        |
| ---- | ------------------------------------------------------------ |
| 7536 | Quand un article est copié, il est possible de demander la copie des données relatives aux taxes. |
| 7537 | Il est possible de consulter et de modifier le montant des taxes depuis la fiche article. |

## Mise à jour 16.2 

Disponibilité : Novembre 2021.       
Versions Dynamics 365 Business Central : de 16.2 à 19.X .

Les problèmes suivants sont résolus dans cette mise à jour  :

| ID   | Titre                                                        |
| ---- | ------------------------------------------------------------ |
| 6017 | Certains champs affichant des descriptions de ligne de document ne sont pas assez grands. |
| 6019 | Les champs "Product Group" sont rendus obsolètes dans certaines tables. |
| 6021 | Certains champs liés à la table Catégorie Article ne sont pas assez grands. |
| 3527 | Dans les articles taxes, le champ "Code catégorie article" est trop court. |
| 4257 | Quand une ligne de taxe est générée, elle ne porte pas sur le magasin de la ligne d'origine. Cela pose des soucis sur NAVAgri. |

