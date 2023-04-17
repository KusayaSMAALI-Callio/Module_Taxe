pageextension 8062614 "CAGTX_Vendor Card" extends "Vendor Card"
{
    actions
    {
        addlast(navigation)
        {
            action("CAGTX_VendorSubjectToTax")
            {
                Caption = 'Add Customer Subject To Tax';
                Image = TaxDetail;
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Executes the Add Customer Subject To Tax action';

                trigger OnAction()
                var
                    TaxManagement_L: Codeunit "CAGTX_Tax Management";
                begin
                    TaxManagement_L.ShowThridPartyUseSubjectToTax(1, Rec."No.", Rec."Vendor Posting Group");
                end;
            }
        }
    }
}

