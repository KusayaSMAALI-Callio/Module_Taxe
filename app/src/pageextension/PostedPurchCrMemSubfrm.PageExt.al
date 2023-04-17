pageextension 8062612 "CAGTX_PostedPurch.Cr.MemSubfrm" extends "Posted Purch. Cr. Memo Subform"
{

    layout
    {
        addafter("Shortcut Dimension 2 Code")
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
        addafter(ItemReturnShipmentLines)
        {
            action("CAGTX_TaxLines")
            {
                Caption = 'Tax Lines';
                Image = ExpandDepositLine;
                ApplicationArea = Basic, Suite;
                RunObject = Page "CAGTX_Shipment Tax Lines";
                RunPageLink = "Document No." = FIELD("Document No."),
                              "CAGTX_Origin Tax Line" = FIELD("Line No.");
                ToolTip = 'Executes the Tax Lines action';
            }
        }
    }
}

