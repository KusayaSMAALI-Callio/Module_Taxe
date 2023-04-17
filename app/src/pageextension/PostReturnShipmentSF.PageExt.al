pageextension 8062644 "CAGTX_Post. Return Shipment SF" extends "Posted Return Shipment Subform"
{

    layout
    {
        addafter(Correction)
        {
            field("CAGTX_Tax Code"; Rec."CAGTX_Tax Code")
            {
                Editable = false;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the value of the CAGTX_Tax Code field';
            }
        }
    }
    actions
    {
        addafter(ItemCreditMemoLines)
        {
            action("CAGTX_TaxLines")
            {
                Caption = 'Tax Lines';
                Image = ExpandDepositLine;
                RunObject = Page "CAGTX_Shipment Tax Lines";
                RunPageLink = "Document No." = FIELD("Document No."),
                              "CAGTX_Origin Tax Line" = FIELD("Line No.");
                ApplicationArea = Basic, Suite;
                ToolTip = 'Executes the Tax Lines action';
            }
        }
    }
}

