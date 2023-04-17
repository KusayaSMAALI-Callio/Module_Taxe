pageextension 8062610 "CAGTX_Posted Purch. Rcpt. SF" extends "Posted Purchase Rcpt. Subform"
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
        addafter(ItemInvoiceLines)
        {
            action("CAGTX_TaxLines")
            {
                Caption = 'Tax Lines';
                ApplicationArea = Basic, Suite;
                Image = ExpandDepositLine;
                RunObject = Page "CAGTX_Shipment Tax Lines";
                RunPageLink = "Document No." = FIELD("Document No."),
                              "CAGTX_Origin Tax Line" = FIELD("Line No.");
                ToolTip = 'Executes the Tax Lines action';
            }
        }
    }
}

