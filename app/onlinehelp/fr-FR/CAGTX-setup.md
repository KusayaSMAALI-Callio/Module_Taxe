---
title: Paramétrer le module de gestion des taxes | Microsoft Docs
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
# Paramétrer le module de gestion des taxes

## Définir les paramètres généraux

Pour définir les paramètres généraux, suivez les étapes suivantes :

1. Choisissez l'icône ![Lightbulb that opens the Tell Me feature](media/ui-search/search_small.png "Tell me what you want to do") , saisissez **Taxes** , puis sélectionnez le lien associé.
2. Renseignez les champs selon vos besoins.

**Onglet Général**

| Champs                       | Description                                                  |
| ---------------------------- | ------------------------------------------------------------ |
| Code                         | Code de la taxe                                              |
| Désignation                  | Description de la taxe.<br />*Ce champ n’est pas repris dans le champ désignation dans les lignes de documents de vente ou d’achat.* |
| Type de calcul               | Ce paramètre a pour objectif de définir la manière dont sera calculée la taxe associée.<br />Ligne : Dans ce cas, à chaque ligne du document éligible sera ajoutée une ligne de taxe associée.<br />Total : Une seule ligne de taxe sera calculée pour l’ensemble des lignes du document. |
| Type valeur par défaut       | Ce paramètre permet de définir un type de valeur par défaut.<br />- **Valeur unitaire** :<br />-- Si le Type de calcul = Ligne, le système calcule la ligne de frais en multipliant la quantité de la ligne achat ou vente (qté commandée) avec la valeur de la taxe <br />-- Si le Type de calcul = Total, le système calcule la ligne de frais en multipliant la somme des quantités des lignes du document concernées par cette taxe, avec la valeur de la taxe.<br />- **Pourcentage :**<br />-- Le système calcule la ligne de frais en appliquant le pourcentage de la taxe sur le montant HT de la ligne<br />- **Valeur forfaitaire: **<br />-- Le système calcule la ligne de frais en appliquant simplement la valeur forfaitaire paramétrée (la quantité sera forcée à 1 dans la ligne de taxe). Il peut être utilisé pour une application au document mais aussi à la ligne.<br />⚠ **La validation du champ « Type valeur par défaut » modifiera le champ « Type Valeur » de l’ensemble des affectations articles associées à la taxe en cours de paramétrage**. |
| Valeur par défaut            | La valeur par défaut est exprimé en fonction du type de valeur par défaut.<br />⚠ **Pour les champs « Valeur unitaire » et « Valeur Forfaitaire », la valeur sera exprimé en devise société HT.**<br />*La validation du champ « Valeur par défaut » modifiera le champ « Valeur » de l’ensemble des affectations articles associées à la taxe en cours de paramétrage.* |
| Taxe appliquée sur le TTC    | Sera utilisé dans le cas ou la taxe s’applique après le calcul de la TVA.<br />⚠ **Attention, le paramétrage du compte devra être HT, afin de ne pas ajouter de la TVA sur un TTC.** |
| Remise facture autorisée     | La taxe est prise en compte dans le calcul de la remise facture. |
| Appliquée sur montant remisé | La taxe sera calculée sur le montant remisé.                 |
| Option d'application         | Définition de la date qui sera prise en compte lors de l’application de la taxe : <br />Les valeurs possibles sont : <br />- Date de comptabilisation<br />- Date de document<br />- Date de commande |
| Option de validation         | L’objectif de cette option est  de piloter la manière dont seront comptabilisées les taxes lors du processus  de facturation.    Dans BC, vous ne pouvez pas facturer ce qui n’a pas été expédié ou reçu. Par  conséquent, cette option pilote l’expédition ou la réception d’une taxe en  fonction de 3 options :<br />  -   **Première** :  l’ensemble de la ligne de taxe sera expédié (ou reçu) lors de la    première expédition  (ou réception) de la ligne vente concernée par la taxe  <br />-     **Prorata** :  La ligne de taxe sera expédié au prorata de la quantité expédié de la ligne  vente pour laquelle la ligne taxe est calculée.  <br />-     **Dernière** :  l’ensemble de la ligne de taxe sera expédié (ou reçu) lors de la dernière  expédition (ou réception) de la ligne vente pour laquelle la ligne taxe est  calculée.<br /> ⚠ **L’option Prorata sera incompatible avec les taxes dont le type de calcul sera égal à total**.<br/>⚠ **L’option Dernière avec le type de calcul total sera incompatible avec l’utilisation des frais annexes.** |
| Afficher les lignes          | Ce paramètre permet l’affichage de la taxe dans les documents ventes ou achat.<br /> ⚠ **Un bouton permettra de consulter l’ensemble des taxes visibles ou non dans les documents.** |

**Onglet Affectation**

| Champs              | Description                                                  |
| ------------------- | ------------------------------------------------------------ |
| Type compte vente   | Définition du type de compte utilisé lors de la création de la taxe sur les documents de vente.<br />⚠ **Si ce paramètre n’est pas défini alors la taxe ne sera pas active dans les documents de vente**.<br />Les valeurs possibles sont : <br />\-    Compte général<br />\-    Ressource<br />-    Frais annexe |
| N° compte vente     | Définir le N° correspondant au type de compte vente sélectionné précédemment.<br />⚠ **La description du référentiel sélectionné sera utilisée dans le champ description des lignes de taxes insérées dans le document.** |
| Type compte achat   | Définition du type de compte utilisé lors de la création de la taxe sur les documents de vente.<br />⚠ **Si ce paramètre n’est pas défini alors la taxe ne sera pas active dans les documents de vente**.<br />Les valeurs possibles sont : <br />\-    Compte général<br />-    Frais annexe |
| N° compte achat     | Définir le N° correspondant au type de compte achat sélectionné précédemment.<br />⚠ **La description du référentiel sélectionné sera utilisée dans le champ description des lignes de taxes insérées dans le document.** |
| Type compte service | Définition du type de compte utilisé lors de la création de la taxe sur les documents de vente.<br />⚠ **Si ce paramètre n’est pas défini alors la taxe ne sera pas active dans les documents de vente**.<br />Les valeurs possibles sont : <br />\-    Compte général<br />\-    Ressource |
| N° compte service   | Définir le N° correspondant au type de compte service sélectionné précédemment.<br />⚠ **La description du référentiel sélectionné sera utilisée dans le champ description des lignes de taxes insérées dans le document**. |

**Onglet Etats**

| Champs                  | Description                                                  |
| ----------------------- | ------------------------------------------------------------ |
| Afficher sur commande   | Option permettant l’affichage des taxes sur les documents de type commande ou retour (vente ou achat).<br />⚠ **Ce paramètre devra être utilisé dans les développements des états associés du client.** |
| Afficher sur expédition | Option permettant l’affichage des taxes sur les documents d’expédition ou de réception (vente ou achat).<br />⚠ **Ce paramètre devra être utilisé dans les développements des états  associés du client.** |

## Paramétrer l'affectation des tiers aux taxes

Il faut définir les tiers (Client / Fournisseur) qui seront concernés par la taxe.

Pour les définir, suivez les étapes suivantes :

1. Se positionner dans la fiche souhaitée, puis :
2. Cliquer sur *Affectation taxe aux tiers* dans le ruban.

| Champ          | Description                                                  |
| -------------- | ------------------------------------------------------------ |
| Code taxe      | Code taxe à paramétrer.                                      |
| Lié à la table | Ce paramètre définit le type de tiers à paramétrer Client ou Fournisseur. |
| Type           | Ce paramètre permet de définir sélectivité de la taxe.<br/>Les valeurs possibles sont : <br />-	Tiers (Client ou fournisseur)<br/>-	Groupe Compta (Client ou fournisseur)<br/>-	Tous |
| N°             | Définir le N° correspondant au type de tiers sélectionné précédemment.<br />⚠ **Si l’option tous est paramétré alors il ne sera pas possible de saisir un N°.** |
| Désignation    | La désignation liée au n° sélectionné apparait automatiquement. |

## Paramétrer l'affectation des taxes

Il faut définir les types de ligne de document (Article, Ressource, Compte Général) qui seront concernés par la taxe.

Pour qu’une taxe puisse être appliquée, il faudra paramétrer sur quelle ressource (article, ressource, compte général) devra être calculée la taxe.

Pour les définir, suivez les étapes suivantes :

1. Se positionner dans la fiche souhaitée, puis :
2. Cliquer sur *Affectation taxe* dans le ruban.

| Champ                  | Description                                                  |
| ---------------------- | ------------------------------------------------------------ |
| Code taxe              | Code taxe à paramétrer.                                      |
| Désignation            | Désignation de la taxe.                                      |
| Type                   | Ce paramètre permet de définir sélectivité de la taxe.<br/>Les valeurs possibles sont : <br />-	Article<br/>-	Resource<br/>-	Compte général |
| N°                     | Définir le N° correspondant au type sélectionné précédemment.<br />⚠ **Si l’option article est paramétrée, il sera possible de laisser ce champ à vide. Dans ce cas, la taxe sera applicable à l’ensemble des articles, ce principe n'est valable que pour les articles.** |
| Code variante          | Définir le code variante associé au N° d’article précédemment sélectionné. |
| Code catégorie article | Définir un code catégorie article que si le N° article n’est pas spécifié. |
| Date effet             | Permet de définir une date à partir de laquelle la taxe sera active, elle sera appliquée à la date définie dans le paramétrage général de la taxe. |
| Code unité             | Associé à la quantité ce paramètre permet de définir la quantité d’unité à partir de laquelle la taxe est applicable.<br />⚠ **Le code unité ne pourra être saisi que si un numéro est spécifié.** |
| Quantité minimum       | Associée au code unité ce paramètre permet de définir la quantité d’unité à partir de laquelle la taxe est applicable.<br />⚠ **La quantité ne pourra être saisie que si une unité est spécifiée.** |
| Type valeur            | Ce paramètre permet de définir un type de valeur. <br/>Les valeurs possibles sont : <br />-	Valeur unitaire<br/>-	Pourcentage<br/>-	Valeur forfaitaire<br />⚠ **Cette valeur est modifiable dans le cas ou la case « Désynchroniser type de valeur » figurant dans le ruban est cochée.** |
| Valeur                 | Valeur par défaut exprimé en fonction du type de valeur par défaut.<br />⚠ **Pour les champs « Valeur unitaire » et « Valeur Forfaitaire », la valeur sera exprimée en devise société HT.** |

**Note** : 

- Désynchroniser type de valeur : Permet la définition de valeurs différentes dans les lignes d’affectation taxe avec celle définie au niveau de la taxe. Ce principe peut être utile dans le cas d’une gestion quantitative, la première ligne peut être au forfait, les suivantes en valeur ou pourcentage en fonction des quantités.

## Affectation des taxes aux articles

Dans la **Fiche article**, un raccourci **Affectation taxes** est ajouté : il permet de consulter les paramétrages de taxe pour l'article en cours. 

**Business Central** propose une fonction de duplication d'article. Cette fonction a été modifiée afin de permettre la duplication du paramétrage des taxes.

Pour copier un article en dupliquant le paramétrage des taxes :

1. Lancer le [traitement de duplication d'article](https://docs.microsoft.com/fr-fr/dynamics365/business-central/inventory-how-copy-items).
2. Afin de dupliquer le paramétrage des taxes de l'article d'origine vers le nouvel article, cocher le champ **Taxes** dans le raccourci **Taxes**.

## Voir aussi

[Aperçu du module de gestion des taxes](CAGTX-overview.md)     
[Utilisation des taxes dans les documents](CAGTX-tax-in-documents.md)   
[Utilisation de Business Central](https://docs.microsoft.com/fr-FR/dynamics365/business-central/ui-work-product)