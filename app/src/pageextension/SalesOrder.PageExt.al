pageextension 8062616 "CAGTX_Sales Order" extends "Sales Order"
{
    layout
    {
        addafter("VAT Bus. Posting Group")
        {
            field("CAGTX_Disable Tax Calculation"; Rec."CAGTX_Disable Tax Calculation")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the value of the CAGTX_Disable Tax Calculation field';
            }
        }
    }
    actions
    {
        addafter(IncomingDocument)
        {
            action("CAGTX_TaxLines")
            {
                AccessByPermission = TableData CAGTX_Tax = R;
                Caption = 'Tax Lines';
                Image = TaxDetail;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "CAGTX_Sales Doc Tax Lines";
                RunPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("No.");
                RunPageView = SORTING("Document Type", "Document No.", "Line No.")
                              ORDER(Ascending);
                ApplicationArea = Basic, Suite;
                ToolTip = 'Executes the Tax Lines action';
            }
            action("CAGTX_UpdateTax")
            {
                AccessByPermission = TableData CAGTX_Tax = R;
                Caption = 'Update Tax';
                Image = CalculateSalesTax;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Executes the Update Tax action';

                trigger OnAction()
                var
                    CMBSalesTaxManagement_L: Codeunit "CAGTX_Sales Tax Management";
                begin
                    CMBSalesTaxManagement_L.GenerateTaxLine(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}

