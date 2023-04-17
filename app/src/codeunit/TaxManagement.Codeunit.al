codeunit 8062635 "CAGTX_Tax Management"
{

    procedure FindTaxLine(var P_CMBDocTaxBuffer: Record "CAGTX_Doc. Tax Buffer") r_RateValue: Boolean
    var
        ItemTax_L: Record "CAGTX_Item Tax V2";
        ItemUoM: Record "Item Unit of Measure";
        ResUoM: Record "Resource Unit of Measure";
        CurrExchRate_L: Record "Currency Exchange Rate";
    begin
        ItemTax_L.SetRange("Tax Code", P_CMBDocTaxBuffer."Tax Code");
        ItemTax_L.SetRange(Type, P_CMBDocTaxBuffer.Type);
        ItemTax_L.SetFilter("No.", '%1|%2', '', P_CMBDocTaxBuffer."No.");
        ItemTax_L.SetFilter("Item Category Code", '%1|%2', '', P_CMBDocTaxBuffer."Item Category Code");
        ItemTax_L.SetFilter("Unit of Measure Code", '%1|%2', '', P_CMBDocTaxBuffer."Unit of Measure Code");
        ItemTax_L.SetFilter("Variant Code", '%1|%2', '', P_CMBDocTaxBuffer."Variant Code");
        ItemTax_L.SetRange("Effective Date", 0D, P_CMBDocTaxBuffer."Posting Date");
        if ItemTax_L.FindLast() then begin
            if (P_CMBDocTaxBuffer."Intial Posting Date" <> 0D) and (ItemTax_L."Effective Date" <> 0D) and
              (P_CMBDocTaxBuffer."Intial Posting Date" < ItemTax_L."Effective Date") then begin
                P_CMBDocTaxBuffer."Base Quantity Tax" := P_CMBDocTaxBuffer."Outstanding Qty. (Base)";
                P_CMBDocTaxBuffer."Quantity Tax Line" := P_CMBDocTaxBuffer."Base Quantity Tax";
            end;
            if (ItemTax_L."Unit of Measure Code" <> '') and (ItemTax_L."Minimum Quantity" <> 0) then
                case P_CMBDocTaxBuffer.Type of
                    P_CMBDocTaxBuffer.Type::Item:
                        begin
                            if ItemUoM.Get(P_CMBDocTaxBuffer."No.", ItemTax_L."Unit of Measure Code") then
                                ItemTax_L.SetRange("Minimum Quantity", 0, Round(P_CMBDocTaxBuffer."Base Quantity Tax" / ItemUoM."Qty. per Unit of Measure"));
                            if ItemTax_L.FindLast() then begin
                                P_CMBDocTaxBuffer."Rate value" := ItemTax_L."Rate Value";
                                P_CMBDocTaxBuffer."Rate Type" := ItemTax_L."Rate Type";
                                r_RateValue := true;
                            end;
                        end;
                    P_CMBDocTaxBuffer.Type::Resource:
                        begin
                            if ResUoM.Get(P_CMBDocTaxBuffer."No.", ItemTax_L."Unit of Measure Code") then
                                ItemTax_L.SetRange("Minimum Quantity", 0, Round(P_CMBDocTaxBuffer."Base Quantity Tax" / ResUoM."Qty. per Unit of Measure"));
                            if ItemTax_L.FindLast() then begin
                                P_CMBDocTaxBuffer."Rate value" := ItemTax_L."Rate Value";
                                P_CMBDocTaxBuffer."Rate Type" := ItemTax_L."Rate Type";
                                r_RateValue := true;
                            end;
                        end;
                end
            else begin
                P_CMBDocTaxBuffer."Rate value" := ItemTax_L."Rate Value";
                P_CMBDocTaxBuffer."Rate Type" := ItemTax_L."Rate Type";
                r_RateValue := true;
            end;
        end else
            r_RateValue := false;

        if r_RateValue and (P_CMBDocTaxBuffer."Currency Code" <> '') and
           (P_CMBDocTaxBuffer."Rate Type" in [P_CMBDocTaxBuffer."Rate Type"::"Unit Amount", P_CMBDocTaxBuffer."Rate Type"::"Flat Rate"]) then
            P_CMBDocTaxBuffer."Rate value" :=
              Round(
                CurrExchRate_L.ExchangeAmtLCYToFCY(
                  P_CMBDocTaxBuffer."Posting Date",
                  P_CMBDocTaxBuffer."Currency Code",
                  P_CMBDocTaxBuffer."Rate value",
                  P_CMBDocTaxBuffer."Currency Factor"), P_CMBDocTaxBuffer."Unit-Amount Rounding Precision");
        exit(r_RateValue);
    end;

    procedure UpdateThridPartySubjectToTax(var p_Rec: Record "CAGTX_Tax Assign. Third Party"; p_xRec: Record "CAGTX_Tax Assign. Third Party"; p_IsDeleteTrigger: Boolean; p_IsRenameTrigger: Boolean)
    var
        ThridPartySubjectToTax_L: Record "CAGTX_Customer Subject To Tax";
        Tax_L: Record CAGTX_Tax;
    begin
        fUpdateTaxThridParty(p_Rec, p_xRec);
        if p_IsDeleteTrigger then begin
            if ThridPartySubjectToTax_L.Get(p_Rec."Tax Code", p_Rec."Link to Table", p_Rec.Type, p_Rec."No.") then
                ThridPartySubjectToTax_L.Delete();
        end else
            if p_IsRenameTrigger then begin
                if ThridPartySubjectToTax_L.Get(p_xRec."Tax Code", p_Rec."Link to Table", p_Rec.Type, p_xRec."No.") then
                    ThridPartySubjectToTax_L.Delete();
                fInsertThridPartySubjectToTax(p_Rec);
            end else
                if ThridPartySubjectToTax_L.Get(p_Rec."Tax Code", p_Rec."Link to Table", p_Rec.Type, p_Rec."No.") then begin
                    if Tax_L.Get(p_Rec."Tax Code") then begin
                        ThridPartySubjectToTax_L."Invoiced Tax" := Tax_L."Tax Paid By The Company";
                        ThridPartySubjectToTax_L.Modify();
                    end;
                end else
                    if not p_IsDeleteTrigger then
                        fInsertThridPartySubjectToTax(p_Rec);
    end;

    local procedure fUpdateTaxThridParty(var p_Rec: Record "CAGTX_Tax Assign. Third Party"; p_xRec: Record "CAGTX_Tax Assign. Third Party")
    var
        CMBTaxChargedtoCust_L: Record "CAGTX_Tax Assign. Third Party";
        CMBTaxChargedtoCust2_L: Record "CAGTX_Tax Assign. Third Party";
    begin
        if p_Rec.Type <> p_Rec.Type::"Third Party" then begin
            CMBTaxChargedtoCust_L.SetRange("Tax Code", p_Rec."Tax Code");
            CMBTaxChargedtoCust_L.SetRange("Link to Table", p_Rec."Link to Table");
            if p_Rec.Type = p_Rec.Type::"Posting Group" then begin
                p_Rec.TestField("Tax Code");
                p_Rec.TestField("No.");
                CMBTaxChargedtoCust_L.SetRange(Type, CMBTaxChargedtoCust_L.Type::"Third Party");
                CMBTaxChargedtoCust_L.SetRange("Post. Group Filter", p_Rec."No.");
                if p_Rec."Link to Table" = p_Rec."Link to Table"::Customer then begin
                    CMBTaxChargedtoCust_L.SetRange("Is in Customer Posting Gp.", true);
                    CMBTaxChargedtoCust_L.CalcFields("Is in Customer Posting Gp.");
                end else begin
                    CMBTaxChargedtoCust_L.SetRange("Is in Vendor Posting Gp.", true);
                    CMBTaxChargedtoCust_L.CalcFields("Is in Vendor Posting Gp.");
                end;
                if not CMBTaxChargedtoCust_L.IsEmpty then
                    CMBTaxChargedtoCust_L.DeleteAll(true);
            end else
                if p_Rec.Type = p_Rec.Type::All then begin
                    p_Rec.TestField("Tax Code");
                    CMBTaxChargedtoCust_L.SetRange(Type, CMBTaxChargedtoCust_L.Type::"Third Party", CMBTaxChargedtoCust_L.Type::"Posting Group");
                    if CMBTaxChargedtoCust_L.FindSet(true, true) then
                        repeat
                            if p_xRec.RecordId <> CMBTaxChargedtoCust_L.RecordId then begin
                                CMBTaxChargedtoCust2_L := CMBTaxChargedtoCust_L;
                                CMBTaxChargedtoCust2_L.Delete(true);
                            end;
                        until CMBTaxChargedtoCust_L.Next() = 0;
                end;
        end;
    end;

    local procedure fInsertThridPartySubjectToTax(p_Rec: Record "CAGTX_Tax Assign. Third Party")
    var
        CustomerSubjectToTax_L: Record "CAGTX_Customer Subject To Tax";
        Tax_L: Record CAGTX_Tax;
    begin
        if Tax_L.Get(p_Rec."Tax Code") and Tax_L."Tax Paid By The Company" then begin
            CustomerSubjectToTax_L.Init();
            CustomerSubjectToTax_L.Validate(Type, p_Rec.Type);
            CustomerSubjectToTax_L.Validate("Tax Code", p_Rec."Tax Code");
            CustomerSubjectToTax_L.Validate("No.", p_Rec."No.");
            CustomerSubjectToTax_L."Invoiced Tax" := Tax_L."Tax Paid By The Company";
            if not CustomerSubjectToTax_L.Insert() then
                CustomerSubjectToTax_L.Modify();
        end;
    end;

    procedure ShowThridPartyUseSubjectToTax(p_LinkTotable: Option Customer,Vendor; p_No: Code[20]; p_PostingGp: Code[20])
    var
        CustTax_L: Record "CAGTX_Customer Subject To Tax";
        PageCustomerTax_L: Page "CAGTX_Third Party Subj. To Ta";
    begin
        CustTax_L.FilterGroup(10);
        CustTax_L.SetRange(Type, CustTax_L.Type::"Third Party");
        CustTax_L.SetRange("Link to Table", p_LinkTotable);
        CustTax_L.SetRange("No.", p_No);
        if CustTax_L.FindFirst() then
            repeat
                CustTax_L.Mark := true;
            until CustTax_L.Next() = 0;
        CustTax_L.SetRange(Type, CustTax_L.Type::"Posting Group");
        CustTax_L.SetRange("No.", p_PostingGp);
        if CustTax_L.FindFirst() then
            CustTax_L.Mark := true;
        CustTax_L.SetRange(Type, CustTax_L.Type::All);
        CustTax_L.SetRange("No.");
        if CustTax_L.FindFirst() then
            CustTax_L.Mark := true;
        CustTax_L.SetRange(Type);
        CustTax_L.MarkedOnly(true);
        CustTax_L.FilterGroup(0);
        PageCustomerTax_L.SetTableView(CustTax_L);
        PageCustomerTax_L.Run();
    end;

    procedure SetPriceIncludeVAT(var P_Value: Decimal; p_VATPercent: Decimal; p_RoundingPrecision: Decimal; p_PriceIncludeVAT: Boolean)
    begin
        if p_PriceIncludeVAT then
            P_Value := Round(P_Value * (1 + (p_VATPercent / 100)), p_RoundingPrecision);
    end;

    procedure SetLineDiscount(var P_CMBDocTaxBuffer: Record "CAGTX_Doc. Tax Buffer")
    begin
        P_CMBDocTaxBuffer."Tax Unit Amount" := Round(P_CMBDocTaxBuffer."Tax Unit Amount" * (1 - (P_CMBDocTaxBuffer."Line Discount %" / 100)),
                                                  P_CMBDocTaxBuffer."Unit-Amount Rounding Precision")
    end;

    procedure CalculateTaxLineAmount(var P_CMBDocTaxBuffer: Record "CAGTX_Doc. Tax Buffer") returnValue: Boolean
    var
        Tax_L: Record CAGTX_Tax;
        CMBTaxMgt_L: Codeunit "CAGTX_Tax Management";
    begin
        Tax_L.Get(P_CMBDocTaxBuffer."Tax Code");
        case P_CMBDocTaxBuffer."Rate Type" of
            P_CMBDocTaxBuffer."Rate Type"::"Unit Amount":
                begin

                    P_CMBDocTaxBuffer."Tax Unit Amount" := Round(P_CMBDocTaxBuffer."Rate value", P_CMBDocTaxBuffer."Unit-Amount Rounding Precision");


                    CMBTaxMgt_L.SetPriceIncludeVAT(P_CMBDocTaxBuffer."Rate value", P_CMBDocTaxBuffer."Tax VAT %",
                                                     P_CMBDocTaxBuffer."Unit-Amount Rounding Precision", P_CMBDocTaxBuffer."Prices Including VAT");

                    P_CMBDocTaxBuffer."Amount Tax Line" := Round(P_CMBDocTaxBuffer."Tax Unit Amount" * P_CMBDocTaxBuffer."Quantity Tax Line",
                                                              P_CMBDocTaxBuffer."Amount Rounding Precision");
                    returnValue := (P_CMBDocTaxBuffer."Quantity Tax Line" <> 0);
                end;
            P_CMBDocTaxBuffer."Rate Type"::Percent:
                begin

                    if (P_CMBDocTaxBuffer."Qty. per Unit of Measure" <> 0) then
                        P_CMBDocTaxBuffer."Tax Unit Amount" := Round(
                                            (P_CMBDocTaxBuffer."Unit Amount" / P_CMBDocTaxBuffer."Qty. per Unit of Measure") * P_CMBDocTaxBuffer."Rate value" / 100,
                                            P_CMBDocTaxBuffer."Unit-Amount Rounding Precision")
                    else
                        P_CMBDocTaxBuffer."Tax Unit Amount" := Round(
                                            P_CMBDocTaxBuffer."Unit Amount" * P_CMBDocTaxBuffer."Rate value" / 100,
                                            P_CMBDocTaxBuffer."Unit-Amount Rounding Precision");

                    IF Tax_L."Allow Line Disc." THEN
                        CMBTaxMgt_L.SetLineDiscount(P_CMBDocTaxBuffer);

                    P_CMBDocTaxBuffer."Amount Tax Line" := Round(P_CMBDocTaxBuffer."Tax Unit Amount" * P_CMBDocTaxBuffer."Quantity Tax Line",
                                                                 P_CMBDocTaxBuffer."Amount Rounding Precision");
                    returnValue := (P_CMBDocTaxBuffer."Tax Unit Amount" <> 0);
                end;
            P_CMBDocTaxBuffer."Rate Type"::"Flat Rate":
                begin
                    P_CMBDocTaxBuffer."Quantity Tax Line" := 1;
                    P_CMBDocTaxBuffer."Amount Tax Line" := P_CMBDocTaxBuffer."Quantity Tax Line" * P_CMBDocTaxBuffer."Rate value";
                    CMBTaxMgt_L.SetPriceIncludeVAT(P_CMBDocTaxBuffer."Rate value", P_CMBDocTaxBuffer."Tax VAT %",
                                                     P_CMBDocTaxBuffer."Unit-Amount Rounding Precision", P_CMBDocTaxBuffer."Prices Including VAT");
                    P_CMBDocTaxBuffer."Tax Unit Amount" := P_CMBDocTaxBuffer."Rate value";
                    P_CMBDocTaxBuffer."Amount Tax Line" := Round(P_CMBDocTaxBuffer."Tax Unit Amount" * P_CMBDocTaxBuffer."Quantity Tax Line",
                                                                 P_CMBDocTaxBuffer."Amount Rounding Precision");

                    returnValue := (P_CMBDocTaxBuffer."Tax Unit Amount" <> 0);
                end;
            else
                OnCalculateSpecificTaxLineAmount(P_CMBDocTaxBuffer, Tax_L, returnValue);
        end;
    end;

    procedure CalculateTaxTotalAmount(var P_CMBDocTaxBuffer: Record "CAGTX_Doc. Tax Buffer") returnValue: Boolean
    var
        Tax_L: Record CAGTX_Tax;
        CMBTaxMgt_L: Codeunit "CAGTX_Tax Management";
    begin
        Tax_L.Get(P_CMBDocTaxBuffer."Tax Code");

        case P_CMBDocTaxBuffer."Rate Type" of
            P_CMBDocTaxBuffer."Rate Type"::"Unit Amount":
                begin
                    P_CMBDocTaxBuffer."Tax Unit Amount" := Round(P_CMBDocTaxBuffer."Rate value", P_CMBDocTaxBuffer."Unit-Amount Rounding Precision");

                    // TODO
                    // IF Tax_L."Allow Line Disc." THEN
                    //   CMBTaxMgt_L.SetLineDiscount(P_CMBDocTaxBuffer);

                    CMBTaxMgt_L.SetPriceIncludeVAT(P_CMBDocTaxBuffer."Tax Unit Amount", P_CMBDocTaxBuffer."Tax VAT %",
                                                     P_CMBDocTaxBuffer."Unit-Amount Rounding Precision", P_CMBDocTaxBuffer."Prices Including VAT");

                    P_CMBDocTaxBuffer."Amount Tax Line" := Round(P_CMBDocTaxBuffer."Tax Unit Amount" * P_CMBDocTaxBuffer."Base Quantity Tax",
                                                              P_CMBDocTaxBuffer."Amount Rounding Precision");
                    returnValue := (P_CMBDocTaxBuffer."Tax Unit Amount" <> 0);
                end;
            P_CMBDocTaxBuffer."Rate Type"::Percent:
                begin
                    P_CMBDocTaxBuffer."Quantity Tax Line" := 1;

                    if (P_CMBDocTaxBuffer."Qty. per Unit of Measure" <> 0) then
                        P_CMBDocTaxBuffer."Tax Unit Amount" := Round(
                                            (P_CMBDocTaxBuffer."Unit Amount" / P_CMBDocTaxBuffer."Qty. per Unit of Measure") * P_CMBDocTaxBuffer."Rate value" / 100,
                                            P_CMBDocTaxBuffer."Unit-Amount Rounding Precision")
                    else
                        P_CMBDocTaxBuffer."Tax Unit Amount" := Round(
                                            P_CMBDocTaxBuffer."Unit Amount" * P_CMBDocTaxBuffer."Rate value" / 100,
                                            P_CMBDocTaxBuffer."Unit-Amount Rounding Precision");

                    if Tax_L."Allow Line Disc." then
                        CMBTaxMgt_L.SetLineDiscount(P_CMBDocTaxBuffer);

                    P_CMBDocTaxBuffer."Amount Tax Line" := P_CMBDocTaxBuffer."Tax Unit Amount" * P_CMBDocTaxBuffer."Base Quantity Tax";
                    returnValue := (P_CMBDocTaxBuffer."Tax Unit Amount" <> 0);
                end;
            P_CMBDocTaxBuffer."Rate Type"::"Flat Rate":
                begin
                    P_CMBDocTaxBuffer."Quantity Tax Line" := 1;
                    P_CMBDocTaxBuffer."Amount Tax Line" := P_CMBDocTaxBuffer."Quantity Tax Line" * P_CMBDocTaxBuffer."Rate value";
                    CMBTaxMgt_L.SetPriceIncludeVAT(P_CMBDocTaxBuffer."Rate value", P_CMBDocTaxBuffer."Tax VAT %",
                                                     P_CMBDocTaxBuffer."Unit-Amount Rounding Precision", P_CMBDocTaxBuffer."Prices Including VAT");
                    P_CMBDocTaxBuffer."Tax Unit Amount" := P_CMBDocTaxBuffer."Rate value";
                    returnValue := (P_CMBDocTaxBuffer."Tax Unit Amount" <> 0);
                end;
            else
                OnCalculateSpecificTaxTotalAmount(P_CMBDocTaxBuffer, Tax_L, returnValue);
        end;
    end;

    procedure CopyTaxesOnNewItem(SourceItem: Record Item; TargetItem: Record Item)
    var
        SourceTaxes: record "CAGTX_Item Tax V2";
        TargetTaxes: record "CAGTX_Item Tax V2";
    begin
        SourceTaxes.Reset();
        SourceTaxes.SetRange(Type, SourceTaxes.Type::Item);
        SourceTaxes.SetRange("No.", SourceItem."No.");
        if SourceTaxes.FindSet() then
            repeat
                TargetTaxes.init();
                TargetTaxes.TransferFields(SourceTaxes);
                TargetTaxes."No." := TargetItem."No.";
                TargetTaxes.Insert();
            until SourceTaxes.next() = 0;
    end;

    procedure RoundBaseQty(QtyToRound: Decimal): Decimal
    begin
        exit(Round(QtyToRound, 0.00001));
    end;

    procedure OpenItemTaxes(ItemNo: Code[20])
    var
        ItemTax: Record "CAGTX_Item Tax V2";
        ItemTaxPage: Page "CAGTX_Item Tax";
    begin
        ItemTaxPage.SetFromItemNo(ItemNo);
        ItemTax.Reset();
        ItemTax.SetRange(Type, ItemTax.Type::Item);
        ItemTax.SetRange("No.", ItemNo);
        ItemTaxPage.SetTableView(ItemTax);
        ItemTaxPage.RunModal();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateSpecificTaxLineAmount(var P_CMBDocTaxBuffer: Record "CAGTX_Doc. Tax Buffer"; var P_Tax: Record CAGTX_Tax; var p_Insertax: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateSpecificTaxTotalAmount(var P_CMBDocTaxBuffer: Record "CAGTX_Doc. Tax Buffer"; var P_Tax: Record CAGTX_Tax; var p_Insertax: Boolean)
    begin
    end;
}

