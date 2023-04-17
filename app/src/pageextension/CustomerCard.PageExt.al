pageextension 8062613 "CAGTX_Customer Card" extends "Customer Card"
{
    actions
    {
        addlast("F&unctions")
        {
            action("CAGTX_CustomerSubjectToTax")
            {
                Caption = 'Add Customer Subject To Tax';
                Image = TaxDetail;
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Executes the Add Customer Subject To Tax action';

                trigger OnAction()
                var
                    CMBTaxManagement_L: Codeunit "CAGTX_Tax Management";
                begin
                    CMBTaxManagement_L.ShowThridPartyUseSubjectToTax(0, Rec."No.", Rec."Customer Posting Group");
                end;
            }
        }
    }
}

