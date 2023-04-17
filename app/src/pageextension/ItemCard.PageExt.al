pageextension 8062958 "CAGTX_Item Card" extends "Item Card"
{
    layout
    {
        addafter(Warehouse)
        {
            part("CAGTX_Item Taxes SP"; "CAGTX_Item Taxes SP")
            {
                Caption = 'Item Taxes';
                ApplicationArea = All;
                Editable = true;
                SubPageLink = Type = CONST(Item), "No." = FIELD("No.");
            }
        }
    }

    actions
    {
        addlast(Navigation_Item)
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

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage."CAGTX_Item Taxes SP".Page.SetFromItem(Rec);
    end;
}