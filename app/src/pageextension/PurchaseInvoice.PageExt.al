pageextension 8062623 "CAGTX_Purchase Invoice" extends "Purchase Invoice"
{
    layout
    {
        addafter("VAT Bus. Posting Group")
        {
            field("CAGTX_Disable Tax Calculation"; Rec."CAGTX_Disable Tax Calculation")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Disable Tax Calculation';
            }
        }
    }
    actions
    {
        addafter(MoveNegativeLines)
        {
            action("CAGTX_TaxLines")
            {
                AccessByPermission = TableData CAGTX_Tax = R;
                Caption = 'Tax Lines';
                Image = TaxDetail;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "CAGTX_Purch Doc Tax Lines";
                RunPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("No.");
                RunPageView = SORTING("Document Type", "Document No.", "Line No.")
                              ORDER(Ascending);
                ApplicationArea = Basic, Suite;
                ToolTip = 'Tax Lines';
            }
            action("CAGTX_UpdateTaxe")
            {
                AccessByPermission = TableData CAGTX_Tax = R;
                Caption = 'Update Tax';
                Image = CalculateSalesTax;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Update Tax';

                trigger OnAction()
                var
                    CMBPurchTaxManagement_L: Codeunit "CAGTX_Purch. Tax Management";
                begin
                    CMBPurchTaxManagement_L.GenerateTaxLine(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}

