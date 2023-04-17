pageextension 8062959 "CAGTX_Item List" extends "Item List"
{
    actions
    {
        addlast(Item)
        {
            action("CAGTX_OpenItemTaxes")
            {
                Caption = 'Taxes';
                ToolTip = 'Taxes';
                ApplicationArea = all;
                Image = TaxSetup;
                Promoted = true;
                PromotedCategory = Category4;

                trigger OnAction()
                var
                    TaxMgt: Codeunit "CAGTX_Tax Management";
                begin
                    TaxMgt.OpenItemTaxes(Rec."No.");
                end;
            }
        }
    }
}