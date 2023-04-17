codeunit 8062639 "CAGTX_Tax Subscription"
{
    var
        CMBSalesTaxManagement_G: Codeunit "CAGTX_Sales Tax Management";
        CMBPurchTaxManagement_G: Codeunit "CAGTX_Purch. Tax Management";
        CMBServiceTaxManagement_G: Codeunit "CAGTX_Service Tax Management";
        TransfertaxLines_G: Codeunit "CAGTX_Transfer tax Lines";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnBeforeInsertToSalesLine', '', true, false)]
    local procedure RunC6620OnBeforeInsertToSalesLine(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line"; FromDocType: Option; RecalcLines: Boolean; var ToSalesHeader: Record "Sales Header"; DocLineNo: Integer; var NextLineNo: Integer)
    begin
        if FromSalesLine."CAGTX_Origin Tax Line" <> 0 then
            ToSalesLine."CAGTX_Origin Tax Line" := TransfertaxLines_G.GetNewLineNumber(FromSalesLine."CAGTX_Origin Tax Line");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnCopySalesDocOnBeforeCopyLines', '', false, false)]
    local procedure OnCopySalesDocOnBeforeCopyLines(FromSalesHeader: Record "Sales Header"; var ToSalesHeader: Record "Sales Header"; var IsHandled: Boolean);
    begin
        TransfertaxLines_G.ClearRecLineNo();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopySalesLineFromSalesDocSalesLine', '', false, false)]
    local procedure OnAfterCopySalesLineFromSalesDocSalesLine(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesLine: Record "Sales Line"; IncludeHeader: Boolean; RecalculateLines: Boolean);
    begin
        TransfertaxLines_G.InsertLineNumbers(FromSalesLine."Line No.", ToSalesLine."Line No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopySalesLineFromSalesCrMemoLineBuffer', '', false, false)]
    local procedure OnAfterCopySalesLineFromSalesCrMemoLineBuffer(var ToSalesLine: Record "Sales Line"; FromSalesCrMemoLine: Record "Sales Cr.Memo Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocSalesLine: Record "Sales Line"; ToSalesHeader: Record "Sales Header"; FromSalesLineBuf: Record "Sales Line");
    begin
        TransfertaxLines_G.InsertLineNumbers(FromSalesCrMemoLine."Line No.", ToSalesLine."Line No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopySalesLineFromSalesShptLineBuffer', '', false, false)]
    local procedure OnAfterCopySalesLineFromSalesShptLineBuffer(var ToSalesLine: Record "Sales Line"; FromSalesShipmentLine: Record "Sales Shipment Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocSalesLine: Record "Sales Line"; ToSalesHeader: Record "Sales Header"; FromSalesLineBuf: Record "Sales Line"; ExactCostRevMandatory: Boolean);
    begin
        TransfertaxLines_G.InsertLineNumbers(FromSalesShipmentLine."Line No.", ToSalesLine."Line No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopySalesLineFromSalesLineBuffer', '', false, false)]
    local procedure OnAfterCopySalesLineFromSalesLineBuffer(var ToSalesLine: Record "Sales Line"; FromSalesInvLine: Record "Sales Invoice Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocSalesLine: Record "Sales Line"; ToSalesHeader: Record "Sales Header"; FromSalesLineBuf: Record "Sales Line"; var FromSalesLine2: Record "Sales Line"; FromSalesLine: Record "Sales Line"; ExactCostRevMandatory: Boolean);
    begin
        TransfertaxLines_G.InsertLineNumbers(FromSalesInvLine."Line No.", ToSalesLine."Line No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopySalesLineFromReturnRcptLineBuffer', '', false, false)]
    local procedure OnAfterCopySalesLineFromReturnRcptLineBuffer(var ToSalesLine: Record "Sales Line"; FromReturnReceiptLine: Record "Return Receipt Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocSalesLine: Record "Sales Line"; ToSalesHeader: Record "Sales Header"; FromSalesLineBuf: Record "Sales Line"; CopyItemTrkg: Boolean);
    begin
        TransfertaxLines_G.InsertLineNumbers(FromReturnReceiptLine."Line No.", ToSalesLine."Line No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopyArchSalesLine', '', false, false)]
    local procedure OnAfterCopyArchSalesLine(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; FromSalesLineArchive: Record "Sales Line Archive"; IncludeHeader: Boolean; RecalculateLines: Boolean);
    begin
        TransfertaxLines_G.InsertLineNumbers(FromSalesLineArchive."Line No.", ToSalesLine."Line No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnBeforeCopyPurchaseDocument', '', false, false)]
    local procedure OnBeforeCopyPurchaseDocument(FromDocumentType: Option; FromDocumentNo: Code[20]; var ToPurchaseHeader: Record "Purchase Header");
    begin
        TransfertaxLines_G.ClearRecLineNo();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnBeforeInsertToPurchLine', '', true, false)]
    local procedure RunC6620OnBeforeInsertToPurchLine(var ToPurchLine: Record "Purchase Line"; FromPurchLine: Record "Purchase Line"; FromDocType: Option; RecalcLines: Boolean; var ToPurchHeader: Record "Purchase Header")
    begin
        if FromPurchLine."CAGTX_Origin Tax Line" <> 0 then
            ToPurchLine."CAGTX_Origin Tax Line" := TransfertaxLines_G.GetNewLineNumber(FromPurchLine."CAGTX_Origin Tax Line");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnCopyPurchDocPurchLineOnAfterCopyPurchLine', '', false, false)]
    local procedure OnCopyPurchDocPurchLineOnAfterCopyPurchLine(ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; IncludeHeader: Boolean; RecalculateLines: Boolean);
    begin
        TransfertaxLines_G.InsertLineNumbers(FromPurchLine."Line No.", ToPurchLine."Line No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopyPurchLineFromPurchLineBuffer', '', false, false)]
    local procedure OnAfterCopyPurchLineFromPurchLineBuffer(var ToPurchLine: Record "Purchase Line"; FromPurchInvLine: Record "Purch. Inv. Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocPurchaseLine: Record "Purchase Line"; ToPurchHeader: Record "Purchase Header"; FromPurchLineBuf: Record "Purchase Line");
    begin
        TransfertaxLines_G.InsertLineNumbers(FromPurchInvLine."Line No.", ToPurchLine."Line No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopyPurchLineFromPurchCrMemoLineBuffer', '', false, false)]
    local procedure OnAfterCopyPurchLineFromPurchCrMemoLineBuffer(var ToPurchaseLine: Record "Purchase Line"; FromPurchCrMemoLine: Record "Purch. Cr. Memo Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocPurchLine: Record "Purchase Line"; ToPurchHeader: Record "Purchase Header"; FromPurchLineBuf: Record "Purchase Line");
    begin
        TransfertaxLines_G.InsertLineNumbers(FromPurchCrMemoLine."Line No.", ToPurchaseLine."Line No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopyPurchLineFromPurchRcptLineBuffer', '', false, false)]
    local procedure OnAfterCopyPurchLineFromPurchRcptLineBuffer(var ToPurchaseLine: Record "Purchase Line"; FromPurchRcptLine: Record "Purch. Rcpt. Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocPurchLine: Record "Purchase Line"; ToPurchHeader: Record "Purchase Header"; FromPurchLineBuf: Record "Purchase Line"; CopyItemTrkg: Boolean);
    begin
        TransfertaxLines_G.InsertLineNumbers(FromPurchRcptLine."Line No.", ToPurchaseLine."Line No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopyPurchLineFromReturnShptLineBuffer', '', false, false)]
    local procedure OnAfterCopyPurchLineFromReturnShptLineBuffer(var ToPurchaseLine: Record "Purchase Line"; FromReturnShipmentLine: Record "Return Shipment Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocPurchLine: Record "Purchase Line"; ToPurchHeader: Record "Purchase Header"; FromPurchLineBuf: Record "Purchase Line"; CopyItemTrkg: Boolean);
    begin
        TransfertaxLines_G.InsertLineNumbers(FromReturnShipmentLine."Line No.", ToPurchaseLine."Line No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopyArchPurchLine', '', false, false)]
    local procedure OnAfterCopyArchPurchLine(ToPurchHeader: Record "Purchase Header"; var ToPurchaseLine: Record "Purchase Line"; FromPurchaseLineArchive: Record "Purchase Line Archive"; IncludeHeader: Boolean; RecalculateLines: Boolean);
    begin
        TransfertaxLines_G.InsertLineNumbers(FromPurchaseLineArchive."Line No.", ToPurchaseLine."Line No.");
    end;


    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnBeforeDeleteEvent', '', true, false)]
    local procedure RunT37BeforeDeleteLine(var Rec: Record "Sales Line"; RunTrigger: Boolean)
    begin
        if RunTrigger and not Rec.IsTemporary then
            CMBSalesTaxManagement_G.DeleteTaxLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Shipment Line", 'OnBeforeInsertInvLineFromShptLine', '', true, false)]
    local procedure RunT111OnBeforeInsertInvLineFromShptLine(var SalesShptLine: Record "Sales Shipment Line"; var SalesLine: Record "Sales Line")
    var
        SalesTaxManagement_L: Codeunit "CAGTX_Sales Tax Management";
    begin
        SalesLine."CAGTX_Origin Tax Line" := SalesTaxManagement_L.GetTaxSourceLine(SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesShptLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Invoice Header", 'OnAfterInsertEvent', '', true, false)]
    local procedure RunT112AfterInsertInvHeader(var Rec: Record "Sales Invoice Header"; RunTrigger: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        if Rec."Prepayment Invoice" then
            if SalesHeader.Get(SalesHeader."Document Type"::Order, Rec."Prepayment Order No.") then
                CMBSalesTaxManagement_G.GenerateTaxLine(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Cr.Memo Header", 'OnAfterInsertEvent', '', true, false)]
    local procedure RunT114AfterInsertCrMemo(var Rec: Record "Sales Cr.Memo Header"; RunTrigger: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        if Rec."Prepayment Credit Memo" then
            if SalesHeader.Get(SalesHeader."Document Type"::Order, Rec."Prepayment Order No.") then
                CMBSalesTaxManagement_G.GenerateTaxLine(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Return Receipt Line", 'OnBeforeInsertInvLineFromRetRcptLine', '', true, false)]
    local procedure RunT6661OnBeforeInsertInvLineFromRetRcptLine(var SalesLine: Record "Sales Line"; SalesOrderLine: Record "Sales Line"; var ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean)
    var
        SalesTaxManagement_L: Codeunit "CAGTX_Sales Tax Management";
    begin
        SalesLine."CAGTX_Origin Tax Line" := SalesTaxManagement_L.GetTaxSourceLine(SalesLine."Document Type".AsInteger(), SalesLine."Document No.", ReturnReceiptLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', true, false)]
    local procedure RunC80BeforePostSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        if (SalesHeader.Status = SalesHeader.Status::Open) or (SalesHeader.Status = SalesHeader.Status::"Pending Prepayment") then
            CMBSalesTaxManagement_G.GenerateTaxLine(SalesHeader);
        CMBSalesTaxManagement_G.SetTaxQtyToPost(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterInsertDropOrderPurchRcptHeader', '', true, false)]
    local procedure RuncC80OnAfterInsertDropOrderPurchRcptHeader(var PurchRcptHeader: Record "Purch. Rcpt. Header")
    var
        CMBTax_L: Record CAGTX_Tax;
        PurchOrderLine_L: Record "Purchase Line";
        TempPurchaseOrderLine_L: Record "Purchase Line" temporary;
        PurchRcptLine_L: Record "Purch. Rcpt. Line";
        CMBPurchTaxManagement_L: Codeunit "CAGTX_Purch. Tax Management";
    begin
        if not CMBTax_L.IsEmpty then begin
            PurchRcptLine_L.Reset();
            PurchRcptLine_L.SetRange("Document No.", PurchRcptHeader."No.");
            if PurchRcptLine_L.FindSet() then
                repeat
                    if PurchOrderLine_L.Get(PurchOrderLine_L."Document Type"::Order, PurchRcptLine_L."Order No.", PurchRcptLine_L."Order Line No.") then
                        CMBPurchTaxManagement_L.SetDropShipmentLine(PurchRcptHeader, PurchRcptLine_L, PurchOrderLine_L, TempPurchaseOrderLine_L);
                until PurchRcptLine_L.Next() = 0;

            CMBPurchTaxManagement_L.SetTaxAmtToPostTotal(PurchRcptHeader, TempPurchaseOrderLine_L);
            CMBPurchTaxManagement_L.SetDropShipmentTotal(PurchRcptHeader, PurchRcptLine_L, PurchOrderLine_L);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnBeforeManualReleaseSalesDoc', '', true, false)]
    local procedure RunC414OnBeforeManualReleaseSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    begin
        CMBSalesTaxManagement_G.GenerateTaxLine(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Sales Shipment Line", 'OnBeforeOnRun', '', true, false)]
    local procedure RunC5815OnBeforeOnRun(var SalesShipmentLine: Record "Sales Shipment Line"; var IsHandled: Boolean; var SkipTypeCheck: Boolean)
    var
        CMBTax_L: Record CAGTX_Tax;
    begin
        if not CMBTax_L.IsEmpty then
            SalesShipmentLine.SetRange("CAGTX_Origin Tax Line", 0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Sales Shipment Line", 'OnAfterCode', '', true, false)]
    local procedure RunC5815OnAfterCode(var SalesShipmentLine: Record "Sales Shipment Line")
    var
        CMBTax_L: Record CAGTX_Tax;
        CMBSalesTaxManagement_L: Codeunit "CAGTX_Sales Tax Management";
        FilterText_L: Text;
    begin
        if not CMBTax_L.IsEmpty then begin
            FilterText_L := SalesShipmentLine.GetFilter(Correction);
            SalesShipmentLine.SetRange("CAGTX_Origin Tax Line", 0);
            SalesShipmentLine.SetRange(Correction, true);
            if not SalesShipmentLine.IsEmpty() then begin
                SalesShipmentLine.Find('-');
                repeat
                    CMBSalesTaxManagement_L.UndoSalesShipmentTaxLine(SalesShipmentLine);
                until SalesShipmentLine.Next() = 0;
            end;
            SalesShipmentLine.SetRange("CAGTX_Origin Tax Line");
            SalesShipmentLine.SetFilter(Correction, FilterText_L);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Return Receipt Line", 'OnBeforeOnRun', '', true, false)]
    local procedure RunC5816OnBeforeOnRun(var ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean; var SkipTypeCheck: Boolean)
    var
        CMBTax_L: Record CAGTX_Tax;
    begin
        if not CMBTax_L.IsEmpty then
            ReturnReceiptLine.SetRange("CAGTX_Origin Tax Line", 0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Return Receipt Line", 'OnAfterCode', '', true, false)]
    local procedure RunC5816OnAfterCode(var ReturnReceiptLine: Record "Return Receipt Line")
    var
        CMBTax_L: Record CAGTX_Tax;
        CMBSalesTaxManagement_L: Codeunit "CAGTX_Sales Tax Management";
        FilterText_L: Text;
    begin
        if not CMBTax_L.IsEmpty then begin
            FilterText_L := ReturnReceiptLine.GetFilter(Correction);
            ReturnReceiptLine.SetRange(Correction, true);
            ReturnReceiptLine.SetRange("CAGTX_Origin Tax Line", 0);
            if not ReturnReceiptLine.IsEmpty then begin
                ReturnReceiptLine.Find('-');
                repeat
                    CMBSalesTaxManagement_L.UndoReturnRcptTaxLine(ReturnReceiptLine);
                until ReturnReceiptLine.Next() = 0;
            end;
            ReturnReceiptLine.SetRange("CAGTX_Origin Tax Line");
            ReturnReceiptLine.SetFilter(Correction, FilterText_L);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnBeforeDeleteEvent', '', true, false)]
    local procedure RunT39OnBeforeDeleteLine(var Rec: Record "Purchase Line"; RunTrigger: Boolean)
    begin
        if RunTrigger and not Rec.IsTemporary then
            CMBPurchTaxManagement_G.DeleteTaxLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Rcpt. Line", 'OnBeforeInsertInvLineFromRcptLine', '', false, false)]
    local procedure OnBeforeInsertInvLineFromRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; var PurchLine: Record "Purchase Line"; PurchOrderLine: Record "Purchase Line");
    var
        PurchTaxManagement_L: Codeunit "CAGTX_Purch. Tax Management";
    begin
        PurchLine."CAGTX_Origin Tax Line" := PurchTaxManagement_L.GetTaxSourceLine(PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchRcptLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Inv. Header", 'OnAfterInsertEvent', '', true, false)]
    local procedure RunT122AfterInsertInvHeader(var Rec: Record "Purch. Inv. Header"; RunTrigger: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if Rec."Prepayment Invoice" then
            if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, Rec."Prepayment Order No.") then
                CMBPurchTaxManagement_G.GenerateTaxLine(PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Cr. Memo Hdr.", 'OnAfterInsertEvent', '', true, false)]
    local procedure RunT124AfterInsertCrMemo(var Rec: Record "Purch. Cr. Memo Hdr."; RunTrigger: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if Rec."Prepayment Credit Memo" then
            if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, Rec."Prepayment Order No.") then
                CMBPurchTaxManagement_G.GenerateTaxLine(PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Return Shipment Line", 'OnBeforeInsertInvLineFromRetShptLine', '', true, false)]
    local procedure RunT6651OnBeforeInsertInvLineFromRetShptLine(var PurchLine: Record "Purchase Line"; var PurchOrderLine: Record "Purchase Line"; var ReturnShipmentLine: Record "Return Shipment Line"; var IsHandled: Boolean)
    var
        PurchTaxManagement_L: Codeunit "CAGTX_Purch. Tax Management";
    begin
        PurchLine."CAGTX_Origin Tax Line" := PurchTaxManagement_L.GetTaxSourceLine(PurchLine."Document Type".AsInteger(), PurchLine."Document No.", ReturnShipmentLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', true, false)]
    local procedure RunC90OnBeforePostPurchaseDoc(var PurchaseHeader: Record "Purchase Header")
    begin
        if (PurchaseHeader.Status in [PurchaseHeader.Status::Open, PurchaseHeader.Status::"Pending Prepayment"]) then
            CMBPurchTaxManagement_G.GenerateTaxLine(PurchaseHeader);
        CMBPurchTaxManagement_G.SetTaxQtyToPost(PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterInsertCombinedSalesShipment', '', true, false)]
    local procedure RuncC90OnAfterInsertCombinedSalesShipment(var SalesShipmentHeader: Record "Sales Shipment Header")
    var
        CMBTax_L: Record CAGTX_Tax;
        SalesShptLine_L: Record "Sales Shipment Line";
        SalesOrderLine_L: Record "Sales Line";
        TempSalesOrderLine_L: Record "Sales Line" temporary;
        CMBSalesTaxManagement_L: Codeunit "CAGTX_Sales Tax Management";
    begin
        if not CMBTax_L.IsEmpty then begin
            SalesShptLine_L.Reset();
            SalesShptLine_L.SetRange("Document No.", SalesShipmentHeader."No.");
            if SalesShptLine_L.FindSet() then
                repeat
                    if SalesOrderLine_L.Get(SalesOrderLine_L."Document Type"::Order, SalesShptLine_L."Order No.", SalesShptLine_L."Order Line No.") then
                        CMBSalesTaxManagement_L.SetDropShipmentLine(SalesShipmentHeader, SalesShptLine_L, SalesOrderLine_L, TempSalesOrderLine_L);
                until SalesShptLine_L.Next() = 0;
            CMBSalesTaxManagement_L.SetTaxAmtToPostTotal(SalesShipmentHeader, TempSalesOrderLine_L);
            CMBSalesTaxManagement_L.SetDropShipmentTotal(SalesShipmentHeader, SalesShptLine_L, SalesOrderLine_L);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnBeforeManualReleasePurchaseDoc', '', true, false)]
    local procedure RunC415OnBeforeManualReleasePurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean)
    begin
        CMBPurchTaxManagement_G.GenerateTaxLine(PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnBeforePerformManualCheckAndRelease', '', true, false)]
    local procedure RunC415OnBeforePerformManualCheckAndRelease(var PurchHeader: Record "Purchase Header"; PreviewMode: Boolean)
    begin
        CMBPurchTaxManagement_G.GenerateTaxLine(PurchHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Purchase Receipt Line", 'OnBeforeOnRun', '', true, false)]
    local procedure RunC5813OnBeforeOnRun(var PurchRcptLine: Record "Purch. Rcpt. Line"; var IsHandled: Boolean; var SkipTypeCheck: Boolean)
    var
        CMBTax_L: Record CAGTX_Tax;
    begin
        if not CMBTax_L.IsEmpty then
            PurchRcptLine.SetRange("CAGTX_Origin Tax Line", 0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Purchase Receipt Line", 'OnAfterCode', '', true, false)]
    local procedure RunC5813OnAfterCode(var PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        CMBTax_L: Record CAGTX_Tax;
        CMBPurchTaxManagement_L: Codeunit "CAGTX_Purch. Tax Management";
        FilterText_L: Text;
    begin
        if not CMBTax_L.IsEmpty() then begin
            FilterText_L := PurchRcptLine.GetFilter(Correction);
            PurchRcptLine.SetRange(Correction, true);
            PurchRcptLine.SetRange("CAGTX_Origin Tax Line", 0);
            if not PurchRcptLine.IsEmpty then begin
                PurchRcptLine.Find('-');
                repeat
                    CMBPurchTaxManagement_L.UndoPurchaseReceiptTaxLine(PurchRcptLine);
                until PurchRcptLine.Next() = 0;
            end;
            PurchRcptLine.SetRange("CAGTX_Origin Tax Line");
            PurchRcptLine.SetFilter(Correction, FilterText_L);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Return Shipment Line", 'OnBeforeOnRun', '', true, false)]
    local procedure RunC5814OnBeforeRun(var ReturnShipmentLine: Record "Return Shipment Line"; var IsHandled: Boolean; var SkipTypeCheck: Boolean)
    var
        CMBTax_L: Record CAGTX_Tax;
    begin
        if not CMBTax_L.IsEmpty then
            ReturnShipmentLine.SetRange("CAGTX_Origin Tax Line", 0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Return Shipment Line", 'OnAfterCode', '', true, false)]
    local procedure RunC5814OnAfterCode(var ReturnShipmentLine: Record "Return Shipment Line")
    var
        CMBTax_L: Record CAGTX_Tax;
        CMBPurchTaxManagement_L: Codeunit "CAGTX_Purch. Tax Management";
        FilterText_L: Text;
    begin
        if not CMBTax_L.IsEmpty then begin
            FilterText_L := ReturnShipmentLine.GetFilter(Correction);
            ReturnShipmentLine.SetRange(Correction, true);
            ReturnShipmentLine.SetRange("CAGTX_Origin Tax Line", 0);
            if not ReturnShipmentLine.IsEmpty then begin
                ReturnShipmentLine.Find('-');
                repeat
                    CMBPurchTaxManagement_L.UndoReturnShipmentTaxLine(ReturnShipmentLine);
                until ReturnShipmentLine.Next() = 0;
            end;
            ReturnShipmentLine.SetRange("CAGTX_Origin Tax Line");
            ReturnShipmentLine.SetFilter(Correction, FilterText_L);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnBeforeDeleteEvent', '', true, false)]
    local procedure RunT5900BeforeDeleteEventHeader(var Rec: Record "Service Line"; RunTrigger: Boolean)
    begin
        if RunTrigger then
            CMBServiceTaxManagement_G.DeleteTaxLine(Rec);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnAfterInitialize', '', true, false)]
    local procedure RunC5988OnAfterInitialize(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var CloseCondition: Boolean; Ship: Boolean; Consume: Boolean; Invoice: Boolean)
    var
        CMBServiceDocTaxDetail_L: Record "CAGTX_Service Doc. Tax Detail";
        ServiceLine_L: Record "Service Line";
        TempServiceLine_L: Record "Service Line" temporary;
        DocumentType_L: Option;
    begin
        if Ship or (ServiceHeader."Document Type" in
            [ServiceHeader."Document Type"::Invoice, ServiceHeader."Document Type"::"Credit Memo"]) then
            CMBServiceTaxManagement_G.GenerateTaxLine(ServiceHeader);

        DocumentType_L := ServiceLine."Document Type".AsInteger();
        CMBServiceDocTaxDetail_L.SetRange("Document Type", ServiceLine."Document Type");
        CMBServiceDocTaxDetail_L.SetRange("Document No.", ServiceLine."Document No.");
        CMBServiceDocTaxDetail_L.SetRange("Line No.", ServiceLine."Line No.");
        if CMBServiceDocTaxDetail_L.FindSet() then begin
            CMBServiceTaxManagement_G.SetTaxLineQtyToPost(ServiceLine);
            repeat
                if ServiceLine_L.Get(CMBServiceDocTaxDetail_L."Document Type", CMBServiceDocTaxDetail_L."Document No.",
                                      CMBServiceDocTaxDetail_L."Tax Line No.") then
                    if (Ship and (ServiceLine_L."Qty. to Ship" <> 0)) or Invoice then begin
                        TempServiceLine_L := ServiceLine_L;
                        TempServiceLine_L."Posting Date" := ServiceLine."Posting Date";
                        if not TempServiceLine_L.Insert() then
                            TempServiceLine_L.Modify();
                    end;
            until CMBServiceDocTaxDetail_L.Next() = 0;
            if TempServiceLine_L.FindFirst() then
                repeat
                    if Consume then
                        TempServiceLine_L.Validate("Qty. to Consume", TempServiceLine_L."Qty. to Ship");
                    if Invoice or (DocumentType_L in [ServiceLine."Document Type"::Invoice.AsInteger(), ServiceLine."Document Type"::"Credit Memo".AsInteger()]) then
                        TempServiceLine_L.InitQtyToInvoice();
                    ServiceLine := TempServiceLine_L;
                    if not ServiceLine.Insert() then
                        ServiceLine.Modify();
                until TempServiceLine_L.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Item", 'OnAfterCopyItem', '', true, false)]
    local procedure OnAfterCopyItem(var CopyItemBuffer: Record "Copy Item Buffer"; SourceItem: Record Item; var TargetItem: Record Item)
    var
        TaxMgt: Codeunit "CAGTX_Tax Management";
    begin
        if CopyItemBuffer.CAGTX_IncludeTaxes then
            TaxMgt.CopyTaxesOnNewItem(SourceItem, TargetItem);
    end;
}

