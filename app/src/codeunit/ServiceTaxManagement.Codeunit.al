codeunit 8062638 "CAGTX_Service Tax Management"
{

    trigger OnRun()
    begin
    end;

    var
        ModifiyFieldUpdateTaxMsg: Label 'You have changed %1 on the service header, but it has not been changed on the existing service lines.\', Comment = '%1 = service header';
        ConfirmUpdateTaxQst: Label 'Do you want to update the tax?';
        TaxLineInsertErr: Label 'There is not enough space to insert tax lines.';

    procedure GenerateTaxLine(ServiceHeader_P: Record "Service Header")
    var
        ServiceLine_L: Record "Service Line";
        Currency_L: Record Currency;
        TempCustomerTax_L: Record "CAGTX_Tax Assign. Third Party" temporary;
    begin
        if not ServiceHeader_P."CAGTX_Disable Tax Calculation" then begin
            ServiceLine_L.SetCurrentKey("CAGTX_Tax Line", "CAGTX_Tax Code", "CAGTX_Origin Tax Line");
            ServiceLine_L.SetRange("Document Type", ServiceHeader_P."Document Type");
            ServiceLine_L.SetRange("Document No.", ServiceHeader_P."No.");
            ServiceLine_L.SetRange("CAGTX_Tax Line", false);
            ServiceLine_L.SetRange(Type, ServiceLine_L.Type::Item, ServiceLine_L.Type::"G/L Account");
            ServiceLine_L.SetRange("Shipment No.", '');
            if ServiceLine_L.FindSet(true, true) then begin
                CleanTaxLine(ServiceHeader_P);

                if ServiceHeader_P."Currency Code" = '' then
                    Currency_L.InitRoundingPrecision()
                else begin
                    ServiceHeader_P.TestField("Currency Factor");
                    Currency_L.Get(ServiceHeader_P."Currency Code");
                    Currency_L.TestField("Amount Rounding Precision");
                end;
                if FindTaxCode(TempCustomerTax_L, ServiceHeader_P."Bill-to Customer No.", ServiceHeader_P."Customer Posting Group") then
                    repeat
                        CreateTaxLines(ServiceLine_L, ServiceHeader_P, Currency_L, TempCustomerTax_L);
                    until ServiceLine_L.Next() = 0;
            end;
        end;
    end;

    procedure UpdateTaxLine(p_Header: Record "Service Header"; p_ConfirmMessage: Boolean; p_FieldNo: Integer)
    var
        RecordRef_L: RecordRef;
        FieldRef_L: FieldRef;
    begin
        if not (p_Header."CAGTX_Disable Tax Calculation") then
            if ServLineExists(p_Header) then
                if p_ConfirmMessage then begin
                    RecordRef_L.GetTable(p_Header);
                    FieldRef_L := RecordRef_L.Field(p_FieldNo);
                    if Confirm(ModifiyFieldUpdateTaxMsg + ConfirmUpdateTaxQst, true, FieldRef_L.Caption) then
                        GenerateTaxLine(p_Header);
                end else
                    GenerateTaxLine(p_Header);
    end;

    local procedure CreateTaxLines(var P_Rec: Record "Service Line"; p_Header: Record "Service Header"; p_Currency: Record Currency; var P_CustomerTax: Record "CAGTX_Tax Assign. Third Party")
    var
        CMBDocTaxDetail_L: Record "CAGTX_Service Doc. Tax Detail";
    begin
        if P_CustomerTax.FindFirst() then
            repeat
                CreateTaxLine(P_Rec, p_Header, p_Currency, P_CustomerTax, CMBDocTaxDetail_L);
            until P_CustomerTax.Next() = 0;
    end;

    local procedure CreateTaxLine(var P_Rec: Record "Service Line"; p_Header: Record "Service Header"; p_Currency: Record Currency; var P_CustomerTax: Record "CAGTX_Tax Assign. Third Party"; var P_CMBDocTaxDetail: Record "CAGTX_Service Doc. Tax Detail")
    var
        Line_L: Record "Service Line";
        Tax_L: Record CAGTX_Tax;
        CMBDocTaxBuffer_L: Record "CAGTX_Doc. Tax Buffer";
        CMBTaxManagement_L: Codeunit "CAGTX_Tax Management";
        FindLineTax_L: Boolean;
    begin
        Tax_L.Get(P_CustomerTax."Tax Code");
        if (Tax_L."Service Account Type" <> Tax_L."Service Account Type"::" ") then begin
            Line_L.SetRange("Document Type", P_Rec."Document Type");
            Line_L.SetRange("Document No.", P_Rec."Document No.");
            Line_L.SetRange("CAGTX_Tax Code", Tax_L.Code);
            if Tax_L."Calcul Type" = Tax_L."Calcul Type"::Line then
                Line_L.SetRange("CAGTX_Origin Tax Line", P_Rec."Line No.")
            else
                Line_L.SetRange("CAGTX_Origin Tax Line", 0);
            Line_L.SetRange("CAGTX_Tax Line", true);
            FindLineTax_L := Line_L.FindFirst();

            SetDocTaxBuffer(P_Rec, p_Header, p_Currency, Tax_L, CMBDocTaxBuffer_L, Line_L);

            if CMBTaxManagement_L.FindTaxLine(CMBDocTaxBuffer_L) then begin
                Line_L.SuspendStatusCheck(true);

                if not FindLineTax_L then begin
                    InitTaxServiceLine(Line_L, P_Rec, Tax_L, CMBDocTaxBuffer_L);
                    if CalculateTaxAmount(Line_L, CMBDocTaxBuffer_L, not P_CustomerTax.Mark()) then begin
                        Line_L.Insert(true);
                        TransferToTaxeDetail(CMBDocTaxBuffer_L, P_CMBDocTaxDetail);
                    end;
                end else
                    if (Line_L."Quantity Invoiced" = 0) and (Line_L."Quantity Consumed" = 0)
                        and (Line_L."Qty. Shipped (Base)" <> CMBDocTaxBuffer_L."Base Quantity Tax") then
                        if CalculateTaxAmount(Line_L, CMBDocTaxBuffer_L, not P_CustomerTax.Mark()) then begin
                            Line_L.Modify(true);
                            TransferToTaxeDetail(CMBDocTaxBuffer_L, P_CMBDocTaxDetail);
                        end else
                            Line_L.Delete(true);
                P_CustomerTax.Mark(true);
            end;
        end;
    end;

    local procedure CalculateTaxAmount(var P_Line: Record "Service Line"; var P_CMBDocTaxBuffer: Record "CAGTX_Doc. Tax Buffer"; p_First: Boolean) returnValue: Boolean
    var
        CMBTaxManagement_L: Codeunit "CAGTX_Tax Management";
    begin
        P_CMBDocTaxBuffer."Tax Line No." := P_Line."Line No.";
        if P_CMBDocTaxBuffer."Calcul Type" = P_CMBDocTaxBuffer."Calcul Type"::Line then begin
            returnValue := CMBTaxManagement_L.CalculateTaxLineAmount(P_CMBDocTaxBuffer);
            if returnValue then begin
                P_Line.Validate(Quantity, P_Line.Quantity + P_CMBDocTaxBuffer."Quantity Tax Line");
                P_Line.Validate("Unit Price", P_CMBDocTaxBuffer."Tax Unit Amount");
            end;
        end else begin
            returnValue := CMBTaxManagement_L.CalculateTaxTotalAmount(P_CMBDocTaxBuffer);
            if returnValue then
                case P_CMBDocTaxBuffer."Rate Type" of
                    P_CMBDocTaxBuffer."Rate Type"::Percent:
                        begin
                            P_Line.Validate(Quantity, 1);
                            if p_First then
                                P_Line.Validate("Unit Price", P_CMBDocTaxBuffer."Amount Tax Line")
                            else
                                P_Line.Validate("Unit Price", P_Line."Unit Price" + P_CMBDocTaxBuffer."Amount Tax Line");
                        end;
                    P_CMBDocTaxBuffer."Rate Type"::"Unit Amount":
                        begin
                            if p_First then
                                P_Line.Validate(Quantity, P_CMBDocTaxBuffer."Quantity Tax Line")
                            else
                                P_Line.Validate(Quantity, P_Line.Quantity + P_CMBDocTaxBuffer."Quantity Tax Line");
                            P_Line.Validate("Unit Price", P_CMBDocTaxBuffer."Tax Unit Amount");
                        end;
                    P_CMBDocTaxBuffer."Rate Type"::"Flat Rate":
                        begin
                            P_Line.Validate(Quantity, 1);
                            P_Line.Validate("Unit Price", P_CMBDocTaxBuffer."Tax Unit Amount");
                        end;
                    else
                        OnCalculateSpecificTaxAmount(P_Line, P_CMBDocTaxBuffer, p_First);
                end;
        end;

        OnAfterCalculateTaxAmount(P_Line, P_CMBDocTaxBuffer);
        exit(returnValue);
    end;

    local procedure SetDocTaxBuffer(var P_Rec: Record "Service Line"; p_Header: Record "Service Header"; p_Currency: Record Currency; p_Tax: Record CAGTX_Tax; var P_CMBDocTaxBuffer: Record "CAGTX_Doc. Tax Buffer"; P_Line: Record "Service Line")
    begin
        P_CMBDocTaxBuffer.Init();
        P_CMBDocTaxBuffer."Table No." := DATABASE::"Service Line";
        P_CMBDocTaxBuffer."Document Type" := P_Rec."Document Type".AsInteger();
        P_CMBDocTaxBuffer."Document No." := P_Rec."Document No.";
        P_CMBDocTaxBuffer."Line No." := P_Rec."Line No.";
        case P_Rec.Type of
            P_Rec.Type::Item:
                P_CMBDocTaxBuffer.Type := P_CMBDocTaxBuffer.Type::Item;
            P_Rec.Type::Resource:
                P_CMBDocTaxBuffer.Type := P_CMBDocTaxBuffer.Type::Resource;
            P_Rec.Type::"G/L Account":
                P_CMBDocTaxBuffer.Type := P_CMBDocTaxBuffer.Type::"G/L Account";
        end;
        P_CMBDocTaxBuffer."No." := P_Rec."No.";
        P_CMBDocTaxBuffer."Posting Date" := GetEffectiveDate(p_Header, p_Tax);
        P_CMBDocTaxBuffer."Unit-Amount Rounding Precision" := p_Currency."Unit-Amount Rounding Precision";
        P_CMBDocTaxBuffer."Amount Rounding Precision" := p_Currency."Amount Rounding Precision";
        P_CMBDocTaxBuffer."Currency Code" := p_Header."Currency Code";
        P_CMBDocTaxBuffer."Prices Including VAT" := p_Header."Prices Including VAT";
        P_CMBDocTaxBuffer."Currency Factor" := p_Header."Currency Factor";
        P_CMBDocTaxBuffer."Variant Code" := P_Rec."Variant Code";
        P_CMBDocTaxBuffer."Unit of Measure Code" := P_Rec."Unit of Measure Code";
        P_CMBDocTaxBuffer."Item Category Code" := P_Rec."Item Category Code";
        P_CMBDocTaxBuffer."Tax Code" := p_Tax.Code;
        P_CMBDocTaxBuffer."Intial Posting Date" := GetInitalDate(p_Header, p_Tax);
        P_CMBDocTaxBuffer."Quantity (Base)" := P_Rec."Quantity (Base)";
        P_CMBDocTaxBuffer."Outstanding Qty. (Base)" := P_Rec."Outstanding Qty. (Base)";
        P_CMBDocTaxBuffer."Base Quantity Tax" := P_Rec."Quantity (Base)";
        P_CMBDocTaxBuffer."Quantity Tax Line" := P_CMBDocTaxBuffer."Base Quantity Tax" - P_Line."Qty. Shipped (Base)";
        P_CMBDocTaxBuffer."Unit Amount" := P_Rec."Unit Price";
        P_CMBDocTaxBuffer."Qty. per Unit of Measure" := P_Rec."Qty. per Unit of Measure";
        P_CMBDocTaxBuffer."Line Discount %" := P_Rec."Line Discount %";

        if p_Tax."Tax Apply on VAT" then
            P_CMBDocTaxBuffer."VAT %" := P_Rec."VAT %";

        if p_Tax."Allow Line Disc." then
            P_CMBDocTaxBuffer."Base Amount Tax" := P_Rec."Line Amount"
        else
            P_CMBDocTaxBuffer."Base Amount Tax" := P_Rec."Unit Price" * P_Rec.Quantity;

        P_CMBDocTaxBuffer."Rate value" := 0;
        P_CMBDocTaxBuffer."Rate Type" := 0;
        P_CMBDocTaxBuffer."Calcul Type" := p_Tax."Calcul Type";
        P_CMBDocTaxBuffer."Tax VAT %" := GetVATPersent(p_Tax, p_Header."VAT Bus. Posting Group");
        P_CMBDocTaxBuffer."Amount Tax Line" := 0;
        P_CMBDocTaxBuffer."Application Order" := 1;
        P_CMBDocTaxBuffer."Calculate Tax on Tax" := false;
        OnAfterSetDocTaxBuffer(P_Rec, p_Header, p_Currency, p_Tax, P_CMBDocTaxBuffer);
    end;

    local procedure TransferToTaxeDetail(var P_CMBDocTaxBuffer: Record "CAGTX_Doc. Tax Buffer"; var P_CMBDocTaxDetail: Record "CAGTX_Service Doc. Tax Detail")
    begin
        P_CMBDocTaxDetail.TransferFields(P_CMBDocTaxBuffer, true);
        if not P_CMBDocTaxDetail.Insert() then
            P_CMBDocTaxDetail.Modify();
    end;

    local procedure FindTaxCode(var P_CustomerTax: Record "CAGTX_Tax Assign. Third Party"; p_Code: Code[20]; p_PostingGroup: Code[20]) Find_r: Boolean
    var
        CustomerTax_L: Record "CAGTX_Tax Assign. Third Party";
        SetMarkFilter: Boolean;
    begin
        P_CustomerTax.DeleteAll();
        CustomerTax_L.Reset();
        if CustomerTax_L."Tax Code" <> '' then
            CustomerTax_L.SetRange("Tax Code", CustomerTax_L."Tax Code")
        else
            SetMarkFilter := true;
        CustomerTax_L.SetRange("Link to Table", CustomerTax_L."Link to Table"::Customer);
        CustomerTax_L.SetRange(Type, CustomerTax_L.Type::"Third Party");
        CustomerTax_L.SetRange("No.", p_Code);
        Find_r := CustomerTax_L.FindSet();
        if Find_r then
            repeat
                P_CustomerTax := CustomerTax_L;
                if P_CustomerTax.Insert() then;
            until CustomerTax_L.Next() = 0;

        if not Find_r or SetMarkFilter then
            if (p_PostingGroup <> '') then begin
                CustomerTax_L.SetRange(Type, CustomerTax_L.Type::"Posting Group");
                CustomerTax_L.SetRange("No.", p_PostingGroup);
                Find_r := CustomerTax_L.FindSet();
                if Find_r and SetMarkFilter then
                    repeat
                        P_CustomerTax := CustomerTax_L;
                        if P_CustomerTax.Insert() then;
                    until CustomerTax_L.Next() = 0;
            end;
        if not Find_r or SetMarkFilter then begin
            CustomerTax_L.SetRange(Type, CustomerTax_L.Type::All);
            CustomerTax_L.SetRange("No.");
            Find_r := CustomerTax_L.FindSet();
            if Find_r and SetMarkFilter then
                repeat
                    P_CustomerTax := CustomerTax_L;
                    if P_CustomerTax.Insert() then;
                until CustomerTax_L.Next() = 0;
        end;

        if SetMarkFilter then
            Find_r := not P_CustomerTax.IsEmpty();
        exit(Find_r);
    end;

    local procedure InitTaxServiceLine(var P_Line: Record "Service Line"; var P_Rec: Record "Service Line"; p_Tax: Record CAGTX_Tax; p_CMBDocTaxBuffer: Record "CAGTX_Doc. Tax Buffer")
    begin
        P_Line.Init();
        P_Line."Document Type" := ConvertOptionToServiceEnum(p_CMBDocTaxBuffer."Document Type");
        P_Line."Document No." := p_CMBDocTaxBuffer."Document No.";
        P_Line."Line No." := GetLineNo(P_Rec, p_CMBDocTaxBuffer."Calcul Type");
        case p_Tax."Service Account Type" of
            p_Tax."Service Account Type"::Resource:
                P_Line.Type := P_Line.Type::Resource;
            p_Tax."Service Account Type"::"G/L Account":
                P_Line.Type := P_Line.Type::"G/L Account";
        end;
        P_Line.Validate("No.", p_Tax."Service Account No.");
        P_Line."CAGTX_Tax Code" := p_CMBDocTaxBuffer."Tax Code";
        P_Line."CAGTX_Tax Line" := true;
        if p_CMBDocTaxBuffer."Calcul Type" = p_CMBDocTaxBuffer."Calcul Type"::Line then
            P_Line."CAGTX_Origin Tax Line" := p_CMBDocTaxBuffer."Line No."
        else
            P_Line."CAGTX_Origin Tax Line" := 0;

        P_Line."Service Item No." := P_Rec."Service Item No.";
        P_Line."Service Item Line No." := P_Rec."Service Item Line No.";
        P_Line."Job No." := P_Rec."Job No.";
        P_Line."Job Task No." := P_Rec."Job Task No.";
        P_Line."Job Line Type" := P_Rec."Job Line Type";
        P_Line."Job Planning Line No." := P_Rec."Job Planning Line No.";

        P_Line."CAGTX_Hide Tax Line" := not (p_Tax."Show Line");
        P_Line."Allow Invoice Disc." := (p_Tax."Allow Invoice Disc.");
        P_Line."Location Code" := P_Rec."Location Code";
    end;

    local procedure GetLineNo(var P_Rec: Record "Service Line"; pTaxType: Option Line,Total) rLineNo: Integer
    var
        Line2_L: Record "Service Line";
        LastLineTax_L: Integer;
        EoR_L: Boolean;
        LineSpacing_L: Integer;
    begin
        Line2_L := P_Rec;
        Line2_L.SetRange("Document Type", P_Rec."Document Type");
        Line2_L.SetRange("Document No.", P_Rec."Document No.");
        if pTaxType = pTaxType::Line then begin
            LastLineTax_L := P_Rec."Line No.";
            EoR_L := Line2_L.Find('>');
            if ((Line2_L."Attached to Line No." <> 0) or (Line2_L."CAGTX_Origin Tax Line" <> 0)) then
                LastLineTax_L := Line2_L."Line No.";
            while ((Line2_L."Attached to Line No." <> 0) or (Line2_L."CAGTX_Origin Tax Line" <> 0)) and EoR_L do begin
                EoR_L := Line2_L.Find('>');
                if ((Line2_L."Attached to Line No." <> 0) or (Line2_L."CAGTX_Origin Tax Line" <> 0)) then
                    LastLineTax_L := Line2_L."Line No.";
            end;
            if EoR_L then begin
                LineSpacing_L := (Line2_L."Line No." - LastLineTax_L) div 2;
                if LineSpacing_L = 0 then
                    Error(TaxLineInsertErr);
                rLineNo := LastLineTax_L + LineSpacing_L;
            end else begin
                LineSpacing_L := 10000;
                rLineNo := LastLineTax_L + LineSpacing_L;
            end;
        end else begin
            if Line2_L.FindLast() then
                rLineNo := Line2_L."Line No." + 10000;
            while Line2_L.Get(P_Rec."Document Type", P_Rec."Document No.", rLineNo) do
                rLineNo += 10000;
        end;
    end;

    local procedure GetEffectiveDate(p_Header: Record "Service Header"; p_Tax: Record CAGTX_Tax) r_Effectivedate: Date
    begin
        case p_Tax."Applied Option" of
            p_Tax."Applied Option"::"Posting Date":
                r_Effectivedate := p_Header."Posting Date";
            p_Tax."Applied Option"::"Document Date":
                r_Effectivedate := p_Header."Document Date";
            p_Tax."Applied Option"::"Order Date":
                r_Effectivedate := p_Header."Order Date";
        end;

        if r_Effectivedate = 0D then
            r_Effectivedate := WorkDate();
    end;

    local procedure GetInitalDate(p_Header: Record "Service Header"; p_Tax: Record CAGTX_Tax) r_Effectivedate: Date
    var
        OrderFirstInvDate_L: Query "CAGTX_Serv. Ord. Frst Inv Date";
    begin
        if not (p_Header."Document Type" in [p_Header."Document Type"::Order]) then
            exit(0D);

        OrderFirstInvDate_L.SetRange(Order_No, p_Header."No.");
        OrderFirstInvDate_L.Open();
        if not OrderFirstInvDate_L.Read() then
            exit(0D);

        case p_Tax."Applied Option" of
            p_Tax."Applied Option"::"Posting Date":
                r_Effectivedate := OrderFirstInvDate_L.Posting_Date;
            p_Tax."Applied Option"::"Document Date":
                r_Effectivedate := OrderFirstInvDate_L.Document_Date;
            p_Tax."Applied Option"::"Order Date":
                r_Effectivedate := OrderFirstInvDate_L.Order_Date;
        end;
    end;

    local procedure GetVATPersent(p_Tax: Record CAGTX_Tax; p_VATBusPostingGp: Code[20]): Decimal
    var
        GLAccount_L: Record "G/L Account";
        Resource_L: Record Resource;
        VATPostingSetup_L: Record "VAT Posting Setup";
    begin
        case p_Tax."Service Account Type" of
            p_Tax."Service Account Type"::"G/L Account":
                begin
                    GLAccount_L.Get(p_Tax."Service Account No.");
                    VATPostingSetup_L.Get(p_VATBusPostingGp, GLAccount_L."VAT Prod. Posting Group");
                end;
            p_Tax."Service Account Type"::Resource:
                begin
                    Resource_L.Get(p_Tax."Service Account No.");
                    VATPostingSetup_L.Get(p_VATBusPostingGp, Resource_L."VAT Prod. Posting Group");
                end;
            else
                VATPostingSetup_L.Init();
        end;
        exit(VATPostingSetup_L."VAT %");
    end;

    local procedure ServLineExists(p_ServiceHeader: Record "Service Header"): Boolean
    var
        Line_L: Record "Service Line";
    begin
        Line_L.Reset();
        Line_L.SetRange("Document Type", p_ServiceHeader."Document Type");
        Line_L.SetRange("Document No.", p_ServiceHeader."No.");
        exit(not Line_L.IsEmpty);
    end;

    procedure DeleteTaxLine(p_Rec: Record "Service Line")
    var
        Line_L: Record "Service Line";
        CMBDocTaxDetail_L: Record "CAGTX_Service Doc. Tax Detail";
    begin
        Line_L.Reset();
        Line_L.SetCurrentKey("CAGTX_Tax Line", "CAGTX_Tax Code", "CAGTX_Origin Tax Line");
        Line_L.SetRange("Document Type", p_Rec."Document Type");
        Line_L.SetRange("Document No.", p_Rec."Document No.");
        Line_L.SetRange("CAGTX_Tax Line", true);
        Line_L.SetRange("CAGTX_Origin Tax Line", p_Rec."Line No.");
        if not Line_L.IsEmpty then
            Line_L.DeleteAll(true);

        CMBDocTaxDetail_L.Reset();
        CMBDocTaxDetail_L.SetRange("Document Type", p_Rec."Document Type");
        CMBDocTaxDetail_L.SetRange("Document No.", p_Rec."Document No.");
        if p_Rec."CAGTX_Tax Line" then
            CMBDocTaxDetail_L.SetRange("Tax Line No.", p_Rec."Line No.")
        else
            CMBDocTaxDetail_L.SetRange("Line No.", p_Rec."Line No.");
        if not CMBDocTaxDetail_L.IsEmpty then
            CMBDocTaxDetail_L.DeleteAll(true);


    end;

    local procedure CleanTaxLine(p_Header: Record "Service Header")
    var
        Line_L: Record "Service Line";
        Line2_L: Record "Service Line";
        CMBDocTaxDetail_L: Record "CAGTX_Service Doc. Tax Detail";
    begin
        Line_L.SetCurrentKey("CAGTX_Tax Line", "CAGTX_Tax Code", "CAGTX_Origin Tax Line");
        Line_L.SetRange("Document Type", p_Header."Document Type");
        Line_L.SetRange("Document No.", p_Header."No.");
        Line_L.SetRange("CAGTX_Tax Line", true);
        Line_L.SetRange("Shipment No.", '');
        if not Line_L.IsEmpty() then begin
            Line_L.FindSet();
            repeat
                if Line_L.Quantity = Line_L."Outstanding Quantity" then begin
                    Line2_L := Line_L;
                    Line2_L.SuspendStatusCheck(true);
                    if Line2_L.Delete(true) then begin
                        CMBDocTaxDetail_L.SetRange("Document Type", Line_L."Document Type");
                        CMBDocTaxDetail_L.SetRange("Document No.", Line_L."Document No.");
                        CMBDocTaxDetail_L.SetRange("Tax Line No.", Line_L."Line No.");
                        if not CMBDocTaxDetail_L.IsEmpty() then
                            CMBDocTaxDetail_L.DeleteAll(true);
                    end;
                end;
            until Line_L.Next() = 0;
        end;
    end;

    procedure SetTaxLineQtyToPost(Line_P: Record "Service Line")
    var
        TaxLine_L: Record "Service Line";
        Tax_L: Record CAGTX_Tax;
        NewTaxLine_L: Record "Service Line";
        TempTaxLine_L: Record "Service Line" temporary;
        AppAccessMgt: Codeunit CAGTX_AppAccessMgt;
    begin
        if not AppAccessMgt.IsAppAccessAllowed(false) then
            exit;

        TaxLine_L.SetCurrentKey("CAGTX_Tax Line", "CAGTX_Tax Code", "CAGTX_Origin Tax Line");
        TaxLine_L.SetRange("Document Type", Line_P."Document Type");
        TaxLine_L.SetRange("Document No.", Line_P."Document No.");
        TaxLine_L.SetRange("CAGTX_Tax Line", true);
        if TaxLine_L.FindSet(true, false) then
            repeat
                Tax_L.Get(TaxLine_L."CAGTX_Tax Code");
                if (Tax_L."Calcul Type" = Tax_L."Calcul Type"::Line) then begin
                    if (TaxLine_L."CAGTX_Origin Tax Line" = Line_P."Line No.") then
                        SetTaxQtyToPostLine(TaxLine_L, Tax_L);
                end else
                    SetTaxQtyToPostTotal(TaxLine_L, /*Tax_L,*/ Line_P."Line No.");
            until TaxLine_L.Next() = 0;

        if TempTaxLine_L.FindFirst() then begin
            NewTaxLine_L.Init();
            NewTaxLine_L.TransferFields(TempTaxLine_L);
            NewTaxLine_L.Insert();
        end;
    end;

    procedure GetTaxQtyToPostLine(var P_TaxLine: Record "Service Line"; P_OriginLine: Record "Service Line"; p_Tax: Record CAGTX_Tax) returnValue: Decimal
    begin
        exit(GetOrigineQtyToPost(P_OriginLine, P_OriginLine."Line No."));
    end;

    local procedure GetOrigineQtyToPost(p_OrgineLine: Record "Service Line"; p_Line: Integer) returnValue: Decimal
    begin
        if (p_Line <> 0) and (p_Line <> p_OrgineLine."Line No.") then
            returnValue := 0
        else
            if p_OrgineLine."Document Type" in [p_OrgineLine."Document Type"::"Credit Memo"] then
                returnValue := p_OrgineLine."Qty. to Ship (Base)"
            else
                returnValue := p_OrgineLine."Qty. to Ship (Base)";
    end;

    local procedure SetTaxQtyToPostLine(var P_TaxLine: Record "Service Line"; p_Tax: Record CAGTX_Tax)
    var
        OriginLine_L: Record "Service Line";
    begin
        OriginLine_L.Get(P_TaxLine."Document Type", P_TaxLine."Document No.", P_TaxLine."CAGTX_Origin Tax Line");
        if OriginLine_L."Document Type" in [OriginLine_L."Document Type"::"Credit Memo"] then
            P_TaxLine.Validate("Qty. to Ship (Base)", GetTaxQtyToPostLine(P_TaxLine, OriginLine_L, p_Tax))
        else
            P_TaxLine.Validate("Qty. to Ship (Base)", GetTaxQtyToPostLine(P_TaxLine, OriginLine_L, p_Tax));

        P_TaxLine.Modify();
    end;

    local procedure GetTaxQtyToPostTotal(var P_TaxLine: Record "Service Line"; /*p_Tax: Record CAGTX_Tax;*/ p_LineNo: Integer) returnValue: Decimal
    var
        OriginLine_L: Record "Service Line";
        CMBDocTaxDetail_L: Record "CAGTX_Service Doc. Tax Detail";
        RatioQty: Decimal;
        AmountToShip: Decimal;
        FullShip: Boolean;
    begin
        CMBDocTaxDetail_L.SetRange("Document Type", P_TaxLine."Document Type");
        CMBDocTaxDetail_L.SetRange("Document No.", P_TaxLine."Document No.");
        CMBDocTaxDetail_L.SetRange("Tax Line No.", P_TaxLine."Line No.");
        FullShip := true;
        if CMBDocTaxDetail_L.FindSet() then
            repeat
                if OriginLine_L.Get(CMBDocTaxDetail_L."Document Type", CMBDocTaxDetail_L."Document No.", CMBDocTaxDetail_L."Line No.") then begin
                    if OriginLine_L.Quantity <> 0 then
                        RatioQty := GetOrigineQtyToPost(OriginLine_L, p_LineNo) / OriginLine_L.Quantity;
                    if (OriginLine_L."Outstanding Quantity" <> OriginLine_L."Qty. to Ship") then
                        FullShip := false;
                    AmountToShip += CMBDocTaxDetail_L."Amount Tax Line" * RatioQty;
                end;
            until CMBDocTaxDetail_L.Next() = 0;

        if FullShip then
            returnValue := P_TaxLine."Outstanding Quantity"
        else
            if (P_TaxLine."Line Amount" <> 0) and (P_TaxLine."Outstanding Quantity" <> 0) then
                returnValue := Round((AmountToShip / P_TaxLine."Line Amount") * P_TaxLine.Quantity);

    end;

    local procedure SetTaxQtyToPostTotal(var P_TaxLine: Record "Service Line"; /*p_Tax: Record CAGTX_Tax;*/ p_LineNo: Integer)
    var
        OriginLine_L: Record "Service Line";
        CMBDocTaxDetail_L: Record "CAGTX_Service Doc. Tax Detail";
    begin
        CMBDocTaxDetail_L.SetRange("Document Type", P_TaxLine."Document Type");
        CMBDocTaxDetail_L.SetRange("Document No.", P_TaxLine."Document No.");
        CMBDocTaxDetail_L.SetRange("Tax Line No.", P_TaxLine."Line No.");
        if p_LineNo <> 0 then
            CMBDocTaxDetail_L.SetRange("Line No.", p_LineNo);
        if P_TaxLine."CAGTX_Origin Tax Line" <> 0 then
            CMBDocTaxDetail_L.SetRange("Line No.", P_TaxLine."CAGTX_Origin Tax Line");
        if CMBDocTaxDetail_L.FindFirst() then begin
            OriginLine_L.Get(P_TaxLine."Document Type", P_TaxLine."Document No.", CMBDocTaxDetail_L."Line No.");
            if OriginLine_L."Document Type" in [OriginLine_L."Document Type"::"Credit Memo"] then
                P_TaxLine.Validate("Qty. to Ship (Base)", GetTaxQtyToPostTotal(P_TaxLine,/* p_Tax,*/ p_LineNo))
            else
                P_TaxLine.Validate("Qty. to Ship (Base)",
              GetTaxQtyToPostTotal(P_TaxLine,/* p_Tax,*/ p_LineNo));
            P_TaxLine.Modify();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDocTaxBuffer(var P_Rec: Record "Service Line"; p_Header: Record "Service Header"; p_Currency: Record Currency; p_Tax: Record CAGTX_Tax; var P_CMBDocTaxBuffer: Record "CAGTX_Doc. Tax Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateTaxAmount(var P_Line: Record "Service Line"; var P_CMBDocTaxBuffer: Record "CAGTX_Doc. Tax Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateSpecificTaxAmount(var P_Line: Record "Service Line"; var P_CMBDocTaxBuffer: Record "CAGTX_Doc. Tax Buffer"; p_First: Boolean)
    begin
    end;

    local procedure ConvertOptionToServiceEnum(ServiceDocType: Option Quote,"Order",Invoice,"Credit Memo"): Enum "Service Document Type"
    begin
        Case ServiceDocType of
            ServiceDocType::Quote:
                exit("Service Document Type"::Quote);
            ServiceDocType::"Order":
                exit("Service Document Type"::Order);
            ServiceDocType::Invoice:
                exit("Service Document Type"::Invoice);
            ServiceDocType::"Credit Memo":
                exit("Service Document Type"::"Credit Memo");
        end;
    end;
}

