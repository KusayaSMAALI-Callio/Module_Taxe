codeunit 50251 "CAGTX_Copy Item Taxes"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        NoSeries: record "No. Series";
        Assert: Codeunit Assert;
        LibraryInvent: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        TaxHelpers: Codeunit "CAGTX_Tax Helpers";
        PermissionTestMgt: Codeunit "CAGTX_Permission Test Mgt";
        RandItemNo: Code[20];
        TaxLastValue: Boolean;
        IsFirstInvoke: Boolean;
        TaxNotCopyErrorLbl: Label 'At list one tax was not copy.', Locked = true;
        TargetItemTaxesCountErrorLbl: Label 'The number of item taxes are not equal.', Locked = true;
        RelatedItemTaxesErrorLbl: Label 'LockedNo Item Taxes found related to target item.', Locked = true;
        FieldCopyCheckValueErrorLbl: Label 'Field %1 was copy with the wrong value. Expected %2 - result %3', Locked = true;
        IncludeTaxesVisibleErrorLbl: Label 'IncludeTaxes was not visible in CopyItem page', Locked = true;
        IncludeTaxesSaveValueErrorLbl: Label 'Include taxes value should be same as the last execution.', Locked = true;


    [test]
    [HandlerFunctions('CopyItemHandler')]
    procedure TestCopySingleTax()
    var
        Item: record Item;
        Tax: Record CAGTX_Tax;
        SourceItemTaxes: Record "CAGTX_Item Tax V2";
        TargetItemTaxes: Record "CAGTX_Item Tax V2";
        ItemCard: TestPage "Item Card";
    begin
        // [FEATURES] [Copy Item Taxe]
        // [SCENARIO] Test de copie des taxes d'un article

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // [GIVEN] Création article et taxes
        LibraryInvent.CreateItem(Item);
        TaxHelpers.CreateTax(Tax, CopyStr(LibraryRandom.RandText(100), 1, 100));
        TaxHelpers.CreateItemTax(SourceItemTaxes, Tax, Item);
        TaxHelpers.CreateTax(Tax, CopyStr(LibraryRandom.RandText(100), 1, 100));
        TaxHelpers.CreateItemTax(SourceItemTaxes, Tax, Item);

        // [WHEN] Ouverture de la fiche article puis appuie sur le bouton copie article
        ItemCard.OpenView();
        ItemCard.GoToRecord(Item);
        ItemCard.CopyItem.Invoke();
        ItemCard.Close();

        // [THEN]
        SourceItemTaxes.Reset();
        SourceItemTaxes.SetRange(Type, SourceItemTaxes.Type::Item);
        SourceItemTaxes.SetRange("No.", Item."No.");
        if SourceItemTaxes.FindSet() then
            repeat
                Assert.IsTrue(TargetItemTaxes.Get(TargetItemTaxes.Type::Item, SourceItemTaxes."Tax Code", RandItemNo, SourceItemTaxes."Item Category Code",
                SourceItemTaxes."Product Group Code", SourceItemTaxes."Variant Code", SourceItemTaxes."Effective Date", SourceItemTaxes."Unit of Measure Code",
                SourceItemTaxes."Minimum Quantity"), TaxNotCopyErrorLbl);
            until SourceItemTaxes.Next() = 0
        else
            error(RelatedItemTaxesErrorLbl);

        TargetItemTaxes.Reset();
        TargetItemTaxes.SetRange(Type, TargetItemTaxes.Type::Item);
        TargetItemTaxes.SetRange("No.", RandItemNo);
        Assert.AreEqual(SourceItemTaxes.Count(), TargetItemTaxes.Count(), TargetItemTaxesCountErrorLbl);
    end;

    [test]
    [HandlerFunctions('CopyMultiItem')]
    procedure TestCopyTaxesOnMultiItem()
    var
        Item: record Item;
        Tax: Record CAGTX_Tax;
        SourceItemTaxes: Record "CAGTX_Item Tax V2";
        TargetItemTaxes: Record "CAGTX_Item Tax V2";
        ItemCard: TestPage "Item Card";
        StartSerialCode: Code[20];
        EndSerialCode: Code[20];
    begin
        // [FEATURES] [Copy Item Taxe]
        // [SCENARIO] Test de copie des taxes d'un article

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // [GIVEN] Création d'article et taxes et affectation taxe sur article.
        NoSeries.Get(LibraryERM.CreateNoSeriesCode());
        StartSerialCode := TaxHelpers.GetLastSerialNo(NoSeries);

        LibraryInvent.CreateItem(Item);
        TaxHelpers.CreateTax(Tax, CopyStr(LibraryRandom.RandText(100), 1, 100));
        TaxHelpers.CreateItemTax(SourceItemTaxes, Tax, Item);
        TaxHelpers.CreateTax(Tax, CopyStr(LibraryRandom.RandText(100), 1, 100));
        TaxHelpers.CreateItemTax(SourceItemTaxes, Tax, Item);

        Commit();

        // [WHEN] ouverture de la fiche article et copie 
        ItemCard.OpenView();
        ItemCard.GoToRecord(Item);
        ItemCard.CopyItem.Invoke();
        ItemCard.Close();

        // [WHEN] préparation du n° de souche 
        EndSerialCode := TaxHelpers.GetLastSerialNo(NoSeries);
        SourceItemTaxes.Reset();
        SourceItemTaxes.SetRange(Type, SourceItemTaxes.Type::Item);
        SourceItemTaxes.SetRange("No.", Item."No.");

        // [THEN] comparaisons des valeurs entre article original et celui copié
        If SourceItemTaxes.Findset() then
            repeat
                TargetItemTaxes.Reset();
                TargetItemTaxes.SetRange(Type, TargetItemTaxes.Type::Item);
                TargetItemTaxes.SetRange("Tax Code", SourceItemTaxes."Tax Code");
                TargetItemTaxes.SetRange("No.", StartSerialCode, EndSerialCode);
                if TargetItemTaxes.FindSet() then
                    repeat
                        Assert.IsTrue(TargetItemTaxes."Rate Type" = SourceItemTaxes."Rate Type", StrSubstNo(FieldCopyCheckValueErrorLbl, TargetItemTaxes.FieldCaption("Rate Type"), SourceItemTaxes."Rate Type", TargetItemTaxes."Rate Type"));
                        Assert.IsTrue(TargetItemTaxes."Rate Value" = SourceItemTaxes."Rate Value", StrSubstNo(FieldCopyCheckValueErrorLbl, TargetItemTaxes.FieldCaption("Rate Value"), SourceItemTaxes."Rate Value", TargetItemTaxes."Rate Value"));
                        Assert.IsTrue(TargetItemTaxes."Item Category Code" = SourceItemTaxes."Item Category Code", StrSubstNo(FieldCopyCheckValueErrorLbl, TargetItemTaxes.FieldCaption("Item Category Code"), SourceItemTaxes."Item Category Code", TargetItemTaxes."Item Category Code"));
                        Assert.IsTrue(TargetItemTaxes."Product Group Code" = SourceItemTaxes."Product Group Code", StrSubstNo(FieldCopyCheckValueErrorLbl, TargetItemTaxes.FieldCaption("Product Group Code"), SourceItemTaxes."Product Group Code", TargetItemTaxes."Product Group Code"));
                        Assert.IsTrue(TargetItemTaxes."Effective Date" = SourceItemTaxes."Effective Date", StrSubstNo(FieldCopyCheckValueErrorLbl, TargetItemTaxes.FieldCaption("Effective Date"), SourceItemTaxes."Effective Date", TargetItemTaxes."Effective Date"));
                        Assert.IsTrue(TargetItemTaxes.Description = SourceItemTaxes.Description, StrSubstNo(FieldCopyCheckValueErrorLbl, TargetItemTaxes.FieldCaption(Description), SourceItemTaxes.Description, TargetItemTaxes.Description));
                        Assert.IsTrue(TargetItemTaxes."Minimum Quantity" = SourceItemTaxes."Minimum Quantity", StrSubstNo(FieldCopyCheckValueErrorLbl, TargetItemTaxes.FieldCaption("Minimum Quantity"), SourceItemTaxes."Minimum Quantity", TargetItemTaxes."Minimum Quantity"));
                        Assert.IsTrue(TargetItemTaxes."Unit of Measure Code" = SourceItemTaxes."Unit of Measure Code", StrSubstNo(FieldCopyCheckValueErrorLbl, TargetItemTaxes.FieldCaption("Unit of Measure Code"), SourceItemTaxes."Unit of Measure Code", TargetItemTaxes."Unit of Measure Code"));
                        Assert.IsTrue(TargetItemTaxes."Variant Code" = SourceItemTaxes."Variant Code", StrSubstNo(FieldCopyCheckValueErrorLbl, TargetItemTaxes.FieldCaption("Variant Code"), SourceItemTaxes."Variant Code", TargetItemTaxes."Variant Code"));
                    until TargetItemTaxes.Next() = 0;

            until SourceItemTaxes.Next() = 0;
        TargetItemTaxes.Reset();
        TargetItemTaxes.SetRange(Type, TargetItemTaxes.Type::Item);
        TargetItemTaxes.SetRange("Tax Code", SourceItemTaxes."Tax Code");
        TargetItemTaxes.SetRange("No.", StartSerialCode, EndSerialCode);
        Assert.AreEqual(SourceItemTaxes.Count() * (TargetItemTaxes.Count() / 2), TargetItemTaxes.Count(), TargetItemTaxesCountErrorLbl);
    end;

    [test]
    [HandlerFunctions('CopyItem3')]
    procedure TestTaxCheckBoxVisibilityInCopyItem()
    var
        Item: record Item;
        Tax: Record CAGTX_Tax;
        SourceItemTaxes: Record "CAGTX_Item Tax V2";
        ItemCard: TestPage "Item Card";
    begin
        // [FEATURES] [Copy Item Taxe]
        // [SCENARIO] Test de copie des taxes et vérification de la visibilité du bouton

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // [GIVEN] article et taxe créé
        LibraryInvent.CreateItem(Item);
        TaxHelpers.CreateTax(Tax, CopyStr(LibraryRandom.RandText(100), 1, 100));
        TaxHelpers.CreateItemTax(SourceItemTaxes, Tax, Item);
        TaxHelpers.CreateTax(Tax, CopyStr(LibraryRandom.RandText(100), 1, 100));
        TaxHelpers.CreateItemTax(SourceItemTaxes, Tax, Item);
        IsFirstInvoke := false;

        // [WHEN] ouverture de la fiche article et copie
        ItemCard.OpenView();
        ItemCard.GoToRecord(Item);
        ItemCard.CopyItem.Invoke();
        ItemCard.Close();
        Commit();

        // [THEN] réouverture et copie article
        NoSeries.Reset();
        ItemCard.OpenView();
        ItemCard.GoToRecord(Item);
        ItemCard.CopyItem.Invoke();
        ItemCard.Close();
    end;

    [ModalPageHandler]
    procedure CopyItemHandler(var CopyItem: TestPage "Copy Item")
    begin
        RandItemNo := TaxHelpers.getRandomTargetItemNo();
        CopyItem.TargetItemNo.SetValue(RandItemNo);
        CopyItem.GeneralItemInformation.SetValue(true);
        CopyItem.CAGTX_IncludeTaxes.SetValue(true);
        CopyItem.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CopyMultiItem(var CopyItem: TestPage "Copy Item")
    begin
        CopyItem.TargetItemNo.SetValue('');
        CopyItem.GeneralItemInformation.SetValue(true);
        CopyItem.CAGTX_IncludeTaxes.SetValue(true);
        CopyItem.TargetNoSeries.SetValue(NoSeries);
        CopyItem.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CopyItem3(var CopyItem: TestPage "Copy Item")
    begin
        RandItemNo := TaxHelpers.getRandomTargetItemNo();
        CopyItem.TargetItemNo.SetValue(RandItemNo);
        CopyItem.GeneralItemInformation.SetValue(true);
        Assert.IsTrue(CopyItem.CAGTX_IncludeTaxes.Visible(), IncludeTaxesVisibleErrorLbl);

        if not IsFirstInvoke then begin
            TaxLastValue := not CopyItem.CAGTX_IncludeTaxes.AsBoolean();
            CopyItem.CAGTX_IncludeTaxes.SetValue(TaxLastValue);
            IsFirstInvoke := true;
        end else
            Assert.IsTrue(TaxLastValue = CopyItem.CAGTX_IncludeTaxes.AsBoolean(), IncludeTaxesSaveValueErrorLbl);
        CopyItem.OK().Invoke();
    end;
}