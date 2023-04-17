codeunit 8062637 "CAGTX_Purch. Tax Management"
{

    Permissions = TableData "Purch. Rcpt. Line" = rim,
                  TableData "Return Shipment Line" = rim;

    var
        ModifiyFieldUpdateTaxMsg: Label 'You have changed %1 on the purchase header, but it has not been changed on the existing purchase lines.\', Comment = '%1 = purchase header';
        ConfirmUpdateTaxQst: Label 'Do you want to update the tax?';
        Text002_Lbl: Label 'There is not enough space to insert tax lines.';
        TaxLineDeleteErr: Label 'You cannot delete a tax line that refers to a line partially or fully received.';

    procedure GenerateTaxLine(p_Header: Record "Purchase Header")
    var
        Line_L: Record "Purchase Line";
        Currency_L: Record Currency;
        TempCustomerTax_L: Record "CAGTX_Tax Assign. Third Party" temporary;
        AppAccessMgt: Codeunit CAGTX_AppAccessMgt;
    begin
        if not AppAccessMgt.IsAppAccessAllowed(false) then
            exit;

        if not p_Header."CAGTX_Disable Tax Calculation" then begin
            Line_L.SetCurrentKey("CAGTX_Tax Line", "CAGTX_Tax Code", "CAGTX_Origin Tax Line");
            Line_L.SetRange("Document Type", p_Header."Document Type");
            Line_L.SetRange("Document No.", p_Header."No.");
            Line_L.SetRange("CAGTX_Tax Line", false);
            Line_L.SetRange(Type, Line_L.Type::"G/L Account", Line_L.Type::Resource);
            Line_L.SetRange("Receipt No.", '');
            Line_L.SetRange("Return Shipment No.", '');
            if Line_L.FindSet(true, true) then begin
                CleanTaxLine(p_Header);

                if p_Header."Currency Code" = '' then
                    Currency_L.InitRoundingPrecision()
                else begin
                    p_Header.TestField("Currency Factor");
                    Currency_L.Get(p_Header."Currency Code");
                    Currency_L.TestField("Amount Rounding Precision");
                end;
                if FindTaxCode(TempCustomerTax_L, p_Header."Buy-from Vendor No.", p_Header."Vendor Posting Group") then
                    repeat
                        CreateTaxLines(Line_L, p_Header, Currency_L, TempCustomerTax_L);
                    until Line_L.Next() = 0;
            end;
        end;
    end;

    procedure UpdateTaxLine(p_Header: Record "Purchase Header"; p_ConfirmMessage: Boolean; p_FieldNo: Integer)
    var
        RecordRef_L: RecordRef;
        FieldRef_L: FieldRef;
    begin
        if not (p_Header."CAGTX_Disable Tax Calculation") and (p_Header.Status = p_Header.Status::Released) then
            if p_Header.PurchLinesExist() then
                if p_ConfirmMessage then begin
                    RecordRef_L.GetTable(p_Header);
                    FieldRef_L := RecordRef_L.Field(p_FieldNo);
                    if Confirm(ModifiyFieldUpdateTaxMsg + ConfirmUpdateTaxQst, true, FieldRef_L.Caption) then
                        GenerateTaxLine(p_Header);
                end else
                    GenerateTaxLine(p_Header);
    end;

    local procedure CreateTaxLines(var P_Rec: Record "Purchase Line"; p_Header: Record "Purchase Header"; p_Currency: Record Currency; var P_CustomerTax: Record "CAGTX_Tax Assign. Third Party")
    var
        CMBDocTaxDetail_L: Record "CAGTX_Purch. Doc. Tax Detail";
    begin
        if P_CustomerTax.FindFirst() then
            repeat
                CreateTaxLine(P_Rec, p_Header, p_Currency, P_CustomerTax, CMBDocTaxDetail_L);
            until P_CustomerTax.Next() = 0;

        GenerateItemCharge(CMBDocTaxDetail_L, p_Currency);
    end;

    local procedure CreateTaxLine(var P_Rec: Record "Purchase Line"; p_Header: Record "Purchase Header"; p_Currency: Record Currency; var P_CustomerTax: Record "CAGTX_Tax Assign. Third Party"; var P_CMBDocTaxDetail: Record "CAGTX_Purch. Doc. Tax Detail")
    var
        Line_L: Record "Purchase Line";
        Tax_L: Record CAGTX_Tax;
        CMBDocTaxBuffer_L: Record "CAGTX_Doc. Tax Buffer";
        CMBTaxManagement_L: Codeunit "CAGTX_Tax Management";
        FindLineTax_L: Boolean;
    begin
        Tax_L.Get(P_CustomerTax."Tax Code");
        if (Tax_L."Purch. Account Type" <> Tax_L."Purch. Account Type"::"  ") then begin
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
                    InitTaxPurchLine(Line_L, P_Rec, Tax_L, CMBDocTaxBuffer_L);
                    if CalculateTaxAmount(Line_L, CMBDocTaxBuffer_L, not P_CustomerTax.Mark()) then begin
                        Line_L.Insert(true);
                        TransferToTaxeDetail(CMBDocTaxBuffer_L, P_CMBDocTaxDetail);
                    end;
                end else
                    if (Line_L."Qty. Invoiced (Base)" = 0) and ((Line_L."Qty. Received (Base)" + Line_L."Return Qty. Shipped (Base)") <> CMBDocTaxBuffer_L."Base Quantity Tax") then //begin
                        if CalculateTaxAmount(Line_L, CMBDocTaxBuffer_L, not P_CustomerTax.Mark()) then begin
                            Line_L.Modify(true);
                            TransferToTaxeDetail(CMBDocTaxBuffer_L, P_CMBDocTaxDetail);
                        end else
                            Line_L.Delete(true);
                P_CustomerTax.Mark(true);
            end;
        end;
    end;

    local procedure CalculateTaxAmount(var P_Line: Record "Purchase Line"; var P_CMBDocTaxBuffer: Record "CAGTX_Doc. Tax Buffer"; p_First: Boolean) returnValue: Boolean
    var
        CMBTaxManagement_L: Codeunit "CAGTX_Tax Management";
    begin
        P_CMBDocTaxBuffer."Tax Line No." := P_Line."Line No.";
        if P_CMBDocTaxBuffer."Calcul Type" = P_CMBDocTaxBuffer."Calcul Type"::Line then begin
            returnValue := CMBTaxManagement_L.CalculateTaxLineAmount(P_CMBDocTaxBuffer);
            if returnValue then begin
                P_Line.Validate(Quantity, P_CMBDocTaxBuffer."Quantity (Base)");
                P_Line.Validate("Qty. to Receive", P_CMBDocTaxBuffer."Qty. to Receive");
                P_Line.Validate("Direct Unit Cost", P_CMBDocTaxBuffer."Tax Unit Amount");
            end;
        end else begin
            returnValue := CMBTaxManagement_L.CalculateTaxTotalAmount(P_CMBDocTaxBuffer);
            if returnValue then
                case P_CMBDocTaxBuffer."Rate Type" of
                    P_CMBDocTaxBuffer."Rate Type"::Percent:
                        begin
                            P_Line.Validate(Quantity, 1);
                            if p_First then
                                P_Line.Validate("Direct Unit Cost", P_CMBDocTaxBuffer."Amount Tax Line")
                            else
                                P_Line.Validate("Direct Unit Cost", P_Line."Direct Unit Cost" + P_CMBDocTaxBuffer."Amount Tax Line");
                        end;
                    P_CMBDocTaxBuffer."Rate Type"::"Unit Amount":
                        begin
                            if p_First then
                                P_Line.Validate(Quantity, P_CMBDocTaxBuffer."Quantity Tax Line")
                            else
                                P_Line.Validate(Quantity, P_Line.Quantity + P_CMBDocTaxBuffer."Quantity Tax Line");
                            P_Line.Validate("Direct Unit Cost", P_CMBDocTaxBuffer."Tax Unit Amount");
                        end;
                    P_CMBDocTaxBuffer."Rate Type"::"Flat Rate":
                        begin
                            P_Line.Validate(Quantity, 1);
                            P_Line.Validate("Direct Unit Cost", P_CMBDocTaxBuffer."Tax Unit Amount");
                        end;
                    else
                        OnCalculateSpecificTaxAmount(P_Line, P_CMBDocTaxBuffer, p_First);
                end;
        end;

        OnAfterCalculateTaxAmount(P_Line, P_CMBDocTaxBuffer);
        exit(returnValue);
    end;

    local procedure SetDocTaxBuffer(var P_Rec: Record "Purchase Line"; p_Header: Record "Purchase Header"; p_Currency: Record Currency; p_Tax: Record CAGTX_Tax; var P_CMBDocTaxBuffer: Record "CAGTX_Doc. Tax Buffer"; P_Line: Record "Purchase Line")
    begin
        P_CMBDocTaxBuffer.Init();
        P_CMBDocTaxBuffer."Table No." := DATABASE::"Purchase Line";
        P_CMBDocTaxBuffer."Document Type" := P_Rec."Document Type".AsInteger();
        P_CMBDocTaxBuffer."Document No." := P_Rec."Document No.";
        P_CMBDocTaxBuffer."Line No." := P_Rec."Line No.";
        P_CMBDocTaxBuffer.Type := P_Rec.Type.AsInteger();
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
        P_CMBDocTaxBuffer."Qty. to Receive" := P_Rec."Qty. to Receive";

        P_CMBDocTaxBuffer."Base Quantity Tax" := P_Rec."Quantity (Base)";
        P_CMBDocTaxBuffer."Quantity Tax Line" := P_CMBDocTaxBuffer."Base Quantity Tax" - (P_Line."Qty. Received (Base)" + P_Line."Return Qty. Shipped (Base)");

        P_CMBDocTaxBuffer."Unit Amount" := P_Rec."Direct Unit Cost";
        P_CMBDocTaxBuffer."Qty. per Unit of Measure" := P_Rec."Qty. per Unit of Measure";
        P_CMBDocTaxBuffer."Line Discount %" := P_Rec."Line Discount %";

        if p_Tax."Tax Apply on VAT" then
            P_CMBDocTaxBuffer."VAT %" := P_Rec."VAT %";

        if p_Tax."Allow Line Disc." then
            P_CMBDocTaxBuffer."Base Amount Tax" := P_Rec."Line Amount"
        else
            P_CMBDocTaxBuffer."Base Amount Tax" := P_Rec."Direct Unit Cost" * P_Rec.Quantity;

        P_CMBDocTaxBuffer."Rate value" := 0;
        P_CMBDocTaxBuffer."Rate Type" := 0;
        P_CMBDocTaxBuffer."Calcul Type" := p_Tax."Calcul Type";
        P_CMBDocTaxBuffer."Tax VAT %" := GetVATPersent(p_Tax, p_Header."VAT Bus. Posting Group");
        P_CMBDocTaxBuffer."Amount Tax Line" := 0;
        P_CMBDocTaxBuffer."Application Order" := 1;
        P_CMBDocTaxBuffer."Calculate Tax on Tax" := false;
        OnAfterSetDocTaxBuffer(P_Rec, p_Header, p_Currency, p_Tax, P_CMBDocTaxBuffer);
    end;

    local procedure TransferToTaxeDetail(var P_CMBDocTaxBuffer: Record "CAGTX_Doc. Tax Buffer"; var P_CMBDocTaxDetail: Record "CAGTX_Purch. Doc. Tax Detail")
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
        CustomerTax_L.SetRange("Link to Table", CustomerTax_L."Link to Table"::Vendor);
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
            Find_r := not P_CustomerTax.IsEmpty;

        exit(Find_r);
    end;

    local procedure InitTaxPurchLine(var P_Line: Record "Purchase Line"; var P_Rec: Record "Purchase Line"; p_Tax: Record CAGTX_Tax; p_CMBDocTaxBuffer: Record "CAGTX_Doc. Tax Buffer")
    begin
        P_Line.Init();
        P_Line."Document Type" := ConvertOptionToPurchEnum(p_CMBDocTaxBuffer."Document Type");
        P_Line."Document No." := p_CMBDocTaxBuffer."Document No.";
        P_Line."Line No." := GetLineNo(P_Rec, p_CMBDocTaxBuffer."Calcul Type");
        case p_Tax."Purch. Account Type" of
            p_Tax."Purch. Account Type"::Resource:
                P_Line.Type := P_Line.Type::Resource;
            p_Tax."Purch. Account Type"::"G/L Account":
                P_Line.Type := P_Line.Type::"G/L Account";
            p_Tax."Purch. Account Type"::"Charge (Item)":
                P_Line.Type := P_Line.Type::"Charge (Item)";
        end;
        P_Line.Validate("No.", p_Tax."Purch. Account No.");
        P_Line."CAGTX_Tax Code" := p_CMBDocTaxBuffer."Tax Code";
        P_Line."CAGTX_Tax Line" := true;
        if p_CMBDocTaxBuffer."Calcul Type" = p_CMBDocTaxBuffer."Calcul Type"::Line then
            P_Line."CAGTX_Origin Tax Line" := p_CMBDocTaxBuffer."Line No."
        else
            P_Line."CAGTX_Origin Tax Line" := 0;
        P_Line."CAGTX_Hide Tax Line" := not (p_Tax."Show Line");
        P_Line."Allow Invoice Disc." := (p_Tax."Allow Invoice Disc.");
        P_Line."Location Code" := P_Rec."Location Code";
    end;

    local procedure GetLineNo(var P_Rec: Record "Purchase Line"; pTaxType: Option Line,Total) rLineNo: Integer
    var
        Line2_L: Record "Purchase Line";
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
                    Error(Text002_Lbl);
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

    local procedure GetLineTotalAmount(var P_Rec: Record "Purchase Line"; P_CMBDocTaxBuffer: Record "CAGTX_Doc. Tax Buffer"; p_Tax: Record CAGTX_Tax; p_CurrLineNo: Integer) TotalAmount_r: Decimal
    var
        OriginLine_L: Record "Purchase Line";
        CustomerTax_L: Record "CAGTX_Tax Assign. Third Party";
        Item_L: Record Item;
        Header_L: Record "Purchase Header";
        CMBTaxManagement_L: Codeunit "CAGTX_Tax Management";
    begin
        OriginLine_L.Reset();
        OriginLine_L.SetCurrentKey("Document Type", "Document No.", Type, "No.");
        OriginLine_L.SetRange("Document Type", P_Rec."Document Type");
        OriginLine_L.SetRange("Document No.", P_Rec."Document No.");
        OriginLine_L.SetFilter("Line No.", '<>%1', p_CurrLineNo);
        OriginLine_L.SetRange("CAGTX_Tax Line", false);
        OriginLine_L.SetRange(Type, P_Rec.Type::"G/L Account", OriginLine_L.Type::Resource);
        TotalAmount_r := 0;

        if OriginLine_L.FindSet() then
            repeat
                CustomerTax_L."Tax Code" := p_Tax.Code;
                if OriginLine_L.Type = OriginLine_L.Type::Item then
                    Item_L.Get(OriginLine_L."No.")
                else
                    Clear(Item_L);
                Header_L.Get(P_Rec."Document Type", P_Rec."Document No.");
                if FindTaxCode(CustomerTax_L, P_Rec."Buy-from Vendor No.", Header_L."Vendor Posting Group") and
                   CMBTaxManagement_L.FindTaxLine(P_CMBDocTaxBuffer) then //begin
                    if p_Tax."Allow Line Disc." then
                        TotalAmount_r += OriginLine_L."Line Amount"
                    else
                        TotalAmount_r += OriginLine_L.Quantity * OriginLine_L."Direct Unit Cost";
            until OriginLine_L.Next() = 0;
        exit(TotalAmount_r);
    end;

    local procedure GetEffectiveDate(p_Header: Record "Purchase Header"; p_Tax: Record CAGTX_Tax) r_Effectivedate: Date
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

    local procedure GetInitalDate(p_Header: Record "Purchase Header"; p_Tax: Record CAGTX_Tax) r_Effectivedate: Date
    var
        OrderFirstInvDate_L: Query "CAGTX_Purch Ord. Frst Inv Date";
        RetOrderFirstInvDate_L: Query "CAGTX_Purch Ret. Frst Cr. Date";
    begin
        if not (p_Header."Document Type" in [p_Header."Document Type"::Order, p_Header."Document Type"::"Return Order"]) then
            exit(0D);

        if p_Header."Document Type" = p_Header."Document Type"::Order then begin
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
        end else begin
            RetOrderFirstInvDate_L.SetRange(Return_Order_No, p_Header."No.");
            RetOrderFirstInvDate_L.Open();
            if not RetOrderFirstInvDate_L.Read() then
                exit(0D);

            case p_Tax."Applied Option" of
                p_Tax."Applied Option"::"Posting Date":
                    r_Effectivedate := RetOrderFirstInvDate_L.Posting_Date;
                p_Tax."Applied Option"::"Document Date":
                    r_Effectivedate := RetOrderFirstInvDate_L.Document_Date;
                p_Tax."Applied Option"::"Order Date":
                    r_Effectivedate := p_Header."Order Date";
            end;
        end;
    end;

    local procedure GetVATPersent(p_Tax: Record CAGTX_Tax; p_VATBusPostingGp: Code[20]): Decimal
    var
        GLAccount_L: Record "G/L Account";
        Resource_L: Record Resource;
        ItemCharge_L: Record "Item Charge";
        VATPostingSetup_L: Record "VAT Posting Setup";
    begin
        case p_Tax."Purch. Account Type" of
            p_Tax."Purch. Account Type"::"G/L Account":
                begin
                    GLAccount_L.Get(p_Tax."Purch. Account No.");
                    VATPostingSetup_L.Get(p_VATBusPostingGp, GLAccount_L."VAT Prod. Posting Group");
                end;
            p_Tax."Purch. Account Type"::Resource:
                begin
                    Resource_L.Get(p_Tax."Purch. Account No.");
                    VATPostingSetup_L.Get(p_VATBusPostingGp, Resource_L."VAT Prod. Posting Group");
                end;
            p_Tax."Purch. Account Type"::"Charge (Item)":
                begin
                    ItemCharge_L.Get(p_Tax."Purch. Account No.");
                    VATPostingSetup_L.Get(p_VATBusPostingGp, ItemCharge_L."VAT Prod. Posting Group");
                end;
            else
                VATPostingSetup_L.Init();
        end;
        exit(VATPostingSetup_L."VAT %");
    end;

    procedure DeleteTaxLine(p_Rec: Record "Purchase Line")
    var
        Line_L: Record "Purchase Line";
        CMBDocTaxDetail_L: Record "CAGTX_Purch. Doc. Tax Detail";
        TaxLineCheckView_L: Query "CAGTX_Purch Tax Line Chk View";
    begin
        if p_Rec."CAGTX_Tax Line" and (p_Rec."Quantity Received" <> 0) then begin
            TaxLineCheckView_L.SetRange(Document_Type_Filter, p_Rec."Document Type");
            TaxLineCheckView_L.SetRange(Document_No_Filter, p_Rec."Document No.");
            TaxLineCheckView_L.SetRange(Line_No_Filter, p_Rec."Line No.");
            TaxLineCheckView_L.Open();
            if TaxLineCheckView_L.Read() then
                if (TaxLineCheckView_L.Sum_Outstanding_Quantity <> TaxLineCheckView_L.Sum_Quantity) then
                    Error(TaxLineDeleteErr);
        end;
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

    local procedure CleanTaxLine(p_Header: Record "Purchase Header")
    var
        Line_L: Record "Purchase Line";
        Line2_L: Record "Purchase Line";
        CMBDocTaxDetail_L: Record "CAGTX_Purch. Doc. Tax Detail";
    begin
        Line_L.SetCurrentKey("CAGTX_Tax Line", "CAGTX_Tax Code", "CAGTX_Origin Tax Line");
        Line_L.SetRange("Document Type", p_Header."Document Type");
        Line_L.SetRange("Document No.", p_Header."No.");
        Line_L.SetRange("CAGTX_Tax Line", true);
        Line_L.SetRange("Receipt No.", '');
        Line_L.SetRange("Return Shipment No.", '');
        if not Line_L.IsEmpty then begin
            Line_L.FindSet();
            repeat
                if Line_L.Quantity = Line_L."Outstanding Quantity" then begin
                    Line2_L := Line_L;
                    Line2_L.SuspendStatusCheck(true);
                    if Line2_L.Delete(true) then begin
                        CMBDocTaxDetail_L.SetRange("Document Type", Line_L."Document Type");
                        CMBDocTaxDetail_L.SetRange("Document No.", Line_L."Document No.");
                        CMBDocTaxDetail_L.SetRange("Tax Line No.", Line_L."Line No.");
                        if not CMBDocTaxDetail_L.IsEmpty then
                            CMBDocTaxDetail_L.DeleteAll(true);
                    end;
                end;
            until Line_L.Next() = 0;
        end;
    end;

    local procedure GenerateItemCharge(var P_CMBDocTaxDetail: Record "CAGTX_Purch. Doc. Tax Detail"; P_Currency: Record Currency)
    var
        CMBDocTaxDetail2_L: Record "CAGTX_Purch. Doc. Tax Detail";
        RatioAmount_L: Decimal;
        TotalQtyToAssign_L: Decimal;
        TotalAmtToAssign_L: Decimal;
    begin
        P_CMBDocTaxDetail.SetAutoCalcFields("Tax Type", "Tax No.", "Tax Description");
        P_CMBDocTaxDetail.SetRange("Document Type", P_CMBDocTaxDetail."Document Type");
        P_CMBDocTaxDetail.SetRange("Document No.", P_CMBDocTaxDetail."Document No.");
        P_CMBDocTaxDetail.SetRange("Tax Type", P_CMBDocTaxDetail."Tax Type"::"Charge (Item)");
        if P_CMBDocTaxDetail.FindFirst() then
            repeat
                if P_CMBDocTaxDetail."Rate Type" = P_CMBDocTaxDetail."Rate Type"::"Unit Amount" then begin
                    TotalAmtToAssign_L := P_CMBDocTaxDetail."Rate value" * P_CMBDocTaxDetail."Quantity Tax Line";
                    SetItemCharge(P_CMBDocTaxDetail, P_Currency, P_CMBDocTaxDetail."Tax No.", P_CMBDocTaxDetail."Quantity Tax Line", TotalAmtToAssign_L);
                end else begin
                    CMBDocTaxDetail2_L.SetRange("Document Type", P_CMBDocTaxDetail."Document Type");
                    CMBDocTaxDetail2_L.SetRange("Document No.", P_CMBDocTaxDetail."Document No.");
                    CMBDocTaxDetail2_L.SetRange("Tax Line No.", P_CMBDocTaxDetail."Tax Line No.");
                    CMBDocTaxDetail2_L.CalcSums("Amount Tax Line");
                    if CMBDocTaxDetail2_L."Amount Tax Line" <> 0 then begin
                        RatioAmount_L := P_CMBDocTaxDetail."Amount Tax Line" / CMBDocTaxDetail2_L."Amount Tax Line";
                        TotalQtyToAssign_L := RatioAmount_L * P_CMBDocTaxDetail."Quantity Tax Line";
                        if P_CMBDocTaxDetail."Rate Type" = P_CMBDocTaxDetail."Rate Type"::"Flat Rate" then
                            TotalAmtToAssign_L := RatioAmount_L * P_CMBDocTaxDetail."Amount Tax Line"
                        else
                            TotalAmtToAssign_L := P_CMBDocTaxDetail."Amount Tax Line";
                        SetItemCharge(P_CMBDocTaxDetail, P_Currency, P_CMBDocTaxDetail."Tax No.", TotalQtyToAssign_L, TotalAmtToAssign_L);
                    end;
                end;
            until P_CMBDocTaxDetail.Next() = 0;
    end;

    local procedure SetItemCharge(P_CMBDocTaxDetail: Record "CAGTX_Purch. Doc. Tax Detail"; p_Currency: Record Currency; p_ItemChargeNo: Code[20]; var TotalQtyToAssign: Decimal; var TotalAmtToAssign: Decimal)
    var
        ItemChargeAssignment_L: Record "Item Charge Assignment (Purch)";
        ItemChargeAssgnt_L: Codeunit "Item Charge Assgnt. (Purch.)";
        NextLine_L: Integer;
    begin
        ItemChargeAssignment_L.SetRange("Document Type", P_CMBDocTaxDetail."Document Type");
        ItemChargeAssignment_L.SetRange("Document No.", P_CMBDocTaxDetail."Document No.");
        ItemChargeAssignment_L.SetRange("Document Line No.", P_CMBDocTaxDetail."Tax Line No.");
        if ItemChargeAssignment_L.FindLast() then
            NextLine_L := ItemChargeAssignment_L."Line No.";
        ItemChargeAssignment_L.SetRange("Applies-to Doc. No.", P_CMBDocTaxDetail."Document No.");
        ItemChargeAssignment_L.SetRange("Applies-to Doc. Line No.", P_CMBDocTaxDetail."Line No.");
        if not ItemChargeAssignment_L.FindFirst() then begin
            ItemChargeAssignment_L."Document Type" := P_CMBDocTaxDetail."Document Type";
            ItemChargeAssignment_L."Document No." := P_CMBDocTaxDetail."Document No.";
            ItemChargeAssignment_L."Document Line No." := P_CMBDocTaxDetail."Tax Line No.";
            ItemChargeAssignment_L."Item Charge No." := p_ItemChargeNo;
            ItemChargeAssignment_L."Unit Cost" := P_CMBDocTaxDetail."Amount Tax Line" / P_CMBDocTaxDetail."Quantity Tax Line";
            ItemChargeAssgnt_L.InsertItemChargeAssignment(ItemChargeAssignment_L, P_CMBDocTaxDetail."Document Type",
                                                            P_CMBDocTaxDetail."Document No.", P_CMBDocTaxDetail."Line No.",
                                                            P_CMBDocTaxDetail."No.", P_CMBDocTaxDetail.Description, NextLine_L);
        end;
        ItemChargeAssignment_L.FindFirst();
        ItemChargeAssignment_L."Qty. to Assign" := Round(TotalQtyToAssign, 0.00001);
        ItemChargeAssignment_L."Amount to Assign" :=
          Round(TotalAmtToAssign, p_Currency."Amount Rounding Precision");
        ItemChargeAssignment_L."Unit Cost" :=
          Round(ItemChargeAssignment_L."Amount to Assign" / ItemChargeAssignment_L."Qty. to Assign", p_Currency."Unit-Amount Rounding Precision");
        TotalQtyToAssign -= ItemChargeAssignment_L."Qty. to Assign";
        TotalAmtToAssign -= ItemChargeAssignment_L."Amount to Assign";
        ItemChargeAssignment_L.Modify();
    end;

    local procedure UpdateItemCharge(p_SourceLine: Record "Purchase Line"; p_TaxLine: Record "Purchase Line"; p_QtyToAssign: Decimal)
    var
        ItemChargeAssignment_L: Record "Item Charge Assignment (Purch)";
    begin
        if p_TaxLine.Type = p_TaxLine.Type::"Charge (Item)" then begin
            ItemChargeAssignment_L.SetRange("Document Type", p_SourceLine."Document Type");
            ItemChargeAssignment_L.SetRange("Document No.", p_SourceLine."Document No.");
            ItemChargeAssignment_L.SetRange("Document Line No.", p_TaxLine."Line No.");

            ItemChargeAssignment_L.SetRange("Applies-to Doc. No.", p_SourceLine."Document No.");
            ItemChargeAssignment_L.SetRange("Applies-to Doc. Line No.", p_SourceLine."Line No.");
            if ItemChargeAssignment_L.FindFirst() then begin
                ItemChargeAssignment_L.Validate("Qty. to Assign", p_QtyToAssign);
                ItemChargeAssignment_L.Modify();
            end;
        end;
    end;

    procedure SetTaxQtyToPost(Header_P: Record "Purchase Header")
    var
        TaxLine_L: Record "Purchase Line";
        Tax_L: Record CAGTX_Tax;
    begin
        TaxLine_L.Reset();
        TaxLine_L.SetCurrentKey("CAGTX_Tax Line", "CAGTX_Tax Code", "CAGTX_Origin Tax Line");
        TaxLine_L.SetRange("Document Type", Header_P."Document Type");
        TaxLine_L.SetRange("Document No.", Header_P."No.");
        TaxLine_L.SetRange("CAGTX_Tax Line", true);
        if TaxLine_L.FindSet(true, false) then
            repeat
                Tax_L.Get(TaxLine_L."CAGTX_Tax Code");
                if Tax_L."Calcul Type" = Tax_L."Calcul Type"::Line then
                    SetTaxQtyToPostLine(TaxLine_L, Tax_L)
                else
                    SetTaxQtyToPostTotal(TaxLine_L, Tax_L);
            until TaxLine_L.Next() = 0;
    end;

    procedure GetTaxQtyToPostLine(var P_TaxLine: Record "Purchase Line"; P_OriginLine: Record "Purchase Line"; p_Tax: Record CAGTX_Tax) returnValue: Decimal
    begin
        returnValue := 0;
        case p_Tax."Posted Option" of
            p_Tax."Posted Option"::First:
                if GetOrigineQtyToPost(P_OriginLine, P_TaxLine) <> 0 then
                    returnValue := P_TaxLine."Outstanding Qty. (Base)";
            p_Tax."Posted Option"::Prorata:
                returnValue := GetOrigineQtyToPost(P_OriginLine, P_TaxLine);
            p_Tax."Posted Option"::Last:
                if (GetOrigineQtyToPost(P_OriginLine, P_TaxLine) <> 0) and
                   ((P_OriginLine."Outstanding Qty. (Base)" - P_OriginLine."Qty. to Receive (Base)" - P_OriginLine."Return Qty. to Ship (Base)" = 0) or (P_OriginLine."Outstanding Qty. (Base)" = 0)) then
                    returnValue := P_TaxLine."Outstanding Qty. (Base)"
                else
                    returnValue := 0;
        end;
    end;

    local procedure GetOrigineQtyToPost(SrcPurchLine: Record "Purchase Line"; TaxPurchLine: Record "Purchase Line") returnValue: Decimal
    var
        TaxMgt: Codeunit "CAGTX_Tax Management";
    begin
        if SrcPurchLine."Document Type" in [SrcPurchLine."Document Type"::"Return Order", SrcPurchLine."Document Type"::"Credit Memo"] then
            returnValue := (((SrcPurchLine."Return Qty. Shipped (Base)" + SrcPurchLine."Return Qty. to Ship (Base)") * TaxPurchLine."Quantity (Base)") / SrcPurchLine."Quantity (Base)") - TaxPurchLine."Return Qty. Shipped (Base)"
        else
            returnValue := (((SrcPurchLine."Qty. Received (Base)" + SrcPurchLine."Qty. to Receive (Base)") * TaxPurchLine."Quantity (Base)") / SrcPurchLine."Quantity (Base)") - TaxPurchLine."Qty. Received (Base)";
        returnValue := TaxMgt.RoundBaseQty(returnValue);
    end;

    local procedure SetTaxQtyToPostLine(var P_TaxLine: Record "Purchase Line"; p_Tax: Record CAGTX_Tax)
    var
        OriginLine_L: Record "Purchase Line";
    begin
        OriginLine_L.Get(P_TaxLine."Document Type", P_TaxLine."Document No.", P_TaxLine."CAGTX_Origin Tax Line");
        case P_TaxLine."Document Type" of
            P_TaxLine."Document Type"::Order:
                begin
                    P_TaxLine.Validate("Qty. to Receive (Base)", GetTaxQtyToPostLine(P_TaxLine, OriginLine_L, p_Tax));
                    P_TaxLine.Validate("Qty. to Invoice (Base)", GetTaxQtyToInvPostLine(P_TaxLine, OriginLine_L, p_Tax))
                end;
            P_TaxLine."Document Type"::"Return Order":
                begin
                    P_TaxLine.Validate("Return Qty. to Ship (Base)", GetTaxQtyToPostLine(P_TaxLine, OriginLine_L, p_Tax));
                    P_TaxLine.Validate("Qty. to Invoice (Base)", GetTaxQtyToInvPostLine(P_TaxLine, OriginLine_L, p_Tax))
                end;
            P_TaxLine."Document Type"::Invoice, P_TaxLine."Document Type"::"Credit Memo":
                begin
                    P_TaxLine.SuspendStatusCheck(true);
                    P_TaxLine.Validate("Quantity (Base)", GetTaxQtyToInvPostLine(P_TaxLine, OriginLine_L, p_Tax))
                end;
        end;
        OnAfterModifyTaxQtyToPostLine(P_TaxLine, p_Tax);
        P_TaxLine.Modify();
    end;

    local procedure GetTaxQtyToPostTotal(var P_TaxLine: Record "Purchase Line"; p_Tax: Record CAGTX_Tax) returnValue: Decimal
    var
        OriginLine_L: Record "Purchase Line";
        CMBDocTaxDetail_L: Record "CAGTX_Purch. Doc. Tax Detail";
        Ship_L: Boolean;
        RatioQty: Decimal;
        AmountToShip: Decimal;
    begin
        case p_Tax."Posted Option" of
            p_Tax."Posted Option"::First:

                returnValue := P_TaxLine."Outstanding Qty. (Base)";

            p_Tax."Posted Option"::Prorata:
                begin
                    CMBDocTaxDetail_L.SetRange("Document Type", P_TaxLine."Document Type");
                    CMBDocTaxDetail_L.SetRange("Document No.", P_TaxLine."Document No.");
                    CMBDocTaxDetail_L.SetRange("Tax Line No.", P_TaxLine."Line No.");
                    if CMBDocTaxDetail_L.FindSet() then
                        repeat
                            if OriginLine_L.Get(CMBDocTaxDetail_L."Document Type", CMBDocTaxDetail_L."Document No.", CMBDocTaxDetail_L."Line No.") then begin
                                if OriginLine_L."Quantity (Base)" <> 0 then begin
                                    RatioQty := GetOrigineQtyToPost(OriginLine_L, P_TaxLine) / OriginLine_L."Quantity (Base)";
                                    if OriginLine_L.Quantity <> 0 then
                                        UpdateItemCharge(OriginLine_L, P_TaxLine, P_TaxLine.Quantity * RatioQty * (OriginLine_L."Qty. to Invoice" / OriginLine_L.Quantity));
                                end;
                                AmountToShip += CMBDocTaxDetail_L."Amount Tax Line" * RatioQty;
                            end;
                        until CMBDocTaxDetail_L.Next() = 0;

                    if (P_TaxLine."Line Amount" <> 0) and (P_TaxLine."Outstanding Qty. (Base)" <> 0) then
                        returnValue := ((AmountToShip / P_TaxLine."Line Amount") * P_TaxLine."Quantity (Base)");
                end;
            p_Tax."Posted Option"::Last:
                begin
                    Ship_L := true;
                    OriginLine_L.SetCurrentKey("CAGTX_Tax Line", "CAGTX_Tax Code", "CAGTX_Origin Tax Line");
                    OriginLine_L.SetRange("Document Type", P_TaxLine."Document Type");
                    OriginLine_L.SetRange("Document No.", P_TaxLine."Document No.");
                    OriginLine_L.SetRange("CAGTX_Tax Line", false);
                    if OriginLine_L.FindSet() then
                        repeat
                            if OriginLine_L."Document Type" in [OriginLine_L."Document Type"::"Return Order", OriginLine_L."Document Type"::"Credit Memo"] then
                                Ship_L := Ship_L and (OriginLine_L."Return Qty. to Ship (Base)" - OriginLine_L."Outstanding Qty. (Base)" = 0)
                            else
                                Ship_L := Ship_L and (OriginLine_L."Qty. to Receive (Base)" - OriginLine_L."Outstanding Qty. (Base)" = 0);
                        until not Ship_L or (OriginLine_L.Next() = 0);
                    if Ship_L then
                        returnValue := P_TaxLine."Outstanding Qty. (Base)"
                    else
                        returnValue := 0;
                end;
        end;
    end;

    local procedure SetTaxQtyToPostTotal(var P_TaxLine: Record "Purchase Line"; p_Tax: Record CAGTX_Tax)
    var
        OriginLine_L: Record "Purchase Line";
        CMBDocTaxDetail_L: Record "CAGTX_Purch. Doc. Tax Detail";
    begin
        CMBDocTaxDetail_L.SetRange("Document Type", P_TaxLine."Document Type");
        CMBDocTaxDetail_L.SetRange("Document No.", P_TaxLine."Document No.");
        CMBDocTaxDetail_L.SetRange("Tax Line No.", P_TaxLine."Line No.");
        if P_TaxLine."CAGTX_Origin Tax Line" <> 0 then
            CMBDocTaxDetail_L.SetRange("Line No.", P_TaxLine."CAGTX_Origin Tax Line");
        CMBDocTaxDetail_L.FindFirst();
        OriginLine_L.Get(P_TaxLine."Document Type", P_TaxLine."Document No.", CMBDocTaxDetail_L."Line No.");
        if OriginLine_L."Document Type" in [OriginLine_L."Document Type"::"Return Order", OriginLine_L."Document Type"::"Credit Memo"] then
            P_TaxLine.Validate("Return Qty. to Ship (Base)", GetTaxQtyToPostTotal(P_TaxLine, p_Tax))
        else
            P_TaxLine.Validate("Qty. to Receive (Base)", GetTaxQtyToPostTotal(P_TaxLine, p_Tax));
        P_TaxLine.Modify();
    end;

    procedure SetTaxAmtToPostTotal(SalesShptHeader: Record "Purch. Rcpt. Header"; var OrderLineTmp_L: Record "Purchase Line") returnValue: Boolean
    var
        CMBDocTaxDetail_L: Record "CAGTX_Purch. Doc. Tax Detail";
        Tax_L: Record CAGTX_Tax;
        TaxLine_L: Record "Purchase Line";
        OriginLine_L: Record "Purchase Line";
        Ship_L: Boolean;
        TaxAmountToShip: Decimal;
        Qty_L: Decimal;
    begin
        CMBDocTaxDetail_L.SetRange("Document Type", CMBDocTaxDetail_L."Document Type"::Order);
        CMBDocTaxDetail_L.SetRange("Document No.", SalesShptHeader."Order No.");
        CMBDocTaxDetail_L.SetRange("Calcul Type", CMBDocTaxDetail_L."Calcul Type"::Total);
        if not CMBDocTaxDetail_L.IsEmpty then begin
            CMBDocTaxDetail_L.FindSet();
            repeat
                Tax_L.Get(CMBDocTaxDetail_L."Tax Code");
                TaxLine_L.Get(CMBDocTaxDetail_L."Document Type", CMBDocTaxDetail_L."Document No.", CMBDocTaxDetail_L."Tax Line No.");

                case Tax_L."Posted Option" of
                    Tax_L."Posted Option"::First:
                        TaxAmountToShip := TaxLine_L."Outstanding Qty. (Base)" * TaxLine_L."Direct Unit Cost";
                    Tax_L."Posted Option"::Prorata:
                        if OrderLineTmp_L.Get(CMBDocTaxDetail_L."Document Type", CMBDocTaxDetail_L."Document No.", CMBDocTaxDetail_L."Line No.") then begin
                            if OrderLineTmp_L.Quantity <> 0 then
                                Qty_L := GetOrigineQtyToPost(OrderLineTmp_L, TaxLine_L) / OrderLineTmp_L."Quantity (Base)";
                            TaxAmountToShip += CMBDocTaxDetail_L."Amount Tax Line" * Qty_L;
                        end;
                    Tax_L."Posted Option"::Last:
                        begin
                            Ship_L := false;
                            if OrderLineTmp_L.FindFirst() then
                                repeat
                                    Ship_L := Ship_L and (GetOrigineQtyToPost(OrderLineTmp_L, TaxLine_L) = OrderLineTmp_L."Outstanding Qty. (Base)");
                                until not Ship_L or (OriginLine_L.Next() = 0);
                            if Ship_L then
                                TaxAmountToShip := TaxLine_L."Outstanding Qty. (Base)" * TaxLine_L."Direct Unit Cost"
                            else
                                TaxAmountToShip := 0;
                        end;
                end;
                CMBDocTaxDetail_L."Tax Amount. to Receive" := TaxAmountToShip;
                CMBDocTaxDetail_L.Modify();
            until CMBDocTaxDetail_L.Next() = 0;
        end;
    end;

    procedure SetDropShipmentLine(DropShptHeader: Record "Purch. Rcpt. Header"; var DropShptLine: Record "Purch. Rcpt. Line"; OrderLine: Record "Purchase Line"; var P_OrderLineTmp: Record "Purchase Line")
    var
        CMBDocTaxDetail_L: Record "CAGTX_Purch. Doc. Tax Detail";
        OriginLine_L: Record "Purchase Line";
        Tax_L: Record CAGTX_Tax;
    begin
        P_OrderLineTmp := OrderLine;
        P_OrderLineTmp.Insert();

        CMBDocTaxDetail_L.SetRange("Document Type", OrderLine."Document Type");
        CMBDocTaxDetail_L.SetRange("Document No.", OrderLine."Document No.");
        CMBDocTaxDetail_L.SetRange("Line No.", OrderLine."Line No.");
        CMBDocTaxDetail_L.SetRange("Calcul Type", CMBDocTaxDetail_L."Calcul Type"::Line);
        if CMBDocTaxDetail_L.FindSet() then
            repeat
                OriginLine_L.Get(CMBDocTaxDetail_L."Document Type", CMBDocTaxDetail_L."Document No.", CMBDocTaxDetail_L."Tax Line No.");
                DropShptLine.Init();
                DropShptLine.TransferFields(OriginLine_L);
                DropShptLine."Posting Date" := DropShptHeader."Posting Date";
                DropShptLine."Document No." := DropShptHeader."No.";
                Tax_L.Get(CMBDocTaxDetail_L."Tax Code");
                OriginLine_L.Validate("Qty. Received (Base)", GetTaxQtyToPostLine(OriginLine_L, OrderLine, Tax_L));
                DropShptLine.Quantity := OriginLine_L."Qty. to Receive";
                DropShptLine."Quantity (Base)" := OriginLine_L."Qty. to Receive (Base)";
                DropShptLine."Quantity Invoiced" := 0;
                DropShptLine."Qty. Invoiced (Base)" := 0;
                DropShptLine."Order No." := OriginLine_L."Document No.";
                DropShptLine."Order Line No." := OriginLine_L."Line No.";
                DropShptLine."Qty. Rcd. Not Invoiced" := DropShptLine.Quantity - DropShptLine."Quantity Invoiced";

                DropShptLine.Insert();

                OriginLine_L."Quantity Received" := OriginLine_L."Quantity Received" + DropShptLine.Quantity;
                OriginLine_L."Qty. Received (Base)" := OriginLine_L."Qty. Received (Base)" + DropShptLine."Quantity (Base)";
                OriginLine_L.InitOutstanding();
                OriginLine_L.InitQtyToReceive();
                OriginLine_L.Modify();

            until CMBDocTaxDetail_L.Next() = 0;
    end;

    procedure SetDropShipmentTotal(DropShptHeader: Record "Purch. Rcpt. Header"; var DropShptLine: Record "Purch. Rcpt. Line"; OrderLine: Record "Purchase Line")
    var
        CMBDocTaxDetail_L: Record "CAGTX_Purch. Doc. Tax Detail";
        TempCMBDocTaxDetail_L: Record "CAGTX_Purch. Doc. Tax Detail" temporary;
        OriginLine_L: Record "Purchase Line";
        Tax_L: Record CAGTX_Tax;
    begin
        CMBDocTaxDetail_L.SetRange("Document Type", CMBDocTaxDetail_L."Document Type"::Order);
        CMBDocTaxDetail_L.SetRange("Document No.", DropShptHeader."Order No.");
        CMBDocTaxDetail_L.SetRange("Calcul Type", CMBDocTaxDetail_L."Calcul Type"::Total);
        if CMBDocTaxDetail_L.FindSet() then
            repeat
                TempCMBDocTaxDetail_L := CMBDocTaxDetail_L;
                TempCMBDocTaxDetail_L."Line No." := 0;
                if not TempCMBDocTaxDetail_L.Find() then
                    TempCMBDocTaxDetail_L.Insert()
                else begin
                    TempCMBDocTaxDetail_L."Tax Amount. to Receive" += CMBDocTaxDetail_L."Tax Amount. to Receive";
                    TempCMBDocTaxDetail_L.Modify();
                end
            until CMBDocTaxDetail_L.Next() = 0;
        if TempCMBDocTaxDetail_L.FindSet() then
            repeat
                OriginLine_L.Get(TempCMBDocTaxDetail_L."Document Type", TempCMBDocTaxDetail_L."Document No.", TempCMBDocTaxDetail_L."Tax Line No.");
                if Tax_L.Code <> TempCMBDocTaxDetail_L."Tax Code" then
                    Tax_L.Get(TempCMBDocTaxDetail_L."Tax Code");
                case Tax_L."Posted Option" of
                    Tax_L."Posted Option"::First:
                        OriginLine_L.Validate("Qty. to Receive (Base)", OriginLine_L."Outstanding Qty. (Base)");
                    /*
                    Tax_L."Posted Option"::Prorata:
                        begin

                        end;
                    */
                    Tax_L."Posted Option"::Last:
                        if (TempCMBDocTaxDetail_L."Tax Amount. to Receive" = TempCMBDocTaxDetail_L."Amount Tax Line") then
                            OriginLine_L.Validate("Qty. to Receive (Base)", OriginLine_L."Outstanding Qty. (Base)")
                        else
                            OriginLine_L.Validate("Qty. to Receive", 0);
                end;

                DropShptLine.Init();
                DropShptLine.TransferFields(OriginLine_L);
                DropShptLine."Posting Date" := DropShptHeader."Posting Date";
                DropShptLine."Document No." := DropShptHeader."No.";
                DropShptLine.Quantity := OriginLine_L."Qty. to Receive";
                DropShptLine."Quantity (Base)" := OriginLine_L."Qty. to Receive (Base)";
                DropShptLine."Quantity Invoiced" := 0;
                DropShptLine."Qty. Invoiced (Base)" := 0;
                DropShptLine."Order No." := OriginLine_L."Document No.";
                DropShptLine."Order Line No." := OriginLine_L."Line No.";
                DropShptLine."Qty. Rcd. Not Invoiced" := DropShptLine.Quantity - DropShptLine."Quantity Invoiced";

                DropShptLine.Insert();

                OriginLine_L."Quantity Received" += DropShptLine.Quantity;
                OriginLine_L."Qty. Received (Base)" += DropShptLine."Quantity (Base)";
                OriginLine_L.InitOutstanding();
                OriginLine_L.Validate("Qty. to Receive (Base)", OriginLine_L."Outstanding Qty. (Base)");
                OriginLine_L.Modify();
            until TempCMBDocTaxDetail_L.Next() = 0;
    end;

    procedure UndoPurchaseReceiptTaxLine(p_PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        PostedTaxLine_L: Record "Purch. Rcpt. Line";
        DocLineNo: Integer;
    begin
        PostedTaxLine_L.SetRange("Document No.", p_PurchRcptLine."Document No.");
        PostedTaxLine_L.SetRange("CAGTX_Origin Tax Line", p_PurchRcptLine."Line No.");
        PostedTaxLine_L.SetRange(Correction, false);
        if PostedTaxLine_L.FindSet() then
            repeat
                DocLineNo := GetPurchRcptLineDocLineNo(PostedTaxLine_L);

                InsertNewReceiptLine(PostedTaxLine_L, 0, DocLineNo);

                UpdateOrderLine(PostedTaxLine_L);

                if (PostedTaxLine_L."Blanket Order No." <> '') and (PostedTaxLine_L."Blanket Order Line No." <> 0) then
                    UpdateBlanketOrder(PostedTaxLine_L);

                PostedTaxLine_L."Quantity Invoiced" := PostedTaxLine_L.Quantity;
                PostedTaxLine_L."Qty. Invoiced (Base)" := PostedTaxLine_L."Quantity (Base)";
                PostedTaxLine_L."Qty. Rcd. Not Invoiced" := 0;
                PostedTaxLine_L.Correction := true;

                /// TODO Champ issue du module CMB-8061050
                // PostedTaxLine_L."CMB- Skip Line on Position" := TRUE;
                PostedTaxLine_L.Modify();
            until PostedTaxLine_L.Next() = 0;

    end;

    local procedure InsertNewReceiptLine(OldPurchRcptLine: Record "Purch. Rcpt. Line"; ItemRcptEntryNo: Integer; DocLineNo: Integer)
    var
        NewPurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        NewPurchRcptLine.Init();
        NewPurchRcptLine.Copy(OldPurchRcptLine);
        NewPurchRcptLine."Line No." := DocLineNo;
        NewPurchRcptLine."Appl.-to Item Entry" := OldPurchRcptLine."Item Rcpt. Entry No.";
        NewPurchRcptLine."Item Rcpt. Entry No." := ItemRcptEntryNo;
        NewPurchRcptLine.Quantity := -OldPurchRcptLine.Quantity;
        NewPurchRcptLine."Quantity (Base)" := -OldPurchRcptLine."Quantity (Base)";
        NewPurchRcptLine."Quantity Invoiced" := NewPurchRcptLine.Quantity;
        NewPurchRcptLine."Qty. Invoiced (Base)" := NewPurchRcptLine."Quantity (Base)";
        NewPurchRcptLine."Qty. Rcd. Not Invoiced" := 0;
        NewPurchRcptLine.Correction := true;
        // /// TODO Champ issue du module CMB-8061050
        // NewPurchRcptLine."CMB- Skip Line on Position" := TRUE;
        NewPurchRcptLine."Dimension Set ID" := OldPurchRcptLine."Dimension Set ID";
        NewPurchRcptLine.Insert();

    end;

    local procedure UpdateOrderLine(PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        PurchLine: Record "Purchase Line";
        TempGlobalItemLedgEntry: Record "Item Ledger Entry" temporary;
        UndoPostingMgt: Codeunit "Undo Posting Management";
    begin
        PurchLine.Get(PurchLine."Document Type"::Order, PurchRcptLine."Order No.", PurchRcptLine."Order Line No.");
        UndoPostingMgt.UpdatePurchLine(PurchLine, PurchRcptLine.Quantity, PurchRcptLine."Quantity (Base)", TempGlobalItemLedgEntry);

    end;

    local procedure UpdateBlanketOrder(PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        BlanketOrderPurchaseLine: Record "Purchase Line";
    begin
        if BlanketOrderPurchaseLine.Get(
                 BlanketOrderPurchaseLine."Document Type"::"Blanket Order", PurchRcptLine."Blanket Order No.", PurchRcptLine."Blanket Order Line No.")
            then begin
            BlanketOrderPurchaseLine.TestField(Type, PurchRcptLine.Type);
            BlanketOrderPurchaseLine.TestField("No.", PurchRcptLine."No.");
            BlanketOrderPurchaseLine.TestField("Buy-from Vendor No.", PurchRcptLine."Buy-from Vendor No.");

            if BlanketOrderPurchaseLine."Qty. per Unit of Measure" = PurchRcptLine."Qty. per Unit of Measure" then
                BlanketOrderPurchaseLine."Quantity Received" := BlanketOrderPurchaseLine."Quantity Received" - PurchRcptLine.Quantity
            else
                BlanketOrderPurchaseLine."Quantity Received" :=
                  BlanketOrderPurchaseLine."Quantity Received" -
                  Round(PurchRcptLine."Qty. per Unit of Measure" / BlanketOrderPurchaseLine."Qty. per Unit of Measure" * PurchRcptLine.Quantity, 0.00001);

            BlanketOrderPurchaseLine."Qty. Received (Base)" := BlanketOrderPurchaseLine."Qty. Received (Base)" - PurchRcptLine."Quantity (Base)";
            BlanketOrderPurchaseLine.InitOutstanding();
            BlanketOrderPurchaseLine.Modify();
        end;
    end;

    procedure UndoReturnShipmentTaxLine(p_ReturnShptLine: Record "Return Shipment Line")
    var
        PostedTaxLine_L: Record "Return Shipment Line";
        DocLineNo: Integer;
    begin
        PostedTaxLine_L.SetRange("Document No.", p_ReturnShptLine."Document No.");
        PostedTaxLine_L.SetRange("CAGTX_Origin Tax Line", p_ReturnShptLine."Line No.");
        PostedTaxLine_L.SetRange(Correction, false);
        if PostedTaxLine_L.FindSet() then
            repeat
                DocLineNo := GetReturnShipmentLineDocLineNo(PostedTaxLine_L);

                InsertNewReturnShptLine(PostedTaxLine_L, 0, DocLineNo);

                UpdateReturnOrderLine(PostedTaxLine_L);

                PostedTaxLine_L."Quantity Invoiced" := PostedTaxLine_L.Quantity;
                PostedTaxLine_L."Qty. Invoiced (Base)" := PostedTaxLine_L."Quantity (Base)";
                PostedTaxLine_L."Return Qty. Shipped Not Invd." := 0;
                PostedTaxLine_L.Correction := true;
                // /// TODO Champ issue du module CMB-8061050
                // PostedTaxLine_L."CMB- Skip Line on Position" := TRUE;
                PostedTaxLine_L.Modify();
            until PostedTaxLine_L.Next() = 0;

    end;

    local procedure InsertNewReturnShptLine(OldReturnShptLine: Record "Return Shipment Line"; ItemRcptEntryNo: Integer; DocLineNo: Integer)
    var
        NewReturnShptLine: Record "Return Shipment Line";
    begin
        NewReturnShptLine.Init();
        NewReturnShptLine.Copy(OldReturnShptLine);
        NewReturnShptLine."Line No." := DocLineNo;
        NewReturnShptLine."Appl.-to Item Entry" := OldReturnShptLine."Item Shpt. Entry No.";
        NewReturnShptLine."Item Shpt. Entry No." := ItemRcptEntryNo;
        NewReturnShptLine.Quantity := -OldReturnShptLine.Quantity;
        NewReturnShptLine."Quantity (Base)" := -OldReturnShptLine."Quantity (Base)";
        NewReturnShptLine."Quantity Invoiced" := NewReturnShptLine.Quantity;
        NewReturnShptLine."Qty. Invoiced (Base)" := NewReturnShptLine."Quantity (Base)";
        NewReturnShptLine."Return Qty. Shipped Not Invd." := 0;
        NewReturnShptLine.Correction := true;

        /// TODO Champ issue du module CMB-8061050
        // NewReturnShptLine."CMB- Skip Line on Position" := TRUE;
        NewReturnShptLine."Dimension Set ID" := OldReturnShptLine."Dimension Set ID";
        NewReturnShptLine.Insert();

    end;

    local procedure UpdateReturnOrderLine(ReturnShptLine: Record "Return Shipment Line")
    var
        PurchLine: Record "Purchase Line";
        TempGlobalItemLedgEntry: Record "Item Ledger Entry" temporary;
        UndoPostingMgt: Codeunit "Undo Posting Management";
    begin
        PurchLine.Get(PurchLine."Document Type"::"Return Order", ReturnShptLine."Return Order No.", ReturnShptLine."Return Order Line No.");
        UndoPostingMgt.UpdatePurchLine(PurchLine, ReturnShptLine.Quantity, ReturnShptLine."Quantity (Base)", TempGlobalItemLedgEntry);

    end;

    procedure GetTaxQtyToInvPostLine(var TaxPurchLine: Record "Purchase Line"; SrcPurchLine: Record "Purchase Line"; p_Tax: Record CAGTX_Tax) returnValue: Decimal
    var
        PurchRcptLine_L: Record "Purch. Rcpt. Line";
        ReturnShptLine_L: Record "Return Shipment Line";
        TaxMgt: Codeunit "CAGTX_Tax Management";
    begin
        returnValue := 0;
        case p_Tax."Posted Option" of
            p_Tax."Posted Option"::First, p_Tax."Posted Option"::Last:
                case TaxPurchLine."Document Type" of
                    TaxPurchLine."Document Type"::"Return Order":
                        returnValue := TaxPurchLine."Ret. Qty. Shpd Not Invd.(Base)" + TaxPurchLine."Return Qty. to Ship (Base)";
                    TaxPurchLine."Document Type"::Order:
                        returnValue := TaxPurchLine."Qty. Rcd. Not Invoiced (Base)" + TaxPurchLine."Qty. to Receive (Base)";
                    TaxPurchLine."Document Type"::Invoice:
                        if (TaxPurchLine."Receipt No." <> '') and (TaxPurchLine."Receipt Line No." <> 0) and
                           PurchRcptLine_L.Get(TaxPurchLine."Receipt No.", TaxPurchLine."Receipt Line No.") then
                            returnValue := PurchRcptLine_L."Qty. Rcd. Not Invoiced" * TaxPurchLine."Qty. per Unit of Measure"
                        else
                            returnValue := SrcPurchLine."Qty. to Invoice (Base)";
                    TaxPurchLine."Document Type"::"Credit Memo":
                        if (TaxPurchLine."Return Shipment No." <> '') and (TaxPurchLine."Return Shipment Line No." <> 0) and
                           ReturnShptLine_L.Get(TaxPurchLine."Return Shipment No.", TaxPurchLine."Return Shipment Line No.") then
                            returnValue := ReturnShptLine_L."Return Qty. Shipped Not Invd." * ReturnShptLine_L."Qty. per Unit of Measure"
                        else
                            returnValue := SrcPurchLine."Qty. to Invoice (Base)";
                end;
            p_Tax."Posted Option"::Prorata:
                returnValue := (((SrcPurchLine."Qty. to Invoice (Base)" + SrcPurchLine."Qty. Invoiced (Base)") * TaxPurchLine."Quantity (Base)") / SrcPurchLine."Quantity (Base)") - TaxPurchLine."Qty. Invoiced (Base)";
        end;
        returnvalue := TaxMgt.RoundBaseQty(returnValue);
    end;

    procedure GetTaxSourceLine(DocumentType_P: Option; DocumentNo_P: Code[20]; PostedDocLine_P: Variant): Integer
    var
        RecRef_L: RecordRef;
    begin
        RecRef_L.GetTable(PostedDocLine_P);
        case RecRef_L.Number of
            DATABASE::"Purch. Rcpt. Line":
                exit(GetPurchReceiptTaxSourceLine(DocumentType_P, DocumentNo_P, PostedDocLine_P));
            DATABASE::"Return Shipment Line":
                exit(GetReturnShipmentTaxSourceLine(DocumentType_P, DocumentNo_P, PostedDocLine_P));
            else
                exit(0);
        end;

    end;

    local procedure GetPurchReceiptTaxSourceLine(DocumentType_P: Option; DocumentNo_P: Code[20]; PostedDocLine_P: Record "Purch. Rcpt. Line"): Integer
    var
        DocLine_L: Record "Purchase Line";
    begin
        if PostedDocLine_P."CAGTX_Origin Tax Line" = 0 then
            exit(0);

        DocLine_L.Reset();
        DocLine_L.SetCurrentKey("Document Type", "Receipt No.", "Receipt Line No.");
        DocLine_L.SetRange("Document Type", DocumentType_P);
        DocLine_L.SetRange("Document No.", DocumentNo_P);
        DocLine_L.SetRange("Receipt No.", PostedDocLine_P."Document No.");
        DocLine_L.SetRange("Receipt Line No.", PostedDocLine_P."CAGTX_Origin Tax Line");
        if DocLine_L.FindFirst() then
            exit(DocLine_L."Line No.");

        exit(0);
    end;

    procedure GetPurchRcptLineDocLineNo(p_PurchRcptLine: Record "Purch. Rcpt. Line") ReturnValue: Integer
    var
        PurchRcptLine2_L: Record "Purch. Rcpt. Line";
        LineSpacing_L: Integer;
    begin
        PurchRcptLine2_L.SetRange("Document No.", p_PurchRcptLine."Document No.");
        PurchRcptLine2_L."Document No." := p_PurchRcptLine."Document No.";
        PurchRcptLine2_L."Line No." := p_PurchRcptLine."Line No.";
        PurchRcptLine2_L.Find('=');

        if PurchRcptLine2_L.Find('>') then begin
            LineSpacing_L := (PurchRcptLine2_L."Line No." - p_PurchRcptLine."Line No.") div 2;
            if LineSpacing_L = 0 then
                Error(Text002_Lbl);
        end else
            LineSpacing_L := 10000;
        ReturnValue := p_PurchRcptLine."Line No." + LineSpacing_L;

    end;

    local procedure GetReturnShipmentTaxSourceLine(DocumentType_P: Option; DocumentNo_P: Code[20]; PostedDocLine_P: Record "Return Shipment Line"): Integer
    var
        DocLine_L: Record "Purchase Line";
    begin
        if PostedDocLine_P."CAGTX_Origin Tax Line" = 0 then
            exit(0);

        DocLine_L.Reset();
        DocLine_L.SetCurrentKey("Document Type", "Return Shipment No.", "Return Shipment Line No.");
        DocLine_L.SetRange("Document Type", DocumentType_P);
        DocLine_L.SetRange("Document No.", DocumentNo_P);
        DocLine_L.SetRange("Return Shipment No.", PostedDocLine_P."Document No.");
        DocLine_L.SetRange("Return Shipment Line No.", PostedDocLine_P."CAGTX_Origin Tax Line");
        if DocLine_L.FindFirst() then
            exit(DocLine_L."Line No.");

        exit(0);
    end;

    procedure GetReturnShipmentLineDocLineNo(p_ReturnShptLine: Record "Return Shipment Line") ReturnValue: Integer
    var
        ReturnShptLine2_L: Record "Return Shipment Line";
        LineSpacing_L: Integer;
    begin
        ReturnShptLine2_L.SetRange("Document No.", p_ReturnShptLine."Document No.");
        ReturnShptLine2_L."Document No." := p_ReturnShptLine."Document No.";
        ReturnShptLine2_L."Line No." := p_ReturnShptLine."Line No.";
        ReturnShptLine2_L.Find('=');

        if ReturnShptLine2_L.Find('>') then begin
            LineSpacing_L := (ReturnShptLine2_L."Line No." - p_ReturnShptLine."Line No.") div 2;
            if LineSpacing_L = 0 then
                Error(Text002_Lbl);
        end else
            LineSpacing_L := 10000;
        ReturnValue := p_ReturnShptLine."Line No." + LineSpacing_L;

    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDocTaxBuffer(var P_Rec: Record "Purchase Line"; p_Header: Record "Purchase Header"; p_Currency: Record Currency; p_Tax: Record CAGTX_Tax; var P_CMBDocTaxBuffer: Record "CAGTX_Doc. Tax Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateTaxAmount(var P_Line: Record "Purchase Line"; var P_CMBDocTaxBuffer: Record "CAGTX_Doc. Tax Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateSpecificTaxAmount(var P_Line: Record "Purchase Line"; var P_CMBDocTaxBuffer: Record "CAGTX_Doc. Tax Buffer"; p_First: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterModifyTaxQtyToPostLine(var P_TaxLine: Record "Purchase Line"; p_Tax: Record CAGTX_Tax)
    begin
    end;

    local procedure ConvertOptionToPurchEnum(PurchDocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"): Enum "Purchase Document Type"
    begin
        Case PurchDocType of
            PurchDocType::Quote:
                exit("Purchase Document Type"::Quote);
            PurchDocType::"Order":
                exit("Purchase Document Type"::Order);
            PurchDocType::Invoice:
                exit("Purchase Document Type"::Invoice);
            PurchDocType::"Credit Memo":
                exit("Purchase Document Type"::"Credit Memo");
            PurchDocType::"Blanket Order":
                exit("Purchase Document Type"::"Blanket Order");
            PurchDocType::"Return Order":
                exit("Purchase Document Type"::"Return Order");
        end;
    end;
}

