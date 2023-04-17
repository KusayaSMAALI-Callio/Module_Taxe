codeunit 50254 "CAGTX_Tax Test"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Item: record Item;
        Cust: record Customer;
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: codeunit "Library - Sales";
        LibraryPurchase: codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        TaxHelper: codeunit "CAGTX_Tax Helpers";
        PermissionTestMgt: Codeunit "CAGTX_Permission Test Mgt";
        TaxCode: Code[20];
        CalculType: option Line,Total;
        DefaultRateType: Option "Unit Amount",Percent,"Flat Rate";
        AppliedOption: Option "Posting Date","Document Date","Order Date";
        SalesAccountType: Option " ","G/L Account",,Resource,,"Charge (Item)";
        PurchAccountType: Option " ","G/L Account",,Resource,,"Charge (Item)";
        DescriptionEmptyErr: Label 'Tax Test Auto ID : 50254';
        ItemNoEmptyErr: Label 'Item No is empty';
        NoSalesLineFoundErr: Label 'No Sales Line found.';

    [Test]
    [HandlerFunctions('TaxAssgntoThirdPartHandler,ItemTaxPageHandler')]
    procedure CreateTaxAndAssignThirdPart()
    var
        GLAccount: record "G/L Account";
        GLAccount2: record "G/L Account";
        TaxAssignThirdParty: record "CAGTX_Tax Assign. Third Party";
        ItemTax: record "CAGTX_Item Tax V2";
        Taxes: testpage CAGTX_Taxes;
        ItemCard: TestPage "Item Card";
        ThirdPartType: Option "Third Party","Posting Group",All;
        LinkToTable: Option " ",Customer,Vendor;
        TaxCodeErr: Label 'Erreur TaxCode';
        CustomerErr: Label 'Erreur Customer';
        TypeErr: Label 'Erreur Type';
        LinkToTableErr: Label 'Erreur Link to table';
        ItemTaxCodeErr: Label 'Item Tax Code is empty';
        ThirdTaxCodeErr: Label 'Third Tax Code is empty';
    begin
        // [FEATURES] [Tax In Documents]
        // [SCENARIO] Création d'une taxe et affectation à un article et un client

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // [GIVEN] Création d'un article, un client et les taxes liées
        LibrarySales.CreateCustomer(Cust);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(GLAccount2);

        Taxes.OpenNew();
        Taxes.Code.SetValue(LibraryRandom.RandText(10));
        Taxes.Description.SetValue(DescriptionEmptyErr);
        Taxes."Default Rate Type".SetValue(DefaultRateType::Percent);
        Taxes."Default Rate Value".SetValue(10);
        Taxes."Sale Account Type".SetValue(SalesAccountType::"G/L Account");
        Taxes."Sale Account No.".SetValue(GLAccount."No.");
        Taxes."Purch. Account Type".SetValue(PurchAccountType::"G/L Account");
        Taxes."Purch. Account No.".SetValue(GLAccount2."No.");

        Taxes.TaxChargedtoThridParty.Invoke();

        TaxCode := CopyStr(Taxes.Code.Value(), 1, MaxStrLen(TaxCode));

        LibraryInventory.CreateItem(Item);

        // [WHEN] Ouverture de la fiche article et ouverture taxe articles liées
        ItemCard.OpenEdit();
        ItemCard.GoToRecord(Item);
        ItemCard.CAGTX_OpenItemTaxes.Invoke();
        ItemCard.Close();

        Commit();

        // [THEN] Vérification des Valeurs dans les sous tables de taxe
        ItemTax.Reset();
        ItemTax.SetRange("Tax Code", Taxes.Code.Value());
        ItemTax.FindFirst();
        Assert.IsTrue(ItemTax."Tax Code" <> '', ItemTaxCodeErr);
        Assert.IsTrue(ItemTax."No." = Item."No.", ItemNoEmptyErr);
        Assert.IsTrue(ItemTax.Type = ItemTax.Type::Item, ItemNoEmptyErr);
        Assert.IsTrue(ItemTax."Rate Type" = ItemTax."Rate Type"::Percent, ItemTaxCodeErr);

        TaxAssignThirdParty.Reset();
        TaxAssignThirdParty.SetRange("Tax Code", Taxes.Code.Value());
        TaxAssignThirdParty.FindFirst();
        Assert.IsTrue(TaxAssignThirdParty."Tax Code" <> '', ThirdTaxCodeErr);
        Assert.IsTrue(TaxAssignThirdParty."No." = Cust."No.", CustomerErr);
        Assert.IsTrue(TaxAssignThirdParty.Type = ThirdPartType::"Third Party", TypeErr);
        Assert.IsTrue(TaxAssignThirdParty."Link to Table" = LinkToTable::Customer, LinkToTableErr);

        Taxes.Close();
    end;

    [Test]
    procedure TestTaxWhenReleaseSalesOrderWithExclVAT()
    var
        SOItem: record Item;
        Tax: record CAGTX_Tax;
        Customer: record Customer;
        SalesLine: record "Sales Line";
        SalesHeader: record "Sales Header";
        SalesGLAccount: record "G/L Account";
        PurchGLAccount: record "G/L Account";
        VATPostingSetup: record "VAT Posting Setup";
        VATBusPostingSetup: record "VAT Business Posting Group";
        resource: record resource;
        TempSalesLine: record "Sales Line" temporary;
    begin
        // [FEATURES] [Tax In Documents]
        // [SCENARIO] Création d'une taxe et affectation à un article et un client sur une commande de vente (tva non incluse) puis lancer

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // GIVEN Création d'un article, un client et les taxes liées
        TaxHelper.DeleteExistingTax();
        if not resource.FindFirst() then;

        TaxHelper.CreateComplexeTax(Tax, DescriptionEmptyErr, CalculType::Line, AppliedOption::"Posting Date", DefaultRateType::Percent, 10, Tax."Posted Option"::Prorata, resource."No.");
        TaxHelper.CreateThirdPartyAndItemTax(Customer, SOItem, Tax, SalesGLAccount, PurchGLAccount, DefaultRateType::Percent, 10);

        VATPostingSetup.Get(Customer."VAT Bus. Posting Group", SOItem."VAT Prod. Posting Group");
        VATPostingSetup.validate("VAT %", 20);
        VATPostingSetup.Modify();

        Commit();

        // [WHEN] Création d'une commande de vente et lancement pour générer les taxes
        LibrarySales.CreateSalesHeader(SalesHeader, Enum::"Sales Document Type"::Order, Customer."No.");
        SalesHeader."Posting Date" := Calcdate('<-1d>', Today());
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Enum::"Sales Line Type"::Item, SOItem."No.", 2);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);

        LibrarySales.ReleaseSalesDocument(SalesHeader);

        TempSalesLine.DeleteAll();
        TaxHelper.ExpectedSalesLineValue(TempSalesLine, SalesHeader, 10000, Enum::"Sales Line Type"::Item, SOItem."No.", SalesLine."Variant Code", 2, '', False, 0, 24, 100, 240);
        TaxHelper.ExpectedSalesLineValue(TempSalesLine, SalesHeader, 20000, Enum::"Sales Line Type"::"G/L Account", SalesGLAccount."No.", '', 2, Tax.Code, True, 10000, 0, 10, 24);

        // [THEN] Vérification des valeurs des lignes de ventes
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if not SalesLine.IsEmpty() then
            TaxHelper.CompareSalesExpectedAndResultLine(TempSalesLine, SalesLine)
        else
            error(NoSalesLineFoundErr);
    end;

    [Test]
    procedure TestTaxWhenReleaseSalesOrderInclVAT()
    var
        SOItem: record Item;
        Tax: record CAGTX_Tax;
        Customer: record Customer;
        SalesLine: record "Sales Line";
        SalesHeader: record "Sales Header";
        SalesGLAccount: record "G/L Account";
        PurchGLAccount: record "G/L Account";
        VATPostingSetup: record "VAT Posting Setup";
        VATBusPostingSetup: record "VAT Business Posting Group";
        resource: record resource;
        TempSalesLine: record "Sales Line" temporary;
    begin
        // [FEATURES] [Tax In Documents]
        // [SCENARIO] Création d'une taxe et affectation à un article et un client sur une commande de vente (tva incluse) puis lancer

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // [GIVEN] Création d'un article, un client et les taxes liées
        TaxHelper.DeleteExistingTax();
        if not resource.FindFirst() then;

        TaxHelper.CreateComplexeTax(Tax, DescriptionEmptyErr, CalculType::Line, AppliedOption::"Posting Date", DefaultRateType::Percent, 10, Tax."Posted Option"::Prorata, resource."No.");
        TaxHelper.CreateThirdPartyAndItemTax(Customer, SOItem, Tax, SalesGLAccount, PurchGLAccount, DefaultRateType::Percent, 10);

        VATPostingSetup.Get(Customer."VAT Bus. Posting Group", SOItem."VAT Prod. Posting Group");
        VATPostingSetup.validate("VAT %", 20);
        VATPostingSetup.Modify();

        Commit();

        // [WHEN] Création d'une commande de vente et lancement pour générer les taxes
        LibrarySales.CreateSalesHeader(SalesHeader, Enum::"Sales Document Type"::Order, Customer."No.");
        SalesHeader."Posting Date" := Calcdate('<-1d>', Today());
        SalesHeader."Prices Including VAT" := true;
        SalesHeader.Modify(true);

        TaxHelper.CreateSalesLineWithNo(SalesLine, SalesHeader, 10000, Enum::"Sales Line Type"::Item, SOItem."No.", 2, 120);

        LibrarySales.ReleaseSalesDocument(SalesHeader);

        TempSalesLine.DeleteAll();
        TaxHelper.ExpectedSalesLineValue(TempSalesLine, SalesHeader, 10000, Enum::"Sales Line Type"::Item, SOItem."No.", SalesLine."Variant Code", 2, '', False, 0, 24, 120, 240);
        TaxHelper.ExpectedSalesLineValue(TempSalesLine, SalesHeader, 20000, Enum::"Sales Line Type"::"G/L Account", SalesGLAccount."No.", '', 2, Tax.Code, True, 10000, 0, 12, 24);

        // [THEN] Vérification des valeurs des lignes de ventes
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if not SalesLine.IsEmpty() then
            TaxHelper.CompareSalesExpectedAndResultLine(TempSalesLine, SalesLine)
        else
            error(NoSalesLineFoundErr);
    end;

    [Test]
    procedure TestTaxWhenPostSalesOrderExclVAT()
    var
        SOItem: record Item;
        Tax: record CAGTX_Tax;
        Customer: record Customer;
        SalesLine: record "Sales Line";
        SalesHeader: record "Sales Header";
        SalesGLAccount: record "G/L Account";
        PurchGLAccount: record "G/L Account";
        SalesInvLine: record "Sales Invoice Line";
        SalesInvHeader: record "Sales Invoice Header";
        TempSalesInvLine: record "Sales Invoice Line" temporary;
    begin
        // [FEATURES] [Tax In Documents]
        // [SCENARIO] Création d'une taxe et affectation à un article et un client sur une commande de vente (tva non incluse) puis lancer

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // [GIVEN] Création d'un article, un client et les taxes liées

        TaxHelper.CreateTax(Tax, DescriptionEmptyErr, CalculType::Line, AppliedOption::"Posting Date", DefaultRateType::Percent, 10);
        TaxHelper.CreateThirdPartyAndItemTax(Customer, SOItem, Tax, SalesGLAccount, PurchGLAccount, DefaultRateType::Percent, 10);

        Commit();

        // [WHEN] Création d'une commande de vente et lancement pour générer les taxes
        LibrarySales.CreateSalesHeader(SalesHeader, Enum::"Sales Document Type"::Order, Customer."No.");
        SalesHeader."Posting Date" := Calcdate('<-1d>', Today());
        //SalesHeader."Prices Including VAT" := true;
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Enum::"Sales Line Type"::Item, SOItem."No.", 2);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);

        LibrarySales.ReleaseSalesDocument(SalesHeader);

        SalesInvHeader.get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        TempSalesInvLine.DeleteAll();
        TaxHelper.ExpectedSalesInvLineValue(TempSalesInvLine, SalesInvHeader, 10000, Enum::"Sales Line Type"::Item, SOItem."No.", SalesLine."Variant Code", 2, '', False, 0, 100, 240);
        TaxHelper.ExpectedSalesInvLineValue(TempSalesInvLine, SalesInvHeader, 20000, Enum::"Sales Line Type"::"G/L Account", SalesGLAccount."No.", '', 2, Tax.Code, True, 10000, 10, 24);

        // [THEN] Vérification des valeurs des lignes de ventes
        SalesInvLine.Reset();
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        if not SalesInvLine.IsEmpty() then
            TaxHelper.ComparePostedSalesExpectedAndResultLine(TempSalesInvLine, SalesInvLine)
        else
            error(NoSalesLineFoundErr);
    end;

    [Test]
    procedure TestTaxWhenPostSalesOrderInclVAT()
    var
        SOItem: record Item;
        Tax: record CAGTX_Tax;
        Customer: record Customer;
        SalesLine: record "Sales Line";
        SalesHeader: record "Sales Header";
        SalesGLAccount: record "G/L Account";
        PurchGLAccount: record "G/L Account";
        SalesInvLine: record "Sales Invoice Line";
        SalesInvHeader: record "Sales Invoice Header";
        TempSalesInvLine: record "Sales Invoice Line" temporary;
    begin
        // [FEATURES] [Tax In Documents]
        // [SCENARIO] Création d'une taxe et affectation à un article et un client sur une commande de vente (tva incluse) puis lancer

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // [GIVEN] Création d'un article, un client et les taxes liées

        TaxHelper.CreateTax(Tax, DescriptionEmptyErr, CalculType::Line, AppliedOption::"Posting Date", DefaultRateType::Percent, 10);
        TaxHelper.CreateThirdPartyAndItemTax(Customer, SOItem, Tax, SalesGLAccount, PurchGLAccount, DefaultRateType::Percent, 10);

        Commit();

        // [WHEN] Création d'une commande de vente et lancement pour générer les taxes
        LibrarySales.CreateSalesHeader(SalesHeader, Enum::"Sales Document Type"::Order, Customer."No.");
        SalesHeader."Posting Date" := Calcdate('<-1d>', Today());
        SalesHeader."Prices including VAT" := true;
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Enum::"Sales Line Type"::Item, SOItem."No.", 2);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);

        LibrarySales.ReleaseSalesDocument(SalesHeader);

        SalesInvHeader.get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        TempSalesInvLine.DeleteAll();
        TaxHelper.ExpectedSalesInvLineValue(TempSalesInvLine, SalesInvHeader, 10000, Enum::"Sales Line Type"::Item, SOItem."No.", SalesLine."Variant Code", 2, '', False, 0, 100, 200);
        TaxHelper.ExpectedSalesInvLineValue(TempSalesInvLine, SalesInvHeader, 20000, Enum::"Sales Line Type"::"G/L Account", SalesGLAccount."No.", '', 2, Tax.Code, True, 10000, 10, 20);

        // [THEN] Vérification des valeurs des lignes de ventes
        SalesInvLine.Reset();
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        if not SalesInvLine.IsEmpty() then
            TaxHelper.ComparePostedSalesExpectedAndResultLine(TempSalesInvLine, SalesInvLine)
        else
            error(NoSalesLineFoundErr);
    end;

    [Test]
    procedure TestTaxWhenReleaseSalesInvoiceExclVAT()
    var
        SaleInvItem: record Item;
        Tax: record CAGTX_Tax;
        Customer: record Customer;
        SalesLine: record "Sales Line";
        SalesGLAccount: record "G/L Account";
        PurchAccount: record "G/L Account";
        SalesHeader: record "Sales Header";
        TempSalesLine: record "Sales Line" temporary;
    begin
        // [FEATURES] [Tax In Documents]
        // [SCENARIO] Création d'une taxe et affectation à un article et un client sur une Facture de vente (tva non incluse) puis lancer

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // [GIVEN] Création d'un article, un client et les taxes liées
        TaxHelper.CreateTax(Tax, DescriptionEmptyErr, CalculType::Line, AppliedOption::"Posting Date", DefaultRateType::Percent, 10);
        TaxHelper.CreateThirdPartyAndItemTax(Customer, SaleInvItem, Tax, SalesGLAccount, PurchAccount, DefaultRateType::Percent, 10);

        Commit();

        // [WHEN] Création facture de vente avec ligne article puis lancement du document
        LibrarySales.CreateSalesHeader(SalesHeader, Enum::"Sales Document Type"::Invoice, Customer."No.");
        SalesHeader."Posting Date" := Calcdate('<-1d>', Today());
        //SalesHeader."Prices Including VAT" := true;
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Enum::"Sales Line Type"::Item, SaleInvItem."No.", 2);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Validate(Quantity, 2);
        SalesLine.Modify(true);

        LibrarySales.ReleaseSalesDocument(SalesHeader);

        TempSalesLine.DeleteAll();
        TaxHelper.ExpectedSalesLineValue(TempSalesLine, SalesHeader, 10000, Enum::"Sales Line Type"::Item, SaleInvItem."No.", SalesLine."Variant Code", 2, '', False, 0, 24, 100, 240);
        TaxHelper.ExpectedSalesLineValue(TempSalesLine, SalesHeader, 20000, Enum::"Sales Line Type"::"G/L Account", SalesGLAccount."No.", '', 2, Tax.Code, True, 10000, 0, 10, 24);

        // [THEN] Vérification des valeurs de taxe dans la facture généré
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if not SalesLine.IsEmpty() then
            TaxHelper.CompareSalesExpectedAndResultLine(TempSalesLine, SalesLine)
        else
            error(NoSalesLineFoundErr);
    end;

    [Test]
    procedure TestTaxWhenReleaseSalesInvoiceInclVAT()
    var
        SaleInvItem: record Item;
        Tax: record CAGTX_Tax;
        Customer: record Customer;
        SalesLine: record "Sales Line";
        SalesGLAccount: record "G/L Account";
        PurchAccount: record "G/L Account";
        SalesHeader: record "Sales Header";
        TempSalesLine: record "Sales Line" temporary;
    begin
        // [FEATURES] [Tax In Documents]
        // [SCENARIO] Création d'une taxe et affectation à un article et un client sur une Facture de vente (tva incluse) puis lancer

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // [GIVEN] Création d'un article, un client et les taxes liées
        TaxHelper.CreateTax(Tax, DescriptionEmptyErr, CalculType::Line, AppliedOption::"Posting Date", DefaultRateType::Percent, 10);
        TaxHelper.CreateThirdPartyAndItemTax(Customer, SaleInvItem, Tax, SalesGLAccount, PurchAccount, DefaultRateType::Percent, 10);

        Commit();

        // [WHEN] Création facture de vente avec ligne article puis lancement du document
        LibrarySales.CreateSalesHeader(SalesHeader, Enum::"Sales Document Type"::Invoice, Customer."No.");
        SalesHeader."Posting Date" := Calcdate('<-1d>', Today());
        SalesHeader."Prices Including VAT" := true;
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Enum::"Sales Line Type"::Item, SaleInvItem."No.", 2);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Validate(Quantity, 2);
        SalesLine.Modify(true);

        LibrarySales.ReleaseSalesDocument(SalesHeader);

        TempSalesLine.DeleteAll();
        TaxHelper.ExpectedSalesLineValue(TempSalesLine, SalesHeader, 10000, Enum::"Sales Line Type"::Item, SaleInvItem."No.", SalesLine."Variant Code", 2, '', False, 0, 20, 100, 200);
        TaxHelper.ExpectedSalesLineValue(TempSalesLine, SalesHeader, 20000, Enum::"Sales Line Type"::"G/L Account", SalesGLAccount."No.", '', 2, Tax.Code, True, 10000, 0, 10, 20);

        // [THEN] Vérification des valeurs de taxe dans la facture généré
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if not SalesLine.IsEmpty() then
            TaxHelper.CompareSalesExpectedAndResultLine(TempSalesLine, SalesLine)
        else
            error(NoSalesLineFoundErr);
    end;

    [Test]
    procedure TestTaxWhenPostSalesInvoiceExclVAT()
    var
        SIItem: record Item;
        Tax: record CAGTX_Tax;
        Customer: record Customer;
        SalesLine: record "Sales Line";
        SalesInvHeader: record "Sales Invoice Header";
        SalesInvLine: record "Sales Invoice Line";
        SalesGLAccount: record "G/L Account";
        PurchAccount: record "G/L Account";
        SalesHeader: record "Sales Header";
        TempSalesInvLine: record "Sales Invoice Line" temporary;
    begin
        // [FEATURES] [Tax In Documents]
        // [SCENARIO] Création d'une taxe et affectation à un article et un client sur une facture de vente (tva non incluse) puis valider

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // [GIVEN] Création d'un article, un client et les taxes liées
        TaxHelper.CreateTax(Tax, DescriptionEmptyErr, CalculType::Line, AppliedOption::"Posting Date", DefaultRateType::Percent, 10);
        TaxHelper.CreateThirdPartyAndItemTax(Customer, SIItem, Tax, SalesGLAccount, PurchAccount, DefaultRateType::Percent, 10);

        Commit();

        // [WHEN] Création facture de vente avec ligne article puis lancement et validation du document
        LibrarySales.CreateSalesHeader(SalesHeader, Enum::"Sales Document Type"::Invoice, Customer."No.");
        SalesHeader."Posting Date" := Calcdate('<-1d>', Today());
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Enum::"Sales Line Type"::Item, SIItem."No.", 2);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);

        LibrarySales.ReleaseSalesDocument(SalesHeader);

        SalesInvHeader.get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        TempSalesInvLine.DeleteAll();
        TaxHelper.ExpectedSalesInvLineValue(TempSalesInvLine, SalesInvHeader, 10000, Enum::"Sales Line Type"::Item, SIItem."No.", SalesLine."Variant Code", 2, '', False, 0, 100, 240);
        TaxHelper.ExpectedSalesInvLineValue(TempSalesInvLine, SalesInvHeader, 20000, Enum::"Sales Line Type"::"G/L Account", SalesGLAccount."No.", '', 2, Tax.Code, True, 10000, 10, 24);

        // [THEN] Vérification des valeurs de taxe dans la facture généré
        SalesInvLine.Reset();
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        if not SalesInvLine.IsEmpty() then
            TaxHelper.ComparePostedSalesExpectedAndResultLine(TempSalesInvLine, SalesInvLine)
        else
            error(NoSalesLineFoundErr);
    end;

    [Test]
    procedure TestTaxWhenPostSalesInvoiceInclVAT()
    var
        SIItem: record Item;
        Tax: record CAGTX_Tax;
        Customer: record Customer;
        SalesLine: record "Sales Line";
        SalesInvHeader: record "Sales Invoice Header";
        SalesInvLine: record "Sales Invoice Line";
        SalesGLAccount: record "G/L Account";
        PurchAccount: record "G/L Account";
        SalesHeader: record "Sales Header";
        TempSalesInvLine: record "Sales Invoice Line" temporary;
    begin
        // [FEATURES] [Tax In Documents]
        // [SCENARIO] Création d'une taxe et affectation à un article et un client sur une facture de vente (tva incluse) puis valider

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // [GIVEN] Création d'un article, un client et les taxes liées
        TaxHelper.CreateTax(Tax, DescriptionEmptyErr, CalculType::Line, AppliedOption::"Posting Date", DefaultRateType::Percent, 10);
        TaxHelper.CreateThirdPartyAndItemTax(Customer, SIItem, Tax, SalesGLAccount, PurchAccount, DefaultRateType::Percent, 10);

        Commit();

        // [WHEN] Création facture de vente avec ligne article puis lancement et validation du document
        LibrarySales.CreateSalesHeader(SalesHeader, Enum::"Sales Document Type"::Invoice, Customer."No.");
        SalesHeader."Posting Date" := Calcdate('<-1d>', Today());
        SalesHeader."Prices Including VAT" := true;
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Enum::"Sales Line Type"::Item, SIItem."No.", 2);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);

        LibrarySales.ReleaseSalesDocument(SalesHeader);

        SalesInvHeader.get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        TempSalesInvLine.DeleteAll();
        TaxHelper.ExpectedSalesInvLineValue(TempSalesInvLine, SalesInvHeader, 10000, Enum::"Sales Line Type"::Item, SIItem."No.", SalesLine."Variant Code", 2, '', False, 0, 100, 200);
        TaxHelper.ExpectedSalesInvLineValue(TempSalesInvLine, SalesInvHeader, 20000, Enum::"Sales Line Type"::"G/L Account", SalesGLAccount."No.", '', 2, Tax.Code, True, 10000, 10, 20);

        // [THEN] Vérification des valeurs de taxe dans la facture généré
        SalesInvLine.Reset();
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        if not SalesInvLine.IsEmpty() then
            TaxHelper.ComparePostedSalesExpectedAndResultLine(TempSalesInvLine, SalesInvLine)
        else
            error(NoSalesLineFoundErr);
    end;

    [Test]
    procedure TestTaxWhenReleasePurchOrderExclVAT()
    var
        POItem: record Item;
        Tax: record CAGTX_Tax;
        Vendor: record Vendor;
        PurchLine: record "Purchase Line";
        SalesGLAccount: record "G/L Account";
        PurchGLAccount: record "G/L Account";
        PurchHeader: record "Purchase Header";
        TempPurchLine: record "Purchase Line" temporary;
        PurchOrder: testpage "Purchase Order";
    begin
        // [FEATURES] [Tax In Documents]
        // [SCENARIO] Création d'une taxe et affectation à un article et un client sur une commande d'achat (tva non incluse) puis lancer

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // [GIVEN] Création d'un article, un client et les taxes liées
        TaxHelper.CreateTax(Tax, DescriptionEmptyErr, CalculType::Line, AppliedOption::"Posting Date", DefaultRateType::Percent, 10);
        TaxHelper.CreateThirdPartyAndItemTax(Vendor, POItem, Tax, SalesGLAccount, PurchGLAccount, DefaultRateType::Percent, 10);

        // [WHEN] Création facture d'achat avec ligne article puis lancement et validation du document
        LibraryPurchase.CreatePurchHeader(PurchHeader, Enum::"Purchase Document Type"::Order, Vendor."No.");
        PurchHeader."Posting Date" := Calcdate('<-1d>', Today());

        PurchHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, Enum::"Purchase Line Type"::Item, POItem."No.", 2);
        PurchLine.Validate("Direct Unit Cost", 100);
        PurchLine.Modify(true);

        Commit();

        TempPurchLine.DeleteAll();
        TaxHelper.ExpectedPurchLineValue(TempPurchLine, PurchHeader, 10000, Enum::"Purchase Line Type"::Item, POItem."No.", PurchLine."Variant Code", 2, '', False, 0, 24, 100, 240);
        TaxHelper.ExpectedPurchLineValue(TempPurchLine, PurchHeader, 20000, Enum::"Purchase Line Type"::"G/L Account", PurchGLAccount."No.", '', 2, Tax.Code, True, 10000, 0, 10, 24);

        PurchOrder.OpenEdit();
        PurchOrder.GoToRecord(PurchHeader);
        PurchOrder.Release.Invoke();
        PurchOrder.Close();

        // [THEN] Vérification des valeurs de taxe dans la facture généré
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        if not PurchLine.IsEmpty() then
            TaxHelper.ComparePurchExpectedAndResultLine(TempPurchLine, PurchLine)
        else
            error(NoSalesLineFoundErr);
    end;

    [Test]
    procedure TestTaxWhenReleasePurchOrderInclVAT()
    var
        POItem: record Item;
        Tax: record CAGTX_Tax;
        Vendor: record Vendor;
        PurchLine: record "Purchase Line";
        SalesGLAccount: record "G/L Account";
        PurchGLAccount: record "G/L Account";
        PurchHeader: record "Purchase Header";
        TempPurchLine: record "Purchase Line" temporary;
        PurchOrder: testpage "Purchase Order";
    begin
        // [FEATURES] [Tax In Documents]
        // [SCENARIO] Création d'une taxe et affectation à un article et un client sur une commande d'achat (tva incluse) puis lancer

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // [GIVEN] Création d'un article, un client et les taxes liées
        TaxHelper.CreateTax(Tax, DescriptionEmptyErr, CalculType::Line, AppliedOption::"Posting Date", DefaultRateType::Percent, 10);
        TaxHelper.CreateThirdPartyAndItemTax(Vendor, POItem, Tax, SalesGLAccount, PurchGLAccount, DefaultRateType::Percent, 10);

        // [WHEN] Création facture d'achat avec ligne article puis lancement et validation du document
        LibraryPurchase.CreatePurchHeader(PurchHeader, Enum::"Purchase Document Type"::Order, Vendor."No.");
        PurchHeader."Posting Date" := Calcdate('<-1d>', Today());
        PurchHeader."Prices Including VAT" := true;
        PurchHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, Enum::"Purchase Line Type"::Item, POItem."No.", 2);
        PurchLine.Validate("Direct Unit Cost", 100);
        PurchLine.Modify(true);

        Commit();

        TempPurchLine.DeleteAll();
        TaxHelper.ExpectedPurchLineValue(TempPurchLine, PurchHeader, 10000, Enum::"Purchase Line Type"::Item, POItem."No.", PurchLine."Variant Code", 2, '', False, 0, 20, 100, 200);
        TaxHelper.ExpectedPurchLineValue(TempPurchLine, PurchHeader, 20000, Enum::"Purchase Line Type"::"G/L Account", PurchGLAccount."No.", '', 2, Tax.Code, True, 10000, 0, 10, 20);

        PurchOrder.OpenEdit();
        PurchOrder.GoToRecord(PurchHeader);
        PurchOrder.Release.Invoke();
        PurchOrder.Close();

        // [THEN] Vérification des valeurs de taxe dans la facture généré
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        if not PurchLine.IsEmpty() then
            TaxHelper.ComparePurchExpectedAndResultLine(TempPurchLine, PurchLine)
        else
            error(NoSalesLineFoundErr);
    end;

    [Test]
    procedure TestTaxWhenPostPurchOrderExclVAT()
    var
        POItem: record Item;
        Tax: record CAGTX_Tax;
        Vendor: record Vendor;
        PurchLine: record "Purchase Line";
        SalesGLAccount: record "G/L Account";
        PurchGLAccount: record "G/L Account";
        PurchHeader: record "Purchase Header";
        PurchInvHeader: record "Purch. Inv. Header";
        PurchInvLine: record "Purch. Inv. Line";
        TempPurchInvLine: record "Purch. Inv. Line" temporary;
    begin
        // [FEATURES] [Tax In Documents]
        // [SCENARIO] Création d'une taxe et affectation à un article et un client sur une commande d'achat (tva non incluse) puis valider

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // [GIVEN] Création d'un article, un client et les taxes liées
        TaxHelper.CreateTax(Tax, DescriptionEmptyErr, CalculType::Line, AppliedOption::"Posting Date", DefaultRateType::Percent, 10);
        TaxHelper.CreateThirdPartyAndItemTax(Vendor, POItem, Tax, SalesGLAccount, PurchGLAccount, DefaultRateType::Percent, 10);

        // [WHEN] Création facture d'achat avec ligne article puis lancement et validation du document
        LibraryPurchase.CreatePurchHeader(PurchHeader, Enum::"Purchase Document Type"::Order, Vendor."No.");
        PurchHeader."Posting Date" := Calcdate('<-1d>', Today());
        PurchHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, Enum::"Purchase Line Type"::Item, POItem."No.", 2);
        PurchLine.Validate("Direct Unit Cost", 100);
        PurchLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchHeader);

        PurchInvHeader.get(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));

        TempPurchInvLine.DeleteAll();
        TaxHelper.ExpectedPurchInvLineValue(TempPurchInvLine, PurchInvHeader, 10000, Enum::"Purchase Line Type"::Item, POItem."No.", PurchLine."Variant Code", 2, '', False, 0, 100, 240);
        TaxHelper.ExpectedPurchInvLineValue(TempPurchInvLine, PurchInvHeader, 20000, Enum::"Purchase Line Type"::"G/L Account", PurchGLAccount."No.", '', 2, Tax.Code, True, 10000, 10, 24);

        // [THEN] Vérification des valeurs de taxe dans la facture généré
        PurchInvLine.Reset();
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        if not PurchInvLine.IsEmpty() then
            TaxHelper.ComparePostedPurchExpectedAndResultLine(TempPurchInvLine, PurchInvLine)
        else
            error(NoSalesLineFoundErr);
    end;

    [Test]
    procedure TestTaxWhenPostPurchOrderInclVAT()
    var
        POItem: record Item;
        Tax: record CAGTX_Tax;
        Vendor: record Vendor;
        PurchLine: record "Purchase Line";
        SalesGLAccount: record "G/L Account";
        PurchGLAccount: record "G/L Account";
        PurchHeader: record "Purchase Header";
        PurchInvHeader: record "Purch. Inv. Header";
        PurchInvLine: record "Purch. Inv. Line";
        TempPurchInvLine: record "Purch. Inv. Line" temporary;
    begin
        // [FEATURES] [Tax In Documents]
        // [SCENARIO] Création d'une taxe et affectation à un article et un client sur une commande d'achat (tva incluse) puis valider

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // [GIVEN] Création d'un article, un client et les taxes liées
        TaxHelper.CreateTax(Tax, DescriptionEmptyErr, CalculType::Line, AppliedOption::"Posting Date", DefaultRateType::Percent, 10);
        TaxHelper.CreateThirdPartyAndItemTax(Vendor, POItem, Tax, SalesGLAccount, PurchGLAccount, DefaultRateType::Percent, 10);

        // [WHEN] Création facture d'achat avec ligne article puis lancement et validation du document
        LibraryPurchase.CreatePurchHeader(PurchHeader, Enum::"Purchase Document Type"::Order, Vendor."No.");
        PurchHeader."Posting Date" := Calcdate('<-1d>', Today());
        PurchHeader."Prices Including VAT" := true;
        PurchHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, Enum::"Purchase Line Type"::Item, POItem."No.", 2);
        PurchLine.Validate("Direct Unit Cost", 100);
        PurchLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchHeader);

        PurchInvHeader.get(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));

        TempPurchInvLine.DeleteAll();
        TaxHelper.ExpectedPurchInvLineValue(TempPurchInvLine, PurchInvHeader, 10000, Enum::"Purchase Line Type"::Item, POItem."No.", PurchLine."Variant Code", 2, '', False, 0, 100, 200);
        TaxHelper.ExpectedPurchInvLineValue(TempPurchInvLine, PurchInvHeader, 20000, Enum::"Purchase Line Type"::"G/L Account", PurchGLAccount."No.", '', 2, Tax.Code, True, 10000, 10, 20);

        // [THEN] Vérification des valeurs de taxe dans la facture généré
        PurchInvLine.Reset();
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        if not PurchInvLine.IsEmpty() then
            TaxHelper.ComparePostedPurchExpectedAndResultLine(TempPurchInvLine, PurchInvLine)
        else
            error(NoSalesLineFoundErr);
    end;

    [Test]
    procedure TestTaxWhenReleasePurchInvoiceExclVAT()
    var
        PIItem: record Item;
        Tax: record CAGTX_Tax;
        Vendor: record Vendor;
        PurchLine: record "Purchase Line";
        SalesGLAccount: record "G/L Account";
        PurchGLAccount: record "G/L Account";
        PurchHeader: record "Purchase Header";
        TempPurchLine: record "Purchase Line" temporary;
        PurchInvoice: testpage "Purchase Invoice";
    begin
        // [FEATURES] [Tax In Documents]
        // [SCENARIO] Création d'une taxe et affectation à un article et un client sur une Facture d'achat (tva non incluse) puis lancer

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // [GIVEN] Création d'un article, un client et les taxes liées
        TaxHelper.CreateTax(Tax, DescriptionEmptyErr, CalculType::Line, AppliedOption::"Posting Date", DefaultRateType::Percent, 10);
        TaxHelper.CreateThirdPartyAndItemTax(Vendor, PIItem, Tax, SalesGLAccount, PurchGLAccount, DefaultRateType::Percent, 10);

        Commit();

        // [WHEN] Création facture d'achat avec ligne article puis lancement du document
        LibraryPurchase.CreatePurchHeader(PurchHeader, Enum::"Sales Document Type"::Invoice, Vendor."No.");
        PurchHeader."Posting Date" := Calcdate('<-1d>', Today());
        PurchHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, Enum::"Purchase Line Type"::Item, PIItem."No.", 2);
        PurchLine.Validate("Direct Unit Cost", 100);
        PurchLine.Modify(true);

        TempPurchLine.DeleteAll();
        TaxHelper.ExpectedPurchLineValue(TempPurchLine, PurchHeader, 10000, Enum::"Purchase Line Type"::Item, PIItem."No.", PurchLine."Variant Code", 2, '', False, 0, 24, 100, 240);
        TaxHelper.ExpectedPurchLineValue(TempPurchLine, PurchHeader, 20000, Enum::"Purchase Line Type"::"G/L Account", PurchGLAccount."No.", '', 2, Tax.Code, True, 10000, 0, 10, 24);

        PurchInvoice.OpenEdit();
        PurchInvoice.GoToRecord(PurchHeader);
        PurchInvoice."Re&lease".Invoke();
        PurchInvoice.Close();

        // [THEN] Vérification des valeurs de taxe dans la facture généré
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Invoice);
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        if not PurchLine.IsEmpty() then
            TaxHelper.ComparePurchExpectedAndResultLine(TempPurchLine, PurchLine)
        else
            error(NoSalesLineFoundErr);
    end;

    [Test]
    procedure TestTaxWhenReleasePurchInvoiceInclVAT()
    var
        PIItem: record Item;
        Tax: record CAGTX_Tax;
        Vendor: record Vendor;
        PurchLine: record "Purchase Line";
        SalesGLAccount: record "G/L Account";
        PurchGLAccount: record "G/L Account";
        PurchHeader: record "Purchase Header";
        TempPurchLine: record "Purchase Line" temporary;
        PurchInvoice: testpage "Purchase Invoice";
    begin
        // [FEATURES] [Tax In Documents]
        // [SCENARIO] Création d'une taxe et affectation à un article et un client sur une Facture d'achat (tva incluse) puis lancer

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // [GIVEN] Création d'un article, un client et les taxes liées
        TaxHelper.CreateTax(Tax, DescriptionEmptyErr, CalculType::Line, AppliedOption::"Posting Date", DefaultRateType::Percent, 10);
        TaxHelper.CreateThirdPartyAndItemTax(Vendor, PIItem, Tax, SalesGLAccount, PurchGLAccount, DefaultRateType::Percent, 10);

        Commit();

        // [WHEN] Création facture d'achat avec ligne article puis lancement du document
        LibraryPurchase.CreatePurchHeader(PurchHeader, Enum::"Sales Document Type"::Invoice, Vendor."No.");
        PurchHeader."Posting Date" := Calcdate('<-1d>', Today());
        PurchHeader."Prices Including VAT" := true;
        PurchHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, Enum::"Purchase Line Type"::Item, PIItem."No.", 2);
        PurchLine.Validate("Direct Unit Cost", 100);
        PurchLine.Modify(true);

        TempPurchLine.DeleteAll();
        TaxHelper.ExpectedPurchLineValue(TempPurchLine, PurchHeader, 10000, Enum::"Purchase Line Type"::Item, PIItem."No.", PurchLine."Variant Code", 2, '', False, 0, 20, 100, 200);
        TaxHelper.ExpectedPurchLineValue(TempPurchLine, PurchHeader, 20000, Enum::"Purchase Line Type"::"G/L Account", PurchGLAccount."No.", '', 2, Tax.Code, True, 10000, 0, 10, 20);

        PurchInvoice.OpenEdit();
        PurchInvoice.GoToRecord(PurchHeader);
        PurchInvoice."Re&lease".Invoke();
        PurchInvoice.Close();

        // [THEN] Vérification des valeurs de taxe dans la facture généré
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Invoice);
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        if not PurchLine.IsEmpty() then
            TaxHelper.ComparePurchExpectedAndResultLine(TempPurchLine, PurchLine)
        else
            error(NoSalesLineFoundErr);
    end;

    [Test]
    procedure TestTaxWhenPostedPurchInvoiceExclVAT()
    var
        PIItem: record Item;
        Vendor: record Vendor;
        Tax: record CAGTX_Tax;
        PurchLine: record "Purchase Line";
        SalesGLAccount: record "G/L Account";
        PurchGLAccount: record "G/L Account";
        PurchHeader: record "Purchase Header";
        PurchInvLine: record "Purch. Inv. Line";
        PurchInvHeader: record "Purch. Inv. Header";
        TempPurchInvLine: record "Purch. Inv. Line" temporary;
    begin
        // [FEATURES] [Tax In Documents]
        // [SCENARIO] Création d'une taxe et affectation à un article et un client sur une Facture d'achat (tva non incluse) puis valider

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // [GIVEN] Création d'un article, un client et les taxes liées
        TaxHelper.CreateTax(Tax, DescriptionEmptyErr, CalculType::Line, AppliedOption::"Posting Date", DefaultRateType::Percent, 10);
        TaxHelper.CreateThirdPartyAndItemTax(Vendor, PIItem, Tax, SalesGLAccount, PurchGLAccount, DefaultRateType::Percent, 10);

        Commit();

        // [WHEN] Création facture d'achat avec ligne article puis lancement et validation du document
        LibraryPurchase.CreatePurchHeader(PurchHeader, Enum::"Sales Document Type"::Invoice, Vendor."No.");
        PurchHeader."Posting Date" := Calcdate('<-1d>', Today());
        PurchHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, Enum::"Purchase Line Type"::Item, PIItem."No.", 2);
        PurchLine.Validate("Direct Unit Cost", 100);
        PurchLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchHeader);

        PurchInvHeader.get(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));

        TempPurchInvLine.DeleteAll();
        TaxHelper.ExpectedPurchInvLineValue(TempPurchInvLine, PurchInvHeader, 10000, Enum::"Purchase Line Type"::Item, PIItem."No.", PurchLine."Variant Code", 2, '', False, 0, 100, 240);
        TaxHelper.ExpectedPurchInvLineValue(TempPurchInvLine, PurchInvHeader, 20000, Enum::"Purchase Line Type"::"G/L Account", PurchGLAccount."No.", '', 2, Tax.Code, True, 10000, 10, 24);

        // [THEN] Vérification des valeurs de taxe dans la facture généré
        PurchInvLine.Reset();
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        if not PurchLine.IsEmpty() then
            TaxHelper.ComparePostedPurchExpectedAndResultLine(TempPurchInvLine, PurchInvLine)
        else
            error(NoSalesLineFoundErr);
    end;

    [Test]
    procedure TestTaxWhenPostedPurchInvoiceInclVAT()
    var
        PIItem: record Item;
        Vendor: record Vendor;
        Tax: record CAGTX_Tax;
        PurchLine: record "Purchase Line";
        SalesGLAccount: record "G/L Account";
        PurchGLAccount: record "G/L Account";
        PurchHeader: record "Purchase Header";
        PurchInvLine: record "Purch. Inv. Line";
        PurchInvHeader: record "Purch. Inv. Header";
        TempPurchInvLine: record "Purch. Inv. Line" temporary;
    begin
        // [FEATURES] [Tax In Documents]
        // [SCENARIO] Création d'une taxe et affectation à un article et un client sur une Facture d'achat (tva incluse) puis valider

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // [GIVEN] Création d'un article, un client et les taxes liées
        TaxHelper.CreateTax(Tax, DescriptionEmptyErr, CalculType::Line, AppliedOption::"Posting Date", DefaultRateType::Percent, 10);
        TaxHelper.CreateThirdPartyAndItemTax(Vendor, PIItem, Tax, SalesGLAccount, PurchGLAccount, DefaultRateType::Percent, 10);

        Commit();

        // [WHEN] Création facture d'achat avec ligne article puis lancement et validation du document
        LibraryPurchase.CreatePurchHeader(PurchHeader, Enum::"Sales Document Type"::Invoice, Vendor."No.");
        PurchHeader."Posting Date" := Calcdate('<-1d>', Today());
        PurchHeader."Prices Including VAT" := true;
        PurchHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, Enum::"Purchase Line Type"::Item, PIItem."No.", 2);
        PurchLine.Validate("Direct Unit Cost", 100);
        PurchLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchHeader);

        PurchInvHeader.get(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));

        TempPurchInvLine.DeleteAll();
        TaxHelper.ExpectedPurchInvLineValue(TempPurchInvLine, PurchInvHeader, 10000, Enum::"Purchase Line Type"::Item, PIItem."No.", PurchLine."Variant Code", 2, '', False, 0, 100, 200);
        TaxHelper.ExpectedPurchInvLineValue(TempPurchInvLine, PurchInvHeader, 20000, Enum::"Purchase Line Type"::"G/L Account", PurchGLAccount."No.", '', 2, Tax.Code, True, 10000, 10, 20);

        // [THEN] Vérification des valeurs de taxe dans la facture généré
        PurchInvLine.Reset();
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        if not PurchLine.IsEmpty() then
            TaxHelper.ComparePostedPurchExpectedAndResultLine(TempPurchInvLine, PurchInvLine)
        else
            error(NoSalesLineFoundErr);
    end;

    [Test]
    procedure TestTaxWhenReleasePurchCreditMemoExclVAT()
    var
        PIItem: record Item;
        Tax: record CAGTX_Tax;
        Vendor: record Vendor;
        PurchLine: record "Purchase Line";
        SalesGLAccount: record "G/L Account";
        PurchGLAccount: record "G/L Account";
        PurchHeader: record "Purchase Header";
        TempPurchLine: record "Purchase Line" temporary;
    begin
        // [FEATURES] [Tax In Documents]
        // [SCENARIO] Création d'une taxe et affectation à un article et un client sur un avoir d'achat (tva non incluse) puis lancer

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // [GIVEN] Création d'un article, un client et les taxes liées
        TaxHelper.CreateTax(Tax, DescriptionEmptyErr, CalculType::Line, AppliedOption::"Posting Date", DefaultRateType::Percent, 10);
        TaxHelper.CreateThirdPartyAndItemTax(Vendor, PIItem, Tax, SalesGLAccount, PurchGLAccount, DefaultRateType::Percent, 10);

        Commit();

        // [WHEN] Création avoir d'achat avec ligne article puis lancement du document
        LibraryPurchase.CreatePurchHeader(PurchHeader, Enum::"Sales Document Type"::Invoice, Vendor."No.");
        PurchHeader."Posting Date" := Calcdate('<-1d>', Today());
        PurchHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, Enum::"Purchase Line Type"::Item, PIItem."No.", 2);
        PurchLine.Validate("Direct Unit Cost", 100);
        PurchLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchHeader);

        TempPurchLine.DeleteAll();
        TaxHelper.ExpectedPurchLineValue(TempPurchLine, PurchHeader, 10000, Enum::"Purchase Line Type"::Item, PIItem."No.", PurchLine."Variant Code", 2, '', False, 0, 24, 100, 240);
        TaxHelper.ExpectedPurchLineValue(TempPurchLine, PurchHeader, 20000, Enum::"Purchase Line Type"::"G/L Account", PurchGLAccount."No.", '', 2, Tax.Code, True, 10000, 0, 10, 24);

        // [THEN] Vérification des valeurs de taxe dans la avoir généré
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Invoice);
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        if not PurchLine.IsEmpty() then
            TaxHelper.ComparePurchExpectedAndResultLine(TempPurchLine, PurchLine)
        else
            error(NoSalesLineFoundErr);
    end;

    [Test]
    procedure TestTaxWhenReleasePurchCreditMemoInclVAT()
    var
        PIItem: record Item;
        Tax: record CAGTX_Tax;
        Vendor: record Vendor;
        PurchLine: record "Purchase Line";
        SalesGLAccount: record "G/L Account";
        PurchGLAccount: record "G/L Account";
        PurchHeader: record "Purchase Header";
        TempPurchLine: record "Purchase Line" temporary;
    begin
        // [FEATURES] [Tax In Documents]
        // [SCENARIO] Création d'une taxe et affectation à un article et un client sur un avoir d'achat (tva incluse) puis lancer

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // [GIVEN] Création d'un article, un client et les taxes liées
        TaxHelper.CreateTax(Tax, DescriptionEmptyErr, CalculType::Line, AppliedOption::"Posting Date", DefaultRateType::Percent, 10);
        TaxHelper.CreateThirdPartyAndItemTax(Vendor, PIItem, Tax, SalesGLAccount, PurchGLAccount, DefaultRateType::Percent, 10);

        Commit();

        // [WHEN] Création avoir d'achat avec ligne article puis lancement du document
        LibraryPurchase.CreatePurchHeader(PurchHeader, Enum::"Sales Document Type"::Invoice, Vendor."No.");
        PurchHeader."Posting Date" := Calcdate('<-1d>', Today());
        PurchHeader."Prices Including VAT" := true;
        PurchHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, Enum::"Purchase Line Type"::Item, PIItem."No.", 2);
        PurchLine.Validate("Direct Unit Cost", 100);
        PurchLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchHeader);

        TempPurchLine.DeleteAll();
        TaxHelper.ExpectedPurchLineValue(TempPurchLine, PurchHeader, 10000, Enum::"Purchase Line Type"::Item, PIItem."No.", PurchLine."Variant Code", 2, '', False, 0, 20, 100, 200);
        TaxHelper.ExpectedPurchLineValue(TempPurchLine, PurchHeader, 20000, Enum::"Purchase Line Type"::"G/L Account", PurchGLAccount."No.", '', 2, Tax.Code, True, 10000, 0, 10, 20);

        // [THEN] Vérification des valeurs de taxe dans la avoir généré
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Invoice);
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        if not PurchLine.IsEmpty() then
            TaxHelper.ComparePurchExpectedAndResultLine(TempPurchLine, PurchLine)
        else
            error(NoSalesLineFoundErr);
    end;

    [Test]
    procedure TestTaxWhenPostedPurchCreditMemoExclVAT()
    var
        PIItem: record Item;
        Tax: record CAGTX_Tax;
        Vendor: record Vendor;
        PurchLine: record "Purchase Line";
        SalesGLAccount: record "G/L Account";
        PurchGLAccount: record "G/L Account";
        PurchHeader: record "Purchase Header";
        PurchInvHeader: record "Purch. Inv. Header";
        PurchInvLine: record "Purch. Inv. Line";
        TempPurchInvLine: record "Purch. Inv. Line" temporary;
    begin
        // [FEATURES] [Tax In Documents]
        // [SCENARIO] Création d'une taxe et affectation à un article et un client sur un avoir d'achat (tva non incluse) puis valider

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // [GIVEN] Création d'un article, un client et les taxes liées
        TaxHelper.CreateTax(Tax, DescriptionEmptyErr, CalculType::Line, AppliedOption::"Posting Date", DefaultRateType::Percent, 10);
        TaxHelper.CreateThirdPartyAndItemTax(Vendor, PIItem, Tax, SalesGLAccount, PurchGLAccount, DefaultRateType::Percent, 10);

        Commit();

        // [WHEN] Création avoir d'achat avec ligne article puis lancement et validation du document
        LibraryPurchase.CreatePurchHeader(PurchHeader, Enum::"Sales Document Type"::Invoice, Vendor."No.");
        PurchHeader."Posting Date" := Calcdate('<-1d>', Today());
        PurchHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, Enum::"Purchase Line Type"::Item, PIItem."No.", 2);
        PurchLine.Validate("Direct Unit Cost", 100);
        PurchLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchHeader);

        PurchInvHeader.get(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));

        TempPurchInvLine.DeleteAll();
        TaxHelper.ExpectedPurchInvLineValue(TempPurchInvLine, PurchInvHeader, 10000, Enum::"Purchase Line Type"::Item, PIItem."No.", PurchLine."Variant Code", 2, '', False, 0, 100, 240);
        TaxHelper.ExpectedPurchInvLineValue(TempPurchInvLine, PurchInvHeader, 20000, Enum::"Purchase Line Type"::"G/L Account", PurchGLAccount."No.", '', 2, Tax.Code, True, 10000, 10, 24);

        // [THEN] Vérification des valeurs de taxe dans la avoir généré
        PurchInvLine.Reset();
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        if not PurchLine.IsEmpty() then
            TaxHelper.ComparePostedPurchExpectedAndResultLine(TempPurchInvLine, PurchInvLine)
        else
            error(NoSalesLineFoundErr);
    end;

    [Test]
    procedure TestTaxWhenPostedPurchCreditMemoInclVAT()
    var
        PIItem: record Item;
        Tax: record CAGTX_Tax;
        Vendor: record Vendor;
        PurchLine: record "Purchase Line";
        SalesGLAccount: record "G/L Account";
        PurchGLAccount: record "G/L Account";
        PurchHeader: record "Purchase Header";
        PurchInvHeader: record "Purch. Inv. Header";
        PurchInvLine: record "Purch. Inv. Line";
        TempPurchInvLine: record "Purch. Inv. Line" temporary;
    begin
        // [FEATURES] [Tax In Documents]
        // [SCENARIO] Création d'une taxe et affectation à un article et un client sur un avoir d'achat (tva incluse) puis valider

        // [PERMISSIONS] Essentials, CAGTX_Admin
        PermissionTestMgt.SetO365BusinessEssentialPermissions();

        // [GIVEN] Création d'un article, un client et les taxes liées
        TaxHelper.CreateTax(Tax, DescriptionEmptyErr, CalculType::Line, AppliedOption::"Posting Date", DefaultRateType::Percent, 10);
        TaxHelper.CreateThirdPartyAndItemTax(Vendor, PIItem, Tax, SalesGLAccount, PurchGLAccount, DefaultRateType::Percent, 10);

        Commit();

        // [WHEN] Création avoir d'achat avec ligne article puis lancement et validation du document
        LibraryPurchase.CreatePurchHeader(PurchHeader, Enum::"Sales Document Type"::Invoice, Vendor."No.");
        PurchHeader."Posting Date" := Calcdate('<-1d>', Today());
        PurchHeader."Prices Including VAT" := true;
        PurchHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, Enum::"Purchase Line Type"::Item, PIItem."No.", 2);
        PurchLine.Validate("Direct Unit Cost", 100);
        PurchLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchHeader);

        PurchInvHeader.get(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));

        TempPurchInvLine.DeleteAll();
        TaxHelper.ExpectedPurchInvLineValue(TempPurchInvLine, PurchInvHeader, 10000, Enum::"Purchase Line Type"::Item, PIItem."No.", PurchLine."Variant Code", 2, '', False, 0, 100, 200);
        TaxHelper.ExpectedPurchInvLineValue(TempPurchInvLine, PurchInvHeader, 20000, Enum::"Purchase Line Type"::"G/L Account", PurchGLAccount."No.", '', 2, Tax.Code, True, 10000, 10, 20);

        // [THEN] Vérification des valeurs de taxe dans la avoir généré
        PurchInvLine.Reset();
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        if not PurchLine.IsEmpty() then
            TaxHelper.ComparePostedPurchExpectedAndResultLine(TempPurchInvLine, PurchInvLine)
        else
            error(NoSalesLineFoundErr);
    end;

    [ModalPageHandler]
    procedure ItemTaxPageHandler(var ItemTaxPage: testpage "CAGTX_Item Tax")
    var
        TypeItemTax: Option " ","G/L Account",Item,Resource;
        RateType: Option "Unit Amount",Percent,"Flat Rate";
    begin
        ItemTaxPage."Tax Code".SetValue(TaxCode);
        ItemTaxPage.Type.SetValue(TypeItemTax::Item);
        ItemTaxPage."No.".SetValue(Item."No.");
        ItemTaxPage."Variant Code".SetValue('');
        ItemTaxPage."Effective Date".SetValue(Calcdate('<-1d>', Today()));
        ItemTaxPage."Rate Type".SetValue(RateType::Percent);
        ItemTaxPage."Rate Value".SetValue(10);
    end;

    [PageHandler]
    procedure TaxAssgntoThirdPartHandler(var TaxAssgntoThirdPart: testPage "CAGTX_Tax Assgn. to Third Part")
    var
        ThirdPartType: Option "Third Party","Posting Group",All;
        LinkToTable: Option " ",Customer,Vendor;
    begin
        TaxAssgntoThirdPart."Link to Table".SetValue(LinkToTable::Customer);
        TaxAssgntoThirdPart.Type.SetValue(ThirdPartType::"Third Party");
        TaxAssgntoThirdPart."No.".SetValue(Cust."No.");
    end;
}