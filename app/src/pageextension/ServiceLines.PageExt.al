pageextension 8062630 "CAGTX_Service Lines" extends "Service Lines"
{
    actions
    {
        addafter(Preview)
        {
            action("CAGTX_UpdateTax")
            {
                AccessByPermission = TableData CAGTX_Tax = R;
                Caption = 'Update Tax';
                Image = CalculateSalesTax;
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Executes the Update Tax action';

                trigger OnAction()
                var
                    ServiceHeader_L: Record "Service Header";
                    CMBServiceTaxManagement_L: Codeunit "CAGTX_Service Tax Management";
                begin
                    ServiceHeader_L.Get(Rec."Document Type", Rec."Document No.");
                    CMBServiceTaxManagement_L.GenerateTaxLine(ServiceHeader_L);
                    CurrPage.Update(false);
                end;
            }
            action("CAGTX_TaxLines")
            {
                AccessByPermission = TableData CAGTX_Tax = R;
                Caption = 'Tax Lines';
                Image = TaxDetail;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "CAGTX_Service Doc Tax Lines";
                RunPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("Document No.");
                RunPageView = SORTING("Document Type", "Document No.", "Line No.")
                              ORDER(Ascending);
                ApplicationArea = Basic, Suite;
                ToolTip = 'Executes the Tax Lines action';
            }
        }
    }

    /*   var
          "< 3LI GLOCALS 8060990/152 >": Integer;
           IndentTax_G: Integer;*/
}

