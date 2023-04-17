codeunit 50250 "CAGTX_Tax Helpers"
{
    var

        Assert: codeunit Assert;
        LibraryERM: codeunit "Library - ERM";
        LibraryRandom: codeunit "Library - Random";
        LibraryInventory: codeunit "Library - Inventory";
        LibrarySales: codeunit "Library - Sales";
        LibraryPurchase: codeunit "Library - Purchase";
        TaxCodeErr: Label 'Tax Code Expected ''%1'' is different than result : %2', Comment = '%1 is expected Tax Code and %2 is current result';
        TaxLineErr: Label 'Tax Line Expected ''%1'' is different than result : %2', Comment = '%1 is expected Tax Line and %2 is current result';
        OriginTaxCodeErr: Label 'Origin Tax Code Expected ''%1'' is different than result : %2', Comment = '%1 is expected Origin Tax Code and %2 is current result';
        TaxAmountErr: Label 'Tax Amount Expected ''%1'' is different than result : %2', Comment = '%1 is expected Tax Amount and %2 is current result';
        AmountInclVATErr: Label 'Amount Incl. VAT Expected ''%1'' is different than result : %2', Comment = '%1 is expected Amount Incl. VAT and %2 is current result';
        UnitPriceErr: Label 'Unit Price Expected ''%1'' is different than result : %2', Comment = '%1 is expected Unit Price and %2 is current result';
        DirectUnitCostErr: Label 'Direct Unit Cost Expected ''%1'' is different than result : %2', Comment = '%1 is expected Direct Unit Cost and %2 is current result';

    procedure CreateTax(var Tax: Record CAGTX_Tax; Description: Text[100])
    begin
        Tax.init();
        Tax.Code := Copystr(Description, 1, 10);
        Tax.Description := Description;
        Tax."Calcul Type" := Tax."Calcul Type"::Line;
        Tax."Default Rate Type" := Tax."Default Rate Type"::"Flat Rate";
        Tax."Default Rate Value" := 5;
        Tax.Insert();
    end;

    procedure DeleteExistingTax()
    var
        Tax: record CAGTX_Tax;
    begin
        Tax.DeleteAll(true);
    end;

    procedure CreateTax(var Tax: Record CAGTX_Tax; Description: Text[100]; CalculType: option Line,Total; AppliedOption: option "Posting Date","Document Date","Order Date"; DefaultRateType: option "Unit Amount",Percent,"Flat Rate"; DefaultRateValue: Integer)
    begin
        Tax.init();
        Tax.Code := Copystr(LibraryRandom.RandText(10), 1, MaxStrLen(Tax.Code));
        Tax.Description := Description;
        Tax."Calcul Type" := CalculType;
        Tax."Default Rate Type" := DefaultRateType;
        Tax."Default Rate Value" := DefaultRateValue;
        Tax."Applied Option" := AppliedOption;
        Tax.Insert();
    end;

    procedure CreateComplexeTax(var Tax: Record CAGTX_Tax; Description: Text[100]; CalculType: option Line,Total; AppliedOption: option "Posting Date","Document Date","Order Date"; DefaultRateType: option "Unit Amount",Percent,"Flat Rate"; DefaultRateValue: Integer; PostedOption: Option First,Last,Prorata; ServiceGLAccountNo: Code[20])
    begin
        Tax.init();
        Tax.Code := Copystr(LibraryRandom.RandText(10), 1, MaxStrLen(Tax.Code));
        Tax.Description := Description;
        Tax."Default Rate Type" := DefaultRateType;
        Tax."Default Rate Value" := DefaultRateValue;
        Tax."Service Account Type" := Tax."Service Account Type"::"G/L Account";
        Tax."Service Account No." := ServiceGLAccountNo;
        Tax."Show Line" := true;
        Tax."Applied Option" := AppliedOption;
        Tax."Posted Option" := PostedOption;
        Tax."Allow Invoice Disc." := true;
        Tax."Allow Line Disc." := true;
        Tax."Calcul Type" := CalculType;
        Tax.Insert();
    end;

    procedure CreateItemTax(var ItemTax: Record "CAGTX_Item Tax V2"; Tax: Record CAGTX_Tax; Item: Record Item)
    begin
        ItemTax.Init();
        ItemTax."Tax Code" := Tax.Code;
        ItemTax."No." := Item."No.";
        ItemTax."Rate Type" := ItemTax."Rate Type"::"Flat Rate";
        ItemTax."Rate Value" := 4;
        ItemTax.type := ItemTax.type::Item;
        ItemTax."Effective Date" := Today;
        ItemTax.Insert();
    end;

    procedure GetLastSerialNo(var NoSeries: record "No. Series"): Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.Reset();
        NoSeriesLine.SetRange("Series Code", NoSeries.Code);
        NoSeriesLine.FindFirst();
        if NoSeriesLine."Last No. Used" <> '' then
            exit(NoSeriesLine."Last No. Used")
        else
            exit(NoSeriesLine."Starting No.");
    end;

    procedure getRandomTargetItemNo(): Code[20]
    var
    begin
        exit(CopyStr(LibraryRandom.RandText(20), 1, 20));
    end;

    procedure CreateGLAccountWithSetup(var GLAccount: record "G/L Account"; Customer: record Customer; Item: record Item; GenPostingType: Enum "General Posting Type")
    var
        VATPostingSetup: record "VAT Posting Setup";
    begin
        If not VATPostingSetup.get(Customer."VAT Bus. Posting Group", Item."VAT Prod. Posting Group") then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, Customer."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        GLAccount.get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GenPostingType));
    end;

    procedure CreateGLAccountWithSetup(var GLAccount: record "G/L Account"; Vendor: record Vendor; Item: record Item; GenPostingType: Enum "General Posting Type")
    var
        VATPostingSetup: record "VAT Posting Setup";
    begin
        If not VATPostingSetup.get(Vendor."VAT Bus. Posting Group", Item."VAT Prod. Posting Group") then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, Vendor."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        GLAccount.get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GenPostingType));
    end;

    procedure SetAllPostingSetupForPost(Item: record Item; Customer: record Customer)
    var
        GenPostingSetup: record "General Posting Setup";
    begin
        LibraryERM.CreateGeneralPostingSetup(GenPostingSetup, '', Item."Gen. Prod. Posting Group");
        LibraryInventory.CreateItemWithPostingSetup(Item, '', GenPostingSetup."Gen. Bus. Posting Group");
    end;

    procedure CreateVATPostingSetup(var VATPostingSetup: record "VAT Posting Setup"; var Item: record Item; var Customer: record Customer)
    var
        VATProdPostingGroup: record "VAT Product Posting Group";
        VATBusPostingGroup: record "VAT Business Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup.Code);
        VATPostingSetup.Validate("VAT %", 20);
        VATPostingSetup.Modify();

        Item."VAT Prod. Posting Group" := VATProdPostingGroup.Code;
        Item.Modify();
        Customer."VAT Bus. Posting Group" := VATBusPostingGroup.Code;
        Customer.Modify();
    end;

    procedure CreateCustomerWithTax(var Customer: record Customer; var Tax: record CAGTX_Tax)
    var
        TaxAssgntoThird: record "CAGTX_Tax Assign. Third Party";
        ThirdPartType: Option "Third Party","Posting Group",All;
        LinkToTable: Option " ",Customer,Vendor;
    begin
        LibrarySales.CreateCustomer(Customer);
        TaxAssgntoThird.Init();
        TaxAssgntoThird."Tax Code" := Tax.Code;
        TaxAssgntoThird."Link to Table" := LinkToTable::Customer;
        TaxAssgntoThird.Type := ThirdPartType::"Third Party";
        TaxAssgntoThird."No." := Customer."No.";
        TaxAssgntoThird.Insert();
    end;

    procedure CreateVendorWithTax(var Vendor: record Vendor; var Tax: record CAGTX_Tax)
    var
        TaxAssgntoThird: record "CAGTX_Tax Assign. Third Party";
        ThirdPartType: Option "Third Party","Posting Group",All;
        LinkToTable: Option " ",Customer,Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        TaxAssgntoThird.Init();
        TaxAssgntoThird."Tax Code" := Tax.Code;
        TaxAssgntoThird.Type := ThirdPartType::"Third Party";
        TaxAssgntoThird."Link to Table" := LinkToTable::Vendor;
        TaxAssgntoThird."No." := Vendor."No.";
        TaxAssgntoThird.Insert();
    end;

    procedure CreateItemWithTax(var Item: record Item; var Tax: record CAGTX_Tax; RateType: Option "Unit Amount",Percent,"Flat Rate"; RateValue: integer)
    var
        ItemTax: record "CAGTX_Item Tax V2";
        TypeItemTax: Option " ","G/L Account",Item,Resource;
    begin
        LibraryInventory.CreateItem(Item);
        ItemTax.Init();
        ItemTax."Tax Code" := Tax.Code;
        ItemTax.Type := TypeItemTax::Item;
        ItemTax."No." := Item."No.";
        ItemTax."Variant Code" := '';
        ItemTax."Item Category Code" := '';
        ItemTax."Effective Date" := Calcdate('<-1d>', Today());
        ItemTax."Unit of Measure Code" := '';
        ItemTax."Minimum Quantity" := 1;
        ItemTax."Rate Type" := RateType;
        ItemTax."Rate Value" := RateValue;
        ItemTax.Insert();
    end;

    procedure CreateSalesLineWithNo(var SalesLine: record "Sales Line"; SalesHeader: record "Sales Header"; LineNo: Integer; Type: Enum "Sales Line Type"; No: code[20]; Quantity: Decimal; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Type := Type;
        SalesLine."No." := No;
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Modify(true);
    end;

    procedure CreateThirdPartyAndItemTax(var Customer: record Customer; var SOItem: record Item; var Tax: record CAGTX_Tax; var SalesGLAccount: record "G/L Account"; var PurchGLAccount: record "G/L Account"; DefaultRateType: option "Unit Amount",Percent,"Flat Rate"; RateValue: Integer)
    begin
        CreateCustomerWithTax(Customer, Tax);
        CreateItemWithTax(SOItem, Tax, DefaultRateType, RateValue);
        CreateGLAccountWithSetup(SalesGLAccount, Customer, SOItem, Enum::"General Posting Type"::Sale);
        CreateGLAccountWithSetup(PurchGLAccount, Customer, SOItem, Enum::"General Posting Type"::Purchase);
        SetSalesAndPurchaseAccountForTax(Tax, SalesGLAccount, PurchGLAccount);
    end;

    procedure CreateThirdPartyAndItemTax(var Vendor: record Vendor; var Item: record Item; var Tax: record CAGTX_Tax; var SalesGLAccount: record "G/L Account"; var PurchGLAccount: record "G/L Account"; DefaultRateType: option "Unit Amount",Percent,"Flat Rate"; RateValue: Integer)
    begin
        CreateVendorWithTax(Vendor, Tax);
        CreateItemWithTax(Item, Tax, DefaultRateType, RateValue);
        CreateGLAccountWithSetup(SalesGLAccount, Vendor, Item, Enum::"General Posting Type"::Sale);
        CreateGLAccountWithSetup(PurchGLAccount, Vendor, Item, Enum::"General Posting Type"::Purchase);
        SetSalesAndPurchaseAccountForTax(Tax, SalesGLAccount, PurchGLAccount);
    end;

    procedure SetSalesAndPurchaseAccountForTax(var Tax: Record CAGTX_Tax; SaleGLAccount: record "G/L Account"; PurchGLAccount: record "G/L Account")
    begin
        Tax."Sale Account Type" := Tax."Sale Account Type"::"G/L Account";
        Tax."Sale Account No." := SaleGLAccount."No.";
        Tax."Purch. Account Type" := Tax."Purch. Account Type"::"G/L Account";
        Tax."Purch. Account No." := PurchGLAccount."No.";
        Tax.Modify();
    end;

    procedure ExpectedSalesLineValue(var TempSalesLine: record "Sales Line" temporary; SalesHeader: Record "Sales Header"; LineNo: integer; LineType: Enum "Sales Line Type"; No: Code[20]; CodeVariant: Code[10]; Quantity: decimal; TaxCode: Code[20]; IsTaxLine: Boolean; OriginTaxCode: Integer; TaxAmount: Decimal; UnitPrice: Decimal; AmountIncludingVat: Decimal)
    begin
        TempSalesLine.Init();
        TempSalesLine."Document No." := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(TempSalesLine."Document No."));
        TempSalesLine."Document Type" := SalesHeader."Document Type";
        TempSalesLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
        TempSalesLine."Line No." := LineNo;
        TempSalesLine.Type := LineType;
        TempSalesLine."No." := No;
        TempSalesLine."Location Code" := SalesHeader."Location Code";
        TempSalesLine."Variant Code" := CodeVariant;
        TempSalesLine.Quantity := Quantity;
        TempSalesLine."Unit Price" := UnitPrice;
        TempSalesLine."Amount Including VAT" := AmountIncludingVat;
        TempSalesLine."CAGTX_Tax Code" := TaxCode;
        TempSalesLine."CAGTX_Tax Line" := IsTaxLine;
        TempSalesLine."CAGTX_Origin Tax Line" := OriginTaxCode;
        TempSalesLine."CAGTX_Tax Amount" := TaxAmount;
        TempSalesLine.Insert();
    end;

    procedure ExpectedSalesInvLineValue(var TempSalesInvLine: record "Sales Invoice Line" temporary; SalesInvHeader: Record "Sales Invoice Header"; LineNo: integer; LineType: Enum "Sales Line Type"; No: Code[20]; CodeVariant: Code[10]; Quantity: decimal; TaxCode: Code[20]; IsTaxLine: Boolean; OriginTaxCode: Integer; UnitPrice: Decimal; AmountIncludingVat: Decimal)
    begin
        TempSalesInvLine.Init();
        TempSalesInvLine."Document No." := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(TempSalesInvLine."Document No."));
        TempSalesInvLine."Sell-to Customer No." := SalesInvHeader."Sell-to Customer No.";
        TempSalesInvLine."Line No." := LineNo;
        TempSalesInvLine.Type := LineType;
        TempSalesInvLine."No." := No;
        TempSalesInvLine."Location Code" := SalesInvHeader."Location Code";
        TempSalesInvLine."Variant Code" := CodeVariant;
        TempSalesInvLine.Quantity := Quantity;
        TempSalesInvLine."Unit Price" := UnitPrice;
        TempSalesInvLine."Amount Including VAT" := AmountIncludingVat;
        TempSalesInvLine."CAGTX_Tax Code" := TaxCode;
        TempSalesInvLine."CAGTX_Tax Line" := IsTaxLine;
        TempSalesInvLine."CAGTX_Origin Tax Line" := OriginTaxCode;
        TempSalesInvLine.Insert();
    end;

    procedure ExpectedPurchLineValue(var TempPurchLine: record "Purchase Line" temporary; PurchHeader: Record "Purchase Header"; LineNo: integer; LineType: Enum "Sales Line Type"; No: Code[20]; CodeVariant: Code[10]; Quantity: decimal; TaxCode: Code[20]; IsTaxLine: Boolean; OriginTaxCode: Integer; TaxAmount: Decimal; DirectUnitCost: Decimal; AmountIncludingVat: Decimal)
    begin
        TempPurchLine.Init();
        TempPurchLine."Document No." := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(TempPurchLine."Document No."));
        TempPurchLine."Document Type" := PurchHeader."Document Type";
        TempPurchLine."Pay-to Vendor No." := PurchHeader."Pay-to Vendor No.";
        TempPurchLine."Line No." := LineNo;
        TempPurchLine.Type := LineType;
        TempPurchLine."No." := No;
        TempPurchLine."Location Code" := PurchHeader."Location Code";
        TempPurchLine."Variant Code" := CodeVariant;
        TempPurchLine.Quantity := Quantity;
        TempPurchLine."Direct Unit Cost" := DirectUnitCost;
        TempPurchLine."Amount Including VAT" := AmountIncludingVat;
        TempPurchLine."CAGTX_Tax Code" := TaxCode;
        TempPurchLine."CAGTX_Tax Line" := IsTaxLine;
        TempPurchLine."CAGTX_Origin Tax Line" := OriginTaxCode;
        TempPurchLine."CAGTX_Tax Amount" := TaxAmount;
        TempPurchLine.Insert();
    end;

    procedure ExpectedPurchInvLineValue(var TempPurchInvLine: record "Purch. Inv. Line" temporary; PurchInvHeader: Record "Purch. Inv. Header"; LineNo: integer; LineType: Enum "Sales Line Type"; No: Code[20]; CodeVariant: Code[10]; Quantity: decimal; TaxCode: Code[20]; IsTaxLine: Boolean; OriginTaxCode: Integer; DirectUnitCost: Decimal; AmountIncludingVat: Decimal)
    begin
        TempPurchInvLine.Init();
        TempPurchInvLine."Document No." := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(TempPurchInvLine."Document No."));
        TempPurchInvLine."Pay-to Vendor No." := PurchInvHeader."Pay-to Vendor No.";
        TempPurchInvLine."Line No." := LineNo;
        TempPurchInvLine.Type := LineType;
        TempPurchInvLine."No." := No;
        TempPurchInvLine."Location Code" := PurchInvHeader."Location Code";
        TempPurchInvLine."Variant Code" := CodeVariant;
        TempPurchInvLine.Quantity := Quantity;
        TempPurchInvLine."Direct Unit Cost" := DirectUnitCost;
        TempPurchInvLine."Amount Including VAT" := AmountIncludingVat;
        TempPurchInvLine."CAGTX_Tax Code" := TaxCode;
        TempPurchInvLine."CAGTX_Tax Line" := IsTaxLine;
        TempPurchInvLine."CAGTX_Origin Tax Line" := OriginTaxCode;
        TempPurchInvLine.Insert();
    end;

    procedure CompareSalesExpectedAndResultLine(var TempSalesLine: record "Sales Line" temporary; var SalesLine: record "Sales Line")
    var
        ItemErr: Label 'Item expected %1 is different than result : %2', Comment = '%1 is expected Item and %2 is current result';
        GLAccountErr: Label 'G/L Account expected ''%1'' is different than result : %2', Comment = '%1 is expected Item and %2 is current result';
        VariantCodeErr: Label 'Variant expected ''%1'' is different than result : %2', Comment = '%1 is expected Item and %2 is current result';
        QuantityErr: Label 'Quantity expected ''%1'' is different than result : %2', Comment = '%1 is expected Quantity and %2 is current result';
        ExpectedLineNoErr: Label 'Expected ''%1'' Line, Result ''%2'' line found.', Comment = '%1 is expected line no, Result is %2';
        LineTypeErr: Label 'Line Type Expected ''%1'' is different than result : %2', Comment = '%1 is expected line type and %2 is current result';
    begin
        TempSalesLine.SetCurrentKey("Line No.");
        SalesLine.SetCurrentKey("Line No.");
        Assert.IsTrue(TempSalesLine.count = SalesLine.Count, StrSubstNo(ExpectedLineNoErr, TempSalesLine.Count, SalesLine.Count));
        If TempSalesLine.FindSet() and SalesLine.FindSet() then
            repeat
                assert.IsTrue(TempSalesLine.Type = SalesLine.Type, StrSubstNo(LineTypeErr, TempSalesLine.Type, SalesLine.Type));
                If TempSalesLine.Type = TempSalesLine.Type::Item then
                    Assert.IsTrue(TempSalesLine."No." = SalesLine."No.", StrSubstNo(ItemErr, TempSalesLine."No.", SalesLine."No."))
                else
                    If TempSalesLine.Type = TempSalesLine.Type::"G/L Account" then
                        Assert.IsTrue(TempSalesLine."No." = SalesLine."No.", StrSubstNo(GLAccountErr, TempSalesLine."No.", SalesLine."No."));
                Assert.IsTrue(TempSalesLine."Variant Code" = SalesLine."Variant Code", StrSubstNo(VariantCodeErr, TempSalesLine."Variant Code", SalesLine."Variant Code"));
                Assert.IsTrue(TempSalesLine.Quantity = SalesLine.Quantity, StrSubstNo(QuantityErr, TempSalesLine.Quantity, SalesLine.Quantity));
                Assert.IsTrue(TempSalesLine."CAGTX_Tax Code" = SalesLine."CAGTX_Tax Code", StrSubstNo(TaxCodeErr, TempSalesLine."CAGTX_Tax Code", SalesLine."CAGTX_Tax Code"));
                Assert.IsTrue(TempSalesLine."CAGTX_Tax Line" = SalesLine."CAGTX_Tax Line", StrSubstNo(TaxLineErr, TempSalesLine."CAGTX_Tax Line", SalesLine."CAGTX_Tax Line"));
                Assert.IsTrue(TempSalesLine."CAGTX_Origin Tax Line" = SalesLine."CAGTX_Origin Tax Line", StrSubstNo(OriginTaxCodeErr, TempSalesLine."CAGTX_Origin Tax Line", SalesLine."CAGTX_Origin Tax Line"));
                Assert.IsTrue(TempSalesLine."CAGTX_Tax Amount" = SalesLine."CAGTX_Tax Amount", StrSubstNo(TaxAmountErr, TempSalesLine."CAGTX_Tax Amount", SalesLine."CAGTX_Tax Amount"));
                Assert.IsTrue(TempSalesLine."Unit Price" = SalesLine."Unit Price", StrSubstNo(UnitPriceErr, TempSalesLine."Unit Price", SalesLine."Unit Price"));
                Assert.IsTrue(TempSalesLine."Amount Including VAT" = SalesLine."Amount Including VAT", StrSubstNo(AmountInclVATErr, TempSalesLine."Amount Including VAT", SalesLine."Amount Including VAT"));
            until (TempSalesLine.next() = 0) or (SalesLine.next() = 0);
    end;


    procedure ComparePostedSalesExpectedAndResultLine(var TempSalesInvLine: record "Sales Invoice Line" temporary; var SalesInvLine: record "Sales Invoice Line")
    var
        ItemErr: Label 'Item expected %1 is different than result : %2', Comment = '%1 is expected Item and %2 is current result';
        GLAccountErr: Label 'G/L Account expected ''%1'' is different than result : %2', Comment = '%1 is expected Item and %2 is current result';
        VariantCodeErr: Label 'Variant expected ''%1'' is different than result : %2', Comment = '%1 is expected Item and %2 is current result';
        QuantityErr: Label 'Quantity expected ''%1'' is different than result : %2', Comment = '%1 is expected Quantity and %2 is current result';
        ExpectedLineNoErr: Label 'Expected ''%1'' Line, Result ''%2'' line found.', Comment = '%1 is expected line no, Result is %2';
        LineTypeErr: Label 'Line Type Expected ''%1'' is different than result : %2', Comment = '%1 is expectd line type and %2 is current result';
    begin
        TempSalesInvLine.SetCurrentKey("Line No.");
        SalesInvLine.SetCurrentKey("Line No.");
        Assert.IsTrue(TempSalesInvLine.count = SalesInvLine.Count, StrSubstNo(ExpectedLineNoErr, TempSalesInvLine.Count, SalesInvLine.Count));
        If TempSalesInvLine.FindSet() and SalesInvLine.FindSet() then
            repeat
                assert.IsTrue(TempSalesInvLine.Type = SalesInvLine.Type, StrSubstNo(LineTypeErr, TempSalesInvLine.Type, SalesInvLine.Type));
                If TempSalesInvLine.Type = TempSalesInvLine.Type::Item then
                    Assert.IsTrue(TempSalesInvLine."No." = SalesInvLine."No.", StrSubstNo(ItemErr, TempSalesInvLine."No.", SalesInvLine."No."))
                else
                    If TempSalesInvLine.Type = TempSalesInvLine.Type::"G/L Account" then
                        Assert.IsTrue(TempSalesInvLine."No." = SalesInvLine."No.", StrSubstNo(GLAccountErr, TempSalesInvLine."No.", SalesInvLine."No."));
                Assert.IsTrue(TempSalesInvLine."Variant Code" = SalesInvLine."Variant Code", StrSubstNo(VariantCodeErr, TempSalesInvLine."Variant Code", SalesInvLine."Variant Code"));
                Assert.IsTrue(TempSalesInvLine.Quantity = SalesInvLine.Quantity, StrSubstNo(QuantityErr, TempSalesInvLine.Quantity, SalesInvLine.Quantity));
                Assert.IsTrue(TempSalesInvLine."CAGTX_Tax Code" = SalesInvLine."CAGTX_Tax Code", StrSubstNo(TaxCodeErr, TempSalesInvLine."CAGTX_Tax Code", SalesInvLine."CAGTX_Tax Code"));
                Assert.IsTrue(TempSalesInvLine."CAGTX_Tax Line" = SalesInvLine."CAGTX_Tax Line", StrSubstNo(TaxLineErr, TempSalesInvLine."CAGTX_Tax Line", SalesInvLine."CAGTX_Tax Line"));
                Assert.IsTrue(TempSalesInvLine."CAGTX_Origin Tax Line" = SalesInvLine."CAGTX_Origin Tax Line", StrSubstNo(OriginTaxCodeErr, TempSalesInvLine."CAGTX_Origin Tax Line", SalesInvLine."CAGTX_Origin Tax Line"));
                Assert.IsTrue(TempSalesInvLine."Unit Price" = SalesInvLine."Unit Price", StrSubstNo(UnitPriceErr, TempSalesInvLine."Unit Price", SalesInvLine."Unit Price"));
                Assert.IsTrue(TempSalesInvLine."Amount Including VAT" = SalesInvLine."Amount Including VAT", StrSubstNo(AmountInclVATErr, TempSalesInvLine."Amount Including VAT", SalesInvLine."Amount Including VAT"));
            until (TempSalesInvLine.next() = 0) or (SalesInvLine.next() = 0);
    end;

    procedure ComparePurchExpectedAndResultLine(var TempPurchLine: record "Purchase Line" temporary; var PurchLine: record "Purchase Line")
    var
        ItemErr: Label 'Item expected %1 is different than result : %2', Comment = '%1 is expected Item and %2 is current result';
        GLAccountErr: Label 'G/L Account expected ''%1'' is different than result : %2', Comment = '%1 is expected Item and %2 is current result';
        VariantCodeErr: Label 'Variant expected ''%1'' is different than result : %2', Comment = '%1 is expected Item and %2 is current result';
        QuantityErr: Label 'Quantity expected ''%1'' is different than result : %2', Comment = '%1 is expected Quantity and %2 is current result';
        ExpectedLineNoErr: Label 'Expected ''%1'' Line, Result ''%2'' line found.', Comment = '%1 is expected line no, Result is %2';
        LineTypeErr: Label 'Line Type Expected ''%1'' is different than result : %2', Comment = '%1 is expectd line type and %2 is current result';
    begin
        TempPurchLine.SetCurrentKey("Line No.");
        PurchLine.SetCurrentKey("Line No.");
        Assert.IsTrue(TempPurchLine.count = PurchLine.Count, StrSubstNo(ExpectedLineNoErr, TempPurchLine.Count, PurchLine.Count));
        If TempPurchLine.FindSet() and PurchLine.FindSet() then
            repeat
                assert.IsTrue(TempPurchLine.Type = PurchLine.Type, StrSubstNo(LineTypeErr, TempPurchLine.Type, PurchLine.Type));
                If TempPurchLine.Type = TempPurchLine.Type::Item then
                    Assert.IsTrue(TempPurchLine."No." = PurchLine."No.", StrSubstNo(ItemErr, TempPurchLine."No.", PurchLine."No."))
                else
                    If TempPurchLine.Type = TempPurchLine.Type::"G/L Account" then
                        Assert.IsTrue(TempPurchLine."No." = PurchLine."No.", StrSubstNo(GLAccountErr, TempPurchLine."No.", PurchLine."No."));
                Assert.IsTrue(TempPurchLine."Variant Code" = PurchLine."Variant Code", StrSubstNo(VariantCodeErr, TempPurchLine."Variant Code", PurchLine."Variant Code"));
                Assert.IsTrue(TempPurchLine.Quantity = PurchLine.Quantity, StrSubstNo(QuantityErr, TempPurchLine.Quantity, PurchLine.Quantity));
                Assert.IsTrue(TempPurchLine."CAGTX_Tax Code" = PurchLine."CAGTX_Tax Code", StrSubstNo(TaxCodeErr, TempPurchLine."CAGTX_Tax Code", PurchLine."CAGTX_Tax Code"));
                Assert.IsTrue(TempPurchLine."CAGTX_Tax Line" = PurchLine."CAGTX_Tax Line", StrSubstNo(TaxLineErr, TempPurchLine."CAGTX_Tax Line", PurchLine."CAGTX_Tax Line"));
                Assert.IsTrue(TempPurchLine."CAGTX_Origin Tax Line" = PurchLine."CAGTX_Origin Tax Line", StrSubstNo(OriginTaxCodeErr, TempPurchLine."CAGTX_Origin Tax Line", PurchLine."CAGTX_Origin Tax Line"));
                Assert.IsTrue(TempPurchLine."CAGTX_Tax Amount" = PurchLine."CAGTX_Tax Amount", StrSubstNo(TaxAmountErr, TempPurchLine."CAGTX_Tax Amount", PurchLine."CAGTX_Tax Amount"));
                Assert.IsTrue(TempPurchLine."Direct Unit Cost" = PurchLine."Direct Unit Cost", StrSubstNo(DirectUnitCostErr, TempPurchLine."Direct Unit Cost", PurchLine."Direct Unit Cost"));
                Assert.IsTrue(TempPurchLine."Amount Including VAT" = PurchLine."Amount Including VAT", StrSubstNo(AmountInclVATErr, TempPurchLine."Amount Including VAT", PurchLine."Amount Including VAT"));
            until (TempPurchLine.next() = 0) or (PurchLine.next() = 0);
    end;

    procedure ComparePostedPurchExpectedAndResultLine(var TempPurchLine: record "Purch. Inv. Line" temporary; var PurchInvLine: record "Purch. Inv. Line")
    var
        ItemErr: Label 'Item expected %1 is different than result : %2', Comment = '%1 is expected Item and %2 is current result';
        GLAccountErr: Label 'G/L Account expected ''%1'' is different than result : %2', Comment = '%1 is expected Item and %2 is current result';
        VariantCodeErr: Label 'Variant expected ''%1'' is different than result : %2', Comment = '%1 is expected Item and %2 is current result';
        QuantityErr: Label 'Quantity expected ''%1'' is different than result : %2', Comment = '%1 is expected Quantity and %2 is current result';
        ExpectedLineNoErr: Label 'Expected ''%1'' Line, Result ''%2'' line found.', Comment = '%1 is expected line no, Result is %2';
        LineTypeErr: Label 'Line Type Expected ''%1'' is different than result : %2', Comment = '%1 is expectd line type and %2 is current result';
    begin
        TempPurchLine.SetCurrentKey("Line No.");
        PurchInvLine.SetCurrentKey("Line No.");
        Assert.IsTrue(TempPurchLine.count = PurchInvLine.Count, StrSubstNo(ExpectedLineNoErr, TempPurchLine.Count, PurchInvLine.Count));
        If TempPurchLine.FindSet() and PurchInvLine.FindSet() then
            repeat
                assert.IsTrue(TempPurchLine.Type = PurchInvLine.Type, StrSubstNo(LineTypeErr, TempPurchLine.Type, PurchInvLine.Type));
                If TempPurchLine.Type = TempPurchLine.Type::Item then
                    Assert.IsTrue(TempPurchLine."No." = PurchInvLine."No.", StrSubstNo(ItemErr, TempPurchLine."No.", PurchInvLine."No."))
                else
                    If TempPurchLine.Type = TempPurchLine.Type::"G/L Account" then
                        Assert.IsTrue(TempPurchLine."No." = PurchInvLine."No.", StrSubstNo(GLAccountErr, TempPurchLine."No.", PurchInvLine."No."));
                Assert.IsTrue(TempPurchLine."Variant Code" = PurchInvLine."Variant Code", StrSubstNo(VariantCodeErr, TempPurchLine."Variant Code", PurchInvLine."Variant Code"));
                Assert.IsTrue(TempPurchLine.Quantity = PurchInvLine.Quantity, StrSubstNo(QuantityErr, TempPurchLine.Quantity, PurchInvLine.Quantity));
                Assert.IsTrue(TempPurchLine."CAGTX_Tax Code" = PurchInvLine."CAGTX_Tax Code", StrSubstNo(TaxCodeErr, TempPurchLine."CAGTX_Tax Code", PurchInvLine."CAGTX_Tax Code"));
                Assert.IsTrue(TempPurchLine."CAGTX_Tax Line" = PurchInvLine."CAGTX_Tax Line", StrSubstNo(TaxLineErr, TempPurchLine."CAGTX_Tax Line", PurchInvLine."CAGTX_Tax Line"));
                Assert.IsTrue(TempPurchLine."CAGTX_Origin Tax Line" = PurchInvLine."CAGTX_Origin Tax Line", StrSubstNo(OriginTaxCodeErr, TempPurchLine."CAGTX_Origin Tax Line", PurchInvLine."CAGTX_Origin Tax Line"));
                Assert.IsTrue(TempPurchLine."Direct Unit Cost" = PurchInvLine."Direct Unit Cost", StrSubstNo(DirectUnitCostErr, TempPurchLine."Direct Unit Cost", PurchInvLine."Direct Unit Cost"));
                Assert.IsTrue(TempPurchLine."Amount Including VAT" = PurchInvLine."Amount Including VAT", StrSubstNo(AmountInclVATErr, TempPurchLine."Amount Including VAT", PurchInvLine."Amount Including VAT"));
            until (TempPurchLine.next() = 0) or (PurchInvLine.next() = 0);
    end;
}