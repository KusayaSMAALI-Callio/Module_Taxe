pageextension 8062609 "CAGTX_Posted Sales Cr. Memo SF" extends "Posted Sales Cr. Memo Subform"
{

    actions
    {
        addlast("&Line")
        {
            action("CAGTX_Tax Lines")
            {
                Caption = 'Tax Lines';
                Image = ExpandDepositLine;
                RunObject = Page "CAGTX_Sales Cr. Memo Tax Lines";
                RunPageLink = "Document No." = FIELD("Document No."),
                              "CAGTX_Origin Tax Line" = FIELD("Line No.");
                ApplicationArea = Basic, Suite;
                ToolTip = 'Executes the Tax Lines action';
            }
        }
    }
}

