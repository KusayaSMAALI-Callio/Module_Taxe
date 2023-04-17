pageextension 8062640 "CAGTX_Sales Return Orde" extends "Sales Return Order"
{
    actions
    {
        addafter("Send IC Return Order Cnfmn.")
        {
            action("CAGTX_TaxLines")
            {
                AccessByPermission = TableData CAGTX_Tax = R;
                Caption = 'Tax Lines';
                Image = TaxDetail;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "CAGTX_Sales Doc Tax Lines";
                RunPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("No.");
                RunPageView = SORTING("Document Type", "Document No.", "Line No.")
                              ORDER(Ascending);
                ApplicationArea = Basic, Suite;
                ToolTip = 'Executes the Tax Lines action';
            }
        }
    }
}

